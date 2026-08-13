#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Socket;

# Phase 5: the pure-XS Hyperman loop adapter, over Hyperman's C ABI. Seam
# conformance (watchers, timers + cancellation, native futures, await) and
# the pool driven end-to-end through the C vtable path (no Perl call frame
# between fd readiness and the pool's frame handler).

BEGIN {
    plan skip_all => 'Hyperman required' unless eval { require Hyperman; 1 };
}

use DBIx::Loop;
use DBIx::Loop::Loop::Hyperman;

# Hyperman loading is not the same thing as an adapter this dist can build.
# The adapter binds to Hyperman's public C ABI, which arrived in Hyperman
# 0.10; against an older one it croaks, correctly. DBIx::Loop declares no
# Hyperman prerequisite - the coupling is runtime-only, by design - so
# whichever Hyperman happens to be installed is not ours to demand: skip on
# one that predates the ABI rather than failing the distribution over it.
my $ad = eval { DBIx::Loop::Loop::Hyperman->new };
unless ($ad) {
    my $have = eval { Hyperman->VERSION };
    plan skip_all => 'Hyperman ' . (defined $have ? $have : '(unknown version)')
                   . ' has no C ABI for this adapter (needs Hyperman 0.10+)';
}

isa_ok($ad, 'DBIx::Loop::Loop::Hyperman', 'adapter');
isa_ok($ad->loop, 'Hyperman::Loop', 'underlying loop');

# ---- native futures -------------------------------------------------------------
{
    my $f = $ad->new_future;
    isa_ok($f, 'Hyperman::Future', 'new_future is ecosystem-native');
    ok(!$f->is_ready, 'new future is pending');
    $f->done(42);
    is(($f->get)[0], 42, 'settles and holds its value');
}

# ---- timer fires; await pumps the loop ------------------------------------------
{
    my $f = $ad->new_future;
    $ad->timer(0.02, sub { $f->done('tick') });
    $ad->await($f);
    is(($f->get)[0], 'tick', 'timer fired and await returned');
}

# ---- cancel_timer: a cancelled timer never fires --------------------------------
{
    my $fired = 0;
    my $id = $ad->timer(3600, sub { $fired++ });
    $ad->cancel_timer($id);
    my $f = $ad->new_future;
    $ad->timer(0.02, sub { $f->done });
    $ad->await($f);
    is($fired, 0, 'cancelled timer did not fire');
}

# ---- add_reader / remove --------------------------------------------------------
{
    socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $count = 0;
    my $f = $ad->new_future;
    $ad->add_reader(fileno($a), sub {
        sysread($a, my $buf, 16);
        $count++;
        $f->done($buf);
    });
    syswrite($b, 'ping');
    $ad->await($f);
    is(($f->get)[0], 'ping', 'add_reader saw the bytes');
    is($count, 1, 'reader fired once');

    $ad->remove(fileno($a));
    syswrite($b, 'again');
    my $f2 = $ad->new_future;
    $ad->timer(0.05, sub { $f2->done });
    $ad->await($f2);
    is($count, 1, 'remove() actually stops callbacks');
    close $a; close $b;
}

# ---- add_writer -----------------------------------------------------------------
{
    socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $f = $ad->new_future;
    $ad->add_writer(fileno($a), sub {
        $ad->remove(fileno($a));   # persistent watcher: disarm before done
        $f->done('writable');
    });
    $ad->await($f);
    is(($f->get)[0], 'writable', 'add_writer fired on a writable socket');
    close $a; close $b;
}

# ---- await bridges foreign futures ----------------------------------------------
{
    my $df = DBIx::Loop::Future->new;
    $ad->timer(0.02, sub { $df->done('bridged') });
    $ad->await($df);
    is(($df->get)[0], 'bridged', 'await pumps for a DBIx::Loop::Future too');
}

# ---- the pool end-to-end through the C vtable -----------------------------------
SKIP: {
    skip 'DBD::SQLite required', 7 unless eval { require DBD::SQLite; 1 };
    skip 'Storable required',    7 unless eval { require Storable; 1 };

    my $dir  = File::Temp->newdir;
    my $file = "$dir/pool.db";
    my $db   = DBIx::Loop->connect(
        "dbi:SQLite:dbname=$file", '', '',
        { RaiseError => 1, PrintError => 0 },
        loop => $ad, workers => 2,
    );

    is($db->capability, 'pool', 'SQLite -> pool backend');

    my $await1 = sub { my $f = shift; $ad->await($f); ($f->get)[0] };

    {
        my $f = $db->do("CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT)");
        $ad->await($f);
        ok($f->is_done, 'CREATE TABLE resolved through the C seam');
    }
    {
        my @f = map { $db->do("INSERT INTO t (id,name) VALUES (?,?)", $_, "n$_") } 1 .. 4;
        my $affected = 0;
        $affected += $await1->($_)->{rows_affected} for @f;
        is($affected, 4, 'concurrent inserts all resolved');
    }
    {
        my $res = $await1->($db->query("SELECT id,name FROM t ORDER BY id"));
        is(scalar @{ $res->{rows} }, 4, 'four rows back');
        is($res->{rows}[0][1], 'n1', 'row content survives the frame');
    }
    {
        my $f = $db->query("SELECT no_such_column FROM t");
        $ad->await($f);
        ok($f->is_failed, 'a failing query fails only its own future');
    }
    {
        my $res = $await1->($db->query("SELECT COUNT(*) FROM t"));
        is($res->{rows}[0][0], 4, 'pool still healthy after a failure');
    }

    $db->disconnect;
}

done_testing;
