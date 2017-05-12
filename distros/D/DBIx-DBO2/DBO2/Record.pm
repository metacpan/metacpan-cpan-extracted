=head1 NAME

DBIx::DBO2::Record - A row in a table in a datasource

=head1 SYNOPSIS

  package MyRecord;
  use DBIx::DBO2::Record '-isasubclass';
  use DBIx::DBO2::Fields (
    'sequential' => 'id',
    'string -length 64' => 'name',
    'timestamp --modified' => 'lastupdate',
  );
  
  my $sqldb = DBIx::SQLEngine->new( ... );
  MyRecord->table( $sqldb->table( 'foo' );
  unless ( MyRecord->table->table_exists ) {
    MyRecord->table->create_table( MyRecord->field_columns );
  }

  my $record = MyRecord->new( name => 'Dave' );
  $record->save_record;
  
  my $results = MyRecord->fetch_records( criteria => { name => 'Dave' } );
  foreach my $rec ( $results->records ) {
    print $rec->name() . ' ' . $rec->lastupdate_readable();
  }

=head1 DESCRIPTION

The DBIx::DBO2::Record class represents database records in tables accessible via DBIx::SQLEngine.

By subclassing this package, you can easily create a class whose instances represent each of the rows in a SQL database table.

=cut

package DBIx::DBO2::Record;

use strict;
use Carp;

########################################################################

=head1 REFERENCE

=cut

use Class::MakeMethods;

use DBIx::SQLEngine;
use DBIx::SQLEngine::Schema::Table;
use DBIx::SQLEngine::Criteria;

use DBIx::DBO2::RecordSet;

########################################################################

=head2 Subclass Factory

=over 4

=item import

  package My::Record;
  use DBIx::DBO2::Record '-isasubclass';

Allows for a simple declaration of inheritance.

=back

=cut

sub import {
  my $class = shift;
  
  if ( scalar @_ == 1 and $_[0] eq '-isasubclass' ) {
    shift;
    my $target_class = ( caller )[0];
    no strict;
    push @{"$target_class\::ISA"}, $class;
  }
  
  $class->SUPER::import( @_ );
}

########################################################################

# =item type - Template::ClassName:subclass_name
#
# Access subclasses by name.

# Class::MakeMethods->make(
#   'Template::ClassName:subclass_name' => 'type',
# );

########################################################################

=head2 Table and SQLEngine

Each Record class stores a reference to the table its instances are stored in.

=over 4

=item table

  RecordClass->table ( $table )
  RecordClass->table () : $table

Establishes the table a specific class of record will be stored in.

=item count_rows

  RecordClass->count_rows () : $integer

Delegated to table.

=item datasource

  RecordClass->datasource () : $datasource

Delegated to table. Returns the table's SQLEngine.

=item do_sql

  RecordClass->do_sql ( $sql_statement ) 

Delegated to datasource.

=back

=cut

Class::MakeMethods->make(
  'Template::ClassInherit:object' => [ table => {class=>'DBIx::SQLEngine::Schema::Table'} ],
  'Standard::Universal:delegate' => [ 
    [ qw( count_rows datasource do_sql column_primary_name ) ] => { target=>'table' },
  ],
);

sub demand_table {
  my $self = shift;
  $self->table() or croak("No table set for " . ( ref( $self ) || $self ));
}

########################################################################

=head2 Hooks

Many of the methods below are labeled "Inheritable Hook." These methods allow you to register callbacks which are then invoked at specific points in each record's lifecycle. You can add these callbacks to all record classes, to a particular class, or even to a particular object instance.

To register a callback, call the install_hooks method, and pass it pairs of a hook method name, and a subroutine reference, as follows: I<callee>->install_hooks( I<methodname> => I<coderef>, ... ).

Here are a few examples to show the possibilities this provides you with:

=over 4

=item *

To have each record write to a log when it's loaded from the database:

  sub log_fetch { my $record = shift; warn "Loaded record $record->{id}" } );
  MyClass->install_hooks( post_fetch => \&log_fetch );

