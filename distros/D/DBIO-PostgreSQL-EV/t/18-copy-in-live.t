use strict;
use warnings;
use Test::More;
use Test::Exception;

# LIVE coverage for $storage->copy_in
# (DBIO::PostgreSQL::EV::Storage::copy_in, Storage.pm:718-757).
#
# WHY this is a live test: copy_in dispatches a real `COPY FROM STDIN`
# protocol over libpq: $pg->query to enter COPY mode, then a stream of
# $pg->put_copy_data rows in the wire format (TAB-separated, '\N' for NULL),
# then $pg->put_copy_end to flush. The bug class this guards against is
# "put_copy_end not called on the error path so the connection hangs in
# COPY mode", "rows not actually persisted because we never left COPY
# state", or "pool connection leaked when the coderef dies". A mock
# libpq could be wired to accept a single callback chain and would prove
# nothing — only a real PostgreSQL parses the COPY wire format, applies the
# rows, and either commits them or surfaces a real server-side error. We
# assert that:
#
#   1. 100 rows in via copy_in are persisted;
#   2. NULL values round-trip (undef -> '\N' -> SQL NULL);
#   3. the copy_in Future resolves to a truthy value (currently 1);
#   4. the pool connection is released after success (no leak);
#   5. a coderef that dies fails the Future with the die message AND the
#      pool connection is still released (no leak on error).
#
# Known production limitation: copy_in calls pool->release IMMEDIATELY
# after $pg->put_copy_end, but the COPY stream is still being processed
# asynchronously by libpq — the server has not yet sent CommandComplete.
# The released connection is therefore still in COPY state on the wire.
# If the same Storage object then runs any other query on the same pool,
# the next acquire picks the still-busy connection and libpq returns
# "PQsendQueryParams failed: another command is already in progress".
# This test therefore verifies row persistence via a SECOND Storage
# instance (separate pool, fresh connections) and does not assert that
# the same Storage can immediately run another query. Filed as a karr
# ticket for follow-up; this test is the regression guard.

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
}

use EV;
use EV::Pg;
use DBIO::PostgreSQL::EV::Storage;

# Parse DSN into a libpq conninfo hash (mirrors t/12-/t/13-/t/14-/t/15-/t/16-/t/17-).
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

# Drive a Future to completion on the EV loop under a wall-clock guard.
sub await_guarded {
  my ($f, $what) = @_;
  local $SIG{ALRM} = sub { die "TIMEOUT awaiting $what\n" };
  alarm 20;
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

my $table = 'dbio_copy_in_live';

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ \%ci, {} ]);

run_raw($storage, "DROP TABLE IF EXISTS $table");
run_raw($storage,
  "CREATE TABLE $table (id int PRIMARY KEY, name text, score int)"
);

# --- 1. bulk load 100 rows; every row round-trips through select_async ---

my $N = 100;
my $idle_before = $storage->pool->available;

my $copy_f = await_guarded(
  $storage->copy_in($table, [ 'id', 'name', 'score' ], sub {
    my ($put) = @_;
    for my $i (1..$N) {
      # Half the rows: NULL name (Storage maps undef -> '\N' on the wire).
      my $name = ($i % 2 == 0) ? undef : "user-$i";
      $put->([ $i, $name, $i * 10 ]);
    }
  }),
  'copy_in 100 rows',
);

ok $copy_f->is_done,  'copy_in Future resolved';
ok !$copy_f->is_failed, 'copy_in Future succeeded';
ok $copy_f->get,       'copy_in Future resolved to a truthy value (currently 1)';

# Connection released back to the idle pool. Note: `available` does not
# necessarily equal `idle_before + 1`; copy_in acquires one connection and
# then releases it, net-zero change on the idle stack. What we want to
# assert is: at least one connection is idle (released), and the pool did
# not spawn an extra connection.
ok $storage->pool->available >= 1,
  'pool connection released back to idle after copy_in success';
is $storage->pool->size, 1,
  'copy_in did not spawn an extra connection';

# Verify all 100 rows were persisted. We deliberately use a SECOND
# Storage instance with a fresh pool here — see the WHY comment at the
# top of this file for the known production limitation that would make
# the same-storage read fail with "another command is already in progress".
my $verifier = DBIO::PostgreSQL::EV::Storage->new(undef);
$verifier->connect_info([ \%ci, {} ]);

my @rows = await_guarded(
  $verifier->select_async($table, [ 'id', 'name', 'score' ], {}),
  'select (verifier storage) after copy_in',
)->get;
is scalar(@rows), $N, "all $N rows persisted via COPY are visible to a fresh storage";
$verifier->disconnect;

# Spot-check a handful of rows for shape (defends against off-by-one in
# the put_copy_data loop) and prove NULL round-trips.
my %by_id = map { $_->[0] => $_ } @rows;
is_deeply $by_id{1},   [ 1, 'user-1', 10 ],  'odd id 1: name user-1, score 10';
is_deeply $by_id{2},   [ 2, undef,    20 ],  'even id 2: name NULL (undef round-trip)';
is_deeply $by_id{49},  [ 49, 'user-49', 490 ],
  'odd id 49: name user-49, score 490';
is_deeply $by_id{50},  [ 50, undef,    500 ],
  'even id 50: name NULL (undef round-trip)';
is_deeply $by_id{100}, [ 100, undef, 1000 ],
  'even id 100: name NULL (undef round-trip)';

# Dedicated NULL-count assertion: exactly half the rows have undef name.
my $null_count = grep { !defined $_->[1] } @rows;
is $null_count, $N / 2, "exactly $N/2 NULL names round-tripped via backslash-N wire format";

# --- 2. coderef that DIES — Future fails AND connection is still released -
#
# We use a fresh Storage instance here so the broken-conn-from-section-1
# (see the WHY comment at the top) does not poison section 2.

my $storage2 = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage2->connect_info([ \%ci, {} ]);

my $f_die = await_guarded(
  $storage2->copy_in($table, [ 'id', 'name', 'score' ], sub {
    $_[0]->([ 1, 'first', 1 ]);
    $_[0]->([ 2, 'second', 2 ]);
    die "boom-in-copy-coderef\n";
  }),
  'copy_in die',
);

ok $f_die->is_failed, 'dying coderef: copy_in Future failed (did not hang)';
is +($f_die->failure // ''), "boom-in-copy-coderef\n",
  'dying coderef: copy_in Future carries the die message';

# Critical: even on the error path the pool connection must be released.
# A regression that skipped pool->release on the die branch would hang
# forever and only a separate live test could surface it. The pool may
# have spawned exactly one connection for this copy_in (cold pool) and
# then released it; what we care about is that the connection made it
# back to the idle stack instead of being leaked.
ok $storage2->pool->available >= 1,
  'dying coderef: pool connection released back to idle (no leak on error)';
$storage2->disconnect;

# --- cleanup --------------------------------------------------------------
#
# Use a throwaway Storage for the DROP — $storage's pool conn is still in
# COPY state (see WHY comment at top), so a direct run_raw would fail with
# "another command is already in progress".

{
  my $cleanup = DBIO::PostgreSQL::EV::Storage->new(undef);
  $cleanup->connect_info([ \%ci, {} ]);
  run_raw($cleanup, "DROP TABLE IF EXISTS $table");
  $cleanup->disconnect;
}
$storage->disconnect;

done_testing;
