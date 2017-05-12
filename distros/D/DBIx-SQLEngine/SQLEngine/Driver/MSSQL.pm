=head1 NAME

DBIx::SQLEngine::Driver::MSSQL - Support Microsoft SQL Server via DBD::ODBC

=head1 SYNOPSIS

B<DBI Wrapper>: Adds methods to a DBI database handle.

  my $sqldb = DBIx::SQLEngine->new( 'dbi:odbc:mycnxn' );
  
B<Portability Subclasses:> Uses driver's idioms or emulation.
  
  $hash_ary = $sqldb->fetch_select( 
    table => 'students' 
    limit => 5, offset => 10
  );

=head1 DESCRIPTION

This package provides a subclass of DBIx::SQLEngine which compensates for Microsoft SQL Server's idiosyncrasies.

=head2 Under Development

Note: this driver class has been added recently and not yet tested in real-world conditions.

=head2 About Driver Subclasses

You do not need to use this package directly; when you connect to a database, the SQLEngine object is automatically re-blessed in to the appropriate subclass.

=cut

########################################################################

package DBIx::SQLEngine::Driver::MSSQL;

use strict;
use Carp;

########################################################################

=head1 FETCHING DATA (SQL DQL)

=head2 Methods Used By Complex Queries 

=over 4

=item sql_limit()

Adds support for SQL select limit clause.

=back

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

########################################################################

=head1 EDITING DATA (SQL DML)

=head2 Insert to Add Data 

=over 4

=item do_insert_with_sequence()

  $sqldb->do_insert_with_sequence( $sequence_name, %sql_clauses ) : $row_count

Implemented using _seq_do_insert_postfetch and seq_fetch_current.

=item seq_fetch_current

  $sqldb->seq_fetch_current( ) : $current_value

Implemented using MS SQL's "select @@IDENTITY". Note that this
doesn't fetch the current sequence value for a given table, since
it doesn't respect the table and field arguments, but merely returns
the last sequencial value created during this session.

=back

=cut

# $rows = $self->do_insert_with_sequence( $sequence, %clauses );
sub do_insert_with_sequence {
  (shift)->_seq_do_insert_postfetch( @_ )
}

# $current_id = $sqldb->seq_fetch_current( );
sub seq_fetch_current {
  my ($self, $table, $field) = @_;
  $self->fetch_one_value( 
    sql => 'select @@IDENTITY AS lastID'
  );
}

########################################################################

########################################################################

=head1 DEFINING STRUCTURES (SQL DDL)

=head2 Create and Drop Tables

=over 4

=item dbms_create_column_types()

  $sqldb->dbms_create_column_types () : %column_type_codes

Implemented using MS SQL's blob and int types.

=item dbms_create_column_text_long_type

  $sqldb->dbms_create_column_text_long_type () : $col_type_str

Implemented using MS SQL's blob type.

=back

=cut

sub dbms_create_column_types {
  'sequential' => 'int not null', 
  'binary' => 'blob',
}

sub dbms_create_column_text_long_type {
  'blob'
}

########################################################################

########################################################################

=head1 INTERNAL STATEMENT METHODS (DBI STH)

=head2 Statement Handle Lifecycle 

=over 4

=item prepare_execute()

After the normal prepare_execute cycle, this also sets the sth's LongReadLen to dbms_longreadlen_bufsize().

=item dbms_longreadlen_bufsize()

Set to 1_000_000.

=back

=cut

sub dbms_longreadlen_bufsize { 1_000_000 }

sub prepare_execute {
  my $self = shift;
  my $sth = $self->SUPER::prepare_execute( @_ );
  $sth->{LongReadLen} = $self->dbms_longreadlen_bufsize;
  $sth->{LongTruncOk} = 0;
  $sth;
}

########################################################################

=head2 recoverable_query_exceptions

  $sqldb->recoverable_query_exceptions() : @common_error_messages

Provides a list of error messages which represent common
communication failures or other incidental errors.

=cut

sub recoverable_query_exceptions {
  'Communication link failure',
  'General network error',
}

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
