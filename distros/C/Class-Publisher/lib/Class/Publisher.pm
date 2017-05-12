# $Id: Publisher.pm,v 1.3 2005/03/25 13:20:21 simonflack Exp $
package Class::Publisher;
use strict;
use Carp;
use Class::ISA;
use Scalar::Util qw/blessed reftype weaken/;
use vars '$VERSION';

$VERSION = '0.2';
my (%S, %P) = ();


# Add one or more subscribers (class name, object or subroutine) to a
# subscribed item (class or object). Return new number of subscribers.
sub add_subscriber {
    my ($item, $event, $subscriber, $use_method) = @_;
    $event = '*' unless defined $event && length $event;
    croak "Invalid subscriber - $subscriber, expected a coderef, object or class name"
        unless _valid_subscriber($subscriber);

    my $subscriber_list = $S {$item} {$event} ||= {};
    weaken($subscriber) if blessed($subscriber);
    my $new_subscriber;
    if ($use_method && (!ref $subscriber || blessed($subscriber))) {
        $new_subscriber = [ $subscriber, $use_method ];
    } else {
        $new_subscriber = $subscriber;
    }

    TRACEF("Adding subscriber [%s] of '%s' on [%s]",
           $subscriber, _event_name($event), _item_name($item));
    $subscriber_list->{$subscriber} = $new_subscriber;

    return scalar keys %$subscriber_list;
}


# Remove one or more subscribers from a subscribed item. Return new
# number of subscribers.
# TODO: Will this work with subroutines?
sub delete_subscriber {
    my ($item, $event, $subscriber) = @_;
    return 0 unless ref $S { $item };
    $event = '*' unless defined $event && length $event;

    if ($subscriber) {
        my @events;
        if (defined $event && length $event) {
            @events = ($event);
        } else {
            @events = _get_registered_events($item);
        }

        foreach my $subscribed_event (@events) {
            TRACEF("Removing subscriber [%s] of '%s' on [%s]",
                   $subscriber,
                   _event_name($subscribed_event),
                   _item_name($item));

            my $removed = delete $S {$item} {$subscribed_event} {$subscriber};
            TRACEF("Found subscriber [%s]; removing", $subscriber);
        }
    }
    return defined wantarray ? 0 + $item -> get_subscribers($event) : undef;
}


# Remove all subscribers from a subscribed item. Return number of
# subscribers removed.
sub delete_all_subscribers {
    my ($item) = @_;
    TRACEF("Removing all subscribers from [%s]", _item_name($item));
    my $rv = defined wantarray ? 0 + $item -> get_subscribers : undef;
    return 0 unless ref $S {$item};
    $S {$item} = {};
    return $rv;
}


# Tell all subscribers that a event-change has occurred. No return
# value.
sub notify_subscribers {
    my ($item, $event, @params) = @_;
    croak "Invalid event name '$event'" if $event && ref $event;
    $event = '*' unless defined $event && length $event;
    TRACEF("Notification from [%s] with event [%s]",
           _item_name($item), _event_name($event));

    my @subscribers = $item -> get_subscribers($event);
    unless ($event eq '*') {
        push @subscribers, $item -> get_subscribers('*');
    }

    my %called;
    foreach my $s (@subscribers) {
        TRACEF("Notifying subscriber [%s]", $s);
        if ($called {$s}++) {
            TRACEF("Already called subscriber [%s]", $s);
            next;
        }
        if (reftype $s && reftype $s eq 'CODE') {
            $s -> ($item, $event, @params);
        }
        else {
            my ($callable, $method) = ($s, 'update');
            if (ref $s && reftype $s eq 'ARRAY' && ! blessed($s)) {
                ($callable, $method) = @$s;
            }
            next unless $callable && $method;
            $callable -> $method($item, $event, @params);
        }
    }
}


# Retrieve *all* subscribers for a particular item. (See docs for what
# *all* means.) Returns a list of subscribers
sub get_subscribers {
    my ($item, $event) = @_;
    TRACEF("Retrieving subscribers of [%s] on [%s]",
           _event_name($event), _item_name($item));

    my @subscribers = ();
    my $class = ref $item;
    if ($class) {
        TRACEF("Retrieving object-specific subscribers from [%s]",
               _item_name($item));
        push @subscribers, _obs_get_subscribers_scoped($item, $event);
    }
    else {
        $class = $item;
    }
    TRACEF("Retrieving class-specific subscribers from [%s] and its "
           . "parents", $class);
    push @subscribers, _obs_get_subscribers_scoped($class, $event),
            _obs_get_parent_subscribers($class, $event);

    my (@filtered, %seen);
    foreach (@subscribers) {
        push @filtered, $_, unless $seen {$_}++;
    }
    TRACEF("Found subscribers [%s]", join '][', @filtered);
    return @filtered;
}