=item *

To make a class "read-only" by preventing all inserts, updates, and deletes:

  my $refusal = sub { return 0 };
  MyClass->install_hooks( 
    ok_insert => $refusal, 
    ok_update => $refusal, 
    ok_delete => $refusal, 
  );

=item *

To have a particular record automatically save any changes you've made to it when it goes out of scope:

  my $record = MyClass->fetch_one( ... );
  my $saver = sub { my $record = shift; $record->save_record };
  $record->install_hooks( pre_destroy => $saver );

=back

=cut

sub install_hooks {
  my $callee = shift;
  while ( my( $method_name, $code_ref ) = splice( @_, 0, 2 ) ) {
    $callee->$method_name( 
      Class::MakeMethods::Composite::Inheritable->Hook( $code_ref )
    );
  }
}

########################################################################

=head2 Constructor

Record objects are constructed when they are fetched from their table as described in the next section, or you may create your own for new instances.

=over 4

=item new 

  my $obj = MyRecord->new( method1 => value1, ... ); 

  my $shallow_copy = $record->new;

Create a new instance.
(Class::MakeMethods::Standard::Hash:new).

=item clone

  my $similar_record = $record->clone;

Makes a copy of a record and then clears its id so that it will be recognized as a distinct, new row in the database rather than overwriting the original when you save it.

=item post_new

Inheritable Hook. Subclasses should override this with any functions they wish performed immediately after each record is created and initialized.

=back

=cut

use Class::MakeMethods::Composite::Hash (
  'new' => [ 'new' => { post_rules => [ sub { map $_->post_new, Class::MakeMethods::Composite->CurrentResults } ] } ],
);

use Class::MakeMethods::Composite::Inheritable(hook=>'post_new' ); 

sub clone { 
  my $callee = shift;
  $callee->new( $callee->column_primary_name() => '', @_ );
}

########################################################################

=head2 Selecting Records

=over 4

=item fetch_records

  $recordset = My::Students->fetch_records( criteria => {status=>'active'} );

Fetch all matching records and return them in a RecordSet.

=item fetch_one

  $dave = My::Students->fetch_one( criteria => { name => 'Dave' } );

Fetch a single matching record.

=item fetch_id

  $prisoner = My::Students->fetch_id( 6 );

Fetch a single record based on its primary key.

=item visit_records

  @results = My::Students->visit_records( \&mysub, criteria=> ... );

Calls the provided subroutine on each matching record as it is retrieved. Returns the accumulated results of each subroutine call (in list context).

=item refetch_record

  $record->refetch_record();

Re-retrieve the values for this record from the database based on its primary key. 

=item post_fetch

Inheritable Hook. Subclasses should override this with any functions they wish performed immediately after each record is retrieved from the database.

=back

=cut

use Class::MakeMethods::Composite::Inheritable( hook=>'post_fetch' ); 

sub fetch_records {
  my $record_or_class = shift;
  my $class = ref( $record_or_class ) || $record_or_class;
  my $table = $record_or_class->table() or croak("No table set for $class");  
  my $records = $table->fetch_select( @_ );
  bless [ map { bless $_, $class; $_->post_fetch; $_ } @$records ], 'DBIx::DBO2::RecordSet';
}

sub visit_records {
  my $record_or_class = shift;
  my $class = ref( $record_or_class ) || $record_or_class;
  my $table = $record_or_class->table() or croak("No table set for $class");  
  my $sub = shift;
  my $func = sub { 
    my $record = shift; 
    bless $record, $class; 
    $record->post_fetch; 
    &$sub( $record ) 
  };
  $table->visit_select( $func, @_ );
}

sub fetch_one {
  my $record_or_class = shift;
  my $class = ref( $record_or_class ) || $record_or_class;
  my $table = $record_or_class->table() or croak("No table set for $class");  
  
  my $records = $table->fetch_select( @_ );
  ( scalar @$records < 2 ) or
    carp "Multiple matches for fetch_one: " . join(', ', map "'$_'", @_ );
  
  my $record = $records->[0] or return;
  bless $record, $class;
  $record->post_fetch;
  $record;
}

