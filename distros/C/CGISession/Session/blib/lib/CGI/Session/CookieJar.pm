#!/usr/local/bin/perl5
#

package CGI::Session::CookieJar;

use Carp;

=item CGI::Session::CookieJar

An abstract data store for cookies.

The general usage is as follows:

my $cookiejar;
$cookiejar = new CGI::Session::CookieJar::YOUR_JAR_HERE( PARAMETERS );
$cookiejar->open();
...
... cookie operations
...
$cookiejar->close();


Most functions manipulating cookies use "queries" to specify the
cookies which will be operated upon.  These queries are references to
associative arrays.  The keys indicate variables which will be
compared, and the values specify the query operations. These
intersection of all the results determines which ones will be
selected.

Here are examples of simple queries:

{ user => "bob" } selects all cookies with the user value of "bob"

{ expiration => "<".time() } selects all cookies which have already
                             expired

{ expiration => ">".time() } selects all cookies which have not
                             expired

{ cookie_name => "$cookie" } selects all cookies which are named $cookie

{ passkey => "435765" } selects all cookies which have the passkey value
                        of "435765"


{ user => "bob", passkey => "6578" } selects all cookies which have the user
                                     "bob" and the passkey set to "6578"

There is no way to select a union of search results.

=cut

=item CGI::Session::CookieJar::open

$cookiejar->open();

Opens up the cookie jar.  This must be called before any operations
can take place.  When you are through with the cookie jar the close
operation me be called.

=cut

sub open { my $p=__PACKAGE__; croak "The $p::open operation must be defined."; }


=item CGI::Session::CookieJar::close

$cookiejar->close;

Closes a previously opened cookie jar.  This must be done before your program ends.

=cut

sub close { my $p = __PACKAGE__; croak "The method $p::close must be defined."; }


=item CGI::Session::CookieJar::contains

Determines if a session contains a given cookie.

my $time = time;
my %query = ( user=>'bob',
	      cookie_name=>'3476dfgh', 
	      passkey=>'23438',
	      expiration=>'>$time' );

my $has_cookie = $cookie_jar->contains( -query => \$query );

=cut

sub contains { my $p=__PACKAGE__; croak "$p::contains is not implemented, but it must be."; };




=item CGI::Session::CookieJar::cookie

Retreives a cookie from the cookie jar using a specified query. If no
cookie is found then it returns 'undef'.

By default all cookie fields are returned as an array of hashes .  If
your application potentially contains large 'server_side_data' fields
this may not be what you want.  In this case cases you can specify
that the server_side_data field will not be returned by setting the
-omit_server_side_data option to a true value.

my $time = time;
my %query = ( user=>'bob',
	      cookie_name=>'3476dfgh', 
	      passkey=>'23438',
	      expiration=>">$time" );

my $cookie = $cookie_jar->cookie( -query => \%query );

if ( !defined $cookie ) { croak "There is no such cookie."; }

...or...

my @sessions = $cookie_jar->session( -query => \%query,
				     -omit_server_side_data=>1 );
 
=cut

sub session { my $p=__PACKAGE__; croak "$p::session is not implemented, but it must be."; };



=item CGI::Session::CookieJar::delete

Deletes the specified cookies from the cookie jar. 

my $time = time;
my %query = ( expiration=>'<$time' );
$cookie_jar->delete( -query => \$query );

=cut

sub delete { my $p=__PACKAGE__; croak "$p::delete is not implemented, but it must be."; };




=item CGI::Session::CookieJar::set_session

Sets the session variables for a previously created user entry.  The
user entry must already exist.  If it does not exist then it must
be created with CGI::Session::CookieJar::register_user.

The 'user' field is required for the c

my $time = time;
my %session = ( user=>'bob',
	       cookie_name=>'3476dfgh', 
	       passkey=>'23438',
	       expiration=>'$time',
	       server_data=>$data );

my $cookie_jar->set_session( -session => \%session );

=cut

sub set_session { my $p=__PACKAGE__; croak "$p::set_session is not implemented, but it must be."; };



=item CGI::Session::CookieJar::register_user

Creates an entry for the specified user within the cookie jar. Attempting
to register a user which does not exist will result in an error.

  if ( ! $cookie_jar->contains( -user=>$username ) )
    {
      $cookie_jar->register_user( $username );
    }

=cut


=item CGI::Session::CookieJar::version

Returns the version of CGI::Session that was used to create this 
data store.

my $version => $cookie_jar->version();

=cut

sub version { my $p=__PACKAGE__; croak "$p::version is not implemented, but it must be."; };


=item CGI::Session::CookieJar::create_cookie_jar

Creates a new cookie jar.  For a database cookie jar this would create
the necessary tables.  For a file based cookie jar this might set up
the required directory structure.

This should only be necessary once.

$cookie_jar->create_cookie_jar();

=cut

sub create_cookie_jar { my $p=__PACKAGE__; croak "$p::create_cookie_jar is not implemented, but it must be."; };


=item CGI::Session::CookieJar::destroy_cookie_jar

Destroys an existing cookie jar.  For a database cookie jar this would
drop all of the tables.  For a file based cookie jar this might
delete all the existing files and directories.

This should only be necessary once.

$cookie_jar->destroy_cookie_jar();

=cut

sub destroy_cookie_jar { my $p=__PACKAGE__; croak "$p::destroy_cookie_jar is not implemented, but it must be."; };




=item CGI::Session::CookieJar::error

If the previous cookie operation resulted in an error then
the value of this error will be found here.  If the operation
did not result in an error then this will return 'undef'.

Calling error() does not alter the value.  Each cookie jar object has
it's own error state, which is independent of the backend database.

my $error = $cookie_jar->error();

=cut

sub error { my $p=__PACKAGE__; croak "$p::error is not implemented, but it must be."; };



1;















