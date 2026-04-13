#!/usr/bin/env perl
# K-way merge: each worker produces sorted sequences, heap merges them in order
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::Heap::Shared;
$| = 1;

my $K = shift || 4;  # number of sorted streams
my $N = shift || 10;  # items per stream

my $heap = Data::Heap::Shared->new(undef, $K * $N + $K);

# each worker pushes a sorted sequence: stream_id * 1000 + offset as value,
# offset as priority (so items from all streams interleave by offset)
my @pids;
for my $s (1..$K) {
    my $pid = fork // die;
    if ($pid == 0) {
        for my $i (1..$N) {
            $heap->push($i, $s * 1000 + $i);
            select(undef, undef, undef, rand(0.01));
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;

# drain in priority order — items from all streams merge by offset
printf "merged %d items from %d streams:\n", $heap->size, $K;
my $prev_pri = -1;
my $ok = 1;
while (!$heap->is_empty) {
    my ($pri, $val) = $heap->pop;
    my $stream = int($val / 1000);
    my $item   = $val % 1000;
    printf "  pri=%2d stream=%d item=%d\n", $pri, $stream, $item if $pri <= 3;
    $ok = 0 if $pri < $prev_pri;
    $prev_pri = $pri;
}
printf "  ... (showing first 3 priority levels)\n" if $N > 3;
printf "order correct: %s\n", $ok ? "yes" : "NO";
