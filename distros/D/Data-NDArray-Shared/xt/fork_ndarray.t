use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::NDArray::Shared;

# An anonymous MAP_SHARED f64 array inherited across fork: each child fills a
# disjoint flat range with set_flat, contending on the shared data buffer under
# the rwlock. Because every write is performed while holding the write lock, the
# writes serialize and the final array is DETERMINISTIC regardless of how the
# children interleave: every element ends up holding its own flat index, so the
# array is exactly (0, 1, 2, ..., N-1).

my $kids = 4;
my $N    = 4000;
my $band = $N / $kids;          # 1000 elements per child (exact)
die "N must divide evenly by kids" if $N % $kids;

my $a = Data::NDArray::Shared->new(undef, "f64", $N);

my @pids;
for my $k (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $base = $k * $band;                  # disjoint band [base, base+band)
        $a->set_flat($base + $_, $base + $_) for 0 .. $band - 1;
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

# Every element holds its own flat index.
my $bad = 0;
$bad++ for grep { $a->get_flat($_) != $_ } 0 .. $N - 1;
is $bad, 0, "cross-process: every element holds its flat index (all $kids bands written)";

# The sum is the triangular number 0 + 1 + ... + (N-1).
my $expected = $N * ($N - 1) / 2;
is $a->sum, $expected, "cross-process: sum == N*(N-1)/2 == $expected";

done_testing;
