package Apache::AuthCookieURL;
use strict;
use mod_perl qw(1.24 StackedHandlers MethodHandlers Authen Authz);
use Apache::Constants qw(:common M_GET REDIRECT MOVED);
use vars qw($VERSION);
use Apache::URI ();
use Apache::Cookie;

use constant DEBUG  => 'AuthCookieURLDebug';

# $Id: AuthCookieURL.pm,v 1.3 2000/11/21 00:46:01 lii Exp $
$VERSION = sprintf '%d.%03d', q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

#======================== NOTE ============================================

### This module is a modification of Ken Williams <ken@forum.swarthmore.edu>
### Apache::AuthCookie apache module.

# Modified July 14, 2000 to handle munged urls and sessions w/o login
# - use cookies or munged urls for sessions
# - can be used with a login script, or without for simple session management
# - Will create sessions without overriding, if you don't care how unique they are.
# Comments to: Bill Moseley moseley@hank.org

#======================== NOTE ============================================




# These should be overridden in your own module
# Purpose: to provide a default session ID when not using a login script
# Must use with URLsession enabled so initail redirect will see a different url
# in the Location header from the original request.

sub authen_cred ($$\@) {
    my $self = shift;
    my $r = shift;
    my @creds = @_;

    # Normall this would convert credentials into a session key
    

    # A really silly session key.
    return time . $$ . int rand $$;

    # Or return a flag that authen_ses_key can look for
    return 'invalid:account_expired';

    # Or return a message that will be placed in a 'Reason' cookie
    return ('','User Blocked');

}    

sub authen_ses_key ($$$) {
    my ($self, $r, $session) = @_;

    # Validate the session and convert it into REMOTE_USER
    

    # This is using the session key as the REMOTE_USER
    return $session;

    # This returns undef so no REMOTE_USER is set sending back to login form
    # Make sure there IS a login form before doing this.
    return undef;
    
}



sub recognize_user ($$) {
    my ($self, $r) = @_;
    my $debug = $r->dir_config( DEBUG ) || 0;
    my ($auth_type, $auth_name) = ($r->auth_type, $r->auth_name);
    return unless $auth_type && $auth_name;
    # return unless $r->header_in('Cookie');

    
    my ($cookie) = ($r->header_in( 'Cookie' ) || '') =~ /${auth_type}_$auth_name=([^;]+)/;

    # Get session from URI if not set in a cookie
    # (won't likely be here if this isn't a protected doc)
    $cookie ||= $r->notes( 'URI_Session' ) || '';


    $r->log_error("session provided  = '$cookie'" ) if $debug >= 1;

    return OK unless $cookie;

    if (my ($user) = $auth_type->authen_ses_key($r, $cookie)) {
        $r->log_error("recognize user = '$user'") if $debug >= 2;
        $r->connection->user($user);
    }
    return OK;
}


# Transhandler to strip the session from the URL
#
# $r->notes('Session_prefix')      session prefix found in httpd.conf
#                                  also used to idicate to login() that trans handler in use
#
# $r-notes('URI_Session')          is the extracted session.
#                                  authenticate() uses it if no cookie
#
# $r->subprocess_env( 'SESSION' )  is set so cgi scripts can prefix to href links
#
# $r->notes( 'SESSION' )           is set for ErrorDocument fixups - prefix
#                                  Location: headers if exists (might as well use the $ENV{SESSION})


sub URLsession ( $$ ) {
    my ($self, $r) = @_;

    return DECLINED unless $r->is_initial_req;

    # I'd like to be able to do this so don't need all that httpd.conf config
    # $r->custom_response( MOVED , \&error_document );
    # $r->custom_response( REDIRECT , \&error_document );


    my $debug = $r->dir_config( DEBUG ) || 0;
    $r->log_error('TRANS:Requested URI = \'' . $r->the_request() . "'" ) if $debug >= 3;


    my ( undef, $session, $rest ) = split m[/+], $r->uri, 3;
    $rest ||= '';

    my $prefix = $r->dir_config('SessionPrefix') || 'Session-';

    # This way simply adding the PerlTransHandler is enough to enable URL munging
    $r->notes( Session_prefix => $prefix );


    return DECLINED unless $session && $session =~ /^$prefix(.+)$/;


    # Session found.  Extract and make it available in notes();

    $session = $1;

    $r->log_error("Found session '$session' in url") if $debug >= 1;

    $r->notes( URI_Session => $session );


    # Make the prefix and session available to CGI scripts for use in absolute
    # links or redirects
    
    $r->subprocess_env( SESSION => "/$prefix$session" );

    $r->notes( SESSION => "/$prefix$session" );  # for error document fixup

 
    # Remove the session from the URI
    $r->uri( "/$rest" );

    return DECLINED;
}




