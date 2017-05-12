####################################################################
#
# CGI::Session
#
# A module which makes LDAP authentication and session state
# much easier to manage.
#
####################################################################
#
# Generalized by Jeff Younker
# jyounker@inktomi.com (or jeff@math.uh.edu)
#
# Many thanks for the basic code and idea go to Luke
# Sheneman (sheneman@inktomi.com).
#
####################################################################

package CGI::Session;
use strict;

use vars qw($VERSION);
$VERSION = '0.9c';

use CGI::Carp;
use CGI;
use Date::Format;
use DBI;

=head1 NAME 

  CGI::Session - CGI cookie authentication against an LDAP database

=head1 ABSTRACT

  Provides a simple API authenticate users against an LDAP server, and then
  to cache this authentication information between invokations of CGI scripts
  without sending passwords subsequent to login.

  The state information is maintained in a combination of a cookie, a database,
  and a magic passkey which is sent in the contents of the web page.  Acquiring
  the login thus requires stealing both the cookie and a current copy of the
  web page.

  CGI::Session also contains a subclass of CGI which transparently injects
  the passkey into forms.  It is strongly suggested that you use this class.

=head1 SYNOPSIS

=head2 Setting Things Up

use CGI::Session;
use CGI;

  my $cgi = new CGI::Session::CGI;
  my $session = new CGI::Session( $cgi );
  $cgi->session( $session );

  my $session_store = new CGI::Session::CookieJar::DBI;
  $session_store->set( -cookie_name=>'cookie_name',
                       -username=>'myuser',
                       -password=>'kjsdfdf',
                       -host=>'dbhost',
                       -database=>'mydb',
                       -cookie_table=>'cookiejar' );
  $session->set( -cookie_jar => $session_store );


  $session->auth_servers(
	[ new CGI::Session::LDAPServer(
	    'ldap.server.my.domain',                  # host
            389,                                      # port
            'ou=my,ou=domain',                        # root
	    'ou=people,ou=my,ou=domain'               # base
	    'uid=$username,ou=people,ou=my,ou=domain' # bind
	) ] );

   $session->open;

=head2 Performing the Initial Login

   my $action = $cgi->param('action');
   my $passkey = $cgi->param('passkey');

   if ( defined $action and $action eq 'Log In' )
     {
       my $username = $cgi->param('username');
       my $password = $cgi->param('password');
       if ( $session->authenticated( $username, $password ) )
	 {
	   $session->set_passkey( $user );
	   $session->set_login_cookie( $user );

	   # Notice that we use $session->header and not $cgi->header
	   #
	   print $session->header();
	   print $cgi->start_html( 'Login Succeeded' );
	   ...

	   # The passkey is sent via the cgi wrapper.
	   #
	   my $passkey = $session->passkey;
	   print $cgi->start_form( -action=>'http://my.stupid/script.cgi' );

	   print ...your form here...

           print $cgi->end_form;
           ...
	   print $cgi->end_html;
	   exit 0;
         }
       else
         {
	   ...
	   Login Failed
	   ...
           $session->close;
	   exit 0;
	 }
     }

=head2 Confirming an Existing Session

     my $passkey = $cgi->param('passkey');
     if ( defined $passkey and !$session->confirm_userlogin( $passkey ) )
       {
         print $session->header();
	 print $cgi->start_html( 'Open Session' );
	 ...
	 my $passkey = $session->passkey;

         print $cgi->start_form( -action=>'http://my.stupid/script.cgi' );

         print ...your form here...

         print $cgi->end_form;
         ... 
         print $cgi->end_html;
         $session->close;
	 exit 0;
       }
     else
       {
	 ... Authentication Failed Page ...
       }

=head2 Logging out of an Existing Session

      $session->set_logout_cookie;
      print $session->header;
      print $cgi->start_html( 'Logout Complete' );
      print "You have logged out.";
      print $cgi->end_html;
      exit 0;

=head1 REQUIRES

CGI.pm
CGI::Carp
DBI (and at least one DBD)
Mozilla::LDAP
Date::Format

=head1 DESCRIPTION

When a user first authenticates the LDAP database is consulted.  If
the user is successfully authenticated the information is cached. For
subsequent login attempts.  The successful login is recorded in a
database, and opaque references to this information are passed back to
the client.

One of the opaque references is a cookie which is managed by the
client, and the other is a randomly chosen string which is passed
within the content of the web pages.  The random string is referred to
as a passkey, and it must be resent with every page.

On subsequent executions the cookie and the passkey are checked.  If
either of these do not match the record in the database then the user
is rejected.

When the program is complete the user is logged out by expiring the
cookie.

=head1 USAGE

There are four major operations.  The first is setting up the
CGIviaLDAP.  Gotta do this every time.  The second is authenticating a
new user/connection.  The third is authenticating an existing session.
The fourth is logging out an existing session.  ( And somewhere in there
you have to send the cookie and passkey back to the client. )

=head2 Setting up the Authentication Object

The first step is to include the necessary libraries.  These are
CGI::Session.pm and CGI.

    use CGI::Session::CGI;
    use CGI::Session;

The second step is to create the CGI::Session object which will be
used.  It requires a CGI object when it is created.  The CGI object
provides the machinery to manage cookies.

    my $cgi = new CGI::Session::CGI;
    my $session = new CGI::Session( $cgi );
    $cgi->session( $cgi );

Now you have to tell the CGIviaLDAP several things.  You have to tell it
which LDAP servers it should use for authentication.  You need to tell it
how to connect to the database.  You need to describe the database table
in which it will store its information.  You need to describe the cookie
that it will send to the client's web browser.  Finally, you need to
describe various aspects of the login behavior.

=head2 Setting the Authentication Servers

  $session->auth_servers( new CGI::Session::LDAPServer( -host=>'my.host.my.domain',
							    -port=>389,
							    -bind=>'uid=$username,ou=people,dc=my,dc=domain' ) );

The string '$username' within the -bind argument will be replaced with
the username when authentication occurrs.

You can also supply more than one ldap server by passing an array of
servers.  The servers will be checked from first to last in the array.

  my $server1 = new CGI::Session::LDAPServer( -host=>'ldap1.my.domain',
						  -port=>389,
						  -bind=>'uid=$username,ou=people,dc=my,dc=domain' );
  my $server2 = new CGI::Session::LDAPServer( -host=>'ldap2.your.domain',
						  -port=>389,
						  -bind=>'uid=$username,ou=people,dc=your,dc=domain' );
  $session->auth_servers( [ $server1, $server2 ] );


