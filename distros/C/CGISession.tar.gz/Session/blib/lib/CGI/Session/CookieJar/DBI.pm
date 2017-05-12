#!/usr/local/bin/perl5
#

package CGI::Session::CookieJar::DBI;

use Carp;
use Time::Local;
use CGI::Session::CookieJar;

use vars qw( @ISA );
push @ISA, qw( CGI::Session::CookieJar );

# Mechanisms for managing databases.
#
my $DB_MYSQL='DB_MYSQL';
sub db_type { _param( shift, '-db_type', @_ ); }
sub use_mysql { shift->db_type( $DB_MYSQL ); }
sub db { _param( shift, '-db', @_ ); }

my $I_USER = 'user';
my $I_COOKIE = 'cookie';
my $I_COOKIE_NAME = 'cookie_name';
my $I_EXPIRATION = 'expiration';
my $I_PASSKEY = 'passkey';
my $I_SERVER_SIDE_DATA = 'server_side_data';


sub new
  {
    my ( $type ) = shift;
    my $self = {};
    bless $self, $type;
    $self->use_mysql;
    $self->set( -cookie_table => 'sessions',
		-user_column => 'user',
		-cookie_column => 'cookie',
                -cookie_name_column => 'cookie_name',
		-passkey_column => 'passkey',
		-login_expiration_column => 'expiration',
		-server_side_data_column => 'data',
		-host => 'localhost', );

    $self->set(@_) if @_;
    return $self;
  }


=name CGI::Session::CookieJar::DBI

A DBI Based CookieJar.

The general usage is as follows:

my $cookiejar;
$cookiejar = new CGI::Session::CookieJar::DBI();
$cookiejar->use_mysql();
$cookiejar->user( 'MyMYSQLUser' );
$cookiejar->password( 'lijlkdfsf' );
$cookiejar->database( 'DBI' );
$cookiejar->host( 'my.dbi.server.myco.com' );
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

{ cookie_name => "$cookie_name" } selects all cookies which are named $cookie_name

{ cookie => "$cookie" } selects all cookies which have the value $cookie

{ passkey => "435765" } selects all cookies which have the passkey value
                        of "435765"


{ user => "bob", passkey => "6578" } selects all cookies which have the user
                                     "bob" and the passkey set to "6578"

There is no way to select a union of search results.

=cut



=item CGI::Session::CookieJar::DBI::open

$cookiejar->open();

Opens up the cookie jar.  This must be called before any operations
can take place.  When you are through with the cookie jar the close
operation must be called.

=cut

sub open
  {
    my $self = shift;
    $self->error( undef );

    my $db = $self->db;

    if ( $db )
      {
# Open should be safe to be called more than once.
#
#	$self->error( "Attempted to open a database connection without closing the previous one." );
	return;
      }

    if ( $self->db_type eq $DB_MYSQL )
      {
	my $host = $self->host;
	my $database = $self->database;
	$db = DBI->connect( "DBI:mysql:$database".($host ? ":$host" : ""),  $self->user, $self->password );
	if ( !$db )
	  {
	    $self->error( sprintf( "Could not connect to backend database: %s, %s", $DBI::err, $DBI::errstr ) );
	    return;
	  }
	$self->db( $db );
      }
    else
      {
	$self->error( "Could not determine the type of database that should be connected to." );
      }
  }

=item CGI::Session::CookieJar::DBI::close

$cookiejar->close;

Closes a previously opened cookie jar.  This must be done before your program ends.

=cut

sub close
  {
    my $self=shift;
    $self->error( undef );
    return unless defined $self->db();
    $self->db->disconnect;
    $self->db( undef );
  }


=item CGI::Session::CookieJar::DBI::contains

Determines if a session contains a given cookie.

my $time = time;
my %query = ( -user=>'bob',
              -cookie_name=>'sdfljkjj48jf',
	      -cookie=>'3476dfgh', 
	      -passkey=>'23438',
	      -expiration=>'>$time' );

my $has_cookie = $cookie_jar->contains( -query => \$query );

=cut