# Copy all subscribers from one item to another. This DOESN'T copy
# subscribers from parents.
sub copy_subscribers {
    my ($item_from, $item_to) = @_;

    my $rv;
    foreach my $event ('', _get_registered_events($item_from)) {
        my @obs = _obs_get_explicit_subscribers_scoped($item_from, $event);
        foreach my $subscriber (@obs) {
            $item_to -> add_subscriber($event, $subscriber);
            $rv++;
        }
    }
    return $rv;
}


sub count_subscribers {
    my ($item, $event) = @_;
    TRACEF("Counting subscribers of [%s] on [%s]",
           _event_name($event), _item_name($item));
    return scalar $item -> get_subscribers($event);
}


# Log::Trace stubs
sub TRACE  {}
sub TRACEF {}

############################################################################
# Private functions

sub _get_registered_events {
    my ($item) = @_;
    return () unless ref $S {$item};
    return grep defined ($_) && length ($_), keys % {$S {$item}};
}

# Find subscribers from parents
sub _obs_get_parent_subscribers {
    my ($item, $event) = @_;
    my $class = ref $item || $item;

    # We only find the parents the first time, so if you muck with
    # @ISA you'll get unexpected behavior...

    unless (ref $P {$class}) {
        my @parent_path = Class::ISA::super_path($class);
        TRACEF("Finding subscribers from parent classes [%s]",
                         join '] [', @parent_path );
        my @subscribed_parents = ();
        foreach my $parent (@parent_path) {
            next if ($parent eq 'Class::Publisher');
            if ($parent -> isa('Class::Publisher')) {
                push @subscribed_parents, $parent;
            }
        }
        push @subscribed_parents, __PACKAGE__;
        $P {$class} = \@subscribed_parents;
        TRACEF("Found subscribed parents for [%s]: [%s]",
                        $class, join '] [', @subscribed_parents);
    }

    my @parent_subscribers = ();
    foreach my $parent (@{$P {$class}}) {
        push @parent_subscribers, _obs_get_subscribers_scoped($parent, $event);
    }
    return @parent_subscribers;
}


# Return subscribers ONLY for the specified item
sub _obs_get_subscribers_scoped {
    my ($item, $event) = @_;
    return () unless (ref $S {$item});

    my @events;
    if (defined $event && length $event) {
        @events = ('', $event);
    } else {
        @events = ('', _get_registered_events($item));
    }

    my @subscribers;
    foreach (@events) {
        next unless (ref $S {$item} {$_});
        push @subscribers, values %{$S {$item} {$_}};
    }
    return @subscribers;
}

# Return subscribers EXPLICITLY registered for the specified item AND event
sub _obs_get_explicit_subscribers_scoped {
    my ($item, $event) = @_;
    return () unless ref $S {$item} && ref $S {$item} {$event};
    return values %{$S {$item} {$event}};
}

# Return subscriber validation errors
sub _valid_subscriber {
    my $s = shift;

    return unless defined $s;
    return 1 if !ref $s && length $s;           # Class
    return 1 if ref $s && reftype $s eq 'CODE'; # Subroutine
    return 1 if blessed ($s);                   # Object
    return 0;
}

# Used in debugging
sub _item_name {
    my ($item) = @_;
    return "Class $item" unless (ref $item);
    my $item_class = ref $item;
    if ($item -> can('id')) {
        return "Object of class $item_class with ID " . $item -> id;
    }
    return "Instance of class $item_class";
}

sub _event_name {
    my ($event) = @_;
    return $event if defined $event && length $event;
    return 'all events';
}

1;

__END__

=head1 NAME

Class::Publisher - A simple publish-subscribe event framework

=head1 SYNOPSIS

    # Define a class that publishes events
    package My::Widget;
    use base 'Class::Publisher';

    # Publish event
    sub incriment {
        my ($self) = @_;
        my $old_value = $self->{value}++;
        $self->notify_subscribers('changed', old_value => $old_value);
    }

    # Define a subscriber;
    package My::Subscriber;

    sub new {
        my $self = bless {}, shift;

        # Subscribe to events from My::Widget
        My::Widget->add_subscriber('changed', sub {$self->_widgetvalue(@_)});

        # Subscribe to all events from My::Widget
        My::Widget->add_subscriber('*', \&_on_update_widget);

        return $self;
    }

    sub _widgetvalue {
        my $self = shift;
        my ($item, $event, %params) = @_;

        # do something with new/old value
    }

    sub _on_update_widget {
        my ($item, $event, %params) = @_;
        print STDERR "Caught event $event from '$item'\n";
    }


=head1 DESCRIPTION

Class::Publisher impliments the Publish-Subscribe pattern (also referred to as
the Observer pattern). It is often used in user interfaces when many entities
are interested in a particular event. The Publish-Subscribe pattern decouples
the publisher and subscriber and provides a generic interface for publishing
and subscribing to events.

This module is based on L<Class::Observable|Class::Observable> by Chris
Winters. The main difference is that entities can subscribe to specific events
raised by the publisher rather than receiving all notifications.

Like L<Class::Observable|Class::Observable>, entities can subscribe to events
raised by a publisher class or a publisher instance:

    My::Widget->add_subscriber('update', \&_on_widget_update);
    $widget->('update', sub {print STDERR "$widget raised update event"});

