#!/usr/bin/env perl
# Multiprocess shared counters with atomic operations
use strict;
use warnings;
use POSIX qw(_exit);
use Data::Buffer::Shared::I64;

my $nprocs = 4;
my $iters = 100_000;

# anonymous mmap — shared across fork, no file needed
my $buf = Data::Buffer::Shared::I64->new_anon(3);
# slot 0: atomic incr counter
# slot 1: cas-based counter
# slot 2: add_slice counter

my @pids;
for my $p (1..$nprocs) {
    my $pid = fork();
    if ($pid == 0) {
        for (1..$iters) {
            $buf->incr(0);

            my $old;
            do { $old = $buf->get(1) }
            until ($buf->cas(1, $old, $old + 1));

            $buf->add(2, 1);
        }
        _exit(0);
    }
    push @pids, $pid;
}

waitpid($_, 0) for @pids;

my $expected = $nprocs * $iters;
printf "incr counter:      %d (expected %d) %s\n",
    $buf->get(0), $expected, $buf->get(0) == $expected ? 'OK' : 'MISMATCH';
printf "cas counter:       %d (expected %d) %s\n",
    $buf->get(1), $expected, $buf->get(1) == $expected ? 'OK' : 'MISMATCH';
printf "add counter:       %d (expected %d) %s\n",
    $buf->get(2), $expected, $buf->get(2) == $expected ? 'OK' : 'MISMATCH';