sub contains
  {
    my ( $self ) = shift;
    $self->error(undef);
    return unless $self->has_valid_connection;
    my $db = $self->db;
    my $query = $self->build_where_query(@_);
    my $select = sprintf( "SELECT count(*) FROM %s WHERE $query", $self->cookie_table );
    my $statement = $db->prepare( $select ); 
    my $rows = $statement->execute();
    if ( $self->db_error( "Encountered DBI error: %s" ) )
      {
	$statement->finish;
	return;
      }
    if ( $self->db_type eq $DB_MYSQL and $rows != 1 )
      {
	$self->error( "SQL should have generated one result, but it resulted in $rows" );
	$statement->finish;
	return;
      }
    my @count = $statement->fetchrow_array();
    my $matches = $count[0];
    $statement->finish;
    return $matches != 0;
  }
 

=item CGI::Session::CookieJar::DBI::cookie

Retreives a cookie from the cookie jar using a specified query. If no
cookie is found then it returns 'undef'.

By default all cookie fields are returned.  If your application potentially
contains large 'server_data' fields this may not be what you want.  In these
cases you can specify a list of fields to omit.  These fields are passed in
via array reference.

my $time = time;
my %query = ( -user=>'bob',
              -cookie_name=>'myApp7887',
	      -cookie=>'3476dfgh', 
	      -passkey=>'23438',
	      -expiration=>">$time" );

my $sessions = $cookie_jar->session( -query => \%query );

if ( !defined $cookie ) { croak "There is no such cookie."; }

...or...

my $cookie = $cookie_jar->session( -query => \%query,
				   -omit_server_side_data => 1 );
 
=cut

sub session
  {
    my $self = shift;
    my %args = ( ref $_[0] eq 'HASH' ) ? %{$_[0]} : @_ ;
    $self->error(undef);
    return unless $self->has_valid_connection;
    return unless defined $args{-query};
    my $query = $self->build_where_query( $args{-query} );
    my $db = $self->db;
    my $user_column = $self->user_column;
    my $cookie_column = $self->cookie_column;
    my $cookie_name_column = $self->cookie_name_column;
    my $passkey_column = $self->passkey_column;
    my $login_expiration_column = $self->login_expiration_column;
    my $server_side_data_column = $self->server_side_data_column;
    my %columns = ( $user_column=>1,
                    $cookie_column=>1,
                    $cookie_name_column=>1,
                    $passkey_column=>1,
                    $login_expiration_column=>1,
                    $server_side_data_column=>1 );
    if ( defined $args{-omit_server_side_data} )
      {
        delete $columns{$server_side_data_column};
      }
    my $select_columns = join( ', ', ( keys %columns ) );
    my $select = sprintf( "SELECT $select_columns FROM %s WHERE $query", $self->cookie_table );
    my $statement = $db->prepare( $select );
    my $rows = $statement->execute();
    if ( $self->db_error( "Encountered error while attempting to retreive a cookie from ".($self->cookie_table).': %s' ) )
      {
        $statement->finish;
        return;
      }
    my @results; 
    while( my $row = $statement->fetchrow_hashref )
      {
        my $session = {};
        $session->{$I_COOKIE} = $row->{$cookie_column} if defined $row->{$cookie_column};
        $session->{$I_COOKIE_NAME} = $row->{$cookie_name_column} if defined $row->{$cookie_name_column};
        $session->{$I_USER} = $row->{$user_column} if defined $row->{$user_column};
        $session->{$I_PASSKEY} = $row->{$passkey_column} if defined $row->{$passkey_column};
        $session->{$I_EXPIRATION} = $self->timestamp_to_time($row->{$login_expiration_column}) if defined $row->{$login_expiration_column};
        $session->{$I_SERVER_SIDE_DATA} = $row->{$server_side_data_column} if defined $row->{$server_side_data_column};
        push @results, $session;
      }
    $statement->finish;
    return \@results; 
  }


=item CGI::Session::CookieJar::DBI::delete

Deletes the specified cookies from the cookie jar. 

my $time = time;
my %query = ( -expiration=>'<$time' );
$cookie_jar->delete( %query );


=cut

sub delete
  {
    my $self = shift;
    return unless $self->has_valid_connection;
    $self->error(undef);
    my $query = $self->build_where_query( @_ );
    my $db = $self->db;
    $db->do( "DELETE FROM $db->cookie_table WHERE $query" );
    $self->db_error( "Database error while attempting to delete from ".($db->cookie_table).": %s" );
  }



=item CGI::Session::CookieJar::DBI::set_session

Creates a new session

