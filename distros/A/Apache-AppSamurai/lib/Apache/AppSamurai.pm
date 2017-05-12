# Apache::AppSamurai - Protect your master, even if he is without honour.

# $Id: AppSamurai.pm,v 1.66 2008/05/03 06:43:25 pauldoom Exp $

##
# Copyright (c) 2008 Paul M. Hirsch (paul@voltagenoir.org).
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
##

# AppSamurai is a set of scripts and a module that tie into Apache via
# mod_perl to provide an authenticating reverse proxy front end for
# web applications.  It allows the use of outside authentication not
# supported by the backend app, and also adds session tracking.

package Apache::AppSamurai;
use strict;
use warnings;

# Keep VERSION (set manually) and REVISION (set by CVS)
use vars qw($VERSION $REVISION $MP);
$VERSION = '1.01';
$REVISION = substr(q$Revision: 1.66 $, 10, -1);

use Carp;

# mod_perl Includes
BEGIN {
    if (eval{require mod_perl2;}) {
	mod_perl2->import(qw(1.9922 StackedHandlers MethodHandlers Authen
			     Authz));
        require Apache2::Connection;
	require Apache2::RequestRec;
	require Apache2::RequestUtil;
	require Apache2::Log;
	require Apache2::Access;
	require Apache2::Response;
	require Apache2::Util;
	require Apache2::URI;
	require APR::Table;
	require APR::Pool;
	require Apache2::Const;
	Apache2::Const->import(qw(OK DECLINED REDIRECT HTTP_FORBIDDEN
				  HTTP_INTERNAL_SERVER_ERROR
				  HTTP_MOVED_TEMPORARILY HTTP_UNAUTHORIZED
				  M_GET));
	require Apache2::Request;
	$MP = 2;
    } else {
	require mod_perl;
	mod_perl->import(qw(1.07 StackedHandlers MethodHandlers Authen Authz));
	require Apache;
	require Apache::Log;
	require Apache::Util;
	require Apache::Constants;
	Apache::Constants->import(qw(OK DECLINED REDIRECT HTTP_FORBIDDEN
				     HTTP_INTERNAL_SERVER_ERROR
				     HTTP_MOVED_TEMPORARILY HTTP_UNAUTHORIZED
				     M_GET));
	require Apache::Request;
	$MP = 1;
    }
}

# Non-mod_perl includes
use CGI::Cookie;
use URI;
use Time::HiRes qw(usleep);

use Apache::AppSamurai::Util qw(CreateSessionAuthKey CheckSidFormat
				HashPass HashAny ComputeSessionId
				CheckUrlFormat CheckHostName
				CheckHostIP XHalf);

# Apache::AppSamurai::Session is a replacement for Apache::Session::Flex
# It provides normal Apache::Session::Flex features, plus optional extras
# like alternate session key generators/sizes and record level encryption
use Apache::AppSamurai::Session;

# Apache::AppSamurai::Tracker is a special instance of Session meant to
# be shared between all processes serving an auth_name
use Apache::AppSamurai::Tracker;

### START Apache::AuthSession based methods

# The following lower case methods are directly based on Apache::AuthCookie, or
# are required AuthCookie methods (like authen_cred() and authen_ses_key())

# Note - ($$) syntax, used in mod_perl 1 to induce calling the handler as
# an object, has been eliminated in mod_perl 2.  Each handler method called
# directly from Apache must be wrapped to support mod_perl 1 and mod_perl 2
# calls.  (Just explaining the mess before you have to read it.)

# Identify the username for the session and set for the request
sub recognize_user_mp1 ($$) { &recognize_user_real }
sub recognize_user_mp2 : method { &recognize_user_real }
*recognize_user = ($MP eq 1) ? \&recognize_user_mp1 : \&recognize_user_mp2;

sub recognize_user_real {
    my ($self, $r) = @_;
    my ($auth_type, $auth_name) = ($r->auth_type, $r->auth_name);
    
    return DECLINED unless $auth_type and $auth_name;    

    my $cookie_name = $self->cookie_name($r);
    
    my ($cookie) = $r->headers_in->{'Cookie'} =~ /$cookie_name=([^;]+)/;
    if (!$cookie && $r->dir_config("${auth_name}Keysource")) {
	# Try to get key text using alternate method then compute the key.
	# FetchKeysource returns '' if no custom source is configured, in
	# which case the cookie should have been previously set, so non-zero
	# output is required.
	$cookie = $self->FetchKeysource($r);
	if ($cookie) {
	    $cookie = CreateSessionAuthKey($cookie);
	}
    }    
    
    return DECLINED unless $cookie;
    
    $self->Log($r, ('debug', "recognize_user(): cookie $cookie_name is " . XHalf($cookie)));
    
    my ($user,@args) = $auth_type->authen_ses_key($r, $cookie);
    if ($user and scalar @args == 0) {
	$self->Log($r, ('debug', "recognize_user(): user is $user"));
	($MP eq 1) ? ($r->connection->user($user)) : ($r->user($user));
    } elsif (scalar @args > 0 and $auth_type->can('custom_errors')) {
	return $auth_type->custom_errors($r, $user, @args);
    } else {
	# Shrug
	$self->Log($r, ('warn', "recognize_user(): Unexpected result"));
	return DECLINED;
    }
    
    return OK;
}

# Get the cookie name for this protected area
sub cookie_name {
    my ($self, $r) = @_;

    my $auth_type = $r->auth_type;
    my $auth_name = $r->auth_name;
    my $cookie_name = $r->dir_config("${auth_name}CookieName") ||
	"${auth_type}_${auth_name}";
    return $cookie_name;
}

# Set request cache options (no-cache unless specifically told to cache)
sub handle_cache {
    my ($self, $r) = @_;
    
    my $auth_name = $r->auth_name;
    return unless $auth_name;

    unless ($r->dir_config("${auth_name}Cache")) {
	$r->no_cache(1);
	if (!$r->headers_out->{'Pragma'}) {
	    $r->err_headers_out->{'Pragma'} = 'no-cache';
	}
    }
}

# Backdate cookie to attempt to clear from web browser cookie store
sub remove_cookie {
    my ($self, $r) = @_;
    
    my $cookie_name = $self->cookie_name($r);
    my $str = $self->cookie_string( request => $r,
				    key     => $cookie_name,
				    value   => '',
				    expires => 'Mon, 21-May-1971 00:00:00 GMT' );
    
    $r->err_headers_out->add("Set-Cookie" => "$str");
    
    $self->Log($r, ('debug', "remove_cookie(): removed_cookie \"$cookie_name\""));
}

# Convert current POST request to GET
# Note - The use of this is questionable now that Apache::Request is being
# used.  May go away in the future.
sub _convert_to_get {
    my ($self, $r) = @_;
    return unless $r->method eq 'POST';

    $self->Log($r, ('debug', "Converting POST -> GET"));

    # Use Apache::Request for immediate access to all arguments.
    my $ar = ($MP eq 1) ? 
	Apache::Request->instance($r) :
	Apache2::Request->new($r);
    
    # Pull list if GET and POST args
    my @params = $ar->param;
    my ($name, @values, $value);
    my @pairs = ();

    foreach $name (@params) {
	# we don't want to copy login data, only extra data.
	$name =~ /^(destination|credential_\d+)$/ and next;
		
	# Pull list of values for this key
	@values = $ar->param($name);
		
	# Make sure there is at least one value, which can be empty
	(scalar(@values)) or ($values[0] = '');

	foreach $value (@values) {
	    if ($MP eq 1) {
		push(@pairs, Apache::Util::escape_uri($name) . '=' .
		     Apache::Util::escape_uri($value));
	    } else {
		# Assume mod_perl 2 behaviour
		push(@pairs, Apache2::Util::escape_path($name, $r->pool) . 
		     '=' . Apache2::Util::escape_path($value, $r->pool));
	    }
	}   
    }
    
    $r->args(join '&', @pairs) if scalar(@pairs) > 0;
    
    $r->method('GET');
    $r->method_number(M_GET);
    $r->headers_in->unset('Content-Length');
}


# Handle regular (form based) login
sub login_mp1 ($$) { &login_real }
sub login_mp2 : method { &login_real }
*login = ($MP eq 1) ? \&login_mp1 : \&login_mp2;
sub login_real {
    my ($self, $r) = @_;
    my ($auth_type, $auth_name) = ($r->auth_type, $r->auth_name);
    
    # Use the magic of Apache::Request to ditch POST handling code
    # and cut to the args.
    my $ar = ($MP eq 1) ?
	Apache::Request->instance($r) :
	Apache2::Request->new($r);

    my ($ses_key, $tc, $destination, $nonce, $sig, $serverkey);
    my @credentials = ();

    # Get the hard set destination, or setup to just reload
    if ($r->dir_config("${auth_name}LoginDestination")) {
	$destination = $r->dir_config("${auth_name}LoginDestination");
    } elsif ($ar->param("destination")) {
	$destination = $ar->param("destination");
    } else {
	# Someday something slick could hold the URL, then cut through
	# to it.  Someday.  Today we die.
        $self->Log($r, ('warn', "No key 'destination' found in form data"));
        $r->subprocess_env('AuthCookieReason', 'no_cookie');
        return $auth_type->login_form($r);
    }  

    # Check form nonce and signature
    if (defined($ar->param("nonce")) and defined($ar->param("sig"))) {
	unless (($nonce = CheckSidFormat($ar->param("nonce"))) and
		($sig = CheckSidFormat($ar->param("sig")))) {
	    
	    $self->Log($r, ('warn', "Missing/invalid form nonce or sig"));
	    $r->subprocess_env('AuthCookieReason', 'no_cookie');
	    $r->err_headers_out->{'Location'} = $self->URLErrorCode($destination, 'bad_credentials');
	    $r->status(REDIRECT);
	    return REDIRECT;
	}
	$serverkey = $self->GetServerKey($r) or die("FATAL: Could not fetch valid server key\n");

	# Now check!
	unless ($sig eq ComputeSessionId($nonce, $serverkey)) {
	    # Failed!
	    $self->Log($r, ('warn', "Bad signature on posted form (Possible scripted attack)"));
	    $r->subprocess_env('AuthCookieReason', 'no_cookie');
	    $r->err_headers_out->{'Location'} = $self->URLErrorCode($destination, 'bad_credentials');
	    $r->status(REDIRECT);
	    return REDIRECT;
	}
    } else {
	# Failed!
	$self->Log($r, ('warn', "Missing NONCE and/or SIG in posted form (Possible scripted attack)"));
	$r->subprocess_env('AuthCookieReason', 'no_cookie');
	$r->err_headers_out->{'Location'} = $self->URLErrorCode($destination, 'bad_credentials');
	$r->status(REDIRECT);
	return REDIRECT;
    }

    # Get the credentials from the data posted by the client
    while ($tc = $ar->param("credential_" . scalar(@credentials))) {
	push(@credentials, $tc);
	
	($tc) ? ($tc =~ s/^(.).*$/$1/s) : ($tc = ''); # Only pull first char
 	                                              # for logging
	$self->Log($r, ('debug', "login(); Received credential_" . (scalar(@credentials) - 1) . ": $tc (hint)"));
    }

    # Convert all args into a GET and clear the credential_X args
    $self->_convert_to_get($r) if $r->method eq 'POST';
    
    # Check against credential cache if UniqueCredentials is set
    if ($r->dir_config("${auth_name}AuthUnique")) {
	unless ($self->CheckTracker($r, 'AuthUnique', @credentials)) {
	    # Tried to send the same credentials twice (or tracker system
	    # failure. Delete the credentials to fall through
	    @credentials = ();
	    $self->Log($r, ('warn', "login(): AuthUnique check failed: Tracker failure, or same credentials have been sent before"));
	}
    }

    if (@credentials) {
	# Exchange the credentials for a session key.
	$ses_key = $self->authen_cred($r, @credentials);
	if ($ses_key) {
	    # Set session cookie with expiration included if SessionExpire
	    # is set. (Extended +8 hours so we see logout events and cleanup)
	    if ($r->dir_config("${auth_name}SessionExpire")) {
		$self->send_cookie($r, $ses_key, {expires => $r->dir_config("${auth_name}SessionExpire") + 28800});
	    } else {
		$self->send_cookie($r, $ses_key);
	    }
	    $self->handle_cache($r);
	    
	    # Log 1/2 of session key to debug
	    $self->Log($r, ('debug', "login(): session key (browser cookie value): " . XHalf($ses_key)));
	    
	    # Godspeed You Black Emperor!
	    $r->headers_out->{"Location"} = $destination;
	    return HTTP_MOVED_TEMPORARILY;
	}
    }

    # Add their IP to the failure tracker
    # Ignores return (refusing a login page to an attacker doesn't stop them
    # from blindly reposting... can add a fail here if an embedded form
    # verification key is added to the mix in the future)
    if ($r->dir_config("${auth_name}IPFailures")) {
        if ($MP eq 1) {
	    $self->CheckTracker($r, 'IPFailures', $r->dir_config("${auth_name}IPFailures"), $r->get_remote_host);
        } else {
            $self->CheckTracker($r, 'IPFailures', $r->dir_config("${auth_name}IPFailures"), $r->connection->get_remote_host);
        }
    }

    # Append special error message code and try to redirect to the entry
    # point. (Avoids having the LOGIN URL show up in the browser window)
    $r->err_headers_out->{'Location'} = $self->URLErrorCode($destination, 'bad_credentials');
    $r->status(REDIRECT);
    return REDIRECT;
    # Handle this ol' style - XXX remove?
    #$r->subprocess_env('AuthCookieReason', 'bad_credentials');
    #$r->uri($destination);
    #return $auth_type->login_form($r);
}

