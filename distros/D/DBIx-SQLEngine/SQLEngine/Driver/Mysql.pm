=head1 NAME

DBIx::SQLEngine::Driver::Mysql - Support DBD::mysql

=head1 SYNOPSIS

B<DBI Wrapper>: Adds methods to a DBI database handle.

  my $sqldb = DBIx::SQLEngine->new( 'dbi:mysql:test' );
  
B<Portability Subclasses:> Uses driver's idioms or emulation.

  $hash_ary = $sqldb->fetch_select( 
    table => 'students' 
    limit => 5, offset => 10
  );

=head1 DESCRIPTION

This package provides a subclass of DBIx::SQLEngine which compensates for MySQL's idiosyncrasies.

=head2 About Driver Subclasses

You do not need to use this package directly; when you connect to a database, the SQLEngine object is automatically re-blessed in to the appropriate subclass.

For more information about the underlying driver class, see L<DBD::Mysql>.

=cut

########################################################################

package DBIx::SQLEngine::Driver::Mysql;

use strict;
use Carp;

########################################################################

########################################################################

=head1 DRIVER AND DATABASE FLAVORS

=head2 About DBMS Flavors

This driver uses the DatabaseFlavors trait in order to accomodate variations between different versions of MySQL. For more information, see L<DBIx::SQLEngine::Driver::Trait::DatabaseFlavors>.

=head2 Detecting DBMS Flavors

=over 4

=item default_dbms_flavor()

  $sqldb->default_dbms_flavor() : "V3_0"

By default, it is assumed that we're talking to an early version of MySQL 3.0, without transactions, unions, or stored procedures.

=item detect_dbms_flavor()

  $sqldb->detect_dbms_flavor() : $flavor_name

Attempts to determine which version of MySQL we're connected to based on the results of are_transactions_supported() and detect_union_supported().

=back

If you want to take advantage of any advanced features that may be available, first call select_detect_dbms_flavor().

=cut

use DBIx::SQLEngine::Driver::Trait::DatabaseFlavors qw( :all !default_dbms_flavor !detect_dbms_flavor );

sub default_dbms_flavor { 'V3_0' }

sub detect_dbms_flavor {
  my $self = shift;
  my $guess = 'V3_0';
  $guess = 'V3_23' if ( $self->are_transactions_supported() );
  $guess = 'V4_0' if ( $self->detect_union_supported() );
  return $guess;
}

########################################################################

=head2 Version Classes

The following subclasses provide support for particular versions of MySQL:

=over 4

=item V3_0

This is the earliest version we have a subclass for. Default. 
No transactions, union selects, or stored procedures.

=item V3_23

This is the first version with support for transactions.
No union selects, or stored procedures.

=item V4_0

This is the first version with support for unions in select statements.
No stored procedures.

=item V5_0

The version is still in development. It will be the first version to support stored procedures.

=back

=cut

FLAVOR_CLASSES: { 

  no strict;
  
  ############################################################

  package DBIx::SQLEngine::Driver::Mysql::V3_0;
  @ISA = qw( DBIx::SQLEngine::Driver::Mysql );

  use DBIx::SQLEngine::Driver::Trait::NoUnions ':all';
  use DBIx::SQLEngine::Driver::Trait::NoAdvancedFeatures qw( /transaction/ /storedproc/ );
  
  ############################################################
  
  package DBIx::SQLEngine::Driver::Mysql::V3_23;
  @ISA = qw( DBIx::SQLEngine::Driver::Mysql );

  use DBIx::SQLEngine::Driver::Trait::NoUnions ':all';
  use DBIx::SQLEngine::Driver::Trait::NoAdvancedFeatures qw( /storedproc/ );
  
  ############################################################
  
  package DBIx::SQLEngine::Driver::Mysql::V4_0;
  @ISA = qw( DBIx::SQLEngine::Driver::Mysql );

  use DBIx::SQLEngine::Driver::Trait::NoAdvancedFeatures qw( /storedproc/ );
  
  ############################################################
  
  package DBIx::SQLEngine::Driver::Mysql::V5_0;
  @ISA = qw( DBIx::SQLEngine::Driver::Mysql );
  
  ############################################################

}

########################################################################

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
  if ( $sql =~ /\bfrom\b/i and $limit or $offset) {
    $limit ||= 1_000_000; # MySQL select with offset requires a limit
    $sql .= " limit " . ( $offset ? "$offset," : '' ) . $limit;
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

=item seq_fetch_current()

  $sqldb->seq_fetch_current( ) : $current_value

Implemented using MySQL's "select LAST_INSERT_ID()". Note that this
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
  $self->fetch_one_value( sql => 'select LAST_INSERT_ID()' );
}

########################################################################

########################################################################

=head1 DEFINING STRUCTURES (SQL DDL)

=head2 Detect Tables and Columns

=over 4

=item sql_detect_table()

  $sqldb->sql_detect_table ( $tablename )  : %sql_select_clauses

Implemented using MySQL's "select * from $tablename limit 1".

=back

=cut

sub sql_detect_table {
  my ($self, $tablename) = @_;
  return ( sql => "select * from $tablename limit 1" );
}

########################################################################

=head2 Column Type Methods

=over 4

=item dbms_create_column_types()

  $sqldb->dbms_create_column_types () : %column_type_codes

Implemented using MySQL's blob and auto_increment types.

=item dbms_create_column_text_long_type()

  $sqldb->dbms_create_column_text_long_type () : $col_type_str

Implemented using MySQL's blob type.

=back

=cut

sub dbms_create_column_types {
  'sequential' => 'int auto_increment primary key', 
  'binary' => 'blob',
}

sub dbms_create_column_text_long_type {
  'blob'
}

########################################################################

########################################################################

=head1 INTERNAL STATEMENT METHODS (DBI STH)

=head2 Statement Error Handling 

=over 4

=item recoverable_query_exceptions()

  $sqldb->recoverable_query_exceptions() : @common_error_messages

Provides a list of error messages which represent common
communication failures or other incidental errors.

=back

=cut

sub recoverable_query_exceptions {
  'Lost connection to MySQL server',
  'MySQL server has gone away',
  'no statement executing',
  'fetch without execute',
  "\Qfetch() without execute()",
}

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