# Error document

# Add the session ID to location headers on redirects
# iff not using cookies and host matches

sub error_document ($$) {
    my ( $self, $r )  = @_;

    my $uri;

    # unlikely, but might as well make sure there's a location header available

    if ( $r->prev->header_out('Location') ) {

        $uri = Apache::URI->parse($r, $r->prev->header_out('Location') );

        
        my $same_host   = 1;
        my $hostname    = $uri->hostname || '';
        $same_host = 0 if $hostname && $hostname ne $r->get_server_name;


        my $session = $r->prev->notes( 'SESSION' ) || '';

        if ( $same_host && $session && $uri->path !~ /^$session/ ) {
            $uri->path( $session . $uri->path );
            $r->header_out('Location', $uri->unparse );

        } else {
            $r->header_out('Location', $r->prev->header_out('Location') );
        }
    }


    my $status      = $r->prev->status;
    my $location    = $uri ? $uri->unparse : 'unknown';
    my $description = ( $status == MOVED ) ? 'Moved Permanently' : 'Found';

    my $message = <<EOF;

<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<HTML>
  <HEAD>
    <TITLE>$status $description</TITLE>
  </HEAD>
  <BODY>
    <H1>$description</H1>
    The document has moved <A HREF="$location">$location</A>.<P>
  </BODY>
</HTML>
EOF

    $r->content_type('text/html');
    $r->send_http_header;
   
    $r->print( $message );

    return OK;

}

    
# Action of the login.pl script, or called directly from authenticate if login script is 'NONE'
sub login ($$) {
    my ($self, $r, $destination ) = @_;


    my $debug = $r->dir_config( DEBUG ) || 0;
    $r->log_error( "** In login **" ) if $debug >= 3;

    my ($auth_type, $auth_name) = ($r->auth_type, $r->auth_name);


    my %args = $r->method eq 'POST' ? $r->content : $r->args;


    $destination ||= $args{destination} || '';

    unless ( $destination ) {
        $r->log_error("No key 'destination' found in posted data");
        return SERVER_ERROR;
    } else {
        $r->log_error("'destination' in posted data = '$destination'") if $debug >= 1;
    }
    

    # Get the credentials from the data posted by the client, if any.

    my @credentials;

    while (exists $args{"credential_" . ($#credentials + 1)}) {

        $r->log_error("credential_" . ($#credentials + 1) . "= '" .
		    $args{"credential_" . ($#credentials + 1)} . "'") if $debug >= 2;

        push(@credentials, $args{"credential_" . ($#credentials + 1)});
    }


    # convert post to get
    
    if ($r->method eq 'POST') {
        $r->method('GET');
        $r->method_number(M_GET);
        $r->headers_in->unset('Content-Length');
    }

    $r->no_cache(1) unless $r->dir_config( $auth_name . 'Cache' );


    # Exchange the credentials for a session key.
    my ($ses_key, $error_message ) = $self->authen_cred($r, @credentials);

    # Would be nice if could somehow go back to original request yet pass info
    # from authen_cred about a failed authentication
    # two ideas: 1) return a session key that authen_ses_key can identify as invalid
    #            2) return a message and place that in a cookie



    # Get the uri so can adjust path, and to redirect including the query string
    my $uri = Apache::URI->parse($r, $destination );


    unless ( $ses_key ) {
        $r->log_error("No session returned from authen_cred" ) if $debug >= 2;

        # Pass a cookie with the error reason that can be read after the redirect.
        # Use a cookie with no time limit
        $self->send_cookie( name=>'Reason', value=>$error_message, expires=>undef ) if $error_message;

    } else {

        # Delete error message cookie, if found
        $self->send_cookie( value=>'none', name=>'Reason', expires=>'-1d' )
            if ($r->header_in( 'Cookie' ) || '') =~ /${auth_type}_${auth_name}Reason/;


        $r->log_error("ses_key returned from authen_cred = '$ses_key'" ) if $debug >= 2;


        # Send cookie if a session was returned from authen_cred
    
        $self->send_cookie(value=>$ses_key);



        # add the session to the URI - if trans handler not installed prefix will be empty

        if ( my $prefix = $r->notes('Session_Prefix') || '' ) {

            $uri->path( "/$prefix$ses_key" . $uri->path );
    
            # And save info for ErrorDocument handler
            $r->notes( SESSION => "/$prefix$ses_key" );
        }


    }



    # See if destination is a directory and add a slash (might as well save a redirect)
    
    if ( $uri->path !~ m[/$] && -d $r->lookup_uri( $destination )->filename ) {
        $r->log_error("Destination '$destination' is a directory: add slash before redirect") if $debug >= 3;

        $uri->path( $uri->path . '/' );
    }
    



    $r->log_error("login() Redirecting to " . $uri->unparse ) if $debug >= 2;


    $r->header_out( Location => $uri->unparse );
    return REDIRECT;
}



# Note -- should redirect without adding the session for URL-based logout?
# Might be smart to override this method so that the session can be marked as logged out
# in whatever database you are using

sub logout($$) {
  my ($self,$r) = @_;
  my $debug = $r->dir_config( DEBUG ) || 0;
  
  my ($auth_type, $auth_name) = ($r->auth_type, $r->auth_name);
  
  # Send the Set-Cookie header to expire the auth cookie.
  $self->send_cookie(value=>'none', expires=>'-1d');

  return FORBIDDEN;

  # This doesn't seem to work.

  $r->no_cache(1) unless $r->dir_config( $auth_name . 'Cache' );

  my $location = $r->dir_config( $auth_name . 'LogoutURI' ) || '/';

  $r->notes('SESSION', undef );  # so error doc doesn't fixup.

  $r->header_out( Location => $location );
  return REDIRECT;
}


sub authenticate ($$) {
    my ($auth_type, $r) = @_;
    my ($authen_script, $auth_user);



    my $debug = $r->dir_config( DEBUG ) || 0;
    $r->log_error( '** In authenticate **' ) if $debug >= 3;
    $r->log_error( "auth_type= '$auth_type'" ) if $debug >= 3;

    # This is a way to open up some documents/directories
    return OK if lc $r->auth_name eq 'none';
    return OK if $r->dir_config('DisableAuthCookieURL');


    # Only authenticate the first internal request
    return OK unless $r->is_initial_req;


    # How to solve the problem of protecting from the root downward yet allow access to login script?
    # Don't really want to set another PerlSetVar, so currently the action of the login script must
    # be '/LOGIN' if protecting from the root down.
    return OK if $r->uri =~ m[^/LOGIN];


    if ($r->auth_type ne $auth_type) {
        # This location requires authentication because we are being called,
        # but we don't handle this AuthType.
        $r->log_error("AuthType mismatch: $auth_type =/= ".$r->auth_type) if $debug >= 3;

        return DECLINED;
    }

    # Ok, the AuthType is $auth_type which we handle, what's the authentication
    # realm's name?

    my $auth_name = $r->auth_name;

    $r->log_error( "auth_name= '$auth_name'" ) if $debug >= 2;

    unless ($auth_name) {
        $r->log_reason("AuthName not set, AuthType=$auth_type", $r->uri);
        return SERVER_ERROR;
    }



    ## Check and get session from cookie or URL ##

    # Get the Cookie header. If there is a session key for this realm, strip
    # off everything but the value of the cookie.

    my ($ses_key_cookie) = ($r->header_in( 'Cookie' ) || "") =~ /${auth_type}_$auth_name=([^;]+)/;

    my $cookie = $ses_key_cookie || '';


    # Get session from URI if not set in a cookie
    $ses_key_cookie ||= $r->notes( 'URI_Session' ) || '';



    $r->log_error("session provided  = '$ses_key_cookie'" ) if $debug >= 1;
    $r->log_error("requested uri = '" . $r->uri . "'" ) if $debug >= 2;



    unless  ($ses_key_cookie) {
        $r->subprocess_env( AuthCookieURLReason => 'no_session_provided' );

    } else {

        # Check and convert the session key into a user
        
        if ($auth_user = $auth_type->authen_ses_key($r, $ses_key_cookie)) {

            # We have a valid session key, so we return with an OK value.
            # Tell the rest of Apache what the authentication method and
            # user is.

            $r->connection->auth_type($auth_type);
            $r->connection->user($auth_user);
            $r->log_error("user authenticated as $auth_user. Exiting Authen") if $debug >= 1;

            $r->log_error( "Cookie: '$cookie' and URI_Session: '" . ($r->notes( 'URI_Session' ) || '') ."'") if $debug >= 4; 

            # Clean up the path by redirecting if cookies are in use

            if ( $cookie && $r->notes( 'URI_Session' ) ) {

                my $query = $r->args ? '?' . $r->args : '';
                $query = $r->uri . $query;

                $r->log_error("Cookies are in use -- redirecting to '$query'") if $debug >= 3;

                # prevent the error_document from adding the session back in.
                $r->notes('SESSION', undef );

                $r->header_out( Location => $query );
                return REDIRECT;
            }

            return OK;

        } else {
            # There was a session key set, but it's invalid for some reason. So,
            # remove it from the client now so when the credential data is posted
            # we act just like it's a new session starting.

            # Do this even if no cookie was sent -- can't hurt.
            $auth_type->send_cookie( value=>'vanish', expires=>'-1d');
      

            $r->subprocess_env( AuthCookieURLReason => 'bad_session_provided' );
        }
    }


    # Invalid or no session was provided -- send to the login form


    # If the LoginScript is set to 'NONE' then only generating a session
    # So call login() directly instead of calling the login form.

    if ($r->dir_config($auth_name . 'LoginScript' ) &&
        $r->dir_config($auth_name . 'LoginScript' ) eq 'NONE' )
    {
        $r->log_error('LoginScript=NONE -- passing to login()' ) if $debug >= 2;

        # Call login script, passing the original URI

        my $query = $r->args ? '?' . $r->args : '';
        
        return $auth_type->login( $r, $r->uri . $query );
    }
        


    # They aren't authenticated, and they tried to get a protected
    # document.  Send them the authen form.
    return $auth_type->login_form;
}
  

sub login_form {  
    my $r = Apache->request or die "no request";
    my $auth_name = $r->auth_name;


    my $debug = $r->dir_config( DEBUG ) || 0;
    $r->log_error( "** In login_form **" ) if $debug >= 3;

    # There should be a PerlSetVar directive that gives us the URI of
    # the script to execute for the login form.
  
    my $authen_script;

    unless ($authen_script = $r->dir_config($auth_name . 'LoginScript' )) {
        $r->log_reason("PerlSetVar '${auth_name}LoginScript' not set", $r->uri);
        return SERVER_ERROR;
    }

    $r->log_error("Internally redirecting to $authen_script") if $debug >= 3;
    
    $r->custom_response(FORBIDDEN, $authen_script);
  
    return FORBIDDEN;
}



sub authorize ($$) {
    my ($auth_type, $r) = @_;
    my $debug = $r->dir_config( DEBUG ) || 0;

    $r->log_error( "** In authorize **" ) if $debug >= 3;

    # This is a way to open up some documents/directories
    return OK if lc $r->auth_name eq 'none';
    return OK if $r->dir_config('DisableAuthCookieURL');


    return OK unless $r->is_initial_req; #only the first internal request

    # How to solve the problem of protecting from the root downward?
    # Don't really want to set another PerlSetVar.
    return OK if $r->uri =~ m[^/LOGIN];

  
    if ($r->auth_type ne $auth_type) {
        $r->log_error($auth_type . " auth type is " . $r->auth_type) if $debug >= 3;
        return DECLINED;
    }
  
    my $reqs_arr = $r->requires or return DECLINED;
  
    my $user = $r->connection->user;

    unless ($user) {
        # user is either undef or =0 which means the authentication failed
        $r->log_reason("No user authenticated", $r->uri);
        return FORBIDDEN;
    }
  
    my ($forbidden);

    foreach my $req (@$reqs_arr) {
        my ($requirement, $args) = split /\s+/, $req->{requirement}, 2;
        $args = '' unless defined $args;
        $r->log_error("requirement := $requirement, $args") if $debug >= 2;
    
        next if $requirement eq 'valid-user';

        if($requirement eq 'user') {
            next if $args =~ m/\b$user\b/;
            $forbidden = 1;
            next;
        }

        # Call a custom method
        my $ret_val = $auth_type->$requirement($r, $args);
        $r->log_error("$auth_type->$requirement returned $ret_val") if $debug >= 3;
        next if $ret_val == OK;

        # Nothing succeeded, deny access to this user.
        $forbidden = 1;
        last;
    }


    return $forbidden ? FORBIDDEN : OK;
}

sub send_cookie {
    my ($self, %settings ) = @_;
    my $r = Apache->request();

    my ( $auth_name, $auth_type ) = ( $r->auth_name, $r->auth_type );

    return if $r->dir_config( $auth_name . 'NoCookie' );

    $settings{name} = $settings{name}
                      ? "${auth_type}_$auth_name$settings{name}"
                      : "${auth_type}_$auth_name";


    for (qw/Path Expires Domain Secure/) {
        next if exists $settings{ lc() };
        
        if (my $value = $r->dir_config( $auth_name . $_ )) {
            $settings{ lc() } = $value;
        }
    }

    # Remove any undef settings
    my @deletes = grep { ! defined $settings{$_} } keys %settings;
    delete $settings{$_} for @deletes;

    $settings{path} ||= '/';  # need to do this so will return cookie when url is munged.

    my $cookie = Apache::Cookie->new( $r, %settings );
    $cookie->bake;

    my $debug = $r->dir_config( DEBUG ) || 0;
    $r->log_error('Send cookie: ' . $cookie->as_string ) if $debug >= 3;

    
}

sub key {
    my $self = shift;
    my $r = Apache->request;
    
    my ( $auth_name, $auth_type ) = ( $r->auth_name, $r->auth_type );
    my ( $ses_key_cookie ) = ($r->header_in( 'Cookie' ) || '') =~ /${auth_type}_$auth_name=([^;]+)/;

    return $ses_key_cookie || $r->notes( 'URI_Session' ) || undef;
}

1;

__END__

=head1 NAME

Apache::AuthCookieURL - Perl Authentication and Authorization
or session management via cookies or URL munging

=head1 SYNOPSIS

In httpd.conf

    # Your module that overrides AuthCookieURL methods
    PerlModule My::AuthCookieURLHandler

    # Or to use simple session generation w/o persistence
    #PerlModule Apache::AuthCookieURL

    ## Some settings -- "Whatever" is set by AuthName ##
    # most can be set within <directory> sections

    # Send expires with cookie
    PerlSetVar WhateverExpires +90d

    # Other cookie settings
    #PerlSetVar WhateverDomain some.domain

    # This can only be set to "/" if using URL sessions
    #PerlSetVar WhateverPath /path
    #PerlSetVar WhateverSecure 1


    # Login script to call
    PerlSetVar WhateverLoginScript /login.pl

    # Or for just session management without a login script
    #PerlSetVar WhateverLoginScript NONE

    # Debugging options
    #PerlSetVar AuthCookieURLDebug 5

    # Disable cookies (only URL based sessions)
    #PerlSetVar WhateverNoCookie 1

    # Define a string that indicates to AuthCookieURL
    # what a session looks like
    # This can only be in main config
    #PerlSetVar SessionPrefix Session-


    # This block enables URL session handling
    PerlTransHandler  Apache::AuthCookieURLHandler->URLsession

    ErrorDocument 302 /MISSING
    ErrorDocument 301 /MISSING
    <Location /MISSING>
        SetHandler perl-script
        PerlHandler Apache::AuthCookieURLHandler->error_document
    </Location>



    <Location /protected>
        AuthType Apache::AuthCookieURLHandler
        AuthName Whatever
        PerlAuthenHandler Apache::AuthCookieURLHandler->authenticate
        PerlAuthzHandler Apache::AuthCookieURLHandler->authorize
        require valid-user
    </Location>


    # provide open access to some areas below
    <Location /protected/open>
        PerlSetVar DisableAuthCookieURL 1
    </Location>

    # or if the entire directory tree was protected
    <Location /images>
        PerlSetVar DisableAuthCookieURL 1
    </Location>


    # Make sure the login script can be run
    <Files login.pl>
         Options +ExecCGI
         SetHandler perl-script
         PerlHandler Apache::Registry
    </Files>

    # LOGIN is the action defined by the login.pl script

    <Files LOGIN>
         AuthType Apache::AuthCookieURLHandler
         AuthName Whatever
         SetHandler perl-script
         PerlHandler Apache::AuthCookieURLHandler->login
    </Files>

    # Note: If protecting the entire web site (from root down) then
    # the action *must* be C</LOGIN> as the module looks for this string.

    # better to just invalidate the session, of course
    <Files LOGOUT>
         AuthType Apache::AuthCookieURLHandler
         PerlSetVar WhateverLogoutURI /
         AuthName Whatever
         SetHandler perl-script
         PerlHandler Apache::AuthCookieURLHandler->logout
    </Files>

=head1 DESCRIPTION

** Warning: beta software.  This should be used for testing purposes only.
That said, there are a few people using it and I've been using it for a
few months without problem.  The interface may change (or disappear) without notice.
Please report any problems or comments back to Bill Moseley E<lt>moseley@hank.orgE<gt>.

This module is a modification of Ken Williams E<lt>ken@forum.swarthmore.eduE<gt> Apache::AuthCookie.
Please see perldoc Apache::AuthCookie for complete instructions.  As this is intended to be
a drop-in replacement for Apache::AuthCookie you may wish to install and test with Ken's
Apache::AuthCookie before trying AuthCookieURL.

Basically, this module allows you to catch any unauthenticated access and redirect to a
login script that you define.  The login script posts credentials (e.g. username and password)
and your module can then validate and provide a session key.  The session key is sent in a cookie,
and also in a munged URL and a redirect is issued and the process starts all over.

Typically, you will write your own module that will override methods in Apache::AuthCookieURL.
These methods are described completely in Ken's Apache::AuthCookie.  Your methods will be used
to generate and validate session keys.  You can use Apache::AuthCookieURL without overriding
its methods and then AuthCookieURL can be used as a simple session manager.

With this module you should be able to enable session management for an entire site
using E<lt>Location /E<gt>, and then allow access to, say, the images directory, and also require
password access to other locations.  One issue at this point is that the session key is
stripped from URLs in a Trans handler.  So you would need to use cookies to use different
session keys for different parts of your web tree.

Apache::AuthCookieURL adds the following features to Apache::AuthCookie.

=over 4

=item * URL munging

If the PerlTransHandler is enabled in httpd.conf the session key will also be placed in the URL.
The session will be removed from the URL if cookies are enabled
on the next request.  Typically, someone visiting your site with cookies enabled
will never see the munged URL.

To make URL sessions work you must use relative links in your documents so the client/browser
knows to place the session key on all links.  CGI scripts can also access the session
information via the environment.

=item * Simple Session Management

If the login script is set to `NONE' with PerlSetVar WhateverLoginScript NONE then
Apache::AuthCookeURL acts like a simple session manager:  your module will provide a new
session key if one is not provided with the request, or if the one provided is invalid.

=item * Really Simple Session Management

Apache::AuthCookieURL provides default authen_cred() and authen_ses_key() methods that
generates a (questionably) random session key.  This means you can use AuthCookieURL
directly without subclassing for really simple session management without any persistence of
session keys.

=back


Unless you are not subclassing this module (and using the default methods provide),
your own module must define two methods: authen_cred() and authen_ses_key(), and then
subclass by including Apache::AuthCookieURL in your module's @ISA array.
Again, please see Apache::AuthCookie for
complete documentation.

=over 4

=item * authen_cred()

This method verifies the credentials (e.g. username/password) and returns a session key.  If the credentials are
not acceptable then you can return a list, with the second element being an error message
that is placed in a cookie.  This allows your login script to display a failure reason.  This
method is needed since a redirect is done before your login script is executed again.  Of course,
this requires that the client has cookies enabled.

Another method is to return a session key that is really an error code and generate
messages based on that returned session (error) code.

=item * authen_ses_key()

This method's job is to validate and convert a session key into a username and return it.
AuthCookieURL places the returned value into $ENV{REMOTE_USER}.

=back

=head1 CONFIGURATION SETTINGS

Configuration settings are set with the PerlSetVar directive:

    PerlSetVar WhateverExpires +90d

"Whatever" is whatever the current AuthName is set.  I think I might remove this
and instead just use the settings as Apache dir_merge returns them.  In other words,
if you want a setting to override a global setting, then use it within a E<lt>directoryE<gt>,
E<lt>fileE<gt>, or E<lt>locationE<gt> section.

=over 4

=item * AuthCookieURLDebug

Sets the debugging level.  Since some debugging info is generated in the Trans
handler this needs to be set in the main httpd config.  Default is 0.

Example: PerlSetVar AuthCookieURLDebug 5

=item * SessionPrefix

SessionPrefix sets the prefix used by the Trans handler to recognize the session
in the URL (thus needs to be set in the main config), and to create the session ID.
Default is 'Session-'.

Example: PerlSetVar SessionPrefix ID-

=item * WhateverCache

UNLESS set then $r-E<gt>no_cache(1) will be called when processing the login and logout requests.
Defaults to unset and thus $r-E<gt>no_cache(1) IS called.

Example: PerlSetVar WhateverCache 1

=item * WhateverLogoutURI

Sets where you are redirected after requesting the logout URL (see SYNOPSIS).
Defaults to '/'.  

Example: PerlSetVar WhateverLogoutURI /gone.html

=item * DisableAuthCookieURL

This causes the Authen and Authz handlers to return OK.  In other words,

    <Location /protected/notprotected>
        PerlSetVar DisableAuthCookieURL 1
    </Location>

Allows full access to the notprotected directory.


=item * WhateverLoginScript

This sets the Login script to be executed when authorization is
required (no valid session key was sent by cookie or URL).  This login script can be a
CGI script, Apache::Registry script, or a mod_perl handler.

If set to `NONE' then AuthCookieURL will be in simple session management mode.
AuthCookieURL-E<gt>login will be called which calls authen_cred() to generate a session key.
authen_cred() should just return a session key without checking the credentials.

If you do not override AuthCookieURL::authen_cred(), then AuthCookieURL::authen_cred()
simply returns this for a session key.

    return time . $$ . int rand $$;

Example: PerlSetVar WhateverLoginScript /login.pl
         PerlSetVar WhateverLoginScript NONE

=item * WhateverNoCookie

Turns off cookies.

Example: PerlSetVar WhateverNoCookie 1

=item * Whatever(Path|Expires|Domain|Secure)

These all control the values sent in cookies.  Path, if used, must be '/' if
using URL-based sessions.

Example: PerlSetVar WhateverPath /


=back

=head1 ENVIRONMENT AND NOTES

Apache::AuthCookieURL sets some environment variables and Apache notes:

authen_ses_key() returns a value that is placed in $ENV{REMOTE_USER}.  authen_ses_key()
normally converts the session key into a username.

$ENV{SESSION} contains the current session key

$ENV{AuthCookieURLReason} contains the reason authentication failed.  Either
'no_session_provided' or 'bad_session_provided'.

$r-E<gt>notes( 'URI_Session' ) is the session extracted from the URI

$r-E<gt>notes('Session_prefix') is the prefix used with the session keys, of course.

$r-E<gt>notes( 'SESSION' ) is the full session, including the prefix.



=head1 WARNING

URL munging has security issues.  Session keys can get written to access logs, cached by
browsers, leak outside your site, and are broken if your pages use absolute links to other
pages on-site.

=head1 TO DO

Apache::AuthCookieURL uses error documents to try to fixup any redirects.  The obvious
example is when a request is made for a directory without a trailing slash and Apache
issues a redirect.  (Actually, AuthCookieURL tries to detect this case and rewrite the URL
before Apache redirects.)  I wish I knew a better way to fixup Location: headers in
redirects without sub-requesting every request.  There's no way to catch a CGI script
or module that might issue a Location: header or REDIRECT.
I guess that's left for Apache 2.0 when all output can be filtered.

=head1 REQUIRED

mod_perl 1.24, Apache::Cookie


=head1 AUTHOR

Bill Moseley E<lt>moseley@hank.orgE<gt> made minor changes to Ken Williams' E<lt>ken@forum.swarthmore.eduE<gt>
Apache::AuthCookie.

Thanks very much to Ken for Apache::AuthCookie.

=head1 VERSION

    $Revision: 1.3 $

=head1 SEE ALSO

L<Apache::AuthCookie>

=cut
