use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::RadixTree::Shared;

# An anonymous MAP_SHARED radix tree inherited across fork: each child inserts
# its own disjoint band of keys ("c$k-$i") into the shared node pool/arena,
# contending under the rwlock. Because every insert is performed while holding
# the write lock, the inserts serialize and the final tree is DETERMINISTIC
# regardless of how the children interleave: K children each insert PER_CHILD
# distinct keys, so count == K * PER_CHILD afterwards and a sample from every
# child's band looks up to its value.

my $kids      = 4;
my $per_child = 2000;
my $total     = $kids * $per_child;

# Generous capacity. Worst case each key is its own leaf (2 nodes) but shared
# "c$k-" prefixes collapse; still size with plenty of headroom. Labels are short
# ("c0-1".."c3-2000"), ~8 bytes each -> arena well under 256 KiB.
my $node_cap  = 4 * $total + 16;
my $arena_cap = 16 * $total + 4096;

my $t = Data::RadixTree::Shared->new(undef, $node_cap, $arena_cap);

my @pids;
for my $k (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        for my $i (1 .. $per_child) {
            $t->insert("c$k-$i", $k * 1_000_000 + $i);   # value encodes child + index
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

# Every insert serialized under the write lock -> exactly K*PER_CHILD keys.
is $t->count, $total,
   sprintf('cross-process: count == %d (%d children x %d keys)', $total, $kids, $per_child);

# Sample a handful of keys from each child's band and confirm the values.
my $bad = 0;
for my $k (0 .. $kids - 1) {
    for my $i (1, 2, 17, 500, 999, 1000, 1999, $per_child) {
        my $got = $t->lookup("c$k-$i");
        $bad++ unless defined($got) && $got == $k * 1_000_000 + $i;
    }
}
is $bad, 0, 'cross-process: a sample from every child band looks up to its value';

# A key that no child inserted is absent.
ok !$t->exists("c9-1"), 'cross-process: a never-inserted key is absent';

# stats are self-consistent after the concurrent load.
my $st = $t->stats;
cmp_ok $st->{nodes_used}, '<=', $st->{nodes_capacity}, 'nodes_used within capacity';
cmp_ok $st->{arena_used}, '<=', $st->{arena_capacity}, 'arena_used within capacity';
is $st->{keys}, $total, 'stats keys == total inserted';

done_testing;