=head2 Describing the Database Connection

CGIviaLDAP uses perl DBI modules to access the database.  There are
three items of major importance.  These are the connection DN, the
the database user, and their associated password.

  $session->dbi_dn( 'dbi:mysql:my_apps_database' );
  $session->dbi_username( 'my_apps_user' );
  $session->dbi_password( '!CENSORED' );

=head2 Describing the Database Table

You've now told the object how to connect to the database.  Now you need
to tell it what the table it stores the information in will look like.
The most important is the name of the table in which the information
will be stored.

  $session->cookie_table( 'login_cookies' );

There are three columns it expects.  The first is the name of the
user; the second is the contents of the cookie; and the third is the
passkey.  By default these are called, respectively, 'user_id',
'cookie', and 'cookie', and 'passkey'.  You may never need to change
these.  If you do need to change them then you would write:

  $session->user_column('username');
  $session->cookie_column('login_cookie');
  $session->passkey_column('login_passkey');

=head2 Setting Cookie Parameters

When your program sends back a cookie, the cookie needs to have several
parameters set.  These include the name of the cookie, the path which it
covers, the domain for which it is good, and wether or not it should
be used without a secure connection.

  $session->cookie_name( 'MySessionCookie123587098' );  # The name of the cookie
  $session->cookie_path( '/' );
  $session->cookie_domain( '.drinktomi.com' );
  $session->secure( 1 );  # 1=requires secure transport
                          # 0=does not require secure transport

Most importantly you need describe how long the cookie should be valid
for.  This is the expiration.  It is given in seconds.  If using the
refresh option (more on this later) then the expiration determines how
long the web browser can sit idle.  If not using the refresh option
then it determines how long the user will remain logged in.

  $session->cookie_expiration( 60*60*2 );  # Cookies will be good for two hours.

=head2 Setting Login Behavior

Setting the auto refresh cookie option to 1 will the cookie's expiration
time to be updated every time a page is sent to the client.  As long as
the user keeps using the application they will never be logged out.

  $session->auto_refresh_cookie(1) # 1=always refresh the session cookie
                                   # 0=never automatically refresh the session cookie

In some instances you only want people to log in when they have a
pre-existing database entry.  In this case there are two ways of
managing things.  The first is to create an external file containing
the valid user IDs.  This is kind of a hack.

  $session->allowed_user_file( '/var/etc/allowed_users' );
  $session->restricted_access( 1 )  # 1=use allowed user file
                                    # 0=do not use allowed user file

The second way of managing things is a little more to my taste.  Normally
the auth object will register the user (create an entry for them) in the
cookie table.  You can change this so it will not log a person in unless
they already have an entry in the cookie table.

  $session->register(1);     # 1=automatically register users in the cookie table.
                             # 0=do not automatically register users in the cookie table.

Some day we may support check LDAP group memberships as a third mechanism.


=head2 Sending Back a Page

You have to do two things.  The first is that you have to generate the HTTP header
using CGI::Session instead of CGI, and the second is that you have to make sure
that the passkey gets sent back with the results of the next page.  

The call CGI::Session::header is used _exactly_ like CGI::header.
The only difference is that it automatically injects the session
cookie if it needs to.

    print $session->header;

The best way to get the passkey back to the user is by using
CGI::Session::CGI instead of CGI, and using the start_form
and end_form functions.  These will automatically inject the
necessary html.  The code looks something like this:

   print $cgi->start_form( -action=>$cgi->self_url );
   print "YOUR FORM HERE";
   print $cgi->end_form;

As long as you use CGI::Session::CGI then you don't have to do
anything else.

If you want to inject passkey into the document yourself then the
simplest way is to use a hidden text field.  The current passcode is
contained in CGI::Session::passkey.  The code to create the form
might look something like the next snippet.

    print "<form...>"
    ...
    my $key = $session->passkey;
    print "<input type=hidden name=passkey value=$key>";
    ...
    print "</form>"

If you don't send the passkey along then confirmation of the next
session login will fail.

=head2 Authenticating a New Session

Read the user name, and password from the incoming CGI form, and then
pass them to CGIviaLDAP::authenticated.  If the user is authenticated
the we must generate a passkey and a session cookie.

  my $username = $cgi->param('username');
  my $password = $cgi->param('password');
  if ( $session->authenticated( $username, $password ) )
    {
      $session->set_passkey( $username );
      $session->set_login_cookie( $username );
      ...
      Successfully authenticated, send response
      ...
    }
  else
    {
      ...
      Login Failed
      ...
    }


=head2 Confirming an Existing Session

  Read the passkey from the incoming CGI form, and then ask
  CGIviaLDAP to confirm it.

  my $key = $cgi->param('passkey');
  if ( $session->confirmed($key) )
    {
      ...
      Session was confirmed and this is a valid session
      ...
    }
  else
    {
      ...
      Session was not confirmed, and this is not a valid session
      ...
    }

Once a session has been confirmed you can do several things with it.
You can change the passcode; you can change the cookie identifier; or
you can refresh the cookie so that the expiration time will be reset.

=head2 Changing the Passcode

  if ( $session->confirmed( $key ) )
    {
      $session->set_passcode;
      ...
      Session was confirmed and this is a valid session
      ...
    }

=head2 Changing the Cookie Identifier

  if ( $session->confirmed( $key ) )
    {
      $session->set_login_cookie;
      ...
      Session was confirmed and this is a valid session
      ...
    }

=head2 Refreshing the Cookie Expiration

  if ( $session->confirmed( $key ) )
    {
      $session->refresh_login_cookie;
      ...
      Session was confirmed and this is a valid session
      ...
    }

=head2 Logging Out

  if ( $session->confirmed( $key ) and $logout )
    {
      $session->set_logout_cookie;
      ...
      print $session->header() # You must send back a cookie using the $session
      print $cgi->start_html( 'Logout Page' );
      print "You have been logged out.";        # Notice that the passkey does not
                                                # need to be sent back.
      print $cgi->end_html;
      exit 0;
    }


=head2 Creating the Cookie Table

