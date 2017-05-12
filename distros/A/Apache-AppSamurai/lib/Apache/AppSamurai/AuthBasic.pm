# Apache::AppSamurai::AuthBasic - AppSamurai authentication against webserver
# using basic authentication.                                  

# $Id: AuthBasic.pm,v 1.18 2008/04/30 21:40:05 pauldoom Exp $

##
# Copyright (c) 2008 Paul M. Hirsch (paul@voltagenoir.org).
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
##

package Apache::AppSamurai::AuthBasic;
use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = substr(q$Revision: 1.18 $, 10, -1);

use Carp;
use Apache::AppSamurai::AuthBase;

# Below is used to make client connection to backend server to test auth
# and collect any cookies we want to keep
use LWP::UserAgent;
use HTTP::Request;
use MIME::Base64;

@ISA = qw( Apache::AppSamurai::AuthBase );

sub Configure {
    my $self = shift;

    # Pull defaults from AuthBase and save.
    $self->SUPER::Configure();
    my $conft = $self->{conf};

    # Initial configuration.  Put defaults here before the @_ args are
    # pulled in.
    $self->{conf} = { %{$conft},
		      LoginUrl => 'https://127.0.0.1', # URL to authenticate
		                                       # aginst
		      KeepAuth => 0, # Keep Authorization: Basic XXX header 
		                     # and continue to send to the proxied
                                     # servers. BE CAREFUL!
		      PassBackCookies => 0, # Pass all Set-Cookies back to
                                            # client browser
		      AllowRedirect => 0, # Follow redirects (Keep off and get
		                          # the URL right!)
		      UserAgent => '', # The User-Agent: header to report
		      RequireRealm => '', # If set, this realm must match that
		                          # returned by the backend server
		      SuccessCode => 200, # Auth considered a failure unless
                                          # this code is returned after login
		      Timeout => 10, # Timeout for connecting to auth server
		      PassMin => 3,
		      PassChars => '\w\d !\@\#\$\%\^\&\*,\.\?\-_=\+', # NOTE:
                                          # No : since that perplexes Mr. 
                                          # Basic Auth
		      @_,
		  };
    return 1;
}

sub Initialize {
    my $self = shift;

    # Holding space for alterlist items
    $self->{alterlist} = {};

    # Create LWP client and empty request
    $self->{client} = new LWP::UserAgent(timeout => $self->{conf}{Timeout});
    ($self->{client}) || ($self->AddError("Initialization of LWP::UserAgent failed: $!") && return 0);
    $self->{request} = new HTTP::Request("GET", $self->{conf}{LoginUrl});
    ($self->{request}) || ($self->AddError("Initialization of HTTP::Request failed: $!") && return 0);

    # Turn off all redirects if configured
    ($self->{conf}{AllowRedirect} == 1) || ($self->{client}->requests_redirectable([]));

    # Set the User-Agent for the request (You may want to use
    # "HEADER:User-Agent" as the value in your Apache config.  AppSamurai.pm
    # will fill in the client's User-Agent: header value per-request, then.)
    ($self->{conf}{UserAgent} eq '') || ($self->{request}->header('User-Agent' => $self->{conf}{UserAgent}));

    $self->{init} = 1;
    return 1;
}


