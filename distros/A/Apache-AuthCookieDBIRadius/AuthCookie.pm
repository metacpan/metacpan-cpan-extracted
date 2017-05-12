package Apache::AuthCookie;

use strict;

use Carp;
use CGI::Util ();
use mod_perl qw(1.07 StackedHandlers MethodHandlers Authen Authz);
use Apache::Constants qw(:common M_GET M_POST FORBIDDEN REDIRECT);
use vars qw($VERSION);

# $Id: AuthCookie.pm,v 2.16 2001/06/01 15:50:27 mschout Exp $
$VERSION = '3.00';

sub recognize_user ($$) {
  my ($self, $r) = @_;
  my $debug = $r->dir_config("AuthCookieDebug") || 0;
  my ($auth_type, $auth_name) = ($r->auth_type, $r->auth_name);
  return unless $auth_type && $auth_name;
  return unless $r->header_in('Cookie');

  my ($cookie) = $r->header_in('Cookie') =~ /${auth_type}_${auth_name}=([^;]+)/;
  $r->log_error("cookie ${auth_type}_${auth_name} is $cookie") if $debug >= 2;
  return unless $cookie;

  if (my ($user) = $auth_type->authen_ses_key($r, $cookie)) {
    $r->log_error("user is $user") if $debug >= 2;
    $r->connection->user($user);
  }
  return OK;
}