Guess what? Once you have configured your CGIviaLDAP there is a function
which will create the table that you have described.  It only works for
MySQL at the moment, but in the future it may work for other databases.

  $session->create_cookie_table;


=head1 TO DO

=over 4

=item 1. Provide function to retreive username from the database using the cookie.

=item 2. Provide support for Net::LDAP

=item 3. Clean up DBI code. (DBI provides the independence that the old routines did.)

=item 4. Clean up DBI connection creation. (Makes way too many database connections.)

=item 5. Make an 'add_cookie_table' function to alter existing tables.

=item 6. Date tracking and garbage collection of expired cookie entries for auto-registered tables.


=back


=head1 REFERENCE

=cut

############################################
#                                          # 
# Some Constants, used only within Inktomi #
#                                          #
############################################

# Toggle this to limit access to the application to a specific set of 
#  people.  1 = restricted, 0 = open
my $RESTRICTED_ACCESS = 0;

my $ALLOWED_USER_FILE = "/var/tmp/allowed_users";

#
# Settings for the LDAP server to authenticate against
#
my $AUTH_LDAP_SERVER = "gandalf.inktomi.com";
my $AUTH_LDAP_PORT   = 389;
my $AUTH_LDAP_ROOT   = "o=inktomi.com";
my $AUTH_LDAP_BASE   = $AUTH_LDAP_ROOT;
my $AUTH_LDAP_BIND   = "uid=\$username,ou=People,$AUTH_LDAP_BASE";

#
# Settings for the general-purpose LDAP server
#
my $GEN_LDAP_SERVER = "phonebook.inktomi.com";
my $GEN_LDAP_PORT   = 389;
my $GEN_LDAP_ROOT   = "dc=inktomi,dc=com";
my $GEN_LDAP_BASE   = "ou=People,$GEN_LDAP_ROOT";
my $GEN_LDAP_BIND   = "uid=\$username,$GEN_LDAP_BASE";

my $UNIKEY          = "kevinbac0n";

my $COOKIE_LOGGED_IN  = "1FA6FAACE01B7A2677";
my $COOKIE_LOGGED_OUT = "1FA90BCCA7510F0CC9";
my $COOKIE_EXPIRATION = (3600*24);   # in seconds
my $COOKIE_PATH = "/";
my $COOKIE_DOMAIN = ".inktomi.com";
my $COOKIE_SECURE = 1;

my $DBI_DN = 'dbi:mysql';
my $DBI_USERNAME = 'nobody';
my $DBI_PASSWORD = 'mangle';
my $COOKIE_TABLE = 'stock';

my $USER_REGISTER = 1;
my $AUTO_REFRESH_COOKIE = 0;

my $PASSKEY_NAME = 'passkey2134343245';


=over 4
=item CGI::Session::new

Creates a new session object.  Requires at least one argument.  This
argument is a CGI object of some kind.

  my $cgi = new CGI::Session::CGI;
  my $session = new CGI::Session( $cgi );

You can then set values with function calls.  Or, you can use the
handy-dandy '-PARAMETER=>VALUE' syntax just like the standard module
CGI.pm uses.  This is in fact the prefered method, and I strongly
suggest that you use it.

  my $cgi = new CGI::Session::CGI;
  my $session = new CGI::Session( $cgi,
				      -auth_servers => [ $ldap1, $ldap2 ],
				      
				      -dbi_dn => 'dbi:mysql:stock',
				      -cookie_table => 'everyones_cookies',
				      -dbi_username => 'your_mythical_db_user',
				      -dbi_password => 'its_password',
				      
				      -cookie_expiration => 900,
				      -cookie_name => '1FA6FAACE01B7A2677',
				      -cookie_path => '/',
				      -cookie_domain => '.inktomi.com',
				      -cookie_secure => 0,
				      
				      -passkey_name => 'passkey',
				      
				      -restricted_access => 0,
				      -register => 1,
				      -auto_refresh_cookie => 1 );

=head2 Parameters for a new CGI::Session

=over 8

=item -cookie_name

  The name of the cookie that will be passed back to the browser.

=item -cookie_expiration

  The lifetime of the cookie in seconds.

=item -cookie_path

  The path of the cookie.

=item -cookie_domain

  The domain of the cookie.

=item -cookie_secure

  If set to 1 (-cookie_secure=>1) then SSL will be required for this
  connection. If set to 0 or undef then then normal http can be used.
  Defaults to 1.

=item -auth_servers

  Points to either a single authentication server, or an anonymous
  array of authentication servers.  Currently authentication servers
  are defined using CGI::Session::LDAPServer.  Others may be added
  in the future.  (At that time this will become a very poorly named
  module.)

  my $ldap1 = new CGI::Session::LDAPServer( -host=>'ldap.inktomi.com',
						-port=>389,
						-bind=>'uid=$username,ou=People,dc=inktomi,dc=com' );
  my $ldap2 = new CGI::Session::LDAPServer( -host=>'mccoy.inktomi.com',
                                                -port=>389,
                                                -bind=>'uid=$username,ou=People,dc=inktomi,dc=com' );

  $session => new CGI::Session( $cgi, -auth_servers => $ldap1 );

  --or--

  $session => new CGI::Session( $cgi, -auth_servers => [ $ldap1, $ldap2 ] );

=item -restricted_access

 This is set to either a 1 or 0 (undef is the same as 0).  If set to a
 one then access will be restricted to those users which are specfied
 in the file corresponding to -allowed_user_file.  This file contains
 the names of the users which can be successfully authenticated. One
 username is listed on each line of this file.

=item -allowed_user_file

 The full path to a file containing the usernames of the users which
 can be successfully authenticated.  Each line of the file contains one
 username.  If a user is not specified in this file then authentication
 will fail.

 This file is only consulted if -restricted_access is set to 1.

=item -unikey

 DANGER. The password for a back door.  If this value is set to 0
 or undef then no back door exists.  This is ONLY A TESTING feature.
 DO NOT SET THIS VARIABLE IN PRODUCTION CODE.

=item -register

 If set to 1 then an entry is automatically created in the cookie
 table if one does not exist.  If set to 0 then authentication will
 fail if the user does not exist.

=item -dbi_dn

 The DBI connection string which will be used to connect to the
 database.

=item -dbi_username

 The username which will be used to connect to the database.

=item -dbi_password

 The password which will be used to connect to the database.

=item -cookie_table

 The database table in which the cookie information will be stored.

