#!/usr/bin/env perl
# memfd: create deque, child opens via fd, both push/pop
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::Deque::Shared;
$| = 1;

my $dq = Data::Deque::Shared::Int->new_memfd("demo_dq", 20);
my $fd = $dq->memfd;
printf "parent: memfd=%d, capacity=%d\n", $fd, $dq->capacity;

$dq->push_back(1);
$dq->push_back(2);
$dq->push_back(3);

my $pid = fork // die;
if ($pid == 0) {
    my $child = Data::Deque::Shared::Int->new_from_fd($fd);
    printf "child:  front=%d (reads parent data)\n", $child->pop_front;
    $child->push_front(0);
    printf "child:  pushed 0 at front\n";
    _exit(0);
}
waitpid($pid, 0);

printf "parent: drain (FIFO): ";
printf "%d ", $dq->pop_front while !$dq->is_empty;
printf "\n";