# Special version of login that handles Basic Auth login instead of form
# Can be called by authenticate() if there is no valid session but a
# Authorization: Basic header is detected.  Can also be called directly,
# just like login() for targeted triggering
sub loginBasic_mp1 ($$) { &loginBasic_real }
sub loginBasic_mp2 : method { &loginBasic_real }
*loginBasic = ($MP eq 1) ? \&loginBasic_mp1 : \&loginBasic_mp2;
sub loginBasic_real {
    my ($self, $r) = @_;
    my ($auth_type, $auth_name) = ($r->auth_type, $r->auth_name);
    
    my ($ses_key, $t, @at, $tc);
    my @credentials = ();

    return DECLINED unless $r->is_initial_req; # Authenticate first req only
    
    # Count input credentials to figure how to split input
    my @authmethods = $self->GetAuthMethods($r);
    (@authmethods) || (die("loginBasic(): Missing authentication methods\n"));    
    my $amc = scalar(@authmethods);

    # Extract basic auth info and fill out @credentials array
    my ($stat, $pass) = $r->get_basic_auth_pw;

    if ($r->user && $pass) {
	# Strip "domain\" portion of user if present.
	# (Thanks Windows Mobile ActiveSync for forcing domain\username syntax)
	$t = $r->user;
	$t =~ s/^.*\\+//;
	$r->user($t);
	push(@credentials, $t);

	# Use custom map pattern if set; else just a generic split on semicolon
	if (defined($r->dir_config("${auth_name}BasicAuthMap"))) {
	    push(@credentials, $self->ApplyAuthMap($r,$pass,$amc));
	} else {
	    # Boring old in-order split
	    foreach (split(';', $pass, $amc)) {
		push(@credentials, $_);
	    }
	}

	# Log partial first char of each credential
	if ($r->dir_config("${auth_name}Debug")) {
	    for (my $i = 0; $i < scalar(@credentials); $i++) {
		$credentials[$i] =~ /^(.)/;
		$self->Log($r, ('debug', "loginBasic(): Received credential_$i: $1 (hint)"));
	    }
	}

	# Check against credential cache if AuthUnique is set
	if ($r->dir_config("${auth_name}AuthUnique")) {
	    unless ($self->CheckTracker($r, 'AuthUnique', @credentials)) {
		# Tried to send the same credentials twice (or tracker system
		# failure. Delete the credentials to fall through
		@credentials = ();
		$self->Log($r, ('warn', "loginBasic(): AuthUnique check failed: Same credentials have been sent before"));
	    }
	}
 
	if (@credentials) {
	    # Exchange the credentials for a session key.
	    $ses_key = $self->authen_cred($r, @credentials);
	    if ($ses_key) {
		# Set session cookie with expiration included if SessionExpire
		# is set. (Extended +8 hours for logouts/cleanup)
		if ($r->dir_config("${auth_name}SessionExpire")) {
		    $self->send_cookie($r, $ses_key, {expires => $r->dir_config("${auth_name}SessionExpire") + 28800});
		} else {
		    $self->send_cookie($r, $ses_key);
		}
		$self->handle_cache($r);

		# Log 1/2 of session key to debug
		$self->Log($r, ('debug', "loginBasic(): session key (browser cookie value): " . XHalf($ses_key)));
		
		# Godspeed You Black Emperor!
		$t = $r->uri;
		($r->args) && ($t .= '?' . $r->args);
		$self->Log($r, ('debug', "loginBasic(): REDIRECTING TO: $t"));
		$r->err_headers_out->{'Location'} = $t;
		return REDIRECT;
	    }
	}
    }

    # Unset the username if set
    $r->user() and $r->user(undef);

    # Add their IP to the failure tracker and just return HTTP_FORBIDDEN
    # if they exceed the limit
    if ($r->dir_config("${auth_name}IPFailures")) {
        if ($MP eq 1) {
	    unless ($self->CheckTracker($r, 'IPFailures', $r->dir_config("${auth_name}IPFailures"), $r->get_remote_host)) {
	        $self->Log($r, ('warn', "loginBasic(): Returning HTTP_FORBIDDEN to IPFailires banned IP"));
	        return HTTP_FORBIDDEN;
            }
        } else {
            unless ($self->CheckTracker($r, 'IPFailures', $r->dir_config("${auth_name}IPFailures"), $r->connection->get_remote_host)) {
                $self->Log($r, ('warn', "loginBasic(): Returning HTTP_FORBIDDEN to IPFailires banned IP"));
                return HTTP_FORBIDDEN;
            }
	}
    }

    # Set the basic auth header and send back to the client
    $r->note_basic_auth_failure;
    return HTTP_UNAUTHORIZED;
}


# Logout, kill session, kill, kill, kill
sub logout_mp1 ($$) { &logout_real }
sub logout_mp2 : method { &logout_real }
*logout = ($MP eq 1) ? \&logout_mp1 : \&logout_mp2;
sub logout_real {
    my $self = shift;
    my $r = shift;
    my $auth_name = $r->auth_name;
    my $redirect = shift || "";
    my ($sid, %sess, $sessconfig, $username, $alterlist);
    
    # Get the Cookie header. If there is a session key for this realm, strip
    # off everything but the value of the cookie.
    my $cookie_name = $self->cookie_name($r);
    my ($key) = $r->headers_in->{'Cookie'} =~ /$cookie_name=([^;]+)/;
    
    # Try custom keysource if no cookie is present and Keysource is configured
    if (!$key && $auth_name && $r->dir_config("${auth_name}Keysource")) {
	# Pull in key text
	$key = $self->FetchKeysource($r);
	# Non-empty, so use to generate the real session auth key
	if ($key) {
	    $key = CreateSessionAuthKey($key);
	}
    }

    # If set, check key format, else check for custom keysource
    if ($key) {
	($key = CheckSidFormat($key)) || (($self->Log($r, 'error', 'logout(): Invalid Session Key Format')) && (return undef));
    }

    # Get session config from Apache
    ($sessconfig = $self->GetSessionConfig($r)) || (die("logout: Unable to get session configuration while checking authentication\n"));

    if ($key) {
	# Enter the authentication key into the session config (NEVER STORE IT 
	# IN THE ACTUAL SESSION DATA!)
	$sessconfig->{key} = $key;

        # Compute real session ID
	($sessconfig->{ServerKey}) ||
	    (($self->Log($r, ('error', 'logout(): ${auth_name}SessionServerPass or ${auth_name}SessionServerKey not set (required for HMAC sessions)'))) &&
	     (return undef));
	($sid = ComputeSessionId($key, $sessconfig->{ServerKey})) || (($self->Log($r, ('error', 'logout(): Error computing session ID'))) && (return undef));
    } else {
	$sid = '';
    }

    # Try to delete the session.  Note that session handling errors do not 
    # return but fall through to return OK or REDIRECT depending
    # on how we were called.
    if ($sid) {
	# Check the SID
  	if ($sid = CheckSidFormat($sid)) {
	    # Open the session (this should die on a non-existant session)!!!
	    eval { tie(%sess, 'Apache::AppSamurai::Session', $sid, $sessconfig); };
	    if ($@) {
		$self->Log($r, ('debug', "logout(): Unable to open session \"$sid\": $@"));
	    } else {
		$username = $sess{'username'};
		
                # Load alterlist
		$alterlist = $self->AlterlistLoad(\%sess);
		# Re-apply passback cookies to which were cleared and backdated
		# after session creation.  (This clears the passback cookies)
		if (defined($alterlist->{cookie})) {
		    $self->AlterlistPassBackCookie($alterlist, $r);
		}

		$self->DestroySession($r, \%sess);
        	untie(%sess);
		$self->Log($r, ('notice', "LOGOUT: username=\"$username\", session=\"$sid\", reason=logout"));
	    }
	} else {
	    $self->Log($r, ('error', 'logout(): Invalid Session ID Format'));
	}
    } else {
	# No cookie set
	$self->Log($r, ('error', 'logout(): Missing session ID'));
    }
    
    # Clear cookie and set no-cache for client
    $self->remove_cookie($r);
    $self->handle_cache($r);

    # Check for hard-coded redirect for logout, or failing that, our
    # landing page
    if ($r->dir_config("${auth_name}LogoutDestination")) {
	$redirect = $r->dir_config("${auth_name}LogoutDestination");
    } elsif ($r->dir_config("${auth_name}LoginDestination")) {
	$redirect = $r->dir_config("${auth_name}LoginDestination");
    } 

    if ($redirect ne '') { 
    	$r->err_headers_out->{'Location'} = $redirect;
    	$r->status(REDIRECT);
    	return REDIRECT;
    } else {
	# Strip path and reload - THIS ONLY WORKS IF / IS REDIRECTED TO THE
	# LANDING PAGE
	$r->err_headers_out->{'Location'} = '/';
	$r->status(REDIRECT);
    	return REDIRECT;
    }
 
    # Returning the login form without redirecting on logout is probably not
    # right for any circumstance.  (Leaving this here for reference.)
    # else {
    #    return $self->login_form($r);
    # }
}


# Check for unauthenticated session and force login if not authenticated
sub authenticate_mp1 ($$) { &authenticate_real }
sub authenticate_mp2 : method { &authenticate_real }
*authenticate = ($MP eq 1) ? \&authenticate_mp1 : \&authenticate_mp2;
sub authenticate_real {
    my ($self, $r) = @_;
    my $auth_user;
    my ($t, $foundcookie);
    
    unless ($r->is_initial_req) {
	if (defined $r->prev) {
	    # we are in a sub-request.  Just copy user from previous request.
	    ($MP eq 1) ? ($r->connection->user($r->prev->connection->user)) :
		($r->user($r->prev->user));
	}
	return OK;
    }
    
    # Type must either be our own, or Basic
    unless (($r->auth_type eq $self) || ($r->auth_type =~ /^basic$/i)) {
	# Location requires authentication but we don't handle this AuthType.
	$self->Log($r, ('debug', "authenticate(): AuthType mismatch: $self =/= ".$r->auth_type));
	return DECLINED;
    }

    # AuthType is $auth_type which we handle, Check the authentication realm
    my $auth_name = $r->auth_name;
    $self->Log($r, ('debug', "authenticate(): auth_name " . $auth_name));
    unless ($auth_name) {
	$r->log_reason("AuthName not set, AuthType=$self", $r->uri);
	return HTTP_INTERNAL_SERVER_ERROR;
    }
    
    # Get the Cookie header. If there is a session key for this realm, strip
    # off everything but the value of the cookie.
    my $cookie_name = $self->cookie_name($r);
    my ($ses_key_cookie) = ($r->headers_in->{"Cookie"} || "") =~ /$cookie_name=([^;]+)/;
    
    $foundcookie = 0;
    if ($ses_key_cookie) {
	# If cookie found and not "", set $foundcookie to note auth key source
	$foundcookie = 1;
    } elsif ($r->dir_config("${auth_name}Keysource")) {
	# Try custom keysource if no cookie is present and Keysource is configured
	# Pull in key text
	$ses_key_cookie = $self->FetchKeysource($r);

	if ($ses_key_cookie) {
	    # Non-empty, so use to generate the real session auth key
	    $ses_key_cookie = CreateSessionAuthKey($ses_key_cookie);
	} else {
	    $ses_key_cookie = "";
	}
    } else {
	$ses_key_cookie = "";
    }

    # Report half of session key
    $self->Log($r, ('debug', "authenticate(): Current ses_key_cookie: \"" . XHalf($ses_key_cookie) . "\""));
    
    if ($ses_key_cookie) {
	my ($auth_user, @args) = $self->authen_ses_key($r, $ses_key_cookie);
	
	if ($auth_user and scalar @args == 0) {
	    # We have a valid session key, so we return with an OK value.
	    # Tell the rest of Apache what the authentication method and
	    # user is.
	    if ($MP eq 1) {
		$r->connection->auth_type($self);
		$r->connection->user($auth_user);
	    } else {
		# Assume MP2 behaviour
		$r->ap_auth_type($self);
		$r->user($auth_user);
	    }
	    $self->Log($r, ('debug', "authenticate(): user authenticated as $auth_user"));
	    
	    return OK;

	} elsif (scalar @args > 0 and $self->can('custom_errors')) {
	    return $self->custom_errors($r, $auth_user, @args);
	} else {
	    # There was a session key set, but it's invalid.
	    if ($foundcookie) {
		# Remove cookie from the client now so it does not come back.
		$self->remove_cookie($r);
	    }
	    $self->handle_cache($r);
	    $r->subprocess_env('AppSamuraiReason', 'bad_cookie');

	    # Add to our the session tracker (so we can short cut if resent)
	    # Ignores return (we are already on the way out...)
	    if ($r->dir_config("${auth_name}SessionUnique")) {
		$self->CheckTracker($r, 'SessionUnique', $ses_key_cookie);
	    }
   	}
    } else {
	# They have no cookie or Keysource generated auth key
	$r->subprocess_env('AppSamuraiReason', 'no_cookie');
    }

    # If serving Basic, hand control over the the basic login handler    
    if ($r->auth_type =~ /^basic$/i) {
	# (Returns an OK if the login was good or return a 401 if not.)
	$self->Log($r, ('debug',  "authenticate(): Basic auth protected area: Attempting loginBasic()"));
	return $self->loginBasic($r);
    } else {
	# They aren't authenticated, and they tried to get a protected
	# document.  Send them the authen form.
	return $self->login_form($r);
    }
}

# Generate login form
sub login_form {  
    my ($self, $r) = @_;
    my $auth_name = $r->auth_name;
    
    # Pull POST args into the GET args and set type as GET
    $self->_convert_to_get($r) if $r->method eq 'POST';
    
    my $authen_script;
    unless ($authen_script = $r->dir_config($auth_name . "LoginScript")) {
	$self->Log($r, ('error', "login_form(): PerlSetVar '${auth_name}LoginScript' not set", $r->uri));
	return HTTP_INTERNAL_SERVER_ERROR;
    }
    $self->Log($r, ('debug', "login_form(): Displaying $authen_script"));
    $r->custom_response(HTTP_FORBIDDEN, $authen_script);
    
    return HTTP_FORBIDDEN;
}

# Check for sane "satisfy" setting
sub satisfy_is_valid {
    my ($self, $r, $satisfy) = @_;
    $satisfy = lc $satisfy;
    
    if ($satisfy eq 'any' or $satisfy eq 'all') {
	return 1;
    } else { 
	my $auth_name = $r->auth_name;
	$self->Log($r, ('error', "satisfy_is_valid(): PerlSetVar ${auth_name}Satisfy $satisfy invalid",$r->uri));
	return 0;
    }
}

# Get satisfy setting
sub get_satisfy {
    my ($self, $r) = @_;
    my $auth_name = $r->auth_name;
    return lc $r->dir_config("${auth_name}Satisfy") || 'all';
}


# Check for proper authorization for the area
sub authorize_mp1 ($$) { &authorize_real }
sub authorize_mp2 : method { &authorize_real }
*authorize = ($MP eq 1) ? \&authorize_mp1 : \&authorize_mp2;
sub authorize_real {
    my ($self, $r) = @_;

    $self->Log($r, ('debug', 'authorize(): URI '.$r->uri()));
    return OK unless $r->is_initial_req; #only the first internal request
    
    unless (($r->auth_type eq $self) || ($r->auth_type =~ /^basic$/i)) {
	$self->Log($r, ('debug', $self . "authorize(): Wrong auth type: " . $r->auth_type));
	return DECLINED;
    }
    
    my $reqs_arr = $r->requires or return DECLINED;
    
    my $user = ($MP eq 1) ? ($r->connection->user) : ($r->user);
    unless ($user) {
	# user is either undef or =0 which means the authentication failed
	$r->log_reason("No user authenticated", $r->uri);
	return HTTP_FORBIDDEN;
    }
    
    my $satisfy = $self->get_satisfy($r);
    return HTTP_INTERNAL_SERVER_ERROR unless $self->satisfy_is_valid($r,$satisfy);
    my $satisfy_all = $satisfy eq 'all';
    
    my ($forbidden);
    foreach my $req (@$reqs_arr) {
	my ($requirement, $args) = split /\s+/, $req->{requirement}, 2;
	$args = '' unless defined $args;
	$self->Log($r, ('debug', "authorize(): requirement := $requirement, $args"));
	
	if ( lc($requirement) eq 'valid-user' ) {
	    if ($satisfy_all) {
		next;
	    } else {
		return OK;
	    }
	}
	
	if($requirement eq 'user') {
	    if ($args =~ m/\b$user\b/) {
		next if $satisfy_all;
		return OK; # satisfy any
	    }
	    
	    $forbidden = 1;
	    next;
	}
	
	# Call a custom method
	my $ret_val = $self->$requirement($r, $args);
	$self->Log($r, ('debug', "authorize(): $self->$requirement returned $ret_val"));
	if ($ret_val == OK) {
	    next if $satisfy_all;
	    return OK; # satisfy any
	}
	
	# Nothing succeeded, deny access to this user.
	$forbidden = 1;
    }

    return $forbidden ? HTTP_FORBIDDEN : OK;
}