=head2 Publisher classes and objects

The publisher does not need to implement any extra methods or
variables. Whenever it wants to let subscribers know about an event, it just
needs to call C<notify_subscribers()>.

As noted above, it does not matter if the publisher is a class or object -- the
behavior is the same. The difference comes in determining which subscribers are
to be notified:

=over 4

=item *

If the publisher is a class, all objects instantiated from that class will use
these subscribers. In addition, all subclasses and objects instantiated from
the subclasses will use these subscribers.

=item *

If the publisher is an object, only that particular object will use its
subscribers. Once it falls out of scope then the subscribers will no longer be
available. (See L<Publisher Objects and DESTROY> below.)

=back

=head2 Subscribers

There are three types of subscribers: classes, objects and subroutines. They
all respond to events raised by the publisher's C<notify_subscribers()> method.

The following parameters are passed to subscribers:

=over 4

=item *

The publisher class or object that generated the event

=item *

The name of the event or C<'*'> if no event was defined for the event

=item *

Additional parameters passed to the C<notify_subscribers()> method

=back

Class and object subscribers differ slightly by being passed their class
name/object an additional parameter before the publisher item

=over 4

=item Class subscribers

Class subscribers are notified of events via the class's C<update()> method:

    package My::Subscriber;

    sub update {
        my ($class, $publisher, $event, @args) = @_;
        if ($event eq 'reload') {
            # ...
        } elsif ($event eq 'refresh') {
        }
        # ...
    }

Class notifications can be routed to other methods. See C<add_subscriber()>.

=item Object subscribers

Object subscribers are notified of events via the object's C<update()> method:

    package My::Subscriber;

    sub update {
        my ($self, $publisher, $event, @args) = @_;
        # ...
    }

Object notifications can be routed to other methods. See C<add_subscriber()>.

=item Subroutine subscribers

    package My::Subscriber;

    sub _refresh {
        my ($publisher, $event, @args) = @_;
        # ...
    }

    sub _reload {
        my $self = shift;
        my ($publisher, $event, @args) = @_;
        # ...
    }

    sub _catch_all {
        # ...
    }

    My::Publisher->add_subscriber('_refresh', \&_refresh);
    My::Publisher->add_subscriber('_refresh', sub {$self->_reload(@_)});
    My::Publisher->add_subscriber('*', \&_catch_all);

=back

=head2 Publisher Objects and DESTROY

One problem with this module relates to subscribed objects. Once the
publisher goes out of scope, its subscribers will still be hanging
around. For one-off scripts this is not a problem, but for long-lived
processes this could be a memory leak.

To take care of this, it is a good idea to explicitly release
subscribers attached to an object in the C<DESTROY> method. This should
suffice:

  sub DESTROY {
      my ( $self ) = @_;
      $self->delete_all_subscribers;
  }

=head1 METHODS

=over 4

=item add_subscriber($event, $subscriber, [$method_name])

Registers a subscriber to receive event notifications on the publisher. Each
subscriber can be a class name, object or subroutine -- see L<Subscribers>.

Object and class notifications can be routed to C<$method_name> if
defined. Otherwise the default C<update()> method will be called.

If C<$event> is undefined or C<''>, the subscribers will be subscribed to the
special event '*' that receives notifications of I<all events>. Otherwise, the
subscribers will only receive notifications when the notification event matches
C<$event>.

Returns: The number of subscribers of the given topic.

=item notify_subscribers([$event], @params)

Notify subscribers of a event.

C<$event> and C<@params> are optional. If a C<$event> is given, subscribers to
that event are notified. Subscribers to '*' (I<all events>) are
always notified.

=item delete_subscriber([$event], $subscriber)

Unsubscribes a subscriber from the given event on the publishing item.

If C<$event> is undefined, all subscriptions will be cancelled for the
subscribers.

Returns: The number of remaining subscribers of the given topic.

=item delete_all_subscribers()

Unsubscribes all subscribers from the publisher.

Returns: the number of subscribers removed

=item get_subscribers([$event])

Return the subscribers for the given event. All subscribers for all events will
be returned if no event is given.

=item copy_subscribers($to_object)

Copy subscribers to another publisher item.

Returns: the number of subscribers copied

=item count_subscribers([$count])

Return a count of the subscribers for the given event (or all subscribers of no
event was given).

=back

=head1 DEBUGGING

C<Class::Publisher> has C<Log::Trace> hooks. You can enable debugging with a statement like this:

  use Log::Trace warn => {Deep => 1, Match => 'Class::Publisher'};

See L<Log::Trace> for more options

=head1 AUTHOR

Simon Flack

Based quite heavily on L<Class::Observable|Class::Observable> by Chris Winters

=head1 LICENSE

Class::Publisher is free software which you can redistribute and/or modify
under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::Observable|Class::Observable>

L<Class::ISA|Class::ISA>

L<Class::Trigger|Class::Trigger>

L<Aspect|Aspect>

