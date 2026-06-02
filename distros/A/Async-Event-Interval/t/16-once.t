use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use Test::More;
use Time::HiRes qw(usleep);

use Async::Event::Interval;

my $mod = 'Async::Event::Interval';

{
    my $e = $mod->new(0, sub {select(undef, undef, undef, 0.5)});

    is $e->waiting, 1, "Before start, the event is waiting";

    $e->start;

    sleep 1;

    is $e->status, 0, "Zero as interval sets status to complete (0)";
    is $e->error, 0, "Clean one-shot does not set error";
    is $e->_pid, undef, "Zero as interval clears _pid (was -99 sentinel)";
    is $e->pid,  undef, "...and public pid() also returns undef after completion";
    is $e->waiting, 1, "Zero as interval sets waiting to true";

    $e->start;
    is $e->waiting, 0, "An event doesn't set waiting until after it's done";

    sleep 1;

    is $e->waiting, 1, "Event sets waiting after it completes";
}

# Clean one-shot: _crashed stays 0, runs incremented
{
    my $e = $mod->new(0, sub { 1 });
    $e->start;
    select(undef, undef, undef, 0.3);

    is $e->runs, 1, "clean one-shot: runs incremented";
    is $e->error, 0, "clean one-shot: error() returns 0";
    is $e->errors, 0, "clean one-shot: errors() is 0";
    is $e->_crashed, 0, "clean one-shot: _crashed stays 0";
    is $e->waiting, 1, "clean one-shot: waiting() returns 1";
}

# Crashed one-shot: _crashed is set, error() returns 1
{
    my $e = $mod->new(0, sub { die "boom\n" });
    $e->start;
    select(undef, undef, undef, 0.3);

    is $e->error, 1, "crashed one-shot: error() returns 1";
    is $e->errors, 1, "crashed one-shot: errors() is 1";
    is $e->_crashed, 1, "crashed one-shot: _crashed is set";
    is $e->waiting, 1, "crashed one-shot: waiting() returns 1";
}

# _clean_exit flag cleared on restart: clean first, crash second
{
    my $should_die = 0;
    my $e = $mod->new(0, sub { die "boom\n" if $should_die });
    $e->start;
    select(undef, undef, undef, 0.3);

    is $e->error, 0, "first run clean: error() is 0";

    $should_die = 1;
    $e->start;
    select(undef, undef, undef, 0.3);

    is $e->error, 1, "second run crash: error() is 1 after restart";
}
