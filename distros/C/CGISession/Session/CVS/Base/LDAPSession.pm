####################################################################
#
# CGI::LDAPSession
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

package CGI::LDAPSession;
use strict;

use vars qw($VERSION);
$VERSION = '0.9b';

use Mozilla::LDAP::Conn;                # Main "OO" layer for LDAP
use Mozilla::LDAP::Utils;               # LULU, utilities.
use CGI::Carp;
use CGI;
use Date::Format;
use DBI;

=pod
=head1 NAME

  CGI::LDAPSession - CGI cookie authentication against an LDAP database

=head1 ABSTRACT

  Provides a simple API authenticate users against an LDAP server, and then
  to cache this authentication information between invokations of CGI scripts
  without sending passwords subsequent to login.

  The state information is maintained in a combination of a cookie, a database,
  and a magic passkey which is sent in the contents of the web page.  Acquiring
  the login thus requires stealing both the cookie and a current copy of the
  web page.

  CGI::LDAPSession also contains a subclass of CGI which transparently injects
  the passkey into forms.  It is strongly suggested that you use this class.

=head1 SYNOPSIS

=head2 Setting Things Up

use CGI::LDAPSession;
use CGI;

my $cgi = new CGI::LDAPSession::CGI;
my $session = new CGI::LDAPSession( $cgi );
$cgi->session( $session );

  $session->auth_servers(
	[ new CGI::LDAPSession::LDAPServer(
	    'ldap.server.my.domain',                  # host
            389,                                      # port
            'ou=my,ou=domain',                        # root
	    'ou=people,ou=my,ou=domain'               # base
	    'uid=$username,ou=people,ou=my,ou=domain' # bind
	) ] );

   $session->cookie_table( 'myCookieTable' );

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
CGI::LDAPSession.pm and CGI.

    use CGI::LDAPSession::CGI;
    use CGI::LDAPSession;

The second step is to create the CGI::LDAPSession object which will be
used.  It requires a CGI object when it is created.  The CGI object
provides the machinery to manage cookies.

    my $cgi = new CGI::LDAPSession::CGI;
    my $session = new CGI::LDAPSession( $cgi );
    $cgi->session( $cgi );

Now you have to tell the CGIviaLDAP several things.  You have to tell it
which LDAP servers it should use for authentication.  You need to tell it
how to connect to the database.  You need to describe the database table
in which it will store its information.  You need to describe the cookie
that it will send to the client's web browser.  Finally, you need to
describe various aspects of the login behavior.

=head2 Setting the Authentication Servers

  $session->auth_servers( new CGI::LDAPSession::LDAPServer( -host=>'my.host.my.domain',
							    -port=>389,
							    -bind=>'uid=$username,ou=people,dc=my,dc=domain' ) );

The string '$username' within the -bind argument will be replaced with
the username when authentication occurrs.

