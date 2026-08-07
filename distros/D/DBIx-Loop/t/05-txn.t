#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp ();

# Phase 4: transactions pinned to one pool slot. txn() acquires a slot, BEGINs,
# runs the block with a pinned DBIx::Loop::Txn handle, COMMITs / ROLLBACKs, and
# releases. SQLite TEMP tables are per-connection, which makes pinning provable:
# a temp table created through $tx must be visible to the next $tx statement
# (same connection) and invisible to $db (other workers).

BEGIN {
    plan skip_all => 'IO::Async required' unless eval { require IO::Async::Loop; 1 };
    plan skip_all => 'DBD::SQLite required' unless eval { require DBD::SQLite; 1 };
}

use DBIx::Loop;
use DBIx::Loop::Loop::IOAsync;

my $dir  = File::Temp->newdir;
my $file = "$dir/txn.db";
my $ad   = DBIx::Loop::Loop::IOAsync->new;
my $db   = DBIx::Loop->connect(
    "dbi:SQLite:dbname=$file", '', '',
    { RaiseError => 1, PrintError => 0, sqlite_use_immediate_transaction => 0 },
    loop => $ad, workers => 3,
);

sub await1 { my $f = shift; $ad->await($f); return ($f->get)[0] }

await1($db->do("CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT)"));

# ---- commit: writes inside the txn become visible --------------------------------
{
    my $f = $db->txn(sub {
        my ($tx) = @_;
        return $tx->do("INSERT INTO t (id,name) VALUES (?,?)", 1, 'rex')
                  ->then(sub { $tx->do("INSERT INTO t (id,name) VALUES (?,?)", 2, 'milo') });
    });
    $ad->await($f);
    ok($f->is_done, 'txn future resolves') or diag $f->failure;
    my $res = await1($db->query("SELECT COUNT(*) FROM t"));
    is($res->{rows}[0][0], 2, 'both inserts committed');
}

# ---- rollback on a failed block-future -------------------------------------------
{
    my $f = $db->txn(sub {
        my ($tx) = @_;
        return $tx->do("INSERT INTO t (id,name) VALUES (?,?)", 3, 'gone')
                  ->then(sub { $tx->query("SELECT * FROM no_such_table") });
    });
    $ad->await($f);
    ok($f->is_failed, 'failed statement fails the txn');
    like($f->failure, qr/no such table/i, 'failure carries the DB error');
    my $res = await1($db->query("SELECT COUNT(*) FROM t"));
    is($res->{rows}[0][0], 2, 'the insert was rolled back');
}

# ---- rollback when the block dies -------------------------------------------------
{
    my $f = $db->txn(sub {
        my ($tx) = @_;
        my $g = $tx->do("INSERT INTO t (id,name) VALUES (?,?)", 4, 'gone-too');
        die "changed my mind\n";
    });
    $ad->await($f);
    ok($f->is_failed, 'a die in the block fails the txn');
    like($f->failure, qr/changed my mind/, 'failure carries the die message');
    my $res = await1($db->query("SELECT COUNT(*) FROM t"));
    is($res->{rows}[0][0], 2, 'the insert was rolled back after the die');
}

# ---- pinning proof: TEMP tables are per-connection --------------------------------
{
    my $f = $db->txn(sub {
        my ($tx) = @_;
        return $tx->do("CREATE TEMP TABLE tx_only (v INTEGER)")
            ->then(sub { $tx->do("INSERT INTO tx_only (v) VALUES (41)") })
            ->then(sub { $tx->do("INSERT INTO tx_only (v) VALUES (1)") })
            ->then(sub { $tx->query("SELECT SUM(v) FROM tx_only") });
    });
    $ad->await($f);
    ok($f->is_done, 'temp-table txn resolves') or diag $f->failure;
    is((($f->get)[0])->{rows}[0][0], 42,
       'three statements saw the same connection (TEMP table pinning)');
}

# ---- the plain $db stays usable while a txn holds a slot -------------------------
{
    my $done_outside = 0;
    my $f = $db->txn(sub {
        my ($tx) = @_;
        # a plain query goes to another (unreserved) worker
        my $out = $db->query("SELECT COUNT(*) FROM t");
        $out->on_ready(sub { $done_outside = shift->is_done });
        return $tx->do("INSERT INTO t (id,name) VALUES (?,?)", 5, 'aria')
                  ->then(sub { $out });
    });
    $ad->await($f);
    ok($f->is_done, 'txn with an interleaved plain query resolves');
    ok($done_outside, 'the plain $db query ran on another slot meanwhile');
    my $res = await1($db->query("SELECT COUNT(*) FROM t"));
    is($res->{rows}[0][0], 3, 'txn committed');
}

# ---- block return shapes ----------------------------------------------------------
{
    my $plain = $db->txn(sub { 'just-a-value' });
    $ad->await($plain);
    is(($plain->get)[0], 'just-a-value', 'a plain block return becomes the result');
}

# ---- txn handle after completion fails cleanly ------------------------------------
{
    my $escaped;
    my $f = $db->txn(sub { my ($tx) = @_; $escaped = $tx; 'ok' });
    $ad->await($f);
    ok(!$escaped->is_active, 'handle is inactive after the txn ends');
    my $late = $escaped->query("SELECT 1");
    ok($late->is_failed, 'a statement on a finished handle fails');
    like($late->failure, qr/not active/, '... with a clear message');
}

# ---- saturation: more txns than workers queue for slots ---------------------------
{
    my @f = map {
        my $n = $_;
        $db->txn(sub {
            my ($tx) = @_;
            $tx->do("INSERT INTO t (id,name) VALUES (?,?)", 100 + $n, "w$n");
        });
    } 1 .. 5;                       # 5 txns over 3 workers
    $ad->await($_) for @f;
    is(scalar(grep { $_->is_done } @f), 5, '5 txns complete over 3 slots');
    my $res = await1($db->query("SELECT COUNT(*) FROM t WHERE id > 100"));
    is($res->{rows}[0][0], 5, 'all five committed');
}

$db->disconnect;
done_testing();
