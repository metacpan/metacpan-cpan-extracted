#!/usr/bin/env perl
# EV event loop: producer push_back with notify, consumer pops on EV::io wakeup
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use EV;
use POSIX qw(_exit);
use Data::Deque::Shared;
$| = 1;

my $dq = Data::Deque::Shared::Int->new(undef, 50);
my $efd = $dq->eventfd;

my ($io_w, $stop_w);
my $consumed = 0;
$io_w = EV::io $efd, EV::READ, sub {
    $dq->eventfd_consume;
    while (!$dq->is_empty) {
        my $v = $dq->pop_front // last;
        $consumed++;
        printf "[consumer] %d (size=%d)\n", $v, $dq->size;
    }
};

my $pid = fork // die;
if ($pid == 0) {
    for my $b (1..5) {
        $dq->push_back($b * 100 + $_) for 1..4;
        $dq->notify;
        select(undef, undef, undef, 0.15);
    }
    _exit(0);
}

$stop_w = EV::timer 1.5, 0, sub { undef $io_w; undef $stop_w };
EV::run;
waitpid($pid, 0);
printf "done, consumed=%d, size=%d\n", $consumed, $dq->size;
