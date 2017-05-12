#!/usr/bin/perl

package Catalyst::Continuation;
use Moose;

use strict;
use warnings;

use Storable ();
use Carp qw/croak/;

use overload '""' => "uri";

use Data::Visitor::Callback;

sub Catalyst::Continuation::SerializedAction::new {
    my ( $class, $action ) = @_;
    bless \( $action->reverse ), $class;
}

has id => (
    isa => "Str",
    is  => "ro",
);

has c => (
    isa      => "Catalyst",    # FIXME Catalyst::Context
    is       => "ro",
    weak_ref => 1,
);

has saved_in_store => (
    isa     => "Bool",
    is      => "rw",
    default => 0,
);

has forward_to_caller => (
    isa     => "Str",
    is      => "rw",
    lazy    => 1,
    default => "",
);

has method => (
    isa     => "Str",
    is      => "rw",
    default => "forward",
);

has auto_delete => (
    isa     => "Bool",
    is      => "rw",
    default => 1,
);

has caller => (
    is  => "ro",
);

# this is what we are forwarding to, simply the args to ->forward
has forward => ( isa => "ArrayRef", is => "ro" );

has stash              => ( isa => "HashRef",  is => "ro" );
has action             => ( is => "ro" );
has namespace          => ( isa => "Str",      is => "ro" );
has state              => ( is => "ro" );
has request_arguments  => ( isa => "ArrayRef", is => "ro" );
has request_action     => ( isa => "Str",      is => "ro" );
has request_path       => ( isa => "Str",      is => "ro" );
has request_match      => ( isa => "Str",      is => "ro" );
has request_parameters => ( isa => "HashRef",  is => "ro" );

my %unsaved_attrs = map { $_ => undef } qw/id c saved_in_store/;
my %meta_attrs = map { $_ => undef } qw/forward_to_caller method auto_delete/;

sub new {
    my ( $class, %attrs ) = @_;

    croak 'You must provide something to forward to'
      unless exists $attrs{forward};
    croak 'You must provide the $c object' unless my $c = $attrs{c};

    my $v = Data::Visitor::Callback->new(
        'Catalyst::Action' => sub {
            Catalyst::Continuation::SerializedAction->new( $_ );
        },
    );

    %attrs = (
        %attrs,
        id     => $c->generate_continuation_id,
        action => $v->visit( $c->action ),
        caller  => $v->visit( $c->stack->[-1] ),
    );

    # initialize all the "dumb" fields
    foreach my $attr (
        grep { not exists $attrs{$_} }
        grep { not exists $meta_attrs{$_} }
        grep { not exists $unsaved_attrs{$_} }
        keys %{ $class->meta->get_attribute_map }
      )
    {
        my $value = $c;
        my @chain = split '_', $attr;
        while (@chain) {
            my $meth = shift @chain;
            $value = $value->$meth;
        }

        $attrs{$attr} = ref($value) ? Storable::dclone($value) : $value;
    }

    $class->SUPER::new(%attrs);
}

sub new_from_store {
    my ( $class, $c, $id ) = @_;
    my $fields = Storable::dclone( $c->get_continuation($id) || return );
    $class->SUPER::new(
        forward_to_caller => "forward",
        %$fields,
        id => $id,
        c  => $c,
    );
}

sub save_in_store {
    my $self = shift;

    unless ( $self->saved_in_store ) {
        $self->c->set_continuation( $self->id => $self->as_hashref );
        $self->saved_in_store(1);
    }
}

sub delete_from_store {
    my $self = shift;

    $self->saved_in_store(0);
    $self->c->delete_continuation( $self->id );
}

sub as_hashref {
    my $self = shift;

    return {
        map { $_ => $self->$_ }
          grep { exists $self->{$_} }
          grep { not exists $unsaved_attrs{$_} }
          keys %{ $self->meta->get_attribute_map },
    };
}

