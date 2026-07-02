use strict; use warnings; use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};

use Data::SpatialHash::Shared;

# Many processes concurrently insert/move/remove/query a shared map; afterwards
# verify global integrity: every live entry is still reachable and the bucket
# chains contain exactly `count` entries (no orphans, no cycle).

my $PROCS = $ENV{MPMC_PROCS} || 6;
my $OPS   = $ENV{MPMC_OPS}   || 20_000;
my $CAP   = $PROCS * 2000;
my $s = Data::SpatialHash::Shared->new(undef, $CAP, 0, 1.0);

my @pids;
for my $w (0 .. $PROCS - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        srand($w * 7919 + $$);
        my @mine;
        for my $i (1 .. $OPS) {
            my $r = rand();
            if ($r < 0.50 || !@mine) {
                my $h = $s->insert(rand()*500, rand()*500, $w * 1_000_000 + $i);
                push @mine, $h if defined $h;
            } elsif ($r < 0.70) {
                $s->move($mine[int rand @mine], rand()*500, rand()*500);
            } elsif ($r < 0.85) {
                $s->query_radius(rand()*500, rand()*500, 5);
            } else {
                $s->remove(splice @mine, int(rand @mine), 1);
            }
        }
        _exit(0);
    }
    push @pids, $pid;
}
my $fails = 0;
waitpid($_, 0), ($fails += ($? != 0)) for @pids;

is $fails, 0, 'no worker crashed under concurrent insert/move/remove/query';
cmp_ok $s->count, '<=', $CAP, 'count within capacity: ' . $s->count;
my @all = $s->query_aabb(-1, -1, 501, 501);
is scalar(@all), $s->count, 'every live entry reachable (full-extent aabb count == count)';
my $st = $s->stats;
is $st->{count}, $s->count, 'stats count consistent';
ok defined $st->{max_chain}, 'chain walk terminates (no cycle); max_chain=' . $st->{max_chain};

done_testing;
