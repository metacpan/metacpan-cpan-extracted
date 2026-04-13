#!/usr/bin/env perl
# memfd: create stack, pass fd to child via fork, child pushes, parent pops
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::Stack::Shared;
$| = 1;

my $stk = Data::Stack::Shared::Int->new_memfd("demo_stk", 20);
my $fd = $stk->memfd;
printf "parent: created memfd stack (fd=%d)\n", $fd;

$stk->push(100);
$stk->push(200);

my $pid = fork // die;
if ($pid == 0) {
    my $child = Data::Stack::Shared::Int->new_from_fd($fd);
    printf "child:  peek=%d (sees parent data)\n", $child->peek;
    $child->push(300);
    $child->push(400);
    printf "child:  pushed 300, 400\n";
    _exit(0);
}
waitpid($pid, 0);

printf "parent: stack size=%d\n", $stk->size;
printf "parent: pop order (LIFO): ";
printf "%d ", $stk->pop while !$stk->is_empty;
printf "\n";