sub as_deep_hashref {
    my $self      = shift;
    my $localized = $self->as_hashref;
    my $ret       = {};

    foreach my $key ( grep { not exists $meta_attrs{$_} } keys %$localized ) {
        my @chain = split '_', $key;
        my $last  = pop @chain;
        my $value = $ret;

        while (@chain) {
            $value = ( $value->{ shift @chain } ||= {} );
        }

        $value->{$last} = delete $localized->{$key};
    }

    my $d = $self->c->dispatcher;

    my $v = Data::Visitor::Callback->new(
        "Catalyst::Continuation::SerializedAction" => sub {
            $d->get_action_by_path( $$_ );
        }
    );

    $v->visit( $ret );
}

sub uri {
    my $self = shift;
    $self->save_in_store;
    $self->c->_uri_to_cont( $self );
}

sub execute {
    my $self = shift;

    my $c = $self->c;

    my $localized = $self->as_deep_hashref;

    my $caller = delete $localized->{caller};
    my $forward = delete $localized->{forward};

    $localized->{stack} = [ @{ $c->stack }, $caller ];

    my $stats_info = $c->_stats_start_execute( $caller );
    if ( my $node = $stats_info->{node} ) {
        $node->getNodeValue->{comment} = " (continuation)";
    }

    my $ret = $c->_localize_fields(
        $localized,
        sub {
            $c->forward(@$forward);
            if ( my $meth = $self->forward_to_caller ) {
                $meth = "forward" unless $c->can($meth);
                $c->$meth( "/" . $caller->reverse );
            }
        }
    );

    $self->delete_from_store if $self->auto_delete;

    $c->_stats_finish_execute( $stats_info );

    return $ret;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Continuation - Pseudo-continuation objects for Catalyst

=head1 SYNOPSIS

    $c->cont("foo");

=head1 DESCRIPTION

This object is returned by the L<Catalyst::Plugin::Continuation/cont> method.
It captures the current state of execution within the context object as best as
it can, within the limitations perl and Perl.

Please do not try to construct it directly.

=head1 METHODS

=head2 new %attrs

Create a continuation

=head2 new_from_store

Restore a continuation. Takes a value as returned by C<as_hashref>. Requires
the C<$c> object to be specified.

=head2 as_hashref

Returns a hash ref that can be serialized. This is required for serialization
due to the fact that C<$c> is different between requests.

=head2 as_deep_hashref

Create the structure that shadows C<$c>'s fields. Suitable for passing to C<_localize_fields>.

=head2 id

The ID of this continuation.

=head2 execute

Invoke the continuation, localizing the whole $c object to what it was when the
continuation was created, and calling the ->forward.

See also C<forward_to_caller> for what happens once this is done.

=head2 uri

This method will return a URI that will cause the continuation to be reinvoked.

It automatically calls C<save_in_store>, in order to allow this continuation to
be invoked from different requests.

=head2 save_in_store

This method causes the continuation to ask the C<$c> object to save it
somewhere. This is handled by L<Catalyst::Plugin::Continuation>, and any
overrides that may have been added.

=head2 delete_from_store

The inverse of C<saved_in_store>.

=head2 method

Which method to invoke on C<$c> as the continuation.

Defaults to C<forward>.

=head2 forward

The argumetns to pass to C<method>. This is an array reference, typically
containing the string of the path to forward to.

=head2 forward_to_caller

Whether or not to ->forward back to the action that created the continuation.
This defaults to true when a continuation is being restored from storage in a
new request, and defaults to false otherwise.

When false nothing happens. When true defaults to a regular forward. When any
string, invokes that method.

=head2 auto_delete

Whether or not a continuation should delete itself after being executed.

Defaults to true.

=head2 meta

This is thte L<Moose> meta class instance for the continuation's class.

=head2 saved_in_store

=head2 c

These two fields are used internally to integrate the continuation with the current request.

=head1 SAVED FIELDS

These paramters contain the collected data. You may use this as a reference to
find out what is saved/restored when a continuation is created/executed.

=over 4

=item stash

=item action

=item namespace

=item request_parameters

=item request_arguments

=item request_path

=item request_match

=item request_action

=item state

These correspond to the methods/fields of $c.

=item caller

The last element on C<< $c->stack >>

=back

=cut


