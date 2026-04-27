use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);

# EV integration: parent creates queue + eventfd, forks a child that
# pushes an item and calls notify. Parent's EV::io on the eventfd fires.

BEGIN {
    eval { require EV; 1 } or plan skip_all => "EV not installed";
}

use Data::Queue::Shared::Int;

my $q = Data::Queue::Shared::Int->new_memfd("ev-q", 16);
my $efd = $q->eventfd;
ok $efd >= 0, "eventfd fd=$efd";

# Fork AFTER eventfd is created so child inherits it
my $pid = fork // die "fork: $!";
if (!$pid) {
    select undef, undef, undef, 0.2;
    my $q2 = Data::Queue::Shared::Int->new_from_fd($q->memfd);
    $q2->eventfd_set($efd);   # point child's notify at parent's inherited fd
    $q2->push(99);
    $q2->notify;
    exit 0;
}

my $fired = 0;
my $got;
my $w = EV::io $efd, EV::READ, sub {
    $fired++;
    $q->eventfd_consume;   # drain the eventfd
    $got = $q->pop;
    EV::break(EV::BREAK_ALL);
};
my $timer = EV::timer 3, 0, sub { EV::break(EV::BREAK_ALL) };

my $t0 = time;
EV::run;
my $elapsed = time - $t0;

waitpid $pid, 0;

ok $fired, "eventfd fired in EV loop (${\sprintf '%.3f', $elapsed}s)";
is $got, 99, "popped value after wakeup";
cmp_ok $elapsed, '<', 2.9, "fired before 3s timer (real async)";

done_testing;
