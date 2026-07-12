use strict;
use warnings;
use Test::More;
use Test::Exception;

# LIVE coverage for N concurrent async queries resolved through a single
# Pool of M connections.
#
# WHY this is a live test: every other live test in this distribution
# drives ONE acquire->query->release round-trip per await. Nothing exercises
# the multiplexed case where N in-flight Futures are spread over M < N
# pooled EV::Pg handles, with libpq callbacks firing in arbitrary order on
# the EV loop. The bug class this guards against is "EV watcher delivers
# result rows to the wrong Future" — only a real socket multiplexing across
# M real libpq handles, with queries out-pacing acquires, can catch a
# demultiplexing defect. A mock could serialize callbacks by hand and would
# prove nothing. We assert that:
#
#   1. 20 concurrent select_async Futures (N=20) issued BEFORE any await all
#      eventually resolve (no Futures lost, no Futures merged);
#   2. every result has exactly one row — proves the libpq result-row
#      callback landed on the Future that issued the matching query;
#   3. pool->size stays at exactly 4 (M) — proves we did not spawn one
#      connection per query;
#   4. (smoke) parallel wall-time is meaningfully less than sequential
#      wall-time × 2 — gated behind a TODO block so it can be marked
#      TODO/flaky on slow CI without invalidating the rest of the test.

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
}

use EV;
use EV::Pg;
use DBIO::PostgreSQL::EV::Storage;

# Parse DSN into a libpq conninfo hash (mirrors t/12-/t/13-/t/14-/t/15-/t/16-).
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

# Pool size: 4 handles, 20 concurrent queries (5x oversubscription).
# Storage.pm:117-119 strips `pool_size` out of the conninfo hash and uses
# it as the pool's max_size, so this is the documented way to size it.
$ci{pool_size} = 4;

# Drive a Future to completion on the EV loop under a wall-clock guard.
sub await_guarded {
  my ($f, $what) = @_;
  local $SIG{ALRM} = sub { die "TIMEOUT awaiting $what\n" };
  alarm 30;
  EV::run(EV::RUN_ONCE) until $f->is_ready;
  alarm 0;
  return $f;
}

# Raw statement on a pooled connection (DDL setup/teardown only).
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

my $table = 'dbio_concurrency_live';

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ \%ci, {} ]);

# Sanity: pool max_size is what we asked for.
is $storage->pool->max_size, 4, 'pool max_size honored the conninfo pool_size=4';

run_raw($storage, "DROP TABLE IF EXISTS $table");
run_raw($storage, "CREATE TABLE $table (id serial PRIMARY KEY, owner text)");

# Pre-populate so the concurrent selects return meaningful rows.
for my $i (1..20) {
  await_guarded(
    $storage->insert_async($table, { owner => "u$i" }),
    "seed insert $i",
  );
}

# --- fire 20 concurrent select_async Futures BEFORE awaiting any ---------

# Snapshot the peak pool size across the run. We poll size from a separate
# EV::check watcher so we catch the maximum even if connections come back
# to idle before we look.
my $peak_size = $storage->pool->size;
my $size_watcher;
$size_watcher = EV::check sub {
  my $now = $storage->pool->size;
  $peak_size = $now if $now > $peak_size;
};

# Prime the pool with 4 PARALLEL acquires (not sequential!) so the pool
# actually has 4 distinct connections ready to be checked out concurrently.
# Sequential acquires would just reuse the same idle connection — pool size
# stays at 1. Only when N acquires are in flight at once does the pool
# spawn up to max_size connections.
my @preheat_futs;
for my $i (1..4) {
  push @preheat_futs, $storage->select_async($table, ['id'], { id => 1 });
}
await_guarded(Future->needs_all(@preheat_futs), 'preheat 4 parallel');
is $storage->pool->size, 4, '4 parallel preheat acquires spawned 4 connections';

# Release the preheat connections so they go back to idle before the burst.
# We cannot truly release them from outside, but the preheat Futures have
# all resolved and released — the 4 connections are now idle.
is $storage->pool->available, 4, 'all 4 preheat connections are back on the idle stack';