=item -user_column

 The column in the cookie_table containing the username.

=item -passkey_column

 The column in the cookie_table containing the passkey.

=item -cookie_column

 The column in the cookie_table containing the cookie value.

=item -cookie_name_column

 The column in the cookie_table containing the cookie name.


=item -login_expiration_column. CURRENTLY UNUSED

 The column in the cookie_table containing the session expiration time.
 

=item -passkey_name

 The name of the CGI parameter which contains the passkey.

=item -debug

 Set to non-zero to generate debugging information.

=back

=cut

sub new
  {
    my ( $type ) = shift;
    my ( $cgi ) = shift;

    my $self = {};
    bless $self, $type;

    # A cgi is required.
    #
    $self->cgi($cgi);

    # Registration behavior.
    #
    $self->register($USER_REGISTER);
    $self->auto_refresh_cookie($AUTO_REFRESH_COOKIE);

    # Set cookie defaults.
    #
    $self->cookie_name( $COOKIE_LOGGED_IN );
    $self->cookie_expiration( $COOKIE_EXPIRATION );

    # Default cookie parameters
    #
    $self->cookie_path( $COOKIE_PATH );
    $self->cookie_domain( $COOKIE_DOMAIN );
    $self->cookie_secure( $COOKIE_SECURE );

#    # Set default LDAP servers.
#    #
#    $self->auth_servers( [ new CGI::Session::LDAPServer( -host=>$AUTH_LDAP_SERVER,
#							       -port=>$AUTH_LDAP_PORT,
#							       -bind=>$AUTH_LDAP_BIND ),
#			   new CGI::Session::LDAPServer( -host=>$GEN_LDAP_SERVER,
#							       -port=>$GEN_LDAP_PORT,
#							       -bind=>$GEN_LDAP_BIND ) ] );

    $self->restricted_access( $RESTRICTED_ACCESS );
    $self->allowed_user_file( $ALLOWED_USER_FILE );

    $self->passkey_name( $PASSKEY_NAME );

    # Set any additional arguments.
    #
    if ( @_ ) { $self->set( @_ ); }
        
    return $self;
  }

# Open up the session if required.
#

=item CGI::Session::open

Internal function.  Opens up the cookie jar.  This function is called by
methods just before they first access a cookie jar.

$session->open;

=cut

sub open
  {
    my ( $self ) = @_;
    my $cookie_jar = $self->cookie_jar;
    $cookie_jar->open();
    if ( $cookie_jar->error )
      {
        croak sprintf( 'Error:  Could not open the cookie jar: %s', $cookie_jar->error );
      }
  }


# Destroy session when needed.
#
sub DESTROY 
  {
    my ( $self ) = shift;
    return unless defined $self->cookie_jar;
    $self->cookie_jar->close();
  }

# The cgi document which this session is connected to.
#

=item CGI::Session::cgi

Accessor method.  The cgi to which the session is attached.

=cut  

sub cgi { my $self=shift; @_ ? $self->{cgi}=shift : $self->{cgi}; }

#################################
######### Authentication results.

=item CGI::Session::cookie

Accessor method.  The value of the current cookie.

=cut 

#################################

sub cookie { my $self=shift; @_ ? $self->{cookie}=shift : $self->{cookie}; }

=item CGI::Session::passkey

Accessor method.  The value of the current passkey.  Set by confirmed() and authenticated().

=cut

sub passkey { my $self=shift; @_ ? $self->{passkey}=shift : $self->{passkey}; }

#################################

=item CGI::Session::is_authenticated

Accessor method.  Authentication state. True if the session has been successfully authenticated.  False if it has not.

=cut

sub is_authenticated { my $self=shift; @_ ? $self->{is_authenticated}=shift : $self->{is_authenticated}; }


# Fast initialization routine.
#
sub set
  {
    my ( $self ) = shift;
    my %a = @_;

    $self->cookie_jar( $a{-cookie_jar} ) if defined $a{-cookie_jar};
    $self->cookie_name( $a{-cookie_name} ) if defined $a{-cookie_name};
    $self->cookie_expiration( $a{-cookie_expiration} ) if defined $a{-cookie_expiration};
    $self->cookie_path( $a{-cookie_path} ) if defined $a{-cookie_path};
    $self->cookie_domain( $a{-cookie_domain} ) if defined $a{-cookie_domain};
    $self->cookie_secure( $a{-cookie_secure} ) if defined $a{-cookie_secure};
    $self->auth_servers( $a{-auth_servers} ) if defined $a{-auth_servers};
    $self->restricted_access( $a{-restricted_access} ) if defined $a{-restricted_access};
    $self->allowed_user_file( $a{-allowed_user_file} ) if defined $a{-allowed_user_file};
    $self->unikey( $a{-unikey} ) if defined $a{-unikey};
    $self->register( $a{-register} ) if defined $a{-register};
    $self->auto_refresh_cookie( $a{-auto_refresh_cookie} ) if defined $a{-auto_refresh_cookie};
    $self->passkey_name( $a{-passkey_name} ) if defined $a{-passkey_name};
    $self->debug( $a{-debug} ) if defined $a{-debug};
  }

# Cookie characteristics.
#
=item Cookie Characteristics

These accessor methods specify the details of the cookies which are generated.


=item CGI::Session::cookie_name

Accessor method.  The name of the login cookie.

=cut

sub cookie_name { my $self=shift; @_ ? $self->{cookie_logged_in}=shift : $self->{cookie_logged_in}; }

=item CGI::Session::cookie_logged_out

Accessor method.  Vestigial logout cookie.  Unused.  Like the wings of an
archeopertyx.  But with no hairy feathers.  Left here for strictly
archeological reasons.

=cut

sub cookie_logged_out { my $self=shift; @_ ? $self->{cookie_logged_out}=shift : $self->{cookie_logged_out}; }


=item CGI::Session::cookie_expiration

Accessor method.  The lifetime of the cookie specified in seconds.

=cut

sub cookie_expiration { my $self=shift; @_ ? $self->{cookie_expiration}=shift : $self->{cookie_expiration}; }


=item CGI::Session::cookie_path

Accessor method.  The path of the cookie.

=cut

sub cookie_path { my $self=shift; @_ ? $self->{cookie_path}=shift : $self->{cookie_path}; }


=item CGI::Session::cookie_domain

