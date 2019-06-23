[![Build Status](https://travis-ci.org/karupanerura/p5-AnyEvent-ForkManager.svg?branch=master)](https://travis-ci.org/karupanerura/p5-AnyEvent-ForkManager)
# NAME

AnyEvent::ForkManager - A simple parallel processing fork manager with AnyEvent

# VERSION

This document describes AnyEvent::ForkManager version 0.07.

# SYNOPSIS

    use AnyEvent;
    use AnyEvent::ForkManager;
    use List::Util qw/shuffle/;

    my $MAX_WORKERS = 10;
    my $pm = AnyEvent::ForkManager->new(max_workers => $MAX_WORKERS);

    $pm->on_start(sub {
        my($pm, $pid, $sec) = @_;
        printf "start sleep %2d sec.\n", $sec;
    });
    $pm->on_finish(sub {
        my($pm, $pid, $status, $sec) = @_;
        printf "end   sleep %2d sec.\n", $sec;
    });

    my @sleep_time = shuffle(1 .. 20);
    foreach my $sec (@sleep_time) {
        $pm->start(
            cb => sub {
                my($pm, $sec) = @_;
                sleep $sec;
            },
            args => [$sec]
        );
    }

    my $cv = AnyEvent->condvar;

    # wait with non-blocking
    $pm->wait_all_children(
        cb => sub {
            my($pm) = @_;
            print "end task!\n";
            $cv->send;
        },
    );

    $cv->recv;

# DESCRIPTION

`AnyEvent::ForkManager` is much like [Parallel::ForkManager](https://metacpan.org/pod/Parallel::ForkManager),
but supports non-blocking interface with [AnyEvent](https://metacpan.org/pod/AnyEvent).

[Parallel::ForkManager](https://metacpan.org/pod/Parallel::ForkManager) is useful but,
it is difficult to use in conjunction with [AnyEvent](https://metacpan.org/pod/AnyEvent).
Because [Parallel::ForkManager](https://metacpan.org/pod/Parallel::ForkManager)'s some methods are blocking the event loop of the [AnyEvent](https://metacpan.org/pod/AnyEvent).

You can accomplish the same goals without adversely affecting the [Parallel::ForkManager](https://metacpan.org/pod/Parallel::ForkManager) to [AnyEvent::ForkManager](https://metacpan.org/pod/AnyEvent::ForkManager) with [AnyEvent](https://metacpan.org/pod/AnyEvent).
Because [AnyEvent::ForkManager](https://metacpan.org/pod/AnyEvent::ForkManager)'s methods are non-blocking the event loop of the [AnyEvent](https://metacpan.org/pod/AnyEvent).

# INTERFACE

## Methods

### `new`

This is constructor.

- max\_workers

    max parallel forking count. (default: 10)

- on\_start

    started child process callback.

- on\_finish

    finished child process callback.

- on\_error

    fork error callback.

- on\_enqueue

    If push to start up child process queue, this callback is called.

- on\_dequeue

    If shift from start up child process queue, this callback is called.

- on\_working\_max

    If request to start up child process and process count equal max process count, this callback is called.

#### Example

    my $pm = AnyEvent::ForkManager->new(
        max_workers => 2,   ## default 10
        on_finish => sub {  ## optional
            my($pid, $status, @anyargs) = @_;
            ## this callback call when finished child process.(like AnyEvent->child)
        },
        on_error => sub {   ## optional
            my($pm, @anyargs) = @_;
            ## this callback call when fork failed.
        },
    );

### `start`

start child process.

- args

    arguments passed to the callback function of the child process.

- cb

    run on child process callback.

#### Example

    $pm->start(
        cb => sub {   ## optional
            my($pm, $job_id) = @_;
            ## this callback call in child process.
        },
        args => [$job_id],## this arguments passed to the callback function
    );

### `wait_all_children`

You can call this method to wait for all the processes which have been forked.
This can wait with blocking or wait with non-blocking in event loop of AnyEvent.
**feature to wait with blocking is ALPHA quality till the version hits v1.0.0. Things might be broken.**

- blocking

    If this parameter is true, blocking wait enable. (default: false)
    **feature to wait with blocking is ALPHA quality till the version hits v1.0.0. Things might be broken.**

- cb

    finished all the processes callback.

#### Example

    $pm->wait_all_children(
        cb => sub {   ## optional
            my($pm) = @_;
            ## this callback call when finished all child process.
        },
    );

### `signal_all_children`

Sends signal to all worker processes. Only usable from manager process.

### `on_error`

As a new method's argument.

### `on_start`

As a new method's argument.

### `on_finish`

As a new method's argument.

### `on_enqueue`

As a new method's argument.

### `on_dequeue`

As a new method's argument.

### `on_working_max`

As a new method's argument.

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

[AnyEvent](https://metacpan.org/pod/AnyEvent)
[AnyEvent::Util](https://metacpan.org/pod/AnyEvent::Util)
[Parallel::ForkManager](https://metacpan.org/pod/Parallel::ForkManager)
[Parallel::Prefork](https://metacpan.org/pod/Parallel::Prefork)

# AUTHOR

Kenta Sato <karupa@cpan.org>

# LICENSE AND COPYRIGHT

Copyright (c) 2012, Kenta Sato. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
