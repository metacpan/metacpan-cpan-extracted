use strict;
use warnings;
use Test::More;
use Test::Exception;

# LIVE regression for karr #10: a full txn_do_async round-trip must complete
# (not hang) for BOTH the commit and the rollback-on-failure path.
#
# WHY this is a live test: the bug was a Future-lifetime defect in the
# BEGIN -> coderef -> COMMIT/ROLLBACK plumbing. The coderef's Future is the
# tail of a ->then chain, which Future holds only WEAKLY; without an explicit
# retain it was GC'd ("lost a sequence Future") before COMMIT/ROLLBACK could
# fire, so $f never resolved and the EV await loop busy-spun at ~100% CPU.
# Only a real connection drives the libpq query callbacks that this plumbing
# sequences, so an offline fake could not reproduce the spin. We assert that:
#
#   1. a txn_do_async COMMIT resolves and the row is actually persisted;
#   2. a coderef returning a FAILED Future rolls back, the outer Future fails
#      with the ORIGINAL error, and nothing is persisted;
#   3. a coderef that DIES rolls back, the outer Future fails with the die
#      message, and nothing is persisted;
#   4. NO "lost a sequence Future" warning is emitted on any path.
#
# Every await is guarded by alarm() so a future regression FAILS LOUD with a
# diagnostic instead of hanging the whole suite forever.

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
}

use EV;
use EV::Pg;
use DBIO::PostgreSQL::EV::Storage;

# Capture warnings so we can assert the "lost a sequence Future" regression
# never returns. Re-emit anything unexpected so genuine warnings stay visible.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0]; warn $_[0] };

# Parse DSN into a libpq conninfo hash (mirrors t/13-cold-pool-live.t).
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

# Drive a Future to completion on the EV loop under a wall-clock guard, so a
# regression that reintroduces the hang fails this test instead of spinning.
sub await_guarded {
  my ($f, $what) = @_;
  local $SIG{ALRM} = sub { die "TIMEOUT awaiting $what (karr #10 regression: txn hung)\n" };
  alarm 15;
  EV::run(EV::RUN_ONCE) until $f->is_ready;
  alarm 0;
  return $f;
}

# Raw statement on a pooled connection (DDL setup/teardown + verification).
sub run_raw {
  my ($storage, $sql) = @_;
  my $f = $storage->pool->acquire->then(sub {
    my $pg  = shift;
    my $rf  = Future->new;
    $pg->query($sql, sub {
      my (undef, $err) = @_;
      $storage->pool->release($pg);
      $err ? $rf->fail($err) : $rf->done;
    });
    return $rf;
  });
  return await_guarded($f, "run_raw: $sql")->get;
}

my $table = 'dbio_karr10_txn';

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ \%ci, {} ]);

run_raw($storage, "DROP TABLE IF EXISTS $table");
run_raw($storage, "CREATE TABLE $table (id serial PRIMARY KEY, name text)");

# --- 1. COMMIT: full round-trip, row persisted -----------------------------

my @committed;
lives_ok {
  @committed = await_guarded(
    $storage->txn_do_async(sub {
      my ($t) = @_;
      return $t->insert_async($table, { name => 'commit-me' });
    }),
    'txn_do_async COMMIT',
  )->get;
} 'karr #10: txn_do_async COMMIT round-trip completed without hanging';
ok scalar(@committed), 'COMMIT txn resolved with the coderef result';
is ref($committed[0]), 'HASH',
  'insert_async inside COMMIT txn resolved with a returned-columns HASHREF (ADR 0031 §3)';
is $committed[0]{name}, 'commit-me',
  'hashref carries the supplied insert data';
# Bare table-name source (no blessed source object) cannot zip the
# RETURNING row onto a declared column order, so the autoinc PK is not
# overlaid into the hashref -- the resolved value is just the supplied
# insert data, matching what sync $storage->insert returns for a bare
# table source too. We prove the row was actually inserted (and the
# serial PK was assigned by the engine) by re-reading it via SELECT
# below; here we assert the contract holds for the bare-name shape.
is_deeply $committed[0], { name => 'commit-me' },
  'hashref carries the supplied insert data (bare table source -- no PK overlay)';

my @after_commit = await_guarded(
  $storage->select_async($table, ['id', 'name'], { name => 'commit-me' }),
  'select after commit',
)->get;
is scalar(@after_commit), 1, 'committed row was actually persisted';

# --- 2. ROLLBACK on a coderef returning a FAILED Future --------------------

my $f_fail = await_guarded(
  $storage->txn_do_async(sub {
    my ($t) = @_;
    # Do a real write first so we can prove it is rolled back, THEN fail.
    return $t->insert_async($table, { name => 'rollback-me' })
             ->then(sub { Future->fail("intentional-failure\n") });
  }),
  'txn_do_async failed-Future ROLLBACK',
);
ok $f_fail->is_failed, 'failed-Future txn: outer Future failed (did not hang)';
is +($f_fail->failure // ''), "intentional-failure\n",
  'failed-Future txn: outer Future carries the original coderef error';

# --- 3. ROLLBACK on a coderef that DIES ------------------------------------

my $f_die = await_guarded(
  $storage->txn_do_async(sub {
    die "boom-in-coderef\n";
  }),
  'txn_do_async die ROLLBACK',
);
ok $f_die->is_failed, 'dying-coderef txn: outer Future failed (did not hang)';
is +($f_die->failure // ''), "boom-in-coderef\n",
  'dying-coderef txn: outer Future carries the die message';

# --- 4. Nothing from either rollback path persisted ------------------------

my @after_rollback = await_guarded(
  $storage->select_async($table, ['id', 'name'], { name => 'rollback-me' }),
  'select after rollback',
)->get;
is scalar(@after_rollback), 0, 'rolled-back write was NOT persisted';

# --- 5. No "lost a sequence Future" warning on any path --------------------

my @lost = grep { /lost a sequence Future/ } @warnings;
is scalar(@lost), 0, 'no "lost a sequence Future" warning emitted (karr #10)'
  or diag "Unexpected lost-future warnings:\n@lost";

# --- cleanup ---------------------------------------------------------------

run_raw($storage, "DROP TABLE IF EXISTS $table");
$storage->disconnect;

done_testing;
