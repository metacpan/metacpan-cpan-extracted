use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::SegmentTree::Shared;

# An anonymous MAP_SHARED segment tree inherited across fork: children each apply
# many range_adds over the WHOLE array concurrently (heavy contention under the
# rwlock).  range_add is commutative, so the final array must equal the sum of
# every child's contributions -- each position bumped by (kids * per) exactly.
my $n    = 2000;
my $kids = 4;
my $per  = 5_000;
my $st = Data::SegmentTree::Shared->new(undef, $n);

my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $st->range_add(0, $n - 1, 1) for 1 .. $per;   # whole array += 1, $per times
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

my $expected = $kids * $per;
is $st->min(0, $n - 1), $expected, "every position bumped exactly kids*per ($expected): min";
is $st->max(0, $n - 1), $expected, "every position bumped exactly kids*per: max (no lost updates)";
is $st->sum(0, $n - 1), $expected * $n, 'total sum consistent across all children';
is $st->get(0), $expected, 'spot-check position 0';
is $st->get($n - 1), $expected, 'spot-check the last position';

done_testing;
