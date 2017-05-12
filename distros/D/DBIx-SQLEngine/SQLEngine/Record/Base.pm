=head1 NAME

DBIx::SQLEngine::Record::Base - Base Class for Records

=head1 SYNOPSIS

B<Setup:> Several ways to create a class.

  my $sqldb = DBIx::SQLEngine->new( ... );

  $class_name = $sqldb->record_class( $table_name );
  
  $sqldb->record_class( $table_name, $class_name );
  
  package My::Record;
  use DBIx::SQLEngine::Record::Class '-isasubclass', @Traits;  

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


=head1 DESCRIPTION

DBIx::SQLEngine::Record::Base is a superclass for database records in tables accessible via DBIx::SQLEngine.

By subclassing this package, you can easily create a class whose instances represent each of the rows in a SQL database table.

=cut

########################################################################

package DBIx::SQLEngine::Record::Base;

use strict;
use Carp;

########################################################################

########################################################################

=head1 SIMPLE RECORD OBJECT

The following concrete methods provide a constructor, accessor, mutator and destructor for a record object.

=head2 Constructor

You may create your own records for new instances, or fetch records from the database as described in L</"FETCHING DATA">

=over 4

=item new_empty_record()

  $class_name->new_empty_record() : $empty_record

Creates and blesses an empty hash object into the given record class.

=back

=cut

# $record = $record_class->new_empty_record();
# $record = $record->new_empty_record();
sub new_empty_record {
  my $self = shift;
  my $class = ( ref($self) || $self );
  bless {}, $class;
}

########################################################################

=head2 Getting and Changing Values

Records are stored as simple hashes, and their contents can typically
be accessed that way, but methods are also available to get and
set field values.

=over 4

=item get_values()

  $record->get_values( key1 ) : $value
  $record->get_values( key1, key2, ... ) : $values_joined_with_comma
  $record->get_values( key1, key2, ... ) : @values

Returns the values associated with the keys in the provided record.

=item change_values()

  $record->change_values( key1 => value1, ... ) 

Sets the associated key-value pairs in the provided record.

=back

=cut

sub get_values {
  my $self = shift;
  ref($self) or croak("Can't call this object method on a record class");
  my @values = @{$self}{ @_ };
  wantarray ? @values : join(', ', @values)
}

sub change_values {
  my $self = shift;
  ref($self) or croak("Can't call this object method on a record class");
  %$self = ( %$self, @_ )
}

########################################################################

=head2 Vivifying and Serializing Records

These methods are called internally by the various public methods and do not need to be called directly.

=over 4

=item record_from_db_data()

  $class_name->record_from_db_data( $hash_ref )
  $class_name->record_from_db_data( $hash_ref ) : $record
  $class_name->record_from_db_data( %hash_contents ) : $record

Converts a hash retrieved from the table to a Record object.

=item record_set_from_db_data()

  $class_name->record_set_from_db_data( $hash_array_ref )
  $class_name->record_set_from_db_data( $hash_array_ref ) : $record_set
  $class_name->record_set_from_db_data( @hash_refs ) : $record_set

Converts an array of hashrefs retrieved from the table to a RecordSet::Set object containing Record objects.

=item record_as_db_data()

  $record->record_as_db_data() : $hash_ref
  $record->record_as_db_data() : %hash_values

Returns an unblessed copy of the values in the record.

=back

=cut

# $record_class->record_from_db_data( $hash_ref );
# $record = $record_class->record_from_db_data( $hash_ref );
# $record = $record_class->record_from_db_data( %hash_contents );
sub record_from_db_data {
  my $class = shift;
  my $hash = ( @_ == 1 ) ? shift : { @_ }
	or return;
  bless $hash, $class;
}

# $record_class->record_set_from_db_data( $hash_array_ref );
# $record_set = $record_class->record_set_from_db_data( $hash_array_ref );
# $record_set = $record_class->record_set_from_db_data( @hash_refs );
sub record_set_from_db_data {
  my $class = shift;
  my $array = ( @_ == 1 ) ? shift : [ @_ ];
  bless [ map { bless $_, $class } @$array ], 'DBIx::SQLEngine::RecordSet::Set';
}

# $hash_ref = $record_obj->record_as_db_data();
# %hash_list = $record_obj->record_as_db_data();
sub record_as_db_data {
  my $self = shift;
  ref($self) or croak("Can't call this object method on a record class");
  wantarray ? %$self : { %$self }
}

########################################################################

=head2 Destructor

=over 4

=item DESTROY()

  $record->DESTROY()

For internal use only. Does nothing. Subclasses can override this with any functions they wish called when an individual record is being garbage collected.

=back

=cut

sub DESTROY {
  # Do nothing
}

########################################################################

########################################################################

=head1 CONVENIENCE METHODS

The following wrapper methods chain together combinations of other methods.