You can also supply more than one ldap server by passing an array of
servers.  The servers will be checked from first to last in the array.

  my $server1 = new CGI::LDAPSession::LDAPServer( -host=>'ldap1.my.domain',
						  -port=>389,
						  -bind=>'uid=$username,ou=people,dc=my,dc=domain' );
  my $server2 = new CGI::LDAPSession::LDAPServer( -host=>'ldap2.your.domain',
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
using CGI::LDAPSession instead of CGI, and the second is that you have to make sure
that the passkey gets sent back with the results of the next page.  

The call CGI::LDAPSession::header is used _exactly_ like CGI::header.
The only difference is that it automatically injects the session
cookie if it needs to.

    print $session->header;

The best way to get the passkey back to the user is by using
CGI::LDAPSession::CGI instead of CGI, and using the start_form
and end_form functions.  These will automatically inject the
necessary html.  The code looks something like this:

   print $cgi->start_form( -action=>$cgi->self_url );
   print "YOUR FORM HERE";
   print $cgi->end_form;

As long as you use CGI::LDAPSession::CGI then you don't have to do
anything else.

If you want to inject passkey into the document yourself then the
simplest way is to use a hidden text field.  The current passcode is
contained in CGI::LDAPSession::passkey.  The code to create the form
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
=item CGI::LDAPSession::new

Creates a new session object.  Requires at least one argument.  This
argument is a CGI object of some kind.

  my $cgi = new CGI::LDAPSession::CGI;
  my $session = new CGI::LDAPSession( $cgi );

You can then set values with function calls.  Or, you can use the
handy-dandy '-PARAMETER=>VALUE' syntax just like the standard module
CGI.pm uses.  This is in fact the prefered method, and I strongly
suggest that you use it.

  my $cgi = new CGI::LDAPSession::CGI;
  my $session = new CGI::LDAPSession( $cgi,
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

=head2 Parameters for a new CGI::LDAPSession

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
  are defined using CGI::LDAPSession::LDAPServer.  Others may be added
  in the future.  (At that time this will become a very poorly named
  module.)

  my $ldap1 = new CGI::LDAPSession::LDAPServer( -host=>'ldap.inktomi.com',
						-port=>389,
						-bind=>'uid=$username,ou=People,dc=inktomi,dc=com' );
  my $ldap2 = new CGI::LDAPSession::LDAPServer( -host=>'mccoy.inktomi.com',
                                                -port=>389,
                                                -bind=>'uid=$username,ou=People,dc=inktomi,dc=com' );

  $session => new CGI::LDAPSession( $cgi, -auth_servers => $ldap1 );

  --or--

  $session => new CGI::LDAPSession( $cgi, -auth_servers => [ $ldap1, $ldap2 ] );

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

=item -login_expiration_column. CURRENTLY UNUSED

 The column in the cookie_table containing the session expiration time.
 

=item -passkey_name

 The name of the CGI parameter which contains the passkey.

=item -debug

 Set to non-zero to generate debugging information.

=back

=cut

sub new($$@)
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
    $self->cookie_logged_in( $COOKIE_LOGGED_IN );
    $self->cookie_logged_out( $COOKIE_LOGGED_OUT );
    $self->cookie_expiration( $COOKIE_EXPIRATION );

    # Set database defaults.
    #
    $self->dbi_dn( $DBI_DN );
    $self->dbi_username( $DBI_USERNAME );
    $self->dbi_password( $DBI_PASSWORD );

    # Describe database
    #
    $self->cookie_table( $COOKIE_TABLE );
    $self->user_column( 'user_id' );
    $self->cookie_column( 'cookie' );
    $self->passkey_column( 'passkey' );

    # Default cookie parameters
    #
    $self->cookie_path( $COOKIE_PATH );
    $self->cookie_domain( $COOKIE_DOMAIN );
    $self->cookie_secure( $COOKIE_SECURE );

    # Set default LDAP servers.
    #
    $self->auth_servers( [ new CGI::LDAPSession::LDAPServer( -host=>$AUTH_LDAP_SERVER,
							       -port=>$AUTH_LDAP_PORT,
							       -bind=>$AUTH_LDAP_BIND ),
			   new CGI::LDAPSession::LDAPServer( -host=>$GEN_LDAP_SERVER,
							       -port=>$GEN_LDAP_PORT,
							       -bind=>$GEN_LDAP_BIND ) ] );

    $self->restricted_access( $RESTRICTED_ACCESS );
    $self->allowed_user_file( $ALLOWED_USER_FILE );

    $self->passkey_name( $PASSKEY_NAME );

    # Set any additional arguments.
    #
    if ( @_ ) { $self->set( @_ ); }
        
    return $self;
  }


=item CGI::LDAPSession::create_cookie_table

  Creates the database tables that are described by a CGI::LDAPSession.

  my $session = new CGI::LDAPSession;
  $session->create_cookie_table;
  exit;

  Fill out your CGI::LDAPSession just like your going to make
  a connection.  Call this routine, and voila!  Your database
  tables are created.

=cut

sub create_cookie_table($)
  {
    my ($self) = @_;

    my $cookie_table = $self->cookie_table;
    my $user_column = $self->user_column;
    my $cookie_column = $self->cookie_column;
    my $passkey_column = $self->passkey_column;

    $self->ConnectToDatabase;
    $self->SendSQL( "CREATE TABLE $cookie_table ( $user_column varchar(64), $cookie_column varchar(32), $passkey_column bigint(20) )" );
    $self->DisconnectDatabase;
  }
					      
# The cgi document which this session is connected to.
#

=item CGI::LDAPSession::cgi

Accessor method.  The cgi to which the session is attached.

=cut  

sub cgi($;$) { my $self=shift; @_ ? $self->{cgi}=shift : $self->{cgi}; }

#################################
######### Authentication results.

=item CGI::LDAPSession::cookie

Accessor method.  The value of the current cookie.

=cut 

#################################

sub cookie($;$) { my $self=shift; @_ ? $self->{cookie}=shift : $self->{cookie}; }

=item CGI::LDAPSession::passkey

Accessor method.  The value of the current passkey.  Set by confirmed() and authenticated().

=cut

sub passkey($;$) { my $self=shift; @_ ? $self->{passkey}=shift : $self->{passkey}; }

#################################

=item CGI::LDAPSession::is_authenticated

Accessor method.  Authentication state. True if the session has been successfully authenticated.  False if it has not.

=cut

sub is_authenticated($;$) { my $self=shift; @_ ? $self->{is_authenticated}=shift : $self->{is_authenticated}; }


# Fast initialization routine.
#

sub set($@)
  {
    my ( $self ) = shift;
    my %a = @_;

    $self->cookie_logged_in( $a{'-cookie_logged_in'} ) if defined $a{'-cookie_logged_in'};
    $self->cookie_logged_in( $a{'-cookie_name'} ) if defined $a{'-cookie_name'};
    $self->cookie_expiration( $a{'-cookie_expiration'} ) if defined $a{'-cookie_expiration'};
    $self->cookie_path( $a{'-cookie_path'} ) if defined $a{'-cookie_path'};
    $self->cookie_domain( $a{'-cookie_domain'} ) if defined $a{'-cookie_domain'};
    $self->cookie_secure( $a{'-cookie_secure'} ) if defined $a{'-cookie_secure'};
    $self->auth_servers( $a{'-auth_servers'} ) if defined $a{'-auth_servers'};
    $self->restricted_access( $a{'-restricted_access'} ) if defined $a{'-restricted_access'};
    $self->allowed_user_file( $a{'-allowed_user_file'} ) if defined $a{'-allowed_user_file'};
    $self->unikey( $a{'-unikey'} ) if defined $a{'-unikey'};
    $self->register( $a{'-register'} ) if defined $a{'-register'};
    $self->auto_refresh_cookie( $a{'-auto_refresh_cookie'} ) if defined $a{'-auto_refresh_cookie'};
    $self->dbi_dn( $a{'-dbi_dn'} ) if defined $a{'-dbi_dn'};
    $self->dbi_password( $a{'-dbi_password'} ) if defined $a{'-dbi_password'};
    $self->dbi_username( $a{'-dbi_username'} ) if defined $a{'-dbi_username'};
    $self->cookie_table( $a{'-cookie_table'} ) if defined $a{'-cookie_table'};
    $self->user_column( $a{'-user_column'} ) if defined $a{'-user_column'};
    $self->passkey_column( $a{'-passkey_column'} ) if defined $a{'-passkey_column'};
    $self->cookie_column( $a{'-cookie_column'} ) if defined $a{'-cookie_column'};
    $self->dbi_login_expiration_column( $a{'-dbi_login_expiration_column'} ) if defined $a{'-dbi_login_expiration_column'};
    $self->passkey_name( $a{-passkey_name} ) if defined $a{-passkey_name};
    $self->debug( $a{-debug} ) if defined $a{-debug};

  }

# Cookie characteristics.
#
=item Cookie Characteristics

These accessor methods specify the details of the cookies which are generated.


=item CGI::LDAPSession::cookie_logged_in($;$)

Accessor method.  The name of the login cookie.  Use cookie_name instead.

=cut

sub cookie_logged_in($;$) { my $self=shift; @_ ? $self->{cookie_logged_in}=shift : $self->{cookie_logged_in}; }


=item CGI::LDAPSession::cookie_name($;$)

Accessor method.  The name of the login cookie.  Use this instead of cookie_logged_in.

=cut

sub cookie_name($;$) { my $self=shift; @_ ? $self->{cookie_logged_in}=shift : $self->{cookie_logged_in}; }

=item CGI::LDAPSession::cookie_logged_out($;$)

Accessor method.  Vestigial logout cookie.  Unused.  Like the wings of an archeopertyx.  But with no hairy feathers.

=cut

sub cookie_logged_out($;$) { my $self=shift; @_ ? $self->{cookie_logged_out}=shift : $self->{cookie_logged_out}; }


=item CGI::LDAPSession::cookie_expiration($;$)

Accessor method.  The lifetime of the cookie specified in seconds.

=cut

sub cookie_expiration($;$) { my $self=shift; @_ ? $self->{cookie_expiration}=shift : $self->{cookie_expiration}; }


=item CGI::LDAPSession::cookie_path($;$)

Accessor method.  The path of the cookie.

=cut

sub cookie_path($;$) { my $self=shift; @_ ? $self->{cookie_path}=shift : $self->{cookie_path}; }


=item CGI::LDAPSession::cookie_domain($;$)

Accessor method.  The domain of the cookie.

=cut

sub cookie_domain($;$) { my $self=shift; @_ ? $self->{cookie_domain}=shift : $self->{cookie_domain}; }


=item CGI::LDAPSession::cookie_secure($;$)

Accessor method.  True if the cookie requires SSL.  False otherwise.

=cut

sub cookie_secure($;$) { my $self=shift; @_ ? $self->{cookie_secure}=shift : $self->{cookie_secure}; }


# Login behavior
#

=item Authentication Behavior Variables

These are variables which affect the behavior of the authentication mechanism.

=item CGI::LDAPSession::auth_servers($;$)

Accessor method.  The list of authentication servers which will be contacted.  This value can either
be a single server or a reference to an array of servers.

Currently these servers are definied by CGI::LDAPSession::LDAPServer objects.

=cut

sub auth_servers($;$) { my $self=shift; @_ ? $self->{auth_servers}=shift : $self->{auth_servers}; }


=item CGI::LDAPSession::restricted_access($;$)

Accessor method.  If set to a non-zero value then the allowed_user_file is turned on.

=cut

sub restricted_access($;$) { my $self=shift; @_ ? $self->{restricted_access}=shift : $self->{restricted_access}; }


=item CGI::LDAPSession::allowed_user_file($;$)

Accessor method.  The full path to the allowed_user_file.

=cut

sub allowed_user_file($;$) { my $self=shift; @_ ? $self->{allowed_user_file}=shift : $self->{allowed_user_file}; }


=item CGI::LDAPSession::unikey($;$)

Accessor method.  Boy this one sucks.  This is a backdoor value.  If this is
set then any user matching this ID will be successfully authenticated.  Why?  Strictly
for testing.  NEVER, EVER SET THIS VALUE UNLESS YOU KNOW WHAT THE FUCK YOU ARE DOING.

=cut

sub unikey($;$) { my $self=shift; @_ ? $self->{unikey}=shift : $self->{unikey}; }


=item CGI::LDAPSession::register($;$)

Accessor method.  Login requires an entry to exist in the cookie table for each user.
If this variable is set then an entry will automatically be created for users which are
successfully authenticated.

=cut

sub register($;$) { my $self=shift; @_ ? $self->{register}=shift : $self->{register}; }


=item CGI::LDAPSession::auto_refresh_cookie($;$)

Accessor method.  Normally the cookie will expire X seconds after it is created, where X is
specified by CGI::LDAPSession::cookie_expiration.  Whenever the cookie is refreshed this
timer resets.  Setting this variable to a non-zero value causes the cookie to be refreshed
every time that it is successfully verified.

=cut

sub auto_refresh_cookie($;$) { my $self=shift; @_ ? $self->{auto_refresh_cookie}=shift : $self->{auto_refresh_cookie}; }


=item CGI::LDAPSession::used_with_custom_cgi($;$)

Forget about this one.  This is an internal function used by CGI::LDAPSession and CGI::LDAPSession::CGI.
Normally set to zero.  Setting CGI::LDAPSession::CGI::session causes this value to be set.

=cut

sub used_with_custom_cgi($;$) { my $self=shift; @_ ? $self->{used_with_custom_cgi}=shift : $self->{used_with_custom_cgi}; }



# DBI structures and connection state.
#
=item DBI Structures and Connection State

Interal accessor methods pertaining to various aspects of the database connection.
These WILL change in future releases, and are documented here for the developer's
use.

=item CGI::LDAPSession::dbi($;$)

Accessor method.  The active DBI connection.  The connection to the database will be created
when first required, and the DBI connection will be cached in this variable.

=cut

sub dbi($;$) { my $self=shift; @_ ? $self->{dbi}=shift : $self->{dbi}; }


=item CGI::LDAPSession::dbi_statement($;$)

Accessor method.  Internal use only.  The current DBI statement.

=cut

sub dbi_statement($;$) { my $self=shift; @_ ? $self->{dbi_statement}=shift : $self->{dbi_statement}; }


=item CGI::LDAPSession::dbi_results($;$)

Accessor method.  Internal use only.  The current results object.

=cut

sub dbi_results($;$) { my $self=shift; @_ ? $self->{dbi_results}=shift : $self->{dbi_results}; }


=item CGI::LDAPSession::dbi_results($;$)

Accessor method.  Internal use only.  The prefetched results from a results object.
Not really necessary with DBI, but I haven't altered the original authentication logic
that required this.

=cut

sub dbi_prefetch($;$) { my $self=shift; @_ ? $self->{dbi_prefetch}=shift : $self->{dbi_prefetch}; }


# Database connection.
#
=item Variables describing the database connection.

These are variables which are used to make the database connection.  They
must be specified in order to make a connection.

=item CGI::LDAPSession::dbi_dn($;$)

Accessor method.  DBI connection string.

=cut

sub dbi_dn($;$) { my $self=shift; @_ ? $self->{dbi_dn}=shift : $self->{dbi_dn}; }


=item CGI::LDAPSession::dbi_password($;$)

Accessor method.  Password for the connection.

=cut

sub dbi_password($;$) { my $self=shift; @_ ? $self->{dbi_password}=shift : $self->{dbi_password}; }


=item CGI::LDAPSession::dbi_username($;$)

Accessor method.  Username for the connection.

=cut

sub dbi_username($;$) { my $self=shift; @_ ? $self->{dbi_username}=shift : $self->{dbi_username}; }


# Login/cookie table description.
#
=item Database tables

The names of the database tables.

=item CGI::LDAPSession::cookie_table($;$)

Accessor method.  The name of the cookie table.

=cut

sub cookie_table($;$) { my $self=shift; @_ ? $self->{cookie_table}=shift : $self->{cookie_table}; }


=item CGI::LDAPSession::user_column($;$)

Accessor method.  The column containing the usernames.

=cut

sub user_column($;$) { my $self=shift; @_ ? $self->{dbi_user_column}=shift : $self->{dbi_user_column}; }


=item CGI::LDAPSession::passkey_column($;$)

Accessor method.  The column containing the passkey.

=cut

sub passkey_column($;$) { my $self=shift; @_ ? $self->{dbi_passkey_column}=shift : $self->{dbi_passkey_column}; }


=item CGI::LDAPSession::cookie_column($;$)

Accessor method.  The column containing the cookie id.

=cut

sub cookie_column($;$) { my $self=shift; @_ ? $self->{dbi_cookie_column}=shift : $self->{dbi_cookie_column}; }


=item CGI::LDAPSession::login_expiration_column($;$)

Accessor method.  The expiration time for the cookie.  Currently not
used, but it will be used in the future.

=cut

sub login_expiration_column($;$) { my $self=shift; @_ ? $self->{dbi_login_expiration_column}=shift : $self->{dbi_login_expiration_column}; }


=item CGI::LDAPSession::passkey_name($;$)

Accessor method.  The name of the passkey field in the form is stored here.
Not currently important, but it will be if/when the table becomes a shared
resource.

=cut

sub passkey_name($;$) { my $self=shift; @_ ? $self->{passkey_name}=shift : $self->{passkey_name}; }


=item CGI::LDAPSession::debug($;$)

Accessor method.  Turns on debugging.  Currently this doesn't do much.  I need
to add more instrumentation.

=cut

sub debug($;$) { my $self=shift; @_ ? $self->{debug}=shift : defined $self->{debug}; }


#sub %($;$) { my $self=shift; @_ ? $self->{%}=shift : $self->{%}; }


##############################
#                            #
# Some LDAP Related Routines #
#                            #
##############################

# Create bind parameters from an ldap server object.
#
=item CGI::LDAPSession::setup_ldap_auth($$$$)

Internal function. Turns a CGI::LDAPSession::LDAPServer into
a Mozilla::LDAP::Utils::ldapArgs.  The user to be checked
is stored is taken from the -bind variable.

Within the -bind variable the string $username will be replaced
with the $user passed to setup_ldap_auth.


  $server = new CGI::LDAPSession::LDAPServer( -host => 'myhost',
                                              -port => 389,
                                              -base => 'ou=People,dc=inktomi,dc=com',
                                              -bind => 'uid=$username,ou=People,dc=inktomi,dc=com' );
  my %mozilla_ldap = $self->setup_ldap_auth( $ldap_server, $user, $password );

=cut

sub setup_ldap_auth($$$$)
  {  
    my ($self,$ldap_server,$username,$password) = @_;
    $username = defined $username ? $username : "" ;
    
    # get the args and set some defaults
    my %ld = Mozilla::LDAP::Utils::ldapArgs();

    $ld{host} = $ldap_server->host;
    $ld{port} = $ldap_server->port;
    $ld{root} = $ldap_server->root;
    $ld{base} = $ldap_server->base;

    my $bind = $ldap_server->bind;
    $bind =~ s/\$username/$username/g;
    $ld{bind} = $bind;
    $ld{pswd} = $password;

    # SUCCESS
    return %ld;
}


=item CGI::LDAPSession::has_passkey

  True if the CGI session has a value for the parameter specified with
  -passkey_name.

  print "Session has passkey: ".( $session->has_passkey ? "YES" : "NO" )."\n";

=cut

sub has_passkey($)
  {
    my $self = shift;
    return $self->cgi->param($self->passkey_name);
  }


=item CGI::LDAPSession::passkey_field

 The value of the CGI parameter specified by -passkey_name.

 $passkey_field = $session->passkey_field;

=cut

sub passkey_field($)
  {
    my $self = shift;
    my $passkey = $self->passkey;
    my $passkey_name = $self->passkey_name;

    return qq(<input type=hidden name="$passkey_name" value="$passkey">);
  }


# Confirm the existance of the session
#
# $session->confirmed( $passkey )
# -or-
# $session->confirmed;
#
# 1 is SUCCESS
# 0 is FAILURE
#

=item CGI::LDAPSession::confirmed

  Confirms that the cookie and a passkey constitute a valid login.  If
  the session confirmation succeeds then it will return a true value.
  If the session confirmation fails then it will return a false value.

  Once this routine is called the variable of
  CGI::LDAPSession::is_authenticated will contain the status of the
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

sub confirmed($;$)
  {
    my ($self) = shift;

    my $passkey = @_ ? shift : $self->cgi->param( $self->passkey_name );
    
    carp "Passkey is $passkey";

    my $client_cookie;
    my $db_passkey;
    
    $client_cookie = $self->check_cookie;

    if(!defined $client_cookie or !$client_cookie)
      {
	# No client Cookie!
        carp "No Cookie!" if $self->debug;
	$self->is_authenticated(undef);
	return 0;
      }

    my $cookie_table = $self->cookie_table;
    my $user_column = $self->user_column;
    my $cookie_column = $self->cookie_column;
    my $passkey_column = $self->passkey_column;

    $self->ConnectToDatabase;
    $self->SendSQL("SELECT $passkey_column FROM $cookie_table WHERE $cookie_column='$client_cookie'");
    ($db_passkey) = $self->FetchSQLData();
    $self->DisconnectDatabase;
    
    
    # passkey doesn't match passkey in database
    if (!defined $passkey)
      {
	carp "ERROR: Passkey is not found" if $self->debug;
	$self->is_authenticated(undef);
	return 0;
      }
    elsif ($passkey ne $db_passkey)
      {
	carp "ERROR: Passkeys don't match" if $self->debug;
	$self->is_authenticated(undef);
	return 0;
      }
    else
      {
        $self->passkey( $passkey );
      }

    # Refresh cookie automagically if the user wants us to.
    #
    $self->refresh_login_cookie if $self->auto_refresh_cookie;

    # Everything matches, confirm login
    #
    $self->is_authenticated(1);
    return 1;
}

# For testing at a separate point.
#
# $session->confirm;
# if ( $session->is_authenticated ) { ... }
#

=item CGI::LDAPSession::confirm

The preferred way of confirming a valid login session.  It extracts
the cookie and session key from the CGI, checks their validity, and
then sets the variable CGI::LDAPSession::is_authenticated.  Used as
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

sub confirm($;$) { my $self = shift; $self->confirmed(@_); }


# Authenticate User (at beginning)
#
# $session->authenticated( $username, $password );
#
# 1 = SUCCESS
# 0 = FAILURE
#

=item CGI::LDAPSession::authenticate

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

sub authenticated($$$) {
    my ($self,$username, $password) = @_;
    $username = defined $username ? $username : "";
    $password = defined $password ? $password : "";

    # the skeleton key!
    #
    if( defined $self->unikey && ($password eq $self->unikey))
      {
	$self->is_authenticated(1);
	return 1;
      }

    # Check restricted access file if the restricted access
    # switch has been set.  (This may eventually be set to an
    # LDAP group comparison.)
    #
    my $found_flag = 0;
    if($self->restricted_access)
      {
	my $result = open(RA_FD, $self->allowed_user_file);
	if(!defined($result))
	  {
	    carp "Could not open allowed access file\n";
	    $self->is_authenticated(undef);
	    return 0;
	  }
	else
	  {
	    while(my $line = <RA_FD>)
	      {
		chomp $line;
		if($line eq $username) {
		  $found_flag++;
		  last;
		}
	      }
	  }
	if(!$found_flag)
	  {
	    close(RA_FD);
	    $self->is_authenticated(undef);
	    return 0;
	  }
      }
    

    # some sanity checking foo
    #
    if( ( $username eq "" || $password eq "") )
      {
	$self->is_authenticated(undef);
	return 0;
      }

    # Check each one of the auth servers in turn.  If any one
    # of them succeeds then the user is logged in.
    #
    my $auth_servers = $self->auth_servers;

    if ( !defined $auth_servers and $auth_servers )
      {
	$self->is_authenticated(undef);
	return 0;
      }

    # Handle a single authorization server.
    #
    if ( ref($auth_servers) ne 'ARRAY' )
      {
	$auth_servers = [ $auth_servers ];
      }

    foreach my $ldap_server ( @{$self->auth_servers} )
      {
	my %ld = $self->setup_ldap_auth( $ldap_server, $username, $password );
	$ld{conn} =  new Mozilla::LDAP::Conn($ld{host}, $ld{port}, $ld{bind}, $ld{pswd});
	if ( $ld{conn} )
	  {
	    $ld{conn}->close;
	    $self->register_username($username);
	    $self->is_authenticated(1);
	    return 1;
	  }
      }

    $self->is_authenticated(undef);
    return 0;
}

# For testing at a separate point.
#
# $session->authenticate( $username, $password );
# if ( $session->is_authenticated ) { ... }
#

=item CGI::LDAPSession::authenticate

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

sub authenticate($$$)
  {
    my ( $self, $username, $password ) = @_;
    if ( $self->authenticated( $username, $password ) )
      {
	$self->set_passkey( $username );
	$self->set_login_cookie( $username );
      }
  }

##############################################################
#
# Wrapper for CGI.pm's header function which transparently
# handles creation of the cookie.
#

sub header_args_with_cookie($@)
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

    carp "Processed args are ".join(',',@processed_args);
    return @processed_args;
  }


