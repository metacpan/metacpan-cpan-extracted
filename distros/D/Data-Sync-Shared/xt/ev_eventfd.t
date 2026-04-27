use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);

use Data::Sync::Shared;

BEGIN {
    eval { require EV; 1 } or plan skip_all => "EV required";
    EV->import;
}

# Parent sets up semaphore + eventfd, attaches an EV::io watcher.
# Child releases the semaphore (bumps eventfd).
# Parent's reactor wakes, consumes, completes. Must not hang.

my $sem = Data::Sync::Shared::Semaphore->new(undef, 1);
# Drain initial permit so the count starts at 0
$sem->try_acquire;
my $efd = $sem->eventfd;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Slight delay so parent enters reactor first.
    select undef, undef, undef, 0.1;
    $sem->release;
    $sem->notify;
    _exit(0);
}

my $saw = 0;
my $w = EV::io($efd, EV::READ, sub {
    $sem->eventfd_consume;
    $saw++;
    EV::break(EV::BREAK_ALL);
});

my $timeout = EV::timer(3, 0, sub { EV::break(EV::BREAK_ALL) });

EV::run;

waitpid $pid, 0;

is $saw, 1, 'eventfd notify woke EV reactor once';
is $sem->value, 1, 'semaphore value incremented by child';

done_testing;