my $time = time;
my %session = ( user=>'bob',
	        cookie_name=>'3476dfgh', 
	        passkey=>'23438',
	        expiration=>'$time',
	        server_side_data=>$data );

my $cookie_jar->set_session( -session => \$cookie );

=cut

sub set_session
  {
    my $self = shift;
    $self->error(undef);
    my %args = ( ref $_[0] eq 'HASH' ) ? %{$_[0]} : @_ ;
    return unless $self->has_valid_connection;
    return unless defined $args{-session};
    my $db = $self->db;
    my %session = %{$args{-session}};

    my $user_column = $self->user_column;
    my $cookie_column = $self->cookie_column;
    my $cookie_name_column = $self->cookie_name_column;
    my $passkey_column = $self->passkey_column;
    my $login_expiration_column = $self->login_expiration_column;
    my $server_side_data_column = $self->server_side_data_column;

    croak "Set_session requires either a username or cookie to be specified in the session." unless $session{$I_USER} or $session{$I_COOKIE} ;

    my ( @assignment_clause, $key, $key_column );

    my %key;
    if ( $session{$I_USER} )
      {
	$key{-user} = $session{$I_USER};
	push( @assignment_clause, "$cookie_column = ".($db->quote($session{$I_COOKIE}))) if defined  $session{$I_COOKIE};
      }
    else
      {
	$key{-passkey} = $session{$I_KEY};
        $key{-cookie} = $session{$I_COOKIE};
	push( @assignment_clause, "$user_column = ".($db->quote($session{$I_USER}))) if defined  $session{$I_USER};
      }
    if ( $session{$I_COOKIE_NAME} )
      {
        $key{-cookie_name} = $session{$I_COOKIE_NAME};
        push( @assignment_clause, "$cookie_name_column = ".($db->quote($session{$I_COOKIE_NAME})) );
      }
    push( @assignment_clause, "$passkey_column = ".($db->quote($session{$I_PASSKEY}))) if defined  $session{$I_PASSKEY};
    push( @assignment_clause, "$login_expiration_column = ".($db->quote( $self->time_to_timestamp($session{$I_EXPIRATION})))) if defined  $session{$I_EXPIRATION};
    push( @assignment_clause, "$server_side_data_column = ".($db->quote($session{$I_SERVER_SIDE_DATA}))) if defined  $session{$I_SERVER_SIDE_DATA};
    my $set_list = join( ', ', @assignment_clause );

    my $where = $self->build_where_query( \%key );
    my $update = sprintf( 'UPDATE %s SET %s WHERE %s',
			  $self->cookie_table,
			  $set_list,
			  $where );
    my $rows = $db->do( $update );
    return if $self->db_error( 'Update of session into '.($self->cookie_table).' failed: %s: '.$update );
    if ( $self->db_type eq $DB_MYSQL and $rows != 1 and $rows != 0 )
      {
	$self->error( "SQL statement should have created exactly one line, but $rows seem to have been created." );
      }
  }


sub time_to_timestamp
   {
      my( $self, $time ) = @_;
      my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = gmtime($time);
      $mon = $mon+1;
      $year = $year+1900;
      return sprintf( "%.4d%.2d%.2d%.2d%.2d%.2d", $year, $mon, $mday, $hour, $min, $sec );
  }

sub timestamp_to_time
  {
    my ( $self, $timestamp ) = @_;
    $timestamp =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;
    return timegm( $6, $5, $4, $3, ($2-1), ($1-1900) );
  }

sub db_error
  {
    my ( $self, $msg ) = @_;
    my $db = $self->db;
    if ( defined $db and $db->err )
      {
	my $error = ($db->err).', '.($db->errstr);
        $self->error( sprintf( $msg, $error ) );
	return 1;
      }
    return 0;
  }

=item CGI::Session::CookieJar::DBI::register_user

Creates an entry for the specified user within the cookie table.

  if ( ! $self->contains( -cookie_name=>$cookie_name, -user=>$username ) )
    {
      $self->register_user( $cookie_name, $username );
    }

=cut

