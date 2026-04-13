#!/usr/bin/env perl
# eventfd integration without EV — using IO::Poll
#
# The eventfd is a regular file descriptor that can be polled
# with select/poll/epoll. This example uses IO::Poll.
use strict;
use warnings;
use POSIX qw(_exit);
use IO::Poll qw(POLLIN);
use IO::Handle;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $sem = Data::Sync::Shared::Semaphore->new(undef, 10, 0);
my $fd = $sem->eventfd;

# Wrap fd in a Perl handle for IO::Poll
open my $efh, '<&=', $fd or die "fdopen: $!";

my $poll = IO::Poll->new;
$poll->mask($efh, POLLIN);

# Child: release permits with notification
my $pid = fork // die "fork: $!";
if ($pid == 0) {
    for my $i (1..5) {
        select(undef, undef, undef, 0.1);
        $sem->release;
        $sem->notify;
        printf "  child: released permit %d\n", $i;
    }
    _exit(0);
}

# Parent: poll for eventfd readability
my $received = 0;
while ($received < 5) {
    my $n = $poll->poll(5.0);
    if ($n > 0 && $poll->events($efh) & POLLIN) {
        $sem->eventfd_consume;
        $received++;
        printf "  parent: polled notification %d (value=%d)\n",
            $received, $sem->value;
    }
}

waitpid($pid, 0);
printf "\ndone: %d notifications, final value=%d\n", $received, $sem->value;

# Close the Perl handle but NOT the underlying fd (owned by $sem)
# IO::Handle would close the fd on DESTROY, so detach it
open $efh, '<&=-1';  # detach
