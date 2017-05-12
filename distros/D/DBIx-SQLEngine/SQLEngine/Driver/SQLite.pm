=head1 NAME

DBIx::SQLEngine::Driver::SQLite - Support DBD::SQLite driver

=head1 SYNOPSIS

B<DBI Wrapper>: Adds methods to a DBI database handle.

  my $sqldb = DBIx::SQLEngine->new( 'dbi:SQLite:dbname=mydatafile.sqlite' );
  
B<Portability Subclasses:> Uses driver's idioms or emulation.

  $hash_ary = $sqldb->fetch_select( 
    table => 'students' 
    limit => 5, offset => 10
  );

=head1 DESCRIPTION

This package provides a subclass of DBIx::SQLEngine which compensates for SQLite's idiosyncrasies.

=head2 About Driver Subclasses

You do not need to use this package directly; when you connect to a database, the SQLEngine object is automatically re-blessed in to the appropriate subclass.

=cut

########################################################################

package DBIx::SQLEngine::Driver::SQLite;

use strict;
use Carp;

########################################################################

=head2 sql_limit

Adds support for SQL select limit clause.

=cut

sub sql_limit {
  my $self = shift;
  my ( $limit, $offset, $sql, @params ) = @_;

  # You can't apply "limit" to non-table fetches like "select LAST_INSERT_ID"
  if ( $sql =~ /\bfrom\b/i and defined $limit or defined $offset) {
    $sql .= " limit $limit" if $limit;
    $sql .= " offset $offset" if $offset;
  }
  
  return ($sql, @params);
}

########################################################################

=head2 do_insert_with_sequence

  $sqldb->do_insert_with_sequence( $sequence_name, %sql_clauses ) : $row_count

Implemented using _seq_do_insert_postfetch and seq_fetch_current.

=head2 seq_fetch_current

  $sqldb->seq_fetch_current( ) : $current_value

Implemented using SQLite's dbh_func() "last_insert_rowid". Note that this
doesn't fetch the current sequence value for a given table, since
it doesn't respect the table and field arguments, but merely returns
the last sequencial value created during this session.

=cut

# $rows = $self->do_insert_with_sequence( $sequence, %clauses );
sub do_insert_with_sequence {
  (shift)->_seq_do_insert_postfetch( @_ )
}

# $current_id = $sqldb->seq_fetch_current( );
sub seq_fetch_current {
  my $self = shift;
  $self->dbh_func('last_insert_rowid');
}

########################################################################

=head2 detect_any

  $sqldb->detect_any ( )  : $boolean

Returns 1, as we presume that the requisite driver modules are
available or we wouldn't have reached this point.

=head2 sql_detect_table

  $sqldb->sql_detect_table ( $tablename )  : %sql_select_clauses

Implemented using SQLite's "select * from $tablename limit 1".

=cut

sub detect_any {
  return 1;
}

sub sql_detect_table {
  my ($self, $tablename) = @_;
  return ( sql => "select * from $tablename limit 1" );
}

########################################################################

=head2 dbms_create_column_types

  $sqldb->dbms_create_column_types () : %column_type_codes

Implemented using SQLite's blob and int auto_increment types.

=head2 dbms_create_column_text_long_type

  $sqldb->dbms_create_column_text_long_type () : $col_type_str

Implemented using SQLite's blob type.

=cut

sub dbms_create_column_types {
  'sequential' => 'integer primary key',
  'binary' => 'blob',
}

sub dbms_create_column_text_long_type {
  'blob'
}

########################################################################

=head2 dbms_column_types_unsupported

  $sqldb->dbms_column_types_unsupported () : 1

Capability Limitation: This driver does not store column type information.

=head2 dbms_indexes_unsupported

  $sqldb->dbms_indexes_unsupported () : 1

Capability Limitation: This driver does not support indexes.

=head2 dbms_storedprocs_unsupported

  $sqldb->dbms_storedprocs_unsupported () : 1

Capability Limitation: This driver does not support stored procedures.

=head2 dbms_detect_tables_unsupported

  $sqldb->dbms_detect_tables_unsupported () : 1

Capability Limitation: This driver does not return a list of available tables.

=cut

use DBIx::SQLEngine::Driver::Trait::NoColumnTypes ':all';

sub dbms_indexes_unsupported      { 1 }
sub dbms_storedprocs_unsupported  { 1 }

sub dbms_detect_tables_unsupported   { 1 }

########################################################################

# sub catch_query_exception {
  # if ( $error =~ /\Q{TYPE}: unrecognised attribute\E/i ) {
  # This means the query failed; we'll return nothing.
  # return 'OK';
# }

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
