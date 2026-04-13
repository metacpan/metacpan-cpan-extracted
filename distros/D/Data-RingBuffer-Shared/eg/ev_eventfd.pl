#!/usr/bin/env perl
# EV event loop: writer pushes values + notifies, reader reacts on EV::io
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use EV;
use POSIX qw(_exit);
use Data::RingBuffer::Shared;
$| = 1;

my $ring = Data::RingBuffer::Shared::Int->new(undef, 50);
my $efd = $ring->eventfd;

my ($io_w, $stop_w);
my $received = 0;
$io_w = EV::io $efd, EV::READ, sub {
    $ring->eventfd_consume;
    while ($received < $ring->count) {
        my $val = $ring->read_seq($received);
        printf "[read] seq=%d val=%d\n", $received, $val if defined $val;
        $received++;
    }
};

my $pid = fork // die;
if ($pid == 0) {
    for my $i (1..8) {
        $ring->write($i * 100);
        $ring->notify;
        select(undef, undef, undef, 0.1);
    }
    _exit(0);
}

$stop_w = EV::timer 1.5, 0, sub { undef $io_w; undef $stop_w };
EV::run;
waitpid($pid, 0);
printf "done, received=%d\n", $received;