Accessor method.  The domain of the cookie.

=cut

sub cookie_domain { my $self=shift; @_ ? $self->{cookie_domain}=shift : $self->{cookie_domain}; }


=item CGI::Session::cookie_secure

Accessor method.  True if the cookie requires SSL.  False otherwise.

=cut

sub cookie_secure { my $self=shift; @_ ? $self->{cookie_secure}=shift : $self->{cookie_secure}; }


# Login behavior
#

=item Authentication Behavior Variables

These are variables which affect the behavior of the authentication mechanism.

=item CGI::Session::auth_servers

Accessor method.  The list of authentication servers which will be contacted.  This value can either
be a single server or a reference to an array of servers.

Currently these servers are definied by CGI::Session::LDAPServer objects.

=cut

sub auth_servers { my $self=shift; @_ ? $self->{authentication_servers}=shift : $self->{authentication_servers}; }
sub authentication_servers { my $self=shift; @_ ? $self->{authentication_servers}=shift : $self->{authentication_servers}; }
sub authorization_servers { my $self=shift; @_ ? $self->{authorization_servers}=shift : $self->{authorization_servers}; }


=item CGI::Session::restricted_access

Accessor method.  If set to a non-zero value then the allowed_user_file is turned on.

=cut

sub restricted_access { my $self=shift; @_ ? $self->{restricted_access}=shift : $self->{restricted_access}; }


=item CGI::Session::allowed_user_file

Accessor method.  The full path to the allowed_user_file.

=cut

sub allowed_user_file { my $self=shift; @_ ? $self->{allowed_user_file}=shift : $self->{allowed_user_file}; }


=item CGI::Session::unikey

Accessor method.  Boy this one sucks.  This is a backdoor value.  If this is
set then any user matching this ID will be successfully authenticated.  Why?  Strictly
for testing.  NEVER, EVER SET THIS VALUE UNLESS YOU KNOW WHAT THE FUCK YOU ARE DOING.

=cut

sub unikey { my $self=shift; @_ ? $self->{unikey}=shift : $self->{unikey}; }


=item CGI::Session::register

Accessor method.  Login requires an entry to exist in the cookie table for each user.
If this variable is set then an entry will automatically be created for users which are
successfully authenticated.

=cut

sub register { my $self=shift; @_ ? $self->{register}=shift : $self->{register}; }


=item CGI::Session::auto_refresh_cookie

Accessor method.  Normally the cookie will expire X seconds after it is created, where X is
specified by CGI::Session::cookie_expiration.  Whenever the cookie is refreshed this
timer resets.  Setting this variable to a non-zero value causes the cookie to be refreshed
every time that it is successfully verified.

=cut

sub auto_refresh_cookie { my $self=shift; @_ ? $self->{auto_refresh_cookie}=shift : $self->{auto_refresh_cookie}; }


=item CGI::Session::used_with_custom_cgi

Forget about this one.  This is an internal function used by CGI::Session and CGI::Session::CGI.
Normally set to zero.  Setting CGI::Session::CGI::session causes this value to be set.

=cut

sub used_with_custom_cgi { my $self=shift; @_ ? $self->{used_with_custom_cgi}=shift : $self->{used_with_custom_cgi}; }


=item CGI::Session::cookie_jar

# Cookiejar.  This handles all cookie storage.
#
Accessor method.  The object encapsulating cookie storage.

=cut

sub cookie_jar { my $self=shift; @_ ? $self->{cookie_jar}=shift : $self->{cookie_jar}; }




=item CGI::Session::passkey_name

Accessor method.  The name of the passkey field in the form is stored here.
Not currently important, but it will be if/when the table becomes a shared
resource.

=cut

sub passkey_name { my $self=shift; @_ ? $self->{passkey_name}=shift : $self->{passkey_name}; }


=item CGI::Session::debug

Accessor method.  Turns on debugging.  Currently this doesn't do much.  I need
to add more instrumentation.

=cut

sub debug { my $self=shift; @_ ? $self->{debug}=shift : defined $self->{debug}; }


#sub %($;$) { my $self=shift; @_ ? $self->{%}=shift : $self->{%}; }


=item CGI::Session::has_passkey

  True if the CGI session has a value for the parameter specified with
  -passkey_name.

  print "Session has passkey: ".( $session->has_passkey ? "YES" : "NO" )."\n";

=cut

sub has_passkey
  {
    my $self = shift;
    return $self->cgi->param($self->passkey_name);
  }


=item CGI::Session::passkey_field

 The value of the CGI parameter specified by -passkey_name.

 $passkey_field = $session->passkey_field;

=cut

sub passkey_field
  {
    my $self = shift;
    my $passkey = $self->passkey;
    my $passkey_name = $self->passkey_name;

    return qq(<input type=hidden name="$passkey_name" value="$passkey">);
  }


# Have the session activate the backend storage.
#



# Confirm the existance of the session
#
# $session->confirmed( $passkey )
# -or-
# $session->confirmed;
#
# 1 is SUCCESS
# 0 is FAILURE
#

=item CGI::Session::confirmed

  Confirms that the cookie and a passkey constitute a valid login.  If
  the session confirmation succeeds then it will return a true value.
  If the session confirmation fails then it will return a false value.

  Once this routine is called the variable of
  CGI::Session::is_authenticated will contain the status of the
  session.

  The function may be called in one of two ways.  You can either let
  it extract the passkey value on its own, or you can hand it the
  passkey value to be checked.  It is much less work to let it extract
  the passkey value.

  if ( $session->confirmed )
  {
    Session was confirmed...
  }

  If you want to handle the extraction of the passkey on your own...

  my $passkey = $cgi->param( 'passkey_name' );
  if ( $session->confirmed( $passkey ) )
  {
    Session was confirmed...
  }

=cut

