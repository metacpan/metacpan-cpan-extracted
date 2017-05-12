package AnyEvent::FIFO;
use strict;
use AnyEvent;
use AnyEvent::Util ();

our $VERSION = '0.00003';

sub new {
    my $class = shift;
    my $self = {
        max_active => 1,
        @_,
        active => {},
        events => {},
    };
    $self->{cv} ||= AE::cv;
    return bless($self, $class);
}

sub push {
    my ($self, $slot, $cb, @args) = @_;
    # the first argument must be the name of the slot or a callback
    if (ref $slot) {
        unshift @args, $cb;
        $cb = $slot;
        $slot = "__default__";
    }

    push @{$self->{events}->{$slot}}, [$cb, @args];
    $self->{cv}->begin();

    AE::postpone sub {
        $self->drain();
    };
}

sub active {
    my ($self, $slot) = @_;
    $slot = "__default__" unless(defined($slot));
    return $self->{active}->{$slot} || 0;
}

sub waiting {
    my ($self, $slot) = @_;
    $slot = "__default__" unless(defined($slot));
    return $self->{events}->{$slot} ? (0 + @{$self->{events}->{$slot}}) : 0;
}

sub cv {
    my $self = shift;
    $self->{cv} = $_[0] if(@_);
    return $self->{cv};
}

sub drain {
    my $self = shift;

    my @slots = keys %{$self->{events}};
    my $dispatched = 1;
    while ($dispatched) {
        $dispatched = 0;
        foreach my $slot (@slots) {
            my $events = $self->{events}->{$slot};
            if ( @$events && ($self->{active}->{$slot} ||= 0) < $self->{max_active} ) {
                $dispatched++;
                my $stuff = shift @$events;
                my ($cb, @args) = @$stuff;
                $self->{active}->{$slot}++;
                $cb->( AnyEvent::Util::guard {
                    $self->{active}->{$slot}--;
                    if ($self->{active}->{$slot} <= 0) {
                        delete $self->{active}->{$slot};
                    }
		    $self->{cv}->end();
                    AE::postpone sub {
                        $self->drain();
                    };
                }, @args );
            }
        }
    }
}

1;

__END__

=head1 NAME

AnyEvent::FIFO - Simple FIFO Callback Dispatch

=head1 SYNOPSIS

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

=head1 DESCRIPTION

AnyEvent::FIFO is a simple FIFO queue to dispatch events in order.

If you use regular watchers and register callbacks from various places in
your program, you're not necessarily guaranteed that the callbacks will be
executed in the order that you expect. By using this module, you can
register callbacks and they will be executed in that particular order.

=head1 METHODS

=head2 new

=over 4

=item max_active => $number

Number of concurrent callbacks to be executed B<per slot>.

=item cv => $cv

Instance of L<AnyEvent condvar|AnyEvent/"CONDITION VARIABLES">. AnyEvent::FIFO will create one for you if this is not provided.

AnyEvent::FIFO calls $cv->begin() when new task is pushed and $cv->end() when task is completed.

=back

=head2 push ([$slot,] $cb [,@args])

=over 4

=item $slot

The name of the slot that this callback should be registered to. If $slot is
not specified, "__default__" is used.

=item $cb

The callback to be executed. Receives a "guard" object, and a list of arguments, as specied in @args.

$guard is the actually trigger that kicks the next callback to be executed, so you should keep it "alive" while you need it. For example, if you need to make an http request to declare the callback done, you should do something like this:

    $fifo->push( sub {
        my ($guard, @args) = @_;

        http_get $uri, sub {
            ...
            undef $guard; # *NOW* the callback is done
        }
    } );

=item @args

List of extra arguments that gets passed to the callback

=back

=head2 active ([$slot])

Returns number of active tasks for a given slot.

=over 4

=item $slot

The name of the slot, "__default__" is used if not specified.

=back

=head2 waiting ([$slot])

Returns number of waiting tasks for a given slot.

=over 4

=item $slot

The name of the slot, "__default__" is used if not specified.

=back

=head2 cv ([$cv])

Gets or sets L<AnyEvent condvar|AnyEvent/"CONDITION VARIABLES">.

=over 4

=item $cv

A new condvar to assign to this FIFO

=back

=head2 drain

Attemps to drain the queue, if possible. You DO NOT need to call this method
by yourself. It's handled automatically

=head1 AUTHOR

Daisuke Maki.

This module is basically a generalisation of the FIFO queue used in AnyEvent::HTTP by Marc Lehmann.

=head1 COPYRIGHT AND LICENSE 

The ZMQ::LibZMQ2 module is

Copyright (C) 2010 by Daisuke Maki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
