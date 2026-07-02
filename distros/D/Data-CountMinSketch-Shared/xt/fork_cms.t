use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::CountMinSketch::Shared;

# An anonymous MAP_SHARED Count-Min sketch inherited across fork: children add
# disjoint item streams concurrently (contending on the shared counter matrix
# under the rwlock), and the parent must see every increment reflected in the
# grand total afterwards. This is the cross-process accumulation guarantee the
# module exists for.
my $kids = 4;
my $per  = 5_000;
my $cms = Data::CountMinSketch::Shared->new(undef, 0.001, 0.001);

my @pids;
for my $k (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $cms->add("p$k-$_") for 1 .. $per;   # disjoint key range per child, each once
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

# Every child's $per single-increment adds must be reflected in the total.
is $cms->total, $kids * $per,
   sprintf('cross-process: total == %d (all %d adds by %d children accounted for)',
           $kids * $per, $kids * $per, $kids);

# And a specific key one child added must estimate >= 1 (no lost increment).
cmp_ok $cms->estimate("p2-100"), '>=', 1,
   'cross-process: a key added by a child estimates >= 1 in the parent';

done_testing;
