package Async::Blackboard;

=head1 NAME

Async::Blackboard - A simple blackboard database and dispatcher.

=head1 SYNOPSIS

  my $blackboard = Async::Blackboard->new();

  $blackboard->watch([qw( foo bar )], [ $object, "found_foobar" ]);
  $blackboard->watch(foo => [ $object, "found_foo" ]);

  $blackboard->put(foo => "First dispatch");
  # $object->found_foo("First dispatch") is called
  $blackboard->put(bar => "Second dispatch");
  # $object->found_foobar("First dispatch", "Second dispatch") is called

  $blackboard->clear;

  $blackboard->put(bar => "Future Dispatch");
  # No dispatch is called...
  # but $blackboard->get("bar") eq "Future Dispatch"

  $blackboard->put(foo => "Another dispatch");

  # Order of the following is undefined, but both are called:
  #
  # $object->found_foo("Future dispatch")
  # $object->found_foobar("Future Dispatch", "Another dispatch")

  $blackboard->hangup;

=head1 DESCRIPTION

Async::Blackboard provides a mechanism for describing the a parallizable
workflow as a series of merge points.  An instance of a given workflow is
associated with a blackboard, which might be cloned from a prototype
blackboard.  The blackboard is a key value store which contains the data
necessary to complete the task in question.

The description of the workflow is in the form of a type of event listener,
which is notified when values are associated with a given set of keys.  Once
values have been published to the blackboard for all of the keys a given
listener is interested in, the listener is invoked given the values.  That
listener then has the opportunity to provide more values.  Used in an
asynchornous I/O bound application, this allows the application workflow to be
intrinsically optimized for parallelism.

=cut

use strict;
use warnings FATAL => "all";
use Carp qw( confess );
use Scalar::Util ();

our $VERSION = "0.3.14";

=head1 CONSTRUCTORS

=over 4

=item new

The new constructor takes no arguments.  If you wish to initialize a blackboard
which is prepopulated, try using the ``build'' constructor, or cloning a
blackboard in a partially run state using the ``clone'' method.

This is done to maintain the guarantee that each listener is notifed once and
only once upon its dependencies being satisifed.

=cut

sub new {
    my ($class) = @_;

    bless {
        -watchers  => {},
        -interests => {},
        -objects   => {},
        -hungup    => 0,
    }, $class;
}

=item build watchers => [ ... ]

=item build values => [ ... ]

=item build watchers => [ ... ], values => [ ... ]

Build and return a blackboard prototype, it takes a balanced list of keys and
array references, with the keys specifying the method to call and the array
reference specifying the argument list.  This is a convenience method which is
short hand explained by the following example:

    my $blackboard = Async::Blackboard->new();

    $blackboard->watch(@$watchers);
    $blackboard->put(@$values);

    # This is equivalent to
    my $blackboard = Async::Blackboard->build(
        watchers => $watchers,
        values   => $values
    );

=cut

sub build {
    confess "Build requires a balanced list of arguments" unless @_ % 2;

    my ($class, %args) = @_;

    my ($watchers, $values) = @args{qw( watchers values )};

    my $blackboard = $class->new();

    $blackboard->watch(@$watchers) if $watchers;
    $blackboard->put(@$values)     if $values;

    return $blackboard;
}

=back

=head1 METHODS

=over 4

=item hungup

Determine whether or not the blackboard has been hung up.  A blackboard which
has been hung up will stop accepting values and release all watcher references.

=cut

sub hungup { shift->{-hungup} }

=item has KEY

Returns true if the blackboard has a value for the given key, false otherwise.

=cut

sub has {
    my ($self, $key) = @_;

    return exists $self->{-objects}->{$key};
}

=item get KEY [, KEY .. ]

Fetch the value of a key.  If given a list of keys and in list context, return
the value of each key supplied as a list.

=cut

sub get {
    my ($self, @keys) = @_;

    if (@keys > 1 && wantarray) {
        return map $self->{-objects}->{$_}, @keys;
    }
    else {
        return $self->{-objects}->{$keys[0]};
    }
}

=item watcher KEY

=item watcher KEYS

Given a key or an array reference of keys, return all watchers interested in
the given key.

=cut

sub watchers {
    my ($self, $keys) = @_;

    $keys = [ $keys ] unless ref $keys;

    return map @{ $self->{-watchers}->{$_} }, @$keys;
}

=item watched

Return a list of all keys currently being watched.

=cut

sub watched {
    my ($self) = @_;

    return keys %{ $self->{-watchers} };
}

=item watch KEYS, WATCHER

=item watch KEY, WATCHER

Given an array ref of keys (or a single key as a string) and an array ref
describing a watcher, register the watcher for a dispatch when the given data
elements are provided.  The watcher may be either an array reference to a tuple
of [ $object, $method_name ] or a subroutine reference.

In the instance that a value has already been provided for this key, the
dispatch will happen immediately.

Returns a reference to self so the builder pattern can be used.

=cut

# Create a callback subref from a tuple.
sub _callback {
    my ($self, $object, $method) = @_;

    return sub {
        $object->$method(@_);
    };

    return $self;
}