=item CGI::LDAPSession::header

Acts just like CGI.pm's header function, but it injects
the authentication cookie.

If you are using CGI::LDAPSession::CGI then this function will not be
used.  If you are using CGI.pm directly then call this function instead
of CGI.pm's header method.

  print $session->header;
  print $cgi->start_html( 'my html' );
  ...

=back

=cut

sub header($@)
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
    carp "LDAPSession->header reads: $header";
    return $header;
  }

######################
#                    #
# Some MySQL-Related #
#     Functions      #
#                    #
######################


sub ConnectToDatabase($)
  {
    my $self = shift;
    if ( !defined $self->dbi )
      {
        my $dbi = DBI->connect( $self->dbi_dn, $self->dbi_username, $self->dbi_password );
	if ( !$dbi )
	  {
            croak "Can't connect to database server for cookie handling.";
	  }
	$self->dbi( $dbi );
      }
    
    return 0;
}

sub DisconnectDatabase($)
  {
    my ($self) = @_;
    if ( $self->dbi )
      {
        $self->dbi_statement->finish if $self->dbi_statement;
        $self->dbi->disconnect;
      }

    # Close everyting up no matter what the state of the
    # dbi connection.
    #
    $self->dbi( undef );
    $self->dbi_statement( undef );

    return 0;
}

