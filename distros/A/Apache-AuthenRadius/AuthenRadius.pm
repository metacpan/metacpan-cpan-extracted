package Apache::AuthenRadius;

# $Id: AuthenRadius.pm,v 1.2 1999/07/31 22:14:23 daniel Exp $
#
# Added digest authentication by Mike McCauley mikem@open.com.au
# especially so it could be used with RadKey token based
# authentication modules for IE5 and Radiator
# http://www.open.com.au/radiator
# http://www.open.com.au/radkey
#
# For Digest Requires Authen::Radius, at least version 0.06 which
# can handle passwords longer than 16 bytes

use strict;
use warnings;
use Authen::Radius;
use Net::hostent;
use Socket;
use vars qw($VERSION);

$VERSION = '0.9';

use mod_perl;
use constant MP2 => $mod_perl::VERSION < 1.99 ? 0 : 1;

=head1 NAME

Apache::AuthenRadius - Authentication via a Radius server

=head1 SYNOPSIS

 # Configuration in httpd.conf

 PerlModule Apache::AuthenRadius

 # Authentication in .htaccess

 AuthName Radius

 AuthType Digest or AuthType Basic

 # authenticate via Radius
 PerlAuthenHandler Apache::AuthenRadius

 PerlSetVar Auth_Radius_host radius.foo.com
 PerlSetVar Auth_Radius_port 1647
 PerlSetVar Auth_Radius_secret MySharedSecret
 PerlSetVar Auth_Radius_timeout 5

 # This allows you to append something to the user name that
 # is sent to the RADIUS server
 # usually a realm so the RADIUS server can use it to
 # discriminate between users
 PerlSetVar Auth_Radius_appendToUsername @some.realm.com

 require valid-user

=head1 DESCRIPTION

This module allows Basic and Digest authentication against a Radius server.

=head1 PUBLIC METHODS

=cut
  
BEGIN {

	if (MP2) {

		require Apache::Access;
		require Apache::RequestRec;
		require Apache::RequestUtil;
		require Apache::RequestIO;
		require Apache::Const;
		require Apache::Log;
		Apache::Const->import(-compile => qw(OK AUTH_REQUIRED DECLINED SERVER_ERROR));

	} else {

		require Apache;
		require Apache::Constants;
		Apache::Constants->import(qw(OK AUTH_REQUIRED DECLINED SERVER_ERROR));
	}
}

=head2 handler( $r )

The mod_perl handler.

=cut
 
sub handler {
	my $r    = shift;
	my $type = (MP2 ? $r->ap_auth_type() : $r->auth_type()) || 'Basic';

	# Now choose a handler depending on the auth type
	if ($type eq 'Basic') {

		return _handler_basic($r);

	} elsif ($type eq 'Digest') {

		return _handler_digest($r);

	} else {

		# Never heard of it
		$r->log_error("Apache::AuthenRadius unknown AuthType", $type);
		return MP2 ? Apache::DECLINED() : Apache::Constants::DECLINED();
	}
}

sub _handler_basic {
	my $r = shift;
	
	# Continue only if the first request.
	return OK() unless $r->is_initial_req();

	my $reqs_arr = $r->requires() || return OK();

	# Grab the password, or return if HTTP_UNAUTHORIZED
	my($res,$pass) = $r->get_basic_auth_pw();
	return $res if $res;

	# Get the user name.
	my $user = MP2 ? $r->user() : $r->connection->user();

	# Sanity for usernames and passwords.
	if (length $user > 64 or $user =~ /[^A-Za-z0-9@_-.]/) {

		$r->log_error("Apache::AuthenRadius username too long or contains illegal characters", $r->uri());
		$r->note_basic_auth_failure();
		return AUTH_REQUIRED();
	}

	if (length $pass > 256) {

		$r->log_error("Apache::AuthenRadius password too long", $r->uri());
		$r->note_basic_auth_failure();
		return AUTH_REQUIRED();
	}

	return _authen_radius($r, $user, $pass);

}

sub _handler_digest {
	my $r = shift;

	# Continue only if the first request.
	return OK() unless $r->is_initial_req();

	my $reqs_arr = $r->requires() || return OK();

	# Get the authorization header, if it exists
	my %headers   = $r->headers_in();
	my $auth      = $headers{$r->proxyreq()} ?  'Proxy-Authorization' : 'Authorization';
	my $algorithm = $r->dir_config("Auth_Radius_algorithm") || 'MD5';
	my $realm     = $r->auth_name();

	unless ($auth) {

		# No authorization supplied, generate a challenge
		my $nonce = time();

		# XXX
		$r->err_header_out($r->proxyreq() ?
			'Proxy-Authenticate' : 'WWW-Authenticate', 
			"Digest algorithm=\"$algorithm\", nonce=\"$nonce\", realm=\"$realm\""
		);

		return AUTH_REQUIRED();
	}

	# This is a response to a previous challenge
	# extract some intersting data and send it to the Radius
	# server

	# Get the user name.
	my ($user) = ($auth =~ /username="([^"]*)"/);

	# REVISIT: check that the uri is correct
	unless ($r->proxyreq()) {
		my ($uri) = ($auth =~ /uri="([^"]*)"/);
		return DECLINED() unless $r->uri() eq $uri;
	}

	# check the nonce is not stale
	my $nonce_lifetime = $r->dir_config('Auth_Radius_nonce_lifetime') || 300;
	my ($nonce) = ($auth =~ /nonce="([^"]*)"/);

	if ($nonce < time() - $nonce_lifetime) {

		# Its stale. Send back another challenge	
		$nonce = time();

		# XXXX
		$r->err_header_out($r->proxyreq() ?
			'Proxy-Authenticate' : 'WWW-Authenticate', 
			"Digest algorithm=\"$algorithm\", nonce=\"$nonce\", realm=\"$realm\", stale=\"true\""
		);

		return AUTH_REQUIRED();
	}
	 
	# Send the entire Authorization header as the password
	# let the radius server figure it out
	my $pass = $auth; 

	# Sanity for usernames and passwords.
	if (length $user > 64) {

		$r->log_error("Apache::AuthenRadius username too long or contains illegal characters", $r->uri());
		return AUTH_REQUIRED();
	}

	if (length $pass > 256) {

		$r->log_error("Apache::AuthenRadius password too long", $r->uri());
		return AUTH_REQUIRED();
	}

	return _authen_radius($r, $user, $pass);
}

