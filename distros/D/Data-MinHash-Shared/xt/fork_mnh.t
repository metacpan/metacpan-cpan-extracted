use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::MinHash::Shared;

# An anonymous MAP_SHARED MinHash sketch inherited across fork: children each
# fold a disjoint slice of one big set into the shared registers concurrently
# (contending under the rwlock).  Because a register only ever moves down to a
# smaller value, the folds commute -- the collaboratively-built sketch must
# match a single process folding the whole set (similarity ~ 1.0), no matter how
# the adds interleaved.
my $k    = 512;
my $kids = 4;
my $per  = 25_000;

my $shared = Data::MinHash::Shared->new(undef, $k);
my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $lo = $c * $per + 1;
        $shared->add("e$_") for $lo .. $lo + $per - 1;   # disjoint slice
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

my $ref = Data::MinHash::Shared->new(undef, $k);
$ref->add("e$_") for 1 .. $kids * $per;

is $shared->size, $k, "sketch has k=$k registers";
is $shared->filled, $k, 'every register filled after the concurrent folds';
my $sim = $shared->similarity($ref);
cmp_ok $sim, '==', 1.0,
    "concurrent folds commute: shared sketch identical to single-process reference (sim=$sim)";

done_testing;
