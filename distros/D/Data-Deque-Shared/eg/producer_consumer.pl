#!/usr/bin/env perl
# Producer-consumer: producer push_back, consumer pop_front (FIFO)
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::Deque::Shared;
$| = 1;

my $n = shift || 1000;
my $dq = Data::Deque::Shared::Int->new(undef, 64);

my $pid = fork // die;
if ($pid == 0) {
    for (1..$n) { $dq->push_back_wait($_, 5.0) }
    $dq->push_back_wait(-1, 5.0);  # sentinel
    _exit(0);
}

my $t0 = time;
my $count = 0;
while (1) {
    my $v = $dq->pop_front_wait(5.0);
    last unless defined $v;
    last if $v == -1;
    $count++;
}
my $dt = time - $t0;
waitpid($pid, 0);

printf "%d items in %.3fs (%.0f items/s)\n", $count, $dt, $count / $dt;
