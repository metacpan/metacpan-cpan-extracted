#!/usr/bin/env perl
# memfd: parent creates heap, child pops via inherited fd
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::Heap::Shared;
$| = 1;

my $h = Data::Heap::Shared->new_memfd("demo", 10);
my $fd = $h->memfd;

$h->push(3, 30);
$h->push(1, 10);
$h->push(2, 20);
printf "parent: pushed 3 items, memfd=%d\n", $fd;

my $pid = fork // die;
if ($pid == 0) {
    my $child = Data::Heap::Shared->new_from_fd($fd);
    while (!$child->is_empty) {
        my ($p, $v) = $child->pop;
        printf "child:  pop pri=%d val=%d\n", $p, $v;
    }
    _exit(0);
}
waitpid($pid, 0);
printf "parent: heap size=%d\n", $h->size;