sub confirmed
  {
    my ($self) = shift;

    $self->is_authenticated(undef);
    $self->open;
    my %args;
    if ( @_ ) { %args = ref @_ eq 'HASH' ? %{$_[0]} : @_ ; }
    my $auth_token = {};
    my ( $group, $groupdn, $passkey );
    $passkey = $args{-passkey} ? $args{-passkey} : $self->cgi->param( $self->passkey_name );
    if ( exists $args{-group}  )
      {
        $group = ref $args{-group} eq 'ARRAY' ? $args{-group} : [$args{-group}];
        $auth_token->{-group} = $group;
      }
    if ( exists $args{-groupdn} )
      {
        $groupdn = ref $args{-groupdn} eq 'ARRAY' ? $args{-groupdn} : [$args{-groupdn}];
        $auth_token->{-groupdn} = $groupdn;
      }

    my $client_cookie;
    my $db_passkey;
    
    $client_cookie = $self->check_cookie;

    if(!defined $client_cookie or !$client_cookie)
      {
	# No client Cookie!
        carp "No Cookie!" if $self->debug;
	return 0;
      }

    my $cookie_jar = $self->cookie_jar;

    my $session = $cookie_jar->session( -query=>{-cookie_name=>$self->cookie_name,
                                                 -cookie=>$client_cookie},
                                        -omit_server_side_data=>1 );
    if ( defined $cookie_jar->error )
      {
	croak "Error: Encountered error while attempting to retrieve passkey: ".($cookie_jar->error);
      }
    if ( scalar @{$session} == 0 )  
      {
	carp "ERROR: Passkey not found in cookie jar" if $self->debug;
	return 0;
      }

    $db_passkey = $session->[0]->{passkey};
    
    # passkey doesn't match passkey in database
    if (!defined $passkey)
      {
	carp "ERROR: Passkey is not found" if $self->debug;
	return 0;
      }
    elsif ($passkey ne $db_passkey)
      {
	carp "ERROR: Passkeys don't match" if $self->debug;
	return 0;
      }
    else
      {
        $self->passkey( $passkey );
        $auth_token->{-username} = $self->username();
      }

    # We can only reach this point if we have been successfully authorized.
    # Now we check authorization.
    #
    if ( authorize( $self, $auth_token ) )
      {
        $self->is_authenticated(1);
        $self->refresh_login_cookie if $self->auto_refresh_cookie;
        return 1;
      }
    else
      {
        return 0;
      }
  }

# For testing at a separate point.
#
# $session->confirm;
# if ( $session->is_authenticated ) { ... }
#

=item CGI::Session::confirm

The preferred way of confirming a valid login session.  It extracts
the cookie and session key from the CGI, checks their validity, and
then sets the variable CGI::Session::is_authenticated.  Used as
follows:

  $session->confirm;
  if ( $session->is_authenticated )
  { 
    Authentication Succeeded
  }
  else
  {
    Authentication Failed
  }

=cut

sub confirm { my $self = shift; $self->confirmed(@_); }


# Authenticate User (at beginning)
#
# $session->authenticated( $username, $password );
#
# 1 = SUCCESS
# 0 = FAILURE
#

=item CGI::Session::authenticate

Call the method authenticated with the username and password that you
want to check.  Authenticated will check their validity.  If user was
successfully authenticated then it will return a true value.  If the
user was not successfully authenticated then it will return a false
value.

Once authenticated is called then is_authenticated will return the
authentication status.

  $username = $cgi->param('your_username_field');
  $password = $cgi->param('your_password_field');

  if ( $session->authenticated( $username, $password ) )
    {
      Authentication Succeeded
    }
  else
    {
      Authentication Failed
    }

=cut

sub authenticated
  {
    my ( $self ) = shift;

    # Parse arguments.
    #
    my %args;
    if ( @_ ) { %args = ref @_ eq 'HASH' ? %{$_[0]} : @_ ; }
    my $auth_token = {};
    my ( $group, $groupdn );
    my $username = $args{-username};
    $self->user( $username );
    $auth_token->{-username} = $username;
    $auth_token->{-password} = $args{-password} if exists $args{-password};
    if ( exists $args{-group}  )
      {
        $group = ref $args{-group} eq 'ARRAY' ? $args{-group} : [$args{-group}];
        $auth_token->{-group} = $group;
      }
    if ( exists $args{-groupdn} )
      {
        $groupdn = ref $args{-groupdn} eq 'ARRAY' ? $args{-groupdn} : [$args{-groupdn}];
        $auth_token->{-groupdn} = $groupdn;
      }
    $self->is_authenticated(undef);
    $self->open();

    return 0 unless $username;

    # Check each one of the auth servers in turn.  If any one
    # of them succeeds then the user is logged in.
    #
    my $authentication_servers = $self->authentication_servers;

    if ( !$authentication_servers )
      {
	return 0;
      }

    # Handle a single authorization server.
    #
    my $authenticated = undef;

    if ( ref($authentication_servers) ne 'ARRAY' )
      {
	$authentication_servers = [ $authentication_servers ];
      }

    $self->is_authenticated(undef);

    foreach my $auth_server ( @{$self->authentication_servers} )
      {
        if ( $auth_server->authenticated( $auth_token ) )
          {
            $authenticated = 1;
            last;
          }
      }

    $self->is_authenticated( $authenticated );
    return 0 unless $authenticated;

    # Check each one of the authorization servers in turn.  If any one
    # of them succeeds then the user is accepted.
    #
    # Note that we can only get to this point if the user has
    # been authenticated.
    #
    my $authorization_servers = $self->authorization_servers;

    # We succeed if there are no authorization servers.
    #
    if ( authorize( $self, $auth_token ) )
      {
        $self->register_user($username);
        $self->is_authenticated(1);
        return 1;
      }

    return 0;
  }

# For testing at a separate point.
#
# $session->authenticate( $username, $password );
# if ( $session->is_authenticated ) { ... }
#

=item CGI::Session::authenticate

The preferred method of authenticating a user. Call the method
authenticate with the username and password that you want to check.
Authenticate will check their validity and then set the variable
is_authenticated with the status.  For example:

  $username = $cgi->param('your_username_field');
  $password = $cgi->param('your_password_field');

  $session->authenticate( $username, $password );
  if ( $session->is_authenticated )
    {
      Authentication Succeeded
    }
  else
    {
      Authentication Failed
    }

=cut

sub authenticate
  {
    my ( $self, $username, $password ) = @_;
    if ( $self->authenticated( $username, $password ) )
      {
	$self->set_passkey( $username );
	$self->set_login_cookie( $username );
      }
  }

# Authorization happens at two points, so I've separated it out.
# Returns true if the user is accepted, false if they are not.
#
# $is_authorized = $session->authorize( $auth_token );
#
=item CGI::Session::authorize

An internal function which performs authorization.  It must be called _after_ authentication has happened.  Used as follows:

