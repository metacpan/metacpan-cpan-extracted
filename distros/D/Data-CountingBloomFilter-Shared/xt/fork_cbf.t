use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::CountingBloomFilter::Shared;

# An anonymous MAP_SHARED counting Bloom filter inherited across fork: children
# add disjoint item ranges concurrently (contending on the shared counter array
# under the rwlock), and the parent must find every child's items present after.
# This is the cross-process no-false-negatives guarantee the module exists for.
my $kids = 4;
my $per  = 25_000;
my $cap  = $kids * $per;
my $bf = Data::CountingBloomFilter::Shared->new(undef, $cap, 0.01);

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

# Cross-process COUNTING and REMOVAL on a fresh shared filter: every child adds
# the same key M times, so the 4-bit counters accumulate all children's
# increments under the rwlock. With kids*M below the 15 ceiling and a lightly
# loaded filter, count_of equals the exact total; removing every contribution
# then makes the item absent.
{
    my $M   = 3;                         # kids*M = 12 < 15, no saturation
    my $key = "shared-counted";
    my $cf  = Data::CountingBloomFilter::Shared->new(undef, 1000, 0.01);   # before fork
    my @cp;
    for my $k (0 .. $kids - 1) {
        my $pid = fork // die "fork: $!";
        if (!$pid) { $cf->add($key) for 1 .. $M; _exit(0); }
        push @cp, $pid;
    }
    waitpid $_, 0 for @cp;
    is $cf->count_of($key), $kids * $M,
       "cross-process count_of == ${\ ($kids * $M) } (every child incremented the shared counters)";
    $cf->remove($key) for 1 .. $kids * $M;
    ok !$cf->contains($key),
       'cross-process: item absent after removing every counted contribution';
}

done_testing;
