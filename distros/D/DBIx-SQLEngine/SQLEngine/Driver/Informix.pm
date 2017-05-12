=head1 NAME

DBIx::SQLEngine::Driver::Informix - Support DBD::Informix and DBD::ODBC/Informix

=head1 SYNOPSIS

B<DBI Wrapper>: Adds methods to a DBI database handle.

  my $sqldb = DBIx::SQLEngine->new( 'dbi:Informix:test_data@my_server' );

B<Portability Subclasses:> Uses driver's idioms or emulation.

  $sqldb->do_insert(                          # use SERIAL column
    table => 'students', sequence => 'id',        
    values => { 'name'=>'Dave', 'age'=>'19', 'status'=>'minor' },
  );


=head1 DESCRIPTION

This package provides a subclass of DBIx::SQLEngine which compensates for Informix's idiosyncrasies.

=head2 About Driver Subclasses

You do not need to use this package directly; when you connect to a database, the SQLEngine object is automatically re-blessed in to the appropriate subclass.

For more information about the underlying driver class, see L<DBD::Informix>.

=head2 Under Development

Note that this driver class has been added recently and not yet tested in real-world conditions.

To Do: Add missing functionality from related CPAN modules. See L<DBD::Informix::Summary>, L<DBIx::SearchBuilder::Handle::Informix> and maybe L<Dimedis::SqlDriver::Informix>.

=cut

########################################################################

package DBIx::SQLEngine::Driver::Informix;

use strict;
use Carp;

########################################################################

########################################################################

=head1 FETCHING DATA (SQL DQL)

=head2 Methods Used By Complex Queries 

=over 4

=item sql_limit()

Not yet supported. Perhaps we should use "first $maxrows" and throw out the first $offset?

=back

=cut

sub sql_limit {
  confess("Not yet supported")
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

Implemented using DBD::Informix's ix_sqlerrd attribute. 

Note that this doesn't fetch the current sequence value for a given
table, since it doesn't respect the table and field arguments, but
merely returns the last sequencial value created during this session.

=back

=cut

# $rows = $self->do_insert_with_sequence( $sequence, %clauses );
sub do_insert_with_sequence {
  (shift)->_seq_do_insert_postfetch( @_ )
}

# $current_id = $sqldb->seq_fetch_current( );
sub seq_fetch_current {
  my $self = shift;
  
  $self->get_dbh->{ix_sqlerrd}[1]
}

########################################################################

########################################################################

=head1 DEFINING STRUCTURES (SQL DDL)

=head2 Column Type Methods

=over 4

=item dbms_create_column_types()

  $sqldb->dbms_create_column_types () : %column_type_codes

Implemented using Informix's byte and SERIAL types.

=item dbms_create_column_text_long_type()

  $sqldb->dbms_create_column_text_long_type () : $col_type_str

Implemented using Informix's text type.

=back

=cut

sub dbms_create_column_types {
  'sequential' => 'SERIAL', 
  'binary' => 'byte',
}

sub dbms_create_column_text_long_type {
  'text'
}

########################################################################

########################################################################

=head1 ADVANCED CAPABILITIES

=head2 Call, Create and Drop Stored Procedures

=over 4

=item fetch_storedproc()

  $sqldb->fetch_storedproc( $proc_name, @arguments ) : $rows

Calls fetch_sql with "execute procedure", the procedure name, and the arguments using placeholders.

=item do_storedproc()

  $sqldb->do_storedproc( $proc_name, @arguments ) : $row_count

Calls do_sql with "execute procedure", the procedure name, and the arguments using placeholders.

=item create_storedproc()

  $sqldb->create_storedproc( $proc_name, $definition )

Calls do_sql with "create procedure", the procedure name, and the definition.

=item drop_storedproc()

  $sqldb->drop_storedproc( $proc_name )

Calls do_sql with "drop procedure" and the procedure name.

=back

=cut

sub fetch_storedproc  { 
  (shift)->fetch_sql( "execute procedure " . (shift) . 
		      "(" . join(', ', ('?') x scalar(@_) ) . ")", @_)
}
sub do_storedproc     { 
  (shift)->do_sql(    "execute procedure " . (shift) . 
		      "(" . join(', ', ('?') x scalar(@_) ) . ")", @_)
}
sub create_storedproc { 
  (shift)->do_sql( "create procedure $_[0] " . join("\n", @_ ) ) 
}
sub drop_storedproc   { 
  (shift)->do_sql( "drop procedure $_[0]" ) 
}

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
