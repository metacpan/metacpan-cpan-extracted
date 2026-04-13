#!/usr/bin/env perl
# memfd: parent creates ring, child reads via inherited fd
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::RingBuffer::Shared;
$| = 1;

my $ring = Data::RingBuffer::Shared::Int->new_memfd("demo", 10);
my $fd = $ring->memfd;

$ring->write(100);
$ring->write(200);
$ring->write(300);
printf "parent: wrote 3 values, fd=%d\n", $fd;

my $pid = fork // die;
if ($pid == 0) {
    my $child = Data::RingBuffer::Shared::Int->new_from_fd($fd);
    printf "child:  size=%d latest=%d\n", $child->size, $child->latest;
    $child->write(400);
    printf "child:  wrote 400\n";
    _exit(0);
}
waitpid($pid, 0);
printf "parent: latest=%d (child's write visible)\n", $ring->latest;
printf "parent: to_list = %s\n", join(' ', $ring->to_list);
