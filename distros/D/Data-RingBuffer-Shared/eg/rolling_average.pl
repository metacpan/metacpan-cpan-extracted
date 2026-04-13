#!/usr/bin/env perl
# Rolling average: writer pushes measurements, reader computes moving average
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);
use Data::RingBuffer::Shared;
$| = 1;

my $window = 20;
my $ring = Data::RingBuffer::Shared::F64->new(undef, $window);

# writer: simulate noisy temperature sensor
my $pid = fork // die;
if ($pid == 0) {
    for my $i (1..100) {
        my $temp = 22.0 + sin($i * 0.1) * 3 + (rand() - 0.5) * 2;
        $ring->write($temp);
        sleep 0.01;
    }
    _exit(0);
}

# reader: compute moving average periodically
for (1..8) {
    sleep 0.15;
    my @vals = $ring->to_list;
    next unless @vals;
    my $sum = 0; $sum += $_ for @vals;
    my $avg = $sum / @vals;
    printf "  window=%2d avg=%.2f°C (latest=%.2f)\n",
        scalar @vals, $avg, $ring->latest;
}
waitpid($pid, 0);

my @final = $ring->to_list;
my $sum = 0; $sum += $_ for @final;
printf "\nfinal: %d samples, avg=%.2f°C\n", scalar @final, $sum / @final;
