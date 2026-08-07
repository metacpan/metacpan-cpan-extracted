#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp ();

# Phase 2: the forked worker pool (Backend B). Each worker holds its own DBI
# connection to a shared on-disk SQLite file; requests/results cross a
# socketpair as Storable frames, driven by the IO::Async loop adapter.

BEGIN {
    plan skip_all => 'IO::Async required' unless eval { require IO::Async::Loop; 1 };
    plan skip_all => 'DBD::SQLite required' unless eval { require DBD::SQLite; 1 };
    plan skip_all => 'Storable required' unless eval { require Storable; 1 };
}

use DBIx::Loop;
use DBIx::Loop::Loop::IOAsync;

my $dir  = File::Temp->newdir;
my $file = "$dir/pool.db";
my $ad   = DBIx::Loop::Loop::IOAsync->new;
my $db   = DBIx::Loop->connect(
    "dbi:SQLite:dbname=$file", '', '',
    { RaiseError => 1, PrintError => 0 },
    loop => $ad, workers => 3,
);

is($db->capability, 'pool', 'SQLite -> pool backend');

sub await1 { my $f = shift; $ad->await($f); return ($f->get)[0] }

# ---- schema + writes (each runs on some worker) ---------------------------------
{
    my $f = $db->do("CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT)");
    $ad->await($f);
    ok($f->is_done, 'CREATE TABLE resolved on a worker');
}
{
    my @f = map { $db->do("INSERT INTO t (id,name) VALUES (?,?)", $_, "n$_") } 1 .. 5;
    my $affected = 0;
    for my $f (@f) { my $r = await1($f); $affected += $r->{rows_affected} }
    is($affected, 5, 'five inserts, one row affected each');
}

# ---- a SELECT comes back as arrayrefs + column names ----------------------------
{
    my $res = await1($db->query("SELECT id,name FROM t ORDER BY id"));
    is(scalar @{ $res->{rows} }, 5, 'five rows selected');
    is_deeply($res->{rows}[0], [1, 'n1'], 'first row is an arrayref');
    is_deeply($res->{columns}, ['id', 'name'], 'column names returned');
}

# ---- concurrency: fire more queries than workers; all resolve -------------------
{
    my @f = map { $db->query("SELECT COUNT(*) FROM t") } 1 .. 8;
    $ad->await($_) for @f;
    my $ok = 0;
    for my $f (@f) { $ok++ if $f->is_done && ($f->get)[0]{rows}[0][0] == 5 }
    is($ok, 8, 'all 8 concurrent queries resolved correctly across 3 workers');
}

# ---- a DB error fails just that future ------------------------------------------
{
    my $f = $db->query("SELECT * FROM does_not_exist");
    $ad->await($f);
    ok($f->is_failed, 'bad query -> failed future');
    like($f->failure, qr/no such table/i, 'failure carries the DB error');

    # the pool keeps working afterward
    my $res = await1($db->query("SELECT COUNT(*) FROM t"));
    is($res->{rows}[0][0], 5, 'pool still serves after an error');
}

# ---- worker crash: in-flight future fails, slot respawns, pool recovers ---------
{
    my @pids = $db->_worker_pids;
    is(scalar @pids, 3, 'pool reports 3 worker pids');

    # kill a worker while a query is in flight on it: with all three workers
    # saturated, worker 0 is provably busy when we SIGKILL its pid.
    my @f = map { $db->query("SELECT COUNT(*) FROM t") } 1 .. 3;
    kill 'KILL', $pids[0];
    $ad->await($_) for @f;
    my $failed = grep { $_->is_failed } @f;
    ok($failed >= 1, 'killing a busy worker fails its in-flight future')
        or diag map { $_->is_failed ? "failed: " . $_->failure : "done" } @f;

    # the slot respawned: pool still has 3 live pids, the dead one replaced
    my @pids2 = $db->_worker_pids;
    is(scalar(grep { $_ > 0 } @pids2), 3, 'dead slot respawned (3 live pids)');
    isnt($pids2[0], $pids[0], 'slot 0 has a new pid');

    # and keeps serving at full width
    my @g = map { $db->query("SELECT COUNT(*) FROM t") } 1 .. 6;
    $ad->await($_) for @g;
    is(scalar(grep { $_->is_done && ($_->get)[0]{rows}[0][0] == 5 } @g), 6,
        'pool serves 6 concurrent queries after the crash');
}

$db->disconnect;

# ---- backpressure: max_queue caps pending work ----------------------------------
{
    my $db2 = DBIx::Loop->connect(
        "dbi:SQLite:dbname=$file", '', '',
        { RaiseError => 1, PrintError => 0 },
        loop => $ad, workers => 1, max_queue => 2,
    );
    # 1 in flight on the single worker + 2 queued = at cap; 4th fails at once
    my @f = map { $db2->query("SELECT COUNT(*) FROM t") } 1 .. 4;
    ok($f[3]->is_ready && $f[3]->is_failed, '4th query fails immediately at the cap');
    like($f[3]->failure, qr/queue full/, 'failure names the queue cap');
    $ad->await($_) for @f[0 .. 2];
    is(scalar(grep { $_->is_done } @f[0 .. 2]), 3, 'the capped three still resolve');
    $db2->disconnect;
}

done_testing();
