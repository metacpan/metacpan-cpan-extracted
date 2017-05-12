package DBIx::SQLEngine;

$VERSION = 0.93;

use DBIx::SQLEngine::Driver;
@ISA = qw( DBIx::SQLEngine::Driver );

1;

__END__

########################################################################

=head1 NAME

DBIx::SQLEngine - Extends DBI with High-Level Operations


=head1 ABSTRACT

The DBIx::SQLEngine class provides an extended interface for the DBI database
framework. Each SQLEngine object is a wrapper around a DBI database handle,
adding methods that support ad-hoc SQL generation and query execution in a
single call. Dynamic subclassing based on database server type enables
cross-platform portability.  An object mapping layer provides classes
for tables, columns, and records.


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

  $sqldb = DBIx::SQLEngine->new( 'test' );

  DBIx::SQLEngine->define_named_queries(
    'all_students'  => 'select * from students',
    'delete_student' => [ 'delete * from students where id = ?', \$1 ],
  );

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

B<Object Mapping:> Classes for tables, columns, and records.

  $table = $sqldb->table('grades');

  $hash_ary = $table->fetch_select(); 

  $table->delete_row( $primary_key ); 

  $sqldb->record_class( 'students', 'My::Student' );

  @records = My::Student->fetch_select( 
		where => 'age > 20',
		order => 'last_name, first_name',
             )->records;

  $record = My::Student->new_with_values( 'first_name' => 'Dave' );
  $record->insert_record();

  $record = My::Student->fetch_record( $primary_key );

  print $record->get_values('first_name', 'last_name');

  $record->change_values( 'status' => 'adult' );
  $record->update_record();

  $record->delete_record();


=head1 DESCRIPTION

DBIx::SQLEngine is the latest generation of a toolkit used by the authors for
several years to develop business data applications. Its goal is to simplify dynamic query execution and to minimize cross-RDMS portability issues.

=head2 Layered Class Framework

DBIx::SQLEngine is an object-oriented framework containing several class hierarchies grouped into three layers. Applications can use the Driver layer directly, or they can use the Schema and Record layers built on top of it.

The Driver layer is the primary and lowest-level layer upon which the other layers depend. Each Driver object contains a DBI database handle and is responsible for generating SQL queries, executing them, and returning the results. These classes are described below in L</"Driver Layer Classes">.

The Schema layer centers around the Table object, which combines a Driver object with the name of a table to perform queries against that table. Table objects keep track of their structure as Column objects, and use that information to facilitate common types of queries. These classes are described below in L</"Schema Layer Classes">. 

The Record layer builds on the Schema layer to create Perl classes which are bound to a given Table object. Your Record subclass can fetch rows from the table which will be blessed into that class, and have methods allowing them to be changed and updated back to the database. These classes are described below in L</"Record Layer Classes">.

=head2 DBI Wrapper

Each DBIx::SQLEngine::Driver object is implemented as a wrapper
around a database handle provided by DBI, the Perl Database Interface.

Arbitrary queries can be executed, bypassing the SQL generation capabilities.
The methods whose names end in _sql, like fetch_sql and do_sql, each accept
a SQL statement and parameters, pass it to the DBI data source, and return
information about the results of the query. Error handling is standardized,
and routine annoyances like timed-out connections are retried automatically.

The Driver also allows direct access to the wrapped database handle,
enabling use of the entire DBI API for cases when high-level interfaces are
insufficient.

Relevant methods are descrbed in the L<Driver Object Creation|DBIx::SQLEngine::Driver/"Driver Object Creation">, L<Connection Methods|DBIx::SQLEngine::Driver/"CONNECTION METHODS (DBI DBH)">, and L<Statement Methods|DBIx::SQLEngine::Driver/"STATEMENT METHODS (DBI STH)"> sections of L<DBIx::SQLEngine::Driver>.

=head2 High-Level Interface

Drivers have a combined query interface provides a useful high-level idiom
to perform the typical cycle of SQL generation, query execution, and results
fetching, all through a single method call.

The various fetch_*, visit_* and do_* methods that don't end in _sql, like
fetch_select and do_insert, are wrappers that combine a SQL-generation and a
SQL-execution method to provide a simple ways to perform a query in one call.

These methods are defined in the L<Fetching Data|DBIx::SQLEngine::Driver/"FETCHING DATA (SQL DQL)">, L<Editing Data|DBIx::SQLEngine::Driver/"EDITING DATA
(SQL DML)">, and L<Defining Structures|DBIx::SQLEngine::Driver/"DEFINING STRUCTURES (SQL DDL)"> sections of L<DBIx::SQLEngine::Driver>.

