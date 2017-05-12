=head1 NAME

DBIx::SQLEngine::Record::Table - Records accessed via a Schema::Table

=head1 SYNOPSIS

B<Setup:> Several ways to create a class.

  my $sqldb = DBIx::SQLEngine->new( ... );

  $class_name = $sqldb->record_class( $table_name );
  
  $sqldb->record_class( $table_name, $class_name );
  
  package My::Record;
  use DBIx::SQLEngine::Record::Class '-isasubclass';  
  My::Record->table( $sqldb->table($table_name) );

B<Basics:> Common operations on a record.
  
  $record = $class_name->new_with_values(somefield => 'My Value');
  
  print $record->get_values( 'somefield' );

  $record->change_values( somefield => 'New Value' );

B<Fetch:> Retrieve records by ID or other query.

  $record = $class_name->select_record( $primary_key );
  
  @records = $class_name->fetch_select(%clauses)->records;

B<Modify:> Write changes to the data source.

  $record->insert_record();
  
  $record->update_record();
  
  $record->delete_record();

B<Schema:> Access to table and columns.

  unless ( $class_name->table_exists ) {
    $class_name->create_table( { name => 'id', type => 'int'} );
  }


=head1 DESCRIPTION

DBIx::SQLEngine::Record::Table is a mixin class for database records in tables accessible via DBIx::SQLEngine.

Don't use this module directly; instead, pass its name as a trait when you create a new record class. This package provides a multiply-composable collection of functionality for Record classes. It is combined with the base class and other traits by DBIx::SQLEngine::Record::Class. 

=cut

########################################################################

package DBIx::SQLEngine::Record::Table;

use strict;
use Carp;

require DBIx::SQLEngine::Schema::Table;
require DBIx::SQLEngine::RecordSet::Set;

########################################################################

########################################################################

=head1 TABLE INTERFACE

Each record class is associated with a table object. The table provides the
DBI connection and SQL execution capabilities required to talk to the remote
data storage.

=head2 Table Accessor

=over 4

=item table()

  $class_name->table() : $table
  $class_name->table($table)

Get and set our current DBIx::SQLEngine::Schema::Table. Required value.
Establishes the table a specific class of record will be stored in. 

=item get_table()

  $class_name->get_table() : $table or exception

Returns the table, or throws an exception if it is not set.

=back

=cut

use Class::MakeMethods (
  'Template::ClassInherit:object' => [ 
		  table => {class=>'DBIx::SQLEngine::Schema::Table'}
  ],
);

sub get_table {
  ($_[0])->table() or croak("No table set for record class '$_[0]'")
}

########################################################################

=head2 Methods Delegated to Table

These methods all call the same method on the associated table.

=over 4

=item detect_sqlengine()

  $class_name->detect_sqlengine : $flag

Detects whether the SQL database is avaialable by attempting to connect.

=item table_exists()

  $class_name->table_exists : $flag

Detects whether the table has been created and has not been dropped.

=item columnset()

  $class_name->columnset () : $columnset

Returns the current columnset, if any.

=item fetch_one_value()

  $class_name->fetch_one_value( %sql_clauses ) : $scalar

Calls fetch_select, then returns the first value from the first row of results.

=item count_rows()

  $class_name->count_rows ( ) : $number
  $class_name->count_rows ( $criteria ) : $number

Return the number of rows in the table. If called with criteria, returns the number of matching rows. 

=back

=cut

use Class::MakeMethods (
  'Standard::Universal:delegate' => [ [ qw( 
	detect_sqlengine 
	table_exists create_table drop_table 
	fetch_one_value count_rows 
	columnset column_primary_name 
    ) ] => { target=>'get_table' },
  ],
);

########################################################################

=head2 Table Delegation Methods

The following methods are used internally to facilitate delegation to the table object.

=over 4

=item table_fetch_one_method()

  $class->table_fetch_one_method( $method, @args );

Calls the named method on the table and inflates the result with record_from_db_data.

=item table_fetch_set_method()

  $class->table_fetch_set_method( $method, @args );

Calls the named method on the table and inflates the result with record_set_from_db_data.

=item table_record_method()

  $record->table_record_method( $method, @args );

Calls the named method on the table, passing the record itself as the first argument.

=back

=cut

sub table_fetch_one_method {
  my $self = shift;
  my $method = shift;
  $self->record_from_db_data( $self->get_table()->$method( @_ ) )
}

sub table_fetch_set_method {
  my $self = shift;
  my $method = shift;
  $self->record_set_from_db_data( scalar $self->get_table()->$method( @_ ) )
}

sub table_record_method {
  my $self = shift;
  my $method = shift;
  ref($self) or croak("Can't call this object method on a record class");
  $self->get_table()->$method( $self, @_ );
}

########################################################################

=head2 Primary Keys

=over 4

=item primary_criteria()

  $record->primary_criteria() : $hash_ref

Returns a hash of key-value pairs which could be used to select this record by its primary key.

