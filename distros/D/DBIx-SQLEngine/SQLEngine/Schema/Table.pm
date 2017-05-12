=head1 NAME

DBIx::SQLEngine::Schema::Table - A table in a data source

=head1 SYNOPSIS

  $sqldb = DBIx::SQLEngine->new( ... );
  
  $table = $sqldb->table( $table_name );
  
  $hash_ary = $table->fetch_select( where => { status => 2 } );

  $table->do_insert( values => { somefield => 'A Value', status => 3 } );
  $table->do_update( values => { status => 3 }, where => { status => 2 } );
  $table->do_delete( where => { somefield => 'A Value' } );

  $hash = $table->fetch_row( $primary_key );

  $table->insert_row( { somefield => 'Some Value' } );
  $table->update_row( { id => $primary_key, somefield => 'Some Value' } );
  $table->delete_row( { id => $primary_key } );


=head1 DESCRIPTION

The DBIx::SQLEngine::Schema::Table class represents database tables accessible via a particular DBIx::SQLEngine.

By storing a reference to a SQLEngine and the name of a table to operate on, a Schema::Table object can facilitate generation of SQL queries that operate on the named table.

Each table can retrieve and cache a ColumnSet containing information about the name and type of the columns in the table. Column information is loaded from the storage as needed, but if you are creating a new table you must provide the definition.

The *_row() methods use this information about the table columns to facilitate common operations on table rows using their primary keys and simple hash-refs.

=cut

########################################################################

package DBIx::SQLEngine::Schema::Table;
use strict;

use Carp;
use Class::MakeMethods;

use DBIx::SQLEngine; 
use DBIx::SQLEngine::Schema::Column;
use DBIx::SQLEngine::Schema::ColumnSet;

########################################################################

=head1 INSTANTIATION AND ACCESSORS

=head2 Table Object Creation

=over 4

=item SQLEngine->table()

  $sqldb->table( $tablename ) : $table

Convenience function to create a table with the given table name and sqlengine.

=item new()

  DBIx::SQLEngine::Schema::Table->new( sqlengine=>$sqldb, name=>$name ) : $table

Standard hash constructor. You are expected to provde the name and sqlengine arguments.

=back

=cut

use Class::MakeMethods (
  'Standard::Hash:new' => 'new',
);

########################################################################

=head2 Name Accessor

=over 4

=item name()

  $table->name() : $string
  $table->name($string)

Get and set the table name. Required value. Identifies this table in the data
source.

=item get_name()

  $table->get_name() : $string or exception

Returns the table name, or throws an exception if it is not set.

=back

=cut

use Class::MakeMethods (
  'Standard::Hash:scalar' => 'name',
);

sub get_name {
  ($_[0])->name() or croak("No name set for table in '$_[0]->{sqlengine}'")
}

########################################################################

=head2 SQLEngine Accessor

=over 4

=item sqlengine()

  $table->sqlengine() : $sqldb
  $table->sqlengine($sqldb)

Get and set our current DBIx::SQLEngine. Required value. The SQLEngine
provides the DBI connection and SQL execution capabilities required to talk
to the remote data storage.

=item get_sqlengine()

  $table->get_sqlengine() : $sqldb or exception

Returns the SQLEngine, or throws an exception if it is not set.

=back

=cut

use Class::MakeMethods (
  'Standard::Hash:object' => { name=>'sqlengine',
				 class=>'DBIx::SQLEngine::Driver::Default' },
);

sub get_sqlengine {
  ($_[0])->sqlengine() or croak("No sqlengine set for table '$_[0]->{name}'")
}

########################################################################

=head2 SQLEngine Method Invocation

=over 4

=item sqlengine_do()

  $table->sqlengine_do( $method, %sql_clauses ) : $results or exception

Calls the provided method name on the associated SQLEngine, passing along the table name and the other provided arguments. Intended for methods with hash-based argument parsing like C<fetch_select( table =E<gt> $table_name )>.

=item sqlengine_table_method()

  $table->sqlengine_table_method( $method, @args ) : $results or exception

Calls the provided method name on the associated SQLEngine, passing along the table name and the other provided arguments. Intended for methods with list-based argument parsing like C<detect_table( $table_name )>.

=back

=cut

sub sqlengine_do {
  my ($self, $method, %args) = @_;
  my $name = $self->name() 
	or croak("No name set for table in '$self->{sqlengine}'");
  my $sqlengine = $self->sqlengine() 
	or croak("No sqlengine set for table '$_[0]->{name}'");
  $args{table} = $name unless( $args{sql} || $args{named_query} );
  $sqlengine->$method( %args)
}