=head2 Data-Driven SQL

Several Driver methods are responsible for converting their arguments into
commands and placeholder parameters in SQL, the Structured Query Language.

The various methods whose names being with sql_, like sql_select and
sql_insert, each accept a hash of arguments and combines then to return a SQL
statement and corresponding parameters. Data for each clause of the statement
is accepted in multiple formats to facilitate query abstraction, often
including various strings, array refs, and hash refs. Each method also
supports passing arbitrary queries through using a C<sql> parameter.

=head2 Named Definitions

Driver connection arguments and query definitions may be registered in named
collections. The named connection feature allows the definition of names for
sets of connection parameters, while the named query methods support names
for various types of queries in either data-driven or plain-SQL formats.

The definitions may include nested data structures with a special type of
placeholders to be replaced by additional values at run-time. References to
subroutines can also be registed as definitions, to be called at run-time with
any additional values to produce the connection or query arguments.

This functionality is described in the 
L<Named Connections|DBIx::SQLEngine::Driver/"Named Connections"> and 
L<Named Query Catalog|DBIx::SQLEngine::Driver/"NAMED QUERY CATALOG"> 
sections of L<DBIx::SQLEngine::Driver>.

=head2 Portability Subclasses

Behind the scenes, different Driver subclasses are instantiated
depending on the type of server to which you connect, thanks to DBIx::AnyData.

This release includes subclasses for connections to MySQL, PostgreSQL,
Oracle, Informix, Sybase, and Microsoft SQL servers, as well as for the
standalone SQLite, AnyData, CSV and XBase packages. For more information
about supported drivers, see L<DBIx::SQLEngine::Driver/"Driver Subclasses">.

As a result, if you use the data-driven query interface, some range of SQL
dialect ideosyncracies can be compensated for.  For example, the sql_limit
method controls the syntax for select statements with limit and offset
clauses, and both MySQL and Oracle override this method to use their local
syntax.

However, some features can not be effectively emulated; it's no use to pretend
that you're starting a transaction if your database don't have a real atomic
rollback/commit function. In those areas, the subclasses provide capability
methods that allow callers to determine whether the current driver has the
features they require. Features which are only available on a limited number
of platforms are listed in L<DBIx::SQLEngine::Driver/"ADVANCED CAPABILITIES">.

=head2 Object Mapping

Built on top of the core SQLEngine functionality is an object mapping layer
that provides a variety of classes which serve as an alternate interface to
database content.

The Schema classes provide objects for tables and columns which call methods
on a SQLEngine to fetch and store data, while the Record classes provide a
means of creating subclasses whose instances map to to rows in a particular
table using the Schema classes.

Note that this is not a general-purpose "object persistence" system, or even
a full-fledged "object-relational mapping" system. It is rather a
"relational-object mapping" system: each record class is linked to a single
table, each instance to a single row in that table, and each key in the record
hash to a value in an identically named column.

Furthermore, no effort has been made to obscure the relational implementation
behind the object abstraction; for example, if you don't need the portability
provided by the data-driven query interface, you can include arbitrary bits
of SQL in the arguments passed to a method that fetch objects from the
database.

This functionality is described in L</"Schema Layer Classes"> and L</"Record Layer Classes">.

=cut

########################################################################

########################################################################

=head1 DRIVER LAYER

The Driver layer is the primary and lowest-level layer upon which the other layers depend. Each Driver object contains a DBI database handle and is responsible for generating SQL queries, executing them, and returning the results. 

=head2 Driver Layer Classes

=over 2

=item *

Driver objects are wrappers around DBI database handles. 
(See L<DBIx::SQLEngine::Driver>.)

=item *

Criteria objects produce elements of SQL where clauses.
(See L<DBIx::SQLEngine::Criteria>.)

=back

The rest of this section briefly introduces some of the methods provided by the Driver layer.

=head2 Connecting 

Create one SQLEngine Driver for each DBI datasource you will use.

=over 4

=item new()

  DBIx::SQLEngine->new( $dsn, $user, $pass ) : $sqldb
  DBIx::SQLEngine->new( $dbh ) : $sqldb
  DBIx::SQLEngine->new( $cnxn_name, @params ) : $sqldb

Creates a Driver object with associated DBI database handle

=item define_named_connections()

  DBIx::SQLEngine->define_named_connections( $name, $cnxn_info )

Defines one or more named connections using the names and definitions provided.

=back

Examples:

=over 2

=item *

