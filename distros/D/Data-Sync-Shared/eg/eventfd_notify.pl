#!/usr/bin/env perl
# Event loop integration via eventfd
#
# The semaphore's eventfd is watched by an EV I/O watcher.
# When a child releases a permit, it calls notify() to wake
# the parent's event loop.
use strict;
use warnings;
use POSIX qw(_exit);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;
use EV;

my $sem = Data::Sync::Shared::Semaphore->new(undef, 5);
my $fd = $sem->eventfd;

# Drain all permits
$sem->try_acquire for 1..5;
print "permits drained to 0, starting watcher\n";

my $received = 0;
my $w = EV::io $fd, EV::READ, sub {
    $sem->eventfd_consume;
    my $val = $sem->value;
    $received++;
    print "  event: permits now $val (notification #$received)\n";
    EV::break if $received >= 5;
};

# Child releases permits one at a time with notification
my $pid = fork // die "fork: $!";
if ($pid == 0) {
    for my $i (1..5) {
        select(undef, undef, undef, 0.05);
        $sem->release;
        $sem->notify;
    }
    _exit(0);
}

EV::run;
waitpid($pid, 0);

printf "done: received %d notifications, final value=%d\n",
    $received, $sem->value;