sub register_user
  {
    my ( $self, $cookie_name, $username ) = @_;

    my $cookie_table = $self->cookie_table;
    my $user_column = $self->user_column;
    my $cookie_name_column = $self->cookie_name_column;

    $self->error(undef);
    return unless $self->has_valid_connection();
    my $db = $self->db;
    my $rows = $db->do(
                       sprintf( "INSERT INTO $cookie_table ( $cookie_name_column, $user_column ) VALUES ( %s, %s )",
                              $db->quote($cookie_name),
                              $db->quote($username) ) );
    return if $self->db_error( "Encountered error while attempting to create $username entry for the cookie name $cookie in $cookie_table: DBI Error: %s" );
    if ( $self->db_type eq $DB_MYSQL and $rows != 0 )
      {
	$self->error( "SQL statement should have created exactly one line, but $rows seem to have been created." );
      }
  }



=item CGI::Session::CookieJar::DBI::version

Returns the version of CGI::Session that was used to create this 
data store.

my $version => $cookie_jar->version();

=cut

sub version { return "0.0001"; }



=item CGI::Session::CookieJar::DBI::destroy_cookie_jar

Destroys an existing cookie jar.  For a database cookie jar this would
drop all of the tables.  For a file based cookie jar this might
delete all the existing files and directories.

This should only be necessary once.

$cookie_jar->destroy_cookie_jar();

=cut

sub destroy_cookie_jar
  {
    my ($self) = @_;

    my $cookie_table = $self->cookie_table;
    my $db = $self->db();
    $db->do( "DROP TABLE $cookie_table" );
  }




=item CGI::Session::CookieJar::DBI::error

If the previous cookie operation resulted in an error then
the value of this error will be found here.  If the operation
did not result in an error then this will return 'undef'.

Calling error() does not alter the value.  Each cookie jar object has
it's own error state, which is independent of the backend database.

my $error = $cookie_jar->error();

=cut

sub error { _param( shift, "-error", @_ ); }


# These are the legal parameters.
#
my %_params = ( -error => __PACKAGE__.".error",
		-cookie_table => __PACKAGE__.".cookie_table",
		-user_column => __PACKAGE__.".user_column",
		-passkey_column => __PACKAGE__.".passkey_column",
		-cookie_column => __PACKAGE__.".cookie_column",
		-cookie_name_column => __PACKAGE__.".cookie_name_column",
		-login_expiration_column => __PACKAGE__.".login_expiration_column",
		-server_side_data_column => __PACKAGE__.".server_side_data_column",
		-use_mysql => __PACKAGE__.".db_type",
		-database => __PACKAGE__.".database",
		-db_type => __PACKAGE__.".db_type",
		-db => __PACKAGE__.".db",
		-host => __PACKAGE__.".host",
		-user => __PACKAGE__.".user",
		-password => __PACKAGE__.".password", );


sub _param
  {
    my $self = shift;
    if ( scalar @_ == 1 )
      {
	my $field = shift;

	# Hack for db types.
	#
	if ( $field eq '-use_mysql' ) { return $db_type eq $DB_MYSQL; } 
	#
	my $slot = $_params{$field};
	croak "Programmer Error: $field is not a known parameter" unless defined $slot;
	return $self->{$slot};
      }
    else
      {
	while( my $field = shift )
	  {
	    my $slot = $_params{$field};

	    # Hack for db types
	    #
	    if ( $field eq '-use_mysql' ) { $self->use_mysql if shift; return; }   
	    #
	    croak "Programmer Error: $field is not a known parameter" unless defined $slot;
	    $self->{$slot} = shift;
	  }
      }
  }

sub set { _param(shift,@_); }

# Login/cookie table description.
#
=item CGI::Session::CookieJar::DBI::host

Accessor method.  The name of the host.

=cut

sub host { _param( shift, '-host', @_ ); }


=item CGI::Session::CookieJar::DBI::user

Accessor method.  The name of the user.

=cut

sub user { _param( shift, '-user', @_ ); }


=item CGI::Session::CookieJar::DBI::password

Accessor method.  The name of the password.

=cut

sub password { _param( shift, '-password', @_ ); }


=item CGI::Session::CookieJar::DBI::database

Accessor method.  The name of the database.

=cut

sub database { _param( shift, '-database', @_ ); }


=item Database tables

The names of the database tables.

=item CGI::Session::CookieJar::DBI::cookie_table

Accessor method.  The name of the cookie table.

=cut

sub cookie_table { _param( shift, '-cookie_table', @_ ); }


=item CGI::Session::CookieJar::DBI::user_column

Accessor method.  The column containing the usernames.

=cut

