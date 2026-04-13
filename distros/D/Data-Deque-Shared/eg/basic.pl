#!/usr/bin/env perl
# Basic deque: FIFO, LIFO, and mixed push/pop at both ends
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Deque::Shared;
$| = 1;

my $dq = Data::Deque::Shared::Int->new(undef, 10);

# FIFO: push_back + pop_front
$dq->push_back(1);
$dq->push_back(2);
$dq->push_back(3);
printf "FIFO: %d %d %d\n", $dq->pop_front, $dq->pop_front, $dq->pop_front;

# LIFO: push_back + pop_back
$dq->push_back(1);
$dq->push_back(2);
$dq->push_back(3);
printf "LIFO: %d %d %d\n", $dq->pop_back, $dq->pop_back, $dq->pop_back;

# mixed: insert at both ends
$dq->push_back(2);
$dq->push_front(1);
$dq->push_back(3);
$dq->push_front(0);
# order: 0 1 2 3
printf "mixed: %d %d %d %d\n",
    $dq->pop_front, $dq->pop_front, $dq->pop_front, $dq->pop_front;