# Have a session cookie Mr. Browser
sub send_cookie {
    my ($self, $r, $ses_key, $cookie_args) = @_;
    
    $cookie_args = {} unless defined $cookie_args;
    
    my $cookie_name = $self->cookie_name($r);
    
    my $cookie = $self->cookie_string( request => $r,
				       key     => $cookie_name,
				       value   => $ses_key,
				       %$cookie_args );
    
    # add P3P header if user has configured it.
    my $auth_name = $r->auth_name;
    if (my $p3p = $r->dir_config("${auth_name}P3P")) {
	$r->err_headers_out->{'P3P'} = $p3p;
    }
    
    $r->err_headers_out->add("Set-Cookie" => $cookie);
}

# Convert cookie store to header ready string
sub cookie_string {
    my $self = shift;
    
    # if passed 3 args, we have old-style call.
    if (scalar(@_) == 3) {
	carp "cookie_string(): deprecated old style call to ".__PACKAGE__."::cookie_string()";
	my ($r, $key, $value) = @_;
	return $self->cookie_string(request=>$r, key=>$key, value=>$value);
    }
    # otherwise assume named parameters.
    my %p = @_;
    for (qw/request key/) {    
	die("cookie_string(): missing required parameter $_\n") unless defined $p{$_};
    }
    # its okay if value is undef here.
    
    my $r = $p{request};
    
    $p{value} = '' unless defined $p{value};
    
    my $string = sprintf '%s=%s', @p{'key','value'};
    
    my $auth_name = $r->auth_name;
    
    if (my $expires = $p{expires} || $r->dir_config("${auth_name}Expires")) {
	$expires = Apache::AppSamurai::Util::expires($expires);
	$string .= "; expires=$expires";
    }
    
    $string .= '; path=' . ( $self->get_cookie_path($r) || '/' );
    
    if (my $domain = $r->dir_config("${auth_name}Domain")) {
	$string .= "; domain=$domain";
    }
    
    if (!$r->dir_config("${auth_name}Secure") || ($r->dir_config("${auth_name}Secure") == 1)) {
	$string .= '; secure';
    }
    
    # HttpOnly is an MS extension.  See
    # http://msdn.microsoft.com/workshop/author/dhtml/httponly_cookies.asp
    if ($r->dir_config("${auth_name}HttpOnly")) {
	$string .= '; HttpOnly';
    }
    
    return $string;
}

# Retrieve session cookie value 
sub key {
    my ($self, $r) = @_;

    my $auth_name = $r->auth_name;
    my $key = "";

    my $allcook = ($r->headers_in->{"Cookie"} || "");
    my $cookie_name = $self->cookie_name($r);
    ($key) = $allcook =~ /(?:^|\s)$cookie_name=([^;]*)/;

    # Try custom keysource if no cookie is present and Keysource is configured
    if (!$key && $auth_name && $r->dir_config("${auth_name}Keysource")) {
	# Pull in key text
	$key = $self->FetchKeysource($r);
	# Non-empty, so use to generate the real session auth key
	if ($key) {
	    $key = CreateSessionAuthKey($key);
	}
    }

    return $key;
}

# Retrieve session cookie path
sub get_cookie_path {
    my ($self, $r) = @_;
    
    my $auth_name = $r->auth_name;
    
    return $r->dir_config("${auth_name}Path");
}

# Check authentication credentials and return a new session key
sub authen_cred {
    my $self = shift;
    my $r = shift;
    my $username = shift;
    my @creds = @_;
    my $alterlist = {};

    # Check for matching credentials and configured authentication methods
    unless (@creds) {
	$self->Log($r, ('error', "LOGIN FAILURE: Missing credentials"));
	return undef;
    }

    my @authmethods = $self->GetAuthMethods($r);
    unless (@authmethods) {
        $self->Log($r, ('error', "LOGIN FAILURE: No authentication methods defined"));
	return undef;
    }
    unless (scalar(@creds) == scalar(@authmethods)) {
        $self->Log($r, ('error', "LOGIN FAILURE: Wrong number of credentials supplied"));
        return undef;
    }
    
    my $authenticated = 0;
    
    my ($ret, $errors);
    
    # Require and get new instance of each authentication module
    my $authenticators = $self->InitAuthenticators($r, @authmethods);
    
    $self->Log($r, ('debug', "authen_cred(): About to cycle authenticators"));
    for (my $i = 0; $i < scalar(@authmethods); $i++) {
	$self->Log($r, ('debug', "authen_cred(): Checking $authmethods[$i]"));
	
        # Perform auth check
	$ret = $authenticators->{$authmethods[$i]}->Authenticate($username, $_[$i]);
	# Log any errors, warnings, etc.
	($errors = $authenticators->{$authmethods[$i]}->Errors) && ($self->Log($r, $errors));
	$self->Log($r, ('debug', "authen_cred(): Done checking $authmethods[$i]"));
	
	if ($ret) {
	    # Success!
	    $authenticated++;

	    # Modify header (add/delete/filter) and cookie
	    # (add/delete/filter/pass) rules
	    $self->AlterlistMod($alterlist, $authenticators->{$authmethods[$i]}->{alterlist});
	    $self->Log($r, ('debug', "authen_cred(): Added alterlist groups for" . join(",", keys %{$alterlist})));

	} else {
	    # Failure! Stop checking auth.
	    last;
	}
    }

    $self->Log($r, ('debug', "authen_cred(): Done cycling authenticators"));

    # If the number of successful authentications equals the number of
    # authentication methods, you may pass.
    if (($authenticated == scalar(@authmethods)) && ($ret = $self->CreateSession($r, $username, $alterlist))) {
	return $ret;
    } else {
	# Log username (Log handles cleanup of the username and all log lines)
	if ($username) {
	    $self->Log($r, ('error', "LOGIN FAILURE: Authentication failed for \"$username\""));
	} else {
	    $self->Log($r, ('error', "LOGIN FAILURE: Authentication failed for missing or malformed username"));
	}

	# Lame excuse for brute force protection! Sleep from 0.0 to 1.0 secs
	# on failure to ensure someone can DoS us. :)  IPFailures tracker needs
	# work to have a pre-check, or to have a call out to a script to
	# do something (like add the IP to a firewall block table)
	usleep(rand(1000000));
    }

    return undef;
}

# Check session key and return user ID
sub authen_ses_key {
    my ($self, $r, $key) = @_;
    my ($sid, %sess, $username, $sessconfig, $tk, $tv, $reason);
    my $alterlist = {};

    # Is it well formed?
    ($key = CheckSidFormat($key)) || (($self->Log($r,('error', 'Invalid Session Key Format'))) && (return undef));

    # Get session config from Apache
    ($sessconfig = $self->GetSessionConfig($r)) || (die("authen_ses_key(): Unable to get session configuration while checking authentication\n"));

    # Enter the authentication key into the session config
    # (NOTE: MUST NOT BE STORED INSIDE SESSION)
    $sessconfig->{key} = $key;

    # Compute real session ID
    ($sessconfig->{ServerKey}) || (($self->Log($r, ('error', 'authen_ses_key(): ServerPass or ServerKey not set (required for HMAC sessions)'))) && (return undef));
    
    ($sid = ComputeSessionId($sessconfig->{key}, $sessconfig->{ServerKey})) || (($self->Log($r, ('error', 'authen_ses_key(): Error computing session ID'))) && (return undef));
    
    # Open the session (Eval will die on a non-existent session)
    eval { tie(%sess, 'Apache::AppSamurai::Session', $sid, $sessconfig); };
    if ($@) {
	$self->Log($r, ('debug', "authen_ses_key(): Unable to open session \"$sid\": $@"));
	return undef;
    }

    # Dump session contents to log (with some attempted cleanup for security)
    if ($self->_debug($r)) {
	my @tsl = ();
	push(@tsl, "authen_ses_key(): Dump of session \"$sid\": ");
	foreach $tk (sort keys %sess) {
	    $tv = $sess{$tk};
	    if ($tk eq 'al-header') {
		# Sanitize headers (Leaving 8 chars of context for each)
		$tv =~ s/^(\w+:authorization:.{1,8})(.*)$/$1 . "X" x length($2)/gmie;
	    } elsif ($tk eq 'al-cookie') {
                # Sanitize cookies (Leaving 8 characters of context)
		$tv =~ s/^(\w+:[^\:\=]+:.{1,8})([^;]*)(;.*)$/$1 . ("X" x length($2)) . $3/gmie;
	    } elsif ($tk =~ /auth/i) {
		# Probably something we want hidden
		$tv =~ s/^(.{1,8})(.*)$/$1 . "X" x length($2)/gmie;
	    }
	    push(@tsl, "$tk=>\"$tv\"");
	}
	$self->Log($r, ('debug', join(",", @tsl)));
    }

    # Pull header and cookie mod lists
    $alterlist = $self->AlterlistLoad(\%sess);

    # No reason... yet
    $reason = '';

    # Give me a reason... anything... any little excuse to kill your session...
    $username = $sess{'username'};
    if (!$username) {
	# Session must have a username
	$reason = 'no_username';
	# Extra-bad!
	$self->Log($r, ('error', "authen_ses_key(): No username for session \"$sid\""));
    } elsif (!$self->CheckTime(\%sess)) {
        # Expiration check failed
	$reason = 'timeout';
    } elsif (($sess{"Authorization"}) && ($r->headers_in->{"Authorization"}) && ($r->headers_in->{"Authorization"} ne $sess{"Authorization"})) {
	# Client sent a Authorization header that does not match the one sent
	# when logging in.  This indicates one of two potential issues:
	# 1) For areas configured to use basic auth, the auth has changed on
	#    the browser side, so kill the session.
	# 2) For areas we front with a form, this indicates that the backend
	#    server sent a 401 to the client.  We need to kill the session to
	#    get things in line again.
	$reason = "basic_auth_change";
    }

    if ($reason) {
	# Oh no!  They gave us a reason... It's ON!  (well, off)
	
	# Remove passback and session cookies first
	if (defined($alterlist->{cookie})) {
	    $self->AlterlistPassBackCookie($alterlist, $r);
	}
	
	$self->remove_cookie($r);
	$self->handle_cache($r);
	
	# Wake up.  Time to die.
        $self->DestroySession($r, \%sess);
	untie(%sess);
	$self->Log($r, ('notice', "LOGOUT: username=\"$username\", session=\"$sid\", reason=$reason"));
	
	# If serving basic auth, return undef instead of triggering login form
	if ($r->auth_type =~ /^basic$/i) {
	    return undef;
	} else {
	    # Use Apache::AuthCookie based custom_errors feature, which will
	    # call back into our custom_errors() method. (expired_cookie
	    # applies as an acceptable error for all of these cases.)
	    return('login', 'expired_cookie');
	}
    }

    # Apply header and cookie alterations to request headed for backend server
    $self->AlterlistApply($alterlist, $r);
    $self->Log($r, ('debug', "authen_ses_key(): Loaded and applied alterlist groups " . join(",", keys %{$alterlist})));

    # Release session file
    untie(%sess);
    
    return $username;
}


# custom_errors are a nice way to get flexible actions based on certain events
# without having to rewrite authentication() and other methods. Takes
# the request, a "code", and a message.  The original intent of this was to
# allow for custom server return messages, but I muck it up to do things like
# redirecting on certain errors, too.
sub custom_errors {
    my ($self, $r, $code, $message) = @_;
    my $t;

    # Handle request based on the format of the $code argument
    if ($code =~ /^login$/) {
	# Append the passed error code using ASERRCODE and bring up the login
	# form.  (Adds error code query to the current URI, which the login
	# form will pull back in)
	$t = $r->uri;
	($r->args) && ($t .= "?" . $r->args);
	$r->uri($self->URLErrorCode($t, 'message'));
	return $self->login_form($r);
    } elsif ($code =~ /^([A-Z0-9_]+)$/) {
	# Codes in all caps with an underscore are assumed to be Apache
        # response codes
	($message) && ($r->custom_response($code, $message));
	return $code;
    } else {
	# What was that?  Die out.
	die "custom_errors(): Invalid code passed to custom_errors: \"$code\"";
    }
}
		       
## END Apache::AuthCookie based methods

# Everything past this point is not an overridden/modified Apache::AuthCookie
# function.

# Taking a request, try to get the <AuthName>AuthMethods list for the resource
sub GetAuthMethods {
    my ($self, $r) = @_;
    my ($authname, $authmethlist);
    my @authmethods = ();

    # Get the auth name
    ($authname = $r->auth_name()) || (die("GetAuthMethods(): No auth name set for this request!\n"));
    ($authmethlist = $r->dir_config($authname . "AuthMethods")) || (die("GetAuthMethods(): No authentication methods found for $authname!\n"));

    # <AuthName>AuthMethods should be a comma deliminated list of methods.  Let
    # us see, shall we?
    foreach (split(',', $authmethlist)) {
	(/^\s*(Auth[\w\d]+)\s*$/) || (die("GetAuthMethods(): Invalid ${authname}AuthMethods definition!\n"));
	push(@authmethods, $1);
    }

    return @authmethods;
}

