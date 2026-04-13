#!/usr/bin/env perl
# Sensor tail: writer produces data, reader tails new values via wait_for
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);
use Data::RingBuffer::Shared;
$| = 1;

my $ring = Data::RingBuffer::Shared::F64->new(undef, 50);

my $pid = fork // die;
if ($pid == 0) {
    for my $i (1..20) {
        $ring->write(sin($i * 0.3) * 100);
        sleep 0.05;
    }
    _exit(0);
}

my $seen = 0;
while ($seen < 20) {
    $ring->wait_for($seen, 1.0);
    my $new_count = $ring->count;
    while ($seen < $new_count) {
        my $val = $ring->read_seq($seen);
        printf "  seq %2d: %.2f\n", $seen, $val if defined $val;
        $seen++;
    }
}
waitpid($pid, 0);
printf "done: tailed %d values\n", $seen;
