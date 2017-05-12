=head1 NAME

DBIx::SQLEngine::Driver::Pg - Support DBD::Pg

=head1 SYNOPSIS

B<DBI Wrapper>: Adds methods to a DBI database handle.

  my $sqldb = DBIx::SQLEngine->new( 'dbi:pg:test' );
    
B<Portability Subclasses:> Uses driver's idioms or emulation.

  $hash_ary = $sqldb->fetch_select( 
    table => 'students' 
    limit => 5, offset => 10
  );

=head1 DESCRIPTION

This package provides a subclass of DBIx::SQLEngine which compensates for Postgres's idiosyncrasies.

=head2 About Driver Subclasses

You do not need to use this package directly; when you connect to a database, the SQLEngine object is automatically re-blessed in to the appropriate subclass.

=cut

########################################################################

package DBIx::SQLEngine::Driver::Pg;

use strict;
use Carp;

########################################################################

=head2 sql_limit

  $sqldb->sql_limit( $limit, $offset, $sql, @params ) : $sql, @params

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

Implemented using _seq_do_insert_preinc and seq_increment.

=head2 seq_increment

  $sqldb->seq_increment( $table, $field ) : $new_value

Increments the sequence, and returns the newly allocated value. 

=cut

# $rows = $self->do_insert_with_sequence( $sequence, %clauses );
sub do_insert_with_sequence {
  (shift)->_seq_do_insert_preinc( @_ )
}

# $current_id = $sqldb->seq_increment( $table, $field );
sub seq_increment {
  my ($self, $table, $field) = @_;
  $self->fetch_one_value( 
    sql => "SELECT nextval('${table}_${field}_seq')"
  );
}

########################################################################

=head2 dbms_create_column_types

  $sqldb->dbms_create_column_types () : %column_type_codes

Implemented using Pg's bytea and serial types.

=head2 dbms_create_column_text_long_type

  $sqldb->dbms_create_column_text_long_type () : $col_type_str

Implemented using Pg's text type.

=cut

sub dbms_create_column_types {
  'sequential' => 'serial', 
  'binary' => 'bytea',
}

sub dbms_create_column_text_long_type { 
  'text' 
}

########################################################################

=head2 recoverable_query_exceptions

  $sqldb->recoverable_query_exceptions() : @common_error_messages

Provides a list of error messages which represent common
communication failures or other incidental errors.

=cut

sub recoverable_query_exceptions {
  'backend closed the channel unexpectedly',
  'there is no connection to the backend',
  'reconnect to the database system and repeat your query',
  'no statement executing',
  'fetch without execute',
  'field number \d+ is out of range 0\.\.\-1',
}

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
