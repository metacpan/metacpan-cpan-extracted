use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::RoaringBitmap::Shared;

# An anonymous MAP_SHARED Roaring bitmap inherited across fork: each child adds
# its own disjoint band of integers into the shared bucket table / container
# pool, contending under the rwlock. Because every add is performed while holding
# the write lock, the adds serialize and the final bitmap is DETERMINISTIC
# regardless of how the children interleave: K children each add PER_CHILD
# distinct integers, so cardinality == K * PER_CHILD afterwards and a sample from
# every child's band is a member.

my $kids      = 4;
my $per_child = 5000;
my $total     = $kids * $per_child;

# Each child k owns the range [k * BAND, k * BAND + per_child). With BAND large
# enough to cross 65536, every child spans several buckets; generous container
# capacity covers the worst case (one container per touched bucket).
my $BAND = 1_000_000;

my $a = Data::RoaringBitmap::Shared->new(undef, 65536);

my @pids;
for my $k (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $base = $k * $BAND;
        $a->add($base + $_) for 0 .. $per_child - 1;
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

# Every add serialized under the write lock -> exactly K*PER_CHILD elements.
is $a->cardinality, $total,
   sprintf('cross-process: cardinality == %d (%d children x %d ints)', $total, $kids, $per_child);

# Sample a handful from each child's band and confirm membership.
my $bad = 0;
for my $k (0 .. $kids - 1) {
    my $base = $k * $BAND;
    for my $off (0, 1, 17, 500, 2500, 4999) {
        $bad++ unless $a->contains($base + $off);
    }
}
is $bad, 0, 'cross-process: a sample from every child band is a member';

# A value no child added is absent.
ok !$a->contains($kids * $BAND + 1), 'cross-process: a never-added value is absent';

# min / max span the full range the children populated.
is $a->min, 0, 'cross-process: min is child 0 band start';
is $a->max, ($kids - 1) * $BAND + $per_child - 1, 'cross-process: max is the last child band end';

# stats are self-consistent after the concurrent load.
my $st = $a->stats;
cmp_ok $st->{containers_used}, '<=', $st->{containers_capacity}, 'containers_used within capacity';
is $st->{cardinality}, $total, 'stats cardinality == total added';

done_testing;
