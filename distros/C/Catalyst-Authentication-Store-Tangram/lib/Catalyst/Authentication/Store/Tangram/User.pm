package Catalyst::Authentication::Store::Tangram::User;
use strict;
use warnings;
use base qw/Catalyst::Authentication::User/;
use Carp qw/confess/;
use Scalar::Util qw/blessed/;

use overload '""' => sub { shift->id }, fallback => 1;

BEGIN {
    __PACKAGE__->mk_accessors(qw/_tangram _storage _store _roles/);
}

sub new {
    my ($class, $storage, $tangram_ob, $store) = @_;
    bless { _storage => $storage, _tangram => $tangram_ob, _store => $store }, $class;
}

*get_object = \&_tangram;

sub id {
    my ($self) = @_;
    return $self->_storage->id($self->_tangram);
}

sub roles {
    my ($self) = @_;
    $self->_roles([$self->_store->lookup_roles($self)])
        unless $self->_roles;
    return @{ $self->_roles };
}

sub supported_features {
        return {
        password => { self_check => 0, },
        session  => 1,
        roles    => { self_check => 0, },
    };
}

sub AUTOLOAD {
    my $self = shift;

    ( my $method ) = ( our $AUTOLOAD =~ /([^:]+)$/ );

    return if $method eq "DESTROY";

    confess("Could not call method $method on tangram class " . 
        blessed($self->_tangram)) unless $self->_tangram->can($method);
    $self->_tangram->$method;
}

1;

=head1 NAME

Catalyst::Authentication::Store::Tangram::User - A thin adaptor
to adapt any Tangram class to behave as needed by
L<Catalyst::Authentication::User>

=head1 SYNOPSIS

    $c->user->id; # Returns unique user ID
    $c->user->get('email_address'); # Retrieve value from the underlying Tangram object.
    $c->user->get_object; # Get the underlying Tangram object yourself.

=head1 DESCRIPTION

The Catalyst::Authentication::Store::Tangram::User class encapsulates any
Tangram class in the L<Catalyst::Authentication::User> interface. An instance
of it will be returned by C<< $c->user >> when using
L<Catalyst::Authentication::Store::Tangram>. Methods not defined in this module
are passed through to the Tangram object. The object stringifies to the
Tangram ID.

=head1 METHODS

=head2 new ($class, $storage, $tangram_object)

Simple constructor

=head2 id

Unique Tangram ID for this object

=head2 get_object

Returns the underlying Tangram user object.

=head2 roles

Returns the list of roles which this user is authorised to do.

=head2 supported_features

Returns hashref of features that this Authentication::User subclass supports.

=head1 AUTHOR

Tomas Doran, <bobtfish at bobtfish dot net>

With thanks to state51, my employer, for giving me the time to work on this.

=head1 BUGS

All complex software has bugs, and I'm sure that this module is no exception.

Please report bugs through the rt.cpan.org bug tracker.

=head1 COPYRIGHT

Copyright (c) 2008, state51. Some rights reserved.

This module is free software; you can use, redistribute, and modify it under
the same terms as Perl 5.8.x.

=cut

