# NAME

Async::Event::Interval - Scheduled and one-off asynchronous events

<div>

    <a href="https://github.com/stevieb9/async-event-interval/actions"><img src="https://github.com/stevieb9/async-event-interval/workflows/CI/badge.svg"/></a>
    <a href='https://coveralls.io/github/stevieb9/async-event-interval?branch=master'><img src='https://coveralls.io/repos/stevieb9/async-event-interval/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>
</div>

# SYNOPSIS

A simple event that updates JSON data from a website using a shared scalar
variable, while allowing the main application to continue running in the
foreground. Multiple events can be simultaneously used if desired.

See ["EXAMPLES"](#examples) for other various functionality of this module.

    use warnings;
    use strict;

    use Async::Event::Interval;

    my $event = Async::Event::Interval->new(2, \&callback);

    my $json = $event->shared_scalar;

    $event->start;

    while (1) {
        print "$$json\n";

        #... do other things

        $event->restart if $event->error;
    }

    sub callback {
        $$json = ...; # Fetch JSON from website
    }

# DESCRIPTION

Very basic implementation of asynchronous events triggered by a timed interval.
If a time of zero is specified, we'll run the event only once.

# METHODS - EVENT OPERATION

## new($delay, $callback, @params)

Returns a new `Async::Event::Interval` object. Does not create the event. Use
`start` for that.

Parameters:

    $delay

Mandatory: The interval on which to trigger your event callback, in seconds.
Represent partial seconds as a floating point number. If zero is specified,
we'll simply run the event once and stop.

    $callback

Mandatory: A reference to a subroutine that will be called every time the
interval expires.

    @params

Optional, List: A list of parameters to pass to the callback. Note that these
are not shared parameters and are a copy only, so changes to them in the main
code will not be seen in the event, and vice-versa. See ["shared\_scalar"](#shared_scalar) if
you'd like to use variables that can be shared between the main application and
the events.

## start

Starts the event timer. Each time the interval is reached, the event callback
is executed.

## stop

Stops the event from being executed.

## restart

Alias for `start()`. Re-starts a `stop()`ped event.

## status

Returns the event's process ID (true) if it is running, `0` (false) if it
isn't.

## waiting

Returns true if the event is dormant and is ready for a `start()` or
`restart()` command. Returns false if the event is already running.

## error

Returns true if an event crashed unexpectedly in the background, and is ready
for a `start()` or `restart()` command. Returns false if the event is not in
an error state.

## interval($seconds)

Gets/sets the delay time (in seconds) between each execution of the event's
callback code. You can use this method to change the delay between calls
during the event's lifecycle.

Parameters:

    $seconds

Optional, Integer: The number of seconds (can be floating point) to delay
between executions.

Return: Integer, the number of seconds between execution runs. If we're in
a run-once scenario, the return will be zero `0`.

## shared\_scalar

Returns a reference to a scalar variable that can be shared between the main
process and the events. This reference can be used within multiple events, and
multiple shared scalars can be created by each event.

To read from or assign to the returned scalar, you must dereference it. Eg.
`$$shared_scalar = 1;`.

# METHODS - EVENT INFORMATION

## errors

Returns the number of times a started or restarted event has crashed
unexpectedly.

## error\_message

Returns the error message (if any) that caused the most recent event crash.

## events

This is a class method that returns a hash reference that contains the data of
all existing events.

    $VAR1 = {
        '0' => {
            'shared_scalars' => {
                '0x555A4654' => \'hello, world',
                '0x4C534758' => \98
             },
            'pid'       => 11859,
            'runs'      => 16,
            'errors'    => 0,
            'interval'  => 5,
        },
        '1' => {
            'pid'           => 11860,
            'runs'          => 447,
            'errors'        => 2,
            'interval'      => 0.6,
            'error_message' => 'File notes.txt not found at scripts/write_file.pl line 227',
        }
    };

## id

Returns the integer ID of the event.

## info

Returns a hash reference containing various data about the event. Eg.

    $VAR1 = {
        'shared_scalars' => {
            '0x55435449' => \'hello, world!,
            '0x43534644' => \98
         },
        'pid'      => 6841,
        'runs'     => 4077,
        'errors'   => 0,
        'interval' => 1.4,
    };

## pid

Returns the Process ID that the event is running under

## runs

Returns the number of executions of the event's callback routine.

# SCENARIOS/EXAMPLES

## Run once

Send in an interval of zero (`0`) to have your event run a single time. Call
`start()` repeatedly for numerous individual/one-off runs.

    use Async::Event::Interval

    my $event = Async::Event::Interval->new(0, sub {print "hey\n";});

    $event->start;

    # Do stuff, then run the event again if it's done its previous task

    $event->start if $event->waiting;

## Change delay interval during operation

Change the delay interval from 5 to 600 seconds after the event has fired 100
times

    use Async::Event::Interval

    my $event = Async::Event::Interval->new(5, sub {print "hey\n";});

    $event->start;

    while (1) {
        if ($event->runs > 99 && $event->interval != 600) {
            $event->interval(600);
        }

        #... do stuff
    }

## Event error management

If an event crashes, print out error information and restart the event. If an
event crashes five or more times, print the most recent error message and halt
the program so you can figure out what's wrong with your callback code.

    use Async::Event::Interval

    my $event = Async::Event::Interval->new(5, sub {print "hey\n";});

    $event->start;

    while (1) {

        #... do stuff

        if ($event->errors >= 5) {
            print $event->error_message;
            exit;
        }

        if ($event->error) {
            printf(
                "Runs: %d, Runs errored: %d, Last error message: %s\n",
                $event->runs,
                $event->errors,
                $event->error_message;
            );

            $event->restart;
        }
    }

## Event suicidal timeout

You can have your callback commit suicide if it takes too long to run. We use
Perl's `$SIG{ALRM}` and `alarm()` to do this. In your main application, you
can check the status of the event and restart it or whatever else you need.

    my $event_timeout = 30;

    my $event = Async::Event::Interval->new(
        30,
        sub {
            local $SIG{ALRM} = sub { print "Committing suicide!\n"; kill 9, $$; };

            alarm $event_timeout;

            # Do stuff here. If it takes 30 seconds, we kill ourselves

            alarm 0;
        },
    );

## Event parameters

You can send in a list of parameters to the event callback. Changing these
within the main program will have no effect on the values sent into the
event itself. These parameter variables are copies and are not shared. For
shared variables, see ["shared\_scalar"](#shared_scalar).

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

## Event crash: Restart event

    use warnings;
    use strict;

    use Async::Event::Interval;

    my $event = Async::Event::Interval->new(0.5, sub { kill 9, $$; });

    $event->start;

    sleep 1; # Do stuff

    if ($event->error){
        print "Event crashed, restarting\n";
        $event->restart;
    }

## Event crash: End program

    use warnings;
    use strict;

    use Async::Event::Interval;

    my $event = Async::Event::Interval->new(0.5, sub { kill 9, $$; });

    $event->start;

    sleep 1; # Do stuff

    die "Event crashed, can't continue" if $event->error;

## Shared data across events

This software uses [IPC::Shareable](https://metacpan.org/pod/IPC%3A%3AShareable) internally, so it's automatically
installed for you already. You can use shared data for use across many processes
and events, and if you use the same IPC key, even across multiple scripts.

Here's an example that uses a hash that's stored in shared memory, where the
parent process (the script) and two other processes (the two events) all share
and update the same hash.

    use Async::Event::Interval;
    use IPC::Shareable;

    tie my %shared_data, 'IPC::Shareable', {
        key         => '123456789',
        create      => 1,
        destroy     => 1
    };

    $shared_data{$$}{called_count}++;

    my $event_one = Async::Event::Interval->new(0.2, \&update);
    my $event_two = Async::Event::Interval->new(1, \&update);

    $event_one->start;
    $event_two->start;

    sleep 10;

    $event_one->stop;
    $event_two->stop;

    for my $pid (keys %shared_data) {
        printf(
            "Process ID %d executed %d times\n",
            $pid,
            $shared_data{$pid}{called_count}
        );
    }

    for my $event ($event_one, $event_two) {
        printf(
            "Event ID %d with PID %d ran %d times, with %d errors and an interval" .
            " of %.2f seconds\n",
            $event->id,
            $event->pid,
            $event->runs,
            $event->errors,
            $event->interval
        );
    }

    sub update {
        # Because each event runs in its own process, $$ will be set to the
        # process ID of the calling event, even though they both call this
        # same function

        $shared_data{$$}{called_count}++;
    }

# AUTHOR

Steve Bertrand, `<steveb at cpan.org>`

# LICENSE AND COPYRIGHT

Copyright 2022 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
