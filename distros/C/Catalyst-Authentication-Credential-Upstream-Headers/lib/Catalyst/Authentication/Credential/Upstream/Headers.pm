package Catalyst::Authentication::Credential::Upstream::Headers;
{
  $Catalyst::Authentication::Credential::Upstream::Headers::VERSION = '0.02';
}

# ABSTRACT: Catalyst authentication credentials from HTTP headers

use Moose;

has user_header =>
	isa			=> 'Str',
	is			=> 'ro',
	default		=> 'X-Catalyst-Credential-Upstream-User';

has role_header =>
	isa			=> 'Str',
	is			=> 'ro',
	default		=> 'X-Catalyst-Credential-Upstream-Roles';

has role_delimiter =>
	isa			=> 'Str',
	is			=> 'ro',
	default		=> '|';

has use_x500_cn =>
	isa			=> 'Bool',
	is			=> 'ro',
	default		=> 1;

has realm =>
	isa			=> 'Catalyst::Authentication::Realm',
	is			=> 'ro',
	required	=> 1;

sub BUILDARGS
{
	my $class	= shift;
	my $config	= shift;
	my $app		= shift;
	my $realm	= shift;

	return { %$config, realm => $realm };
}

sub authenticate
{
	my $self	= shift;
	my $c		= shift;

	# This method is a no-op for the most part.  The work that is done
	# here is mostly marshalling the request headers into user objects
	# that fit the authentication plugin's interface.

	my $user		= undef;
	my $delimiter	= $self->role_delimiter;

	if (my $username = $c->req->headers->header($self->user_header)) {
		my @roles = split /\Q$delimiter\E */, $c->req->headers->header($self->role_header) || '';

		# attempt to extract the cn (common name) component of anything
		# that looks like it might be an X.501 distinguished name

		@roles = map { { split /[;,= ]+/ }->{cn} || $_ } @roles
			if $self->use_x500_cn;

		$user = { id => $username, roles => \@roles };
	}

	return $user ? $self->realm->find_user($user) : undef;
}

1;

__END__

=head1 NAME

Catalyst::Authentication::Credential::Upstream::Headers

=head1 SYNOPSIS

 use Catalyst qw(Authentication);

 __PACKAGE__->config(
     authentication => {
         default_realm => 'upstream',
         realms => {
             upstream => {
                 credential => {
                     class => 'Upstream::Headers',

                     # name of header containing the user id
                     user_header => 'X-Catalyst-Credential-Upstream-User',

                     # name of header containing a delimited list of user roles
                     role_header => 'X-Catalyst-Credential-Upstream-Roles',

                     # the delimiter to use when parsing roles
                     role_delimiter => '|',

                     # boolean value indicating whether or not to attempt to
                     # parse roles as X.500 distinguished names
                     use_x500_cn => 1
                 }
             }
         }
     }
 );

=head1 DESCRIPTION

The Upstream::Headers credential class provides for passing identity
metadata to the application via HTTP headers.  These headers might be
appended by an HTTP front-end that performs authentication services
before reverse proxying to the application.

In addition to the username, a list of delimited roles may be passed.
The delimiter is configurable by setting the role_delimiter property
in the config.  By default, the pipe character ('|') is used for the
delimiter.

By default, roles are crudely checked to see if they look like X.501
distinguished names.  If so, the commonName (cn) component of the DN
is returned instead of the full DN.  This behavior may be disabled by
setting use_x500_cn to false in the config.

=head1 HISTORY

This authentication credential for Catalyst::Plugin::Authentication
was originally implemented to support OpenAM in a way that fit into
the framework provided by C::P::A.

OpenAM (formerly Sun's OpenSSO) is a federated identity management
platform.  It is a complex product supporting SAML and integration
with Microsoft's Active Directory.  OpenAM provides authentication
and authorization services to web applications by utilizing agents
that run in front of the application.  The agents are implemented as
plugins for popular HTTP servers, injecting logic into the request
handler and applying policy based upon upstream configuration.

One of the methods of passing identity information back down to the
application is by including the information in the request headers.
This is similar in scope to the Credential::Remote implementation,
but using headers instead of environment variables.

=head1 CAVEATS

=over 2

=item

I really hope I don't have to say it, but don't let users bypass
your authentication mechanisms by passing the headers themselves.

=item

This is a pretty crappy way of passing identity metadata around.

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

