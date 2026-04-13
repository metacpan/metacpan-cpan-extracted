#!/usr/bin/env perl
# Overwrite detection: reader tracks its position, detects when it fell behind
#
# Pattern: fast writer fills ring, slow reader uses read_seq and detects
# when entries were overwritten (read_seq returns undef for overwritten seqs).
# The reader can compute how many entries it missed.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);
use Data::RingBuffer::Shared;
$| = 1;

my $ring = Data::RingBuffer::Shared::Int->new(undef, 20);

# fast writer
my $pid = fork // die;
if ($pid == 0) {
    $ring->write($_) for 1..100;
    _exit(0);
}
waitpid($pid, 0);

# slow reader: try to read all 100 entries by sequence
my $read = 0;
my $missed = 0;
for my $seq (0..99) {
    my $val = $ring->read_seq($seq);
    if (defined $val) {
        $read++;
    } else {
        $missed++;
    }
}

printf "total written: %d\n", $ring->count;
printf "ring capacity: %d\n", $ring->capacity;
printf "read ok:       %d\n", $read;
printf "overwritten:   %d\n", $missed;
printf "oldest valid:  seq %d (head=%d, cap=%d)\n",
    $ring->head - $ring->capacity, $ring->head, $ring->capacity;

# real-time pattern: reader maintains cursor, catches up
$ring->clear;
$pid = fork // die;
if ($pid == 0) {
    for my $i (1..50) {
        $ring->write($i);
        sleep 0.005;
    }
    _exit(0);
}

my $cursor = 0;
my $caught = 0;
my $gaps = 0;
for (1..10) {
    sleep 0.03;
    my $head = $ring->head;
    my $oldest = $head > $ring->capacity ? $head - $ring->capacity : 0;
    if ($cursor < $oldest) {
        $gaps++;
        printf "  gap: cursor=%d oldest=%d (missed %d)\n",
            $cursor, $oldest, $oldest - $cursor;
        $cursor = $oldest;
    }
    while ($cursor < $head) {
        my $val = $ring->read_seq($cursor);
        $caught++ if defined $val;
        $cursor++;
    }
}
waitpid($pid, 0);
printf "\nreal-time: caught=%d gaps=%d\n", $caught, $gaps;
