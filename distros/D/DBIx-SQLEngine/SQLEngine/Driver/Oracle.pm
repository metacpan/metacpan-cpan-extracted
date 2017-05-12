=head1 NAME

DBIx::SQLEngine::Driver::Oracle - Support DBD::Oracle and DBD::ODBC/Oracle

=head1 SYNOPSIS

B<DBI Wrapper>: Adds methods to a DBI database handle.

  my $sqldb = DBIx::SQLEngine->new( 'dbi:oracle:test' );
    
B<Portability Subclasses:> Uses driver's idioms or emulation.

  $hash_ary = $sqldb->fetch_select( 
    table => 'students' 
    limit => 5, offset => 10
  );

=head1 DESCRIPTION

This package provides a subclass of DBIx::SQLEngine which compensates for Oracle's idiosyncrasies.

=head2 About Driver Subclasses

You do not need to use this package directly; when you connect to a database, the SQLEngine object is automatically re-blessed in to the appropriate subclass.

=cut

package DBIx::SQLEngine::Driver::Oracle;

use strict;
use Carp;

########################################################################

########################################################################

=head1 FETCHING DATA (SQL DQL)

=head2 Methods Used By Complex Queries 

=over 4

=item sql_limit()

Adds support for SQL select limit clause.

Implemented as a subselect with ROWNUM.

=back

=cut

sub sql_limit {
  my $self = shift;
  my ( $limit, $offset, $sql, @params ) = @_;

  # remove tablealiases and group-functions from outer query properties
  my ($properties) = ($sql =~ /^\s*SELECT\s(.*?)\sFROM\s/i);
  $properties =~ s/[^\s]+\s+as\s+//ig;
  $properties =~ s/DISTINCT//ig;
  $properties =~ s/\w+\.//g;
  
  $offset ||= 0;
  my $position = ( $offset + $limit );
  
  $sql = "SELECT $properties FROM ( SELECT $properties, ROWNUM AS sqle_position FROM ( $sql ) WHERE ROWNUM <= $position ) WHERE sqle_position > $offset";

  return ($sql, @params);
}

########################################################################

########################################################################

=head1 EDITING DATA (SQL DML)

=head2 Insert to Add Data 

=over 4

=item do_insert_with_sequence()

  $sqldb->do_insert_with_sequence( $sequence_name, %sql_clauses ) : $row_count

Implemented using _seq_do_insert_preinc and seq_increment.

=head2 seq_increment

  $sqldb->seq_increment( $table, $field ) : $new_value

Increments the sequence, and returns the newly allocated value. 

=back

=cut

# $rows = $self->do_insert_with_sequence( $sequence, %clauses );
sub do_insert_with_sequence { 
  (shift)->_seq_do_insert_preinc( @_ )
}

# $current_id = $sqldb->seq_increment( $table, $field );
sub seq_increment {
  my ($self, $table, $field) = @_;
  $self->fetch_one_value(
    sql => "SELECT $field.NEXTVAL FROM DUAL')"
  );
}

########################################################################

########################################################################

=head1 DEFINING STRUCTURES (SQL DDL)

=head2 Detect Tables and Columns

=over 4

=item sql_detect_table()

  $sqldb->sql_detect_table ( $tablename )  : %sql_select_clauses

Implemented using Oracle's "select * from $tablename limit 1".

=back

=cut

sub sql_detect_table {
  my ($self, $tablename) = @_;
  return (
    table => $tablename,
    criteria => '1 = 0',
    limit => 1,
  )
}

########################################################################

=head2 Column Type Methods

The following methods are used by sql_create_table to specify column information in a DBMS-specific fashion.

=over 4

=item dbms_create_column_types()

  $sqldb->dbms_create_column_types () : %column_type_codes

Implemented using Oracle's blob and number types.

I<Portability:> Note that this capability is currently limited, and 
additional steps need to be taken to manually define sequences in Oracle.

=item dbms_create_column_text_long_type()

  $sqldb->dbms_create_column_text_long_type () : $col_type_str

Implemented using Oracle's clob type.

=back

=cut

sub dbms_create_column_types {
  # sequences have to be defined extra manually with Oracle :-|
  'sequential' => 'number not null', 
  'binary' => 'blob',
}

sub dbms_create_column_text_long_type {
  'clob'
}

########################################################################

########################################################################

=head1 ADVANCED CAPABILITIES

=head2 Call, Create and Drop Stored Procedures

Note: this feature has been added recently, and not yet tested in real-world conditions.

=over 4

=item fetch_storedproc()

  $sqldb->fetch_storedproc( $proc_name, @arguments ) : $rows

Not yet supported.

See L<DBD::Oracle/"Binding Cursors"> for more information.

=item do_storedproc()

  $sqldb->do_storedproc( $proc_name, @arguments ) : $row_count

Calls do_sql with "execute procedure", the procedure name, and the arguments using placeholders.

=item create_storedproc()

  $sqldb->create_storedproc( $proc_name, $definition )

Calls do_sql with "create or replace procedure", the procedure name, and the definition.

=item drop_storedproc()

  $sqldb->drop_storedproc( $proc_name )

Calls do_sql with "drop procedure" and the procedure name.

=back

=cut

sub fetch_storedproc  { 
  confess("Oracle fetch_storedproc: Not yet implemented")
}
sub do_storedproc     { 
  (shift)->do_sql(join("\n",
		      "begin" . 
		      (shift) . "(" . join(', ', ('?') x scalar(@_) ) . ")",
		      "end"), @_)
}
sub create_storedproc { 
  (shift)->do_sql(join("\n", 
		    "create or replace procedure $_[0] is begin", @_, "end" ) ) 
}
sub drop_storedproc   { 
  (shift)->do_sql( "drop procedure $_[0]" ) 
}

########################################################################

########################################################################

=head1 INTERNAL CONNECTION METHODS (DBI DBH)

=head2 Checking For Connection

=over 4

=item sql_detect_any()

  $sqldb->sql_detect_any : %sql_select_clauses

Implemented using Oracle's "select 1 from dual".

=back

=cut

sub sql_detect_any {
  return ( sql => 'select 1 from dual' )
}

########################################################################

=head2 Statement Error Handling 

=over 4

=item recoverable_query_exceptions()

  $sqldb->recoverable_query_exceptions() : @common_error_messages

Provides a list of error messages which represent common
communication failures or other incidental errors.

=back

=cut

sub recoverable_query_exceptions {
  'ORA-03111',	# ORA-03111 break received on communication channel
  'ORA-03113',	# ORA-03113 end-of-file on communication channel
  'ORA-03114',	# ORA-03114 not connected to ORACLE
}

########################################################################

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