sub login ($$) {
  my ($self, $r) = @_;
  my $debug = $r->dir_config("AuthCookieDebug") || 0;

  my ($auth_type, $auth_name) = ($r->auth_type, $r->auth_name);
  my %args = $r->method eq 'POST' ? $r->content : $r->args;
  unless (exists $args{'destination'}) {
    $r->log_error("No key 'destination' found in posted data");
    return SERVER_ERROR;
  }
  
  # Get the credentials from the data posted by the client
  my @credentials;
  while (exists $args{"credential_" . ($#credentials + 1)}) {
    $r->log_error("credential_" . ($#credentials + 1) . " " .
		  $args{"credential_" . ($#credentials + 1)}) if ($debug >= 2);
    push(@credentials, $args{"credential_" . ($#credentials + 1)});
  }
  
  # Exchange the credentials for a session key.
  my $ses_key = $self->authen_cred($r, @credentials);
  $r->log_error("ses_key " . $ses_key) if ($debug >= 2);

  $self->send_cookie($ses_key);

  if ($r->method eq 'POST') {
    $r->method('GET');
    $r->method_number(M_GET);
    $r->headers_in->unset('Content-Length');
  }
  unless ($r->dir_config("${auth_name}Cache")) {
    $r->no_cache(1);
    $r->err_header_out("Pragma" => "no-cache");
  }
  $r->header_out("Location" => $args{'destination'});
  return REDIRECT;
}

sub logout($$) {
  my ($self,$r) = @_;
  my $debug = $r->dir_config("AuthCookieDebug") || 0;
  
  my ($auth_type, $auth_name) = ($r->auth_type, $r->auth_name);
  
  # Send the Set-Cookie header to expire the auth cookie.
  my $str = $self->cookie_string( request => $r,
											 key     => "$auth_type\_$auth_name",
								          value 	=> '',
											 expires => 'Mon, 21-May-1971 00:00:00 GMT' );
  $r->err_headers_out->add("Set-Cookie" => "$str");
  $r->log_error("set_cookie " . $r->err_header_out("Set-Cookie")) if $debug >= 2;
  unless ($r->dir_config("${auth_name}Cache")) {
    $r->no_cache(1);
    $r->err_header_out("Pragma" => "no-cache");
  }

  #my %args = $r->args;
  #if (exists $args{'redirect'}) {
  #  $r->err_header_out("Location" => $args{'redirect'});
  #  return REDIRECT;
  #} else {
  #  $r->status(200);
  #  return OK;
  #}
}

sub authenticate ($$) {
  my ($auth_type, $r) = @_;
  my ($authen_script, $auth_user);
  my $debug = $r->dir_config("AuthCookieDebug") || 0;
  
  $r->log_error("auth_type " . $auth_type) if ($debug >= 3);
  return OK unless $r->is_initial_req; # Only authenticate the first internal request
  
  if ($r->auth_type ne $auth_type) {
    # This location requires authentication because we are being called,
    # but we don't handle this AuthType.
    $r->log_error("AuthType mismatch: $auth_type =/= ".$r->auth_type) if $debug >= 3;
    return DECLINED;
  }

  # Ok, the AuthType is $auth_type which we handle, what's the authentication
  # realm's name?
  my $auth_name = $r->auth_name;
  $r->log_error("auth_name " . $auth_name) if $debug >= 2;
  unless ($auth_name) {
    $r->log_reason("AuthName not set, AuthType=$auth_type", $r->uri);
    return SERVER_ERROR;
  }

  # Get the Cookie header. If there is a session key for this realm, strip
  # off everything but the value of the cookie.
  my ($ses_key_cookie) = ($r->header_in("Cookie") || "") =~ /$auth_type\_$auth_name=([^;]+)/;
  $ses_key_cookie = "" unless defined($ses_key_cookie);

  $r->log_error("ses_key_cookie " . $ses_key_cookie) if ($debug >= 1);
  $r->log_error("uri " . $r->uri) if ($debug >= 2);

  if ($ses_key_cookie) {
    if ($auth_user = $auth_type->authen_ses_key($r, $ses_key_cookie)) {
      # We have a valid session key, so we return with an OK value.
      # Tell the rest of Apache what the authentication method and
      # user is.

      $r->connection->auth_type($auth_type);
      $r->connection->user($auth_user);
      $r->log_error("user authenticated as $auth_user")	if $debug >= 1;
	
		# Returning $TICKET to the environment so you can customize webpages
		# Based on authentication level.
		$r->subprocess_env('TICKET', $ses_key_cookie);

      return OK;
    } else {
      # There was a session key set, but it's invalid for some reason. So,
      # remove it from the client now so when the credential data is posted
      # we act just like it's a new session starting.
      
      my $str = $auth_type->cookie_string(
		  request => $r,
		  key     => "$auth_type\_$auth_name",
		  value   => '',
		  expires => 'Mon, 21-May-1971 00:00:00 GMT'
		);
      $r->err_headers_out->add("Set-Cookie" => "$str");
      $r->log_error("set_cookie " . $r->err_header_out("Set-Cookie")) if $debug >= 2;
		#$r->subprocess_env('AuthCookieReason', 'Bad Cookie');

		# Instead of 'Bad Cookie', lets return something more useful.
		# $ses_key_cookie has a unique value if ERROR, but undef if ! ERROR.
      $r->subprocess_env('AuthCookieReason', $ses_key_cookie) if $ses_key_cookie =~ /ERROR/;
		$r->subprocess_env('AuthCookieReason', 'ERROR! Your session has expired, or your login does not have the proper access level for this webpage.') if $ses_key_cookie !~ /ERROR/;
    }
  } else {
	 #$r->subprocess_env('AuthCookieReason', 'no_cookie');

	 # Instead of 'no_cookie, let's return something more useful.
    $r->subprocess_env('AuthCookieReason', 'Please enter your user name and password.');
  }

  # They aren't authenticated, and they tried to get a protected
  # document.  Send them the authen form.
  return $auth_type->login_form;
}
  

sub login_form {  
  my $r = Apache->request or die "no request";
  my $auth_name = $r->auth_name;

  # There should be a PerlSetVar directive that gives us the URI of
  # the script to execute for the login form.
  
  my $authen_script;
  unless ($authen_script = $r->dir_config($auth_name . "LoginScript")) {
    $r->log_reason("PerlSetVar '${auth_name}LoginScript' not set", $r->uri);
    return SERVER_ERROR;
  }
  #$r->log_error("Redirecting to $authen_script");
  $r->custom_response(FORBIDDEN, $authen_script);
  
  return FORBIDDEN;
}

sub authorize ($$) {
  my ($auth_type, $r) = @_;
  my $debug = $r->dir_config("AuthCookieDebug") || 0;
  
  return OK unless $r->is_initial_req; #only the first internal request
  
  if ($r->auth_type ne $auth_type) {
    $r->log_error($auth_type . " auth type is " .
		  $r->auth_type) if ($debug >= 3);
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
   #return $forbidden ? FORBIDDEN : OK;

   # Was returning generic Apache FORBIDDEN here.  We want to return to login.pl with error message.
   $r->subprocess_env('AuthCookieReason', 'ERROR! Your login does not have the proper permission for this webpage.') if $forbidden;
 	$r->log_error("AuthCookie, ERROR! Login not in list for this directory using require user ...") if $forbidden;
   return $auth_type->login_form if $forbidden;

   return OK;
}

sub send_cookie {
  my ($self, $ses_key) = @_;
  my $r = Apache->request();

  my ($auth_type, $auth_name) = ($r->auth_type, $r->auth_name);
  my $cookie = $self->cookie_string( request => $r, 
											    key     => "$auth_type\_$auth_name", 
												 value   => $ses_key );
  $r->err_header_out("Set-Cookie" => $cookie);
}

sub cookie_string {
  my $self = shift;

  # if passed 3 args, we have old-style call.
  if (scalar(@_) == 3) {
    carp "deprecated old style call to ".__PACKAGE__."::cookie_string()";
    my ($r, $key, $value) = @_;
    return $self->cookie_string(request=>$r, key=>$key, value=>$value);
  }
  # otherwise assume named parameters.
  my %p = @_;
  for (qw/request key/) {
    croak "missing required parameter $_" unless defined $p{$_};
  }
  # its okay if value is undef here.

  my $r = $p{request};

  my $string = sprintf '%s=%s', @p{'key','value'};

  my $auth_name = $r->auth_name;

  if (my $expires = $p{expires} || $r->dir_config("${auth_name}Expires")) {
    $expires = CGI::Util::expires($expires);
    $string .= "; expires=$expires";
  }

  if (my $path = $r->dir_config("${auth_name}Path")) {
    $string .= "; path=$path";
  }
  #$r->log_error("Attribute ${auth_name}Path not set") unless $path;

  if (my $domain = $r->dir_config("${auth_name}Domain")) {
    $string .= "; domain=$domain";
  }

  $string .= '; secure' if $r->dir_config("${auth_name}Secure");

  return $string;
}

sub key {
  my $self = shift;
  my $r = Apache->request;

  my $allcook = ($r->header_in("Cookie") || "");
  my ($type, $name) = ($r->auth_type, $r->auth_name);
  return ($allcook =~ /(?:^|\s)${type}_$name=([^;]*)/)[0];
}

1;

__END__

=head1 NAME

Apache::AuthCookie - Perl Authentication and Authorization via cookies

=head1 SYNOPSIS

Make sure your mod_perl is at least 1.24, with StackedHandlers,
MethodHandlers, Authen, and Authz compiled in.

 # In httpd.conf or .htaccess:
 PerlModule Sample::AuthCookieHandler
 PerlSetVar WhatEverPath /
 PerlSetVar WhatEverLoginScript /login.pl
 
 # The following line is optional - it allows you to set the domain
 # scope of your cookie.  Default is the current domain.
 PerlSetVar WhatEverDomain .yourdomain.com

 # Use this to only send over a secure connection
 PerlSetVar WhatEverSecure 1

 # Usually documents are uncached - turn off here
 PerlSetVar WhatEverCache 1

 # Use this to make your cookies persistent (+2 hours here)
 PerlSetVar WhatEverExpires +2h

 # These documents require user to be logged in.
 <Location /protected>
  AuthType Sample::AuthCookieHandler
  AuthName WhatEver
  PerlAuthenHandler Sample::AuthCookieHandler->authenticate
  PerlAuthzHandler Sample::AuthCookieHandler->authorize
  require valid-user
 </Location>

 # These documents don't require logging in, but allow it.
 <FilesMatch "\.ok$">
  AuthType Sample::AuthCookieHandler
  AuthName WhatEver
  PerlFixupHandler Sample::AuthCookieHandler->recognize_user
 </FilesMatch>

 # This is the action of the login.pl script above.
 <Files LOGIN>
  AuthType Sample::AuthCookieHandler
  AuthName WhatEver
  SetHandler perl-script
  PerlHandler Sample::AuthCookieHandler->login
 </Files>

=head1 DESCRIPTION

B<Apache::AuthCookie> allows you to intercept a user's first
unauthenticated access to a protected document. The user will be
presented with a custom form where they can enter authentication
credentials. The credentials are posted to the server where AuthCookie
verifies them and returns a session key.

The session key is returned to the user's browser as a cookie. As a
cookie, the browser will pass the session key on every subsequent
accesses. AuthCookie will verify the session key and re-authenticate
the user.

All you have to do is write a custom module that inherits from
AuthCookie.  Your module is a class which implements two methods:

=over 4

=item C<authen_cred()>

Verify the user-supplied credentials and return a session key.  The
session key can be any string - often you'll use some string
containing username, timeout info, and any other information you need
to determine access to documents, and append a one-way hash of those
values together with some secret key.

=item C<authen_ses_key()>

Verify the session key (previously generated by C<authen_cred()>,
possibly during a previous request) and return the user ID.  This user
ID will be fed to C<$r-E<gt>connection-E<gt>user()> to set Apache's
idea of who's logged in.

=back

By using AuthCookie versus Apache's built-in AuthBasic you can design
your own authentication system.  There are several benefits.

=over 4

=item 1.

The client doesn't *have* to pass the user credentials on every
subsequent access.  If you're using passwords, this means that the
password can be sent on the first request only, and subsequent
requests don't need to send this (potentially sensitive) information.
This is known as "ticket-based" authentication.

=item 2.

When you determine that the client should stop using the
credentials/session key, the server can tell the client to delete the
cookie.  Letting users "log out" is a notoriously impossible-to-solve
problem of AuthBasic.

=item 3.

AuthBasic dialog boxes are ugly.  You can design your own HTML login
forms when you use AuthCookie.

=item 4.

You can specify the domain of a cookie using PerlSetVar commands.  For
instance, if your AuthName is C<WhatEver>, you can put the command 

 PerlSetVar WhatEverDomain .yourhost.com

into your server setup file and your access cookies will span all
hosts ending in C<.yourhost.com>.

=back

This is the flow of the authentication handler, less the details of the
redirects. Two REDIRECT's are used to keep the client from displaying
the user's credentials in the Location field. They don't really change
AuthCookie's model, but they do add another round-trip request to the
client.

=for html
<PRE>

 (-----------------------)     +---------------------------------+
 ( Request a protected   )     | AuthCookie sets custom error    |
 ( page, but user hasn't )---->| document and returns            |
 ( authenticated (no     )     | FORBIDDEN. Apache abandons      |      
 ( session key cookie)   )     | current request and creates sub |      
 (-----------------------)     | request for the error document. |<-+
                               | Error document is a script that |  |
                               | generates a form where the user |  |
                 return        | enters authentication           |  |
          ^------------------->| credentials (login & password). |  |
         / \      False        +---------------------------------+  |
        /   \                                   |                   |
       /     \                                  |                   |
      /       \                                 V                   |
     /         \               +---------------------------------+  |
    /   Pass    \              | User's client submits this form |  |
   /   user's    \             | to the LOGIN URL, which calls   |  |
   | credentials |<------------| AuthCookie->login().            |  |
   \     to      /             +---------------------------------+  |
    \authen_cred/                                                   |
     \ function/                                                    |
      \       /                                                     |
       \     /                                                      |
        \   /            +------------------------------------+     |
         \ /   return    | Authen cred returns a session      |  +--+
          V------------->| key which is opaque to AuthCookie.*|  |
                True     +------------------------------------+  |
                                              |                  |
               +--------------------+         |      +---------------+
               |                    |         |      | If we had a   |
               V                    |         V      | cookie, add   |
  +----------------------------+  r |         ^      | a Set-Cookie  |
  | If we didn't have a session|  e |T       / \     | header to     |
  | key cookie, add a          |  t |r      /   \    | override the  |
  | Set-Cookie header with this|  u |u     /     \   | invalid cookie|
  | session key. Client then   |  r |e    /       \  +---------------+
  | returns session key with   |  n |    /  pass   \               ^    
  | sucsesive requests         |    |   /  session  \              |    
  +----------------------------+    |  /   key to    \    return   |
               |                    +-| authen_ses_key|------------+
               V                       \             /     False
  +-----------------------------------+ \           /
  | Tell Apache to set Expires header,|  \         /
  | set user to user ID returned by   |   \       /
  | authen_ses_key, set authentication|    \     /
  | to our type (e.g. AuthCookie).    |     \   /
  +-----------------------------------+      \ /
                                              V
         (---------------------)              ^
         ( Request a protected )              |
         ( page, user has a    )--------------+
         ( session key cookie  )
         (---------------------)


 *  The session key that the client gets can be anything you want.  For
    example, encrypted information about the user, a hash of the
    username and password (similar in function to Digest
    authentication), or the user name and password in plain text
    (similar in function to HTTP Basic authentication).

    The only requirement is that the authen_ses_key function that you
    create must be able to determine if this session_key is valid and
    map it back to the originally authenticated user ID.

=for html
</PRE>

=head1 METHODS

C<Apache::AuthCookie> has several methods you should know about.  Here
is the documentation for each. =)

=over 4

=item * authenticate()

This method is one you'll use in a server config file (httpd.conf,
.htaccess, ...) as a PerlAuthenHandler.  If the user provided a
session key in a cookie, the C<authen_ses_key()> method will get
called to check whether the key is valid.  If not, or if there is no
key provided, we redirect to the login form.

=item * authorize()

This will step through the C<require> directives you've given for
protected documents and make sure the user passes muster.  The
C<require valid-user> and C<require user joey-jojo> directives are
handled for you.  You can implement custom directives, such as
C<require species hamster>, by defining a method called C<hamster()>
in your subclass, which will then be called.  The method will be
called as C<$r-E<gt>hamster($r, $args)>, where C<$args> is everything
on your C<require> line after the word C<hamster>.  The method should
return OK on success and FORBIDDEN on failure.

Currently users must satisfy ALL of the C<require> directives.  I have
heard that other Apache modules let the user satisfy ANY of the
C<require> directives.  I don't know which is correct, I haven't found
any Apache docs on the matter.  If you need one behavior or the other,
be careful.  I may change it if I discover that ANY is correct.

=item * authen_cred()

You must define this method yourself in your subclass of
C<Apache::AuthCookie>.  Its job is to create the session key that will
be preserved in the user's cookie.  The arguments passed to it are:

 sub authen_cred ($$\@) {
   my $self = shift;  # Package name (same as AuthName directive)
   my $r    = shift;  # Apache request object
   my @cred = @_;     # Credentials from login form

   ...blah blah blah, create a session key...
   return $session_key;
 }

The only limitation on the session key is that you should be able to
look at it later and determine the user's username.  You are
responsible for implementing your own session key format.  A typical
format is to make a string that contains the username, an expiration
time, whatever else you need, and an MD5 hash of all that data
together with a secret key.  The hash will ensure that the user
doesn't tamper with the session key.  More info in the Eagle book.

=item * authen_ses_key()

You must define this method yourself in your subclass of
Apache::AuthCookie.  Its job is to look at a session key and determine
whether it is valid.  If so, it returns the username of the
authenticated user.

 sub authen_ses_key ($$$) {
   my ($self, $r, $session_key) = @_;
   ...blah blah blah, check whether $session_key is valid...
   return $ok ? $username : undef;
 }

=item * login()

This method handles the submission of the login form.  It will call
the C<authen_cred()> method, passing it C<$r> and all the submitted
data with names like C<"credential_#">, where # is a number.  These will
be passed in a simple array, so the prototype is
C<$self-E<gt>authen_cred($r, @credentials)>.  After calling
C<authen_cred()>, we set the user's cookie and redirect to the
URL contained in the C<"destination"> submitted form field.

=item * login_form()

This method is responsible for displaying the login form. The default
implementation will make an internal redirect and display the URL you
specified with the C<PerlSetVar WhatEverLoginForm> configuration
directive. You can overwrite this method to provide your own
mechanism.

=item * logout()

This is simply a convenience method that unsets the session key for
you.  You can call it in your logout scripts.  Usually this looks like
C<$r-E<gt>auth_type-E<gt>logout($r);>.

=item * send_cookie($session_key)

By default this method simply sends out the session key you give it.
If you need to change the default behavior (perhaps to update a
timestamp in the key) you can override this method.

=item * recognize_user()

If the user has provided a valid session key but the document isn't
protected, this method will set C<$r-E<gt>connection-E<gt>user>
anyway.  Use it as a PerlFixupHandler, unless you have a better idea.

=item * key()

This method will return the current session key, if any.  This can be
handy inside a method that implements a C<require> directive check
(like the C<species> method discussed above) if you put any extra
information like clearances or whatever into the session key.

=back

=head1 UPGRADING FROM VERSION 1.4

There are a few interface changes that you need to be aware of
when migrating from version 1.x to 2.x.  First, the authen() and
authz() methods are now deprecated, replaced by the new authenticate()
and authorize() methods.  The old methods will go away in a couple
versions, but are maintained intact in this version to ease the task
of upgrading.  The use of these methods is essentially the same, though.

Second, when you change to the new method names (see previous
paragraph), you must change the action of your login forms to the
location /LOGIN (or whatever URL will call your module's login()
method).  You may also want to change their METHOD to POST instead of
GET, since that's much safer and nicer to look at (but you can leave
it as GET if you bloody well want to, for some god-unknown reason).

Third, you must change your login forms (see L<THE LOGIN SCRIPT>
below) to indicate how requests should be redirected after a
successful login.

Fourth, you might want to take advantage of the new C<logout()>
method, though you certainly don't have to.

=head1 EXAMPLE

For an example of how to use Apache::AuthCookie, you may want to check
out the test suite, which runs AuthCookie through a few of its paces.
The documents are located in t/eg/, and you may want to peruse
t/real.t to see the generated httpd.conf file (at the bottom of
real.t) and check out what requests it's making of the server (at the
top of real.t).

=head1 THE LOGIN SCRIPT

You will need to create a login script (called login.pl above) that
generates an HTML form for the user to fill out.  You might generate
the page using an Apache::Registry script, or an HTML::Mason
component, or perhaps even using a static HTML page.  It's usually
useful to generate it dynamically so that you can define the
'destination' field correctly (see below).

The following fields must be present in the form:

=over 4

=item 1.

The ACTION of the form must be /LOGIN (or whatever you defined in your
server configuration as handled by the ->login() method - see example
in the SYNOPSIS section).

=item 2.

The various user input fields (username, passwords, etc.) must be
named 'credential_0', 'credential_1', etc. on the form.  These will
get passed to your authen_cred() method.

=item 3.

You must define a form field called 'destination' that tells
AuthCookie where to redirect the request after successfully logging
in.  Typically this value is obtained from C<$r-E<gt>prev-E<gt>uri>.
See the login.pl script in t/eg/.

=back

In addition, you might want your login page to be able to tell the
difference between a user that sent an incorrect auth cookie, and a
user that sent no auth cookie at all.  These typically correspond,
respectively, to users who logged in incorrectly or aren't allowed to
access the given page, and users who are trying to log in for the
first time.  To help you differentiate between the two, B<AuthCookie>
will set C<$r-E<gt>subprocess_env('AuthCookieReason')> to either
C<bad_cookie> or C<no_cookie>.  You can examine this value in your
login form by examining
C<$r-E<gt>prev-E<gt>subprocess_env('AuthCookieReason')> (because it's
a sub-request).

Of course, if you want to give more specific information about why
access failed when a cookie is present, your C<authen_ses_key()>
method can set arbitrary entries in C<$r-E<gt>subprocess_env>.

=head1 THE LOGOUT SCRIPT

If you want to let users log themselves out (something that can't be
done using Basic Auth), you need to create a logout script.  For an
example, see t/eg/logout.pl.  Logout scripts may want to take
advantage of AuthCookie's C<logout()> method, which will set the
proper cookie headers in order to clear the user's cookie.  This
usually looks like C<$r-E<gt>auth_type-E<gt>logout($r);>.

Note that if you don't necessarily trust your users, you can't count
on cookie deletion for logging out.  You'll have to expire some
server-side login information too.  AuthCookie doesn't do this for
you, you have to handle it yourself.

=head1 ABOUT SESSION KEYS

Unlike the sample AuthCookieHandler, you have you verify the user's
login and password in C<authen_cred()>, then you do something
like:

    my $date = localtime;
    my $ses_key = MD5->hexhash(join(';', $date, $PID, $PAC));

save C<$ses_key> along with the user's login, and return C<$ses_key>.

Now C<authen_ses_key()> looks up the C<$ses_key> passed to it and
returns the saved login.  I use Oracle to store the session key and
retrieve it later, see the ToDo section below for some other ideas.

=head1 KNOWN LIMITATIONS

If the first unauthenticated request is a POST, it will be changed to
a GET after the user fills out the login forms, and POSTed data will
be lost.

=head2 TO DO

=over 4

=item *

There ought to be a way to solve the POST problem in the LIMITATIONS
section.  It involves being able to re-insert the POSTed content into
the request stream after the user authenticates.

It might be nice if the logout method could accept some parameters
that could make it easy to redirect the user to another URI, or
whatever.  I'd have to think about the options needed before I
implement anything, though.

=back

=head1 CVS REVISION

$Id: AuthCookie.pm,v 2.16 2001/06/01 15:50:27 mschout Exp $

=head1 AUTHOR

Michael Schout <mschout@gkg.net>

Originally written by Eric Bartley <bartley@purdue.edu>

versions 2.x were written by Ken Williams <ken@forum.swarthmore.edu>

=head1 SEE ALSO

L<perl(1)>, L<mod_perl(1)>, L<Apache(1)>.

=cut