sub fetch_id {
  my $record_or_class = shift;
  my $class = ref( $record_or_class ) || $record_or_class;
  my $table = $record_or_class->table() or croak("No table set for $class");  
  my $record = $table->fetch_id( @_ ) or return;
  bless $record, $class;
  $record->post_fetch;
  $record;
}

sub refetch_record {
  my $self = shift();
  my $class = ref( $self ) || $self;
  my $table = $self->table() or croak("No table set for $class");  
  my $id = $self->{ $table->column_primary_name() };
  my $db_row = $table->fetch_id( $id )
    or confess;
  %$self = %$db_row;
  $self->post_fetch;
  $self;
}

########################################################################

=head2 Row Inserts

After constructing a record with new(), you may save any changes by calling insert_record.

=over 4

=item insert_record

Attempt to insert the record into the database.

  $record->insert_record () : $record_or_undef

Calls ok_insert to ensure that it's OK to insert this row, and aborts if any of hook subroutines return 0. 

Calls any pre_insert hooks, then calls its table's insert_row method, then calls any post_insert hooks.

Returns undef if the update was aborted, or the record if the insert was successful.

=item ok_insert

Inheritable Hook. Subclasses should override this with any functions they wish performed to validate rows before they are inserted.

=item pre_insert

Inheritable Hook. Subclasses should override this with any functions they wish performed immediately before a row is inserted.

=item post_insert

Inheritable Hook. Subclasses should override this with any functions they wish performed after a row is inserted.

=back

=cut

use Class::MakeMethods::Composite::Inheritable(hook=>'ok_insert pre_insert post_insert'); 

# $record->insert_record()
sub insert_record {
  my $self = shift;
  my $class = ref( $self ) or croak("Not a class method");
  my $table = $class->demand_table();
  my @flags = $self->ok_insert();
  if ( grep { length $_ and ! $_ } @flags ) {
    # warn "Cancelling insert of $self, flags are " . join(', ', map "'$_'", @flags);
    return undef;
  } 
  $self->pre_insert();
  $table->insert_row( $self );
  $self->post_insert();
  $self;
}

########################################################################

=head2 Row Updates

After retrieving a record with one of the fetch methods, you may save any changes by calling update_record.

=over 4

=item update_record

Attempts to update the record using its primary key as a unique identifier.

  $record->update_record () : $record_or_undef

Calls ok_update to ensure that it's OK to update this row, and aborts if any of hook subroutines return 0. 

Calls any pre_update hooks, then calls its table's update_row method, then calls any post_update hooks.

Returns undef if the update was aborted, or the record if the update was successful.

=item ok_update

Inheritable Hook. Subclasses should override this with any functions they wish to use to validate rows before they are updated. Return 0 to abort the update.

=item pre_update

Inheritable Hook. Subclasses should override this with any functions they wish performed immediately before a row is updated.

=item post_update

Inheritable Hook. Subclasses should override this with any functions they wish performed immediately after a row is updated.

=back

=cut

use Class::MakeMethods::Composite::Inheritable(hook=>'ok_update pre_update post_update'); 

# $record->update_record()
sub update_record {
  my $self = shift;
  my $class = ref( $self ) or croak("Not a class method");
  my $table = $class->demand_table();
  my @flags = $self->ok_update;
  if ( grep { length $_ and ! $_ } @flags ) {
    # warn "Cancelling update of $self, flags are " . join(', ', map "'$_'", @flags );
    return undef;
  } 
  # warn "About to update $self, flags are " . join(', ', map "'$_'", @flags );
  $self->pre_update();
  $table->update_row( $self );
  $self->post_update();
  $self;
}

########################################################################

=head2 Deletion

=over 4

=item delete_record 

  $record->delete_record () : $boolean_completed

