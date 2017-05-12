=head1 NAME

DBIx::SQLEngine::Driver::Trait::PerlDBLib - For use with SQL::Statement

=head1 SYNOPSIS

  # Classes can import this behavior if they're based on SQL::Statement
  use DBIx::SQLEngine::Driver::Trait::PerlDBLib ':all';
  
=head1 DESCRIPTION

This package works with DBD drivers which are implemented in Perl using SQL::Statement. It combines several other traits and methods which can be shared by most such drivers.

=head2 About Driver Traits

You do not need to use this package directly; it is used internally by those driver subclasses which need it. 

For more information about Driver Traits, see L<DBIx::SQLEngine::Driver/"About Driver Traits">.

=cut

########################################################################

package DBIx::SQLEngine::Driver::Trait::PerlDBLib;

use strict;
use Carp;
use vars qw( @EXPORT_OK %EXPORT_TAGS );

########################################################################

use DBIx::SQLEngine::Driver::Trait::NoUnions ':all';
use DBIx::SQLEngine::Driver::Trait::NoSequences ':all';
use DBIx::SQLEngine::Driver::Trait::NoColumnTypes ':all';
use DBIx::SQLEngine::Driver::Trait::NoAdvancedFeatures  qw( :all );

use Exporter;
sub import { goto &Exporter::import } 
@EXPORT_OK = ( 
  qw( 
    fetch_one_value sql_limit 
    detect_any sql_detect_any
    dbms_create_column_types dbms_create_column_text_long_type 
    sql_create_columns
    dbms_select_table_as_unsupported
  ),
  @DBIx::SQLEngine::Driver::Trait::NoUnions::EXPORT_OK,
  @DBIx::SQLEngine::Driver::Trait::NoSequences::EXPORT_OK,
  @DBIx::SQLEngine::Driver::Trait::NoColumnTypes::EXPORT_OK,
  @DBIx::SQLEngine::Driver::Trait::NoAdvancedFeatures::EXPORT_OK,
);
%EXPORT_TAGS = ( all => \@EXPORT_OK );

########################################################################

=head1 REFERENCE

The following methods are provided:

=cut
########################################################################

=head2 fetch_one_value

Special handling for simple functions. Allows select count(), max(), or min(), but only if that is the only value being returned.

=cut

sub fetch_one_value {
  my $self = shift;
  my %args = @_;
  if ( my $column_clause = $args{columns} ) {
    if ( $column_clause =~ /\A\s*count\((.*?)\)\s*\Z/ ) {
      $args{columns} = $1;
      my $rows = $self->fetch_select( %args );
      return( $rows ? scalar( @$rows ) : 0 )
    } elsif ( $column_clause =~ /\A\s*max\((.*?)\)\s*\Z/ ) {
      $args{columns} = $1;
      $args{order} = "$1 desc";
    } elsif ( $column_clause =~ /\A\s*min\((.*?)\)\s*\Z/ ) {
      $args{columns} = $1;
      $args{order} = "$1";
    } 
  } 
  $self->NEXT('fetch_one_value', %args );
}

########################################################################

=head2 sql_limit

Adds support for SQL select limit clause.

TODO: Needs workaround to support offset.

=cut

sub sql_limit {
  my $self = shift;
  my ( $limit, $offset, $sql, @params ) = @_;
  
  # You can't apply "limit" to non-table fetches
  $sql .= " limit $limit" if ( $sql =~ / from / );
  
  return ($sql, @params);
}

########################################################################

=head2 do_insert_with_sequence

  $sqldb->do_insert_with_sequence( $sequence_name, %sql_clauses ) : $row_count

Implemented using DBIx::SQLEngine::Driver::Trait::NoSequences.

=cut

########################################################################

=head2 detect_any

  $sqldb->detect_any ( )  : $boolean

Returns 1, as we presume that the requisite driver modules are
available or we wouldn't have reached this point.

=head2 sql_detect_any

This should not be called. Throws fatal exception.

=cut

sub detect_any {
  return 1;
}

sub sql_detect_any {
  croak "Unsupported";
}

########################################################################

=head2 sql_create_columns

  $sqldb->sql_create_columns( $column, $fragment_array_ref ) : $sql_fragment

Generates the SQL fragment to define a column in a create table statement.

Overridden to B<not> produce "PRIMARY KEY ( foo )" clauses for the primary key.

=head2 dbms_create_column_types

  $sqldb->dbms_create_column_types () : %column_type_codes

Implemented using the standard int and varchar types.

=head2 dbms_create_column_text_long_type

  $sqldb->dbms_create_column_text_long_type () : $col_type_str

Implemented using the standard varchar type.

=cut

# Filter out primary key clauses in SQL create statements
sub sql_create_columns {
  my($self, $table, $column, $columns) = @_;
  return if ( $column->{type} eq 'primary' );
  $self->NEXT('sql_create_columns', $table, $column, $columns );
}

sub dbms_create_column_types {
  'sequential' => 'int',
}

sub dbms_create_column_text_long_type {
  'varchar(16384)'
}

########################################################################

=head2 dbms_select_table_as_unsupported

  $sqldb->dbms_select_table_as_unsupported () : 1

Capability Limitation: This driver does not support table aliases such as "select * from foo as bar".

=head2 dbms_column_types_unsupported

  $sqldb->dbms_column_types_unsupported () : 1

Capability Limitation: This driver does not store column type information.

=head2 dbms_indexes_unsupported

  $sqldb-> dbms_indexes_unsupported () : 1

Capability Limitation: This driver does not support indexes.

=head2 dbms_storedprocs_unsupported

  $sqldb-> dbms_storedprocs_unsupported () : 1

Capability Limitation: This driver does not support stored procedures.

=cut

sub dbms_select_table_as_unsupported { 1 }

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

See L<DBIx::Sequence> for another version of the sequence-table functionality, which greatly inspired this module.

=cut

########################################################################

1;