# This just loads the appropriate Apache::AppSamurai::AuthXXX modules
# so they are ready to authenticate against.  Note that this function
# needs only be called by authen_cred() most of the time.  Returns a ref
# to a hash with AuthName->AuthNameInstance mappings
sub InitAuthenticators {
    my $self = shift;
    my $r = shift;
    my @authmethods = @_;
    my ($am, $amn, $lkn, $skn, $ch, $authname, $dirconfig);
    
    (scalar(@authmethods)) || (die("InitAuthenticators(): You must specify at least one authentication method!\n"));

    # Clear authenticator handle hash
    my $authenticators = {};

    # Get directory authentication name and a hash of its config
    ($authname = $r->auth_name()) || (die("InitAuthenticators(): No auth name set for this request!\n"));
    $dirconfig = $r->dir_config();

    # Init each auth method
    foreach $am (@authmethods) {
	($am =~ /^Auth[A-Z0-9][a-zA-Z0-9:]+$/) || (die("InitAuthenticators(): Illegal authentication method name!  (Check case)\n"));
	
	# Extract any config variables set for the configure auth methods
	# and store in a temp hash before creating auth module instance
	$ch = {};
	$lkn = '';
	$skn = '';
	foreach $lkn (keys %{$dirconfig}) {
	    ($lkn =~ /^${authname}${am}([\w\d]+)\s*$/) || (next);
	    $skn = $1;
	    $ch->{$skn} = $dirconfig->{$lkn};

	    # If a "header:<field>" is requested, replace with the named
	    # header's value from the client request, or an empty string
	    if ($ch->{$skn} =~ /^header:([\w\d\-]+)$/i) {
		$ch->{$skn} = $r->headers_in->{$1};
	    }
	}

	if ($am =~ /^(AuthSimple)(.+)$/) {
	    # Framework auth modules (like AuthSimple) - These need
	    # a master AppSamurai::Auth*** module that expects the name
	    # of a submodule and its arguments
	    # Set submodule name, assuming it is under the master's tree
	    $ch->{SubModule} = $2;
	    # Use the master auth module from AppSamurai itself
	    $amn = 'Apache::AppSamurai::' . $1;
	} else {
	    $amn = 'Apache::AppSamurai::' . $am;
	}
	
	(eval "require $amn;") ||
	    (die("InitAuthenticators(): Could not load $amn\n"));
	
	{
	    # Disable strict within block so we can call <module>::new
	    no strict 'refs';
	    ($authenticators->{$am} = $amn->new(%{$ch})) ||
		(die("InitAuthenticators(): Could not create new $amn instance: " . $! . "\n"));
	}
	
	# A little sanity check on the returned authenticator
	$authenticators->{$am}->can("Authenticate") or die("InitAuthenticators(): Newly created $amn instance (for $am) does not have Authenticate() method");
    }
    
    return $authenticators;
}
	    
# Retrieve session configuration from Apache config and return as a hash ref
sub GetSessionConfig {
    my ($self, $r) = @_;
    my $auth_name = ($r->auth_name()) || (die("GetSessionConfig(): No auth name defined!\n"));
    my $dirconfig = $r->dir_config;
    # Set some defaults that shouldn't be too horrible
    my $sessconfig = {};
		
    # Pull in session configuration
    foreach (keys %{$dirconfig}) {
	(/^${auth_name}Session([\w\d]+)\s*$/) || (next);
	$sessconfig->{$1} = $dirconfig->{$_};
    }
    
    unless (scalar(keys %{$sessconfig})) {
	$self->Log($r, ('error', "GetSessionConfig(): No Session configuration found for $auth_name!"));
	return undef;
    }

    ## TODO    - This section of session autoconfig/defaults is pretty
    ##           inflexilbe and too tightly tied to HMAC_SHA and CryptBase64.
    ##           It should be abolished or moved out and into a generalized
    ##           pre-config module that can be called ONCE (at startup)

    # Use files for storage and locking by default
    (exists($sessconfig->{Store})) || ($sessconfig->{Store} = "File");
    (exists($sessconfig->{Lock})) || ($sessconfig->{Lock} = "File");

    # If files are being used, paths must be set
    if ($sessconfig->{Store} eq 'File' && !exists($sessconfig->{Directory})) {
	$self->Log($r, ('error', "GetSessionConfig(): ${auth_name}SessionDirectoy must be defined for the File session store"));
	return undef;
    }
    if ($sessconfig->{Lock} eq 'File' && !exists($sessconfig->{LockDirectory})) {
	$self->Log($r, ('error', "GetSessionConfig(): ${auth_name}SessionLockDirectoy must be defined for the File session lock"));
	return undef;
    }

    # Use HMAC_SHA and CryptBase64 for session creation and serialization
    # by default.
    (exists($sessconfig->{Generate})) || ($sessconfig->{Generate} = "AppSamurai/HMAC_SHA");
    (exists($sessconfig->{Serialize})) || ($sessconfig->{Serialize} = "AppSamurai/CryptBase64");
   
    # Check/clean ServerPass if present (else assume ServerKey set)
    if (exists($sessconfig->{ServerPass})) {
	# Set the key (note - GetServerKey logs the error, if any)
	($sessconfig->{ServerKey} = $self->GetServerKey($r)) || (return undef);
    }

    # We have to have a ServerKey at this point, in hex form.
    if (($sessconfig->{Generate} =~ /HMAC/i) || ($sessconfig->{Serialize} =~ /Crypt/i)) {
	unless (CheckSidFormat($sessconfig->{ServerKey})) {
	    # Bad server key format
	    $self->Log($r, ('error', "GetSessionConfig(): You must a valid ${auth_name}ServerPass or ${auth_name}ServerKey!"));
	    return undef;
	}
	
	# For speed, SerializeCipher should be set in the config
	if (!$sessconfig->{SerializeCipher}) {
	    # Attempt to load CryptBase64 module
	    unless (eval "require Apache::AppSamurai::Session::Serialize::CryptBase64") {
		$self->Log($r, ('error', "GetSessionConfig(): Could not load CryptBase64 while attempting to auto-select ${auth_name}SerializeCipher value: $!"));
		return undef;
	    }
	    # Use CryptBase64 cipher detection utility (Slower)
	    unless ($sessconfig->{SerializeCipher} = &Apache::AppSamurai::Session::Serialize::CryptBase64::find_cipher()) {
		# None found.  (Note - Check @allowedciphers in CryptBase64.pm
		# for supported ciphers)
		$self->Log($r, ('error', "GetSessionConfig(): Could not auto-detect a suitable ${auth_name}SerializeCipher value (Please configure manualy): $!"));
		return undef;
	    }
	}
    }
    
    # Set a 1hr Timeout if neither Timeout or Expire are set
    unless ($sessconfig->{Timeout} || $sessconfig->{Expire}) {
	$sessconfig->{Timeout} = 3600;
    }
    
    return $sessconfig;
}


# Compute/check server key from server pass, returning key.
sub GetServerKey {
    my ($self, $r) = @_;
    my $auth_name = ($r->auth_name()) || (die("GetServerKey(): No auth name defined!\n"));
    my $dirconfig = $r->dir_config;
    my $serverkey = '';
    
    if (exists($dirconfig->{$auth_name . "SessionServerPass"})) {
	my $serverpass = $dirconfig->{$auth_name . "SessionServerPass"};
	
	unless ($serverpass =~ s/^\s*([[:print:]]{8,}?)\s*$/$1/s) {
	    $self->Log($r, ('error', "GetServerKey(): Invalid ${auth_name}SessionServerPass (must be use at least 8 printable characters"));
	    return undef;
	}
	
	if ($serverpass =~ /^(password|serverkey|serverpass|12345678)$/i) {
	    $self->Log($r, ('error', "GetServerKey(): ${auth_name}SessionServerPass is $1...  That is too lousy"));
	    return undef;
	}
	
	unless ($serverkey = HashPass($serverpass)) {
	    $self->Log($r, ('error', "GetServerKey(): Problem computing server key hash for ${auth_name}SessionServerPass"));
	    return undef;
	}

    } elsif (exists($dirconfig->{$auth_name . "SessionServerKey"})) {
	$serverkey = $dirconfig->{$auth_name . "SessionServerKey"};

    } else {
	$self->Log($r, ('error', "GetServerKey(): You must define either ${auth_name}SessionServerPass or ${auth_name}SessionServerKey in your Apache configuration"));
	return undef;
    }
    
    # Check for valid key format
    unless (CheckSidFormat($serverkey)) {
	# Not good, dude.  This should not happen
	$self->Log($r, ('error', "GetServerKey(): Invalid server session key (CheckSidFormat() failure) for $auth_name"));
	return undef;
    }

    return $serverkey;
}


# Apply the configured BasicAuthMap to the passed in credentials
# BasicAuthMap allows for flexibly parsing a single line of authentication
# data into multiple credentials in any order.  (Keep those users happy...)
# Returns an array with the parsed credentials in order, or an empty set on
# failure.
sub ApplyAuthMap {
    my ($self, $r, $pass, $amc) = @_;
    my $auth_name = ($r->auth_name) || ('');
    my ($o, $m, $i, @ct);
    my @creds = ();

    # Check basic map format
    ($r->dir_config("${auth_name}BasicAuthMap") =~ /^\s*([\d\,]+)\s*\=\s*(.+?)\s*$/) || (die("ApplyAuthMap(): Bad format in ${auth_name}BasicAuthMap\n"));
    $o = $1;
    $m = $2;
    
    # Try to map values from pass string
    (@ct) = $pass =~ /^$m$/;
    unless (scalar(@ct) eq $amc) {
	$self->Log($r, ('warn', "ApplyAuthMap: Unable to match credentials with ${auth_name}BasicAuthMap"));
	return ();
    }
    
    # Check credential numbers for sanity and assign values
    foreach $i (split(',', $o)) {
	($i =~ s/^\s*(\d+)\s*$/$1/) || (die("ApplyAuthMap(): Bad mapping format in ${auth_name}BasicAuthMap\n"));
	push(@creds, $ct[$i - 1]);
    }
	    
    return @creds;
}


# Gather header and argument items from request to build custom session
# authentication key.  Not nearly as secure as random generation, but
# for cookie losing clients (generally automated), it is the only choice.
#
# Synatax:
#
#    TYPE:NAME
#
# TYPE - Type of item (header or arg) to pull in
# NAME - Name of header or argument to pull in
#
# The name match is case insensitive, but strict:  Only the exact names
# will be used to ensure a consistent key text source.  MAKE SURE TO USE
# PER-CLIENT UNIQUE VALUES!  The less random the key text source is, the
# easier it can be guessed/hacked. (Once again: Do not use the custom
# key text source feature if you can avoid it!)
sub FetchKeysource {
    my ($self, $r) = @_;
    my $auth_name = ($r->auth_name()) || (die("FetchKeysource(): No auth name defined!\n"));
    my @srcs = $r->dir_config->get("${auth_name}Keysource");
 
    # Return empty, which session key creators MUST interpret as a request
    # for a fully randomized key
    return '' unless (scalar @srcs);

    # Use Apache::Request for immediate access to all arguments.
    my $ar = ($MP eq 1) ? Apache::Request->instance($r) : Apache2::Request->new($r);

    my ($s, $t);
    my $keytext = '';
    
    # Pull values in with very moderate checking
    foreach $s (@srcs) {
	if ($s =~ /^\s*header:([\w\d\-\_]+)\s*$/i) {
	    if ($r->headers_in->{$1} and
		($t) = $r->headers_in->{$1} =~ /^\s*([\x20-\x7e]+?)\s*$/s) {
		$keytext .= $t;
		$self->Log($r, ('debug', "FetchKeysource(): Collected $s: " . XHalf($t)));
	    } else {
		$self->Log($r, ('warn', "FetchKeysource(): Missing header field: \"$1\": Can not calculate session key"));
		return undef;
	    }
	} elsif ($s =~ /^\s*arg:([\w\d\.\-\_]+)\s*$/i) {
	    if (($t = $ar->param($1)) && ($t =~ s/^\s*([^\r\n]+?)\s*$/$1/)) {
		$keytext .= $t;
		$self->Log($r, ('debug', "FetchKeysource(): Collected $s: " . XHalf($t)));
	    } else {
		$self->Log($r, ('warn', "FetchKeysource(): Missing argument: \"$1\": Can not calculate session key"));
		return undef;
	    }
	} else {
	    $self->Log($r, ('error', "FetchKeysource(): Invalid Keysource definition for $auth_name"));
	    return undef;
	}
    }
    
    return $keytext;
}

# Initiate a new session and return a session key.  Takes the $r request (for
# record keeping), the username, and an optional "alter list" to be used
# to change cookies and/or headers sent from the proxy to the backend server.
sub CreateSession {
    my ($self, $r, $username, $alterlist) = @_;
    (defined($alterlist)) || ($alterlist = {});    
    my (%sess, $sid, $sessconfig, $kt);
    
    # Extract the session config
    ($sessconfig = $self->GetSessionConfig($r)) || (die "CreateSession(): Unable to get session configuration while creating new session");
    
    # Create a session auth key to send back to send back as the cookie
    # value, and to use the HMAC-SHA and optional session file encryptor.
    # FetchKeysource returns "" by default, resulting in a fully randomized
    # key.
    $kt = $self->FetchKeysource($r);
    if (defined($kt)) {
	$sessconfig->{key} = CreateSessionAuthKey($kt);
    } else {
	$self->Log($r, ('warn', "CreateSession(): Failed to generate session authentication key: Session creation denied"));
	return undef;
    }
    
    # Check for valid looking key
    unless (CheckSidFormat($sessconfig->{key})) {
	$self->Log($r, ('warn', "CreateSession(): Bad session authentication key returned!  Session creation denied"));
	return undef;
    }

    # Run against the unique session tracker if configured.  (*Don't make
    # the same session twice)
    if ($sessconfig->{Unique}) {
	unless ($self->CheckTracker($r, 'SessionUnique', $sessconfig->{key})) {
	    $self->Log($r, ('warn', "CreateSession(): SessionUnique detected duplicate session authentication key!  Session creation denied"));
	    return undef;
	}
    }

    # Wrapped this in an eval, since Apache:Session dies on failures
    eval { tie(%sess, 'Apache::AppSamurai::Session', undef, $sessconfig); };
    if ($@) {
	$self->Log($r, ('error', "CreateSession(): Unable to create new session: $@"));
	return undef;
    }
    $sid = $sess{_session_id};

    # Make sure we received a good session ID.
    (CheckSidFormat($sid)) || (($self->Log($r, ('error', 'CreateSession(): Invalid Session ID Format on new Session'))) && (return undef));
    $self->Log($r, ('notice', "LOGIN: username=\"$username\", session=\"$sid\""));
    
    # Store some basics
    $sess{'username'} = $username;
    $sess{'ctime'} = time();
    
    # Track last access time if Timeout is set
    if ($sessconfig->{Timeout}) {
	$sess{'atime'} = $sess{'ctime'};
	$sess{'Timeout'} = $sessconfig->{Timeout};
    }

    # Set hard expiration time if Expire is set
    if ($sessconfig->{Expire}) {
	$sess{'etime'} = $sess{'ctime'} + $sessconfig->{Expire};
	$sess{'Expire'} = $sessconfig->{Expire};
    }

    # Apply passback cookies to response, and pull in updated alterlist
    if (defined($alterlist->{cookie})) {
	$alterlist = $self->AlterlistPassBackCookie($alterlist, $r);
    }

    # If present, save Authorization header to detect future changes,
    # then prepend an alterlist rule to delete the header to prevent
    # pass though to the backend server.  (If needed, a separate
    # alterlist rule to add an Authorization header should be set
    # by a auth module.)
    if ($r->headers_in->{"Authorization"}) {
	$sess{'Authorization'} = $r->headers_in->{"Authorization"};
	# Stick it in front in case we have an existing add
	# header from an auth module
	unshift(@{$alterlist->{header}}, 'delete:Authorization:');
    }

    # Save current alterlist to session
    $self->AlterlistSave($alterlist, \%sess);
    
    # Release session
    untie(%sess);
    
    # Return the session auth key
    return $sessconfig->{key};
}

