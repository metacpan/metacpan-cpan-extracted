#!/usr/bin/env perl
# Share a buffer between unrelated processes via memfd + fd passing
use strict;
use warnings;
use POSIX qw(_exit dup);
use Data::Buffer::Shared::I64;

# create a named memfd buffer
my $buf = Data::Buffer::Shared::I64->new_memfd("shared_counters", 100);
$buf->fill(0);

my $fd = $buf->fd;
printf "memfd fd: %d\n", $fd;

# in practice, pass $fd to another process via SCM_RIGHTS on a unix socket.
# here we simulate with fork + dup:

my $pid = fork();
if ($pid == 0) {
    # child opens from the inherited fd
    my $fd2 = dup($fd);
    my $child_buf = Data::Buffer::Shared::I64->new_from_fd($fd2);

    for (1..10000) { $child_buf->incr(0) }
    printf "child: incremented slot 0 to %d\n", $child_buf->get(0);
    _exit(0);
}

for (1..10000) { $buf->incr(0) }
waitpid($pid, 0);

printf "parent: final slot 0 = %d (expected 20000)\n", $buf->get(0);