# Connect to the server to check that authentication is required, 
# then send a second request with authentication and check for
# good return code
sub Authenticator {
    my $self = shift;
    my $user = shift;
    my $pass = shift;
    my ($response, $error, @tmp, $check, $realm);

    # Initial connect and check return for 401
    # Note - This pre-check is to make sure the target is actually listening
    $response = $self->{client}->request($self->{request});
    if ($response->code() != 401) {
	# Well, that ain't right!
	$self->AddError('error', "Failure or bad return code while connecting to \"" . $self->{conf}{LoginUrl} . "\": Code \"" . $response->code() . "\", $!");
	return 0;
    } 

    # Check for Basic in the list of WWW-Authorization values and
    # optional realm
    @tmp = $response->header("WWW-Authenticate");
    $check = 0;
    foreach (@tmp) {
        if (/^basic( realm=\"([^\"]*?)\")?$/i) {
	    $realm = $2;
	    
	    if ($self->{conf}{RequireRealm} ne '') {
		# Note - Realm matched without case sensitivity.
		unless ($realm =~ /^\Q$self->{conf}{RequireRealm}\E$/i) {
		    $self->AddError('error', "URL \"" . $self->{conf}{LoginUrl} . "\" returned the wrong realm: \"" . $realm . "\" (Check BasicAuthRequireRealm setting)");
		    return 0;
		}
	    }
	    
	    $check = 1;
	    last;
	}
    }
    unless ($check) {
	$self->AddError('error', "URL \"" . $self->{conf}{LoginUrl} . "\" did not list \"Basic\" as an allowed authentication method");
	return 0;
    }
    
    # Set credentials in request
    $self->{request}->authorization_basic($user, $pass);

    # Connect with beans and check return
    $response = $self->{client}->request($self->{request});

    if ($response->code() == $self->{conf}{SuccessCode}) {
	# YAY!  Now collect and store cookies and headers as directed
	if (($self->{conf}{PassBackCookies}) && (@tmp = $response->header('set-cookie'))) {
	    foreach (@tmp) {
		# Trim whitespace
		s/^\s*(.*?)\s*$/$1/;
		# Add to cookie alterlist for instance (will be sent back to web browser)
		push(@{$self->{alterlist}->{cookie}}, "passback:$1");
	    }
	}

	if ($self->{conf}{KeepAuth}) {
	    push(@{$self->{alterlist}->{header}}, "add:Authorization:Basic " . encode_base64($user . ":" . $pass, ''));
	}

	return 1;
    }

    # Save errors
    if ($error = $response->status_line) {
	$self->AddError('warn', "URL \"" . $self->{conf}{LoginUrl} . "\", Authentication failure: \"$user\": $error");
    } else {
	$self->AddError('error', "URL \"" . $self->{conf}{LoginUrl} . "\", Fatal authentication failure: \"$user\": $!");
    }
    # DEFAULT DENY #
    return 0;
}

1; # End of Apache::AppSamurai::AuthBasic

__END__

=head1 NAME

Apache::AppSamurai::AuthBasic - Check credentials against backend web server
using HTTP basic auth

=head1 SYNOPSIS

The module is selected and configured inside the Apache configuration.

 # Example with an authname of "fred" for use as part of an Apache config.

 # Configure as an authentication method
 PerlSetVar fredAuthMethods "AuthBasic"

 # The URL to send basic authentication checks to
 PerlSetVar fredAuthBasicLoginUrl "https://someserver/somepath/"

 # Use the special "HEADER:<field>" to pass the named header field from
 # the client to the backend authenticator directly. (Optional)
 PerlSetVar fredAuthBasicUserAgent "header:User-Agent"
 
 # Abort the check unless the "realm" returned by the server matches
 # this string. (Optional)
 PerlSetVar fredAuthBasicRequireRealm "Fred World Login"

 # Continue to send the same Authorization: header to the backend server
 # after login.  (Only use this when the AuthBasic check is run against
 # the backend server you are protecting)
 PerlSetVar fredAuthBasicKeepAuth 1

 # Collect cookies from AuthBasic check and send back to the user's browser
 # on login  (This is the default behaviour)
 PerlSetVar fredAuthBasicPassBackCookies 1


=head1 DESCRIPTION

This L<Apache::AppSamurai|Apache::AppSamurai> authentication module checks a
username and password against a backend webserver, (referred to as the "auth
server" below), using HTTP basic authentication (as defined in
L<RFC 2617|http://www.faqs.org/rfcs/rfc2617.html>).  In general, the
auth server is the same as the server Apache::AppSamurai is protecting,
though it does not have to be.

B<It is not recommended that you use AuthBasic as the only authentication
method for an Apache::AppSamurai instance!>  There are various types of
failures that could result in an erroneous login success.  There are also
inherent weaknesses in the HTTP basic auth system.

=head1 USAGE

The basic L<Apache::AppSamurai::AuthBase|Apache::AppSamurai::AuthBase>
configuration options are supported.  Additional options are described
below.  The following must be preceeded by the auth name and the auth
module name, I<AuthBasic>.  For example, if you wish to set the
C<LoginUrl> value for the auth name "Jerry", you would use:

 PerlSetVar JerryAuthBasicLoginUrl "url"

The auth name and "AuthBasic" have been removed for clarity.
See L<Apache::AppSamurai|Apache::AppSamurai> for more general configuration
information, or the F<examples/conf/> directory in the Apache::AppSamurai
distribution for examples.

=head2 I<LoginUrl> C<URL>

(Default: None.  You must set this value.)
Set to the full URL, (protocol, FQDN, and path), to authenticate against.
This URL must return a C<401 Authorization Required> response and a
C<WWW-Authenticate> header with C<Basic> listed as a supported type.
HTTPS is highly recommended.

=head2 I<UserAgent> C<AGENT>

(Default: undef)
Sets the user agent that will be reported to the auth server.  This
is optional.  You may set either a static agent name, like
"Mozilla/10.0 (Donkey Team Approved)", or use the special C<header:HEADERNAME>
syntax, where C<HEADERNAME> is the name of a client request header to copy.

In most cases, you should be able to configure I<UserAgent> as
C<"header:User-Agent">, which will just pass the client's field right
through to the auth server.

=head2 I<RequireRealm> C<NAME>

(Default: undef)
Require the auth server to return a specific basic auth "realm".  (This
is the value set by "realm=" inside the C<WWW-Authorization> server header.
This is also what shows across the top of the popup basic authentication
login box if you go directly to the login URL.

=head2 I<KeepAuth> C<0|1>

(Default: 0)
If 1, saves the basic authentication header that is sent to the auth server
by AuthBasic and continue to send the same header to the proxied server
after login.  This is almost always used when protecting a single basic auth
backend webserver.

B<Cross Server Warning:>
When I<KeepAuth> is enabled, B<all> the backend servers or apps protected
by the specific auth name will receive the authorization header.  B<Do not
enable this feature unless you are certain all the servers and applications
being protected by this Apache::AppSapurai instance should be receiving users'
usernames and passwords!>

B<Session Storage Warning:>
By default Apache::AppSamurai uses AES (Rijndael) to encrypt session data before storing it to disk, greatly reducing the risk of keeping
the basic auth header,  If you use this feature, please leave the
L<Apache::AppSamurai::Session::Serialize::CryptBase64|Apache::AppSamurai::Session::Serialize::CryptBase64> module configured as the session serialization
module.

=head2 I<PassBackCookies> C<0|1>

(Default: 0)
If 1, collects set cookies from the auth server and, upon successful login,
set them in the client web browser.

Even when using basic auth, many apps set cookies for various reasons.
This feature is most useful then the auth server and the protected
backend webserver are the same.  It may also be useful in the case of
using a ticket issuer of some sort as the auth server.  

B<Cross Server Warning:>
This feature does not alter the domain or path of the cookie.  It also does
not filter the cookie domain or path, nor does it translate cookies in
subsequent requests. For new applications, examine the cookie being set
in the browser and ensure that it should be sent to the protected 
servers and applications for this Apache::AppSamurai instance.

B<Session Storage Warning:>
This feature temporarily stores the cookie in the session data store on the
Apache::AppSamurai proxy server.
By default Apache::AppSamurai uses AES (Rijndael) to encrypt session data before storing it to disk, greatly reducing the risk of keeping
the cookie.  If you use this feature, please leave the
L<Apache::AppSamurai::Session::Serialize::CryptBase64|Apache::AppSamurai::Session::Serialize::CryptBase64> module configured as the session serialization
module.

=head2 I<AllowRedirect> C<0|1>

(Default: 0)
If set to 1, allows the auth server to replay with a C<302 Redirect> code,
following the redirect to its eventual destination.

B<This feature should almost never be used!>  Instead, try to find the
eventual URL destination the auth server is expecting.  If you connect to
the auth server's port, (using C<openssl s_client -connect "SERVERNAME:PORT">
for SSL, or just C<telnet SERVERNAME PORT>), and request the page, it should
return a 401 code.

(The skill of being a human web browser is a useful one
to have for web work.
L<http://www.esqsoft.com/examples/troubleshooting-http-using-telnet.htm> gives
a very quick look at how to do it.  After that, check out
L<http://en.wikipedia.org/wiki/HTTP> or the HTTP RFCs for more info.)

=head2 I<SuccessCode> C<CODE>

(Default: 200)
This is the numerical HTTP response code the auth module should expect from
the auth server if the login was a success. 200 is usually correct.

B<Verifying this code is highly recommended!>  Some servers and apps return
a 200 on various failures. (In part, thanks to Internet Explorer's "helpful"
error handling feature that displays its usual generic "Uh, something
happened!" error message on code 500 and other errors that return a page
under a certain length.)

=head2 I<Timeout> C<SECONDS>

(Default: 10)
The number of seconds to wait for the auth server to respond.

=head2 I<PassChars> C<REGEX-CHARS>

(Default: C<< \w\d !\@\#\$\%\^\&\*,\.\?\-_=\+ >>)
This is actually a configuration item included in Apache::AppSamurai::AuthBase.
It is mentioned here because the AuthBasic version overrides the usual
default by removing the C<:> character.  (C<:> is used to split the username
and password inside the Base64 encoded authorization header.)

=head2 OTHERS

All other configuration items are inherited from
L<Apache::AppSamurai::AuthBase|Apache::AppSamurai::AuthBase>.  Consult
its documentation for more information.

=head1 METHODS

=head2 Configure()

Other than the AuthBasic specific configuration options, (described in
L</USAGE>), this is just a wrapper for the AuthBase C<Configure()>.

=head2 Initialize()

Performs the following additional actions:

=over 4

=item *

Creates C<< %{$self->{alterlist}} >> to hold header and cookie alterlist
rules.  (See L<Apache::AppSamurai|Apache::AppSamurai> for alterlist
information.)

=item *

Creates a L<LWP::UserAgent|LWP::UserAgent> instance and saves it in
C<< $self->{client} >>.

=item *

Creates a L<HTTP::Request|HTTP::Request> instance, containing the auth
server URL, and saves it in C<< $self->{request} >>.

=item *

If C<UserAgent> is set, collects (if C<header:> is used), then sets the
C<User-Agent> header in the request.

=back

=head2 Authenticator()

Performs the following actions, logging error(s) and returning 0 if any
actions fail:

=over 4

=item *

Makes an initial connection to the auth server URL and checks for a
C<401 Authorization Required> response code.

=item *

Checks that C<Basic> is listed as a supported type.

=item *

If C<RequireRealm> is configured, the realm returned by the auth server
is checked against the C<RequireRealm> value.

=item *

A second request is sent, this time with the username and password (credential)
included.

=item *

The return code is checked against C<SuccessCode>

=item *

If C<PassBackCookies> is 1, the cookies set by the auth server are saved
in the alterlist cookie hash with "passback" rules.

=item *

If C<KeepAuth> is 1, the authorization header (containing the username and
password) are saved in the alterlist header hash with an "add" rule.

=item *

If all checks have succeeded, 1 is returned.

=back

=head1 EXAMPLES

See L</SYNOPSIS> for a basic example, or configuration examples in
F<examples/conf/> inside the Apache::AppSamurai distribution.

=head1 SEE ALSO

L<Apache::AppSamurai>, L<Apache::AppSamurai::AuthBase>, L<LWP::UserAgent>,
L<HTTP::Request>

=head1 AUTHOR

Paul M. Hirsch, C<< <paul at voltagenoir.org> >>

=head1 BUGS

See L<Apache::AppSamurai> for information on bug submission and tracking.

=head1 SUPPORT

See L<Apache::AppSamurai> for support information.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Paul M. Hirsch, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
