=head1 NAME

DBIx::SQLEngine::Record::Class - Factory for Record Classes

=head1 SYNOPSIS

B<Setup:> Several ways to create a class.

  $sqldb = DBIx::SQLEngine->new( ... );
  
  $class_name = $sqldb->record_class( $table_name, @traits );
  
  $sqldb->record_class( $table_name, $class_name, @traits );
  
  package My::Record;
  use DBIx::SQLEngine::Record::Class '-isasubclass', 'Table', 'Hooks';  
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

=head1 DESCRIPTION

DBIx::SQLEngine::Record::Class is a factory for Record classes.

You can use this package to create a class whose instances represent each of the rows in a SQL database table.

=cut

########################################################################

package DBIx::SQLEngine::Record::Class;

use strict;
use Carp;

require DBIx::SQLEngine::Record::Base;

########################################################################

=head1 CLASS INSTANTIATION

=head2 Subclass Factory

=over 4

=item import

  package My::Record;
  use DBIx::SQLEngine::Record::Class '-isasubclass';
  use DBIx::SQLEngine::Record::Class '-isasubclass', @Traits;

Allows for a simple declaration of inheritance.

=back

=cut

sub import {
  my $factory = shift;

  return unless ( @_ );
  
  if ( $_[0] eq '-isasubclass' ) {
    shift;
    my $base = $factory->class( @_ );

    my $target_class = ( caller )[0];
    no strict;
    push @{"$target_class\::ISA"}, $base;
  } else {
    croak("Unsupported import '$_[0]'")
  }
}

########################################################################

=head2 Mixin Class Factory

=over 4

=item class()

  $factory->class() : $base_class
  $factory->class( @traits ) : $class_name

Build an ad-hod class with mixins. 

See the documentation for Class::MixinFactory to learn more about developing custom mixin classes.

=back

The MixinFactory is configured with the following package names:

=over 12

=item base_class

DBIx::SQLEngine::Record::Base

=item mixin_prefix

DBIx::SQLEngine::Record

=item mixed_prefix

DBIx::SQLEngine::Record::AUTO

=back

=cut

use Class::MixinFactory -isafactory;
__PACKAGE__->base_class(   "DBIx::SQLEngine::Record::Base" );
__PACKAGE__->mixin_prefix( "DBIx::SQLEngine::Record" );
__PACKAGE__->mixed_prefix( "DBIx::SQLEngine::Record::AUTO" );

########################################################################

=head2 Record Class Creation

=over 4

=item new_subclass()

  DBIx::SQLEngine::Record::Class->new_subclass( %options ) : $class_name

Subclass constructor. Accepts a hash of options with the following keys:

=over 4

=item 'name'

If you do not supply a class name, one is generated based on the table name, which must be provided.

If the class name does not contain a "::" package separator, it is prepended
with DBIx::SQLEngine::Record::Auto:: to keep the namespace conflict-free.

=item 'table'

You may provde a DBIx::SQLEngine::Schema::Table object or create the class without it and initialize it later.

=item 'traits'

You may pass a reference to one or more trait names as a "traits" argument.

=back

=item subclass_for_table()

  DBIx::SQLEngine::Record::Class->subclass_for_table( $table, $name, @traits ) : $class_name

Convenience method for common parameters. 
You are expected to provde a DBIx::SQLEngine::Schema::Table object.

=item generate_subclass_name_for_table()

Called internally by new_subclass() if no class name is provided.

=back

Cross-constructors from other objects:

=over 4

=item SQLEngine->record_class()

  $sqldb->record_class( $tablename ) : $class_name
  $sqldb->record_class( $tablename, $name ) : $class_name
  $sqldb->record_class( $tablename, $name, @traits ) : $class_name

Convenience method to create a record class with the given table name.

=item Table->record_class()

  $table->record_class( ) : $class_name
  $table->record_class( $name ) : $class_name
  $table->record_class( $name, @traits ) : $class_name

Convenience method to create a record class for a given table object.

=back

=cut

sub new_subclass {
  my ( $factory, %options ) = @_;

  my $traits = $options{traits};

  my $table = $options{table};
  ( ! $table ) or ( grep { $_ eq 'Table' } @$traits ) or push @$traits, 'Table';

  my $base = $factory->class( $options{traits} );
  
  my $name = $options{name} || do {
    $table or croak("$factory new_subclass without a name requires a table");
    $factory->generate_subclass_name_for_table($table);
  };
  $name = "DBIx::SQLEngine::Record::Auto::" . $name unless ( $name =~ /::/ );

  no strict 'refs';
  @{"$name\::ISA"} = $base;

  $name->table( $table ) if ( $table );
  
  return $name;
}

sub subclass_for_table {
  my ($factory, $table, $classname, @traits) = @_;
  ( grep { $_ eq 'Table' } @traits ) or push @traits, 'Table';
  $factory->new_subclass(
    table => $table, name => $classname, traits => \@traits
  )
}

my %generated_names_for_table;
sub generate_subclass_name_for_table {
  my ($factory, $table) = @_;
  my $tname = $table->name;
  my $tsqle = $table->sqlengine;
  my $t_str = "$tname-$tsqle";

  if ( my $names = $generated_names_for_table{ $tname } ) {
    return $tname if ( $names->{ $tname } eq $t_str );
    my $t_index = $tname . "_1";
    until ( $names->{ $t_index } eq $t_str ) { $t_index ++ }
    return $t_index;
  } else {
    $generated_names_for_table{ $tname } = { $tname => $t_str };
    return $tname;
  }
}

########################################################################

########################################################################

=head1 RECORD CLASS TRAITS

Depending on application, there are several different sets of features that one might or might not wish to have available on their record class. 

=head2 Included Trait Classes

The following trait classes are included with this distribution:

=over 4

=item Accessors

Generates methods for getting and setting values in each record object.

=item Cache

Provides a caching layer to avoid repeated selections of the same information.

=item Hooks 

Adds ok_, pre_, and post_ hooks to key methods. Any number of code refs can be registered to be called at key times, by class or for specific instances. 

=back

=cut

########################################################################

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
