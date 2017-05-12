package Backbone::Events;
$Backbone::Events::VERSION = '0.0.3';
use Carp qw(confess);
use List::MoreUtils qw(any none);
use Scalar::Util qw(blessed);
use Moo::Role;
use namespace::autoclean -also => qr/^__/;

# ABSTRACT: a port of the Backbone.js event API


has _bbe_events => (
    is      => 'ro',
    default => sub { {} },
);

has _bbe_id => (
    is      => 'ro',
    default => sub { __new_id() },
);

has _bbe_listening_to => (
    is      => 'ro',
    default => sub { {} },
);

our $__last_id;
sub __new_id { ++$__last_id }

sub _bbe_trigger {
    my ($self, $event_ref, $event, @args) = @_;
    my $cb = $event_ref->{cb};

    if (any {$_ eq 'all'} @{$event_ref}{qw(ns type)}) {
        $cb->($event, @args);
    } else {
        $cb->(@args);
    }

    if ($event_ref->{once}) {
        my ($event, $listen_id) = @{$event_ref}{qw(event listen_id)};
        $self->off($event, $cb, listen_id => $listen_id//'');
    }
}

sub __wrap_multiple_events {
    my ($orig, $self, $events, @args) = @_;
    if (ref $events eq 'HASH') {
        $self->$orig($_, $events->{$_}, @args) for keys %$events;
    } elsif ($events and $events =~ /\s+/) {
        my $result;
        $result = $self->$orig($_, @args) for split /\s+/, $events;
        # return last result
        return $result;
    } else {
        return $self->$orig($events, @args);
    }
}

sub ___wrap_multiple_events2 {
    my ($orig, $self, $other, $events, @args) = @_;
    if (ref $events eq 'HASH') {
        $self->$orig($other, $_, $events->{$_}, @args) for keys %$events;
    } elsif ($events and $events =~ /\s+/) {
        my $result;
        $result = $self->$orig($other, $_, @args) for split /\s+/, $events;
        # return last result
        return $result;
    } else {
        return $self->$orig($other, $events, @args);
    }
}

sub __parse_event {
    my ($event) = @_;
    # handle two edge cases
    # if passed undef, return empty strings so comparisons don't warn
    return ( '',    ''    ) unless defined $event;
    # and the 'all' event should get the 'all' namespace
    return ( 'all', 'all' ) if $event eq 'all';

    if (my ($ns, $type) = $event =~ /(.*):(.*)/) {
        return ($ns, $type);
    } else {
        return ('', $event);
    }
}

sub __query {
    my ($ids, $q) = @_;
    return grep {
        my $id    = $_;
        my $match = 1;
        for my $field (keys %$q) {
            my $have = $ids->{$id}{$field} // '';
            my $want = $q->{$field};

            my $type = ref $want;
            if ($type eq 'ARRAY') {
                if (none {$_ eq $have} @$want) {
                    $match = 0;
                    last;
                }
            } else {
                if ($want ne $have) {
                    $match = 0;
                    last;
                }
            }
        }
        $match;
    } keys %$ids;
}

sub __does_events {
    my ($obj) = @_;
    return $obj
        && blessed($obj)
        && $obj->DOES(__PACKAGE__);
}

around on => \&__wrap_multiple_events;
sub on {
    my ($self, $event, $cb, %opts) = @_;
    my ($ns, $type) = __parse_event($event);
    $self->_bbe_events->{__new_id()} = {
        %opts,
        cb   => $cb,
        ns   => $ns,
        type => $type,
    };
    return $cb;
}

around off => \&__wrap_multiple_events;
sub off {
    my ($self, $event, $cb, %opts) = @_;
    my ($ns, $type) = __parse_event($event);

    my @ids = __query($self->_bbe_events, {
        %opts,
        ( cb   => $cb   )x!! $cb,
        ( ns   => $ns   )x!! $ns,
        ( type => $type )x!! $type,
    });
    delete @{$self->_bbe_events}{@ids};
}

around trigger => \&__wrap_multiple_events;
sub trigger {
    my ($self, $event, @args) = @_;
    my ($ns, $type) = __parse_event($event);

    my @ids = __query($self->_bbe_events, {
        ns   => [ 'all', $ns   ],
        type => [ 'all', $type ],
    });

    for my $id (@ids) {
        my $event_ref = $self->_bbe_events->{$id};
        $self->_bbe_trigger($event_ref, $event, @args);
    }
}

around once => \&__wrap_multiple_events;
sub once {
    my ($self, $event, $cb) = @_;
    $self->on($event, $cb, once => 1);
    return $cb;
}

around listen_to => \&___wrap_multiple_events2;
sub listen_to {
    my ($self, $other, $event, $cb, %opts) = @_;
    confess "Cannot call listen_to on object that does not consume Backbone::Events"
        if not __does_events($other);

    my ($ns, $type) = __parse_event($event);
    $self->_bbe_listening_to->{__new_id()} = {
        %opts,
        cb       => $cb,
        event    => $event,
        ns       => $ns,
        other    => $other,
        other_id => $other->_bbe_id,
        type     => $type,
    };
    $other->on($event, $cb, %opts, listen_id => $self->_bbe_id);

    return $cb;
}

around stop_listening => \&___wrap_multiple_events2;
sub stop_listening {
    my ($self, $other, $event, $cb) = @_;
    my ($ns, $type) = __parse_event($event);
    confess "Cannot call stop_listening on object that does not consume Backbone::Events"
        if $other and not __does_events($other);

    my $query = {
        ( cb   => $cb   )x!! $cb,
        ( ns   => $ns   )x!! $ns,
        ( type => $type )x!! $type,
    };
    $query->{other_id} = $other->_bbe_id if $other;
    my @ids = __query($self->_bbe_listening_to, $query);

    for my $id (@ids) {
        my $listen_ref = $self->_bbe_listening_to->{$id};
        my $other_obj  = $listen_ref->{other};
        my @args       = @{$listen_ref}{qw(event cb)};
        $other_obj->off(@args, listen_id => $self->_bbe_id);
    }
    delete @{$self->_bbe_listening_to}{@ids};
}

around listen_to_once => \&___wrap_multiple_events2;
sub listen_to_once {
    my ($self, $other, $event, $cb) = @_;
    $self->listen_to($other, $event, $cb, once => 1);
    return $cb;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Backbone::Events - a port of the Backbone.js event API

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS

    package MyProducer {
        use Moo;
        with 'Backbone::Events';
    };
    my $pub = MyProducer->new;

    package MySubscriber {
        use Moo;
        with 'Backbone::Events';
    };
    my $sub = MySubscriber->new;

    $sub->listen_to($pub, 'some-event', sub { ... })
    ...
    $pub->trigger('some-event', qw(args for callback));

=head1 DESCRIPTION

Backbone::Events is a Moo::Role which provides a simple interface for binding
and triggering custom named events. Events do not have to be declared before
they are bound, and may take passed arguments.

Events can be optionally namespaced by prepending the event with the
namespace: '$namespace:$event'.

=head1 METHODS

=head2 on($event, $callback)

Bind a callback to an object.

Callbacks bound to the special 'all' event will be triggered when any event
occurs, and are passed the name of the event as the first argument.

Returns the callback that was passed. This is mainly so anonymous functions
can be returned, and later passed back to 'off'.

=head2 off([$event], [$callback])

Remove a previously-bound callback from an object.

=head2 trigger($event, @args)

Trigger callbacks for the given event.

=head2 once($event, $callback)

Just like 'on', but causes the bound callback to fire only once before being
removed.

Returns the callback that was passed. This is mainly so anonymous functions
can be returned, and later passed back to 'off'.

=head2 listen_to($other, $event, $callback)

Tell an object to listen to a particular event on an other object.
The other object must consume the Backbone::Events role.

Returns the callback that was passed. This is mainly so anonymous functions
can be returned, and later passed back to 'stop_listening'.

=head2 stop_listening([$other], [$event], [$callback])

Tell an object to stop listening to events.

=head2 listen_to_once($other, $event, $callback)

Just like 'listen_to', but causes the bound callback to fire only once before
being removed.

Returns the callback that was passed. This is mainly so anonymous functions
can be returned, and later passed back to 'stop_listening'.

=head1 SEE ALSO

L<http://backbonejs.org/#Events>

=head1 AUTHOR

Mark Flickinger

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Mark Flickinger.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
