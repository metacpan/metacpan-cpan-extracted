use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::DisjointSet::Shared;

# An anonymous MAP_SHARED disjoint-set inherited across fork: each child chains
# its own disjoint band of elements into a single set, contending on the shared
# parent/size arrays under the rwlock. Because every union is performed while
# holding the write lock, the unions serialize and the final partition is
# DETERMINISTIC regardless of how the children interleave: each of the K bands
# collapses to exactly one set, so num_sets == K afterwards.

my $kids = 4;
my $N    = 10_000;
my $band = $N / $kids;          # 2500 elements per child (exact)
die "N must divide evenly by kids" if $N % $kids;

my $d = Data::DisjointSet::Shared->new(undef, $N);

my @pids;
for my $k (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $base = $k * $band;                       # disjoint band [base, base+band)
        # chain the whole band into one set: (base,base+1),(base+1,base+2),...
        $d->union($base + $_, $base + $_ + 1) for 0 .. $band - 2;
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

# K bands, each fully collapsed to one set -> exactly K disjoint sets remain.
is $d->num_sets, $kids,
   sprintf('cross-process: num_sets == %d (each of %d bands collapsed to one set)', $kids, $kids);

# Within-band connectivity holds; across-band does not.
my $within_bad = 0;
for my $k (0 .. $kids - 1) {
    my $base = $k * $band;
    $within_bad++ unless $d->connected($base, $base + $band - 1);   # band endpoints joined
    $within_bad++ unless $d->set_size($base) == $band;              # band set has 'band' members
}
is $within_bad, 0, 'cross-process: every band is fully connected with the expected size';

my $across_bad = 0;
for my $k (0 .. $kids - 2) {
    my $a = $k * $band;
    my $b = ($k + 1) * $band;
    $across_bad++ if $d->connected($a, $b);     # different bands stay disjoint
}
is $across_bad, 0, 'cross-process: distinct bands remain disjoint';

done_testing;
