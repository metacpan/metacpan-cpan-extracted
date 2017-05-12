# $Id: AuthenSecurID.pm,v 1.7 2007/12/08 03:20:58 atobey Exp $

package Apache2::AuthenSecurID;

use strict;
use Apache2::Const qw(OK AUTH_REQUIRED DECLINED REDIRECT SERVER_ERROR);
use Apache2::RequestUtil ();
use Apache2::RequestRec ();
use Apache2::Cookie;
use Crypt::CBC;
use CGI::Carp;
use vars qw($VERSION);

$VERSION = '0.5';

sub handler {
	my $r = shift;


	# get configuration directives
	my $auth_cookie = $r->dir_config("AuthCookie") || "SecurID";
	my $auth_user_cookie = $r->dir_config("AuthUserCookie")||"SecurID_User";

	my $crypt_key = $r->dir_config("AuthCryptKey") || "my secret";

	my $cookie_timeout = $r->dir_config("AuthCookieTimeOut") || 30;
	my $cookie_path = $r->dir_config("AuthCookiePath") || "/";

	my $auth_handler = $r->dir_config("Auth_Handler") || "/ace_init";

	# get cookies
	my ( $session_key ) = ( ($r->headers_in->{Cookie} || "") =~ 
		/${auth_cookie}=([^;]+)/);
	my ( $session_user ) = ( ($r->headers_in->{Cookie} || "") =~ 
		/${auth_user_cookie}=([^;]+)/);


	my $username;
	my $session_time;
	
	# decrypt cookie
	my $cipher = new Crypt::CBC($crypt_key,"Blowfish") || warn ( $! );
	if ( $session_key )  {
		my $plaintext_cookie = $cipher->decrypt_hex($session_key);
		( $session_time, $username ) = split /\:/, $plaintext_cookie;
	}
	
	my $time = time();
	my $timeout = $time - 60 * $cookie_timeout;
	my $uri = $r->uri;

	# check cookie
	if ( $session_key && $username eq $session_user &&
 	   $timeout <= $session_time ) {
		$r->no_cache(1);
		$r->err_headers_out->add("Pragma" => "no-cache" ); 
		#reset timestamp
		my $crypt_cookie = $cipher->encrypt_hex ("$time:$username");
		$r->err_headers_out->add("Set-Cookie" => $auth_cookie . "=" .
			$crypt_cookie . "; path=" . $cookie_path );
		return OK; 
	} else {
		# redirect to authentication handler
		my $uri = $cipher->encrypt_hex ( $uri );
		$r->no_cache(1);
		$r->err_headers_out->add("Pragma" => "no-cache");
                $r->headers_out->add("Location" => "$auth_handler?a=" . $uri  );
		return REDIRECT;
	}
}

1;

__END__

=head1 NAME

Apache2::AuthenSecurID - Authentication via a SecurID server

=head1 SYNOPSIS

 # Configuration in httpd.conf or access.conf 

PerlModule Apache2::AuthenSecurID

<Location /secure/directory>
 AuthName SecurID
 AuthType Basic

 PerlAuthenHandler Apache2::AuthenSecurID

 PerlSetVar AuthCryptKey Encryption_Key 
 PerlSetVar AuthCookie Name_of_Authentication_Cookie 
 PerlSetVar AuthUserCookie Name_of_Username_Authentication_Cookie 
 PerlSetVar AuthCookiePath /path/of/authentication/cookie
 PerlSetVar AuthCookieTimeOut 30 
 PerlSetVar Auth_Handler /path/of/authentication/handler

 require valid-user
</Location>

=head1 DESCRIPTION

This module allows authentication against a SecurID server.  It
detects whether a user has a valid encrypted cookie containing their 
username and last activity time stamp.  If the cookie is valid the module 
will change the activity timestamp to the present time, encrypt and send the
cookie.  If the cookie is not valid the module will redirect to the
authentication handler to prompt for username and passcode.

=head1 LIST OF TOKENS


=item *
AuthCryptKey

The Blowfish key used to encrypt and decrypt the authentication cookie. 
It defaults to F<my secret> if this variable is not set.

=item *
AuthCookie

The name of the of cookie to be set for the authentication token.  
It defaults to F<SecurID> if this variable is not set.

=item *
AuthUserCookie

The name of the of cookie that contains the value of the persons username
in plain text.  This is checked against the contents of the encrypted cookie
to verify user.  The cookie is set of other applications can identify 
authorized users.  It defaults to F<SecurID_User> if this variable is not set.

=item *
AuthCookiePath

The path of the of cookie to be set for the authentication token.  
It defaults to F</> if this variable is not set.

=item *
AuthCookieTimeOut

The time in minute a cookie is valid for.  It is not recommended to set
below 5.  It defaults to F<30> if this variable is not set.

=item *
Auth_Handler

The path of authentication handler.  This is the URL which request with
invalid cookie are redirected to.  The handler will prompt for username
and passcode.  It does the actual authentication and sets the initial
cookie.  This mechanism is used instead of get_basic_auth_pw because
get_basic_auth_pw will do multiple authentication attempt on pages that 
contain frames.  The ACE server will deny simultaneous authentication 
attempts since it considers this a type of attack.  It defaults to 
F</ace_init> if this variable is not set.  Please see
Apache2::AuthenSecurID::Auth to properly configure this functionality.

=head1 CONFIGURATION

The module should be loaded upon startup of the Apache daemon.
Add the following line to your httpd.conf:

 PerlModule Apache2::AuthenSecurID

=head1 PREREQUISITES

For AuthenSecurID you need to enable the appropriate call-back hook 
when making mod_perl: 

  perl Makefile.PL PERL_AUTHEN=1

AuthenSecurID requires Crypt::Blowfish and Crypt::CBC.

=head1 SEE ALSO

L<Apache>, L<mod_perl>, L<Authen::ACE> L<Apache2::AuthenSecurID::Auth>

=head1 AUTHORS

=item *
mod_perl by Doug MacEachern <dougm@osf.org>

=item *
Authen::ACE by Dave Carrigan <Dave.Carrigan@iplenergy.com>

=item *
Apache::AuthenSecurID by David Berk <dberk@lump.org>

=item *
mod_perl2 port and other modifications by Al Tobey <tobert@gmail.com>

=head1 COPYRIGHT

The Apache2::AuthenSecurID module is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

