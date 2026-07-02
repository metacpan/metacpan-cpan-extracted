#!/usr/bin/env perl
# Cross-process: parent builds the array via memfd, child opens the same fd,
# both write into the one shared mapping.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::NDArray::Shared;
$| = 1;

# An 8-element i64 array in a memfd; the fd is inherited across fork.
my $s = Data::NDArray::Shared->new_memfd('ndarray-demo', "i64", 8);
my $fd = $s->memfd;

# Parent writes the lower half: cells 0..3 = 10, 20, 30, 40.
$s->set_flat($_, ($_ + 1) * 10) for 0 .. 3;
printf "parent: wrote cells 0..3, sum=%d fd=%d\n", $s->sum, $fd;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Child: the memfd fd is inherited across fork (CLOEXEC only closes on exec).
    my $c = Data::NDArray::Shared->new_from_fd($fd);
    printf "child:  sees parent's array: [ %s ]\n", join(', ', @{$c->to_list});
    # Child writes the upper half: cells 4..7 = 50, 60, 70, 80.
    $c->set_flat($_, ($_ + 1) * 10) for 4 .. 7;
    # ...then bumps every element by 1 in place (touches the parent's cells too).
    $c->add_scalar(1);
    printf "child:  wrote cells 4..7 and add_scalar(1), sum now=%d\n", $c->sum;
    _exit(0);
}
waitpid($pid, 0);

# The parent sees the child's writes in the same shared mapping.
printf "parent: after child, array = [ %s ]\n", join(', ', @{$s->to_list});
printf "parent: sum=%d  (== 11+21+31+41+51+61+71+81)\n", $s->sum;
