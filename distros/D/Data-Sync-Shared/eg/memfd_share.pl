#!/usr/bin/env perl
# Sharing sync primitives via memfd (no filesystem)
#
# Parent creates primitives with memfd, passes fd to child via fork.
# Works across unrelated processes when using SCM_RIGHTS fd passing.
use strict;
use warnings;
use POSIX qw(_exit);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

# Create primitives backed by memfd
my $sem  = Data::Sync::Shared::Semaphore->new_memfd("my_sem", 2);
my $once = Data::Sync::Shared::Once->new_memfd("my_once");

my $sem_fd  = $sem->memfd;
my $once_fd = $once->memfd;

printf "semaphore memfd=%d, once memfd=%d\n", $sem_fd, $once_fd;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Child opens the same primitives from inherited fds
    my $c_sem  = Data::Sync::Shared::Semaphore->new_from_fd($sem_fd);
    my $c_once = Data::Sync::Shared::Once->new_from_fd($once_fd);

    # Acquire a semaphore permit
    $c_sem->acquire;
    printf "  child: acquired permit (value=%d)\n", $c_sem->value;

    # Try to be the initializer
    if ($c_once->enter) {
        print "  child: I'm the once initializer\n";
        $c_once->done;
    } else {
        print "  child: once already done\n";
    }

    _exit(0);
}

# Parent also uses the primitives
if ($once->enter) {
    print "  parent: I'm the once initializer\n";
    $once->done;
} else {
    print "  parent: once already done\n";
}

waitpid($pid, 0);

printf "final semaphore value: %d (started at 2, child took 1)\n", $sem->value;
printf "once is_done: %d\n", $once->is_done;