# Destroy a session, rendering it forever useless.  Takes a request hash ref
# and a session hash ref as args.  (Session must be tied when DestroySession
# is called.)
sub DestroySession {
    my ($self, $r, $sess) = @_;

    # Call the delete method for the the tied hash.  Wrapped in eval goodness
    # since Apache::Session will die on error.
    eval { tied(%{$sess})->delete; };
    if ($@) {
        $self->Log($r, ('warn', "DestroySession(): Unable to destroy session: $@"));
        return undef;
    }

    return 1;
}


## TRACKER - A system to store persistant and shared data for various
## uses. This is yet more code that could be refactored and busted into
## external modules to allow for adding arbitrary stateful checks of
## all sorts of things, (like the authentication handlers).
## For now, only a small set of tracker types are provided,
## and all are defined in this module.

# Get Tracker config (Tracker being a special case Session type targetted
# at IPC tasks)  The tracker should never hold sensitive data since encryption
# support is not provided!  Make sure to hash sensitive info if you need to
# track old session authentication keys or other items.
sub GetTrackerConfig {
    my ($self, $r) = @_;
    my $auth_name = ($r->auth_name()) || (die("GetTrackerConfig(): No auth name defined!\n"));
    my $dirconfig = $r->dir_config;

    my $trakconfig = {};

    # Pull in the session configurations then write the tracker config
    # over top.
    foreach (keys %{$dirconfig}) {
	(/^${auth_name}Session([\w\d]+)\s*$/) || (next);
	$trakconfig->{$1} = $dirconfig->{$_};
    }
    
    foreach (keys %{$dirconfig}) {
	(/^${auth_name}Tracker([\w\d]+)\s*$/) || (next);
	$trakconfig->{$1} = $dirconfig->{$_};
    }

    # Use files for storage and locking by default
    (exists($trakconfig->{Store})) || ($trakconfig->{Store} = "File");
    (exists($trakconfig->{Lock})) || ($trakconfig->{Lock} = "File");

    # Always use the basic Base64 serializer: it is portable, and avoids
    # having to special case of override when Crypt is used on sessions
    $trakconfig->{Serialize} = "Base64";

    # If files are being used, use the Session paths (if set), else die
    if ($trakconfig->{Store} eq 'File' && !exists($trakconfig->{Directory})) {
	$self->Log($r, ('error', "GetTrackerConfig(): ${auth_name}TrackerDirectoy must be defined for the File store"));
	return undef;
    }
    if ($trakconfig->{Lock} eq 'File' && !exists($trakconfig->{LockDirectory})) {
	$self->Log($r, ('error', "GetTrackerConfig(): ${auth_name}TrackerLockDirectoy must be defined for the File lock"));
	return undef;
    }

    return $trakconfig;
}

# Initiate the tracker.  Takes the $r request, a name (usually just the name of
# the module using the tracker), and returns a tied tracker hash reference.
# Currently does not support different settings for various tracker modules.
# All use the same cleanup, etc.
sub InitTracker {
    my ($self, $r, $name) = @_;
    my (%trak, $trakconfig);
    
    # Extract the tracker config
    ($trakconfig = $self->GetTrackerConfig($r)) || (die("InitTracker(): Unable to get tracker configuration: Please properly configure the tracker system or dissable features that use it\n"));
    
    # Basic sanity check on name, then set value in tracker config so the
    # Tracker module can pick it up if needed
    (($name) && ($name =~ /^[\w\d:\.\_\-]+$/)) || (die("InitTracker(): No tracker name or bad name specified for tracker\n"));
    $trakconfig->{Name} = $name;

    # Wrapped this in an eval, since Apache:Session type modules die on failure
    eval { tie(%trak, 'Apache::AppSamurai::Tracker', $name, $trakconfig); };
    if ($@) {
	$self->Log($r, ('error', "InitTracker(): Unable to setup tracker for \"$name\", retrying..."));
	# Try making a new one
	eval { tie(%trak, 'Apache::AppSamurai::Tracker', undef, $trakconfig); };
	if ($@) {
	    $self->Log($r, ('error', "InitTracker(): Unable to create new tracker for \"$name\": $@"));
	    return undef;
	}
	# Save its name inside
	$trak{Name} = $name;
	$self->Log($r, ('error', "InitTracker(): Created new tracker instance for \"$name\""));
    }

    # If cleanup is set, check if we need to run it
    if ($trakconfig->{Cleanup}) {
	# Fake last cleanup time as now, if not already set
	unless($trak{LastClean}) {
	    $trak{LastClean} = time();
	    $self->Log($r, ('debug', "InitTracker(): Set last cleanup for \"$name\" to " . $trak{LastClean}));
	}
	
	if ((time() - $trak{LastClean}) >= $trakconfig->{Cleanup}) {
	    $self->CleanupTracker($r, \%trak, $trakconfig->{Cleanup});
	}
    }

    # Return the open tracker hash ref
    return \%trak;
}

# Cleanup stale tracker items older than the given cleanup interval.
# Each item to clean MUST have a timestamp record in the first slot
# prefixed by "ts".
sub CleanupTracker {
    my ($self,$r,$trak,$to) = @_;
    my ($tk, $tts);
    my $time = time();

    (tied(%{$trak})) || die("CleanupTracker(): Called without valid tracker handle\n");
    ($trak->{LastClean}) || die("CleanupTracker(): Called without LastClean set for " . $trak->{Name} . "\n");

    # Default to 24 hour cleanup 
    ($to) || die("CleanupTracker(): Called without Cleanup time specified for " . $trak->{Name} . "\n");

    $self->Log($r, ('debug', "CleanupTracker(): Cleaning up items in \"" . $trak->{Name} . "\" older than $to seconds"));

    foreach $tk (keys %{$trak}) {
	# Skip items with no time stamp at start of value
	next unless ($trak->{$tk} =~ /^ts(\d+)/);
	$tts = $1;
	if (($tts + $to) < $time) {
	    # Older than timeout: kill!
	    $self->Log($r, ('debug', "CleanupTracker(): Deleting stale item in \"" . $trak->{Name} . "\": $tk," . $trak->{$tk}));
	    delete($trak->{$tk});
	}
    }

    # Update the LastClean time
    $trak->{LastClean} = $time;
}

# Get ready to use tracker handle, then pass the specified tracker module
# (second arg), and pass it the rest of the arguments.  Returns 1 on sucessful
# setup and a good return from the tracker module, else 0;
sub CheckTracker {
    my $self = shift;
    my $r = shift;
    my $tmod = shift;
    my @args = @_;
    my ($tconf,$trak);
    my $ret = 0;

    # This should all be extended to use external modules instead (like the
    # authentication modules.)  I am pressed for time, so only a small set
    # of local checks are currently supported.
    if ($tmod =~ /^(IPFailures|AuthUnique|SessionUnique)$/) {
	$tmod = "CheckTracker" . $tmod;

	$self->Log($r, ('debug', "CheckTracker(): Calling $tmod"));

	unless ($trak = $self->InitTracker($r,$tmod)) {
	    $self->Log($r, ('error', "CheckTracker(): Failed to get initialized tracker handle for $tmod"));
	    return 0;
	}

	# Tracker methods currently die on major failure.  (A move to
	# object based setup, like auth system, would allow removing this
	# while maintining proper logging.)
	eval { { no strict "refs"; $ret = &$tmod($trak, @args) } };

	if ($@) {
	    $self->Log($r, ('error', "CheckTracker(): Tracker processing error: $@"));
	    untie(%{$trak});
	    return undef;
	}

	# Uncomment to get a dump of the tracker to the log
	#foreach (sort keys %{$trak}) {
	#    $self->Log($r, ('debug', "$tmod: $_ = " . $trak->{$_}));
	#}
	
	untie(%{$trak});
    } else {
	$self->Log($r, ('error', "CheckTracker(): Unknown tracker type $tmod"));
	$ret = 0;
    }

    return $ret;
}	

# TODO - GET ALL TRACKER CHECKS AND MANAGEMENT REFACTORED TO OUTSIDE MODULES
# Check given tracker hash ($_[0]) for IP ($_[1]) hitting more than max ($_[2])
# times with no less than in interval ($_[3]) seconds between.
# Updates tracker item.
sub CheckTrackerIPFailures {
    my ($trak, $setting, $ip) = @_;
    my ($max, $interval, $tc, $tts);
    my $time = time();

    ($max,$interval) = split(':', $setting);
    unless (($max) && ($max =~ /^\d+$/) && ($interval) && ($interval =~ /^\d+$/)) {
	die("CheckTrackerIPFailures(): FATAL: Bad arguments to IPFailures: \"$setting\"\n");
    }

    ($ip = CheckHostIP($ip)) || (die("CheckTrackerIPFailures(): FATAL: Bad IP address\n"));

    # Force defaults of 10 failures in 1 minute or less intervals.
    ($max) || ($max = 10);
    ($interval) || ($interval = 60);

    # If defined and not timed out: add. Else starts fresh
    if ($trak->{$ip}) {
	($tts, $tc) = split(':', $trak->{$ip}, 2);
	
	# Sanity check, and pull actual numbers
	(($tts =~ s/^ts(\d+)$/$1/) && ($tc =~ s/^cnt(\d+)$/$1/)) || (die("CheckTrackerIPFailures(): FATAL: Corrupt entry for $ip detected\n"));

	# Not yet timed out
	if (($tts + $interval) > $time) {
	    $tc++;
	    $tts = $time;

	    $trak->{$ip} = join(':', "ts$tts", "cnt$tc");

	    if ($tc >= $max) {
	        die("CheckTrackerIPFailures(): RULE VIOLATION: ip=$ip, count=$tc\n");
	    }

	    return 1;
	}
    }

    # Expired or New entry: Set timestamp to now and count to 1
    $trak->{$ip} = join(':', "ts$time", "cnt1");
    
    return 1;
}

# Check given tracker hash ($_[0]), make sure we have not seen the same
# set of credentials ($_[1] - $_[n-1]) before.  Stores a hash of credential
# string to minimize security risk.
sub CheckTrackerAuthUnique {
    my $trak = shift;
    my $ch = HashAny(@_);
    my $time = time();

    # If defined, the jig is up!
    if ($trak->{$ch}) {
	die("CheckTrackerAuthUnique(): RULE VIOLATION: credkey=$ch\n");
    } else {
	# Set value to 
	$trak->{$ch} = 'ts' . $time . ":cnt1";
    }
        
    return 1;
}

# Check given tracker hash ($_[0]), make sure we have not seen the same
# session authentication key (cookie) before.  Stores a hash of session key
# string to minimize security risk.
sub CheckTrackerSessionUnique {
    my $trak = shift;
    my $ch = HashAny(@_);
    my $time = time();

    # If defined, the jig is up!
    if ($trak->{$ch}) {
	die("CheckTrackerSessionUnique(): RULE VIOLATION: sesskey=$ch\n");
    } else {
	# Set value to 
	$trak->{$ch} = 'ts' . $time . ":cnt1";
    }
        
    return 1;
}

# Check the last access time stamp, and update if needed, for a given session.
# Does NOT update the time if a fixed timeout has been set.
# Returns undef if the atime is more than the session's timeout age
# or if etime is set and is over the session's expire age.
sub CheckTime {
    my ($self, $sess) = @_;
    my $time = time();
    my $tdiff;
    my $ret = undef;

    # All sessions require at least a floating or fixed timeout!
    ($sess->{atime} || $sess->{etime}) or return undef;

    # Check the hard timeout first, if it exists.
    # This short circuits further checking since the hard timeout is king!
    if ($sess->{etime}) {
	if ($time >= $sess->{etime}) {
	    return undef;
	} else {
	    $ret = $sess->{etime};
	}
    }

    if ($sess->{atime}) {
	$tdiff = $time - $sess->{atime};
	if ($tdiff < $sess->{Timeout}) {
	    # We are still valid.  Update the time if we are over 60 seconds
	    # stale.
	    if ($tdiff >= 60) {
		$sess->{atime} = $time;
	    }
	    $ret = $sess->{atime};
	} else {
	    return undef;
	}
    }

    return $ret;
}


# The Alterlist functions manipulate and apply a list of transforms to apply to
# the headers and cookies of the client request before sending the request
# through to the backend server.  $self->{alterlist} is a hash containing
# one or more of the following container arrays:
#
# header
# ------
# @{$self->{alterlist}->{header}} - One or more header transforms, with the
#  syntax:
#                  ACTION:NAME:VALUE
#  ACTION - add, replace, or delete
#  NAME - Header name (or regex match for delete)
#  VALUE - New value of header for add or replace, else optional regex filter
#          for delete  (Prefix pattern with ! for negation)
#
# cookie
# ------
# @{$self->{alterlist}->{cookie}} - One or more cookie transforms, with the
#  syntax:
#                  ACTION:NAME:VALUE
#  ACTION - add, replace, delete, or passback
#  NAME - Cookie name (or regex match for delete)
#  VALUE - New value of cookie, or regex filter for delete action (Prefix
#          pattern with ! for negation)
# 
# Note - delete rules with optional value match pattern will delete only values
#        of a multi-value cookie that match the value pattern
#
# The special "passback" action passes cookies back to the web browser on
# login, This allows us to gather cookies from backend servers on login, but
# have the web browser maintain them.
#
# More containers can be added without modifying the generic functions.

# Load Alterlist rules from session and return a ref to the loaded alterlist
sub AlterlistLoad {
    my ($self, $sess) = @_;
    my ($sk,$rk);
    my $alterlist = {};

    # All alterlist save value start with al-
    foreach $sk (keys %{$sess}) {
	($sk =~ /^al\-([\w]+)$/) || (next);
	$rk = $1;
	@{$alterlist->{$rk}} = split("\n", $sess->{$sk});
    }

    return $alterlist;
}

# Update current alterlist with given alterlist hash ref
sub AlterlistMod {
    my ($self, $alterlist, $alm) = @_;
    my $rk;

    (defined($alterlist)) || ($alterlist = {});

    # Update alterlist from $alm hash ref
    foreach $rk (keys %{$alm}) {
	foreach (@{$alm->{$rk}}) {
	    push(@{$alterlist->{$rk}}, $_);
	}
    }

    # Modifications made directly, but return the ref in case
    return $alterlist;
}

# Save existing alterlist to given session
sub AlterlistSave {
    my ($self, $alterlist, $sess) = @_;
    my ($sk,$rk);

    # Save alterlist to session in \n deliminated form.
    if (defined($alterlist) && scalar(keys %{$alterlist})) {
	foreach $rk (keys %{$alterlist}) {
	    $sk = "al-" . $rk;
	    $sess->{$sk} = join("\n", @{$alterlist->{$rk}});
	}
    }

    return $alterlist;
}

# Apply current alterlist rules to request (just calls sub methods in order)
sub AlterlistApply {
    my ($self, $alterlist, $r) = @_;
    my $status = 1;
    (defined($alterlist)) || (return 0);

    if (defined($alterlist->{header})) {
	# Run through headers (saving off alter count)
	$self->AlterlistApplyHeader($alterlist, $r);
	$self->Log($r, ('debug', "AlterlistApply(): Applied alterlist for header"));
    }

    if (defined($alterlist->{cookie})) {
	# Run through cookies (saving off alter count)
	$self->AlterlistApplyCookie($alterlist, $r);
	$self->Log($r, ('debug', "AlterlistApply(): Applied alterlist for cookie"));
    }

    return $alterlist;
}

