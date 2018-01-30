package Async::Event::Interval;

use warnings;
use strict;

our $VERSION = '1.00';

use Carp qw(croak);
use Parallel::ForkManager;

$SIG{CHLD} = "IGNORE";
$SIG{__WARN__} = sub {
    my $warn = shift;
    warn $warn if $warn !~ /^child process/;
};

sub new {
    my $self = bless {}, shift;
    $self->{pm} = Parallel::ForkManager->new(1);
    $self->_set(@_);
    $self->{started} = 0;
    return $self;
}
sub start {
    my $self = shift;
    if ($self->{started}){
        warn "event already running...\n";
        return;
    }
    $self->{started} = 1;
    $self->_event;
}
*restart = \&start;
sub stop {
    my $self = shift;

    if ($self->_pid){
        kill 9, $self->_pid;

        $self->{started} = 0;
        $self->{stop} = 1;

        # time to ensure the proc was killed

        sleep 1;

        if (kill 0, $self->_pid){
            croak "Event stop was called, but the process hasn't been killed. " .
                  "This is a fatal event. Exiting...\n";
        }
    }
}
sub status {
    my $self = shift;

    if ($self->{started}){
        if (! $self->_pid){
            croak "Event is started, but no PID can be found. This is a " .
                  "fatal error. Exiting...\n";
        }
        if ($self->_pid > 0){
            if (kill 0, $self->_pid){
                return $self->_pid;
            }
            else {
                # proc must have crashed
                $self->{started} = 0;
                $self->_pid(-99);
                return -1;
            }
        }
    }
    return -1 if defined $self->_pid && $self->_pid == -99;
    return 0;
}
sub _event {
    my $self = shift;
    
    for (0..1){
        my $pid = $self->{pm}->start;
        if ($pid){
            # this is the parent process
            $self->_pid($pid);
            last;
        }

        # set the child's proc id
        $self->_pid($$);

        while(1){
            $self->{cb}->(@{ $self->{args} });
            sleep $self->{interval};
        }
        $self->{pm}->finish;
    }
}
sub _pid {
    my ($self, $pid) = @_;
    $self->{pid} = $pid if defined $pid;
    return $self->{pid} || undef;
}
sub _set {
    my ($self, $interval, $cb, @args) = @_;
    $self->{interval} = $interval;
    $self->{cb} = $cb;
    $self->{args} = \@args;
}
sub DESTROY {
    $_[0]->stop if $_[0]->_pid;
}
sub _vim{}
1;

__END__

=head1 NAME

Async::Event::Interval - Extremely simple timed asynchronous events

=for html
<a href="http://travis-ci.org/stevieb9/async-event-interval"><img src="https://secure.travis-ci.org/stevieb9/async-event-interval.png"/></a>
<a href='https://coveralls.io/github/stevieb9/async-event-interval?branch=master'><img src='https://coveralls.io/repos/stevieb9/async-event-interval/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

A simple event. Multiple events can be simultaneously used. For an example using
an event that can share data with the main application, examples of how to
handle event crashes, and how to send parameters to your event callback, see 
L</EXAMPLES>.

    use Async::Event::Interval;

    my $event = Async::Event::Interval->new(
        1.5, 
        \&callback
    );

    $event->start;

    for (1..10){
        print "$_: in main loop\n";

        $event->stop if $_ == 3;
        $event->start if $_ == 7;

        if ($event->status){
            print "event is running\n";
        }

        if ($event->status == -1){
            print "event has crashed... restarting it\n";
            $event->restart;
        }

        sleep 1;
    }

    sub callback {
        print "timed event callback\n";
    }

=head1 DESCRIPTION

Very basic implementation of asynchronous events that are triggered by a timed
interval.

Variables are not shared between the main application and the event. To do that,
you'll need to use some form of memory sharing, such as L<IPC::Shareable>. See
L</EXAMPLES> for an example. At this time, there is no real parameter passing or
ability to return values. As I said... basic.

Each event is simply a separate forked process, which runs in a while loop.

=head1 METHODS

=head2 new($delay, $callback)

Returns a new C<Async::Event::Interval> object. Does not create the event. Use
C<start> for that.

Parameters:

    $delay

Mandatory: The interval on which to trigger your event callback, in seconds.
Represent partial seconds as a floating point number.

    $callback

Mandatory: A reference to a subroutine that will be called every time the
interval expires.

=head2 start

Starts the event timer. Each time the interval is reached, the event callback
is executed.

=head2 stop

Stops the event from being executed.

=head2 restart

Alias for C<start()>. Re-starts a C<stop()>ped event.

=head2 status

Returns the event's process ID (true) if it is running, C<0> (false) if it
isn't, and C<-1> if the event has crashed.

=head1 EXAMPLES

=head2 Event Parameters

You can send in a list of parameters to the event callback. Changing these
within the main program will have no effect on the values sent into the
event itself.

    use Async::Event::Interval

    my @params = qw(1 2 3);

    my $event = Async::Event::Interval->new(
        1,
        \&callback,
        @params
    );

    sub callback {
        my ($one, $two, $three) = @_;
        print "$one, $two, $three\n";
    }

=head2 Shared Data

A timed event where the event callback shares a hash reference with the main
program.

    use Async::Event::Interval;
    use IPC::Shareable;

    my $href = {a => 0, b => 1};
    tie $href, 'IPC::Shareable', undef;

    my $event
        = Async::Event::Interval->new(10, \&callback);

    sub callback {
        $h->{a}++;
    }

=head2 Event crash: Restart event

    use warnings;
    use strict;
    use feature 'say';

    use Async::Event::Interval;

    my $event = Async::Event::Interval->new(
        2,
        sub {
            kill 9, $$;
        },
    );

    $event->start;

    sleep 1; # do stuff

    if ($event->status == -1){
        say "event crashed, restarting";
        $event->restart;
    }

=head2 Event crash: End program

    use warnings;
    use strict;
    use feature 'say';

    use Async::Event::Interval;

    my $event = Async::Event::Interval->new(
        2,
        sub {
            kill 9, $$;
        },
    );

    $event->start;

    sleep 1; # do stuff

    if ($event->status == -1){
        say "event crashed, can't continue...";
        exit;
    }

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
