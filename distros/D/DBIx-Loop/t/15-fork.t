#!perl
use strict;
use warnings;
use Test::More;
use File::Temp ();

# Fork safety.
#
# A pool belongs to the process that forked its workers. Before this was
# enforced, a process that forked after its first statement left every child
# reading the SAME socketpair - so a request could be answered with another
# request's rows - and a child's DESTROY ran kill(SIGTERM) on workers the
# parent was still using. Both are asserted here, because both are silent:
# nothing warns, the wrong data just arrives, or the pool just dies.

our $ADAPTER;
BEGIN {
    plan skip_all => 'DBI + DBD::SQLite required'
        unless eval { require DBI; require DBD::SQLite; 1 };

    # Any adapter will do: fork safety lives in the pool, not in the loop, and
    # all four adapters answer the same new/await. Which one is available is a
    # property of the perl - current IO::Async needs 5.14, AnyEvent does not -
    # and this has to run on the oldest perl the dist claims.
    for my $try ([ 'IO::Async::Loop' => 'DBIx::Loop::Loop::IOAsync' ],
                 [ 'AnyEvent'        => 'DBIx::Loop::Loop::AnyEvent' ],
                 [ 'Mojo::IOLoop'    => 'DBIx::Loop::Loop::Mojo'     ]) {
        my ($loop, $adapter) = @$try;
        next unless eval "require $loop; require $adapter; 1";
        $ADAPTER = $adapter;
        last;
    }
    plan skip_all => 'no event loop available (IO::Async, AnyEvent or Mojolicious)'
        unless $ADAPTER;
}

use DBIx::Loop;

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $db_file = "$dir/fork.db";

diag("fork safety over $ADAPTER");
my $ad = $ADAPTER->new;
my $db = DBIx::Loop->connect("dbi:SQLite:dbname=$db_file", '', '',
    { RaiseError => 1 }, loop => $ad, workers => 2);

sub await1 {
    my ($f) = @_;
    $ad->await($f);
    my ($r) = $f->get;
    return $r;
}

await1($db->do("CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)"));
await1($db->do("INSERT INTO t (id, v) VALUES (1, 'parent')"));

# ---- the pool is lazy: no workers until the first statement ------------------
# (already true by now - the do() above forced it)
my @parent_pids = $db->_worker_pids;
is(scalar @parent_pids, 2, 'the parent forked its two workers');
ok((grep { $_ > 0 } @parent_pids) == 2, 'and both have real pids');

# ---- a child gets its own pool, not the parent's -----------------------------
{
    my $pid = open my $rd, '-|';
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        # First statement in the child must build a fresh pool: the inherited
        # one is disowned, not reused.
        my $r = await1($db->query("SELECT v FROM t WHERE id = 1"));
        print join(',', $db->_worker_pids), "\n";
        print $r->{rows}[0][0], "\n";
        exit 0;
    }
    my @out = <$rd>;
    close $rd;
    chomp @out;
    my @child_pids = split /,/, ($out[0] // '');

    is(scalar @child_pids, 2, 'the child forked its own two workers');
    my %parent = map { $_ => 1 } @parent_pids;
    is(scalar(grep { $parent{$_} } @child_pids), 0,
       'and none of them is one of the parent\'s');
    is($out[1], 'parent', 'the child read its own correct row');
}

# ---- the parent survives the child's exit -----------------------------------
# This is the SIGTERM bug: the child's DESTROY used to reap the parent's
# workers, so the next parent query hung or failed.
{
    my @still = $db->_worker_pids;
    is_deeply([sort { $a <=> $b } @still], [sort { $a <=> $b } @parent_pids],
              'the parent still has the same workers after the child exited');

    my $alive = grep { kill(0, $_) } @still;
    is($alive, scalar @still, 'and every one of them is still running');

    my $r = await1($db->query("SELECT v FROM t WHERE id = 1"));
    is($r->{rows}[0][0], 'parent', 'the parent can still query');
}

# ---- no response theft under concurrent children ----------------------------
# Each child writes a row only it knows, then reads it back. If two processes
# were sharing a socketpair, a child would sometimes receive a sibling's row.
{
    await1($db->do("INSERT INTO t (id, v) VALUES (?, ?)", $_ + 10, "child$_"))
        for 1 .. 4;

    my @kids;
    for my $i (1 .. 4) {
        my $pid = open my $rd, '-|';
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            my $got = '';
            for (1 .. 5) {
                my $r = await1($db->query("SELECT v FROM t WHERE id = ?", $i + 10));
                $got = $r->{rows}[0][0] // '(undef)';
                last if $got ne "child$i";
            }
            print $got, "\n";
            exit 0;
        }
        push @kids, [ $i, $rd ];
    }
    my @wrong;
    for my $k (@kids) {
        my ($i, $rd) = @$k;
        chomp(my $got = <$rd> // '');
        close $rd;
        push @wrong, "child$i got '$got'" if $got ne "child$i";
    }
    is_deeply(\@wrong, [], 'four concurrent children each saw only their own row')
        or diag explain \@wrong;
}

$db->disconnect;
done_testing;