# Apply alterlist rules to request headers.
sub AlterlistApplyHeader {
    my ($self, $alterlist, $r) = @_;
    (defined($alterlist->{header})) || (return 0);
    my ($t, $h, $hl, $act, $key, $val, $tk, $tv);

    # Extract current header hash and build \n deliminated lookup string
    # to fast match against
    $h = $r->headers_in;
    $hl = "\n" . join("\n", keys(%{$h})) . "\n";
    
    # Cycle through all header transforms
    foreach $t (@{$alterlist->{header}}) {
	($t =~ /^(add|replace|rep|delete|del):([\w\d\-]+):(.*?)$/i) || (($self->Log($r, ('debug', "AlterlistApplyHeader(): Skipping illegal header transform \"$t\""))) && (next));
	$act = $1;
	$key = $2;
	$val = $3;
	
	if ($act =~ /^add$/) {
	    # Blindly clear then add the header
	    $r->headers_in->unset($key);
	    $r->headers_in->add($key => $val);

            # Log obscured value
	    $self->Log($r, ('debug', "HEADER ADD: $key: " . XHalf($val)));
	} else {
	    # Replace and delete allow for regex header name matches
	    while ($hl =~ /($key)/igm) {
		# Update 
		$tk = $1;
		# Make sure header was not deleted
		($r->headers_in->{$tk}) || (next);
		if ($act =~ /^replace|rep$/) {
		    # Blindly delete then add the header
		    # Save old value for log
		    $tv =  $r->headers_in->{$tk};
		    $r->headers_in->unset($tk);
		    $r->headers_in->add($tk => $val);

		    # Log obscured values
		    $self->Log($r, 'debug', ("AlterlistApplyHeader(): HEADER REPLACE: $tk: " . XHalf($tv) . " -> " . XHalf($val)));

		} elsif ($act =~ /^delete|del$/) {
		    # Check for extra content match
		    if ($val) {
			$tv = $r->headers_in->{$tk};
			# Handle negation
			if ($val =~ s/^\!//) {
			    ($tv =~ /($val)/is) && (next);
			} else {
			    ($tv =~ /($val)/is) || (next);
			}
		    }

		    # Kill!
		    $r->headers_in->unset($tk);

		    # Log obscured value
		    $self->Log($r, ('debug', "AlterlistApplyHeader(): HEADER DELETE: $tk: " . XHalf($tv)));
		}
	    }
	}
    }
    
    return $alterlist;
}


# Apply alterlist rules to request cookies.
# Note - Does not handle "passback" cookie.  Use AlterlistPassBackCookie() to
# retrieve and clear passback cookies)
sub AlterlistApplyCookie {
    my ($self, $alterlist, $r) = @_;

    (defined($alterlist->{cookie})) || (return 0);
    my ($t, %c, $cl, $act, $key, $val, $tk, $tv, @ta, @td);
    my $alterred = 0;

    # Grab any cookies any put into a hash of CGI::Cookies, or just make an
    # empty cookie hash for now.
    %c = CGI::Cookie->fetch($r);
    (%c) || (%c = ());
    # Build \n deliminated lookup string to fast match against
    $cl = "\n" . join("\n", keys(%c)) . "\n";
    
    foreach $t (@{$alterlist->{cookie}}) {
	# Note - : or = allowed between NAME and VALUE to make life easier
	($t =~ /^(add|replace|rep|delete|del|passback|set):([\w\d\-]+)(?:\:|\=)(.*?)$/i) || (($self->Log($r, ('debug', "AlterlistApplyCookie(): Skipping illegal cookie transform \"$t\""))) && (next));
	$act = $1;
	$key = $2;
	$val = $3;
	
	if ($act =~ /^passback|set$/) {
	    # passback not handled in this method
	    next;
	} elsif ($act =~ /^add$/) {
	    # Blindly add the cookie
	    @ta = split('&', $val);
	    # Add a new CGI::Cookie to the hash
	    $c{$key} = new CGI::Cookie(-name => $key, -value => \@ta);

	    # Log obscured value
	    $self->Log($r, ('debug', "AlterlistApplyCookie(): COOKIE ADD: $key=" . XHalf($val)));
	    $alterred++;
	} else {
	    # Replace and delete allow for regex cookie name matches
	    while ($cl =~ /($key)/igm) {
		# Update 
		$tk = $1;
		if ($act =~ /^replace|rep$/) {
		    # Blindly delete then add the cookie back with new value
		    # Save old value for log
		    $tv = join('&', $c{$tk}->value);;
		    delete($c{$tk});
		    @ta = split('&', $val);
		    $c{$tk} = new CGI::Cookie(-name => $tk, -value => \@ta);
		    
		    # Log obscured values
		    $self->Log($r, ('debug', "AlterlistApplyCookie(): COOKIE REPLACE: $tk: " . XHalf($tv) . " -> " . XHalf($val)));
		    $alterred++;
		} elsif ($act =~ /^delete|del$/) {
		    # Check for extra content match
		    if ($val) {
			@ta = ();
			@td = (); 
			# Cycle through multi-values
			foreach $tv ($c{$tk}->value) {
			    # Handle negation
			    if ($val =~ s/^\!//) {
				# Save value and continue
				if ($tv =~ /($val)/is) {
				    push(@ta, $tv);
				    next;
				}
			    } else {
				# Save value and continue
				unless ($tv =~ /($val)/is) {
				    push(@ta, $tv);
				    next;
				}
			    }
			    # Fell through, so this value is history/unsaved
			    push(@td, $tv);
			    $alterred++;
			}
			# Kill!
			if (scalar @ta) {
			    # Some values left not deleted, so set those back
			    $c{$tk}->value(\@ta);
			    $tv = join('&', @td);

			    # Log obscured value
			    $self->Log($r, ('debug', "AlterlistApplyCookie(): COOKIE DELETE PARTIAL: $tk=" . XHalf($tv)));
			} else {
			    # Nothing left inside. KILL!
			    delete($c{$tk});
			    $tv = join('&', @td);

			    # Obscure values for logging
			    $tv =~ s/([^X])[\w\d]/${1}X/gs;
			    $self->Log($r, ('debug', "AlterlistApplyCookie(): COOKIE DELETE FULL: $tk=$tv"));
			}
		    } else {
			# Kill Em All
			$tv = $c{$key}->value;
			delete($c{$key});
			    
                        # Obscure values for logging
			$tv =~ s/([^X])[\w\d]/${1}X/gs;
			$self->Log($r, ('debug', "AlterlistApplyCookie(): COOKIE DELETE FULL: $key=$tv"));

			$alterred++;
		    }
		}
	    }
	}
    }
    
    # Unset, then add cookies to header if changes were made
    if ($alterred) {
	$r->headers_in->unset('Cookie');
	$t = '';
	foreach $tk (keys %c) {
	    # Cookie to list in string form.
	    $t .= $c{$tk}->name . "=" . join('&', $c{$tk}->value) . "; ";
	}
	# Kill trailing '; '
	$t =~ s/\; $//s;
	# Ship it
	$r->headers_in->add('Cookie' => $t);
    }

    return $alterlist;
}

# Add a Set-cookie: header to r for all alterlist "passback" cookies and return
# a modified alterlist with the passback cookie values cleared and expired.
#
# Unlike normal alterlist rules, passback cookies are sent BACK to the client.
# The only time this can occur is upon login/redirect. The purpose of passback
# cookies is to set the same cookies in the browser as they would have set
# if they were connecting directly to the backend server(s).
#
# The return should be used to update the alterlist.  When
# AlterlistPassBackCookie is applied again, it will UNSET the passback cookies.
# This should be done on logout.
sub AlterlistPassBackCookie() {
    my ($self, $alterlist, $r) = @_;

    (defined($alterlist->{cookie})) || (return 0);
    my ($t, $key, $val, $opt, $tdomain, $tpath, $texpire);
    my @ct = ();
    my %c = ();

    foreach $t (@{$alterlist->{cookie}}) {
	# Note - : or = allowed between NAME and VALUE to make life easier
	($t =~ /^(passback|set):([\w\d\-]+)(?:\:|\=)([^;]*)(;.*)?$/i) || ((push(@ct, $t)) && (next));
	$key = $2;
	$val = $3;
	$opt = $4;
	$tdomain = $tpath = $texpire = '';

	# Unlike AlterlistApplyCookie which just needs to parse name and
	# value, the PassBack cookies are Set-Cookie items which may
	# have options.  Also, only process the last cookie value if
	# a multi-value cookie is passed

	# Add a new CGI::Cookie to the hash
	$c{$key} = new CGI::Cookie(-name => $key, 
				   -value => $val,
				   );
	# Set further options (only Expires and Path currently passed through)
	foreach $t (split(';', $opt)) {
	    if ($t =~ /^\s*expires=([\w\d \:\;\-,]+)\s*$/) {
		$c{$key}->expires($1);
	    } elsif ($t =~ /^\s*path=(\/.*?)\s*$/) {
                $c{$key}->path($1);
            }
	}

	# Set other options to match session cookie values (could be made a
	# configurable, and allow for maintaining the original options from the
	# cookie.  I don't see a need.)
	my $auth_name = $r->auth_name;
	    
	if ($r->dir_config("${auth_name}Domain")) {
	    $c{$key}->domain($r->dir_config("${auth_name}Domain"));
	}
	if (!$r->dir_config("${auth_name}Secure") || ($r->dir_config("${auth_name}Secure") == 1)) {
	    $c{$key}->secure(1);
	}
	
	$r->err_headers_out->add('Set-Cookie' => $c{$key});

	# Clean up and log
	$t = $c{$key};
	$t =~ /($key\s*\=\s*)(.*?)(;|$)/;
	$self->Log($r, ('debug', "AlterlistPassBackCookie(): COOKIE PASSBACK: " . $1 . XHalf($2) . $3));

	# Save an empty/expired cookie so next call to AlterlistPassBackCookie
	# with this alterlist will unset the cookie
	$c{$key}->value('');
	$c{$key}->expires('Thu, 1-Jan-1970 00:00:00 GMT');
	push(@ct, "passback:" . $c{$key});
    }

    # Save updated cookie array
    @{$alterlist->{cookie}} = @ct; 

    return $alterlist;
}


# Append an error code to the list of query args in a given URL.  (Used to
# pass friendly error messages to users in external redirects.  (Note that
# AuthCookie used subprocess_env() to pass that info, but since that will only
# work in the same main request, it won't pass into an external redirect.)
sub URLErrorCode {
    my $self = shift;
    my $uri = (shift) || (return undef);
    my $ecode = (shift) || ('');
    
    ($uri = new URI($uri)) || (return undef);
    
    # Error codes must contain only letters, numbers, and/or _ chars.
    # Your login.pl script should read them in CAREFULLY and make sure
    # they follow this format.
    ($ecode =~ /^([\w\d_]+)$/) || (return undef);
    
    # Add the error code and return the URI in string form
    $uri->query_form($uri->query_form, 'ASERRCODE' => $ecode);
    return $uri->as_string;
}

# Log to configured log.  Always takes the request as the 1st arg.  Can
# take either a loglevel and a message as args 2 and 3, or an array
# of loglevel and message arrays as the 2nd arg.
sub Log {
    my $self = shift;
    my $r = shift;
    my $la = [];
    my $debug = $self->_debug($r);

    # Check if being called with a level and message, or with a log array
    if (ref($_[0]) eq "ARRAY") {
	$la = $_[0];
	(defined(@{$la}) && (scalar @{$la})) || (return 0);
    } else {
	(defined($_[0]) && defined($_[1])) || (return 0);
	# Set to a single child array of arrays
	$la = [[$_[0], $_[1]]];
    }

    # Collect a few tidbits (package name, client IP and URI?args)
    my $auth_name = ($r->auth_name || "");
    $auth_name .= ': ';
    my $info = ' <client=';
    if ($MP eq 1) {
        $info .= ($r->get_remote_host || "");
    } else {
        $info .= ($r->connection->get_remote_host || "");
    }
    $info .= ', uri="';
    $info .= ($r->uri() || "");
    (defined($r->args())) && ($info .= '?' . $r->args());
    $info .= '">';

    # Get the log handle for the server
    my $log = $r->server->log;
    my $defaultlevel = 'error';
    my ($li, $level, $line);

    # Cycle through the log entries
    foreach $li (@{$la}) {
	if (scalar(@{$li}) == 2) { # 2 argument form with level and line
	    $level = $li->[0];
	    ($level) || ($level = $defaultlevel);
	    ($level =~ s/^(emerg|alert|crit|error|warn|notice|info|debug)$/$1/i) || (return 0);
	    $level = lc($level);
	    # Skip debug unless debug is enabled
	    next if (!$debug && ($level eq 'debug'));
	    $line = $auth_name . $li->[1] . $info;
	} elsif (scalar(@{$li}) == 1) { # 1 argument form: must add a level
	    $level = $defaultlevel;
	    $line = $auth_name . $li->[0] . $info;
	} else { # Who knows form: must hit someone's fingers with a hammer
	    return 0;
	}

	# Check log line, then ship it.
	$line = $self->FilterLogLine($line);
	$log->$level($line);
    }

    return 1;
}

# Check debug setting
sub _debug {
    my $self = shift;
    my $r = shift;
    my $debug = 0;
    if ($r->auth_name) {
	my $auth_name = $r->auth_name;
	if ($r->dir_config("${auth_name}Debug")) {
	    ($r->dir_config("${auth_name}Debug") =~ /^(\d+)$/) && ($debug = $1);
	}
    }
    
    return $debug;
}

# Filter the output line before logging.  Restricts to no more than CharMax
# characters and converts everything matching BlankChars to a space to
# try and protect logging systems and log monitors from attack.
sub FilterLogLine {
    my $self = shift;
    my $line = (shift || return undef);
    my $LogCharMax = 1024;

    # Strip surrounding whitespace 
    $line =~ s/^\s*(.+?)\s*$/$1/s;
    # Convert newlines to ', '
    $line =~ s/\r?\n/, /sg;
    # Check length and truncate if needed
    $line = substr($line, 0, $LogCharMax);
    # Convert BlankChars matches to blanks
    $line =~ s/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f\'\\]+/ /g;

    return $line;
}

1; # End of Apache::AppSamurai

__END__

=head1 NAME

Apache::AppSamurai - An Authenticating Mod_Perl Front End

"Protect your master, even if he is without honour...."

=head1 SYNOPSIS

All configuration is done within Apache.  Requires Apache 1.3.x/mod_perl1 or 
Apache 2.0.x/mod_perl2.  See L</EXAMPLES> for sample configuration segments.

=head1 DESCRIPTION

B<Apache::AppSamurai> protects web applications from direct attack by
unauthenticated users, and adds a flexible authentication front end
to local or proxied applications with limited authentication options.