sub FinishAnyExistingStatement($)
  {
    my ($self) = @_;
    if ( $self->dbi and $self->dbi_statement )
      {
        $self->dbi_statement->finish;
      }
    $self->dbi_statement( undef );
  }

sub SendSQL($$)
  {
    my ($self,$query) = @_;

    # Never do anything unless we have an active dbi connection.
    #
    if ( !defined $self->dbi )
      {
	croak "Programmer error:  Tried to use SendSQL without first calling ConnectDB.";
      }
    my $dbi = $self->dbi;

    # Always attempt to close out any existing statements.
    #
    $self->FinishAnyExistingStatement;

    my $statement = $dbi->prepare( $query );
    $statement->execute;
    if ( !$statement )
      {
	$statement->finish;
	croak "Database access error: $DBI::err: $DBI::errstr\n";
      }
    $self->dbi_statement( $statement );

    # Clear prefetch.
    #
    $self->dbi_prefetch( undef );
}

sub MoreSQLData($)
  {
    my ($self) = @_;
    if (!defined $self->dbi)
      {
        croak "Programmer Error: Attempted to get data from a closed DBI connection.\n ".
	      "This is not supported.\n";
      }

    if (defined $self->dbi_prefetch)
      {
        return 1;
      }

    # If the connection is not open, then we don't do anything.
    #
    if ( !defined $self->dbi_statement )
      {
	return 0;
      }

    my $prefetch = $self->dbi_statement->fetchrow_arrayref;
    $self->dbi_prefetch( $prefetch );

    if ( defined $prefetch )
      {
	return 1;
      }
    else
      {
        if ( !defined $self->dbi_statement )
	  {
	    croak "Assertion Failure:  Should never attempt to finish a DBI ".
	          "statement which has already been closed.";
	  }
	$self->FinishAnyExistingStatement;
	return 0;
      }

}

