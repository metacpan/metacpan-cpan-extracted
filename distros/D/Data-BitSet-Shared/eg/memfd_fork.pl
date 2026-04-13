#!/usr/bin/env perl
# memfd: parent creates bitset, child reads via inherited fd
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::BitSet::Shared;
$| = 1;

my $bs = Data::BitSet::Shared->new_memfd("demo", 64);
my $fd = $bs->memfd;

$bs->set(0);
$bs->set(31);
$bs->set(63);
printf "parent: set bits 0, 31, 63 (count=%d, fd=%d)\n", $bs->count, $fd;

my $pid = fork // die;
if ($pid == 0) {
    my $child = Data::BitSet::Shared->new_from_fd($fd);
    printf "child:  count=%d, test(31)=%d\n", $child->count, $child->test(31);
    $child->set(15);
    printf "child:  set bit 15, count=%d\n", $child->count;
    _exit(0);
}
waitpid($pid, 0);
printf "parent: count=%d (sees child's bit 15: %d)\n", $bs->count, $bs->test(15);