Unauthenticated users are presented with either a login form, or a basic
authentication popup (depending on configuration.)  User supplied credentials
are checked against one or more authentication systems before the user's
session is created and a session authentication cookie is passed back to the
browser.  Only authenticated and authorized requests are proxied through
to the backend server.

Apache::AppSamurai is based on, and includes some code from,
L<Apache::AuthCookie|Apache::AuthCookie>.
Upon that core is added a full authentication and session handling framework.
(No coding required.)  Features include:

=over 4

=item *

B<Modular authentication> - Uses authentication sub-modules for the easy
addition custom authentication methods

=item *

B<Form based or Basic Auth login> - On the front end, supports standard
form based logins, or optionally Basic Auth login.  (For use with automated
systems that can not process a form.)

=item *

B<Apache::Session> - Used for session data handling

=item *

B<Session data encrypted on server> - By default, all session
data encrypted before storing to proxy's filesystem  (Uses custom
B<Apache::Session> compatible session generator and session serialization
modules)

=item *

B<Unified mod_perl 1 and 2 support> - One module set supports both
Apache 1.x/mod_perl 1.x and Apache 2.x/mod_perl 2.x

=back

=head1 SESSION STORAGE SECURITY

Server side session data may include sensitive information, including the basic
authentication C<Authorization> header to be sent to the backend server.
(This is just a Base64 encoded value, revealing the username and password
if stolen.)

To protect the data on-disk, Apache::AppSamurai includes
its own HMAC based session ID generator and encrypting session serializer.
(L<Apache::AppSamurai::Session::Generate::HMAC_SHA|Apache::AppSamurai::Session::Generate::HMAC_SHA>
and
L<Apache::AppSamurai::Session::Serialize::CryptBase64|Apache::AppSamurai::Session::Serialize::CryptBase64>
, respectively.)
These modules are configured by default and may be used directly with
Apache::Session, or outside of Apache::AppSamurai if desired.

=head1 USAGE

Almost all options are set using C<PerlSetVar> statements, and can be used
inside most configuration sections.

Each configuration option must be prefixed by the I<AuthName> for the
Apache::AppSamurai instance you wish to apply the option to.  This
I<AuthName> is then referenced within the protected area(s).   Most of setups
only require one I<AuthName>.  You can call it "BOB" or "MegaAuthProtection".
You can even call it "authname". 

B<IMPORTANT NOTE> - The I<AuthName> is omitted in the configuration
descriptions below for brevity.  "Example" is used as the I<AuthName> in the
L</EXAMPLES> section.

Most setups will include a set of global configuration values to setup the
Apache::AppSamurai instance.  Each protected area then points to a specific
AuthName and Apache::AppSamurai methods for authentication and
authorization.

=head2 GENERAL CONFIGURATION

=head3 I<Debug> C<0|1>

(Default: 0)
Set to 1 to send debugging output to the Apache logs.  (Note - you must have
a log configured to catch errors, including debug level errors, to see the
output.)

=head3 I<CookieName> C<NAME>

(Default:AUTHTYPE_AUTHNAME)
The name of the session cookie to send to the browser.

=head3 I<LoginScript> C<PATH>

(Default: undef)
The URL path (location) of the proxy's login page for form based login.
(Sample script provided with the Apache::AppSamurai distribution.)

=head3 I<Path> C<PATH>

(Default: /)
The URL path to protect.

=head3 I<Domain> C<DOMAIN>

(Default: not set)
The optional domain to set for all session cookies.  Do not configure this
unless you are sure you need it: A misconfigured domain can result in session
stealing.

=head3 I<Satisfy> C<All|Any>

(Default: All)
Set C<require> behaviour within protected areas.  Either C<All> to require all
authentication checks to succeed, or C<Any> to require only one to.

=head3 I<Secure> C<0|1>

(Default: 1)
Set to 1 to require the C<secure> flag to be set on the session cookie, forcing
the use of SSL/TLS.

=head3 I<HttpOnly> C<0|1>

(Default: 0)
Set to 1 to require the Microsoft proprietary C<http-only> flag to be set on
session cookies.

=head3 I<LoginDestination> C<PATH>

(Default: undef)
Set an optional hard coded destination URI path all users will be directed to
after login.  (While full URLs are allowed, a path starting in / is
recommended.)  This setting only applies so form based login.  Basic Auth
logins always follow the requested URL.

=head3 I<LogoutDestination> C<PATH>

(Default: undef)
Set an optional hard coded destination URI path all users will be directed to
after logging out. (While full URLs are allowed, a path starting in / is
recommended.)   This setting only applies so form based login.  Basic Auth
logins always follow the requested URL.

If I<LogoutDestination> is unset and I<LoginDestination> is set,
users will be directed to I<LoginDestination> after logout.  (This is
to prevent a user from logging back into the logout URI, which would log them
back out again.  Oh the humanity!) 

=head2 AUTHENTICATION CONFIGURATION

Most authentication is specific to the authentication module(s) being used.
Review their specific documentation while configuring.

=head3 I<AuthMethods> C<METHOD1,METHOD2...>

(Default: undef)
A comma separated list of the authentication sub-modules to use.  The order of
the list must match the order of the C<credentials_X> parameters in the login
form. (Note - C<credential_0> is always the username, and is passed as such to
all the authentication modules.)

=head3 I<BasicAuthMap> C<N1,N2,.. = REGEX>

(Default: undef)

Custom mapping of Basic authentication password input to specific and separate
individual credentials. This allows for AppSamurai to request basic
authentication for an area, then split the input into credentials that can be
checked against multiple targets, just like a form based login.  This is very
useful for clients, like Windows Mobile ActiveSync, that only support basic
auth logins.  Using this feature you can add SecurID or other additional
authentication factors without having to pick only one.

The syntax is a bit odd.  First, specify a list of the credential numbers
you want mapped, in order they will be found within the input. Then
create a regular expression that will match the input, and group each item
you want mapped.

Example:

 PerlSetVar BobAuthBasicAuthMap "2,1=(.+);([^;]+)"

If the user logs into the basic auth popup with the password:
C<myRockinPassword;1234123456> ,the map above will set credential_1 as
C<1234123456> and credential_2 as C<myRockinPassword>, then proceed as if 
the same were entered into a form login.

=head3 ADDITIONAL AUTHENTICATION OPTIONS

Authentication submodules usually have one or more required settings.  All
settings are passed using PerlSetVar directives with variable names prefixed
with the AuthName and the module's name.

Example:

 PerlSetVar BobAuthBasicLoginUrl C<https://bob.org/login>

For AuthName C<Bob>, set the C<LoginUrl> for the C<AuthBasic> authentication
module to C<https://bob.org/login>

See L<Apache::AppSamurai::AuthBase> for general authentication module
information.  If you need an authentication type that is not supported
by the authentication modules shipped with AppSamurai, and is not
available as an add on module, please review L<Apache::AppSamurai::AuthBase>
and use the skeletal code from AuthTest.pm, which is included under
/examples/auth/ in the AppSamurai distribution.

=head2 SESSION CONFIGURATION

Each Apache::AppSamurai instance must have its local (proxy server side)
session handling defined.
L<Apache::Session|Apache::Session> provides the majority of the session
framework.  Around Apache::Session is wrapped
L<Apache::AppSamurai::Session|Apache::AppSamurai::Session>, which
adds features to allow for more flexible selection of sub-modules.

Most Apache::Session style configuration options can be passed directly to the
session system by prefixing them with C<authnameSession>.

Module selection is slightly different than the default supplied with
Apache::Session.  Plain names, without any path or ::, are handled
exactly the same: Modules are loaded from within the Apache::Session
tree.  Two additional alternatives are provided:

=over 4

=item *

I<AppSamurai/MODULE> - Load I<MODULE> from under the
B<Apache::AppSamurai::Session> tree instead of the B<Apache::Session> tree.

=item *

I<PATH::MODULE> - Load I<PATH::MODULE> literally.  Note - Since :: is required
to be present, a root module name will not work.

=back

The most common configuration options follow.  See
L<Apache::AppSamurai::Session|Apache::AppSamurai::Session> and
L<Apache::Session|Apache::Session> for
more advanced options, like using a database for storage.

B<NOTE> - "Session" is shown prepending each of these directives, Inside
the L<Apache::AppSamurai::Session|Apache::AppSamurai::Session> and
L<Apache::Session|Apache::Session> documentation, "Session" is omitted.

=head3 SessionI<Expire> C<SECONDS>

(Default: 0)
The maximum session lifetime in seconds.  After a user has been logged in this
long, they are logged out.  (Ignores weather the user is idle or not.)


=head3 SessionI<Timeout> C<SECONDS>
(Default: 3600 (1 hour)).

The maximum time a session can be idle before being removed.  After a user has
not accessed the protected application for this many seconds, they are logged
out.

=head3 SessionI<Store> C<NAME>

(Default: File)
The session storage module name. "File" is the default, which maps to
B<Apache::Session::Store::File|Apache::Session::Store::File>
(Note - See the top of this section,
L</SESSION CONFIGURATION>, for details on the three ways to specify a path
for this option and the following options that point to a module.)

=head3 SessionI<Lock> C<NAME>

(Default: File)
The session locking module name.  "File" is used by default, which maps to
B<Apache::Session::Lock::File|Apache::Session::Lock::File>

=head3 SessionI<Generate> C<NAME>

(Default: AppSamurai/HMAC_SHA)
The session ID generator module name. "AppSamurai/HMAC_SHA" is used by default,
which maps to
L<Apache::AppSamurai::Session::Generate::HMAC_SHA|Apache::AppSamurai::Session::Generate::HMAC_SHA>
This special module takes a server key and a session authentication key and
returns a HMAC code representing the local ("real") session ID.  (Input and
output are all SHA256 hex strings that are passed in using the sessionconfig
hash.)

As this is tied closely into the current Apache::AppSamurai code, please do
not use an alternate serializer without first reviewing the related code.

=head3 SessionI<Serialize> C<NAME>

(Default: AppSamurai/CryptBase64)
The session data serializer module.  "AppSamurai/CryptBase64" is used by
default, which maps to
L<Apache::AppSamurai::Session::Serialize::CryptBase64|Apache::AppSamurai::Session::Serialize::CryptBase64>
This special module uses server key and a session authentication key to
encrypt session data using a block cipher before Base64 encoding it.
(All keys are 256 bit hex strings.)

Base64 allows for storage in file, database, etc without worrying about binary
data issues.  In addition, this module allows for safer storage of data on
disk, requiring both the local server key and the secret session key from the
user before unlocking the data.

L<Crypt::CBC|Crypt::CBC> is used with a support block cipher module to perform
encryption/decryption.  (See the next section for information on
configuring a cipher.)

As this is tied closely into the current Apache::AppSamurai code, please do not
use an alternate serializer without first reviewing the related code.

=head3 SessionI<SerializeCipher> C<CIPHER_MODULE>

(Default: undef)
Select the block cipher provider module for
L<Apache::AppSamurai::Session::Serialize::CryptBase64|Apache::AppSamurai::Session::Serialize::CryptBase64>
to use.  For production, you should use this to configure a specific block
cipher to use.  If not set, the cipher is autodetected from the list below.
(Note that autodetect is slow and picks the first cipher module it finds,
which may not be the one you want.)

The following block cipher modules are currently allowed:

 Crypt::Rijndael     - AES implementation (default)
 Crypt::OpenSSL::AES - OpenSSL AES wrapper
 Crypt::Twofish      - Twofish implementation
 Crypt::Blowfish     - Blowfish implementation

See
L<Apache::AppSamurai::Session::Serialize::CryptBase64|Apache::AppSamurai::Session::Serialize::CryptBase64>
for more information.

=head3 SessionI<ServerKey> C<KEY>

(Default: undef)
Define the server's "server key".  (This option is mutually exclusive with
the SessionServerPass option.)  If you configure ServerKey, it MUST be
a 64 character hex string.  (Use L</SessionServerPass PASSPHRASE> if you
prefer using an arbitrary length prase in your configuration.)

The server key is used to look up local session IDs and encrypt/decrypt them
when the HMAC_SHA session generator and CryptBase64 session serializer are
used.  

As this is tied closely into the current AppSamurai code, it is a required
configuration directive.  Either ServerPass or ServerKey must be defined.
Standard Apache::Session generator/serializer modules ignore this setting.

IMPORTANT NOTE FOR CLUSTERS/MULTIPLE PROXIES: If you use a shared session
storage back end (database), and a cluster of AppSamurai proxies to protect 
a single application (using the same AuthName on each), you must use the same
key or pass in the AuthName on each server in the cluster.  The key is used
both the authenticate the user and to decrypt the session data.  

=head3 SessionI<ServerPass> C<PASSPHRASE>

(Default: undef)
Sets an arbitrary length pass code that will be passed through SHA256 to
produce the server's server key.  See L</SessionServerKey KEY> for how
that key is used.

=head3 FURTHER SESSION CONFIGURATION

See L<Apache::AppSamurai::Session|Apache::AppSamurai::Session> and
L<Apache::Session|Apache::Session> for more on the
session system.

=head2 TRACKER SYSTEM CONFIGURATION

The B<Tracker> system is a based on a set of special Apache::Session
stores that are visible between Apache processes.  (In fact, with a shared
central database, they could be visible to an entire cluster of servers.)
It is provided to store various state information for built-in and add-on
features.

Tracker storage uses
L<Apache::AppSamurai::Tracker|Apache::AppSamurai::Tracker>,
which is a modified version of Apache::AppSamurai::Session.  

Security Note - The Tracker system does not use encryption, so never store
sensitive information in a tracker.  If you need to track sensitive items,
encrypt or hash them beforehand.

=head3 TrackerI<Store> C<NAME>

(Default: File)
The tracker storage module name. "File" is the default, which maps to
B<Apache::Session::Store::File|Apache::Session::Store::File>
(Note - See the top of this section,
L</SESSION CONFIGURATION>, for details on the three ways to specify a path
for this option and the following options that point to a module.)

=head3 TrackerI<Lock> C<NAME>

(Default: File)
The tracker locking module name.  "File" is used by default, which maps to
B<Apache::Session::Lock::File|Apache::Session::Lock::File>

=head3 TrackerI<Cleanup> C<SECONDS>

(Default: undef)
If defined, tracked items that have been untouched in this many seconds
are removed.  In the future this may be configurable per-tracker type,
but for now it provides a rudimentary cleanup system.

=head3 FURTHER TRACKER SYSTEM CONFIGURATION

See L<Apache::AppSamurai::Tracker|Apache::AppSamurai::Tracker> for more
on tracker system configuration.

=head2 TRACKER BASED FEATURES

The following features require the tracker system to be configured.
These are pretty basic and static at this point.  (Should probably
be split out into modules.)

=head3 I<IPFailures> C<COUNT:SECONDS>

(Defualt: undef)
Block further login attempts from IPs that send C<COUNT> failures with
no more than C<SECONDS> seconds between each subsequent failure.  Once
blocked, the block will remain in effect till at least C<SECONDS> has
elapsed since the last connection attempt.

=head3 I<AuthUnique> C<0|1>

(Default: 0)
If set to 1, forces at least one credential to be unique per-login.
(Requires dynamic token or other non-static authentication type.)