Checks to see if any of the pre_delete results is "0". If not, asks the table to delete the row.

Returns 1 if the deletion was successful, or 0 if it was aborted.

=item ok_delete

  $record->ok_delete () : @booleans

Inheritable Hook. Subclasses should override this with any functions they wish to use to validate rows before they are updated. Return 0 to abort the deletion.

=item pre_delete

  $record->pre_delete ()

Inheritable Hook. Subclasses should override this with any functions they wish performed before a row is deleted.

=item post_delete

  $record->post_delete ()

Inheritable Hook. Subclasses should override this with any functions they wish performed after a row is deleted.

=back

=cut

use Class::MakeMethods::Composite::Inheritable(hook=>'ok_delete pre_delete post_delete'); 

# $success = $record->delete_record();
sub delete_record {
  my $self = shift;
  my @flags = $self->ok_delete;
  if ( grep { length $_ and ! $_ } @flags ) {
    # warn "Cancelling delete of $self, flags are " . join(', ', map "'$_'", @flags );
    return 0;
  } 
  # warn "About to delete $self, flags are " . join(', ', map "'$_'", @flags );
  $self->pre_delete();
  $self->table->delete_row($self);
  $self->post_delete();
  return 1;
}

########################################################################

=head2 Load and Save Wrappers

Wrappers for new/fetch and insert/update.

=over 4

=item get_record 

  RecordClass->get_record ( $id_or_undef ) : $new_or_fetched_record_or_undef

Calls new if no ID is provided, or if the ID is the special string "-new"; otherwise calls fetch_id.

=item save_record

  $record->save_record () : $record_or_undef

Determines whether the record has an id assigned to it and then calls either insert_record or update_record. Returns the record unless it fails to save the record.

=back

=cut

# $record = $package->get_record()
# $record = $package->get_record( $id )
sub get_record {
  my $package = shift;
  my $id = shift;
  if ( ! $id or $id eq "new" or $id eq "-new" ) {
    $package->new();
  } else {
    $package->fetch_id( $id );
  }
}

# $record->save_record()
sub save_record {
  my $self = shift;
  if ( $self->{id} and $self->{id} eq 'new' ) {
    undef $self->{id};
  }
  if ( $self->{ $self->column_primary_name() } ) {
    $self->update_record( @_ );
  } else {
    $self->insert_record( @_ );
  }
  $self;
}

########################################################################

=head2 Modification Wrappers

Simple interface for applying changes.

=over 4

=item call_methods 

  $record->call_methods( method1 => value1, ... ); 

Call provided method names with supplied values.
(Class::MakeMethods::Standard::Universal:call_methods).

=item change_and_save 

  RecordClass->new_and_save ( %method_argument_pairs ) : $record

Calls call_methods, and then save_record.

=item change_and_save 

  $record->change_and_save ( %method_argument_pairs ) : $record

Calls call_methods, and then save_record.

=back

=cut

use Class::MakeMethods::Standard::Universal ( 'call_methods'=>'call_methods' );

# $record->new_and_save( 'fieldname' => 'new_value', ... )
sub new_and_save {
  my $callee = shift;
  my $record = $callee->new( @_ );
  $record->save_record;
  $record;
}

# $record->change_and_save( 'fieldname' => 'new_value', ... )
sub change_and_save {
  my $record = shift;
  $record->call_methods( @_ );
  $record->save_record;
  $record;
}

########################################################################

=head2 Destructor

Automatically invoked when record is being garbage collected.

=over 4

=item pre_destroy

  $record->pre_destroy ()

Inheritable Hook. Subclasses should override this with any functions they wish called when an individual record is being garbage collected.

=back

=cut

use Class::MakeMethods::Composite::Inheritable(hook=>'pre_destroy'); 

sub DESTROY {
  my $self = shift;
  $self->pre_destroy();
}

########################################################################

=head1 SEE ALSO

See L<DBIx::DBO2> for an overview of this framework.

=cut

########################################################################

1;