sub sqlengine_table_method {
  my ($self, $method, @args) = @_;
  my $name = $self->name() 
	or croak("No name set for table in '$self->{sqlengine}'");
  my $sqlengine = $self->sqlengine() 
	or croak("No sqlengine set for table '$_[0]->{name}'");
  $sqlengine->$method($name, @args)
}

########################################################################

=head2 Detect Availability

=over 4

=item detect_sqlengine()

  $table->detect_sqlengine : $flag

Detects whether the SQL database is avaialable by attempting to connect.

=item detect_table()

  $table->detect_table : @columns

Checks to see if the table exists in the SQL database by attempting to retrieve its columns.

=back

=cut

# $flag = $table->detect_sqlengine;
sub detect_sqlengine {
  (shift)->get_sqlengine()->detect_any;
}

# @columns = $table->detect_table;
sub detect_table {
  (shift)->sqlengine_table_method('detect_table');
}

########################################################################

=head2 Row Class

=over 4

=item record_class()

  $table->record_class() : $record_class

Returns the Record::Class which corresponds to the table.

=back

=cut

sub record_class {
  my ($table, $classname, @traits) = @_;
  require DBIx::SQLEngine::Record::Class;
  DBIx::SQLEngine::Record::Class->subclass_for_table( @_ )
}

########################################################################

########################################################################

=head1 FETCHING DATA (SQL DQL)

=head2 Select to Retrieve Rows

=over 4

=item fetch_select()

  $table->fetch_select ( %select_clauses ) : $row_hash_array

Calls the corresponding SQLEngine method with the table name and the provided arguments. Return rows from the table that match the provided criteria, and in the requested order, by executing a SQL select statement.

=item visit_select()

  $table->visit_select ( $sub_ref, %select_clauses ) : @results
  $table->visit_select ( %select_clauses, $sub_ref ) : @results

Calls the provided subroutine on each matching row as it is retrieved. Returns the accumulated results of each subroutine call (in list context).

=item select_row()

  $table->select_row ( $primary_key_value ) : $row_hash
  $table->select_row ( \@compound_primary_key ) : $row_hash
  $table->select_row ( \%hash_with_primary_key_value ) : $row_hash

Fetches a single row by primary key.

=item select_rows()

  $table->select_rows ( @primary_key_values_or_hashrefs ) : $row_hash_array

Fetches a set of one or more by primary key.

=back

=cut

# $rows = $self->fetch_select( %select_clauses );
sub fetch_select {
  (shift)->sqlengine_do('fetch_select', @_)
}

# $rows = $self->fetch_one_row( %select_clauses );
sub fetch_one_row {
  (shift)->sqlengine_do('fetch_one_row', @_)
}

# @results= $self->visit_select( %select_clauses, $sub );
sub visit_select {
  my $self = shift;
  my $sub = ( ref($_[0]) ? shift : pop );
  $self->sqlengine_do('visit_select', @_, $sub )
}

# $row = $self->select_row( $id_value );
# $row = $self->select_row( \@compound_id );
# $row = $self->select_row( \%hash_with_pk );
  # Retrieve a specific row by id
sub select_row {
  my $self = shift;
  $self->sqlengine_do('fetch_one_row', where=>$self->primary_criteria(@_) )
}

# $rows = $self->select_rows( @ids_or_hashes );
sub select_rows {
  my $self = shift;
  $self->sqlengine_do('fetch_select', where=>$self->primary_criteria(@_) )
}

########################################################################

=head2 Selecting Agregate Values

=over 4

=item fetch_one_value()

  $table->fetch_one_value( %sql_clauses ) : $scalar

Calls fetch_select, then returns the first value from the first row of results.

=item count_rows()

  $table->count_rows ( ) : $number
  $table->count_rows ( $criteria ) : $number

Return the number of rows in the table. If called with criteria, returns the number of matching rows. 

=item try_count_rows()

  $table->try_count_rows ( ) : $number
  $table->try_count_rows ( $criteria ) : $number

Exception catching wrapper around count_rows. If the eval block catches an exception, undef is returned.

=item fetch_max()

  $table->count_rows ( $colname, CRITERIA ) : $number

Returns the largest value in the named column. 

=back

=cut

# $value = $self->fetch_one_value( %select_clauses );
sub fetch_one_value {
  (shift)->sqlengine_do('fetch_one_value', @_ )
}