Here's a connection wrapped around an existing DBI database handle.

  $dbh = DBI->connect( 'dbi:mysql:livedata', $user, $password );
  
  $sqldb = DBIx::SQLEngine->new( $dbh );

=item *

This example shows the use of connection parameters.

  $sqldb = DBIx::SQLEngine->new( 'dbi:mysql:livedata', $user, $password );

=item *

The parameters may be defined first and then used later.

  DBIx::SQLEngine->define_named_connections( 
    'production' => [ 'dbi:mysql:livedata', \$1, \$2 ],
  );

  $sqldb = DBIx::SQLEngine->new( 'production', $user, $password );

=back


=head2 Select to Retrieve Data

The following methods may be used to retrieve data using SQL select statements. 

=over 4

=item fetch_select()

  $sqldb->fetch_select( %sql_clauses ) : $row_hashes
  $sqldb->fetch_select( %sql_clauses ) : ($row_hashes,$column_hashes)

Retrieve rows from the datasource as an array of hashrefs. If called in a list context, also returns an array of hashrefs containing information about the columns included in the result set.

=item visit_select()

  $sqldb->visit_select( $code_ref, %sql_clauses ) : @results
  $sqldb->visit_select( %sql_clauses, $code_ref ) : @results

Retrieve rows from the datasource as a series of hashrefs, and call the user provided function for each one. Returns the results returned by each of those function calls. 

=back

Examples:

=over 2

=item *

Queries can use their own SQL queries and placeholder values.

  $hashes = $sqldb->fetch_select( 
    sql => [ 'select * from students where status = ?', 'minor' ]
  );

=item *

Data-driven SQL generation converts arguments to queries.

  $hashes = $sqldb->fetch_select( 
    table => 'students', where => { 'status' => 'minor' } 
  );

=item *

Visit methods allow processing results one row at a time.

  my @firstnames = $sqldb->visit_select( 
    table => 'student', order => 'name',
    sub {
      my $student = shift;
      ( $student->{name} =~ /(\w+)\s/ ) ? $1 : $student->{name};
    }, 
  );

=item *

Limit and offset arguments retrieve a subset of the rows.

  $hash_ary = $sqldb->fetch_select( 
    table => 'students', order => 'name',
    limit => 20, offset => 100,    
  );

=item *

Inner joins can be specified by a hash of joining criteria.

  $hashes = $sqldb->fetch_select( 
    tables => { 'students.id' => 'grades.student_id' },
    order => 'students.name'
  );

=item *

Joins can also be constructed between multiple tables.

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

Unions combine the results of multiple queries.

  $hash_ary = $sqldb->fetch_select( 
    union=>[ { table=>'students', columns=>'first_name, last_name' },
	     { table=>'staff',    columns=>'name_f, name_l' }, ],
  );

=back

=head2 Insert, Update and Delete 

You can perform database modifications with these methods.

=over 4

=item do_insert()

  $sqldb->do_insert( %sql_clauses ) : $row_count

Insert a single row into a table in the datasource. Should return 1, unless there's an exception.

=item do_update()

  $sqldb->do_update( %sql_clauses ) : $row_count

Modify one or more rows in a table in the datasource.

=item do_delete()

  $sqldb->do_delete( %sql_clauses ) : $row_count

Delete one or more rows in a table in the datasource.

=back

Examples:

=over 2

=item *

Here's a simple insert using a hash of column-value pairs:

  $sqldb->do_insert( 
    table => 'students', 
    values => { 'name'=>'Dave', 'age'=>'19', 'status'=>'minor' } 
  );

=item *

Here's a basic update statement with a hash of columns-value pairs to change:

  $sqldb->do_update( 
    table => 'students', 
    where => 'age > 20', 
    values => { 'status'=>'adult' } 
  );

=item *

Here's a basic delete with a table name and criteria.

  $sqldb->do_delete( 
    table => 'students', where => { 'name'=>'Dave' } 
  );

=back

=head2 Named Query Catalog

These methods manage a collection of named query definitions. 

=over 4

=item define_named_queries()

  $sqldb->define_named_queries( $query_name, $query_info )

Defines one or more named queries using the names and definitions provided.

=back

Examples:

=over 2

=item *

Here's a defined query used to fetch matching rows.

  $sqldb->define_named_query( 'minor_students' => {
    table => 'students', where => { 'status' => 'minor' } 
  } );

  $hashes = $sqldb->fetch_select( 
    named_query => 'minor_students' 
  );

=item *

