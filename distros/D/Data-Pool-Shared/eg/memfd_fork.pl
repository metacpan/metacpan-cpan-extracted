#!/usr/bin/env perl
# memfd + fork: create pool with memfd, child opens via fd

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::Pool::Shared;
$| = 1;

my $pool = Data::Pool::Shared::I64->new_memfd("demo", 10);
my $fd = $pool->memfd;
printf "parent: created memfd pool (fd=%d, capacity=%d)\n", $fd, $pool->capacity;

# parent writes some data
my $s1 = $pool->alloc;
my $s2 = $pool->alloc;
$pool->set($s1, 1000);
$pool->set($s2, 2000);
printf "parent: slot %d=%d, slot %d=%d\n",
    $s1, $pool->get($s1), $s2, $pool->get($s2);

# child opens pool via inherited fd
my $pid = fork // die "fork: $!";
if ($pid == 0) {
    my $child = Data::Pool::Shared::I64->new_from_fd($fd);
    printf "child:  slot %d=%d, slot %d=%d (read via fd)\n",
        $s1, $child->get($s1), $s2, $child->get($s2);

    # child allocates a new slot
    my $s3 = $child->alloc;
    $child->set($s3, 3000 + $$);
    printf "child:  allocated slot %d=%d\n", $s3, $child->get($s3);
    _exit(0);
}
waitpid($pid, 0);

# parent sees child's allocation
printf "parent: used=%d (parent sees child's alloc)\n", $pool->used;
$pool->each_allocated(sub {
    printf "  slot %d = %d (owner pid %d)\n",
        $_[0], $pool->get($_[0]), $pool->owner($_[0]);
});

$pool->reset;
