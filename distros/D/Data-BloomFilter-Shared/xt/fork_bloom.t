use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::BloomFilter::Shared;

# An anonymous MAP_SHARED Bloom filter inherited across fork: children add
# disjoint item ranges concurrently (contending on the shared bit array under
# the rwlock), and the parent must find every child's items present afterwards.
# This is the cross-process no-false-negatives guarantee the module exists for.
my $kids = 4;
my $per  = 25_000;
my $cap  = $kids * $per;
my $bf = Data::BloomFilter::Shared->new(undef, $cap, 0.01);

my @pids;
for my $k (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $bf->add("p$k-$_") for 1 .. $per;   # disjoint key range per child
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

# every item every child added must be contained -- no false negatives across
# processes, regardless of concurrent contention on the shared bit array.
my $miss = 0;
for my $k (0 .. $kids - 1) {
    for my $i (1 .. $per) {
        $bf->contains("p$k-$i") or $miss++;
    }
}
is $miss, 0,
   sprintf('cross-process: all %d items added by %d children are contained (no false negatives)',
           $cap, $kids);

done_testing;
