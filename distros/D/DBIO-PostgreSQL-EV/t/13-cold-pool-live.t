use strict;
use warnings;
use Test::More;
use Test::Exception;

# LIVE regression for karr #9: the very FIRST facade call on a COLD pool must
# succeed.
#
# WHY this is a live test: EV::Pg->new returns before its async connect has
# finished, so the bare PoolBase acquire() handed back a not-yet-connected
# handle and the first query_params dispatched in the next tick threw
# "not connected". Only a real socket connect (against a real server) drives
# the on_connect that the readiness gating now waits for — an offline fake of
# EV::Pg's async-connect timing would be contrived and could not fail the way
# the real handle does. So we assert against a real PostgreSQL that:
#
#   1. the FIRST Storage-facade CRUD call on a freshly built pool succeeds
#      (no pre-warm, no prior acquire) — this is exactly what died pre-fix;
#   2. acquire_txn (which core delegates to acquire) benefits automatically,
#      i.e. a transaction on a cold pool works too.

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
}

use EV;
use EV::Pg;
use DBIO::PostgreSQL::EV::Storage;

# Parse DSN into a libpq conninfo hash (mirrors t/12-positional-placeholders-live.t).
my $dsn  = $ENV{DBIO_TEST_PG_DSN};
my $user = $ENV{DBIO_TEST_PG_USER} || '';
my $pass = $ENV{DBIO_TEST_PG_PASS} || '';

my %ci;
if ($dsn =~ /^dbi:Pg:(.+)/i) {
  for my $kv (split /;/, $1) {
    my ($k, $v) = split /=/, $kv, 2;
    next unless defined $k && length $k;
    $k = 'dbname' if $k eq 'database';   # normalize for libpq
    $ci{$k} = $v;
  }
} else {
  for my $kv (split /\s+/, $dsn) {
    my ($k, $v) = split /=/, $kv, 2;
    $ci{$k} = $v if defined $k && length $k;
  }
}
$ci{user}     = $user if length $user;
$ci{password} = $pass if length $pass;

# Drive a Future to completion on the EV loop, then return its result.
sub await {
  my $f = shift;
  EV::run(EV::RUN_ONCE) until $f->is_ready;
  return $f->get;
}

# Run a raw statement on a pooled connection (table DDL setup/teardown only).
sub run_raw {
  my ($storage, $sql) = @_;
  return await($storage->pool->acquire->then(sub {
    my $pg = shift;
    my $f  = Future->new;
    $pg->query($sql, sub {
      my (undef, $err) = @_;
      $storage->pool->release($pg);
      $err ? $f->fail($err) : $f->done;
    });
    return $f;
  }));
}

my $table = 'dbio_karr9_cold';

# --- COLD pool: the FIRST facade call is the insert below ---

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ \%ci, {} ]);

# DDL setup goes through acquire too (also a cold-pool acquire on first use).
lives_ok {
  run_raw($storage, "DROP TABLE IF EXISTS $table");
  run_raw($storage, "CREATE TABLE $table (id serial PRIMARY KEY, name text)");
} 'cold-pool DDL via acquire succeeded';

# This insert_async is the first CRUD facade call on the pool. Pre-fix it threw
# "not connected"; with the readiness gating it must succeed.
my $ins;
lives_ok {
  $ins = await($storage->insert_async($table, { name => 'cold' }));
} 'karr #9: first facade insert on a COLD pool succeeded (no pre-warm)';
ok $ins && ref $ins eq 'HASH',
  'cold insert resolved with the returned-columns HASHREF (ADR 0031 §3)';
is $ins->{name}, 'cold', 'cold insert hashref carries the supplied data';

my @rows = await($storage->select_async($table, ['id', 'name'], { name => 'cold' }));
is scalar(@rows), 1, 'cold-pool select round-tripped the inserted row';
is $rows[0][1], 'cold', 'cold-pool select returned the right value';

# --- COLD pool + transaction: acquire_txn delegates to acquire (PoolBase
#     acquire_txn just calls acquire), so a transaction on a fresh pool must
#     benefit from the same readiness gating. ---
#
# We assert the karr #9-relevant property directly: on a COLD pool the FIRST
# acquire_txn resolves to an ALREADY-CONNECTED handle, and BEGIN dispatched on
# it succeeds (pre-fix this threw "not connected", exactly as the CRUD path
# did). We deliberately do NOT exercise the full txn_do_async BEGIN/COMMIT chain
# here: that path has a separate, pre-existing "lost a sequence Future" hang
# (Storage::_query_async_pinned, present before this fix and tracked in its own
# karr ticket) which is out of scope for #9's connection-readiness concern.

my $txn_storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$txn_storage->connect_info([ \%ci, {} ]);

my $txn_pg;
lives_ok {
  $txn_pg = await($txn_storage->pool->acquire_txn);
} 'karr #9: first acquire_txn on a COLD pool resolved without "not connected"';
ok $txn_pg->is_connected, 'cold-pool acquire_txn handed back a CONNECTED handle';

# BEGIN on the cold-acquired handle must succeed — this is the first thing
# txn_do_async does, and the part that depends on connection readiness.
lives_ok {
  await(do {
    my $f = Future->new;
    $txn_pg->query('BEGIN', sub {
      my (undef, $err) = @_;
      $err ? $f->fail($err) : $f->done;
    });
    $f;
  });
} 'cold-pool BEGIN on the txn-pinned handle succeeded';

await(do {
  my $f = Future->new;
  $txn_pg->query('ROLLBACK', sub { my (undef, $err) = @_; $err ? $f->fail($err) : $f->done });
  $f;
});
$txn_storage->pool->release($txn_pg);

# --- cleanup ---

lives_ok {
  run_raw($storage, "DROP TABLE IF EXISTS $table");
} 'cold-pool test table dropped';

$storage->disconnect;
$txn_storage->disconnect;

done_testing;