my $auth_token = { -username=>$user, -group=>$group };
my $authorized = $session->authorize( $auth_token );

=cut

sub authorize
  {
    my ( $self, $auth_token ) = @_;
    my $authorization_servers = $self->authorization_servers;

    # We succeed if there are no authorization servers.
    #
    return 1 unless $authorization_servers;

    # Make a single authorization server look the same as many.
    #
    if ( ref($authorization_servers) ne 'ARRAY' )
      {
	$authorization_servers = [ $authorization_servers ];
      }

    # Check each one of the authorization servers in turn.  If any one
    # of them succeeds then the user is accepted.
    #
    foreach my $server ( @{$self->authorization_servers} )
      {
        return 1 if $server->authorized( $auth_token );
      }
    return 0;
}

##############################################################
#
# Wrapper for CGI.pm's header function which transparently
# handles creation of the cookie.
#

sub header_args_with_cookie
  {
    my ($self,%raw_args) = @_;

    # Copy the arguments.  If we find a cookie argument
    # then we add in any cookies that we already know about.
    #
    my @processed_args ;
    my $cookie_is_done = 0;
    foreach my $arg (keys %raw_args)
      {
	push @processed_args, $arg;
	my $val = $raw_args{$arg};
	if ($arg=~/^-?cookie$/i and $self->cookie )
	  {
	    if ( ref($val) eq 'ARRAY' )
	      {
		push @{$val}, $self->cookie;
	      }
	    else
	      {
		$val = [ $val, $self->cookie ]
	      }
	    $cookie_is_done = 1;
	  }
	push @processed_args, $val;
      }

    # If no cookies were found in the argument list then
    # we create one.
    #
    if ( $self->cookie and !$cookie_is_done )
      {
	push @processed_args, '-cookie';
	push @processed_args, $self->cookie;
      }

    return @processed_args;
  }


=item CGI::Session::header

Acts just like CGI.pm's header function, but it injects
the authentication cookie.

If you are using CGI::Session::CGI then this function will not be
used.  If you are using CGI.pm directly then call this function instead
of CGI.pm's header method.

  print $session->header;
  print $cgi->start_html( 'my html' );
  ...

=back

=cut

sub header
  {
    my ($self) = shift;
    my $header;

    # If this is being used with a custom CGI, then we just call the
    # custom CGI which understands how to use the header_args_with_cookie
    # to inject the cookie.  This call shouldn't be hear, but it was
    # put in before I had really thought through the use of a custom
    # CGI.pm wrapper.  (Otherwise we end up with duplicate cookies.)
    #
    if ( $self->used_with_custom_cgi )
      {
	$header = $self->cgi->header(@_);
      }
    else
      {
	$header = $self->cgi->header( $self->header_args_with_cookie(@_) );
      }
    return $header;
  }


=item CGI::Session::user_exists

Internal function.  Checks the database to see if a user has an existing
record within the cookie table.  True if the cookie table contains
an entry for the username, and false if it does not.

  if ( $self->user_exists( $username ) )
    {
      ... perform action for defined user ...
    }

=cut

sub user_exists
  {
    my ($self,$user) = @_;
    $self->open;
    return $self->cookie_jar->contains( -cookie_name=>$self->cookie_name, -user=>$user );
  }


=item CGI::Session::register_user

Internal function.  Creates an entry for the specified user within the cookie table.

  if ( ! $self->user_exists( $username ) )
    {
      $self->register_user( $username );
    }

=cut

sub register_user
  {
      my( $self, $username ) = @_;
      $self->open;
      my $cookie_jar = $self->cookie_jar;
      if ( ! $cookie_jar->contains( -cookie_name=>$self->cookie_name, -user=>$username ) )
	{
	  $cookie_jar->register_user( $self->cookie_name, $username );
	}
  }


=item CGI::Session::login_cookie

Internal function.  Returns the cookie string for the current session. The
expiration time is a unix timestamp as returned by the function time(). The
expiration time is not a lifetime in seconds.

  my $cookie_string = $self->login_cookie( $cookie_name, $expiration_time );

=cut

sub login_cookie
  {
    my ($self,$cookie_value,$expiration_time) = @_;
    my $datetimestr = time2str("%a, %e-%b-%Y %X GMT", $expiration_time, 'GMT');
    my $cgi = $self->cgi;
    my $cookie = $cgi->cookie( -name=>$self->cookie_name,
			       -value=>$cookie_value,
			       -path=>$self->cookie_path,
			       -domain=>$self->cookie_domain,
			       -secure=>($self->cookie_secure ? 1 : 0 ),
			       -expires=>$datetimestr );
    return $cookie;
  }

#
# Set the Session Cookie (login)
#
=item CGI::Session::set_login_cookie

Sets the login cookie for an authenticated session.  If a username
is not specified then it pulls the username corresponding to the
current cookie and passkey combination.

   $self->set_login_cookie( $username );

   ..or..

   $self->set_login_cookie();

=cut

sub set_login_cookie
  {
    my ($self) = shift;
    $self->open;
    my $cookie_jar = $self->cookie_jar;

    # Get user ID.  Either from the argument list or from
    # the cookie ID.
    #
    my $user_id;
    if ( @_ )
      {
	$user_id = shift;
	$user_id = defined $user_id ? $user_id : "";
      }
    else
      {
        my $cookie_name = $self->cookie_name();
	my $session = $cookie_jar->session( -query => { -cookie_name=>$self->cookie_name,
                                                        -cookie=>$self->cgi->cookie( $cookie_name ) },
                                            -omit_server_side_data => 1 );
	if ( defined $cookie_jar->error )
	  {
	    croak( "Error: Could not read user name fom the cookie jar: ".($cookie_jar->error) );
	  }
	if ( scalar @{$session} == 0 )
	  {
	    croak "Error: Could not read user name from the cookie jar";
	  }
	if ( scalar @{$session} > 1 )
	  {
	    croak "Error: Expected to retreive one username, but found several";
	  }
        $user_id = $session->[0]->{user};
      }
    
    my $r = int(rand 999999)+1;
    my $cookie_value = $user_id.$r;
    my $expiration_time = time + $self->cookie_expiration;
    $cookie_jar->set_session( -session=>{ user=>$user_id,
                                          cookie_name=>$self->cookie_name,
					  cookie=>$cookie_value,
					  expiration=>$expiration_time } );
    if ( defined $cookie_jar->error )
      {
	croak "Error: Could not update cookie value: ".($cookie_jar->error);
      }
    
    # Create cookie.
    #
    my $cookie = $self->login_cookie( $cookie_value, $expiration_time );
    $self->cookie( $cookie );

    # SUCCESS
    #
    return 0;
  }


