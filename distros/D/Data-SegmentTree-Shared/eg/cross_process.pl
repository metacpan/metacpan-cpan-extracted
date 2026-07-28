#!/usr/bin/env perl
# Cross-process: parent builds a segment tree via memfd, children open the same
# fd and each range_add over their own disjoint band of positions concurrently.
# Because range_add is commutative, the parent then reads a consistent array --
# a fleet of workers maintaining one shared range-updatable array.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::SegmentTree::Shared;
$| = 1;

my $n    = 4000;
my $kids = 4;
my $band = $n / $kids;

my $st = Data::SegmentTree::Shared->new_memfd('segtree-demo', $n);
my $fd = $st->memfd;
printf "parent: created segment tree n=%d via memfd fd=%d\n", $st->size, $fd;

my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $child = Data::SegmentTree::Shared->new_from_fd($fd);
        my $lo = $c * $band;
        my $hi = $lo + $band - 1;
        # each child applies many small range_adds inside its own band
        $child->range_add($lo, $hi, 1) for 1 .. 10_000;         # whole band += 10000
        $child->range_add($lo, $lo + $band / 2 - 1, 5) for 1 .. 1000;  # first half += 5000
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

printf "parent: after %d children:\n", $kids;
printf "  sum over all       = %d\n", $st->sum(0, $n - 1);
printf "  min over all       = %d\n", $st->min(0, $n - 1);
printf "  max over all       = %d\n", $st->max(0, $n - 1);
for my $c (0 .. $kids - 1) {
    my $lo = $c * $band;
    my $q = $st->query($lo, $lo + $band - 1);
    printf "  band %d [%4d-%4d]: min=%d max=%d\n", $c, $lo, $lo + $band - 1, $q->{min}, $q->{max};
}