=head2 Constructor Methods

=item new_with_values()

  $class_name->new_with_values ( %key_argument_pairs ) : $record

Calls new_empty_record, and then change_values.

=item new_copy()

  $record->new_copy() : $new_record
  $record->new_copy( %key_argument_pairs ) : $new_record

Makes a copy of a record and then clears its primary key so that it will be recognized as a distinct, new row in the database rather than overwriting the original when you save it. Also includes any provided arguments in its call to new_with_values.

=item get_record()

  $class_name->get_record ( ) : $new_empty_record
  $class_name->get_record ( $p_key ) : $fetched_record_or_undef

Calls new if no primary key is provided, or if the primary key is zero; otherwise calls select_record.

=back

=cut

# $record = $record_class->new_with_values( 'fieldname' => 'new_value', ... )
sub new_with_values {
  my $self = (shift)->new_empty_record();
  $self->change_values( @_ );
  $self;
}

# $record = $record->new_copy();
sub new_copy { 
  my $self = shift;
  ref($self) or croak("Can't call this object method on a record class");
  $self->new_with_values( 
    $self->record_as_db_data, $self->column_primary_name() => '', @_ 
  )
}

# $new_record = $package->get_record()
# $selected_record = $package->get_record( $id )
sub get_record {
  my $package = shift;
  my $id = shift;
  if ( ! $id ) {
    $package->new_empty_record();
  } else {
    $package->select_record( $id );
  }
}

########################################################################

=head2 Save Methods

These methods hide the distinction between insert and update.

=over 4

=item save_record()

  $record->save_record () : $record_or_undef

Determines whether the record has an primary key assigned to it and then calls either insert_record or update_record. Returns the record unless it fails to save it.

=item new_and_save()

  $class_name->new_and_save ( %key_argument_pairs ) : $record

Calls new_empty_record, and then change_and_save.

=item change_and_save()

  $record->change_and_save ( %key_argument_pairs ) : $record

Calls change_values, and then save_record.

=back

=cut

# $record->save_record()
sub save_record {
  my $self = shift;
  ref($self) or croak("Can't call this object method on a record class");
  
  if ( ! $self->primary_key_value() ) {
    $self->insert_record( @_ );
  } else {
    $self->update_record( @_ );
  }
  $self;
}

# $record_class->new_and_save( 'fieldname' => 'new_value', ... )
sub new_and_save {
  (shift)->new_with_values( @_ )->save_record();
}

# $record->change_and_save( 'fieldname' => 'new_value', ... )
sub change_and_save {
  my $self = shift;
  $self->change_values( @_ );
  $self->save_record;
}

########################################################################

########################################################################

=head1 FETCHING DATA

The following abstract methods are to be implemented by subclasses; in particular, see L<DBIx::SQLEngine::Record::Table>. 

=head2 Select to Retrieve Records

=over 4

=item fetch_one_record()

  $sqldb->fetch_one_record( %select_clauses ) : $record_hash

Retrives one record from the table using the provided SQL select clauses. 

=item fetch_select()

  $class_name->fetch_select ( %select_clauses ) : $record_set

Retrives records from the table using the provided SQL select clauses. 

=item visit_select()

  $class_name->visit_select ( $sub_ref, %select_clauses ) : @results
  $class_name->visit_select ( %select_clauses, $sub_ref ) : @results

Calls the provided subroutine on each matching record as it is retrieved. Returns the accumulated results of each subroutine call (in list context).

=back

=cut

use Class::MakeMethods::Standard::Universal 
	'abstract' => "fetch_one_record fetch_select visit_select";

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

use Class::MakeMethods::Standard::Universal 
	'abstract' => "select_record select_records";

########################################################################

########################################################################

=head1 ALTERING DATA

The following abstract methods are to be implemented by subclasses; in particular, see L<DBIx::SQLEngine::Record::Table>. 

=head2 Insert to Add Records

After constructing a record with one of the new_*() methods, you may save any changes by calling insert_record.

=over 4

=item insert_record()

  $record_obj->insert_record() : $flag

Adds the values from this record to the table. Returns the number of rows affected, which should be 1 unless there's an error.

=back

=head2 Update to Change Records

After retrieving a record with one of the fetch methods, you may save any changes by calling update_record.

=over 4

=item update_record()

  $record_obj->update_record() : $record_count

Attempts to update the record using its primary key as a unique identifier. Returns the number of rows affected, which should be 1 unless there's an error.

=back

=head2 Delete to Remove Records

=over 4

=item delete_record()

  $record_obj->delete_record() : $record_count

Delete this existing record based on its primary key. Returns the number of rows affected, which should be 1 unless there's an error.

=back

=cut

use Class::MakeMethods::Standard::Universal 
	'abstract' => "insert_record update_record delete_record";

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
