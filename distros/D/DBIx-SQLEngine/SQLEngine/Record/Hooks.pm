=head1 NAME

DBIx::SQLEngine::Record::Hooks - Flexible Pre/Post Hooks

=head1 SYNOPSIS

B<Setup:> Several ways to create a class.

  my $sqldb = DBIx::SQLEngine->new( ... );

  $class_name = $sqldb->record_class( $table_name, undef, 'Hooks' );
  
  $sqldb->record_class( $table_name, 'My::Record', 'Hooks' );
  
  package My::Record;
  use DBIx::SQLEngine::Record::Class '-isasubclass', 'Hooks';  
  My::Record->table( $sqldb->table($table_name) );

B<Hooks:> Register subs for callbacks.

  DBIx::SQLEngine::Record::Hooks->install_hooks( 
    post_new    => sub { warn "Record $_[0] created" },
    post_fetch  => sub { warn "Record $_[0] loaded" },
    post_insert => sub { warn "Record $_[0] inserted" },
    post_update => sub { warn "Record $_[0] updated" },
    post_delete => sub { warn "Record $_[0] deleted" },
  );
  
  $class_name->install_hooks( %hook_subs );

  $record->install_hooks( %hook_subs );

B<Basics:> Layered over superclass.

  # Calls post_fetch hooks on record
  $record = $class_name->fetch_record( $primary_key );

  # Calls post_fetch hooks on each record
  @records = $class_name->fetch_select(%clauses)->records;
  
  # Calls post_new hooks on empty record
  $record = $class_name->new_with_values(somefield => 'My Value');

  # Calls ok_insert, pre_insert, and post_insert hooks
  $record->insert_record();
  
  # Calls ok_update, pre_update, and post_update hooks
  $record->update_record();
  
  # Calls ok_delete, pre_delete, and post_delete hooks
  $record->delete_record();


=head1 DESCRIPTION

This package provides a callback layer for DBIx::SQLEngine::Record objects.

Don't use this module directly; instead, pass its name as a trait when you create a new record class. This package provides a multiply-composable collection of functionality for Record classes. It is combined with the base class and other traits by DBIx::SQLEngine::Record::Class. 

=cut

########################################################################

package DBIx::SQLEngine::Record::Hooks;

use strict;
use Carp;

########################################################################

########################################################################

=head1 HOOKS INTERFACE

Many of the methods below are labeled "Inheritable Hook." These methods allow you to register callbacks which are then invoked at specific points in each record's lifecycle. You can add these callbacks to all record classes, to a particular class, or even to a particular object instance.

These hooks act like the triggers supported by some databases; you can ensure that every time a record is updated in a specific table, certain other actions occur automatically.

To register a callback, call the install_hooks method, and pass it pairs of a hook method name, and a subroutine reference, as follows: I<callee>->install_hooks( I<methodname> => I<coderef>, ... ).

=over 4

=item install_hooks()

  $classname->install_hooks( $hook_name => \&my_sub, ... )
  $record->install_hooks( $hook_name => \&my_sub, ... )

Registers one or more callbacks. Accepts pairs of a hook method name, and a subroutine reference. 

For more about the implementation of the Hook mechanism, see L<Class::MakeMethods::Composite::Inheritable>.

=back

B<Examples:>

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
  $record->install_hooks( pre_destroy => sub { (shift)->save_record } );

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

########################################################################

=head1 SIMPLE RECORD INTERFACE

=head2 Constructor

You may create your own records for new instances, or fetch records from the database as described in L</"FETCHING DATA (SQL DQL)">

=over 4

=item new_empty_record()

  $class_name->new_empty_record() : $empty_record

Adds support for post_new hook. 

=item post_new()

Inheritable Hook. Add functions which should be called immediately after each record is created and initialized.

=back

=cut

sub new_empty_record {
  my $record = (shift)->NEXT('new_empty_record', @_ );
  $record->post_new; 
  return $record;
}

use Class::MakeMethods::Composite::Inheritable(hook=>'post_new' ); 

########################################################################

=head2 Destructor

Automatically invoked when record is being garbage collected.

=over 4

=item DESTROY()

  $record->DESTROY()

Adds support for pre_destroy hook. 

=item pre_destroy

  $record->pre_destroy ()

Inheritable Hook. Add functions which should be called when an individual record is being garbage collected.

=back

=cut

use Class::MakeMethods::Composite::Inheritable(hook=>'pre_destroy'); 

sub DESTROY {
  my $self = shift;
  $self->pre_destroy();
  $self->NEXT('DESTROY');
  $self;
}

########################################################################

########################################################################

=head1 FETCHING DATA (SQL DQL)

=head2 Vivifying Records From The Database

These methods are called internally by the various select methods and do not need to be called directly.

=over 4

=item record_from_db_data()

  $class_name->record_from_db_data( $hash_ref )
  $class_name->record_from_db_data( $hash_ref ) : $record
  $class_name->record_from_db_data( %hash_contents ) : $record

Adds support for post_fetch hook. 