sub FetchSQLData($)
  {
    my $self = shift;
    if (!defined $self->dbi)
      {
        croak "Programmer Error: Attempted to get data from a closed DBI connection.\n ".
	      "This is not supported.\n";
      }

    # Return a prefetch value if it exists.
    #
    if (defined $self->dbi_prefetch )
      {
	my $result = $self->dbi_prefetch;
	$self->dbi_prefetch( undef );
	return @{$result};
      }

    # Check for a valid statement and results before attempting to
    # retreive them.
    #
    if (!defined $self->dbi_statement)
      {
        croak "Programmer Error: Attempted to get data from a DBI connection which has \n".
	      "no active statement.\n";
      }

    return $self->dbi_statement->fetchrow_array;
}


sub FetchOneColumn($)
  {
    my ($self) = @_;
    my @row = $self->FetchSQLData();
    return $row[0];
  }

=item CGI::LDAPSession::user_exists

Internal function.  Checks the database to see if a user has an existing
record within the cookie table.  True if the cookie table contains
an entry for the username, and false if it does not.

  if ( $self->user_exists( $username ) )
    {
      ... perform action for defined user ...
    }

=cut

sub user_exists($$)
  {
    my ($self,$username) = @_;
    
    my $cookie_table = $self->cookie_table;
    my $user_column = $self->user_column;
    my $cookie_column = $self->cookie_column;
    my $passkey_column = $self->passkey_column;

    $self->ConnectToDatabase;
    $self->SendSQL("SELECT count($user_column) FROM $cookie_table WHERE $user_column='$username'");
    my $user_exists = 0;
    if ( $self->MoreSQLData )
      {
	$user_exists = $self->FetchOneColumn == 1;
      }
    $self->DisconnectDatabase;
    return $user_exists;
  }


