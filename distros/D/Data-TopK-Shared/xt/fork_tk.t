use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::TopK::Shared;

# An anonymous MAP_SHARED top-k summary inherited across fork: children each feed
# a stream in which one shared heavy hitter dominates while every child also
# injects its own disjoint noise, all contending under the rwlock.  The heavy
# hitter must survive with an exact total count (it is never the eviction
# victim), and `seen` must equal every observation with none lost to races.
my $kids = 4;
my $per  = 30_000;                   # HEAVY adds per child
my $noise_per = 20_000;              # distinct noise adds per child
my $tk = Data::TopK::Shared->new(undef, 16);

my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        for my $i (1 .. $per) {
            $tk->add("HEAVY");
            $tk->add("c$c-noise-$i") if $i <= $noise_per;   # disjoint per-child noise
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

is $tk->seen, $kids * ($per + $noise_per), 'seen == every observation (no lost updates)';
is $tk->estimate("HEAVY"), $kids * $per, 'heavy hitter total is exact across all children';
is $tk->error("HEAVY"), 0, 'heavy hitter never evicted (zero error)';
is +($tk->top(1))[0]{key}, "HEAVY", 'heavy hitter ranks #1 in the merged summary';

done_testing;
