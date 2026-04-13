#!/usr/bin/env perl
# Metrics ring: workers write measurements, reader displays rolling window
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);
use Data::RingBuffer::Shared;
$| = 1;

my $ring = Data::RingBuffer::Shared::F64->new(undef, 100);

# workers write latency measurements
my @pids;
for my $w (1..3) {
    my $pid = fork // die;
    if ($pid == 0) {
        for (1..50) {
            $ring->write(rand(100) + $w * 10);
            sleep 0.01;
        }
        _exit(0);
    }
    push @pids, $pid;
}

# reader: display rolling stats every 0.2s
for (1..5) {
    sleep 0.2;
    my @vals = $ring->to_list;
    next unless @vals;
    my $sum = 0; $sum += $_ for @vals;
    my $avg = $sum / @vals;
    my $min = (sort { $a <=> $b } @vals)[0];
    my $max = (sort { $b <=> $a } @vals)[0];
    printf "  n=%3d avg=%.1f min=%.1f max=%.1f\n", scalar @vals, $avg, $min, $max;
}
waitpid($_, 0) for @pids;

my $s = $ring->stats;
printf "\nwrites=%d overwrites=%d\n", $s->{writes}, $s->{overwrites};