=item record_set_from_db_data()

  $class_name->record_set_from_db_data( $hash_array_ref )
  $class_name->record_set_from_db_data( $hash_array_ref ) : $record_set
  $class_name->record_set_from_db_data( @hash_refs ) : $record_set

Adds support for post_fetch hook. 

=item post_fetch()

Inheritable Hook. Add functions which should be called immediately after each record is retrieved from the database.

=back

=cut


use Class::MakeMethods::Composite::Inheritable( hook=>'post_fetch' ); 

# $row_class->record_from_db_data( $hash_ref );
# $row = $row_class->record_from_db_data( $hash_ref );
# $row = $row_class->record_from_db_data( %hash_contents );
sub record_from_db_data {
  my $record = (shift)->NEXT('record_from_db_data', @_ ) or return;
  $record->post_fetch; 
  return $record;
}

sub record_set_from_db_data {
  my $recordset = (shift)->NEXT('record_set_from_db_data', @_ ) or return;
  foreach my $record ( @$recordset ) { $record->post_fetch }
  return $recordset;
}

########################################################################

########################################################################

=head1 EDITING DATA (SQL DML)

=head2 Insert to Add Records

After constructing a record with one of the new_*() methods, you may save any changes by calling insert_record.

=over 4

=item insert_record

  $record_obj->insert_record() : $flag

Attempt to insert the record into the database. 

Calls ok_insert to ensure that it's OK to insert this row, and aborts if any of hook subroutines return 0. 

Calls any pre_insert hooks, then calls the superclass insert_row method, then calls any post_insert hooks.

Returns undef if the update was aborted, or the record if the insert was successful.

=item ok_insert

Inheritable Hook. Add functions which should be called to validate rows before they are inserted.

=item pre_insert

Inheritable Hook. Add functions which should be called immediately before a row is inserted.

=item post_insert

Inheritable Hook. Add functions which should be called after a row is inserted.

=back

=cut

use Class::MakeMethods::Composite::Inheritable(hook=>'ok_insert pre_insert post_insert'); 

# $record->insert_record()
sub insert_record {
  my $self = shift;
  my $class = ref( $self ) or croak("Not a class method");
  
  my @flags = $self->ok_insert();
  if ( grep { length $_ and ! $_ } @flags ) {
    # warn "Cancelling insert of $self: " . join(', ', map "'$_'", @flags);
    return undef;
  } 
  $self->pre_insert();
  $self->NEXT('insert_record');
  $self->post_insert();
  $self;
}

########################################################################

=head2 Update to Change Records

After retrieving a record with one of the fetch methods, you may save any changes by calling update_record.

=over 4

=item update_record

  $record_obj->update_record() : $record_count

Attempts to update the record using its primary key as a unique identifier. 

Calls ok_update to ensure that it's OK to update this row, and aborts if any of hook subroutines return 0. 

Calls any pre_update hooks, then calls the superclass method, then calls any post_update hooks.

Returns undef if the update was aborted, or the record if the update was successful.

=item ok_update

Inheritable Hook. Add functions which to use to validate rows before they are updated. Return 0 to abort the update.

=item pre_update

Inheritable Hook. Add functions which should be called immediately before a row is updated.

=item post_update

Inheritable Hook. Add functions which should be called immediately after a row is updated.

=back

=cut

use Class::MakeMethods::Composite::Inheritable(hook=>'ok_update pre_update post_update'); 

# $record->update_record()
sub update_record {
  my $self = shift;
  my $class = ref( $self ) or croak("Not a class method");
  my @flags = $self->ok_update;
  if ( grep { length $_ and ! $_ } @flags ) {
    # warn "Cancelling update of $self: " . join(', ', map "'$_'", @flags );
    return undef;
  } 
  # warn "About to update $self: " . join(', ', map "'$_'", @flags );
  $self->pre_update();
  $self->NEXT('update_record');
  $self->post_update();
  $self;
}

########################################################################

=head2 Delete to Remove Records

=over 4

=item delete_record()

  $record_obj->delete_record() : $record_count

Delete this existing record based on its primary key. 

Checks to see if any of the pre_delete results is "0". If not, calls the superclass method.

Returns 1 if the deletion was successful, or 0 if it was aborted.

=item ok_delete

  $record->ok_delete () : @booleans

Inheritable Hook. Add functions which should be used to use to validate rows before they are updated. Return 0 to abort the deletion.

=item pre_delete

  $record->pre_delete ()

Inheritable Hook. Add functions which should be called before a row is deleted.

=item post_delete

  $record->post_delete ()

Inheritable Hook. Add functions which should be called after a row is deleted.

=back

=cut

use Class::MakeMethods::Composite::Inheritable(hook=>'ok_delete pre_delete post_delete'); 

# $success = $record->delete_record();
sub delete_record {
  my $self = shift;
  my @flags = $self->ok_delete;
  if ( grep { length $_ and ! $_ } @flags ) {
    # warn "Cancelling delete of $self: " . join(', ', map "'$_'", @flags );
    return 0;
  } 
  # warn "About to delete $self: " . join(', ', map "'$_'", @flags );
  $self->pre_delete();
  $self->NEXT('delete_record');
  $self->post_delete();
  return 1;
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