# Now the real concurrency burst: 20 Futures, NONE awaited yet.
#
# (A) fan-out probe: we also select pg_backend_pid() so each resolved row
# carries the OS pid of the backend that served it. pg_backend_pid() is a
# FUNCTION call, not a column, so it must reach libpq as raw SQL — the
# SQLMaker quotes a bare string as an identifier ("pid" -> "pid") which would
# blow up, but passes a SCALAR REF through verbatim. Verified against this
# repo's maker: ['id','owner', \'pg_backend_pid()'] renders
#   SELECT "id", "owner", pg_backend_pid() FROM ... WHERE "owner" = $1
# so index 2 of every result row is the backend pid.
my @futs;
for my $i (1..20) {
  push @futs, $storage->select_async(
    $table, ['id', 'owner', \'pg_backend_pid()'], { owner => "u$i" },
  );
}
is scalar(@futs), 20, '20 concurrent select_async Futures issued';

# Drain the loop until every Future resolves.
my $t0 = time;
await_guarded(
  Future->needs_all(@futs),
  'all 20 concurrent selects',
);
my $parallel_time = time - $t0;

# Every Future resolved (no Futures lost, none merged).
ok !(grep { !$_->is_ready } @futs), 'every concurrent Future resolved';
ok !(grep { $_->is_failed } @futs), 'no concurrent Future failed';

# Every result has exactly one row, and that row's owner matches the query
# binding. This is the demultiplexing assertion: if two Futures shared a
# result we'd see wrong-owner or wrong-row-count here. We also harvest each
# row's backend pid (index 2) into a set for the (A) fan-out assertion below.
my %burst_pid_set;
for my $i (1..20) {
  my @rows = $futs[$i - 1]->get;
  is scalar(@rows), 1, "Future $i: exactly one row returned";
  is $rows[0][1], "u$i", "Future $i: row owner matches the query binding";
  $burst_pid_set{ $rows[0][2] }++;
}

# Pool did not grow beyond 4 — proves multiplexing worked, not "spawn per query".
is $peak_size, 4, 'pool size never exceeded 4 (no connection-per-query leak)';
is $storage->pool->size, 4,
  'pool size still 4 after the burst (all 20 connections released back)';
is $storage->pool->available, 4,
  'all 4 connections back on the idle stack after the burst (no leak)';

# --- (A) BURST FAN-OUT: every pool slot served part of the burst ----------
#
# With pool_size=4 at most 4 distinct backends can exist, and the burst
# checks out all 4 idle conns at once (the first 4 acquires drain the idle
# list; the other 16 queue as waiters and reuse those same 4 as they free
# up). So the 20 Futures MUST spread across all 4 backends — proving the pool
# fans out over every slot instead of serialising onto one hot conn.
#
# NOTE (why this is NOT by itself a FIFO proof — see block B): draining a
# cold, fully-idle pool with N simultaneous acquires empties the idle list to
# zero either way. pop (LIFO) and shift (FIFO) both hand out the same 4
# distinct conns here, so this assertion passes under BOTH — it discriminates
# fan-out, not acquire ORDER.
is scalar(keys %burst_pid_set), 4,
  'burst fanned out across all 4 pooled backends (distinct pg_backend_pid == max_size=4)';

# --- (B) SEQUENTIAL FIFO ROTATION — the real acquire-order proof ----------
#
# FIFO-vs-LIFO is only observable under acquire/release CHURN, where the pool
# is fully idle between acquires and the choice of WHICH idle conn to reuse is
# visible. We drive a strictly sequential loop — acquire -> read
# pg_backend_pid() -> release, awaiting each Future BEFORE issuing the next so
# all 4 conns are back on the idle list at the top of every iteration — and
# watch the pids.
#
# PoolBase models the idle list as a FIFO QUEUE: acquire = shift @_idle
# (oldest-released first), release = push @_idle (newest to the back). So a
# churned loop must ROTATE through every pooled conn in release order: shift
# hands out the front, release pushes it to the back, the next shift takes the
# NEXT conn — never the one we just released. Over 2 full rounds we therefore
# see a fixed period-4 cycle: pid1,pid2,pid3,pid4,pid1,pid2,pid3,pid4.
#
# LIFO SENSITIVITY (house rule #7 — these assertions MUST go red under pop):
# if acquire reverted to pop @_idle (a LIFO stack), every iteration would pop
# the very conn release just pushed — the SAME backend pid every single time.
# Then %rot_seen would hold exactly ONE pid, so (B1) distinct-count (1 != 4)
# and (B2) consecutive-differ (every pair equal) both FAIL, and the (B3)
# cross-check set {pid} != {4 burst pids} FAILS too. That single-conn
# starvation ("one conn preferred, the rest starve") is exactly the karr #13
# bug the shift-fix cured; verified empirically by running this file against
# the still-installed pop core (RED) vs. the fixed shift core (GREEN).
#
# ($rot_pids[i] == $rot_pids[i-4] alone is NOT a discriminator: if all pids
#  are identical it holds trivially. It is the POSITIVE FIFO signature only
#  once (B1) has established that there really are 4 distinct pids.)