=item primary_key_value()

  $record->primary_key_value() : $id_value

Returns the primary key value for this object.

=back

=cut

sub primary_criteria {
  (shift)->table_record_method('primary_criteria');
}

sub primary_key_value {
  my $self = shift;
  
  $self->{ $self->column_primary_name() }
}

########################################################################

########################################################################

=head1 FETCHING DATA (SQL DQL)

=head2 Select to Retrieve Records

=over 4

=item fetch_select()

  $class_name->fetch_select ( %select_clauses ) : $record_set

Retrives records from the table using the provided SQL select clauses. 

Calls the corresponding SQLEngine method with the table name and the provided arguments. Each row hash is blessed into the record class before being wrapped in a RecordSet::Set object.

=item fetch_one_record()

  $sqldb->fetch_one_record( %select_clauses ) : $record_hash

Retrives one record from the table using the provided SQL select clauses. 

Calls fetch_select, then returns only the first row of results. The row hash is blessed into the record class before being returned.

=item visit_select()

  $class_name->visit_select ( $sub_ref, %select_clauses ) : @results
  $class_name->visit_select ( %select_clauses, $sub_ref ) : @results

Calls the provided subroutine on each matching record as it is retrieved. Returns the accumulated results of each subroutine call (in list context).

Each row hash is blessed into the record class before being the subroutine is called.

=back

=cut

# $records = $record_class->fetch_select( %select_clauses );
sub fetch_select {
  (shift)->table_fetch_set_method('fetch_select', @_)
}

# $record = $record_class->fetch_one_record( %clauses );
sub fetch_one_record {
  (shift)->table_fetch_one_method('fetch_one_row', @_)
}

# @results = $record_class->visit_select( %select_clauses, $sub );
# @results = $record_class->visit_select( $sub, %select_clauses );
sub visit_select {
  my $self = shift;
  my $sub = ( ref($_[0]) ? shift : pop );
  $self->get_table()->visit_select(@_, 
			      sub { $self->record_from_db_data($_[0]); &$sub })
}

########################################################################

=head2 Selecting by Primary Key

=over 4

=item select_record()

  $class_name->select_record ( $primary_key_value ) : $record_obj
  $class_name->select_record ( \@compound_primary_key ) : $record_obj
  $class_name->select_record ( \%hash_with_primary_key_value ) : $record_obj

Fetches a single record by primary key.

The row hash is blessed into the record class before being returned.

=item select_records()

  $class_name->select_records ( @primary_key_values_or_hashrefs ) : $record_set

Fetches a set of one or more records by primary key.

Each row hash is blessed into the record class before being wrapped in a RecordSet::Set object.

=back

=cut

# $criteria = $record_class->criteria_for_primary_key( $id_value );
# $criteria = $record_class->criteria_for_primary_key( \@compound_id );
# $criteria = $record_class->criteria_for_primary_key( \%hash_with_pk );
sub criteria_for_primary_key {
  (shift)->get_table()->primary_criteria(@_)
}

# $record = $record_class->select_record( $id_value );
# $record = $record_class->select_record( \@compound_id );
# $record = $record_class->select_record( \%hash_with_pk );
sub select_record {
  my ( $self, $id ) = @_;
  $self->fetch_one_record( where => $self->criteria_for_primary_key($id) )
}

# $records = $record_class->select_records( @ids_or_hashes );
sub select_records {
  my ( $self, @ids ) = @_;
  $self->fetch_select( where => $self->criteria_for_primary_key(@ids) )
}

########################################################################

########################################################################

=head1 EDITING DATA (SQL DML)

=head2 Insert to Add Records

After constructing a record with one of the new_*() methods, you may save any changes by calling insert_record.

=over 4

=item insert_record()

  $record_obj->insert_record() : $flag

Adds the values from this record to the table. Returns the number of rows affected, which should be 1 unless there's an error.

=back

=cut

# $record_obj->insert_record();
sub insert_record {
  (shift)->table_record_method('insert_row');
}

########################################################################

=head2 Update to Change Records

After retrieving a record with one of the fetch methods, you may save any changes by calling update_record.

=over 4

=item update_record()

  $record_obj->update_record() : $record_count

Attempts to update the record using its primary key as a unique identifier. Returns the number of rows affected, which should be 1 unless there's an error.

=back

=cut

# $record_obj->update_record();
sub update_record {
  (shift)->table_record_method('update_row');
}

########################################################################

=head2 Delete to Remove Records

=over 4

=item delete_record()

  $record_obj->delete_record() : $record_count

Delete this existing record based on its primary key. Returns the number of rows affected, which should be 1 unless there's an error.

=back

=cut

# $record_obj->delete_record();
sub delete_record {
  (shift)->table_record_method('delete_row');
}

########################################################################

########################################################################

=head1 SEE ALSO

For more about the Record classes, see L<DBIx::SQLEngine::Record::Class>.

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