# Verify that a watcher has all interests.
sub _can_dispatch {
    my ($self, $watcher) = @_;

    my $interests = $self->{-interests}->{$watcher};

    return @$interests == grep $self->has($_), @$interests;
}

# Dispatch this watcher if it's _interests are all available.
sub _dispatch {
    my ($self, $watcher) = @_;

    my $interests = $self->{-interests}->{$watcher};

    # Determine if all _interests for this watcher have defined keys (some
    # kind of value, including undef).
    $watcher->(@{ $self->{-objects} }{@$interests});
}

# Add the actual listener.
sub _watch {
    my ($self, $keys, $watcher) = @_;

    return if $self->hungup;

    if (ref $watcher eq "ARRAY") {
        $watcher = $self->_callback(@$watcher);
    }

    for my $key (@$keys) {
        push @{ $self->{-watchers}->{$key} ||= [] }, $watcher;
    }

    $self->{-interests}->{$watcher} = $keys;

    $self->_dispatch($watcher) if $self->_can_dispatch($watcher);
}

sub watch {
    my ($self, @args) = @_;

    while (@args) {
        my ($keys, $watcher) = splice @args, 0, 2;

        unless (ref $keys) {
            $keys = [ $keys ];
        }

        $self->_watch($keys, $watcher);
    }
}

sub _found {
    my ($self, $key) = @_;

    my $watchers = $self->{-watchers}->{$key};
    my @ready_watchers = grep $self->_can_dispatch($_), @$watchers;

    for my $watcher (@ready_watchers)
    {
        $self->_dispatch($watcher);

        # Break out of the loop if hangup was invoked during dispatching.
        last if $self->hungup;
    }
}

=item put KEY, VALUE [, KEY, VALUE .. ]

Put the given keys in the blackboard and notify all watchers of those keys that
the objects have been found, if and only if the value has not already been
placed in the blackboard.

=cut

sub put {
    my ($self, %found) = @_;

    my @keys;

    for my $key (grep not($self->has($_)), keys %found) {
        # Unfortunately, because this API was built this API to accept multiple
        # values in a single method invocation, it has to check the value of
        # hangup before every dispatch for hangup to work properly.
        unless ($self->hungup) {
            $self->{-objects}->{$key} = $found{$key};

            $self->_found($key);
        }
    }
}

=item weaken KEY

Weaken the reference to KEY.

When the value placed on the blackboard should *not* have a strong reference
(for instance, a circular reference to the blackboard), use this method to
weaken the value reference to the value associated with the key.

=cut

sub weaken {
    my ($self, $key) = @_;

    Scalar::Util::weaken $self->{-objects}->{$key};
}

=item delete KEY [, KEY ...]

Given a list of keys, remove them from the blackboard.  This method should be
used with I<caution>, since watchers are not notified that the values are
removed but they will be re-notified when a new value is provided.

=cut

sub remove {
    my ($self, @keys) = @_;

    delete @{$self->{-objects}}{@keys};
}

=item replace KEY, VALUE [, KEY, VALUE .. ]

Given a list of key value pairs, replace those values on the blackboard.
Replacements have special semantics, unlike calling `remove` and `put` on a
single key in succession, calling `replace` will not notify any watchers of the
given keys on this blackboard.  But watchers waiting for more than one key who
have not yet been notified, will get the newer value.  Further, replace will
dispatch the found event if the key is new.

=cut

sub replace {
    my ($self, %found) = @_;

    my @new_keys;

    for my $key (keys %found) {
        push @new_keys, $key unless $self->has($key);

        $self->{-objects}->{$key} = $found{$key};
    }

    $self->_found($_) for @new_keys;
}

=item clear

Clear the blackboard of all values.

=cut

sub clear {
    my ($self) = @_;

    $self->{-objects} = {};
}

=item hangup

Clear all watchers, and stop accepting new values on the blackboard.

Once hangup has been called, the blackboard workflow is finished.

=cut

sub hangup {
    my ($self) = @_;

    $self->{-watchers} = {};
    $self->{-hungup}   = 1;
}

=item clone

Create a clone of this blackboard.  This will not dispatch any events, even if
the blackboard is prepopulated.

The clone is two levels, and the two blackboards will operate independently of
one another, but any references stored as values on the blackboard will be
shared between the two instances.

=cut

sub clone {
    my ($self) = @_;

    my $class = ref $self;

    my $objects   = { %{ $self->{-objects}   } };
    my $watchers  = { %{ $self->{-watchers}  } };
    my $interests = { %{ $self->{-interests} } };
    my $hangup    = $self->hungup;

    $interests->{$_} = [ @{ $interests->{$_} } ] for keys %$interests;
    $watchers->{$_}  = [ @{ $watchers->{$_}  } ] for keys %$watchers;

    my $clone = $class->new();

    @$clone{qw( -objects -watchers -interests -hungup )} = ( $objects,
        $watchers, $interests, $hangup );

    return $clone;
}

return __PACKAGE__;

=back

=head1 BUGS

None known, but please submit them to
https://github.com/ssmccoy/Async-Blackboard/issues if any are found, or CPAN
RT.

=head1 LICENSE

Copyright (C) 2011, 2012, 2013 Say Media.

Distributed under the Artistic License, 2.0.

=cut
