use strict;
use warnings;
use Test::More;
use Test::Exception;

# LIVE coverage for $storage->copy_in (DBIO::PostgreSQL::EV::Storage::copy_in).
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
#      pool connection is still released (no leak on error);
#   6. it is the pool's one connection still, and the next statement runs
#      on it.
#
# Everything runs on the one storage that did the COPY, on its one
# connection -- the failing COPY of section 2 and the DROP at the end too: a
# connection left in the COPY, or released while the server's answer is still
# due, refuses the next statement ("another command is already in progress")
# and fails this file. The connection goes back at the server's answer since
# karr k13; t/19-copy-in-regression.t is the regression for that, t/74 holds
# every way a COPY ends.
#
# The read of section 1 alone is made by a second storage, on purpose: what a
# COPY wrote is there for another session -- committed -- and not only for
# the connection that wrote it.

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
}

use EV;
use EV::Pg;
use DBIO::PostgreSQL::EV::Storage;

# The test login as the libpq parameters the transport reads it as; a server
# that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use PoolReset;
use LiveServer;
use GuardedWait;
LiveServer->require_server;
my %ci = LiveServer->conninfo;

# The file's backstop: a hang anywhere in it ends the process. A guarded wait
# has a timeout of its own and leaves this alarm running (karr k88).
alarm 120;

# Drive a Future to completion on the EV loop under a wall-clock guard.
sub await_guarded {
  my ($f, $what) = @_;
  return GuardedWait->until_ready($f, 20, "TIMEOUT awaiting $what\n");
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
  my @r = await_guarded($f, "run_raw: $sql")->get;
  PoolReset->until_reset($storage);   # its connection is idle again (karr k99)
  return @r;
}

my $table = 'dbio_copy_in_live';

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ \%ci, {} ]);

run_raw($storage, "DROP TABLE IF EXISTS $table");
run_raw($storage,
  "CREATE TABLE $table (id int PRIMARY KEY, name text, score int)"
);

# --- 1. bulk load 100 rows; every row round-trips through select_async ---

PoolReset->until_reset($storage);   # the CREATE TABLE's connection is idle again (karr k99)
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
PoolReset->until_reset($storage);   # idle once its reset is answered (karr k99)
ok $storage->pool->available >= 1,
  'pool connection released back to idle after copy_in success';
is $storage->pool->size, 1,
  'copy_in did not spawn an extra connection';

# Verify all 100 rows were persisted: read by a SECOND Storage instance with
# a pool of its own, another session -- the rows are committed, not only
# there for the connection that wrote them.
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
# On the storage of section 1, whose pool holds the one connection that COPY
# ran on: this COPY takes the same one.

my $f_die = await_guarded(
  $storage->copy_in($table, [ 'id', 'name', 'score' ], sub {
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
# forever and only a separate live test could surface it. The pool held
# exactly one connection, idle, before this copy_in took it; what we care
# about is that the connection made it back to the idle stack instead of
# being leaked.
PoolReset->until_reset($storage);
ok $storage->pool->available >= 1,
  'dying coderef: pool connection released back to idle (no leak on error)';
is $storage->pool->size, 1,
  'dying coderef: it is still the one connection, not retired and not a second one';

# --- cleanup --------------------------------------------------------------
#
# On the same storage, so on the connection the failed COPY ran on: left in
# the COPY, it would refuse the DROP ("another command is already in
# progress").

lives_ok { run_raw($storage, "DROP TABLE IF EXISTS $table") }
  'the next statement runs on the connection the failed COPY ran on';
$storage->disconnect;

done_testing;
