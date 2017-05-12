#!/usr/bin/perl

package Catalyst::Plugin::Session::Defaults;

use strict;
use warnings;

use Storable ();
use Carp ();

our $VERSION = "0.01";

sub default_session_data {
    my $c = shift;
    my $def = $c->config->{session}{defaults} || {};

    no warnings "uninitialized";
    Carp::croak("The default session data must be a hash reference")
        unless ref $def eq "HASH";

    return Storable::dclone( $def );
}

sub initialize_session_data {
	my ( $c, @args ) = @_;
	my $data = $c->NEXT::initialize_session_data( @args );
	
	my $defaults = $c->default_session_data;

	@{ $data }{ keys %$defaults } = values %$defaults;

	return $data;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Session::Defaults - Default values in your session.

=head1 SYNOPSIS

	use Catalyst qw/
        Session
        Session::Store::Moose
        Session::State::Cookie
        Session::Defaults
    /;

    __PACKAGE__->config->{session}{defaults} = {
        likes_moose => 1,
    };

=head1 DESCRIPTION

This plugin lets you add default values to the intiial data that a session will
be created with.

You can either go with a hash in the session configuration key C<defaults>, or
you can override the C<default_session_data> method to return a hash dynamically.

=head1 METHODS

=over 4

=item default_session_data

This method returns a deep clone of

    YourApp->config->{session}{defaults}

or an empty hash if there is no such key.

It will die on bad data.

=back

=head1 OVERRIDDEN METHODS

=over 4

=item initialize_session_data

This method is overridden to provide the hook that calls
C<default_session_data>.

=back

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Session>

=head1 AUTHOR

Yuval Kogman, C<nothingmuch@woobling.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