# $rowcount = $self->count_rows
# $rowcount = $self->count_rows( $criteria );
sub count_rows {
  (shift)->fetch_one_value( columns => 'count(*)', where => (shift) )
}

sub try_count_rows {
  my $count = eval { (shift)->count_rows( @_ )  };
  wantarray ? ( $count, $@ ) : $count
}

# $max_value = $self->fetch_max( $colname, $criteria );
sub fetch_max {
  (shift)->fetch_one_value( columns => "max(".(shift).")", where => (shift) )
}

########################################################################

########################################################################

=head1 EDITING DATA (SQL DML)

=head2 Insert to Add Rows

=over 4

=item do_insert()

  $table->do_insert ( %insert_clauses ) : $row_count

Calls the corresponding SQLEngine method with the table name and the provided arguments. 

=item insert_row()

  $table->insert_row ( $row_hash ) : $row_count

Adds the provided row by executing a SQL insert statement. Uses column_names() and column_primary_is_sequence() to produce the proper clauses. Returns the total number of rows affected, which is typically 1.

=item insert_rows()

  $table->insert_rows ( @row_hashes ) : $row_count

Insert each of the rows from the provided list into the table. Returns the total number of rows affected, which is typically the same as the number of arguments passed.

=back

=cut

sub do_insert {
  (shift)->sqlengine_do('do_insert', @_)
}

# $self->insert_row( \%row );
sub insert_row {
  my ($self, $row) = @_;
  
  my $primary = $self->column_primary_name;
  my @colnames = grep { $_ eq $primary or defined $row->{$_} } 
							$self->column_names;
  
  $self->sqlengine_do('do_insert',
    ( $self->column_primary_is_sequence ? ( sequence => $primary ) : () ),
    columns => \@colnames,
    values => $row,
  );
}

# $self->insert_rows( @hashes );
sub insert_rows {
  my $self = shift;
  my $rc;
  foreach my $row ( @_ ) { $rc += $self->insert_row( $row ) }
  $rc
}

########################################################################

=head2 Update to Change Rows

=over 4

=item do_update()

  $table->do_update ( %update_clauses ) : $row_count

Calls the corresponding SQLEngine method with the table name and the provided arguments. 

=item update_row()

  $table->update_row ( $row_hash ) : $row_count

Update this existing row based on its primary key. Uses column_names() and column_primary_is_sequence() to produce the proper clauses. Returns the total number of rows affected, which is typically 1.

=item update_rows()

  $table->update_rows ( @row_hashes ) : $row_count

Update several existing rows based on their primary keys. Uses update_row(). Returns the total number of rows affected, which is typically the same as the number of arguments passed.

=back

=cut

# $self->do_update( %clauses);
sub do_update {
  (shift)->sqlengine_do('do_update', @_ )
}

# $self->update_row( $row );
sub update_row {
  my($self, $row) = @_;
  
  $self->sqlengine_do('do_update', 
    columns => [ $self->column_names ],
    where => $self->primary_criteria( $row ),
    values => $row,
  );
}

# $self->update_rows( @hashes );
sub update_rows {
  my $self = shift;
  my $rc;
  foreach my $row ( @_ ) { $rc += $self->update_row( $row ) }
  $rc
}

########################################################################

=head2 Delete to Remove Rows

=over 4

=item do_delete()

  $table->do_delete ( %delete_clauses ) : $row_count

Calls the corresponding SQLEngine method with the table name and the provided arguments. 

=item delete_row()

  $table->delete_row ( $row_hash_or_id ) : ()

Deletes the provided row from the table. Returns the total number of rows affected, which is typically 1.

=item delete_rows()

  $table->delete_rows ( @row_hashes_or_ids ) : ()

Deletes all of the provided rows from the table. Returns the total number of rows affected, which is typically the same as the number of arguments passed.

=back

=cut

# $self->do_delete( %clauses);
sub do_delete {
  (shift)->sqlengine_do('do_delete', @_ )
}

# $self->delete_row( $row );
sub delete_row { 
  my $self = shift;
  $self->sqlengine_do( 'do_delete', where => $self->primary_criteria(@_ ) )
}

# $self->delete_rows( @hashes );
sub delete_rows {
  my $self = shift;
  $self->sqlengine_do( 'do_delete', where => $self->primary_criteria(@_) )
}

########################################################################

########################################################################

=head1 DEFINING STRUCTURES (SQL DDL)

=head2 ColumnSet

=over 4

=item columnset()

  $table->columnset () : $columnset

Returns the current columnset, if any.