=head3 I<SessionUnique> C<0|1>

(Default: 0)
If 1, prohibits a new session from using the same session ID as a previous
session.  This is generally only relevant for non-random sessions that use the
C<Keysource> directive to calculate a pseudo-cookie value.

=head1 METHODS

The following methods are to be used directly by Apache.  (This is not
a full list of all Apache::AppSamurai methods.)

=head3 authenticate()

Should be configured in the Apache config as the PerlAuthenHandler for
areas protected by Apache::AppSamurai.

C<authenticate()> is called by object reference and expects an Apache request
object as input.C<authenticate()> uses a session authentication key, either
from a cookie or from the optional C<Keysource>, and tries to open the session
tied to the session authentication key.

If the session exists and is valid, the username is extracted from the session
and the method returns C<OK> to allow the request through.

If no key is present, if the session is not present, or if the session
is invalid, a login request is returned.  (Either a redirect to a login form,
or in the case of an area set to basic authentication, a
C<401 Authorization Required> code.)

=head3 authorize()

Should be configured in the Apache config as the PerlAuthzHandler for
areas protected by Apache::AppSamurai.

C<authorize()> is called by object reference and expects an Apache request
object as input.  It then checks the authorization requirements for the
requested location.  In most cases, "require valid-user" is used in conjunction
with the "Satisfy All" Apache::AppSamurai setting.  This authorizes any logged
in user to pass.  This method could be replaced or expanded at a later date if
more granular authorization is required.  (Groups, roles, etc.)

C<OK> is returned if conditions are satisfied, otherwise C<HTTP_FORBIDDEN> is
returned.

=head3 login()

Should be configured in the Apache config as the PerlHandler, (or
"PerlResponseHandler" for mod_perl 2.x), for a special pseudo file under
the F<AppSamurai/> directory.  In example configs and
the example F<login.pl> form page, the pseudo file is named B<LOGIN>.

C<login()> expects an Apache request with a list of credentials included as
arguments.  B<credential_0> is the username.  All further credentials are
mapped in order to the authentication modules defined in L</AuthMethods>.
Each configured authentication method is checked, in order.  If all
succeed, a session is created and a session authentication cookie is returned
along with a redirect to the page requested by the web browser.

If login fails, the browser is redirected to the login form.

=head3 logout()

Should be called directly by your logout page or logout pseudo file.
This expects an Apache request handle.  It can also take a second
option, which should be a scalar URI path to redirect users to after
logout.  C<logout()> attempts to look up and destroy the session tied to the
passed in session authentication key.

Like C<login()>, you may create a special pseudo file named LOGOUT and
use PerlHandler, (or "PerlResponseHandler" for mod_perl 2.x), to map it
to the C<logout()> method.  This is particularly handy when paired with
mod_rewrite to map a specific application URI to a pseudo file mapped to
C<logout()>  (See L</EXAMPLES> for a sample config that uses this method.)


=head1 EXAMPLES

 ## This is a partial configuration example showing most supported
 ## configuration options and a reverse proxy setup.  See examples/conf/
 ## in the Apache::AppSamurai distribution for real-world example configs.

 ## Apache 1.x/mod_perl 1.x settings are enabled with Apache 2.x/mod_perl 2.x
 ## config alternatives commented out. ("*FOR MODPERL2 USE:" precedes
 ## the Apache 2.x/mod_perl 2.x version of any alternative config items.)
 ## Note that example configs in examples/conf/ use IfDefine to support
 ## both version sets without having to comment out items. Also note that it
 ## is far too ugly looking to include in this example.

 ## General mod_perl setup
 
 # Apache::AppSamurai is always strict, warn, and taint clean. (Unless
 # I mucked something up ;)
 PerlWarn On
 PerlTaintCheck On
 PerlModule Apache::Registry
 #*FOR MODPERL2 USE:
 # PerlSwitches -wT
 # PerlModule ModPerl::Registry

 # Load the main module and define configuration options for the 
 # "Example" auth_name
 PerlModule Apache::AppSamurai
 PerlSetVar ExampleDebug 0
 PerlSetVar ExampleCookieName MmmmCookies
 PerlSetVar ExamplePath /
 PerlSetVar ExampleLoginScript /login.pl

 # Defaults to All by may also be Any
 #PerlSetVar ExampleSatisty All
 
 # Optional session cookie domain (Avoid unless absolutely needed.)
 #PerlSetVar ExampleDomain ".thing.er"

 # Require secure sessions (default: 1)
 #PerlSetVar ExampleSecure 1

 # Set proprietary MS flag
 PerlSetVar ExampleHttpOnly 1

 # Define authentication sources, in order
 PerlSetVar ExampleAuthMethods "AuthRadius,AuthBasic"

 # Custom mapping of xxxxxx;yyyyyy Basic authentication password input
 # to specific and separate individual credentials. (default: undef)
 PerlSetVar ExampleBasicAuthMap "2,1=(.+);([^;]+)"

 
 ## Apache::AppSamurai::AuthRadius options ##
 # (Note - See L<Apache::AppSamurai::AuthRadius> for more info)
 PerlSetVar ExampleAuthRadiusConnect "192.168.168.168:1645"
 PerlSetVar ExampleAuthRadiusSecret "radiuspassword"

 
 ## Apache::AppSamurai::AuthBasic options.##
 # (Note - See L<Apache::AppSamurai::AuthBasic> for more info)
 
 # Set the URL to send Basic auth checks to
 PerlSetVar ExampleAuthBasicLoginUrl "https://ex.amp.le/thing/login"
 
 # Always send Basic authentication header to backend server
 PerlSetVar ExampleAuthBasicKeepAuth 1
 
 # Capture cookies from AuthBasic login and set in client browser
 PerlSetVar ExampleAuthBasicPassBackCookies 1
 
 # Abort the check unless the "realm" returned by the server matches
 PerlSetVar ExampleAuthBasicRequireRealm "blah.bleh.blech"
 
 # Pass the named header directly through to the AuthBasic server 
 PerlSetVar ExampleAuthBasicUserAgent "header:User-Agent"

 
 ## Session storage options ##
 # (Note - See L<Apache::AppSamurai::Session> and L<Apache::Session> for
 # more information.)
 
 # Inactivity timeout (in seconds)
 PerlSetVar ExampleSessionTimeout 1800

 # Use the File storage and lock types from Apache::Session
 PerlSetVar ExampleSessionStore "File"
 PerlSetVar ExampleSessionLock "File"

 # File storage options (Relevant only to File storage and lock types)
 PerlSetVar ExampleSessionDirectory "/var/www/session/sessions"
 PerlSetVar ExampleSessionLockDirectory "/var/www/session/slock"

 # Use the Apache::AppSamurai::Session::Generate::HMAC_SHA generator
 PerlSetVar ExampleSessionGenerate "AppSamurai/HMAC_SHA"

 # Use the Apache::AppSamurai::Session::Serialize::CryptBase64
 # data serializer module with Crypt::Rijndael (AES) as the block
 # cipher provider
 PerlSetVar ExampleSessionSerialize "AppSamurai/CryptBase64"
 PerlSetVar ExampleSessionSerializeCipher "Crypt::Rijndael"

 # Set the server's encryption passphrase (for use with HMAC session
 # generation and/or encrypted session storage)
 PerlSetVar ExampleSessionServerPass "This is an example passphrase"

 
 ## Tracker storage options ##
 
 # Cleanup tracker entries that have not changed in 1 day 
 PerlSetVar ExampleTrackerCleanup 86400

 # Block further login attempts from IPs that send 10 failures with
 # no more than 60 seconds between each subsequent failure
 PerlSetVar ExampleIPFailures "10:60"

 # Force at least one credential to be unique per-login.  (Requires
 # token or other non-static authentication type.)
 PerlSetVar ExampleAuthUnique 1

 # Prohibit a new session from using the same session ID as a previous
 # session.  (Only relevant for non-random sessions that use the
 # Keysource directive to calculate a pseudo-cookie.)
 PerlSetVar ExampleSessionUnique 1

 
 ## Special AppSamurai directory options ##
 
 # (These will vary widely depending on your specific setup and requirements.)
 <Directory "/var/www/htdocs/AppSamurai">
  AllowOverride None
  deny from all
  
  <FilesMatch "\.pl$">
   SetHandler perl-script
   Options +ExecCGI
   AuthType Apache::AppSamurai
   AuthName "Example"
    
   PerlHandler Apache::Registry
   #*FOR MODPERL2 USE:
   #PerlResponseHandler ModPerl::Registry
   
   allow from all
  </FilesMatch>
  
  <Files LOGIN>
   SetHandler perl-script
   AuthType Apache::AppSamurai
   AuthName "Example"

   PerlHandler Apache::AppSamurai->login
   #*FOR MODPERL2 USE:
   #PerlResponseHandler Apache::AppSamurai->login

   allow from all
  </Files>

  <Files LOGOUT>
   SetHandler perl-script
   AuthType Apache::AppSamurai
   AuthName "Example"

   PerlHandler Apache::AppSamurai->logout
   #*FOR MODPERL2 USE:
   #PerlResponseHandler Apache::AppSamurai->logout

   allow from all
  </Files>
 </Directory>
   
 <Directory "/var/www/htdocs/AppSamurai/images">
  Options None
  allow from all
 </Directory>

 # Protected/proxied resource config 1: Form based
 <Directory "proxy:https://ex.amp.le/thing/*">
 #*FOR MODPERL2 USE:
 #<Proxy "https://ex.amp.le/thing/*">
 
  AuthType Apache::AppSamurai
  AuthName "Example"
  PerlAuthenHandler Apache::AppSamurai->authenticate
  PerlAuthzHandler Apache::AppSamurai->authorize
  Order deny,allow
  Allow from all
  require valid-user
 
 </Directory>
 #*FOR MODPERL2 USE:
 #</Proxy>


 # Protected/proxied resource config 2: Basic auth
 <Directory "proxy:https://ex.amp.le/thaang/*">
 #*FOR MODPERL2 USE:
 #<Proxy "https://ex.amp.le/thaang/*">

  AuthType Basic
  AuthName "Example"
  PerlAuthenHandler Apache::AppSamurai->authenticate
  PerlAuthzHandler Apache::AppSamurai->authorize

  # Add some local overrides to this directory.  (Has
  # no affect on other directories/locations)

  # Switch from an inactivity timeout to a hard expiration
  PerlSetVar ExampleSessionExpire 3600
  PerlSetVar ExampleSessionTimeout 0

  # In lieu of cookies, calculate the session key using the
  # basic auth header from the client, and an argument called
  # "Sessionthing" from the request URL.  (NOTE - Keysource
  # should be used with care!  Do not use it unless you are
  # sure of what you are doing!!!)
  PerlAddVar ExampleKeysource header:Authorization
  PerlAddVar ExampleKeysource arg:Sessionthing

  Order deny,allow
  Allow from all
  require valid-user

 </Directory>
 #*FOR MODPERL2 USE:
 #</Proxy>


 # Do not allow forward proxying
 ProxyRequests Off
 
 # Proxy requests for /thing/* to  https://ex.amp.le/thing/*
 RewriteRule ^/thing/(.*)$ https://ex.amp.le/thing/$1 [P]

 # Similar for /thaang/*
 RewriteRule ^/thaang/(.*)$ https://ex.amp.le/thaang/$1 [P]

 # Redirect requests to / into our default app
 RewriteRule ^/?$ /thing/ [R,L]

 # Allow in AppSamurai requests to proxy server
 RewriteRule ^/AppSamurai -

 # Capture logout URL from app and send to a pseudo page mapped to logout() 
 RewriteRule ^/thing/logout\.asp$ /AppSamurai/LOGOUT

 # Block all other requests
 RewriteRule .* - [F]

 #*FOR MODPERL2 YOU MUST UNCOMMENT AND PUT THE FOLLOWING INSIDE
 # RELEVANT VirtualHost SECTIONS (For most Apache2 setups, this would be
 # the "<VirtualHost _default_:443>" section inside ssl.conf)
 #
 ## Enable rewrite engine inside virtualhost
 #RewriteEngine on
 ## Inherit rewrite settings from parent (global)
 #RewriteOptions inherit
 ## Enable proxy connections to SSL
 #SSLProxyEngine on


=head1 EXTENDING

Additional authentication modules, tracking features, and other options
can be added to Apache::AppSamurai.  In the case of authentication modules,
all that is required is creating a new module that inherits from
L<Apache::AppSamurai::AuthBase|Apache::AppSamurai::AuthBase>.

Other features may be more difficult to add.  (Apache::AppSamurai could
use some refactoring.)

Interface and utility methods are not documented at this time.  Please
consult the code, and also the L<Apache::AuthCookie|Apache::AuthCookie>
documentation.

=head1 FILES

=over 4

=item F<APPSAMURAI_CONTENT/>

Directory that holds Apache::AppSamurai login/logout pages and related
content.  This must be served by Apache and reachable.  (This is
generally mapped to B</AppSamurai/> on the server.)   When starting from
scratch, copy the contents of F</examples/htdocs/> from the Apache-AppSamurai
distribution into this directory.

=item F<APPSAMURAI_CONTENT/login.pl>

The default login mod_perl script.  Must be modified to match your setup.

=item F<APPSAMURAI_CONTENT/login.html>

The default HTML login form template.  (Split out from login.pl to ease
customization.)

=item F<APPSAMURAI_CONTENT/robots.txt>

Generic "deny all" robots file. (You don't want your login area appearing
on Google.  Note that the default login page also has a META tag to prevent
indexing.)

=item F<APPSAMURAI_CONTENT/images/>

Image files for login page.

=back

=head1 SEE ALSO

L<Apache::AppSamurai::Session>, L<Apache::AppSamurai::Tracker>,
L<Apache::AppSamurai::AuthBase>, L<Apache::AppSamurai::AuthBasic>,
L<Apache::AppSamurai::AuthRadius>, L<Apache::AppSamurai::AuthSimple>,
L<Apache::AppSamurai::Util>,L<Apache::AppSamurai::Session::Generate::HMAC_SHA>,
L<Apache::AppSamurai::Session::Serialize::CryptBase64>,
L<Apache::Session>

=head1 AUTHOR

Paul M. Hirsch, C<< <paul at voltagenoir.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<< <paul at voltagnoir.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Apache::AppSamurai

You can also look for information at:

=over 4

=item * AppSamurai Project Homepage
L<http://appsamurai.sourceforge.net>

=item * AppSamurai Project Homepage (backup)
L<http://www.voltagenoir.org/AppSamurai/>

=item * AnnoCPAN: Annotated CPAN documentation
L<http://annocpan.org/dist/Apache-AppSamurai>

=back

=head1 ACKNOWLEDGEMENTS

AppSamurai.pm (the main Apache::AppSamurai module), contains some code
from Apache::AuthCookie, which was developed by Ken Williams and others.
The included Apache::AuthCookie code is under the same licenses as Perl
and under the following copyright:

Copyright (c) 2000 Ken Williams. All rights reserved.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Paul M. Hirsch, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