sub user_column { _param( shift, '-user_column', @_ ); }


=item CGI::Session::CookieJar::DBI::passkey_column

Accessor method.  The column containing the passkey.

=cut

sub passkey_column { _param( shift, '-passkey_column', @_ ); }


=item CGI::Session::CookieJar::DBI::cookie_name_column

Accessor method.  The column containing the name of the cookie.

=cut

sub cookie_name_column { _param( shift, '-cookie_name_column', @_ ); }


=item CGI::Session::CookieJar::DBI::cookie_column

Accessor method.  The column containing the cookie value.

=cut

sub cookie_column { _param( shift, '-cookie_column', @_ ); }


=item CGI::Session::CookieJar::DBI::login_expiration_column

Accessor method.  The expiration time for the cookie.  Currently not
used, but it will be used in the future.

=cut

sub login_expiration_column { _param( shift, '-login_expiration_column', @_ ); }


=item CGI::Session::CookieJar::DBI::server_side_data_column

Accessor method.  The name of the column containing server side data.

=cut

sub server_side_data_column { _param( shift, '-server_side_data_column', @_ ); }



=item CGI::Session::CookieJar::DBI::create_cookie_jar

  Creates the database tables that are described by a CGI::Session.

  my $session = new CGI::Session;
  $session->create_cookie_jar;
  exit;

  Fill out your CGI::Session just like your going to make
  a connection.  Call this routine, and voila!  Your database
  tables are created.

=cut

sub create_cookie_jar
  {
    my ($self) = @_;

    my $cookie_table = $self->cookie_table;
    my $user_column = $self->user_column;
    my $cookie_name_column = $self->cookie_name_column;
    my $cookie_column = $self->cookie_column;
    my $passkey_column = $self->passkey_column;
    my $expiration_column = $self->login_expiration_column;
    my $server_side_data_column = $self->server_side_data_column;

    my $db = $self->db();
    $db->do( <<EOSQL );
CREATE TABLE $cookie_table (
			    $user_column varchar(64),
                            $cookie_name_column varchar(64),
			    $cookie_column varchar(32),
			    $passkey_column bigint(20),
			    $expiration_column timestamp(14),
			    $server_side_data_column longblob )
EOSQL

  }


# Check to see if a valid connection has been established.  If it has not
# then this routine returns 0 and sets the error code.  If there is a true
# value then it returns true.
#
# This should be called in every user level routine just before it
# uses the value of $self->db();
#
sub has_valid_connection
  {
    my ( $self ) = @_;
    my $db = $self->db;
    if ( !defined $db ) 
      {
	$self->error( "A database connection must be established before this function is called." );
	return 0;
      }
    return 1;
  }

# Builds a query for use with in an SQL where clause. The query is passed as
# a hash.
#
# my $query = $jar->build_where_query( -user=>'bob' );
#
# Currently it the valid queries are:
#
# -cookie_name=>$cookie_name
# -user=>$username
# -cookie=>$cookie
# -passkey=>$passkey
#
# The resulting query returns the intersection of all the queried properties.
# If no queries are specified then it returns a query which will select _all_
# entries in the database. "$username_column IS NOT NULL"
#
sub build_where_query
  {
    my ( $self ) = shift;
    my %query = ( ref $_[0] eq 'HASH' ) ? %{$_[0]} : @_ ;
    my $db = $self->db;
    my @clauses; 
    if ( defined $query{-user} )
      {
	my $quoted_user = $db->quote( $query{-user} );
	push @clauses, ($self->user_column)." = $quoted_user";
      }
    if ( defined $query{-cookie} )
      {
	my $quoted_cookie = $db->quote( $query{-cookie} );
	push @clauses, ($self->cookie_column)." = $quoted_cookie";
      }
    if ( defined $query{-cookie_name} )
      {
	my $quoted_cookie = $db->quote( $query{-cookie_name} );
	push @clauses, ($self->cookie_name_column)." = $quoted_cookie";
      }
    if ( defined $query{-passkey} )
      {
	my $quoted_passkey = $db->quote( $query{-passkey} );
	push @clauses, ($self->passkey_column)." = $quoted_passkey";
      }
    if ( scalar @clauses )
      {
	return join( ' AND ', @clauses );
      }
    else
      {
	return ( ($self->user_column)." IS NOT NULL" );
      }
  }

1;














                                     