This defined query generates SQL for an update.

  $sqldb->define_named_query( 'majority_age' => {
    action => 'update',
    table => 'students', 
    where => 'age > 20', 
    values => { 'status'=>'adult' } 
  } );

  $rowcount = $sqldb->do_update( 
    named_query => 'majority_age' 
  );

=item *

The placeholder in this defined query is replaced at run-time.

  $sqldb->define_named_query( 'delete_name' => {
    action => 'delete',
    table => 'students', 
    where => { 'name'=> \$1 } 
  } );

  $rowcount = $sqldb->do_delete( 
    named_query => [ 'delete_name', 'Dave' ]
  );

=back

=cut

########################################################################

########################################################################

=head1 SCHEMA LAYER

The Schema layer centers around the Table object, which combines a Driver object with the name of a table to perform queries against that table. Table objects keep track of their structure as Column objects, and use that information to facilitate common types of queries.

=head2 Schema Layer Classes

=over 2

=item *

Column objects are very simple structures that hold information about columns in a database table or query result.
(See L<DBIx::SQLEngine::Column>.)

=item *

ColumnSet objects contain an array of Column objects
(See L<DBIx::SQLEngine::ColumnSet>.)

=item *

Table objects represent database tables accessible via a particular DBIx::SQLEngine.
(See L<DBIx::SQLEngine::Table>.)

=item *

TableSet objects contain an array of Table objects
(See L<DBIx::SQLEngine::TableSet>.)

=back

The rest of this section briefly introduces some of the methods provided by the Schema layer.

=head2 Querying Table Objects

Table objects pass the various fetch_ and do_ methods through to the SQLEngine  Driver along with their table name.

=over 2

=item *

Create a Table object for the given driver and table name.

  $table = $sqldb->table( $table_name );

=item *

Perform a select query on the named table.

  $hash_ary = $table->fetch_select( where => { status=>2 } );

=item *

Perform an insert query.

  $table->do_insert( values => { somefield=>'A Value', status=>3 } );

=item *

Perform an update query.

  $table->do_update( values => { status=>3 }, where => { status=>2 } );

=item *

Perform a delete query.

  $table->do_delete( where => { somefield=>'A Value' } );

=back

=head2 Enumerating TableSets

A Schema::TableSet is simply an array of Schema::Table objects.

=over 4

=item count()

  $tableset->count : $number_of_tables

=item tables()

  $tableset->tables : @table_objects

=item table_named()

  $tableset->table_named( $name ) : $table_object

=back

Examples:

=over 2

=item *

Get a TableSet object for the current Driver and print the number of tables it has.

  $tableset = $sqldb->tables();
  print $tableset->count;

=item *

Iterate over the tables.

  foreach my $table ( $tableset->tables ) {
    print $table->name;
  }

=item *

Find a table by name.

  $table = $tableset->table_named( $name );

=back

For more information see the documentation for these packages: L<DBIx::SQLEngine::Schema::Table>, L<DBIx::SQLEngine::Schema::TableSet>, L<DBIx::SQLEngine::Schema::Column>, and L<DBIx::SQLEngine::Schema::ColumnSet>.

=cut

########################################################################

########################################################################

=head1 RECORD LAYER

The Record layer allows you to create Perl classes which are bound to a given Table object. Your Record subclass can fetch rows from the table which will be blessed into that class, and have methods allowing them to be changed and updated back to the database.

=head2 Record Layer Classes

=over 2

=item *

Record objects are hashes which represent rows in a Table.
(See L<DBIx::SQLEngine::Record::Class>.)

=item *

Record Set objects contain an array of Record objects.
(See L<DBIx::SQLEngine::RecordSet::Set>.)

=back

The rest of this section briefly introduces some of the methods provided by the Record layer.

=head2 Setting Up a Record Class

=over 4

=item record_class()

  $sqldb->record_class( $table_name ) : $record_class

=back

Examples:

=over 2

=item *

Generate a record class, giving it a new unique name:

  $class_name = $sqldb->record_class( $table_name );

=item *

Generate a record class with a pre-defined name:

  $sqldb->record_class( $table_name, $class_name );

=back

=head2 Selecting Records

Examples:

=over 2

=item *

Retrieves a set of records meeting some criteria:
  
  $record_set = $class_name->fetch_select( criteria => { status=>2 } );
  
  @records = $record_set->records;

=item *

Retrieves a single record based on its unique primary key:

  $record = $class_name->fetch_record( $primary_key );

=back

=head2 Changing Records

Examples:

=over 2

=item *

Create a new record and insert it into the database:

  $record = $class_name->new_with_values( somefield=>'A Value' );
  $record->insert_record();

