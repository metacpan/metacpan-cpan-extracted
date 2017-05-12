#!/usr/bin/perl

package Catalyst::Authentication::Store::Htpasswd::User;
use base qw/Catalyst::Authentication::User Class::Accessor::Fast/;

use strict;
use warnings;

BEGIN { __PACKAGE__->mk_accessors(qw/_user _store/) }

use overload '""' => sub { shift->id }, fallback => 1;

sub new {
	my ( $class, $store, $user ) = @_;

	return unless $user;

	bless { _store => $store, _user => $user }, $class;
}

sub id {
    my $self = shift;
    return $self->_user->username;
}

sub supported_features {
	return {
        password => {
            self_check => 1,
		},
        session => 1,
        roles => 1,
	};
}

sub check_password {
	my ( $self, $password ) = @_;
	return $self->_user->check_password( $password );
}

sub roles {
	my $self = shift;
	my $field = $self->_user->extra_info->[0];
	return defined $field ? split /,/, $field : ();
}

*for_session = \&id;

*get_object = \&_user;

sub AUTOLOAD {
	my $self = shift;
	
	( my $method ) = ( our $AUTOLOAD =~ /([^:]+)$/ );

	return if $method eq "DESTROY";
	
	$self->_user->$method;
}

1;

__END__

=pod

=head1 NAME

Catalyst::Authentication::Store::Htpasswd::User - A user object
representing an entry in an htpasswd file.

=head1 DESCRIPTION

This object wraps an L<Authen::Htpasswd::User> object. An instance of it will be returned
by C<< $c->user >> when using L<Catalyst::Authentication::Store::Htpasswd>. Methods 
not defined in this module are passed through to the L<Authen::Htpasswd::User> object. The
object stringifies to the username.

=head1 METHODS

=head2 new($store,$user)

Creates a new object from a store object, normally an instance of 
L<Catalyst::Authentication::Store::Htpasswd::Backend>, and a user object,
normally an instance of L<Authen::Htpasswd::User>.

=head2 id

Returns the username.

=head2 check_password($password)

Returns whether the password is valid.

=head2 roles

Returns an array of roles, which is extracted from a comma-separated list in the
third field of the htpasswd file.

=head2 for_session

Returns the username, which is then stored in the session.

=head2 supported_features

Returns data about which featurs this user module supports.

=head2 get_object

Returns the underlieing L<Authen::Htpasswd::User> object for this user

=head1 AUTHORS

Yuval Kogman C<nothingmuch@woobling.org>

David Kamholz C<dkamholz@cpan.org>

Tomas Doran C<bobtfish@bobtfish.net>

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2005 the aforementioned authors. All rights
	reserved. This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut


