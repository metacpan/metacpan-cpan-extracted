=head1 NAME

DBIx::SQLEngine::Driver - DBI Wrapper with Driver Subclasses

=head1 SYNOPSIS

B<DBI Wrapper>: Adds methods to a DBI database handle.

  $sqldb = DBIx::SQLEngine->new( $dbi_dsn, $dbi_user, $dbi_passwd );
  $sqldb = DBIx::SQLEngine->new( $dbh ); # or use your existing handle

  $dbh = $sqldb->get_dbh();              # get the wraped DBI dbh
  $sth = $sqldb->prepare($statement);    # or just call any dbh method

B<High-Level Interface:> Prepare and fetch in one call.

  $row_count = $sqldb->try_query($sql, \@params, 'get_execute_rowcount');
  $array_ary = $sqldb->try_query($sql, \@params, 'fetchall_arrayref');
  $hash_ary  = $sqldb->try_query($sql, \@params, 'fetchall_hashref');

B<Data-Driven SQL:> SQL generation with flexible arguments.

  $hash_ary = $sqldb->fetch_select( 
    table => 'students', where => { 'status'=>'minor' },
  );
  
  $sqldb->do_insert(
    table => 'students', 
    values => { 'name'=>'Dave', 'age'=>'19', 'status'=>'minor' },
  );
  
  $sqldb->do_update( 
    table => 'students', where => 'age > 20',
    values => { 'status'=>'adult' },
  );
  
  $sqldb->do_delete(
    table => 'students', where => { 'name'=>'Dave' },
  );

B<Named Definitions:> Pre-define connections and queries.

  DBIx::SQLEngine->define_named_connections(
    'test'       => 'dbi:AnyData:test',
    'production' => [ 'dbi:Mysql:our_data:dbhost', 'user', 'passwd' ],
  );

  DBIx::SQLEngine->define_named_queries(
    'all_students'  => 'select * from students',
    'delete_student' => [ 'delete * from students where id = ?', \$1 ],
  );

  $sqldb = DBIx::SQLEngine->new( 'test' );

  $hash_ary = $sqldb->fetch_named_query( 'all_students' );

  $rowcount = $sqldb->do_named_query( 'delete_student', $my_id );

B<Portability Subclasses:> Uses driver's idioms or emulation.

  $hash_ary = $sqldb->fetch_select( # uses database's limit syntax 
    table => 'students', order => 'last_name, first_name',
    limit => 20, offset => 100,    
  );
  
  $hash_ary = $sqldb->fetch_select( # use "join on" or merge with "where"
    table => ['students'=>{'students.id'=>\'grades.student'}=>'grades'],
    where => { 'academic_year'=>'2004' },
  );
  
  $hash_ary = $sqldb->fetch_select( # combines multiple query results
    union => [ { table=>'students', columns=>'first_name, last_name' },
	       { table=>'staff',    columns=>'name_f, name_l' }        ],
  );

  $sqldb->do_insert(                # use auto_increment/sequence column
    table => 'students', sequence => 'id',        
    values => { 'name'=>'Dave', 'age'=>'19', 'status'=>'minor' },
  );


=head1 DESCRIPTION

DBIx::SQLEngine::Driver objects are wrappers around DBI database handles which
add methods that support ad-hoc SQL generation and query execution in a single
call. Dynamic subclassing based on database server type enables cross-platform
portability.

For more information about this framework, see L<DBIx::SQLEngine/"DESCRIPTION">.

=cut

########################################################################

=head2 Driver Subclasses

The only methods that are actually provided by the DBIx::SQLEngine::Driver
package itself are the constructors like new(). All of the other
methods described here are defined in DBIx::SQLEngine::Driver::Default,
or in one of its automatically-loaded subclasses.

After setting up the DBI handle that it will use, the SQLEngine is reblessed
into a matching subclass, if one is available. Thus, if you connect a
DBIx::SQLEngine through DBD::mysql, by passing a DSN such as "dbi:mysql:test",
your object will automatically shift to being an instance of the
DBIx::SQLEngine::Driver::Mysql class. This allows the driver-specific
subclasses to compensate for differences in the SQL dialect or execution
ideosyncracies of that platform.

This release includes the following driver subclasses, which support the listed database platforms:

=over 10

=item Mysql

MySQL via DBD::mysql or DBD::ODBC (Free RDBMS)

=item Pg

PostgreSQL via DBD::Pg or DBD::ODBC (Free RDBMS)

=item Oracle

Oracle via DBD::Oracle or DBD::ODBC (Commercial RDBMS)

=item Sybase

Sybase via DBD::Sybase or DBD::ODBC (Commercial RDBMS)

=item Informix

Informix via DBD::Informix or DBD::ODBC (Commercial RDBMS)

=item MSSQL

Microsoft SQL Server via DBD::ODBC (Commercial RDBMS)

=item Sybase::MSSQL

Microsoft SQL Server via DBD::Sybase and FreeTDS libraries

=item SQLite

SQLite via DBD::SQLite (Free Package)

=item AnyData

AnyData via DBD::AnyData (Free Package)

=item CSV

CSV files via DBD::CSV (Free Package)

=back

To understand which SQLEngine driver class will be used for a given database
connection, see the discussion of driver and class names in L<DBIx::AnyDBD>.

The public interface of described below is shared by all of the driver
subclasses.  The superclass methods aim to produce and perform generic queries
in an database-independent fashion, using standard SQL syntax.  Subclasses may
override these methods to compensate for idiosyncrasies of their database
server or mechanism.  To facilitate cross-platform subclassing, many of these
methods are implemented by calling combinations of other methods, which may
individually be overridden by subclasses.

=cut

########################################################################

package DBIx::SQLEngine::Driver;

use strict;

use DBI;
use DBIx::AnyDBD;
use Class::MakeMethods;

########################################################################

########################################################################

=head1 DRIVER INSTANTIATION

These methods allow the creation of SQLEngine Driver objects connected to your databases.

=head2 Driver Object Creation

Create one SQLEngine Driver for each DBI datasource you will use.

B<Public Methods:> Call the new() method to create a Driver object with associated DBI database handle.

=over 4

=item new()

  DBIx::SQLEngine->new( $dsn ) : $sqldb
  DBIx::SQLEngine->new( $dsn, $user, $pass ) : $sqldb
  DBIx::SQLEngine->new( $dsn, $user, $pass, $args ) : $sqldb
  DBIx::SQLEngine->new( $dbh ) : $sqldb
  DBIx::SQLEngine->new( $cnxn_name ) : $sqldb
  DBIx::SQLEngine->new( $cnxn_name, @params ) : $sqldb

Based on the arguments supplied, invokes one of the below new_with_* methods and returns the resulting new object.

=back

B<Internal Methods:> These methods are called internally by new().

=over 4

=item new_with_connect()

  DBIx::SQLEngine::Driver->new_with_connect( $dsn ) : $sqldb
  DBIx::SQLEngine::Driver->new_with_connect( $dsn, $user, $pass ) : $sqldb
  DBIx::SQLEngine::Driver->new_with_connect( $dsn, $user, $pass, $args ) : $sqldb

Accepts the same arguments as the standard DBI connect method. 

=item new_with_dbh()

  DBIx::SQLEngine::Driver->new_with_dbh( $dbh ) : $sqldb

Accepts an existing DBI database handle and creates a new Driver object around it.

=item new_with_name()

  DBIx::SQLEngine::Driver->new_with_name( $cnxn_name ) : $sqldb
  DBIx::SQLEngine::Driver->new_with_name( $cnxn_name, @params ) : $sqldb

Passes the provided arguments to interpret_named_connection, defined below, and uses its results to make a new connection.

=back

=cut

sub new {
  my $class = shift;
  ref( $_[0] )                       ? $class->new_with_dbh( @_ ) : 
  $class->named_connections( $_[0] ) ? $class->new_with_name( @_ ) : 
				       $class->new_with_connect( @_ )
}

sub new_with_connect {
  my ($class, $dsn, $user, $pass, $args) = @_;
  $args ||= { AutoCommit => 1, PrintError => 0, RaiseError => 1 };
  DBIx::SQLEngine::Driver::Default->log_connect( $dsn ) 
	if DBIx::SQLEngine::Driver::Default->DBILogging;
  my $self = DBIx::AnyDBD->connect($dsn, $user, $pass, $args, 
						'DBIx::SQLEngine::Driver');
  return undef unless $self;
  $self->{'reconnector'} = sub { DBI->connect($dsn, $user, $pass, $args) };
  return $self;
}

sub new_with_dbh {
  my ($class, $dbh) = @_;
  my $self = bless { 'package' => 'DBIx::SQLEngine::Driver', 'dbh' => $dbh }, 'DBIx::AnyDBD';
  $self->rebless;
  $self->_init if $self->can('_init');
  return $self;  
}

sub new_with_name {
  my ($class, $name, @args) = @_;
  $class->new( $class->interpret_named_connection( $name, @args ) );
}

########################################################################

=head2 Named Connections

The following methods maanage a collection of named connection parameters.

B<Public Methods:> Call these methods to define connections.

=over 4

=item define_named_connections()

  DBIx::SQLEngine->define_named_connections( $name, $cnxn_info )
  DBIx::SQLEngine->define_named_connections( %names_and_info )

Defines one or more named connections using the names and definitions provided.

The definition for each connection is expected to be in one of the following formats:

=over 4

=item *

A DSN string which will be passed to a DBI->connect call. 

=item *

A reference to an array of a DSN string, and optionally, a user name and password. Items which should later be replaced by per-connection parameters can be represented by references to the special Perl variables $1, $2, $3, and so forth, corresponding to the order and number of parameters to be supplied. 

=item *

A reference to a subroutine or code block which will process the user-supplied arguments and return a connected DBI database handle or a list of connection arguments. 

=back

=item define_named_connections_from_text()

  DBIx::SQLEngine->define_named_connections_from_text($name, $cnxn_info_text)
  DBIx::SQLEngine->define_named_connections_from_text(%names_and_info_text)

Defines one or more connections, using some special processing to facilitate storing dynamic connection definitions in an external source such as a text file or database table. 

The interpretation of each definition is determined by its first non-whitespace character:

=over 4

=item * 

Definitions which begin with a [ character are presumed to contain an array definition and are evaluated immediately.

=item * 

Definitions which begin with a " or ; character are presumed to contain a code definition and evaluated as the contents of an anonymous subroutine. 

=item * 

Other definitions are assumed to contain a plain string DSN.

=back

All evaluations are done via a Safe compartment, which is required when this function is first used, so the code is fairly limited in terms of what actions it can perform. 

=back

B<Internal Methods:> The following methods are called internally by new_with_name().

=over 4

=item named_connections()

  DBIx::SQLEngine::Driver->named_connections() : %names_and_info
  DBIx::SQLEngine::Driver->named_connections( $name ) : $cnxn_info
  DBIx::SQLEngine::Driver->named_connections( \@names ) : @cnxn_info
  DBIx::SQLEngine::Driver->named_connections( $name, $cnxn_info, ... )
  DBIx::SQLEngine::Driver->named_connections( \%names_and_info )

Accessor and mutator for a class-wide hash mappping connection names to their definitions. Used internally by the other named_connection methods.

=item named_connection()

  DBIx::SQLEngine::Driver->named_connection( $name ) : $cnxn_info

Retrieves the connection definition matching the name provided. Croaks if no connection has been defined for that name. Used interally by the interpret_named_connection method.

=item interpret_named_connection()

  DBIx::SQLEngine::Driver->interpret_named_connection($name, @params) : $dbh
  DBIx::SQLEngine::Driver->interpret_named_connection($name, @params) : $dsn
  DBIx::SQLEngine::Driver->interpret_named_connection($name, @params) : @args

Combines the connection definition matching the name provided with the following arguments and returns the resulting connection arguments. Croaks if no connection has been defined for that name.

Depending on the definition associated with the name, it is combined with the provided parameters in one the following ways:

=over 4

=item *

A string. Any connection parameters are assumed to be the user name and password, and are simply appended and returned.

=item *

A reference to an array, possibly with embedded placeholders in the C<\$1> style described above. Uses clone_with_parameters() to make and return a copy of the array, substituting the connection parameters in place of the placeholder references. An exception is thrown if the number of parameters provided does not match the number of special variables referred to. 

=item *

A reference to a subroutine. The connection parameters are passed
along to the subroutine and its results returned for execution.

=back

For more information about the parameter replacement and argument count checking, see the clone_with_parameters() function from L<DBIx::SQLEngine::Utility::CloneWithParams>.

=back

B<Examples:> These samples demonstrate use of the named_connections feature.

=over 2

=item *

Here's a simple definition with a DSN string:

  DBIx::SQLEngine->define_named_connections('test'=>'dbi:mysql:test');

  $sqldb = DBIx::SQLEngine->new( 'test' );

=item *

Here's an example that includes a user name and password:

  DBIx::SQLEngine->define_named_connections( 
    'reference' => [ 'dbi:mysql:livedata', 'myuser', 'mypasswd' ],
  );

  $sqldb = DBIx::SQLEngine->new( 'reference' );

=item *

Here's a definition that requires a user name and password to be provided:

  DBIx::SQLEngine->define_named_connections( 
    'production' => [ 'dbi:mysql:livedata', \$1, \$2 ],
  );

  $sqldb = DBIx::SQLEngine->new( 'production', $user, $password );

=item *

Here's a definition using Perl code to set up the connection arguments:

  DBIx::SQLEngine->define_named_connections( 
    'finance' => sub { "dbi:oracle:accounting", "bob", "123" },
  );

  $sqldb = DBIx::SQLEngine->new( 'finance' );

=item *

Connection names are interpreted recursively, allowing them to be used as aliases:

  DBIx::SQLEngine->define_named_connections(
    'test'       => 'dbi:AnyData:test',
    'production' => 'dbi:Mysql:our_data:dbhost',
  );

  DBIx::SQLEngine->define_named_connections(
    '-active'    => 'production',
  );

  $sqldb = DBIx::SQLEngine->new( '-active' );

=item *

You can also use named connecctions to hijack regular connections:

  DBIx::SQLEngine->define_named_connections(
    'dbi:Mysql:students:db_host' => 'dbi:AnyData:test',
  );
  
  $sqldb = DBIx::SQLEngine->new( 'dbi:Mysql:students:db_host' );

=item *

Connection definitions can be stored in external text files or other sources and then evaluated into data structures or code references. The below code loads a simple text file of query definitions 

  open( CNXNS, '/path/to/my/connections' );
  %cnxn_info = map { split /\:\s*/, $_, 2 } grep { /^[^#]/ } <CNXNS>;
  close CNXNS;

  $sqldb->define_named_connections_from_text( %cnxn_info );

Placing the following text in the target file will define all of the connections used above:

  # Simple DSN that doesn't need any parameters
  test: dbi:mysql:test
  
  # Definition that includes a user name and password
  reference: [ 'dbi:mysql:livedata', 'myuser', 'mypasswd' ]
  
  # Definition that requires a user name and password 
  production: [ 'dbi:mysql:livedata', \$1, \$2 ]

  # Definition using Perl code to set up the connection arguments
  finance: "dbi:oracle:accounting", "bob", "123"

=back

=cut

use Class::MakeMethods ( 'Standard::Global:hash' => 'named_connections' );

use DBIx::SQLEngine::Utility::CloneWithParams ':all';

# $cnxn_def = DBIx::SQLEngine::Driver->named_connection( $name )
sub named_connection {
  my ( $self, $name ) = @_;
  $self->named_connections( $name ) or croak("No connection named '$name'");
}

# ($dsn) = DBIx::SQLEngine::Driver->interpret_named_connection($name, @args) 
# ($dsn, $user, $pass) = DBIx::SQLEngine::Driver->interpret_named_connection(...) 
# ($dsn, $user, $pass, $opts) = DBIx::SQLEngine::Driver->interpret_named_connection(...) 
sub interpret_named_connection {
  my ( $self, $name, @cnxn_args ) = @_;
  my $cnxn_def = $self->named_connection( $name );
  if ( ! $cnxn_def ) {
    croak("No definition was provided for named connection '$name': $cnxn_def")
  } elsif ( ! ref $cnxn_def ) {
    return ( $cnxn_def, @cnxn_args );
  } elsif ( ref($cnxn_def) eq 'ARRAY' ) {
    return ( @{ clone_with_parameters($cnxn_def, @cnxn_args) } );
  } elsif ( ref($cnxn_def) eq 'CODE' ) {
    my @results = $cnxn_def->( @cnxn_args );
    unshift @results, 'sql' if scalar(@results) == 1;
    return @results;
  } else {
    croak("Unable to interpret definition of named connection '$name': $cnxn_def")
  }
}

# DBIx::SQLEngine::Driver->define_named_connections( $name, $string_hash_or_sub, ... )
sub define_named_connections {
  my $self = shift;
  while ( scalar @_ ) {
    $self->named_connections( splice( @_, 0, 2 ) )
  }
}
sub define_named_connection { (shift)->define_named_connections(@_) }

# DBIx::SQLEngine::Driver->define_named_connections_from_text( $name, $string )
sub define_named_connections_from_text {
  my $self = shift;
  while ( scalar @_ ) {
    my ( $name, $text ) = splice( @_, 0, 2 );
    my $cnxn_def = do {
      if ( $text =~ /^\s*[\[|\{]/ ) {
	safe_eval_with_parameters( $text );
      } elsif ( $text =~ /^\s*[\"|\;]/ ) {
	safe_eval_with_parameters( "sub { $text }" );
      } else {
	$text
      }
    };
    $self->define_named_connection( $name, $cnxn_def );
  }
}

########################################################################

# Provide aliases for methods that might be called on the factory class
foreach my $method ( qw/ DBILogging SQLLogging 
	named_queries define_named_queries define_named_queries_from_text / ) {
  no strict 'refs';
  *{$method} = sub { shift; DBIx::SQLEngine::Driver::Default->$method( @_ ) }
}

########################################################################

########################################################################

# Set up default driver package and ensure that we don't try to require it later
package DBIx::SQLEngine::Driver::Default;

BEGIN { $INC{'DBIx/SQLEngine/Driver.pm'} = __FILE__ }
BEGIN { $INC{'DBIx/SQLEngine/Driver/Default.pm'} = __FILE__ }

use strict;
use Carp;
use DBI;

use DBIx::SQLEngine::Utility::CloneWithParams ':all';

########################################################################

########################################################################

=head1 FETCHING DATA (SQL DQL)

Information is obtained from a DBI database through the Data Query Language features of SQL.

=head2 Select to Retrieve Data

The following methods may be used to retrieve data using SQL select statements. They all accept a flexible set of key-value arguments describing the query to be run, as described in the "SQL Select Clauses" section below.

B<Public Methods:> There are several ways to retrieve information from a SELECT query.

The fetch_* methods select and return matching rows.

=over 4

=item fetch_select()

  $sqldb->fetch_select( %sql_clauses ) : $row_hashes
  $sqldb->fetch_select( %sql_clauses ) : ($row_hashes, $column_hashes)

Retrieve rows from the datasource as an array of hashrefs. If called in a list context, also returns an array of hashrefs containing information about the columns included in the result set.

=item fetch_select_rows()

  $sqldb->fetch_select_rows( %sql_clauses ) : $row_arrays
  $sqldb->fetch_select_rows( %sql_clauses ) : ($row_arrays, $column_hashes)

Like fetch_select, but returns an array of arrayrefs, rather than hashrefs.

=item fetch_one_row()

  $sqldb->fetch_one_row( %sql_clauses ) : $row_hash

Calls fetch_select, then returns only the first row of results.

=item fetch_one_value()

  $sqldb->fetch_one_value( %sql_clauses ) : $scalar

Calls fetch_select, then returns the first value from the first row of results.

=back

The visit_* and fetchsub_* methods allow you to loop through the returned records without necessarily loading them all into memory at once.

=over 4

=item visit_select()

  $sqldb->visit_select( $code_ref, %sql_clauses ) : @results
  $sqldb->visit_select( %sql_clauses, $code_ref ) : @results

Retrieve rows from the datasource as a series of hashrefs, and call the user provided function for each one. For your convenience, will accept a coderef as either the first or the last argument. Returns the results returned by each of those function calls. Processing with visit_select rather than fetch_select can be more efficient if you are looping over a large number of rows and do not need to keep them all in memory.

Note that some DBI drivers do not support simultaneous use of more than one statement handle; if you are using such a driver, you will receive an error if you run another query from within your code reference.

=item visit_select_rows()

  $sqldb->visit_select_rows( $code_ref, %sql_clauses ) : @results
  $sqldb->visit_select_rows( %sql_clauses, $code_ref ) : @results

Like visit_select, but for each row the code ref is called with the current row retrieved as a list of values, rather than a hash ref.

=item fetchsub_select()

  $self->fetchsub_select( %clauses ) : $coderef

Execute a query and returns a code reference that can be called repeatedly to retrieve a row as a hashref. When all of the rows have been fetched it will return undef.

The code reference is blessed so that when it goes out of scope and is destroyed it can call the statement handle's finish() method.

Note that some DBI drivers do not support simultaneous use of more than one statement handle; if you are using such a driver, you will receive an error if you run another query while this code reference is still in scope. 

=item fetchsub_select_rows()

  $self->fetchsub_select_rows( %clauses ) : $coderef

Like fetchsub_select, but for each row returns a list of values, rather than a hash ref. When all of the rows have been fetched it will return an empty list.

=back

B<SQL Select Clauses>: The above select methods accept a hash describing the clauses of the SQL statement they are to generate, using the values provided for the keys defined below. 

=over 4

=item 'sql'

May contain a plain SQL statement to be executed, or a reference to an array of a SQL statement followed by parameters for embedded placeholders. Can not be used in combination with the table and columns arguments. 

=item 'named_query'

Uses the named_query catalog to build the query. May contain a defined query name, or a reference to an array of a query name followed by parameters to be handled by interpret_named_query. See L</"NAMED QUERY CATALOG"> for details.

=item 'union'

Calls sql_union() to produce a query that combines the results of multiple calls to sql_select(). Should contain a reference to an array of hash-refs, each of which contains key-value pairs to be used in one of the unified selects. Can not be used in combination with the table and columns arguments. 

=item 'table' I<or> 'tables'

The name of the tables to select from. Required unless one of the above parameters is provided. May contain a string with one or more table names, or a reference to an array or hash of table names and join criteria. See the sql_join() method for details.

=item 'columns'

Optional; defaults to '*'. May contain a comma-separated string of column names, or an reference to an array of column names, or a reference to a hash mapping column names to "as" aliases, or a reference to an object with a "column_names" method.

=item 'distinct'

Optional. Boolean. Adds the "distinct" keyword to the query if value is true.

=item 'where' I<or> 'criteria'

Optional. May contain a literal SQL where clause, an array ref with a SQL clause and parameter list, a hash of field => value pairs, or an object that supports a sql_where() method. See the sql_where() method for details.

=item 'group'

Optional. May contain a comma-separated string of column names or experessions, or an reference to an array of the same.

=item 'order'

Optional. May contain a comma-separated string of column names or experessions, optionally followed by "DESC", or an reference to an array of the same.

=item 'limit'

Optional. Maximum number of rows to be retrieved from the server. Relies on DBMS-specific behavior provided by sql_limit(). 

=item 'offset'

Optional. Number of rows at the start of the result which should be skipped over. Relies on DBMS-specific behavior provided by sql_limit(). 

=back

B<Examples:> These samples demonstrate use of the select features.

=over 2

=item *

Each query can be written out explicitly or generated on demand using whichever syntax is most appropriate to your application; the following examples are functionally equivalent:

  $hashes = $sqldb->fetch_select( 
    sql => "select * from students where status = 'minor'"
  );

  $hashes = $sqldb->fetch_select( 
    sql => [ 'select * from students where status = ?', 'minor' ]
  );

  $hashes = $sqldb->fetch_select( 
    sql => 'select * from students', where => { 'status' => 'minor' }
  );

  $hashes = $sqldb->fetch_select( 
    table => 'students', where => [ 'status = ?', 'minor' ]
  );

  $hashes = $sqldb->fetch_select( 
    table => 'students', where => { 'status' => 'minor' } 
  );

  $hashes = $sqldb->fetch_select( 
    table => 'students', where => 
      DBIx::SQLEngine::Criteria->type_new('Equality','status'=>'minor')
  );

=item *

Both generated and explicit SQL can be stored as named queries and then used again later; the following examples are equivalent to those above:

  $sqldb->define_named_query(
    'minor_students' => "select * from students where status = 'minor'" 
  );
  $hashes = $sqldb->fetch_select( 
    named_query => 'minor_students' 
  );

  $sqldb->define_named_query(
    'minor_students' => {
	table => 'students', where => { 'status' => 'minor' } 
    }
  );
  $hashes = $sqldb->fetch_select( 
    named_query => 'minor_students' 
  );

=item *

Here's a use of some optional clauses listing the columns returned, and specifying a sort order:

  $hashes = $sqldb->fetch_select( 
    table => 'students', columns => 'name, age', order => 'name'
  );

=item *

Here's a where clause that uses a function to find the youngest people; note the use of a backslash to indicate that "min(age)" is an expression to be evaluated by the database server, rather than a literal value:

  $hashes = $sqldb->fetch_select( 
    table => 'students', where => { 'age' => \"min(age)" } 
  );

=item *

If you know that only one row will match, you can use fetch_one_row:

  $joe = $sqldb->fetch_one_row( 
    table => 'student', where => { 'id' => 201 }
  );

All of the SQL select clauses are accepted, including explicit SQL statements with parameters:

  $joe = $sqldb->fetch_one_row( 
    sql => [ 'select * from students where id = ?', 201 ]
  );

=item *

And when you know that there will only be one row and one column in your result set, you can use fetch_one_value:

  $count = $sqldb->fetch_one_value( 
    table => 'student', columns => 'count(*)'
  );

All of the SQL select clauses are accepted, including explicit SQL statements with parameters:

  $maxid = $sqldb->fetch_one_value( 
    sql => [ 'select max(id) from students where status = ?', 'minor' ]
  );

=item *

You can use visit_select to make a traversal of all rows that match a query without retrieving them all at once:

  $sqldb->visit_select( 
    table => 'student',
    sub {
      my $student = shift;
      print $student->{id}, $student->{name}, $student->{age};
    }
  );

You can collect values along the way:

  my @firstnames = $sqldb->visit_select( 
    table => 'student',
    sub {
      my $student = shift;
      ( $student->{name} =~ /(\w+)\s/ ) ? $1 : $student->{name};
    }
  );

You can visit with any combination of the other clauses supported by fetch_select:

   $sqldb->visit_select( 
    table => 'student', 
    columns => 'id, name', 
    order => 'name, id desc',
    where => 'age < 22',
    sub {
      my $student = shift;
      print $student->{id}, $student->{name};
    }
  );

=item *

You can use fetchsub_select to make a traversal of some or all rows without retrieving them all at once:

  my $fetchsub = $sqldb->fetchsub_select( 
    table => 'student',
    where => 'age < 22',
  );
  while ( my $student = $fetchsub->() ) {
    print $student->{id}, $student->{name}, $student->{age};
  }

You can use fetchsub_select_rows to treat each row as a list of values instead of a hashref:

  my $fetchsub = $sqldb->fetchsub_select_rows( 
    table => 'student',
    columns => 'id, name, age',
  );
  while ( my @student = $fetchsub->() ) {
    print $student[0], $student[1], $student[2];
  }

=back

=cut

# $rows = $self->fetch_select( %clauses );
sub fetch_select {
  my $self = shift;
  $self->fetch_sql( $self->sql_select( @_ ) );
}

# $rows = $self->fetch_select_rows( %clauses );
sub fetch_select_rows {
  my $self = shift;
  $self->fetch_sql_rows( $self->sql_select( @_ ) );
}

# $row = $self->fetch_one( %clauses );
sub fetch_one {
  my $self = shift;
  my $rows = $self->fetch_select( limit => 1, @_ ) or return;
  $rows->[0];
}

# $row = $self->fetch_one_row( %clauses );
sub fetch_one_row { (shift)->fetch_one( @_ ) }

# $row = $self->fetch_one_values( %clauses );
sub fetch_one_values {
  my $self = shift;
  my $rows = $self->fetch_select_rows( limit => 1, @_ ) or return;
  $rows->[0] ? @{ $rows->[0] } : ();
}

# $value = $self->fetch_one_value( %clauses );
sub fetch_one_value {
  my $self = shift;
  my $row = $self->fetch_one_row( @_ ) or return;
  (%$row)[1];
}

# @results = $self->visit_select( %clauses, $coderef );
# @results = $self->visit_select( $coderef, %clauses );
sub visit_select {
  my $self = shift;
  $self->visit_sql( ( ref($_[0]) ? shift : pop ), $self->sql_select( @_ ) )
}

# @results = $self->visit_select_rows( %clauses, $coderef );
# @results = $self->visit_select_rows( $coderef, %clauses );
sub visit_select_rows {
  my $self = shift;
  $self->visit_sql_rows( ( ref($_[0]) ? shift : pop ), $self->sql_select( @_ ) )
}

# $coderef = $self->fetchsub_select( %clauses );
sub fetchsub_select {
  my $self = shift;
  $self->fetchsub_sql( $self->sql_select( @_ ) );
}

# $coderef = $self->fetchsub_select_rows( %clauses );
sub fetchsub_select_rows {
  my $self = shift;
  $self->fetchsub_sql_rows( $self->sql_select( @_ ) );
}

########################################################################

=pod

B<Internal Methods:> The following methods are used to construct select queries. They are called automatically by the public select methods, and do not need to be invoked directly.

=over 4

=item sql_select()

  $sqldb->sql_select ( %sql_clauses ) : $sql_stmt, @params

Generate a SQL select statement and returns it as a query string and a list of values to be bound as parameters. Internally, this sql_ method is used by the fetch_ and visit_ methods above, and calls any of the other sql_ methods necessary.

=item sql_where()

  $sqldb->sql_where( $criteria, $sql, @params ) : $sql, @params

Modifies the SQL statement and parameters list provided to append the specified criteria as a where clause. Triggered by use of a where or criteria clause in a call to sql_select(), sql_update(), or sql_delete(). 

The criteria may be a literal SQL where clause (everything after the word "where"), or a reference to an array of a SQL string with embedded placeholders followed by the values that should be bound to those placeholders. 

If the criteria argument is a reference to hash, it is treated as a set of field-name => value pairs, and a SQL expression is created that requires each one of the named fields to exactly match the value provided for it, or if the value is an array reference to match any one of the array's contents; see L<DBIx::SQLEngine::Criteria::HashGroup> for details.

Alternately, if the criteria argument is a reference to an object which supports a sql_where() method, the results of that method will be used; see L<DBIx::SQLEngine::Criteria> for classes with this behavior. 

If no SQL statement or parameters are provided, this just returns the where clause and associated parameters. If a SQL statement is provided, the where clauses is appended to it; if the SQL statement already includes a where clause, the additional criteria are inserted into the existing statement and AND'ed together with the existing criteria.

=item sql_escape_text_for_like()

  $sqldb->sql_escape_text_for_like ( $text ) : $escaped_expr

Fails with message "DBMS-Specific Function".

Subclasses should, based on the datasource's server_type, protect a literal value for use in a like expression.

=item sql_join()

  $sqldb->sql_join( $table1, $table2, ... ) : $sql, @params
  $sqldb->sql_join( \%table_names_and_criteria ) : $sql, @params
  $sqldb->sql_join( $table1, \%criteria, $table2 ) : $sql, @params
  $sqldb->sql_join( $table1, $join_type=>\%criteria, $table2 ) : $sql, @params

Processes one or more table names to create the "from" clause of a select statement. Table names may appear in succession for normal "cross joins", or you may specify a "complex join" by placing an inner or outer joining operation between them.

A joining operation consists of a string containing the word C<join>, followed by an array reference or hash reference that specifies the criteria. The string should be one of the types of joins supported by your database, typically the following: "cross join", "inner join", "outer join", "left outer join", "right outer join". Any underscores in the string are converted to spaces, making it easier to use as an unquoted string. 

The joining criteria can be an array reference of a string containing a bit SQL followed by any necessary placeholder parameters, or a hash reference which will be converted to SQL with the DBIx::SQLEngine::Criteria package.

If an array reference is used as a table name, its contents are evaluated by being passed to another call to sql_join, and then the results are treated as a parenthesized expression. 

If a hash reference is used as a table name, its contents are evaluated as criteria in "table1.column1" => "table2.column2" format. The table names and criteria are passed to another call to sql_join, and then the results are treated as a parenthesized expression. 

B<Portability:> While the cross and inner joins are widely supported, the various outer join capabilities are only present in some databases. Subclasses may provide a degree of emulation; for one implementation of this, see L<DBIx::SQLEngine::Driver::Trait::NoComplexJoins>.

B<Examples:> These samples demonstrate use of the join feature.

=over 2

=item *

Here's a simple inner join of two tables, using a hash ref to express the linkage:

  $hashes = $sqldb->fetch_select( 
    tables => { 'students.id' => 'grades.student_id' },
    order => 'students.name'
  );

=item *

You can also use bits of SQL to express the linkage between two tables:

  $hashes = $sqldb->fetch_select( 
    tables => [ 
      'students', 
	INNER_JOIN=>['students.id = grades.student_id'], 
      'grades'
    ],
    order => 'students.name'
  );

=item *

Any number of tables can be joined in this fashion:

  $hashes = $sqldb->fetch_select( 
    tables => [ 
      'students', 
	INNER_JOIN=>['students.id = grades.student_id'], 
      'grades',
	INNER_JOIN=>['classes.id  = grades.class_id'  ], 
      'classes',
    ],
    order => 'students.name'
  );

=item *

Here's yet another way of expressing a join, using a join type and a hash of criteria:

  $hashes = $sqldb->fetch_select( 
    tables => [ 
      'students', INNER_JOIN=>{ 'students.id'=>\'grades.student_id' }, 'grades'
    ],
    order => 'students.name'
  );

Note that we're using a backslash in our criteria hash again to make it clear that we're looking for tuples where the students.id column matches that the grades.student_id column, rather than trying to match the literal string 'grades.student_id'.

=item *

The inner join shown above is equivalent to a typical cross join with the same joining criteria:

  $hashes = $sqldb->fetch_select( 
    tables => [ 'students', 'grades' ], 
    where => { 'students.id' => \'grades.student_id' },
    order => 'students.name'
  );

=item *

You can use nested array references to produce grouped join expressions:

  $hashes = $sqldb->fetch_select( table => [
    [ 'table1', INNER_JOIN=>{ 'table1.foo' => \'table2.foo' }, 'table2' ],
      OUTER_JOIN=>{ 'table1.bar' => \'table3.bar' },
    [ 'table3', INNER_JOIN=>{ 'table3.baz' => \'table4.baz' }, 'table4' ],
  ] );

=item *

You can also simply pass in your own arbitrary join as text:

  $hashes = $sqldb->fetch_select( 
    tables => 'students OUTER JOIN grades ON students.id = grades.student_id', 
    order => 'students.name'
  );

=back

=item sql_limit()

  $sqldb->sql_limit( $limit, $offset, $sql, @params ) : $sql, @params

Modifies the SQL statement and parameters list provided to apply the specified limit and offset requirements. Triggered by use of a limit or offset clause in a call to sql_select().

B<Portability:> Limit and offset clauses are handled differently by various DBMS platforms. For example, MySQL accepts "limit 20,10", Postgres "limit 10 offset 20", and Oracle requires a nested select with rowcount. The sql_limit method can be overridden by subclasses to adjust this behavior.

B<Examples:> These samples demonstrate use of the limit feature.

=over 2

=item *

This query return records 101 through 120 from an alphabetical list:

  $hash_ary = $sqldb->fetch_select( 
    table => 'students', order => 'last_name, first_name',
    limit => 20, offset => 100,    
  );

=back

=item sql_union()

  $sqldb->sql_union( \%clauses_1, \%clauses_2, ... ) : $sql, @params

Returns a combined select query using the C<union> operator between the SQL statements produced by calling sql_select() with each of the provided arrays of arguments. Triggered by use of a union clause in a call to sql_select(). 

B<Portability:> Union queries are only supported by some databases. Croaks if the dbms_union_unsupported() capability method is set. Subclasses may provide a degree of emulation; for one implementation of this, see L<DBIx::SQLEngine::Driver::Trait::NoUnions>.

B<Examples:> These samples demonstrate use of the union feature.

=over 2

=item *

A union can combine any mixture of queries with generated clauses:

  $hash_ary = $sqldb->fetch_select( 
    union=>[ { table=>'students', columns=>'first_name, last_name' },
	     { table=>'staff',    columns=>'name_f, name_l' }, ],
  );

=item *

Unions can also combine plain SQL strings:

  $hash_ary = $sqldb->fetch_select( 
    union=>[ { sql=>'select first_name, last_name from students' },
	     { sql=>'select name_f, name_l from staff' },  ],
  );

=back

=back

=cut

sub sql_select {
  my ( $self, %clauses ) = @_;

  my $keyword = 'select';
  my ($sql, @params);

  if ( my $named = delete $clauses{'named_query'} ) {
    my %named = $self->interpret_named_query( ref($named) ? @$named : $named );
    %clauses = ( %named, %clauses );
  }

  if ( my $action = delete $clauses{'action'} ) {
    confess("Action mismatch: expecting $keyword, not $action query") 
	unless ( $action eq $keyword );
  }

  if ( my $union = delete $clauses{'union'} ) {
    if ( my ( $conflict ) = grep $clauses{$_}, qw/sql table tables columns/ ) { 
      croak("Can't build a $keyword query using both union and $conflict args")
    }
    ref($union) eq 'ARRAY' or 
      croak("Union clause must be a reference to an array of hashes or arrays");
    
    $clauses{'sql'} = [ $self->sql_union( @$union ) ]
  } 

  if ( my $literal = delete $clauses{'sql'} ) {
    if ( my ($conflict) = grep $clauses{$_}, qw/distinct table tables columns/){ 
      croak("Can't build a $keyword query using both sql and $conflict clauses")
    }
    ($sql, @params) = ( ref($literal) eq 'ARRAY' ) ? @$literal : $literal;
  
  } else {
    
    if ( my $distinct = delete $clauses{'distinct'} ) {
      $keyword .= " distinct";
    } 
    
    my $columns = delete $clauses{'columns'};
    if ( ! $columns ) {
      $columns = '*';
    } elsif ( ! ref( $columns ) and length( $columns ) ) {
      # should be one or more comma-separated column names
    } elsif ( UNIVERSAL::can($columns, 'column_names') ) {
      $columns = join ', ', $columns->column_names;
    } elsif ( ref($columns) eq 'ARRAY' ) {
      $columns = join ', ', @$columns;
    } elsif ( ref($columns) eq 'HASH' ) {
      $columns = join ', ', map { "$_ as $columns->{$_}" } sort keys %$columns;
    } else {
      confess("Unsupported column spec '$columns'");
    }
    $sql = "$keyword $columns";
    
    my $tables = delete $clauses{'table'} || delete $clauses{'tables'};
    if ( ! $tables ) {
      confess("You must supply a table name if you do not use literal SQL or a named query");
    } elsif ( ! ref( $tables ) and length( $tables ) ) {
      # should be one or more comma-separated table names
    } elsif ( UNIVERSAL::can($tables, 'table_names') ) {
      $tables = $tables->table_names;
    } elsif ( ref($tables) eq 'ARRAY' ) {
      ($tables, my @join_params) = $self->sql_join( @$tables );
      push @params, @join_params;
    } elsif ( ref($tables) eq 'HASH' ) {
      ($tables, my @join_params) = $self->sql_join( $tables );
      push @params, @join_params;
    } else {
      confess("Unsupported table spec '$tables'");
    }
    $sql .= " from $tables";
  }
  
  if ( my $criteria = delete $clauses{'criteria'} || delete $clauses{'where'} ){
    ($sql, @params) = $self->sql_where($criteria, $sql, @params);
  }
  
  if ( my $group = delete $clauses{'group'} ) {
    if ( ! ref( $group ) and length( $group ) ) {
      # should be one or more comma-separated column names or expressions
    } elsif ( ref($group) eq 'ARRAY' ) {
      $group = join ', ', @$group;
    } else {
      confess("Unsupported group spec '$group'");
    }
    if ( $group ) {
      $sql .= " group by $group";
    }
  }
  
  if ( my $order = delete $clauses{'order'} ) {
    if ( ! ref( $order ) and length( $order ) ) {
      # should be one or more comma-separated column names with optional 'desc'
    } elsif ( ref($order) eq 'ARRAY' ) {
      $order = join ', ', @$order;
    } else {
      confess("Unsupported order spec '$order'");
    }
    if ( $order ) {
      $sql .= " order by $order";
    }
  }
  
  my $limit = delete $clauses{limit};
  my $offset = delete $clauses{offset};
  if ( $limit or $offset) {
    ($sql, @params) = $self->sql_limit($limit, $offset, $sql, @params);
  }
  
  if ( scalar keys %clauses ) {
    confess("Unsupported $keyword clauses: " . 
      join ', ', map "$_ ('$clauses{$_}')", keys %clauses);
  }
  
  $self->log_sql( $sql, @params );
  
  return( $sql, @params );
}

########################################################################

use DBIx::SQLEngine::Criteria;

sub sql_where {
  my $self = shift;
  my ( $criteria, $sql, @params ) = @_;
  
  my ( $sql_crit, @cp ) = DBIx::SQLEngine::Criteria->auto_where( $criteria );
  if ( $sql_crit ) {
    if ( ! defined $sql ) { 
      $sql = "where $sql_crit";
    } elsif ( $sql =~ s{(\bwhere\b)(.*?)(\border by|\bgroup by|$)}
			{$1 ($2) AND $sql_crit $3}i ) {
    } else {
      $sql .= " where $sql_crit";
    }
    push @params, @cp;
  }
  
  return ($sql, @params);
}

sub sql_escape_text_for_like {
  confess("DBMS-Specific Function")
}

########################################################################

# ( $sql, @params ) = $sqldb->sql_join( $table_name, $table_name, ... );
# ( $sql, @params ) = $sqldb->sql_join( $table_name, \%crit, $table_name);
# ( $sql, @params ) = $sqldb->sql_join( $table_name, join=>\%crit, $table_name);
sub sql_join {
  my ($self, @exprs) = @_;
  my $sql = '';
  my @params;
  while ( scalar @exprs ) {
    my $expr = shift @exprs;

    my ( $table, $join, $criteria );
    if ( ! ref $expr and $expr =~ /^[\w\s]+join$/i and ref($exprs[0]) ) {
      $join = $expr;
      $criteria = shift @exprs;
      $table = shift @exprs;

    } elsif ( $sql and ref($expr) eq 'HASH' ) {
      $join = 'inner join';
      $criteria = $expr;
      $table = shift @exprs;

    } else {
      $join = ',';
      $criteria = undef;
      $table = $expr;
    }
    
    ( $table ) or croak("No table name provided to join to");
    ( $join ) or croak("No join type provided for link to $table");
    
    $join =~ tr[_][ ];
    $sql .= ( ( length($join) == 1 ) ? '' : ' ' ) . $join;
    
    my ( $expr_sql, @expr_params );
    if ( ! ref $table ) {
      $expr_sql = $table 
    } elsif ( ref($table) eq 'ARRAY' ) {
      my ( $sub_sql, @sub_params ) = $self->sql_join( @$table );
      $expr_sql = "( $sub_sql )";
      push @expr_params, @sub_params
    } elsif ( ref($table) eq 'HASH' ) {
      my %seen_tables;
      my @tables = grep { ! $seen_tables{$_} ++ } map { ( /^([^\.]+)\./ )[0] } %$table;
      if ( @tables == 2 ) {
	my ( $sub_sql, @sub_params ) = $self->sql_join( 
	  $tables[0], 
	  inner_join => { map { $_ => \($table->{$_}) } keys %$table },
	  $tables[1], 
	);
	$expr_sql = $sub_sql;
	push @expr_params, @sub_params
      } else {
	confess("sql_join on hash with more than two tables not yet supported")
      }
    } elsif ( UNIVERSAL::can($table, 'name') ) {
      $expr_sql = $table->name
    } else {
      Carp::confess("Unsupported expression in sql_join: '$table'");
    }

    $sql .= " $expr_sql";
    push @params, @expr_params;
    
    if ( $criteria ) {
      my ($crit_sql, @crit_params) = 
			DBIx::SQLEngine::Criteria->auto_where( $criteria );
      if ( $crit_sql ) {
	$sql .= " on $crit_sql";
	push @params, @crit_params;
      }
    }

  }
  $sql =~ s/^, // or carp("Suspect table join: '$sql'");
  ( $sql, @params );
}

########################################################################

sub sql_limit {
  my $self = shift;
  my ( $limit, $offset, $sql, @params ) = @_;
  
  $sql .= " limit $limit" if $limit;
  $sql .= " offset $offset" if $offset;
  
  return ($sql, @params);
}

########################################################################

sub sql_union {
  my ( $self, @queries ) = @_;
  my ( @sql, @params );
  if ( $self->dbms_union_unsupported ) {
    croak("SQL Union not supported by this database");
  }
  foreach my $query ( @queries ) {
    my ( $q_sql, @q_params ) = $self->sql_select( 
	( ref($query) eq 'ARRAY' ) ? @$query : %$query );
    push @sql, $q_sql;
    push @params, @q_params;
  }
  return ( join( ' union ', @sql ), @params )
}

sub detect_union_supported {
  my $self = shift;
  my $result = 0;
  eval {
    local $SIG{__DIE__};
    $self->fetch_select( sql => 'select 1 union select 2' );
    $result = 1;
  };
  return $result;
}

########################################################################

########################################################################

=head1 EDITING DATA (SQL DML)

Information in a DBI database is entered and modified through the Data Manipulation Language features of SQL.

=head2 Insert to Add Data 

B<Public Methods:> You can perform database INSERTs with these methods.

=over 4

=item do_insert()

  $sqldb->do_insert( %sql_clauses ) : $row_count

Insert a single row into a table in the datasource. Should return 1, unless there's an exception.

=item do_bulk_insert()

  $sqldb->do_bulk_insert( %sql_clauses, values => [ @array_or_hash_refs ] ) : $row_count

Inserts several rows into a table. Returns the number of rows inserted.

This is provided so that drivers which have alternate bulk-loader
interfaces can hook into that support here, and to allow specialty
options like C<statements_per_transaction => 100> in order to
optimize performance on servers such as Oracle, where auto-committing
one statement at a time is slow.

=back

B<Internal Methods:> The following method is called by do_insert() and does not need to be called directly. 

=over 4

=item sql_insert()

  $sqldb->sql_insert ( %sql_clauses ) : $sql_stmt, @params

Generate a SQL insert statement and returns it as a query string and a list of values to be bound as parameters. Internally, this sql_ method is used by the do_ method above.

=back

B<SQL Insert Clauses>: The above insert methods accept a hash describing the clauses of the SQL statement they are to generate, and require a value for one or more of the following keys: 

=over 4

=item 'sql'

Optional; overrides all other arguments. May contain a plain SQL statement to be executed, or a reference to an array of a SQL statement followed by parameters for embedded placeholders.

=item 'named_query' 

Uses the named_query catalog to build the query. May contain a defined query name, or a reference to an array of a query name followed by parameters to be handled by interpret_named_query. See L</"NAMED QUERY CATALOG"> for details.

=item 'table' 

Required. The name of the table to insert into.

=item 'columns'

Optional; defaults to '*'. May contain a comma-separated string of column names, or an reference to an array of column names, or a reference to a hash whose keys contain the column names, or a reference to an object with a "column_names" method.

=item 'values'

Required. May contain a string with one or more comma-separated quoted values or expressions in SQL format, or a reference to an array of values to insert in order, or a reference to a hash whose values are to be inserted. If an array or hash reference is used, each value may either be a scalar to be used as a literal value (passed via placeholder), or a reference to a scalar to be used directly (such as a sql function or other non-literal expression).

=item 'sequence'

Optional. May contain a string with the name of a column in the target table which should receive an automatically incremented value. If present, triggers use of the DMBS-specific do_insert_with_sequence() method, described below.

=back

B<Examples:> These samples demonstrate use of the insert feature.

=over 2

=item *

Here's a simple insert using a hash of column-value pairs:

  $sqldb->do_insert( 
    table => 'students', 
    values => { 'name'=>'Dave', 'age'=>'19', 'status'=>'minor' } 
  );

=item *

Here's the same insert using separate arrays of column names and values to be inserted:

  $sqldb->do_insert( 
    table => 'students', 
    columns => [ 'name', 'age', 'status' ], 
    values => [ 'Dave', '19', 'minor' ]
  );

=item *

Here's a bulk insert of multiple rows:

  $sqldb->do_insert( 
    table => 'students', 
    columns => [ 'name', 'age', 'status' ], 
    values => [
      [ 'Dave', '19', 'minor' ],
      [ 'Alice', '20', 'minor' ],
      [ 'Sam', '22', 'adult' ],
    ]
  );

=item *

Of course you can also use your own arbitrary SQL and placeholder parameters.

  $sqldb->do_insert( 
    sql=>['insert into students (id, name) values (?, ?)', 201, 'Dave']
  );

=item *

And the named_query interface is supported as well:

  $sqldb->define_named_query(
    'insert_student' => 'insert into students (id, name) values (?, ?)'
  );
  $hashes = $sqldb->do_insert( 
    named_query => [ 'insert_student', 201, 'Dave' ]
  );

=back

=cut

# $rows = $self->do_insert( %clauses );
sub do_insert {
  my $self = shift;
  my %args = @_;
  
  if ( my $seq_name = delete $args{sequence} ) {
    $self->do_insert_with_sequence( $seq_name, %args );
  } else {
    $self->do_sql( $self->sql_insert( @_ ) );
  }
}

sub do_bulk_insert {
  my $self = shift;
  my %args = @_;
  my $values = delete $args{values};
  foreach my $value ( @$values ) {
    $self->do_insert( %args, values => $value );
  }
}

sub sql_insert {
  my ( $self, %clauses ) = @_;

  my $keyword = 'insert';
  my ($sql, @params);

  if ( my $named = delete $clauses{'named_query'} ) {
    my %named = $self->interpret_named_query( ref($named) ? @$named : $named );
    %clauses = ( %named, %clauses );
  }

  if ( my $action = delete $clauses{'action'} ) {
    confess("Action mismatch: expecting $keyword, not $action query") 
	unless ( $action eq $keyword );
  }

  if ( my $literal = delete $clauses{'sql'} ) {
    return ( ref($literal) eq 'ARRAY' ) ? @$literal : $literal;
  }
  
  my $table = delete $clauses{'table'};
  if ( ! $table ) {
    confess("Table name is missing or empty");
  } elsif ( ! ref( $table ) and length( $table ) ) {
    # should be a single table name
  } else {
    confess("Unsupported table spec '$table'");
  }
  $sql = "insert into $table";
  
  my $columns = delete $clauses{'columns'};
  if ( ! $columns and UNIVERSAL::isa( $clauses{'values'}, 'HASH' ) ) {
    $columns = $clauses{'values'}
  }
  if ( ! $columns or $columns eq '*' ) {
    $columns = '';
  } elsif ( ! ref( $columns ) and length( $columns ) ) {
    # should be one or more comma-separated column names
  } elsif ( UNIVERSAL::can($columns, 'column_names') ) {
    $columns = join ', ', $columns->column_names;
  } elsif ( ref($columns) eq 'HASH' ) {
    $columns = join ', ', sort keys %$columns;
  } elsif ( ref($columns) eq 'ARRAY' ) {
    $columns = join ', ', @$columns;
  } else {
    confess("Unsupported column spec '$columns'");
  }
  if ( $columns ) {
    $sql .= " ($columns)";
  }
  
  my $values = delete $clauses{'values'};
  my @value_args;
  if ( ! defined $values or ! length $values ) {
    croak("Values are missing or empty");
  } elsif ( ! ref( $values ) and length( $values ) ) {
    # should be one or more comma-separated quoted values or expressions
    @value_args = \$values;
  } elsif ( UNIVERSAL::isa( $values, 'HASH' ) ) {
    @value_args = map $values->{$_}, split /,\s?/, $columns;
  } elsif ( ref($values) eq 'ARRAY' ) {
    @value_args = @$values;
  } else {
    confess("Unsupported values spec '$values'");
  }
  ( scalar @value_args ) or croak("Values are missing or empty");    
  my @v_literals;
  my @v_params;
  foreach my $v ( @value_args ) {
    if ( ! defined($v) ) {
      push @v_literals, 'NULL';
    } elsif ( ! ref($v) ) {
      push @v_literals, '?';
      push @v_params, $v;
    } elsif ( ref($v) eq 'SCALAR' ) {
      push @v_literals, $$v;
    } else {
      Carp::confess( "Can't use '$v' as part of a sql values clause" );
    }
  }
  $values = join ', ', @v_literals;
  $sql .= " values ($values)";
  push @params, @v_params;
  
  if ( scalar keys %clauses ) {
    confess("Unsupported $keyword clauses: " . 
      join ', ', map "$_ ('$clauses{$_}')", keys %clauses);
  }
  
  $self->log_sql( $sql, @params );
  
  return( $sql, @params );
}  

########################################################################

=pod

B<Internal Methods:> The following methods are called by do_insert() and do not need to be called directly. 

=over 4

=item do_insert_with_sequence()

  $sqldb->do_insert_with_sequence( $seq_name, %sql_clauses ) : $row_count

Insert a single row into a table in the datasource, using a sequence to fill in the values of the column named in the first argument. Should return 1, unless there's an exception.

Fails with message "DBMS-Specific Function". 

B<Portability:> Auto-incrementing sequences are handled differently by various DBMS platforms. For example, the MySQL and MSSQL subclasses use auto-incrementing fields, Oracle and Pg use server-specific sequence objects, and AnyData and CSV lack this capability, which can be emulated with an ad-hoc table of incrementing values.  

To standardize their use, this package defines an interface with several typical methods which may or may not be supported by individual subclasses. You may need to consult the documentation for the SQLEngine Driver subclass and DBMS platform you're using to confirm that the sequence functionality you need is available.

Drivers which don't support native sequences may provide a degree of emulation; for one implementation of this, see L<DBIx::SQLEngine::Driver::Trait::NoSequences>.

Subclasses will probably want to call either the _seq_do_insert_preinc() method or the _seq_do_insert_postfetch() method, and define the appropriate other seq_* methods to support them. These two methods are not part of the public interface but instead provide a template for the two most common types of insert-with-sequence behavior. The _seq_do_insert_preinc() method first obtaines a new number from the sequence using seq_increment(), and then performs a normal do_insert(). The _seq_do_insert_postfetch() method performs a normal do_insert() and then fetches the resulting value that was automatically incremented using seq_fetch_current().

=item seq_fetch_current()

  $sqldb->seq_fetch_current( $table, $field ) : $current_value

Fetches the current sequence value.

Fails with message "DBMS-Specific Function". 

=item seq_increment()

  $sqldb->seq_increment( $table, $field ) : $new_value

Increments the sequence, and returns the newly allocated value. 

Fails with message "DBMS-Specific Function". 

=back

=cut

# $self->do_insert_with_sequence( $seq_name, %args );
sub do_insert_with_sequence {
  confess("DBMS-Specific Function")
}

# $rows = $self->_seq_do_insert_preinc( $sequence, %clauses );
sub _seq_do_insert_preinc {
  my ($self, $seq_name, %args) = @_;
  
  unless ( UNIVERSAL::isa($args{values}, 'HASH') ) {
    croak ref($self) . " insert with sequence requires values to be hash-ref"
  }
  
  $args{values}->{$seq_name} = $self->seq_increment( $args{table}, $seq_name );
  
  $self->do_insert( %args );
}

# $rows = $self->_seq_do_insert_postfetch( $sequence, %clauses );
sub _seq_do_insert_postfetch {
  my ($self, $seq_name, %args) = @_;
  
  unless ( UNIVERSAL::isa($args{values}, 'HASH') ) {
    croak ref($self) . " insert with sequence requires values to be hash-ref"
  }
  
  my $rv = $self->do_insert( %args );
  $args{values}->{$seq_name} = $self->seq_fetch_current($args{table},$seq_name);
  return $rv;
}

# $current_id = $sqldb->seq_fetch_current( $table, $field );
sub seq_fetch_current {
  confess("DBMS-Specific Function")
}

# $nextid = $sqldb->seq_increment( $table, $field );
sub seq_increment {
  confess("DBMS-Specific Function")
}

########################################################################

=head2 Update to Change Data 

B<Public Methods:> You can perform database UPDATEs with these methods.

=over 4

=item do_update()

  $sqldb->do_update( %sql_clauses ) : $row_count

Modify one or more rows in a table in the datasource.

=back

B<Internal Methods:> These methods are called by the public update method.

=over 4

=item sql_update()

  $sqldb->sql_update ( %sql_clauses ) : $sql_stmt, @params

Generate a SQL update statement and returns it as a query string and a list of values to be bound as parameters. Internally, this sql_ method is used by the do_ method above.

=back

B<SQL Update Clauses>: The above update methods accept a hash describing the clauses of the SQL statement they are to generate, and require a value for one or more of the following keys: 

=over 4

=item 'sql'

Optional; conflicts with table, columns and values arguments. May contain a plain SQL statement to be executed, or a reference to an array of a SQL statement followed by parameters for embedded placeholders.

=item 'named_query' 

Uses the named_query catalog to build the query. May contain a defined query name, or a reference to an array of a query name followed by parameters to be handled by interpret_named_query. See L</"NAMED QUERY CATALOG"> for details.

=item 'table' 

Required unless sql argument is used. The name of the table to update.

=item 'columns'

Optional unless sql argument is used. Defaults to '*'. May contain a comma-separated string of column names, or an reference to an array of column names, or a reference to a hash whose keys contain the column names, or a reference to an object with a "column_names" method.

=item 'values'

Required unless sql argument is used. May contain a string with one or more comma-separated quoted values or expressions in SQL format, or a reference to an array of values to insert in order, or a reference to a hash whose values are to be inserted. If an array or hash reference is used, each value may either be a scalar to be used as a literal value (passed via placeholder), or a reference to a scalar to be used directly (such as a sql function or other non-literal expression).

=item 'where' I<or> 'criteria'

Optional, but remember that ommitting this will cause all of your rows to be updated! May contain a literal SQL where clause, an array ref with a SQL clause and parameter list, a hash of field => value pairs, or an object that supports a sql_where() method. See the sql_where() method for details.

=back

B<Examples:> These samples demonstrate use of the update feature.

=over 2

=item *

Here's a basic update statement with a hash of columns-value pairs to change:

  $sqldb->do_update( 
    table => 'students', 
    where => 'age > 20', 
    values => { 'status'=>'adult' } 
  );

=item *

Here's an equivalent update statement using separate lists of columns and values:

  $sqldb->do_update( 
    table => 'students', 
    where => 'age > 20', 
    columns => [ 'status' ], 
    values => [ 'adult' ]
  );

=item *

You can also use your own arbitrary SQL statements and placeholders:

  $sqldb->do_update( 
    sql=>['update students set status = ? where age > ?', 'adult', 20]
  );

=item *

And the named_query interface is supported as well:

  $sqldb->define_named_query(
    'update_minors' => 
	[ 'update students set status = ? where age > ?', 'adult', 20 ]
  );
  $hashes = $sqldb->do_update( 
    named_query => 'update_minors'
  );

=back

=cut

# $rows = $self->do_update( %clauses );
sub do_update {
  my $self = shift;
  $self->do_sql( $self->sql_update( @_ ) );
}

sub sql_update {
  my ( $self, %clauses ) = @_;
  
  my $keyword = 'update';
  my ($sql, @params);

  if ( my $named = delete $clauses{'named_query'} ) {
    my %named = $self->interpret_named_query( ref($named) ? @$named : $named );
    %clauses = ( %named, %clauses );
  }

  if ( my $action = delete $clauses{'action'} ) {
    confess("Action mismatch: expecting $keyword, not $action query") 
	unless ( $action eq $keyword );
  }
  
  if ( my $literal = delete $clauses{'sql'} ) {
    ($sql, @params) = ( ref($literal) eq 'ARRAY' ) ? @$literal : $literal;
    if ( my ( $conflict ) = grep $clauses{$_}, qw/ table columns values / ) { 
      croak("Can't build a $keyword query using both sql and $conflict clauses")
    }
  
  } else {
    
    my $table = delete $clauses{'table'};
    if ( ! $table ) {
      confess("Table name is missing or empty");
    } elsif ( ! ref( $table ) and length( $table ) ) {
      # should be a single table name
    } else {
      confess("Unsupported table spec '$table'");
    }
    $sql = "update $table";
  
    my $columns = delete $clauses{'columns'};
    if ( ! $columns and UNIVERSAL::isa( $clauses{'values'}, 'HASH' ) ) {
      $columns = $clauses{'values'}
    }
    my @columns;
    if ( ! $columns or $columns eq '*' ) {
      croak("Column names are missing or empty");
    } elsif ( ! ref( $columns ) and length( $columns ) ) {
      # should be one or more comma-separated column names
      @columns = split /,\s?/, $columns;
    } elsif ( UNIVERSAL::can($columns, 'column_names') ) {
      @columns = $columns->column_names;
    } elsif ( ref($columns) eq 'HASH' ) {
      @columns = sort keys %$columns;
    } elsif ( ref($columns) eq 'ARRAY' ) {
      @columns = @$columns;
    } else {
      confess("Unsupported column spec '$columns'");
    }
    
    my $values = delete $clauses{'values'};
    my @value_args;
    if ( ! $values ) {
      croak("Values are missing or empty");
    } elsif ( ! ref( $values ) and length( $values ) ) {
      confess("Unsupported values clause!");
    } elsif ( UNIVERSAL::isa( $values, 'HASH' ) ) {
      @value_args = map $values->{$_}, @columns;
    } elsif ( ref($values) eq 'ARRAY' ) {
      @value_args = @$values;
    } else {
      confess("Unsupported values spec '$values'");
    }
    ( scalar @value_args ) or croak("Values are missing or empty");    
    my @values;
    my @v_params;
    foreach my $v ( @value_args ) {
      if ( ! defined($v) ) {
	push @values, 'NULL';
      } elsif ( ! ref($v) ) {
	push @values, '?';
	push @v_params, $v;
      } elsif ( ref($v) eq 'SCALAR' ) {
	push @values, $$v;
      } else {
	Carp::confess( "Can't use '$v' as part of a sql values clause" );
      }
    }
    $sql .= " set " . join ', ', map "$columns[$_] = $values[$_]", 0 .. $#columns;
    push @params, @v_params;
  }
    
  if ( my $criteria = delete $clauses{'criteria'} || delete $clauses{'where'} ){
    ($sql, @params) = $self->sql_where($criteria, $sql, @params);
  }
  
  if ( scalar keys %clauses ) {
    confess("Unsupported $keyword clauses: " . 
      join ', ', map "$_ ('$clauses{$_}')", keys %clauses);
  }
  
  $self->log_sql( $sql, @params );
  
  return( $sql, @params );
}  

########################################################################

=head2 Delete to Remove Data

B<Public Methods:> You can perform database DELETEs with these methods.

=over 4

=item do_delete()

  $sqldb->do_delete( %sql_clauses ) : $row_count

Delete one or more rows in a table in the datasource.

=back

B<Internal Methods:> These methods are called by the public delete methods.

=over 4

=item sql_delete()

  $sqldb->sql_delete ( %sql_clauses ) : $sql_stmt, @params

Generate a SQL delete statement and returns it as a query string and a list of values to be bound as parameters. Internally, this sql_ method is used by the do_ method above.

=back

B<SQL Delete Clauses>: The above delete methods accept a hash describing the clauses of the SQL statement they are to generate, and require a value for one or more of the following keys: 

=over 4

=item 'sql'

Optional; conflicts with 'table' argument. May contain a plain SQL statement to be executed, or a reference to an array of a SQL statement followed by parameters for embedded placeholders.

=item 'named_query' 

Uses the named_query catalog to build the query. May contain a defined query name, or a reference to an array of a query name followed by parameters to be handled by interpret_named_query. See L</"NAMED QUERY CATALOG"> for details.

=item 'table' 

Required unless explicit "sql => ..." is used. The name of the table to delete from.

=item 'where' I<or> 'criteria'

Optional, but remember that ommitting this will cause all of your rows to be deleted! May contain a literal SQL where clause, an array ref with a SQL clause and parameter list, a hash of field => value pairs, or an object that supports a sql_where() method. See the sql_where() method for details.

=back

B<Examples:> These samples demonstrate use of the delete feature.

=over 2

=item *

Here's a basic delete with a table name and criteria.

  $sqldb->do_delete( 
    table => 'students', where => { 'name'=>'Dave' } 
  );

=item *

You can use your own arbitrary SQL and placeholders:

  $sqldb->do_delete( 
    sql => [ 'delete from students where name = ?', 'Dave' ]
  );

=item *

You can combine an explicit delete statement with dynamic criteria:

  $sqldb->do_delete( 
    sql => 'delete from students', where => { 'name'=>'Dave' } 
  );

=item *

And the named_query interface is supported as well:

  $sqldb->define_named_query(
    'delete_by_name' => 'delete from students where name = ?'
  );
  $hashes = $sqldb->do_delete( 
    named_query => [ 'delete_by_name', 'Dave' ]
  );

=back

=cut

# $rows = $self->do_delete( %clauses );
sub do_delete {
  my $self = shift;
  $self->do_sql( $self->sql_delete( @_ ) );
}

sub sql_delete {
  my ( $self, %clauses ) = @_;

  my $keyword = 'delete';
  my ($sql, @params);

  if ( my $named = delete $clauses{'named_query'} ) {
    my %named = $self->interpret_named_query( ref($named) ? @$named : $named );
    %clauses = ( %named, %clauses );
  }

  if ( my $action = delete $clauses{'action'} ) {
    confess("Action mismatch: expecting $keyword, not $action query") 
	unless ( $action eq $keyword );
  }
  
  if ( my $literal = delete $clauses{'sql'} ) {
    ($sql, @params) = ( ref($literal) eq 'ARRAY' ) ? @$literal : $literal;
    if ( my ( $conflict ) = grep $clauses{$_}, qw/ table / ) { 
      croak("Can't build a $keyword query using both sql and $conflict clauses")
    }
  
  } else {
    
    my $table = delete $clauses{'table'};
    if ( ! $table ) {
      confess("Table name is missing or empty");
    } elsif ( ! ref( $table ) and length( $table ) ) {
      # should be a single table name
    } else {
      confess("Unsupported table spec '$table'");
    }
    $sql = "delete from $table";
  }
    
  if ( my $criteria = delete $clauses{'criteria'} || delete $clauses{'where'} ){
    ($sql, @params) = $self->sql_where($criteria, $sql, @params);
  }
  
  if ( scalar keys %clauses ) {
    confess("Unsupported $keyword clauses: " . 
      join ', ', map "$_ ('$clauses{$_}')", keys %clauses);
  }
  
  $self->log_sql( $sql, @params );
  
  return( $sql, @params );
}

########################################################################

########################################################################

=head1 NAMED QUERY CATALOG

The following methods manage a collection of named query definitions. 

=head2 Defining Named Queries

B<Public Methods:> Call these methods to load your query definitions.

=over 4

=item define_named_queries()

  $sqldb->define_named_query( $query_name, $query_info )
  $sqldb->define_named_queries( $query_name, $query_info, ... )
  $sqldb->define_named_queries( %query_names_and_info )

Defines one or more named queries using the names and definitions provided.

The definition for each query is expected to be in one of the following formats:

=over 4

=item *

A literal SQL string. May contain "?" placeholders whose values will be passed as arguments when the query is run.

=item *

A reference to an array of a SQL string and placeholder parameters. Parameters which should later be replaced by per-query arguments can be represented by references to the special Perl variables $1, $2, $3, and so forth, corresponding to the order and number of parameters to be supplied. 

=item *

A reference to a hash of clauses supported by one of the SQL generation methods. Items which should later be replaced by per-query arguments can be represented by references to the special Perl variables $1, $2, $3, and so forth. 

=item *

A reference to a subroutine or code block which will process the user-supplied arguments and return either a SQL statement, a reference to an array of a SQL statement and associated parameters, or a list of key-value pairs to be used as clauses by the SQL generation methods. 

=back


=item define_named_queries_from_text()

  $sqldb->define_named_queries_from_text($query_name, $query_info_text)
  $sqldb->define_named_queries_from_text(%query_names_and_info_text)

Defines one or more queries, using some special processing to facilitate storing dynamic query definitions in an external source such as a text file or database table. 

The interpretation of each definition is determined by its first non-whitespace character:

=over 4

=item * 

Definitions which begin with a [ or { character are presumed to contain an array or hash definition and are evaluated immediately.

=item * 

Definitions which begin with a " or ; character are presumed to contain a code definition and evaluated as the contents of an anonymous subroutine. 

=item * 

Other definitions are assumed to contain a plain SQL statement.

=back

All evaluations are done via a Safe compartment, which is required when this function is first used, so the code is extremely limited and can not call most other functions. 

=back

=cut

# $sqldb->define_named_queries( $name, $string_hash_or_sub )
sub define_named_queries {
  my $self = shift;
  while ( scalar @_ ) {
    $self->named_queries( splice( @_, 0, 2 ) )
  }
}
sub define_named_query { (shift)->define_named_queries(@_) }

# $sqldb->define_named_queries_from_text( $name, $string )
sub define_named_queries_from_text {
  my $self = shift;
  while ( scalar @_ ) {
    my ( $name, $text ) = splice( @_, 0, 2 );
    my $query_def = do {
      if ( $text =~ /^\s*[\[|\{]/ ) {
	safe_eval_with_parameters( $text );
      } elsif ( $text =~ /^\s*[\"|\;]/ ) {
	safe_eval_with_parameters( "sub { $text }" );
      } else {
	$text
      }
    };
    $self->define_named_queries( $name, $query_def );
  }
}

########################################################################

=head2 Interpreting Named Queries

B<Internal Methods:> These methods are called internally when named queries are used.

=over 4

=item named_queries()

  $sqldb->named_queries() : %query_names_and_info
  $sqldb->named_queries( $query_name ) : $query_info
  $sqldb->named_queries( \@query_names ) : @query_info
  $sqldb->named_queries( $query_name, $query_info, ... )
  $sqldb->named_queries( \%query_names_and_info )

Accessor and mutator for a hash mappping query names to their definitions.
Used internally by the other named_query methods. Created with
Class::MakeMethods::Standard::Inheritable, so if called as a class method,
uses class-wide values, and if called on an instance defaults to its class'
value but may be overridden.

=item named_query()

  $sqldb->named_query( $query_name ) : $query_info

Retrieves the query definition matching the name provided. Croaks if no query has been defined for that name.

=item interpret_named_query()

  $sqldb->interpret_named_query( $query_name, @params ) : %clauses

Combines the query definition matching the name provided with the following arguments and returns the resulting hash of query clauses. Croaks if no query has been defined for that name.

Depending on the definition associated with the name, it is combined with the provided parameters in one the following ways:

=over 4

=item *

A string. Any user-supplied parameters are assumed to be values for embedded "?"-style placeholders. Any parameters passed to interpret_named_query() are collected with the SQL statement in an array reference and returned as the value of a C<sql> key pair for execution. There is no check that the number of parameters match the number of placeholders.

=item *

A reference to an array, possibly with embedded placeholders in the C<\$1> style described above. Uses clone_with_parameters() to make and return a copy of the array, substituting the connection parameters in place of the placeholder references. The array reference is returned as the value of a C<sql> key pair for execution. An exception is thrown if the number of parameters provided does not match the number of special variables referred to. 

=item *

A reference to an hash, possibly with embedded placeholders in the C<\$1> style described above. Uses clone_with_parameters() to make and return a copy of the hash, substituting the connection parameters in place of the placeholder references. An exception is thrown if the number of parameters provided does not match the number of special variables referred to. 

=item *

A reference to a subroutine. The parameters are passed
along to the subroutine and its results returned for execution. The subroutine may return a SQL statement, a reference to an array of a SQL statement and associated parameters, or a list of key-value pairs to be used as clauses by the SQL generation methods. 

=back

For more information about the parameter replacement and argument count checking, see the clone_with_parameters() function from L<DBIx::SQLEngine::Utility::CloneWithParams>.

=back

See the Examples section below for illustrations of these various options.

=cut

use Class::MakeMethods ( 'Standard::Inheritable:hash' => 'named_queries' );

# $query_def = $sqldb->named_query( $name )
sub named_query {
  my ( $self, $name ) = @_;
  $self->named_queries( $name ) or croak("No query named '$name'");
}

# %clauses = $sqldb->interpret_named_query( $name, @args ) 
sub interpret_named_query {
  my ( $self, $name, @query_args ) = @_;
  my $query_def = $self->named_query( $name );
  if ( ! $query_def ) {
    croak("No definition was provided for named query '$name': $query_def")
  } elsif ( ! ref $query_def ) {
    return ( sql => [ $query_def, @query_args ] );
  } elsif ( ref($query_def) eq 'ARRAY' ) {
    return ( sql => clone_with_parameters($query_def, @query_args) );
  } elsif ( ref($query_def) eq 'HASH' ) {
    return ( %{ clone_with_parameters($query_def, @query_args) } );
  } elsif ( ref($query_def) eq 'CODE' ) {
    my @results = $query_def->( @query_args );
    unshift @results, 'sql' if scalar(@results) == 1;
    return @results;
  } else {
    croak("Unable to interpret definition of named query '$name': $query_def")
  }
}

########################################################################

=head2 Executing Named Queries

Typically, named queries are executed by passing a named_query argument to
one of the primary interface methods such as fetch_select or do_insert, but
there are also several convenience methods for use when you know you will
only be using named queries.

B<Public Methods:> These methods provide a simple way to use named queries.

=over 4

=item fetch_named_query()

  $sqldb->fetch_named_query( $query_name, @params ) : $rows
  $sqldb->fetch_named_query( $query_name, @params ) : ( $rows, $columns )

Calls fetch_select using the named query and arguments provided.

=item visit_named_query()

  $sqldb->visit_named_query($query_name, @params, $code) : @results
  $sqldb->visit_named_query($code, $query_name, @params) : @results

Calls visit_select using the named query and arguments provided.

=item do_named_query()

  $sqldb->do_named_query( $query_name, @params ) : $row_count

Calls do_query using the named query and arguments provided.

=back

B<Examples:> These samples demonstrate use of the named_query feature.

=over 2

=item *

A simple named query can be defined in SQL or as generator clauses:

  $sqldb->define_named_query('all_students', 'select * from students');

  $sqldb->define_named_query('all_students', { table => 'students' });

The results of a named select query can be retrieved in several equivalent ways:

  $rows = $sqldb->fetch_named_query( 'all_students' );

  $rows = $sqldb->fetch_select( named_query => 'all_students' );

  @rows = $sqldb->visit_select( named_query => 'all_students', sub { $_[0] } );

=item *

There are numerous ways of defining a query which accepts parameters; any of the following are basically equivalent:

  $sqldb->define_named_query('student_by_id', 
			'select * from students where id = ?' );

  $sqldb->define_named_query('student_by_id', 
	      { sql=>['select * from students where id = ?', \$1 ] } );

  $sqldb->define_named_query('student_by_id', 
	      { table=>'students', where=>[ 'id = ?', \$1 ] } );

  $sqldb->define_named_query('student_by_id', 
	      { table=>'students', where=>{ 'id' => \$1 } } );

  $sqldb->define_named_query('student_by_id', 
    { action=>'select', table=>'students', where=>{ 'id'=>\$1 } } );

Using a named query with parameters requires that the arguments be passed after the name:

  $rows = $sqldb->fetch_named_query( 'student_by_id', $my_id );

  $rows = $sqldb->fetch_select(named_query=>['student_by_id', $my_id]);

If the query is defined using a plain string, as in the first line of the student_by_id example, no checking is done to ensure that the correct number of parameters have been passed; the result will depend on your database server, but will presumably be a fatal error. In contrast, the definitions that use the \$1 format will have their parameters counted and arranged before being executed.

=item *

Queries which insert, update, or delete can be defined in much the same way as select queries are; again, all of the following are roughly equivalent:

  $sqldb->define_named_query('delete_student', 
			    'delete from students where id = ?');

  $sqldb->define_named_query('delete_student', 
		    [ 'delete from students where id = ?', \$1 ]);

  $sqldb->define_named_query('delete_student', 
    { action=>'delete', table=>'students', where=>{ id=>\$1 } });

These modification queries can be invoked with one of the do_ methods:

  $sqldb->do_named_query( 'delete_student', 201 );

  $sqldb->do_query( named_query => [ 'delete_student', 201 ] );

  $sqldb->do_delete( named_query => [ 'delete_student', 201 ] );

=item *

Queries can be defined using subroutines:

  $sqldb->define_named_query('name_search', sub {
    my $name = lc( shift );
    return "select * from students where name like '%$name%'"
  });

  $rows = $sqldb->fetch_named_query( 'name_search', 'DAV' );

=item *

Query definitions can be stored in external text files or database tables and then evaluated into data structures or code references. The below code loads a simple text file of query definitions 

  open( QUERIES, '/path/to/my/queries' );
  my %queries = map { split /\:\s*/, $_, 2 } grep { /^[^#]/ } <QUERIES>;
  close QUERIES;

  $sqldb->define_named_queries_from_text( %queries );

Placing the following text in the target file will define all of the queries used above:

  # Simple query that doesn't take any parameters
  all_students: select * from students
  
  # Query with one required parameter
  student_by_id: [ 'select * from students where id = ?', \$1 ]

  # Generated query using hash format
  delete_student: { action=>'delete', table=>'students', where=>{ id=>\$1 } }
  
  # Perl expression to be turned into a query generating subroutine
  name_search: "select * from students where name like '%\L$_[0]\E%'"

=back

=cut

# ( $row_hashes, $column_hashes ) = $sqldb->fetch_named_query( $name, @args )
sub fetch_named_query {
  (shift)->fetch_select( named_query => [ @_ ] );
}

# @results = $sqldb->visit_named_query( $name, @args, $code_ref )
sub visit_named_query {
  (shift)->visit_select( ( ref($_[0]) ? shift : pop ), named_query => [ @_ ] );
}

# $result = $sqldb->do_named_query( $name, @args )
sub do_named_query {
  (shift)->do_query( named_query => [ @_ ] );
}

########################################################################

# $row_count = $sqldb->do_query( %clauses );
sub do_query {
  my ( $self, %clauses ) = @_;

  if ( my $named = delete $clauses{'named_query'} ) {
    my %named = $self->interpret_named_query( ref($named) ? @$named : $named );
    %clauses = ( %named, %clauses );
  }

  my ($sql, @params);
  if ( my $action = delete $clauses{'action'} ) {
    my $method = "sql_$action";
    ($sql, @params) = $self->$method( %clauses );

  } elsif ( my $literal = delete $clauses{'sql'} ) {
    ($sql, @params) = ( ref($literal) eq 'ARRAY' ) ? @$literal : $literal;
  
  } else {
    croak( "Can't call do_query without either action or sql clauses" );
  }

  $self->do_sql( $sql, @params );
}

########################################################################

########################################################################

=head1 DEFINING STRUCTURES (SQL DDL)

The schema of a DBI database is controlled through the Data Definition Language features of SQL.

=head2 Detect Tables and Columns

B<Public Methods:> These methods provide information about existing tables. 

=over 4

=item detect_table_names()

  $sqldb->detect_table_names () : @table_names

Attempts to collect a list of the available tables in the database we have connected to. Uses the DBI tables() method.

=item detect_table()

  $sqldb->detect_table ( $tablename ) : @columns_or_empty
  $sqldb->detect_table ( $tablename, 1 ) : @columns_or_empty

Attempts to query the given table without retrieving many (or any) rows. Uses a server-specific "trivial" or "guaranteed" query provided by sql_detect_any. 

If succssful, the columns contained in this table are returned as an array of hash references, as described in the Column Information section below.

Catches any exceptions; if the query fails for any reason we return an empty list. The reason for the failure is logged via warn() unless an additional argument with a true value is passed to surpress those error messages.

=back

B<Internal Methods:> These methods are called by the public detect methods.

=over 4

=item sql_detect_table()

  $sqldb->sql_detect_table ( $tablename )  : %sql_select_clauses

Subclass hook. Retrieve something from the given table that is guaranteed to exist but does not return many rows, without knowning its table structure. 

Defaults to "select * from table where 1 = 0", which may not work on all platforms. Your subclass might prefer "select * from table limit 1" or a local equivalent.

=back

=cut

sub detect_table_names {
  my $self = shift;
  $self->get_dbh()->tables();
}

sub detect_table {
  my $self = shift;
  my $tablename = shift;
  my $quietly = shift;
  my @sql;
  my $columns;
  eval {
    local $SIG{__DIE__};
    @sql = $self->sql_detect_table( $tablename );
    ( my($rows), $columns ) = $self->fetch_select( @sql );
  };
  if ( ! $@ ) {
    return @$columns;
  } else {
    warn "Unable to detect_table $tablename: $@" unless $quietly;
    return;
  }
}

sub sql_detect_table {
  my ($self, $tablename) = @_;

  # Your subclass might prefer one of these...
  # return ( sql => "select * from $tablename limit 1" )
  # return ( sql => "select * from $tablename where 1 = 0" )
  
  return (
    table => $tablename,
    where => '1 = 0',
  )
}

########################################################################

=head2 Create and Drop Tables

B<Public Methods:> These methods attempt to create and drop tables.

=over 4

=item create_table()

  $sqldb->create_table( $tablename, $column_hash_ary ) 

Create a table.

The columns to be created in this table are defined as an array of hash references, as described in the Column Information section below.

=item drop_table()

  $sqldb->drop_table( $tablename ) 

Delete the named table.

=back

=cut

# $rows = $self->create_table( $tablename, $columns );
sub create_table {
  my $self = shift;
  $self->do_sql( $self->sql_create_table( @_ ) );
}
sub do_create_table { &create_table }

# $rows = $self->drop_table( $tablename );
sub drop_table {
  my $self = shift;
  $self->do_sql( $self->sql_drop_table( @_ ) );
}
sub do_drop_table { &drop_table }

=pod

B<Column Information>: The information about columns is presented as an array of hash references, each containing the following keys:

=over 4

=item *

C<name =E<gt> $column_name_string>

Defines the name of the column. 

B<Portability:> No case or length restrictions are imposed on column names, but for incresased compatibility, you may wish to stick with single-case strings of moderate length.

=item *

C<type =E<gt> $column_type_constant_string>

Specifies the type of column to create. Discussed further below.

=item *

C<required =E<gt> $not_nullable_boolean>

Indicates whether a value for this column is required; if not, unspecified or undefined values will be stored as NULL values. Defaults to false.

=item *

C<length =E<gt> $max_chars_integer>

Only applicable to column of C<type =E<gt> 'text'>. 

Indicates the maximum number of ASCII characters that can be stored in this column.

=back

B<Internal Methods:> The above public methods use the following sql_ methods to generate SQL DDL statements.

=over 4

=item sql_create_table()

  $sqldb->sql_create_table ($tablename, $columns) : $sql_stmt

Generate a SQL create-table statement based on the column information. Text columns are checked with sql_create_column_text_length() to provide server-appropriate types.

=item sql_create_columns()

  $sqldb->sql_create_columns( $column, $fragment_array_ref ) : $sql_fragment

Generates the SQL fragment to define a column in a create table statement.

=item sql_drop_table()

  $sqldb->sql_drop_table ($tablename) : $sql_stmt

=back

=cut

sub sql_create_table {
  my($self, $table, $columns) = @_;
  
  my @sql_columns;
  foreach my $column ( @$columns ) {
    push @sql_columns, $self->sql_create_columns($table, $column, \@sql_columns)
  }
  
  my $sql = "create table $table ( \n" . join(",\n", @sql_columns) . "\n)\n";
  
  $self->log_sql( $sql );
  return $sql;
}

sub sql_create_columns {
  my($self, $table, $column, $columns) = @_;
  my $name = $column->{name};
  my $type = $self->sql_create_column_type( $table, $column, $columns ) ;
  if ( $type eq 'primary' ) {
    return "PRIMARY KEY ($name)";
  } else {
    return '  ' . $name . 
	    ' ' x ( ( length($name) > 31 ) ? 1 : ( 32 - length($name) ) ) .
	    $type . 
	    ( $column->{required} ? " not null" : '' );
  }
}

sub sql_drop_table {
  my ($self, $table) = @_;
  my $sql = "drop table $table";
  $self->log_sql( $sql );
  return $sql;
}

########################################################################

=head2 Column Type Methods

The following methods are used by sql_create_table to specify column information in a DBMS-specific fashion.

B<Internal Methods:> These methods are used to build create table statements.

=over 4

=item sql_create_column_type()

  $sqldb->sql_create_column_type ( $table, $column, $columns ) : $col_type_str

Returns an appropriate 

=item dbms_create_column_types()

  $sqldb->dbms_create_column_types () : %column_type_codes

Subclass hook. Defaults to empty. Should return a hash mapping column type codes to the specific strings used in a SQL create statement for such a column. 

Subclasses should provide at least two entries, for the symbolic types referenced elsewhere in this interface, "sequential" and "binary".

=item sql_create_column_text_length()

  $sqldb->sql_create_column_text_length ( $length ) : $col_type_str

Returns "varchar(length)" for values under 256, otherwise calls dbms_create_column_text_long_type.

=item dbms_create_column_text_long_type()

  $sqldb->dbms_create_column_text_long_type () : $col_type_str

Fails with message "DBMS-Specific Function".

Subclasses should, based on the datasource's server_type, return the appropriate type of column for long text values, such as "BLOB", "TEXT", "LONGTEXT", or "MEMO".

=back

=cut

sub sql_create_column_type {
  my($self, $table, $column, $columns) = @_;
  my $type = $column->{type};
  
  my %dbms_types = $self->dbms_create_column_types;
  if ( my $dbms_type = $dbms_types{ $type } ) {
    $type = $dbms_type;
  }
  
  if ( $type eq 'text' ) {
    $type = $self->sql_create_column_text_length( $column->{length} || 255 ) ;
  } elsif ( $type eq 'binary' ) {
    $type = $self->sql_create_column_text_length( $column->{length} || 65535 ) ;
  }
  
  return $type;
}

sub sql_create_column_text_length {
  my $self = shift;
  my $length = shift;

  return "varchar($length)" if ($length < 256);
  return $self->dbms_create_column_text_long_type;
}

sub dbms_create_column_text_long_type {
  confess("DBMS-Specific Function")
}

sub dbms_create_column_types {
  return ()
}

########################################################################

=head2 Generating Schema and Record Objects

The object mapping layer provides classes for Record, Table and Column objects which fetch and store information from a SQLEngine Driver. 

Those objects relies on a Driver, typically passed to their constructor or initializer. The following convenience methods let you start this process from your current SQLEngine Driver object.

B<Public Methods:> The following methods provide access to objects
which represent tables, columns and records in a given Driver. They
each ensure the necessary classes are loaded using require().

=over 4

=item tables()

  $sqldb->tables() : $tableset

Returns a new DBIx::SQLEngine::Schema::TableSet object containing table objects with the names discovered by detect_table_names(). See L<DBIx::SQLEngine::Schema::TableSet> for more information on this object's interface.

=item table()

  $sqldb->table( $tablename ) : $table

Returns a new DBIx::SQLEngine::Schema::Table object with this SQLEngine Driver and the given table name. See L<DBIx::SQLEngine::Schema::Table> for more information on this object's interface.

=item record_class()

  $sqldb->record_class( $tablename ) : $record_class
  $sqldb->record_class( $tablename, $classname ) : $record_class
  $sqldb->record_class( $tablename, $classname, @traits ) : $record_class

Generates a Record::Class which corresponds to the given table name. Note that the record class is a class name, not an object. If no class name is provided, one is generated based on the table name. See L<DBIx::SQLEngine::Record::Base> for more information on this object's interface.

=back

=cut

sub tables {
  my $self = shift;
  require DBIx::SQLEngine::Schema::TableSet;
  DBIx::SQLEngine::Schema::TableSet->new( 
    map { $self->table( $_ ) } $self->detect_table_names 
  )
}

sub table {
  require DBIx::SQLEngine::Schema::Table;
  DBIx::SQLEngine::Schema::Table->new( sqlengine => (shift), name => (shift) )
}

sub record_class {
  (shift)->table( shift )->record_class( @_ )
}

########################################################################

########################################################################

=head1 ADVANCED CAPABILITIES

Not all of the below capabilities will be available on all database servers. 

For application reliability, call the relevant *_unsupported methods to confirm that the database you've connected to has the capabilities you require, and either exit with a warning or use some type of fallback strategy if they are not.

=head2 Database Capability Information

Note: this feature has been added recently, and the interface is subject to change.

The following methods all default to returning undef, but may be overridden by subclasses to return a true or false value, indicating whether their connection has this limitation.

B<Public Methods:> These methods return driver class capability information.

=over 4

=item dbms_detect_tables_unsupported()

Can the database driver return a list of tables that currently exist? (True for some simple drivers like CSV.)

=item dbms_joins_unsupported()

Does the database driver support select statements with joins across multiple tables? (True for some simple drivers like CSV.)

=item dbms_union_unsupported()

Does the database driver support select queries with unions to join the results of multiple select statements? (True for many simple databases.)

=item dbms_drop_column_unsupported()

Does the database driver have a problem removing a column from an existing table? (True for Postgres.)

=item dbms_column_types_unsupported()

Does the database driver store column type information, or are all columns the same type? (True for some simple drivers like CSV.)

=item dbms_null_becomes_emptystring()

Does the database driver automatically convert null values in insert and update statements to empty strings? (True for some simple drivers like CSV.)

=item dbms_emptystring_becomes_null()

Does the database driver automatically convert empty strings in insert and update statements to null values? (True for Oracle.)

=item dbms_placeholders_unsupported()

Does the database driver support having ? placehoders or not? (This is a problem for Linux users of DBD::Sybase connecting to MS SQL Servers on Windows.)

=item dbms_transactions_unsupported()

Does the database driver support real transactions with rollback and commit or not? 

=item dbms_multi_sth_unsupported()

Does the database driver support having multiple statement handles active at once or not? (This is a problem for several types of drivers.)

=item dbms_indexes_unsupported()

Does the database driver support server-side indexes or not?

=item dbms_storedprocs_unsupported()

Does the database driver support server-side stored procedures or not?

=back

=cut

sub dbms_select_table_as_unsupported { undef }

sub dbms_joins_unsupported { undef }
sub dbms_join_on_unsupported { undef }
sub dbms_outer_join_unsupported { undef }

sub dbms_union_unsupported { undef }

sub dbms_detect_tables_unsupported { undef }
sub dbms_drop_column_unsupported { undef }

sub dbms_column_types_unsupported { undef }
sub dbms_null_becomes_emptystring { undef }
sub dbms_emptystring_becomes_null { undef }

sub dbms_placeholders_unsupported { undef }
sub dbms_multi_sth_unsupported { undef }

sub dbms_transactions_unsupported { undef }
sub dbms_indexes_unsupported { undef }
sub dbms_storedprocs_unsupported { undef }

########################################################################

=head2 Begin, Commit and Rollback Transactions

Note: this feature has been added recently, and the interface is subject to change.

DBIx::SQLEngine assumes auto-commit is on by default, so unless otherwise specified, each query is executed as a separate transaction. To execute multiple queries within a single transaction, use the as_one_transaction method.

B<Public Methods:> These methods invoke transaction functionality.

=over 4

=item are_transactions_supported()

  $boolean = $sqldb->are_transactions_supported( );

Checks to see if the database has transaction support.

=item as_one_transaction()

  @results = $sqldb->as_one_transaction( $sub_ref, @args );

Starts a transaction, calls the given subroutine with any arguments provided,
and then commits the transaction; if an exception occurs, the transaction is
rolled back instead.  Will fail if we don't have transaction support.

For example:

  my $sqldb = DBIx::SQLEngine->new( ... );
  $sqldb->as_one_transaction( sub { 
    $sqldb->do_insert( ... );
    $sqldb->do_update( ... );
    $sqldb->do_delete( ... );
  } );

Or using a reference to a predefined subroutine:

  sub do_stuff {
    my $sqldb = shift;
    $sqldb->do_insert( ... );
    $sqldb->do_update( ... );
    $sqldb->do_delete( ... );
    1;
  }
  
  my $sqldb = DBIx::SQLEngine->new( ... );
  $sqldb->as_one_transaction( \&do_stuff, $sqldb )
    or warn "Unable to complete transaction";

=item as_one_transaction_if_supported()

  @results = $sqldb->as_one_transaction_if_supported($sub_ref, @args)

If transaction support is available, this is equivalent to as_one_transaction.
If transactions are not supported, simply performs the code in $sub_ref with
no transaction protection. 

This is obviously not very reliable, but may be of use in some ad-hoc utilities or test scripts.

=back

=cut

sub are_transactions_supported {
  my $self = shift;
  my $dbh = $self->get_dbh;
  eval {
    local $SIG{__DIE__};
    $dbh->begin_work;
    $dbh->rollback;
  };
  return ( $@ ) ? 0 : 1;
}

sub as_one_transaction {
  my $self = shift;
  my $code = shift;

  my $dbh = $self->get_dbh;
  my @results;
  $dbh->begin_work;
  my $wantarray = wantarray(); # Capture before eval which otherwise obscures it
  eval {
    local $SIG{__DIE__};
    @results = $wantarray ? &$code( @_ ) : scalar( &$code( @_ ) );
    $dbh->commit;  
  };
  if ($@) {
    warn "DBIx::SQLEngine Transaction Aborted: $@";
    $dbh->rollback;
  }
  $wantarray ? @results : $results[0]
}

sub as_one_transaction_if_supported {
  my $self = shift;
  my $code = shift;
  
  my $dbh = $self->get_dbh;
  my @results;
  my $in_transaction;
  my $wantarray = wantarray(); # Capture before eval which otherwise obscures it
  eval {
    local $SIG{__DIE__};
    $dbh->begin_work;
    $in_transaction = 1;
  };
  eval {
    local $SIG{__DIE__};
    @results = $wantarray ? &$code( @_ ) : scalar( &$code( @_ ) );
    $dbh->commit if ( $in_transaction );
  };
  if ($@) {
    warn "DBIx::SQLEngine Transaction Aborted: $@";
    $dbh->rollback if ( $in_transaction );
  }
  $wantarray ? @results : $results[0]
}

########################################################################

=head2 Create and Drop Indexes

Note: this feature has been added recently, and the interface is subject to change.

B<Public Methods:> These methods create and drop indexes.

=over 4

=item create_index()

  $sqldb->create_index( %clauses )

=item drop_index()

  $sqldb->drop_index( %clauses )

=back

B<Internal Methods:> These methods are called by the public index methods.

=over 4

=item sql_create_index()

  $sqldb->sql_create_index( %clauses ) : $sql, @params

=item sql_drop_index()

  $sqldb->sql_drop_index( %clauses ) : $sql, @params

=back

B<Examples:> These samples demonstrate use of the index feature.

=over 2

=item *

  $sqldb->create_index( 
    table => $table_name, columns => @columns
  );

  $sqldb->drop_index( 
    table => $table_name, columns => @columns
  );

=item *

  $sqldb->create_index( 
    name => $index_name, table => $table_name, columns => @columns
  );

  $sqldb->drop_index( 
    name => $index_name
  );

=back

=cut

sub create_index { 
  my $self = shift;
  $self->do_sql( $self->sql_create_index( @_ ) );
}

sub drop_index   { 
  my $self = shift;
  $self->do_sql( $self->sql_drop_index( @_ ) );
}

sub sql_create_index { 
  my ( $self, %clauses ) = @_;

  my $keyword = 'create';
  my $obj_type = 'index';
  
  my $table = delete $clauses{'table'};
  if ( ! $table ) {
    confess("Table name is missing or empty");
  } elsif ( ! ref( $table ) and length( $table ) ) {
    # should be a single table name
  } else {
    confess("Unsupported table spec '$table'");
  }

  my $columns = delete $clauses{'column'} || delete $clauses{'columns'};
  if ( ! $columns ) {
    confess("Column names is missing or empty");
  } elsif ( ! ref( $columns ) and length( $columns ) ) {
    # should be one or more comma-separated column names
  } elsif ( UNIVERSAL::can($columns, 'column_names') ) {
    $columns = join ', ', $columns->column_names;
  } elsif ( ref($columns) eq 'ARRAY' ) {
    $columns = join ', ', @$columns;
  } else {
    confess("Unsupported column spec '$columns'");
  }
  
  my $name = delete $clauses{'name'};
  if ( ! $name ) {
    $name = join('_', $table, split(/\,\s*/, $columns), 'idx');
  } elsif ( ! ref( $name ) and length( $name ) ) {
    # should be an index name
  } else {
    confess("Unsupported name spec '$name'");
  }
  
  if ( my $unique = delete $clauses{'unique'} ) {
    $obj_type = "unique index";
  }
  
  return "$keyword $obj_type $name on $table ( $columns )";
}

sub sql_drop_index   { 
  my ( $self, %clauses ) = @_;

  my $keyword = 'create';
  my $obj_type = 'index';
    
  my $name = delete $clauses{'name'};
  if ( ! $name ) {
    my $table = delete $clauses{'table'};
    if ( ! $table ) {
      confess("Table name is missing or empty");
    } elsif ( ! ref( $table ) and length( $table ) ) {
      # should be a single table name
    } else {
      confess("Unsupported table spec '$table'");
    }
  
    my $columns = delete $clauses{'column'} || delete $clauses{'columns'};
    if ( ! $columns ) {
      confess("Column names is missing or empty");
    } elsif ( ! ref( $columns ) and length( $columns ) ) {
      # should be one or more comma-separated column names
    } elsif ( UNIVERSAL::can($columns, 'column_names') ) {
      $columns = join ', ', $columns->column_names;
    } elsif ( ref($columns) eq 'ARRAY' ) {
      $columns = join ', ', @$columns;
    } else {
      confess("Unsupported column spec '$columns'");
    }

    $name = join('_', $table, split(/\,\s*/, $columns), 'idx');
  } elsif ( ! ref( $name ) and length( $name ) ) {
    # should be an index name
  } else {
    confess("Unsupported name spec '$name'");
  }

  return "$keyword $obj_type $name";
}

########################################################################

=head2 Call, Create and Drop Stored Procedures

Note: this feature has been added recently, and the interface is subject to change.

These methods are all subclass hooks. Fail with message "DBMS-Specific Function".

B<Public Methods:> These methods create, drop, and use stored procedures.

=over 4

=item fetch_storedproc()

  $sqldb->fetch_storedproc( $proc_name, @arguments ) : $rows

=item do_storedproc()

  $sqldb->do_storedproc( $proc_name, @arguments ) : $row_count

=item create_storedproc()

  $sqldb->create_storedproc( $proc_name, $definition )

=item drop_storedproc()

  $sqldb->drop_storedproc( $proc_name )

=back

=cut

sub fetch_storedproc  { confess("DBMS-Specific Function") }
sub do_storedproc     { confess("DBMS-Specific Function") }
sub create_storedproc { confess("DBMS-Specific Function") }
sub drop_storedproc   { confess("DBMS-Specific Function") }

########################################################################

=head2 Create and Drop Databases

Note: this feature has been added recently, and the interface is subject to change.

B<Public Methods:> These methods create and drop database partitions.

=over 4

=item create_database()

  $sqldb->create_database( $db_name )

Fails with message "DBMS-Specific Function".

=item drop_database()

  $sqldb->drop_database( $db_name )

Fails with message "DBMS-Specific Function".

=back

=cut

sub create_database { confess("DBMS-Specific Function") }
sub drop_database   { confess("DBMS-Specific Function") }

sub sql_create_database { 
  my ( $self, $name ) = @_;
  return "create database $name"
}

sub sql_drop_database { 
  my ( $self, $name ) = @_;
  return "drop database $name"
}

########################################################################

########################################################################

=head1 CONNECTION METHODS (DBI DBH)

The following methods manage the DBI database handle through which we communicate with the datasource.

=head2 Accessing the DBH

B<Public Methods:> You may use these methods to perform your own low-level DBI access.

=over 4

=item get_dbh()

  $sqldb->get_dbh () : $dbh

Get the current DBH

=item dbh_func()

  $sqldb->dbh_func ( $func_name, @args ) : @results

Calls the DBI func() method on the database handle returned by get_dbh, passing the provided function name and arguments. See the documentation for your DBD driver to learn which functions it supports.

=back

=cut

sub get_dbh {
  # maybe add code here to check connection status.
  # or maybe add check once every 10 get_dbh's...
  my $self = shift;
  ( ref $self ) or ( confess("Not a class method") );
  return $self->{dbh};
}

sub dbh_func {
  my $self = shift;
  my $dbh = $self->get_dbh;
  my $func = shift;
  $dbh->func( $func, @_ );
}

########################################################################

=head2 Initialization and Reconnection

B<Internal Methods:> These methods are invoked automatically.

=over 4

=item _init()

  $sqldb->_init () 

Empty subclass hook. Called by DBIx::AnyDBD after connection is made and class hierarchy has been juggled.

=item reconnect()

  $sqldb->reconnect () 

Attempt to re-establish connection with original parameters

=back

=cut

sub _init {  }

sub reconnect {
  my $self = shift;
  my $reconnector = $self->{'reconnector'} 
	or croak("Can't reconnect; reconnector is missing");
  if ( $self->{'dbh'} ) {
    $self->{'dbh'}->disconnect;
  }
  $self->{'dbh'} = &$reconnector()
	or croak("Can't reconnect; reconnector returned nothing");
  $self->rebless;
  $self->_init if $self->can('_init');
  return $self;
}

########################################################################

=head2 Checking For Connection

To determine if the connection is working.

B<Internal Methods:> These methods are invoked automatically.

=over 4

=item detect_any()

  $sqldb->detect_any () : $boolean
  $sqldb->detect_any ( 1 ) : $boolean

Attempts to confirm that values can be retreived from the database,
allowing us to determine if the connection is working, using a
server-specific "trivial" or "guaranteed" query provided by
sql_detect_any.

Catches any exceptions; if the query fails for any reason we return
a false value. The reason for the failure is logged via warn()
unless an additional argument with a true value is passed to surpress
those error messages.

=item sql_detect_any()

  $sqldb->sql_detect_any : %sql_select_clauses

Subclass hook. Retrieve something from the database that is guaranteed to exist. 
Defaults to SQL literal "select 1", which may not work on all platforms. Your database driver might prefer something else, like Oracle's "select 1 from dual".

=item check_or_reconnect()

  $sqldb->check_or_reconnect () : $dbh

Confirms the current DBH is available with detect_any() or calls reconnect().

=back

=cut

sub detect_any {
  my $self = shift;
  my $quietly = shift;
  my $result = 0;
  eval {
    local $SIG{__DIE__};
    $self->fetch_one_value($self->sql_detect_any);
    $result = 1;
  };
  $result or warn "Unable to detect_any: $@" unless $quietly;
  return $result;
}

sub sql_detect_any {
  return ( sql => 'select 1' )
}

sub check_or_reconnect {
  my $self = shift;
  $self->detect_any or $self->reconnect;
  $self->get_dbh or confess("Failed to get_dbh after check_or_reconnect")
}

########################################################################

########################################################################

=head1 STATEMENT METHODS (DBI STH)

The following methods manipulate DBI statement handles as part of processing queries and their results.

B<Portability:> These methods allow arbitrary SQL statements to be executed.
Note that no processing of the SQL query string is performed, so if you call
these low-level functions it is up to you to ensure that the query is correct
and will function as expected when passed to whichever data source the
SQLEngine Driver is using.

=cut

########################################################################

=head2 Generic Query Execution

  $db->do_sql('insert into table values (?, ?)', 'A', 1);
  my $rows = $db->fetch_sql('select * from table where status = ?', 2);

Execute and fetch some kind of result from a given SQL statement.  Internally, these methods are used by the other do_, fetch_ and visit_ methods described above. Each one calls the try_query method with the provided query and parameters, and passes the name of a result method to be used in extracting values from the statement handle.

B<Public Methods:>

=over 4

=item do_sql()

  $sqldb->do_sql ($sql, @params) : $rowcount 

Execute a SQL query by sending it to the DBI connection, and returns the number of rows modified, or -1 if unknown.

=item fetch_sql()

  $sqldb->fetch_sql ($sql, @params) : $row_hash_ary
  $sqldb->fetch_sql ($sql, @params) : ( $row_hash_ary, $columnset )

Execute a SQL query by sending it to the DBI connection, and returns any rows that were produced, as an array of hashrefs, with the values in each entry keyed by column name. If called in a list context, also returns a reference to an array of information about the columns returned by the query.

=item fetch_sql_rows()

  $sqldb->fetch_sql_rows ($sql, @params) : $row_ary_ary
  $sqldb->fetch_sql_rows ($sql, @params) : ( $row_ary_ary, $columnset )

Execute a SQL query by sending it to the DBI connection, and returns any rows that were produced, as an array of arrayrefs, with the values in each entry keyed by column order. If called in a list context, also returns a reference to an array of information about the columns returned by the query.

=item visit_sql()

  $sqldb->visit_sql ($coderef, $sql, @params) : @results
  $sqldb->visit_sql ($sql, @params, $coderef) : @results

Similar to fetch_sql, but calls your coderef on each row, passing it as a hashref, and returns the results of each of those calls. For your convenience, will accept a coderef as either the first or the last argument.

=item visit_sql_rows()

  $sqldb->visit_sql ($coderef, $sql, @params) : @results
  $sqldb->visit_sql ($sql, @params, $coderef) : @results

Similar to fetch_sql, but calls your coderef on each row, passing it as a list of values, and returns the results of each of those calls. For your convenience, will accept a coderef as either the first or the last argument.

=item fetchsub_sql()

  $sqldb->fetchsub_sql ($sql, @params) : $coderef

Execute a SQL query by sending it to the DBI connection, and returns a code reference that can be called repeatedly to invoke the fetchrow_hashref() method on the statement handle. 

=item fetchsub_sql_rows()

  $sqldb->fetchsub_sql_rows ($sql, @params) : $coderef

Execute a SQL query by sending it to the DBI connection, and returns a code reference that can be called repeatedly to invoke the fetchrow_array() method on the statement handle. 


=back

=cut

# $rowcount = $self->do_sql($sql);
# $rowcount = $self->do_sql($sql, @params);
sub do_sql {
  (shift)->try_query( (shift), [ @_ ], 'get_execute_rowcount' )  
}

# $array_of_hashes = $self->fetch_sql($sql);
# $array_of_hashes = $self->fetch_sql($sql, @params);
# ($array_of_hashes, $columns) = $self->fetch_sql($sql);
sub fetch_sql {
  (shift)->try_query( (shift), [ @_ ], 'fetchall_hashref_columns' )  
}

# $array_of_arrays = $self->fetch_sql_rows($sql);
# $array_of_arrays = $self->fetch_sql_rows($sql, @params);
# ($array_of_arrays, $columns) = $self->fetch_sql_rows($sql);
sub fetch_sql_rows {
  (shift)->try_query( (shift), [ @_ ], 'fetchall_arrayref_columns' )  
}

# @results = $self->visit_sql($coderef, $sql, @params);
# @results = $self->visit_sql($sql, @params, $coderef);
sub visit_sql {
  my $self = shift;
  my $coderef = ( ref($_[0]) ? shift : pop );
  $self->try_query( (shift), [ @_ ], 'visitall_hashref', $coderef )
}

# @results = $self->visit_sql_rows($coderef, $sql, @params);
# @results = $self->visit_sql_rows($sql, @params, $coderef);
sub visit_sql_rows {
  my $self = shift;
  my $coderef = ( ref($_[0]) ? shift : pop );
  $self->try_query( (shift), [ @_ ], 'visitall_array', $coderef )
}

# $coderef = $self->fetchsub_sql($sql, @params);
sub fetchsub_sql {
  (shift)->try_query( (shift), [ @_ ], 'fetchsub_hashref' )  
}

# $coderef = $self->fetchsub_sql_rows($sql, @params);
sub fetchsub_sql_rows {
  (shift)->try_query( (shift), [ @_ ], 'fetchsub_array' )  
}

########################################################################

=head2 Statement Error Handling 

B<Internal Methods:>

=over 4

=item try_query()

  $sqldb->try_query ( $sql, \@params, $result_method, @result_args ) : @results

Error handling wrapper around the internal execute_query method.

The $result_method should be the name of a method supported by that
Driver instance, typically one of those shown in the "Retrieving
Rows from an Executed Statement" section below. The @result_args,
if any, are passed to the named method along with the active
statement handle.

=item catch_query_exception()

  $sqldb->catch_query_exception ( $exception, $sql, \@params, 
			$result_method, @result_args ) : $resolution

Exceptions are passed to catch_query_exception; if it returns "REDO"
the query will be retried up to five times. The superclass checks
the error message against the recoverable_query_exceptions; subclasses
may wish to override this to provide specialized handling.

=item recoverable_query_exceptions()

  $sqldb->recoverable_query_exceptions() : @common_error_messages

Subclass hook. Defaults to empty. Subclasses may provide a list of
error messages which represent common communication failures or
other incidental errors.

=back

=cut

# $results = $self->try_query($sql, \@params, $result_method, @result_args);
# @results = $self->try_query($sql, \@params, $result_method, @result_args);
sub try_query {
  my $self = shift;
  
  my $attempts = 0;
  my @results;
  my $wantarray = wantarray(); # Capture before eval which otherwise obscures it
  ATTEMPT: {
    $attempts ++;
    eval {
      local $SIG{__DIE__};

      @results = $wantarray ? $self->execute_query(@_)
		     : scalar $self->execute_query(@_);
    };
    if ( my $error = $@ ) {
      my $catch = $self->catch_query_exception($error, @_);
      if ( ! $catch ) {
	die "DBIx::SQLEngine Query failed: $_[0]\n$error\n";
      } elsif ( $catch eq 'OK' ) {
	return;
      } elsif ( $catch eq 'REDO' ) {
	if ( $attempts < 5 ) {
	  warn "DBIx::SQLEngine Retrying query after failure: $_[0]\n$error";
	  redo ATTEMPT;
	} else {
	  confess("DBIx::SQLEngine Query failed on $attempts consecutive attempts: $_[0]\n$error\n");
	}
      } else {
	confess("DBIx::SQLEngine Query failed: $_[0]\n$error" . 
		"Unknown return from exception handler '$catch'");
      }
    }
    $wantarray ? @results : $results[0]
  }
}

sub catch_query_exception {
  my $self = shift;
  my $error = shift;
  
  foreach my $pattern ( $self->recoverable_query_exceptions() ) {  
    if ( $error =~ /$pattern/i ) {
      $self->reconnect() and return 'REDO';
    }
  }
  
  return;
}

sub recoverable_query_exceptions {
  return ()
}

########################################################################

=head2 Statement Handle Lifecycle 

These are internal methods for query operations

B<Internal Methods:>

=over 4

=item execute_query()

  $sqldb->execute_query($sql, \@params, $result_method, @result_args) : @results

This overall lifecycle method calls prepare_execute(), runs the $result_method, and then calls done_with_query().

The $result_method should be the name of a method supported by that Driver instance, typically one of those shown in the "Retrieving Rows from an Executed Statement" section below. The @result_args, if any, are passed to the named method along with the active statement handle.

=item prepare_execute()

  $sqldb->prepare_execute ($sql, @params) : $sth

Prepare, bind, and execute a SQL statement to create a DBI statement handle.

Uses the DBI prepare_cached(), bind_param(), and execute() methods. 

If you need to pass type information with your parameters, pass a reference to an array of the parameter and the type information.

=item done_with_query()

  $sqldb->done_with_query ($sth) : ()

Called when we're done with the $sth.

=back

=cut

# $results = $self->execute_query($sql, \@params, $result_method, @result_args);
# @results = $self->execute_query($sql, \@params, $result_method, @result_args);
sub execute_query {
  my $self = shift;
  
  my ($sql, $params) = (shift, shift);
  my @query = ( $sql, ( $params ? @$params : () ) );

  my ($method, @args) = @_;
  $method ||= 'do_nothing';

  my $timer = $self->log_start( @query ) if $self->DBILogging;
    
  my ( $sth, @results );
  my $wantarray = wantarray(); # Capture before eval which otherwise obscures it
  eval {
    local $SIG{__DIE__};
    $sth = $self->prepare_execute( @query );
    @results = $wantarray ? ( $self->$method( $sth, @args ) )
		   : scalar ( $self->$method( $sth, @args ) );
  };
  if ( $@ ) {
    $self->done_with_query($sth) if $sth;
    $self->log_stop( $timer, "ERROR: $@" ) if $self->DBILogging;
    die $@;
  } else {
    $self->done_with_query($sth) if $sth;
    
    $self->log_stop( $timer, \@results ) if $self->DBILogging;
    
    return ( $wantarray ? @results : $results[0] )
  }
}

# $sth = $self->prepare_execute($sql);
# $sth = $self->prepare_execute($sql, @params);
sub prepare_execute {
  my ($self, $sql, @params) = @_;
  
  my $sth;
  $sth = $self->prepare_cached($sql);
  for my $param_no ( 0 .. $#params ) {
    my $param_v = $params[$param_no];
    my @param_v = ( ref($param_v) eq 'ARRAY' ) ? @$param_v : $param_v;
    $sth->bind_param( $param_no+1, @param_v );
  }
  $self->{_last_sth_execute} = $sth->execute();
  
  return $sth;
}

# $self->done_with_query( $sth );
sub done_with_query {
  my ($self, $sth) = @_;
  
  $sth->finish;
}

########################################################################

=head2 Retrieving Rows from a Statement

B<Internal Methods:>

=over 4

=item do_nothing()

  $sqldb->do_nothing ($sth) : ()

Does nothing. 

=item get_execute_rowcount()

  $sqldb->get_execute_rowcount ($sth) : $row_count

Returns the row count reported by the last statement executed.

=item fetchall_hashref()

  $sqldb->fetchall_hashref ($sth) : $array_of_hashes

Calls the STH's fetchall_arrayref method with an empty hashref to retrieve all of the result rows into an array of hashrefs.

=item fetchall_hashref_columns()

  $sqldb->fetchall_hashref ($sth) : $array_of_hashes
  $sqldb->fetchall_hashref ($sth) : ( $array_of_hashes, $column_info )

Calls the STH's fetchall_arrayref method with an empty hashref, and if called in a list context, also retrieves information about the columns used in the query result set.

=item fetchall_arrayref()

  $sqldb->fetchall_arrayref ($sth) : $array_of_arrays

Calls the STH's fetchall_arrayref method to retrieve all of the result rows into an array of arrayrefs.

=item fetchall_arrayref_columns()

  $sqldb->fetchall_hashref ($sth) : $array_of_arrays
  $sqldb->fetchall_hashref ($sth) : ( $array_of_arrays, $column_info )

Calls the STH's fetchall_arrayref method, and if called in a list context, also retrieves information about the columns used in the query result set.

=item visitall_hashref()

  $sqldb->visitall_hashref ($sth, $coderef) : ()

Calls coderef on each row with values as hashref, and returns a list of results.

=item visitall_array()

  $sqldb->visitall_array ($sth, $coderef) : ()

Calls coderef on each row with values as list, and returns a list of results.

=item fetchsub_hashref()

  $sqldb->fetchsub_hashref ($sth, $name_uc_or_lc) : $coderef

Returns a code reference that can be called repeatedly to invoke the fetchrow_hashref() method on the statement handle. 

The code reference is blessed so that when it goes out of scope and is destroyed it can call the statement handle's finish() method.

=item fetchsub_array()

  $sqldb->fetchsub_hashref ($sth) : $coderef

Returns a code reference that can be called repeatedly to invoke the fetchrow_array() method on the statement handle. 

The code reference is blessed so that when it goes out of scope and is destroyed it can call the statement handle's finish() method.

=back

=cut

sub do_nothing {
  return;
}

sub get_execute_rowcount {
  my $self = shift;
  return $self->{_last_sth_execute};
}

sub fetchall_arrayref {
  my ($self, $sth) = @_;
  $sth->fetchall_arrayref();
}

sub fetchall_arrayref_columns {
  my ($self, $sth) = @_;
  my $cols = wantarray() ? $self->retrieve_columns( $sth ) : undef;
  my $rows = $sth->fetchall_arrayref();
  wantarray ? ( $rows, $cols ) :   $rows;
}

sub fetchall_hashref {
  my ($self, $sth) = @_;
  $sth->fetchall_arrayref( {} );
}

sub fetchall_hashref_columns {
  my ($self, $sth) = @_;
  my $cols = wantarray() ? $self->retrieve_columns( $sth ) : undef;
  my $rows = $sth->fetchall_arrayref( {} );
  wantarray ? ( $rows, $cols ) :   $rows;
}

# $self->visitall_hashref( $sth, $coderef );
  # Calls a codref for each row returned by the statement handle
sub visitall_hashref {
  my ($self, $sth, $coderef) = @_;
  my $rowhash;
  my @results;
  while ($rowhash = $sth->fetchrow_hashref) {
    push @results, &$coderef( $rowhash );
  }
  return @results;
}

# $self->visitall_array( $sth, $coderef );
  # Calls a codref for each row returned by the statement handle
sub visitall_array {
  my ($self, $sth, $coderef) = @_;
  my @row;
  my @results;
  while (@row = $sth->fetchrow_array) {
    push @results, &$coderef( @row );
  }
  return @results;
}

# $fetchsub = $self->fetchsub_hashref( $sth )
# $fetchsub = $self->fetchsub_hashref( $sth, $name_uc_or_lc )
sub fetchsub_hashref {
  my ($self, $sth, @args) = @_;
  $_[1] = undef;
  DBIx::SQLEngine::Driver::fetchsub->new( $sth, 'fetchrow_hashref', @args );
}

# $fetchsub = $self->fetchsub_array( $sth )
sub fetchsub_array {
  my ($self, $sth) = @_;
  $_[1] = undef;
  DBIx::SQLEngine::Driver::fetchsub->new( $sth, 'fetchrow_array' );
}

FETCHSUB_CLASS: { 
  package DBIx::SQLEngine::Driver::fetchsub;
  
  my $Signal = \"Unique";
  
  sub new {
    my ( $package, $sth, $method, @args ) = @_;
    my $coderef = sub {
      unless ( $_[0] eq $Signal ) {
	$sth->$method( @args, @_ )
      } elsif ( $_[1] eq 'DESTROY' ) {
	$sth->finish() if $sth;
	warn "Fetchsub finish for $sth\n";
	$sth = undef;
      } elsif ( $_[1] eq 'handle' ) {
	return $sth;
      } else {
	Carp::croak( "Unsupported signal to fetchsub: '$_[1]'" );
      }
    };
    bless $coderef, $package;
  }
  
  sub handle {
    my $coderef = shift;
    &$coderef( $Signal => 'handle' )
  }
  
  sub DESTROY {
    my $coderef = shift;
    &$coderef( $Signal => 'DESTROY' )
  }
}

########################################################################

=head2 Retrieving Columns from a Statement

B<Internal Methods:>

=over 4

=item retrieve_columns()

  $sqldb->retrieve_columns ($sth) : $columnset

Obtains information about the columns used in the result set.

=item column_type_codes()

  $sqldb->column_type_codes - Standard::Global:hash

Maps the ODBC numeric constants used by DBI to the names we want to use for simplified internal representation.

=back

To Do: this should probably be using DBI's type_info methods.

=cut

# %@$columns = $self->retrieve_columns($sth)
  #!# 'pri_key' => $sth->is_pri_key->[$i], 
  # is_pri_key causes the driver to fail with the following fatal error:
  #    relocation error: symbol not found: mysql_columnSeek
  # or at least that happens in the version we last tested it with. -S.
  
sub retrieve_columns {
  my ($self, $sth) = @_;
  
  my $type_defs = $self->column_type_codes();
  my $names = $sth->{'NAME_lc'};

  my $types = eval { $sth->{'TYPE'} || [] };
  # warn "Types: " . join(', ', map "'$_'", @$types);
  my $type_codes = [ map { 
	my $typeinfo = scalar $self->type_info($_);
	# warn "Type $typeinfo";
	ref($typeinfo) ? scalar $typeinfo->{'DATA_TYPE'} : $typeinfo;
  } @$types ];
  my $sizes = eval { $sth->{PRECISION} || [] };
  my $nullable = eval { $sth->{'NULLABLE'} || [] };
  [
    map {
      my $type = $type_defs->{ $type_codes->[$_] || 0 } || $type_codes->[$_];
      $type ||= 'text';
      # warn "New col: $names->[$_] ($type / $types->[$_] / $type_codes->[$_])";
      
      {
	'name' => $names->[$_],
	'type' => $type,
	'required' => ! $nullable->[$_],
	( $type eq 'text' ? ( 'length' => $sizes->[$_] ) : () ),
	
      }
    } (0 .. $#$names)
  ];
}

use Class::MakeMethods ( 'Standard::Global:hash' => 'column_type_codes' );
use DBI ':sql_types';

# $code_to_name_hash = $self->determine_column_type_codes();
__PACKAGE__->column_type_codes(
  DBI::SQL_CHAR() => 'text',		# char
  DBI::SQL_VARCHAR() => 'text',		# varchar
  DBI::SQL_LONGVARCHAR() => 'text',	# 
  253			  => 'text', 	# MySQL varchar
  252			  => 'text', 	# MySQL blob
  
  DBI::SQL_NUMERIC() => 'float',	# numeric (?)
  DBI::SQL_DECIMAL() => 'float',	# decimal
  DBI::SQL_FLOAT() => 'float',		# float
  DBI::SQL_REAL() => 'float',		# real
  DBI::SQL_DOUBLE() => 'float',		# double
  
  DBI::SQL_INTEGER() => 'int',		# integer
  DBI::SQL_SMALLINT() => 'int',		# smallint
  -6		=> 'int',		# MySQL tinyint
  
  DBI::SQL_DATE() => 'time',		# date
  DBI::SQL_TIME() => 'time',		# time
  DBI::SQL_TIMESTAMP() => 'time',	# datetime
);

########################################################################

########################################################################

=head1 LOGGING

=head2 DBI Logging

B<Public Methods:>

=over 4

=item DBILogging()

  $sqldb->DBILogging : $value
  $sqldb->DBILogging( $value )

Set this to a true value to turn on logging of DBI interactions. Can be called on the class to set a shared default for all instances, or on any instance to set the value for it alone.

=back

B<Internal Methods:>

=over 4

=item log_connect()

  $sqldb->log_connect ( $dsn )

Writes out connection logging message.

=item log_start()

  $sqldb->log_start( $sql ) : $timer

Called at start of query execution.

=item log_stop()

  $sqldb->log_stop( $timer ) : ()

Called at end of query execution.

=back

=cut

use Class::MakeMethods ( 'Standard::Inheritable:scalar' => 'DBILogging' );

# $self->log_connect( $dsn );
sub log_connect {
  my ($self, $dsn) = @_;
  my $class = ref($self) || $self;
  warn "DBI: Connecting to $dsn\n";
}

# $timer = $self->log_start( $sql );
sub log_start {
  my ($self, $sql, @params) = @_;
  my $class = ref($self) || $self;
  
  my $start_time = time;
  
  my $params = join( ', ', map { defined $_ ? "'" . printable($_) . "'" : 'undef' } @params );
  warn "DBI: $sql; $params\n";
  
  return $start_time;
}

# $self->log_stop( $timer );
# $self->log_stop( $timer, $error_message );
# $self->log_stop( $timer, @$return_values );
sub log_stop { 
  my ($self, $start_time, $results) = @_;
  my $class = ref($self) || $self;
  
  my $message;
  if ( ! ref $results ) {
    $message = "returning an error: $results";
  } elsif ( ref($results) eq 'ARRAY' ) {
    # Successful return
    if ( ! ref( $results->[0] ) ) {
      if ( $results->[0] =~ /^\d+$/ ) {
	$message = "affecting $results->[0] rows";
      } elsif ( $results->[0] eq '0E0' ) {
	$message = "affecting 0 rows";
      } else {
	$message = "producing a value of '$results->[0]'";
      } 
    } elsif ( ref( $results->[0] ) eq 'ARRAY' ) {
      $message = "returning " . scalar(@{ $results->[0] }) . " items";
    } 
  }
  my $seconds = (time() - $start_time or 'less than one' );
  
  warn "DBI: Completed in $seconds seconds" . 
	(defined $message ? ", $message" : '') . "\n";
  
  return;
}

########################################################################

use vars qw( %Printable );
%Printable = ( ( map { chr($_), unpack('H2', chr($_)) } (0..255) ),
	      "\\"=>'\\', "\r"=>'r', "\n"=>'n', "\t"=>'t', "\""=>'"' );

# $special_characters_escaped = printable( $source_string );
sub printable ($) {
  local $_ = ( defined $_[0] ? $_[0] : '' );
  s/([\r\n\t\"\\\x00-\x1f\x7F-\xFF])/\\$Printable{$1}/g;
  return $_;
}

########################################################################

=head2 SQL Logging

B<Public Methods:>

=over 4

=item SQLLogging()

  $sqldb->SQLLogging () : $value 
  $sqldb->SQLLogging( $value )

Set this to a true value to turn on logging of internally-generated SQL statements (all queries except for those with complete SQL statements explicitly passed in by the caller). Can be called on the class to set a shared default for all instances, or on any instance to set the value for it alone.

=back

B<Internal Methods:>

=over 4

=item log_sql()

  $sqldb->log_sql( $sql ) : ()

Called when SQL is generated.

=back

=cut

use Class::MakeMethods ( 'Standard::Inheritable:scalar' => 'SQLLogging' );

# $self->log_sql( $sql );
sub log_sql {
  my ($self, $sql, @params) = @_;
  return unless $self->SQLLogging;
  my $class = ref($self) || $self;
  my $params = join( ', ', map { defined $_ ? "'$_'" : 'undef' } @params );
  warn "SQL: $sql; $params\n";
}

########################################################################

########################################################################

=head2 About Driver Traits

Some features that are shared by several Driver subclasses are implemented as a  package in the Driver::Trait::* namespace.

Because of the way DBIx::AnyDBD munges the inheritance tree,
DBIx::SQLEngine::Driver subclasses can not reliably inherit from mixins. 
To work around this, we export all of the methods into their namespace using Exporter and @EXPORT.

In addition we go through some effort to re-dispatch methods because we can't
rely on SUPER and we don't want to require NEXT. This isn't too complicated,
as we know the munged inheritance tree only uses single inheritance.

Note: this mechanism has been added recently, and the implementation is subject to change.

B<Internal Methods:>

=over 4

=item NEXT()

  $sqldb->NEXT( $method, @args ) : @results

Used by driver traits to redispatch to base-class implementations.

=back

=cut

sub NEXT {
  my ( $self, $method, @args ) = @_;
  
  no strict 'refs';
  my $super = ${ ref($self) . '::ISA' }[0] . "::" . $method;
  # warn "_super_d: $super " . wantarray() . "\n";
  $self->$super( @args );
}

########################################################################

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

For distribution, installation, support, copyright and license 
information, see L<DBIx::SQLEngine::Docs::ReadMe>.

=cut

########################################################################

1;