=item CGI::LDAPSession::register_username($$)

Internal function.  Creates an entry for the specified user within the cookie table.

  if ( ! $self->user_exists( $username ) )
    {
      $self->register_username( $username );
    }

=cut

sub register_username($$)
  {
    my ($self,$username) = @_;
    return unless $self->register;
    return if $self->user_exists($username);

    my $cookie_table = $self->cookie_table;
    my $user_column = $self->user_column;
    my $cookie_column = $self->cookie_column;
    my $passkey_column = $self->passkey_column;

    $self->ConnectToDatabase;
    $self->SendSQL("INSERT INTO $cookie_table ( $user_column ) VALUES ( '$username' )");
    $self->DisconnectDatabase;
  }


=item CGI::LDAPSession::login_cookie($$$)

Internal function.  Returns the cookie string for the current session. The
expiration time is a unix timestamp as returned by the function time(). The
expiration time is not a lifetime in seconds.

  my $cookie_string = $self->login_cookie( $cookie_name, $expiration_time );

=cut

sub login_cookie($$$)
  {
    my ($self,$cookie_value,$expiration_time) = @_;
    my $datetimestr = time2str("%a, %e-%b-%Y %X GMT", $expiration_time, 'GMT');
    my $cgi = $self->cgi;
    my $cookie = $cgi->cookie( -name=>$self->cookie_logged_in,
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
=item CGI::LDAPSession::set_login_cookie($;$)

Sets the login cookie for an authenticated session.  If a username
is not specified then it pulls the username corresponding to the
current cookie and passkey combination.

   $self->set_login_cookie( $username );

   ..or..

   $self->set_login_cookie();

=cut

sub set_login_cookie($;$)
  {
    my ($self) = shift;
    
    my $cookie_table = $self->cookie_table;
    my $user_column = $self->user_column;
    my $cookie_column = $self->cookie_column;
    my $passkey_column = $self->passkey_column;

    $self->ConnectToDatabase;
    
    # Get user ID.  Either from the command line or from
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
        my $current_cookie = $self->cgi->cookie( $self->cookie_logged_in );
	$self->SendSQL("SELECT $user_column FROM $cookie_table WHERE $cookie_column='$current_cookie'");
	if (!$self->MoreSQLData)
	  {
	    croak "Error: Could not read user name from cookie table.\n";
	  }
        $user_id = $self->FetchOneColumn;
      }
    
    my $r = int(rand 999999)+1;
    my $cookie_value = $user_id.$r;
    $self->SendSQL("UPDATE $cookie_table SET $cookie_column='$cookie_value' WHERE $user_column='$user_id'");
    $self->DisconnectDatabase;
    
    # Create cookie.
    #
    my $expiration_time = time + $self->cookie_expiration;
    my $cookie = $self->login_cookie( $cookie_value, $expiration_time );
    $self->cookie( $cookie );

    # SUCCESS
    #
    return 0;
  }


=item CGI::LDAPSession::refresh_login_cookie($)

Resets the expiration time for the current cookie.

  $self->refresh_login_cookie();

=cut

sub refresh_login_cookie($)
  {
    my ($self) = @_;
    my $cookie_value = $self->cgi->cookie($self->cookie_logged_in);
    my $expire = time + $self->cookie_expiration;
    my $cookie = $self->login_cookie( $cookie_value, $expire );
    $self->cookie( $cookie );
  }


=item CGI::LDAPSession::username($)

Pulls the username for the current cookie/passkey pair from
the database.

   my $username = $self->username();

=cut

sub username($)
#
# Gets the user ID for the current session.
#
# my $username = $session->username;
#
  {
    my ( $self ) = @_;

    my $cookie_table = $self->cookie_table;
    my $user_column = $self->user_column;
    my $cookie_column = $self->cookie_column;
    my $passkey_column = $self->passkey_column;


    my $cookie = $self->cgi->cookie( $self->cookie_logged_in );
    my $passkey = $self->passkey;

    return undef unless( defined $cookie and defined $passkey );

    $self->ConnectToDatabase;
    $self->SendSQL("SELECT $user_column FROM $cookie_table WHERE $cookie_column='$cookie' and $passkey_column='$passkey'");
    return undef unless $self->MoreSQLData;
    my $username = $self->FetchOneColumn;
    $self->DisconnectDatabase;

    return $username;
  }

#
# Create and assign the passkey from the database
#
=item CGI::LDAPSession::set_passkey($;$);

Sets the passkey for the current session, and writes it into the
backing store.  The passkey is chosen randomly.  The can either be
specified within the call, or if the passkey and cookie are already set
it can be extracted automatically by the session.

   $self->set_passkey( $username );

   ..or..

   $self->set_passkey();

=cut

sub set_passkey($;$)
  {
    my ($self) = shift;

    my $pass = int(rand 9999999)+1;

    my $cookie_table = $self->cookie_table;
    my $user_column = $self->user_column;
    my $cookie_column = $self->cookie_column;
    my $passkey_column = $self->passkey_column;

    $self->ConnectToDatabase;

    # Set passkey based either on the specified username, or
    # upon the current login cookie.
    #
    if ( @_ )
      {
	my $user_id = shift;
	$user_id = defined $user_id ? $user_id : "";
	$self->SendSQL("UPDATE $cookie_table SET $passkey_column='$pass' WHERE $user_column='$user_id'");
      }
    else
      {
        my $cookie = $self->cgi->cookie( $self->cookie_logged_in );
	$self->SendSQL("UPDATE $cookie_table SET $passkey_column='$pass' WHERE $cookie_column='$cookie'");
      }
    $self->DisconnectDatabase;

    $self->passkey( $pass );

    # SUCCESS
    #
    return 0;
  }

=item CGI::LDAPSession::logout_cookie($)

Returns a login_cookie which has expired.  (Expiration date
is set to epoch.)

    my $cookie = $self->logout_cookie();

=cut

sub logout_cookie($)
  {
    my ($self) = @_;
    my $datetimestr = "Thu, 01-Jan-2000 00:00:01 GMT";
    my $cgi = $self->cgi;
    my $cookie = $cgi->cookie( -name=>$self->cookie_logged_in,
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
=item CGI::LDAPSession::set_logout_cookie($)

Expires the cookie in the backing store.

    my $cookie = $self->set_logout_cookie();

=cut

sub set_logout_cookie($)
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
=item CGI::LDAPSession::check_cookie($)

Returns the cookie for this session if it exists.  If a
cookie does not exist then it returns nothing.

    my $login_cookie = $self->check_cookie();

=cut

sub check_cookie($)
  {
    my ($self) = @_;
    return $self->cgi->cookie($self->cookie_logged_in);
  }



#######################################################################################
#
# An LDAP server
#
package CGI::LDAPSession::LDAPServer;
use strict;

sub new($;@)
  {
    my ( $type ) = shift;
    my %args = @_;

    my $self = {};
    bless $self, $type;

    # set other parameters if needed.
    #
    $self->host( $args{'-host'} ) if $args{'-host'};
    $self->port( $args{'-port'} ) if $args{'-port'};
    $self->root( $args{'-root'} ) if $args{'-root'};
    $self->base( $args{'-base'} ) if $args{'-base'};
    $self->bind( $args{'-bind'} ) if $args{'-bind'};

    return $self;
  }

sub host($;$) { my $self=shift; @_ ? $self->{host}=shift : $self->{host}; }
sub port($;$) { my $self=shift; @_ ? $self->{port}=shift : $self->{port}; }
sub root($;$) { my $self=shift; @_ ? $self->{root}=shift : $self->{root}; }
sub base($;$) { my $self=shift; @_ ? $self->{base}=shift : $self->{base}; }
sub bind($;$) { my $self=shift; @_ ? $self->{bind}=shift : $self->{bind}; }

sub set_mozilla_LDAP_args_in($$)
  {
    my ( $self, $args ) = @_;

    $args->{host} = $self->host;
    $args->{port} = $self->port;
    $args->{root} = $self->root;
    $args->{base} = $self->base;
    $args->{bind} = $self->bind;

    return $args;
  }


#######################################################################################
#
# A CGI wrapper which manages session information.
#

package CGI::LDAPSession::CGI;
use CGI;
use CGI::Carp;

use vars qw( @ISA );

@ISA = qw( CGI );

my %_params = ( -errors => __PACKAGE__.".errors",
		-messages => __PACKAGE__.".messages",
	        -session => __PACKAGE__.".session", );
   
sub errors($;$) { _param( shift, "-errors", @_ ); }
sub messages($;$) { _param( shift, "-messages", @_ ); }
sub session($;$)
  {
    my $self = shift;
    if ( @_ )
      {
	my $session = shift;
	#
	# If someone is unsetting the session then @_ will be
	# defined, but $session will not.  In this case we
	# skip setting the 'used_with_custom_cgi' flag.
	#
	$session->used_with_custom_cgi( 1 ) if defined $session ;
	_param( $self, "-session",  $session );
      }
    else
      {
	return _param( $self, "-session" );
      }
  }

sub _param($@)
  {
    my $self = shift;
    if ( scalar @_ == 1 )
      {
	my $field = shift;
	my $slot = $_params{$field};
	croak "Programmer Error: $field is not a known parameter" unless defined $slot;
	return $self->{$slot};
      }
    else
      {
	while( my $field = shift )
	  {
	    my $slot = $_params{$field};
	    croak "Programmer Error: $field is not a known parameter" unless defined $slot;
	    $self->{$slot} = shift;
	  }
      }
  }

sub set($@) { _param(shift,@_); }

sub add_error($$)
  {
    my ( $self, $error ) = @_;
    push @{ $self->errors}, $error ;
  }

sub has_errors($) { return scalar @{shift->errors}; }

sub add_message($$)
  {
    my ( $self, $message ) = @_;
    push @{$self->messages}, $message;
  }

sub has_messages($) { return scalar @{shift->messages}; }

sub new($;)
  {
    my $type = shift;
    my $self = $type->SUPER::new;
    $self->errors([]);
    $self->messages([]);
    return $self;
  }

sub header($;@)
  {
    my $self = shift;
    my $header;
    if ( defined $self->session and $self->session )
      {
	$header = $self->SUPER::header( $self->session->header_args_with_cookie(@_) );
      }
    else
      {
	$header = $self->SUPER::header(@_);
      }
    carp $header;
    return $header;
  }

sub end_html($;)
  {
    my $self = shift;
    if ( defined $self->session and $self->session )
      {
	$self->session(undef);
      }
    return $self->SUPER::end_html(@_);
  }

sub end_form($;@)
  {
    my $self = shift;
    my $out = "";

    # Inject hidden field with passkey if it exists.
    #
    if ( defined $self->session and $self->session )
      {
	my $session = $self->session;
	my $passkey = $session->passkey;
	my $passkey_name = $session->passkey_name;
	if ( defined $passkey and $passkey )
	  {
	    $out .= qq(<input type=hidden name="$passkey_name" value="$passkey">\n);
	  }
      }
    $out .= $self->SUPER::end_form(@_);
    return $out;
  }
       
sub errors_as_html($)
  {
    my $self = shift;
    return undef unless $self->has_errors;
    my $out .= qq(<ul>\n);
    foreach my $error ( @{$self->errors} )
      {
	$out .= qq(  <li><font color="#ff0000">$error</font></li>\n);
      }
    $out .= qq(</ul>\n);
    return $out;
  }
	       
sub messages_as_html($)
  {
    my $self = shift;
    return undef unless $self->has_messages;
    my $out .= qq(<ul>\n);
    foreach my $message ( @{$self->messages} )
      {
	$out .= qq(  <li>$message</li>\n);
      }
    $out .= qq(</ul>\n);
    return $out;
  }

1;

__END__

