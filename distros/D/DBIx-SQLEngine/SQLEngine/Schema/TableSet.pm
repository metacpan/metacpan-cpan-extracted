=head1 NAME

DBIx::SQLEngine::Schema::TableSet - Array of Schema::Table objects 

=head1 SYNOPSIS

  use DBIx::SQLEngine::Schema::TableSet;
  my $tables = DBIx::SQLEngine::Schema::TableSet->new( $table1, $table2 );
  
  print $tables->count;
  
  foreach my $table ( $tables->tables ) {
    print $table->name;
  }
  
  $table = $tables->table_named( $name );

  $ts->create_tables;

=head1 DESCRIPTION

DBIx::SQLEngine::Schema::TableSet objects contain an array of DBIx::SQLEngine::Schema::Table objects.

=cut

package DBIx::SQLEngine::Schema::TableSet;

use strict;
use Carp;
use Class::MakeMethods;

use DBIx::SQLEngine::Schema::Table;

########################################################################

=head2 Creation

=over 4

=item new()

  DBIx::SQLEngine::Schema::TableSet->new( @tables ) : $tableset

Creates a new instance.

=back

=cut

sub new {
  my $package = shift;
  my @tables = map {
    ( ref($_) eq 'HASH' ) ? DBIx::SQLEngine::Schema::Table->new_from_hash(%$_)
			  : $_
  } @_;
  bless \@tables, $package;
}

########################################################################

=head2 Access to Tables

=over 4

=item tables()

  $tableset->tables : @table_objects

Returns a list of tables contained in this set.

=item call_method_on_tables()

  $tableset->call_method_on_tables( $method, @args ) : @results

Calls the provided method on each of the tables in this set.

=back

=cut

sub tables {
  my $tables = shift;
  @$tables
}

sub call_method_on_tables {
  my $tables = shift;
  my $method = shift;
  return map { $_->$method( @_ ) } @$tables;
}


########################################################################

=head2 Table Names

=over 4

=item table_names()

  $tableset->table_names : @table_names

Returns a list of the names of each of the tables in this set.

=item table_named()

  $tableset->table_named( $table_name ); : $table_object

Searches through the tables in the set until it finds one with the given name. Throws an exception if none are found.

=back

=cut

# @colnames = $tables->table_names;
sub table_names {
  (shift)->call_method_on_tables( 'name' )
}

# $table = $tables->table_named( $table_name );
# $table = $tables->table_named( $table_name );
sub table_named {
  my $tables = shift;
  my $table_name = shift;
  foreach ( @$tables ) {
    return $_ if ( $_->name eq $table_name );
  }
  croak(
    "No table named $table_name in this set\n" . 
    "  (Perhaps you meant one of these: ".join(', ',$tables->table_names)."?)"
  );
}

########################################################################

=head2 Schema Definition

=over 4

=item create_tables()

  $tableset->create_tables : ()

Calls create_table() on each table in the set.

=item ensure_tables_exist()

  $tableset->ensure_tables_exist : ()

Calls ensure_table_exists() on each table in the set.

=item recreate_tables()

  $tableset->recreate_tables : ()

Calls recreate_table_with_rows() on each table in the set.

=item drop_tables()

  $tableset->drop_tables : ()

Calls drop_table() on each table in the set.

=back

=cut

sub create_tables {
  (shift)->call_method_on_tables( 'create_table' )
}

sub ensure_tables_exist {
  (shift)->call_method_on_tables( 'ensure_table_exists' )
}

sub recreate_tables {
  (shift)->call_method_on_tables( 'recreate_table_with_rows' )
}

sub drop_tables {
  (shift)->call_method_on_tables( 'drop_table' )
}

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