my @rot_pids;
my $slots = $storage->pool->max_size;      # 4
for my $iter (1 .. 2 * $slots) {           # 2 full rounds = 8 iterations
  # WHERE id=1 pins the result to exactly one row; the sole selected item is
  # the backend pid (index 0). Awaiting here (not batching) is the whole
  # point — it forces the pool fully idle before the next acquire, so acquire
  # ORDER, not fan-out, is what is under test.
  my $f = $storage->select_async($table, [ \'pg_backend_pid()' ], { id => 1 });
  await_guarded($f, "FIFO rotation iter $iter");
  my @rows = $f->get;
  is scalar(@rows), 1, "rotation iter $iter: exactly one row";
  push @rot_pids, $rows[0][0];
  is $storage->pool->size, 4, "rotation iter $iter: pool still 4 (churn, no growth)";
}

# (B1) FIFO rotates through EVERY pooled backend — the primary LIFO
# discriminator. Under pop this set collapses to size 1.
my %rot_seen;
$rot_seen{$_}++ for @rot_pids;
is scalar(keys %rot_seen), $slots,
  "sequential churn visited all $slots distinct backends (FIFO rotation; LIFO would stick to 1)";

# (B2) No two CONSECUTIVE iterations reused the same backend: shift always
# hands out a different conn than the one release just pushed to the back.
# Under LIFO every consecutive pair is identical.
my $consecutive_repeats = 0;
for my $i (1 .. $#rot_pids) {
  $consecutive_repeats++ if $rot_pids[$i] == $rot_pids[$i - 1];
}
is $consecutive_repeats, 0,
  'no consecutive iteration reused the same backend (FIFO hands out a fresh conn; LIFO repeats every time)';

# (B3) Positive FIFO signature: iteration i reuses the SAME backend as
# iteration i-4, i.e. a fixed period-max_size cycle — each idle conn recycled
# in strict release order, round after round.
my $period_ok = 1;
for my $i ($slots .. $#rot_pids) {
  $period_ok = 0 if $rot_pids[$i] != $rot_pids[$i - $slots];
}
ok $period_ok,
  "pid sequence rotates with a fixed period of $slots (each slot reused in release order every round)"
  or diag "rotation pids: @rot_pids";

# Cross-check: the rotation touched exactly the same 4 backends the burst
# fanned out over — same pool, same conns, no hidden reconnect. Also fails
# under LIFO (its single-pid set != the 4-pid burst set).
is_deeply
  [ sort { $a <=> $b } keys %rot_seen ],
  [ sort { $a <=> $b } keys %burst_pid_set ],
  'FIFO rotation reused the very same 4 backends the burst used (no reconnect)';

# --- sequential wall-time for the smoke comparison ------------------------

$t0 = time;
for my $i (1..20) {
  await_guarded(
    $storage->select_async($table, ['id', 'owner'], { owner => "u$i" }),
    "sequential $i",
  );
}
my $sequential_time = time - $t0;

# Smoke: parallel must beat 2x sequential to be plausibly faster. Over loopback
# and with a small query, sequential is already very fast; if this assertion
# is too flaky on slow CI we just TODO it.
TODO: {
  local $TODO = "wall-time is environment-sensitive on slow CI";
  ok $parallel_time < ($sequential_time * 2),
    "parallel ($parallel_time s) < 2 * sequential ($sequential_time s)"
    or diag "parallel=$parallel_time sequential=$sequential_time";
}

# --- cleanup --------------------------------------------------------------

run_raw($storage, "DROP TABLE IF EXISTS $table");
$size_watcher = undef;     # detach EV::check watcher before disconnect
$storage->disconnect;

done_testing;