sub _authen_radius {
	my ($r, $user, $pass) = @_;

	# Radius Server and port.
	my $host   = $r->dir_config("Auth_Radius_host") or return DECLINED();
	my $port   = $r->dir_config("Auth_Radius_port") || 1647;
	my $ident  = $r->dir_config("Auth_Radius_ident") || 'apache';
	my $ip     = inet_ntoa(gethost($r->hostname)->addr);

	# Shared secret for the host we are running on.
	my $secret = $r->dir_config("Auth_Radius_secret") or return DECLINED();

	# Timeout to wait for a response from the radius server.
	my $timeout = $r->dir_config("Auth_Radius_timeout") || 5;

	# Create the radius connection.
	my $radius = Authen::Radius->new(
		'Host'    => "$host:$port",
		'Secret'  => $secret,
		'TimeOut' => $timeout,
	);

	# Error if we can't connect.
	if (!$radius) {
		$r->log_error("Apache::AuthenRadius failed to connect to $host: $port",$r->uri());
		return SERVER_ERROR();
	}

	# Possibly append somthing to the users name, so we can
	# flag to the radius server where this request came from
	# Clever radius servers like Radiator can then discriminate
	# between web users and dialup users
	$user .= $r->dir_config("Auth_Radius_appendToUsername");

	# Do the actual check by talking to the radius server
	if ($radius->check_pwd($user,$pass)) {

		return OK();

	} else {

		$r->log_error("Apache::AuthenRadius rejected user $user", $r->uri());
		return AUTH_REQUIRED();
	}
}

1;

__END__

=head1 LIST OF TOKENS

=over 4

=item * Auth_Radius_host

The Radius server host: either its name or its dotted quad IP number.
The parameter is passed as the PeerHost option to IO::Socket::INET->new.

=item * Auth_Radius_port

The port on which the Radius server is listening: either its service name or
its actual port number. This parameter defaults to "1647" which is the
official service name for Radius servers. The parameter is passed as the
PeerPort option to IO::Socket::INET->new.

=item * Auth_Radius_secret

The shared secret for connection to the Radius server.

=item * Auth_Radius_timeout

The timeout in seconds to wait for a response from the Radius server.

=item * Auth_Radius_algorithm

For Digest authentication, this is the algorithm to use. Defaults to 'MD5'.
For Basic authentication, it is ignored. If Digest authentication is set,
unauthenticated requests will be sent a Digest challenge, including a nonce.
Authenticated requests will have the nonce checked against
Auth_Radius_nonce_lifetime, then the whole Authentication header sent as the
password to RADIUS.

=item * Auth_Radius_appendToUsername

Appends a string to the end of the user name that is sent to RADIUS.  This
would normally be in the form of a realm (i.e. @some.realm.com) This is useful
where you might want to discriminate between the same user in several
contexts. Clever RADIUS servers such as Radiator can use the realm to let the
user in or no depending on which protected Apache directory they are trying to
access.

=item * Auth_Radius_nonce_lifetime

Specifies the maximum nonce lifetime in seconds for Digest authentication.
This parameter allows you to change the nonce lifetime for Digest
authentication. Digest authentications whose nonce exceeds the maximum
lifetime are declined. Defaults to 300 seconds.

=back

=head1 CONFIGURATION

The module should be loaded upon startup of the Apache daemon.
Add the following line to your httpd.conf:

 PerlModule Apache::AuthenRadius

=head1 PREREQUISITES

For AuthenRadius you need to enable the appropriate call-back hook 
when making mod_perl: 

  perl Makefile.PL PERL_AUTHEN=1

For Digest authentication, you will need Authen::Radius version 
0.06 or better. Version 0.05 only permits 16 byte passwords

=head1 SEE ALSO

L<Apache>, L<mod_perl>, L<Authen::Radius>

=head1 AUTHORS

Authen::Radius by Carl Declerck L<carl@miskatonic.inbe.net>

Apache::AuthenRadius by Dan Sully <daniel | AT | cpan.org>

=head1 COPYRIGHT

The Apache::AuthenRadius module is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
