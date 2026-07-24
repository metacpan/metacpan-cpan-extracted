use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::DDSketch::Shared;

# An anonymous MAP_SHARED sketch inherited across fork: children each feed a
# disjoint slice of 1..N concurrently (contending under the rwlock).  Bucket
# increments are commutative, so the collaboratively-built sketch must match a
# single process feeding all of 1..N -- identical count, min, max, and every
# quantile -- and `count` must equal every observation with none lost to races.
my $kids = 4;
my $per  = 25_000;
my $N    = $kids * $per;

my $shared = Data::DDSketch::Shared->new(undef, 0.01, 2048);
my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $lo = $c * $per + 1;
        $shared->add($_) for $lo .. $lo + $per - 1;   # disjoint slice
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

my $ref = Data::DDSketch::Shared->new(undef, 0.01, 2048);
$ref->add($_) for 1 .. $N;

is $shared->count, $N, 'count == every observation (no lost updates)';
is $shared->min, 1, 'min correct after concurrent feed';
is $shared->max, $N, 'max correct after concurrent feed';
is $shared->quantile(0.5), $ref->quantile(0.5), 'median matches a single-process reference';
is $shared->quantile(0.99), $ref->quantile(0.99), 'p99 matches a single-process reference';

done_testing;
