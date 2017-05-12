package Catalyst::Authentication::Store::LDAP::AD::Class;

use warnings;
use strict;
use base qw/Class::Accessor::Fast/;
use Catalyst::Authentication::Store::LDAP::AD::Class::User;

=head1 NAME

Catalyst::Authentication::Store::LDAP::AD::Class - The great new Catalyst::Authentication::Store::LDAP::AD::Class!

=head1 VERSION

Version 0.01

=cut

our $VERSION= "0.06";

BEGIN {
	__PACKAGE__->mk_accessors(qw/config/);
}

sub new {
	my ( $class, $config, $app ) = @_;

	## figure out if we are overriding the default store user class
	$config->{'store_user_class'} =
		(exists($config->{'store_user_class'})) ? $config->{'store_user_class'} :
		"Catalyst::Authentication::Store::LDAP::AD::Class::User";

	## make sure the store class is loaded.
	Catalyst::Utils::ensure_class_loaded( $config->{'store_user_class'} );

	bless {config => $config}, $class;
}

sub from_session {
	my ( $self, $c, $frozenuser ) = @_;

	my $user = $self->config->{'store_user_class'}->new($self->{'config'}, $c);
	return $user->from_session($frozenuser, $c);
}

sub for_session {
	my ($self, $c, $user) = @_;

	return $user->for_session($c);
}

sub find_user {
	my ( $self, $authinfo, $c ) = @_;

	my $user = $self->config->{'store_user_class'}->new($self->{'config'}, $c);

	return $user->load($authinfo, $c);
}

sub user_supports {
	my $self = shift;
	# this can work as a class method on the user class
	$self->config->{'store_user_class'}->supports( @_ );
}

=head1 SYNOPSIS

	-Setting up authentication (and others):

		use Catalyst qw/
			ConfigLoader
			Authentication
			Session
			Session::State::Cookie
			Session::Store::DBIC
			Unicode
		/;

	-In YAML config:

		'Plugin::Authentication':
			default:
				credential:
					class             :  'Password'
					password_type     :  'self_check'
					password_field    :  'password'
				store:
					class               :    'LDAP::AD::Class'
					ldap_domain         :    'some.domain.com'
					ldap_global_user    :    'cn=blabla,ou=blabla,dc=bla,dc=bla,.......'
					ldap_global_pass    :    'your AD password'
					ldap_timeout        :    3 # LDAP server connection timeout in seconds
					ldap_base           :    'dc=blabla,dc=blabla,.....' # LDAP base name

=head1 AUTHOR

Andrey Chergik, C<< <andrey at chergik.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-authentication-store-ldap-ad-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/FILIN/ReportBug.html?Queue=Catalyst-Authentication-Store-LDAP-AD-Class>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Catalyst::Authentication::Store::LDAP::AD::Class


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/FILIN/Bugs.html?Dist=Catalyst-Authentication-Store-LDAP-AD-Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Authentication-Store-LDAP-AD-Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Authentication-Store-LDAP-AD-Class>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Authentication-Store-LDAP-AD-Class/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Andrey Chergik.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Catalyst::Authentication::Store::LDAP::AD::Class
