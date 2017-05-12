# NAME

AnyEvent::FIFO - Simple FIFO Callback Dispatch

# SYNOPSIS

    my $fifo = AnyEvent::FIFO->new(
        max_active => 1, # max "concurrent" callbacks to execute per slot
    );

    # send to the "default" slot
    $fifo->push( \&callback, @args );

    # send to the "slot" slot
    $fifo->push( "slot", \&callback, @args );

    # dispatch is done automatically
    # wait for all tasks to complete
    $fifo->cv->recv();

    sub callback {
        my ($guard, @args) = @_;

        # next callback will be executed when $guard is undef'ed or
        # when it goes out of scope
    }

# DESCRIPTION

AnyEvent::FIFO is a simple FIFO queue to dispatch events in order.

If you use regular watchers and register callbacks from various places in
your program, you're not necessarily guaranteed that the callbacks will be
executed in the order that you expect. By using this module, you can
register callbacks and they will be executed in that particular order.

# METHODS

## new

- max\_active => $number

    Number of concurrent callbacks to be executed __per slot__.

- cv => $cv

    Instance of [AnyEvent condvar](http://search.cpan.org/perldoc?AnyEvent#CONDITION VARIABLES). AnyEvent::FIFO will create one for you if this is not provided.

    AnyEvent::FIFO calls $cv->begin() when new task is pushed and $cv->end() when task is completed.

## push (\[$slot,\] $cb \[,@args\])

- $slot

    The name of the slot that this callback should be registered to. If $slot is
    not specified, "\_\_default\_\_" is used.

- $cb

    The callback to be executed. Receives a "guard" object, and a list of arguments, as specied in @args.

    $guard is the actually trigger that kicks the next callback to be executed, so you should keep it "alive" while you need it. For example, if you need to make an http request to declare the callback done, you should do something like this:

        $fifo->push( sub {
            my ($guard, @args) = @_;

            http_get $uri, sub {
                ...
                undef $guard; # *NOW* the callback is done
            }
        } );

- @args

    List of extra arguments that gets passed to the callback

## active (\[$slot\])

Returns number of active tasks for a given slot.

- $slot

    The name of the slot, "\_\_default\_\_" is used if not specified.

## waiting (\[$slot\])

Returns number of waiting tasks for a given slot.

- $slot

    The name of the slot, "\_\_default\_\_" is used if not specified.

## cv (\[$cv\])

Gets or sets [AnyEvent condvar](http://search.cpan.org/perldoc?AnyEvent#CONDITION VARIABLES).

- $cv

    A new condvar to assign to this FIFO

## drain

Attemps to drain the queue, if possible. You DO NOT need to call this method
by yourself. It's handled automatically

# AUTHOR

Daisuke Maki.

This module is basically a generalisation of the FIFO queue used in AnyEvent::HTTP by Marc Lehmann.

# COPYRIGHT AND LICENSE 

The ZMQ::LibZMQ2 module is

Copyright (C) 2010 by Daisuke Maki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.