=item *

Retrieve an existing record and make a change in it:

  $record = $class_name->fetch_record( $primary_key );
  $record->change( somefield=>'New Value' );
  $record->update_record();

=item *

Delete an existing record:

  $record = $class_name->fetch_record( $primary_key );
  $record->delete_record();

=back

For more information see the documentation for these packages: L<DBIx::SQLEngine::Record::Base> and L<DBIx::SQLEngine::Record::Set>. 

=cut

########################################################################

########################################################################

=head1 EXAMPLES

The following three examples, based on a writeup by Ron Savage, show a connection being opened, a table created, several rows of data inserted, and then retrieved again. Each uses one of the Driver, Table, or Record interfaces to accomplish the same tasks.

=over 2 

=item *

This example uses the basic Driver interface:

  #!/usr/bin/perl
  
  use strict;
  use warnings;
  
  use DBIx::SQLEngine;
  
  my $engine = DBIx::SQLEngine->new(
    'DBI:mysql:test', 'route', 'bier'
  );
  my $table_name = 'sqle';
  my $columns = [
    {
      name   => 'sqle_id',
      type   => 'sequential',
    },
    {
      name   => 'sqle_name',
      type   => 'text',
      length => 255,
    },
  ];
  $engine->drop_table($table_name);
  $engine->create_table($table_name, $columns);

  $engine->do_insert(table=>$table_name, values=>{sqle_name=>'One'});
  $engine->do_insert(table=>$table_name, values=>{sqle_name=>'Two'});
  $engine->do_insert(table=>$table_name, values=>{sqle_name=>'Three'});

  my $dataset = $engine->fetch_select(table => $table_name);
  my $count = 0;
  for my $data (@$dataset) {
    $count++;
    print "Row $count: ", 
	map( {"\t$_ => " . (defined $$data{$_} ? $$data{$_} : 'NULL') }
	      sort keys %$data), 
	"\n";
  }

=item *

The following example shows an identical series of operations using the Table interface:

  #!/usr/bin/perl
  
  use strict;
  use warnings;
  
  use DBIx::SQLEngine;
  
  my $engine = DBIx::SQLEngine->new(
    'DBI:mysql:test', 'route', 'bier'
  );
  my $table = $engine->table( 'sqle' ); 
  my $columns = [
    {
      name   => 'sqle_id',
      type   => 'sequential',
    },
    {
      name   => 'sqle_name',
      type   => 'text',
      length => 255,
    },
  ];
  $table->drop_table();
  $table->create_table($columns);

  $table->insert_rows({sqle_name=>'One'},
		      {sqle_name=>'Two'},
		      {sqle_name=>'Three'});

  my $dataset = $table->fetch_select();
  my $count = 0;
  for my $data (@$dataset) {
    $count++;
    print "Row $count: ", 
	map( {"\t$_ => " . (defined $$data{$_} ? $$data{$_} : 'NULL') }
	      sort keys %$data), 
	"\n";
  }

=item *

This example shows the same operations using the Record interface:

  #!/usr/bin/perl
  
  use strict;
  use warnings;
  
  use DBIx::SQLEngine;
  
  my $engine = DBIx::SQLEngine->new(
    'DBI:mysql:test', 'route', 'bier'
  );
  $engine->record_class( 'sqle', 'My::Records' ); 
  my $columns = [
    {
      name   => 'sqle_id',
      type   => 'sequential',
    },
    {
      name   => 'sqle_name',
      type   => 'text',
      length => 255,
    },
  ];
  My::Records->drop_table();
  My::Records->create_table($columns);
  
  My::Records->new_and_save( sqle_name=>'One' );
  My::Records->new_and_save( sqle_name=>'Two' );
  My::Records->new_and_save( sqle_name=>'Three' );
  
  my $dataset = My::Records->fetch_select();
  my $count = 0;
  for my $data (@$dataset) {
    $count++;
    print "Row $count: ", 
	map( {"\t$_ => " . (defined $$data{$_} ? $$data{$_} : 'NULL') }
	      sort keys %$data), 
	"\n";
  }

=back


=head1 SEE ALSO 

See L<DBI> and the various DBD modules for information about the underlying database interface.

See L<DBIx::AnyDBD> for details on the dynamic subclass selection mechanism.

The driver interface is described in L<DBIx::SQLEngine::Driver>.

See L<DBIx::SQLEngine::ToDo> for a list of bugs and missing features.

For distribution, installation, support, copyright and license 
information, see L<DBIx::SQLEngine::Docs::ReadMe>.

=cut

########################################################################