=item CGI::Session::refresh_login_cookie

Resets the expiration time for the current cookie.

  $self->refresh_login_cookie();

=cut

sub refresh_login_cookie
  {
    my ($self) = @_;
    $self->open;
    my $cookie_name = $self->cookie_name;
    my $cookie_value = $self->cgi->cookie( $cookie_name );
    my $expire = time + $self->cookie_expiration;
    my $cookie = $self->login_cookie( $cookie_value, $expire );
    my $cookie_jar = $self->cookie_jar;
    $cookie_jar->set_session( -session=>{ cookie_name=>$cookie_name,
                                          cookie=>$cookie_value,
                                          expiration=>$expire } );
    $self->cookie( $cookie );
    if ( $cookie_jar->error )
      {
	croak "Error:  Could not set expiration for cookie: $cookie_jar->error";
      }
  }



=item CGI::Session::user($)

The cached name.

   my $username = $self->user();

=cut

sub user { my $self = shift; @_ ? $self->{user}=shift : $self->{user}; }

=item CGI::Session::username($)

Pulls the username for the current cookie/passkey pair from
the database or local cache.

   my $username = $self->username();

=cut

sub username
#
# Gets the user ID for the current session.
#
# my $username = $session->username;
#
  {
    my ( $self ) = @_;

    return $self->user if $self->user;

    my $cookie = $self->cgi->cookie( $self->cookie_name );
    my $passkey = $self->passkey;

    return undef unless( $cookie and $passkey );

    my $cookie_jar = $self->cookie_jar;
    my $sessions = $cookie_jar->session( -query => { -cookie_name=>$self->cookie_name,
                                                     -cookie=>$cookie,
                                                     -passkey=>$passkey },
                                         -omit_server_side_data => 1 );
    if ( defined $cookie_jar->error )
      {
        croak( "Error: Could not read user name fom the cookie jar: ".($cookie_jar->error) );
      }
    if ( scalar @{$sessions} == 0 )
      {
        croak "Error: Could not read user name from the cookie jar";
      }
    if ( scalar @{$sessions} > 1 )
      {
        croak "Error: Expected to retreive one username, but found several";
      }

    return $sessions->[0]->{user};
  }

#
# Create and assign the passkey from the database
#
=item CGI::Session::set_passkey

Sets the passkey for the current session, and writes it into the
backing store.  The passkey is chosen randomly.  The can either be
specified within the call, or if the passkey and cookie are already set
it can be extracted automatically by the session.

   $self->set_passkey( $username );

   ..or..

   $self->set_passkey();

=cut

sub set_passkey
  {
    my ($self) = shift;

    my $pass = int(rand 9999999)+1;

    $self->open;
    my $cookie_jar = $self->cookie_jar;

    # Set passkey based either on the specified username, or
    # upon the current login cookie.
    #
    if ( @_ )
      {
	my $user_id = shift;
	$user_id = defined $user_id ? $user_id : "";
	$cookie_jar->set_session( -session=>{ cookie_name=>$self->cookie_name,
                                              user=>$user_id,
                                              passkey=>$pass } );
      }
    else
      {
        my $cookie = $self->cgi->cookie( $self->cookie_name );
	$cookie_jar->set_session( -session=>{ cookie_name=>$self->cookie_name,
                                              cookie=>$cookie,
                                              passkey=>$pass } );
      }
    if ( $cookie_jar->error )
      {
	croak "Error: Problem encountered when attempting to store the passkey in the cookie jar: ".($cookie_jar->error);
      }

    $self->passkey( $pass );

    # SUCCESS
    #
    return 0;
  }

sub server_side_data
  {
    my $self = shift;

    $self->open;
    my $username = $self->username;
    my $cookie_jar = $self->cookie_jar;

    # Set or retreive the server side data depending upon
    # whether or not another argument was specified.
    #
    if ( @_ )
      {
        my $server_side_data = shift;
	$cookie_jar->set_session( -session=>{ cookie_name=>$self->cookie_name,
                                              user=>$username,
                                              server_side_data=>$server_side_data } );
        if ( $cookie_jar->error )
          {
            croak "Error: Problem encountered when attempting to store the passkey in the cookie jar: ".($cookie_jar->error);
          }
      }
    else
      {
	my $session = $cookie_jar->session( -query=>{ -cookie_name=>$self->cookie_name,
                                                      -user=>$username } );
        if ( $cookie_jar->error )
          {
            croak "Error: Problem encountered when attempting to store the passkey in the cookie jar: ".($cookie_jar->error);
          }
        return $session->[0]->{server_side_data};
      }
  }


=item CGI::Session::logout_cookie

Returns a login_cookie which has expired.  (Expiration date
is set to epoch.)

    my $cookie = $self->logout_cookie();

=cut

sub logout_cookie
  {
    my ($self) = @_;
    my $datetimestr = "Thu, 01-Jan-2000 00:00:01 GMT";
    my $cgi = $self->cgi;
    my $cookie = $cgi->cookie( -name=>$self->cookie_name,
			       -value=>{},
			       -path=>$self->cookie_path,
			       -domain=>$self->cookie_domain,
			       -secure=>($self->cookie_secure ? 1 : 0 ),
			       -expires=>$datetimestr );
    return $cookie;
  }

#
# logout here (as far as cookies are concerned)
#
=item CGI::Session::set_logout_cookie

Expires the cookie in the backing store.

    my $cookie = $self->set_logout_cookie();

=cut

sub set_logout_cookie
  {
    my ($self) = @_;

    my $logout_cookie = $self->logout_cookie;
    $self->cookie( $logout_cookie );
    
    # SUCCESS
    return 0;
  }

#
# Check Cookie
#
=item CGI::Session::check_cookie

Returns the cookie for this session if it exists.  If a
cookie does not exist then it returns nothing.

    my $login_cookie = $self->check_cookie();

=cut

sub check_cookie
  {
    my ($self) = @_;
    return $self->cgi->cookie($self->cookie_name);
  }

1;
