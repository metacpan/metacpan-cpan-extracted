=head1 NAME

DBIx::SQLEngine::Record::Accessors - Add Methods for Columns

=head1 SYNOPSIS

B<Setup:> Several ways to create a class.

  my $sqldb = DBIx::SQLEngine->new( ... );

  $class_name = $sqldb->record_class( $table_name, undef, 'Accessors' );
  
  $sqldb->record_class( $table_name, 'My::Record', 'Accessors' );
  
  package My::Record;
  use DBIx::SQLEngine::Record::Class '-isasubclass', 'Accessors';  
  My::Record->table( $sqldb->table($table_name) );

B<Accessors:> Create methods for columns.
  
  $class_name->install_accessors( %column_info );


=head1 DESCRIPTION

This package provides automatic method generation for DBIx::SQLEngine::Record objects.

Don't use this module directly; instead, pass its name as a trait when you create a new record class. This package provides a multiply-composable collection of functionality for Record classes. It is combined with the base class and other traits by DBIx::SQLEngine::Record::Class. 

This package is not yet complete.

=cut

########################################################################

package DBIx::SQLEngine::Record::Accessors;

use strict;
use Carp;

########################################################################

########################################################################

=head1 ACCESSORS INTERFACE

=head2 Autoloader

=over 4

=item AUTOLOAD

Provided by Class::MakeMethods::Autoload. Generates scalar accessor methods using Class::MakeMethods::Standard::Hash.

=back

=cut

use Class::MakeMethods::Autoload 'Standard::Hash:scalar';

########################################################################

########################################################################

=head1 SIMPLE RECORD INTERFACE

=head2 Getting and Changing Values

Simple interface for applying changes.

=over 4

=item get_values()

  $record->get_values( key1 ) : $value
  $record->get_values( key1, key2, ... ) : $values_joined_with_comma
  $record->get_values( key1, key2, ... ) : @values

Returns the values associated with the keys in the provided record.

=item change_values 

  $record->change_values( method1 => value1, ... ); 

Call provided method names with supplied values.
(Class::MakeMethods::Standard::Universal:call_methods).

=back

=cut

sub get_values {
  my $self = shift;
  ref($self) or croak("Can't call this object method on a record class");
  my @values = map $self->$_(), @_;
  wantarray ? @values : join(', ', @values)
}

use Class::MakeMethods ( 
  'Standard::Universal:call_methods' => 'change_values',
);

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
