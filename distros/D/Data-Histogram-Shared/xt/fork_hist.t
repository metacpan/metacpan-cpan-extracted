use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::Histogram::Shared;

# An anonymous MAP_SHARED histogram inherited across fork: children record
# disjoint value ranges concurrently (contending on the shared counts array
# under the rwlock), and the parent must see every recording reflected in the
# grand total afterwards. This is the cross-process accumulation guarantee the
# module exists for.
my $kids = 4;
my $per  = 5_000;
my $h = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);

my @pids;
for my $k (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $base = 1 + $k * 100_000;          # disjoint value range per child
        $h->record($base + $_) for 1 .. $per;
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

# Every child's $per single records must be reflected in the total.
is $h->total_count, $kids * $per,
   sprintf('cross-process: total_count == %d (all %d records by %d children accounted for)',
           $kids * $per, $kids * $per, $kids);

# A specific value one child recorded must be present, and percentiles sane.
cmp_ok $h->count_at_value(200_050), '>=', 1,
   'cross-process: a value recorded by a child is present in the parent';
cmp_ok $h->value_at_percentile(50), '>=', $h->min,
   'cross-process: median is at least the min';
cmp_ok $h->value_at_percentile(99), '<=', $h->max,
   'cross-process: p99 is at most the max';

done_testing;