=item get_columnset()

  $table->get_columnset () : $columnset

Returns the current columnset, or runs a trivial query to detect the columns in the sqlengine. If the table doesn't exist, the columnset will be empty.

=item columns()

  $table->columns () : @columns

Return the column objects from the current columnset.

=item column_names()

  $table->column_names () : @column_names

Return the names of the columns, in order.

=item column_named()

  $table->column_named ( $name ) : $column

Return the column info object for the specifically named column.

=back

=cut

use Class::MakeMethods (
  'Standard::Hash:object' => { name=>'columnset', 
				class=>'DBIx::SQLEngine::Schema::ColumnSet' },
  'Standard::Universal:delegate' => [
    [ qw( columns column_names column_named column_primary ) ] => 
				{ target=>'get_columnset' },
  ],
);

sub get_columnset {
  my $self = shift;
  
  $self->columnset or $self->columnset( do {
      my @columns = $self->detect_table() or
	  confess("Couldn't fetch column information for table $self->{name}");
      DBIx::SQLEngine::Schema::ColumnSet->new( @columns )
    }
  );
}

########################################################################

=head2 Primary Keys

=over 4

=item column_primary_is_sequence()

Inheritable boolean which can be set for the table class or any instance.
Indicates that the primary key column uses an auto-incrementing sequence.

=item column_primary_name()

Returns the name of the primary key column. (TODO: Currently hard-coded to the first column in the column set.)

=item primary_criteria()

Returns a hash of key-value pairs which could be used to select this record by its primary key.

=back

=cut

# To-do: finish adding support for tables with multiple-column primary keys.
use Class::MakeMethods (
  # 'Standard::Inheritable:scalar' => { name=>'column_primary_name',  },
  'Standard::Inheritable:scalar' => { name=>'column_primary_is_sequence',  },
);

sub column_primary_name {
  my $columns = (shift)->get_columnset or return;
  my $column = $columns->[0] or return;
  $column->name;
}

# (__PACKAGE__)->column_primary_name( 'id' );
# (__PACKAGE__)->column_primary_is_sequence( 1 );

sub primary_criteria {
  my $self = shift;
  my $primary_col = $self->column_primary_name;
  my @ids = map { UNIVERSAL::isa($_, 'HASH') ? $_->{$primary_col} : $_ } @_;
  return { $primary_col => ( scalar(@ids) > 1 ) ? \@ids : $ids[0] }
}

########################################################################

=head2 Create and Drop Tables

=over 4

=item table_exists()

  $table->table_exists() : $flag

Detects whether the table has been created and has not been dropped.

=item create_table()

  $table->create_table () 
  $table->create_table ( $column_ary ) 

=item drop_table()

  $table->drop_table () 

=item ensure_table_exists()

  $table->ensure_table_exists ( $column_ary )

Create the table's remote storage if it does not already exist.

=item recreate_table()

  $table->recreate_table ()
  $table->recreate_table ( $column_ary )

Drop and then recreate the table's remote storage.

=item recreate_table_with_rows

  $table->recreate_table_with_rows ()
  $table->recreate_table_with_rows ( $column_ary )

Selects all of the existing rows, then drops and recreates the table, then re-inserts all of the rows.

=back

=cut

# $flag = $table->table_exists;
sub table_exists { &detect_table ? 1 : 0 }

# $self->create_table();
sub create_table {
  my $self = shift;
  my $columnset = shift || $self->columnset ||
	  confess("No column information for table $self->{name}");
  $self->sqlengine_table_method('create_table', $columnset ) ;
}

# $sql_stmt = $table->drop_table();
sub drop_table {
  (shift)->sqlengine_table_method('drop_table') ;
}

# $table->ensure_table_exists( $column_ary )
  # Create the remote data source for a table if it does not already exist
sub ensure_table_exists {
  my $self = shift;
  $self->create_table(@_) unless $self->table_exists;
}

# $table->recreate_table
# $table->recreate_table( $column_ary )
  # Delete the source, then create it again
sub recreate_table { 
  my $self = shift;
  my $column_ary = shift;
  if ( $self->table_exists ) {
    $column_ary ||= $self->get_columnset;
    $self->drop_table;
  }
  $self->create_table( $column_ary );
}

# $package->recreate_table_with_rows;
# $package->recreate_table_with_rows( $column_ary );
sub recreate_table_with_rows {
  my $self = shift;
  my $rows = $self->fetch_select();
  $self->recreate_table( @_ );
  $self->insert_rows( $rows );
}

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
