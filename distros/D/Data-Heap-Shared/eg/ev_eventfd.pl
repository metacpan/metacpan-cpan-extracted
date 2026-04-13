#!/usr/bin/env perl
# EV event loop: producer pushes prioritized items, consumer pops on wakeup
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use EV;
use POSIX qw(_exit);
use Data::Heap::Shared;
$| = 1;

my $heap = Data::Heap::Shared->new(undef, 50);
my $efd = $heap->eventfd;

my ($io_w, $stop_w);
my $consumed = 0;
$io_w = EV::io $efd, EV::READ, sub {
    $heap->eventfd_consume;
    while (!$heap->is_empty) {
        my ($pri, $val) = $heap->pop;
        $consumed++;
        printf "[pop] pri=%d val=%d\n", $pri, $val;
    }
};

my $pid = fork // die;
if ($pid == 0) {
    for my $i (1..8) {
        $heap->push(9 - $i, $i * 100);  # decreasing priority
        $heap->notify;
        select(undef, undef, undef, 0.1);
    }
    _exit(0);
}

$stop_w = EV::timer 1.5, 0, sub { undef $io_w; undef $stop_w };
EV::run;
waitpid($pid, 0);
printf "done, consumed=%d\n", $consumed;
