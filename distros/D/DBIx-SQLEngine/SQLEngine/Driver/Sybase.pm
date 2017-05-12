=head1 NAME

DBIx::SQLEngine::Driver::Sybase - Extends SQLEngine for DBMS Idiosyncrasies

=head1 SYNOPSIS

B<DBI Wrapper>: Adds methods to a DBI database handle.

  my $sqldb = DBIx::SQLEngine->new( 'dbi:Sybase:server=MyServer' );

B<Portability Subclasses:> Uses driver's idioms or emulation.

  $sqldb->do_insert(                          # use identity column
    table => 'students', sequence => 'id',        
    values => { 'name'=>'Dave', 'age'=>'19', 'status'=>'minor' },
  );


=head1 DESCRIPTION

This package provides a subclass of DBIx::SQLEngine which compensates for Sybase's idiosyncrasies.

=head2 Under Development

Note: this driver class has been added recently and not yet tested in real-world conditions.

The SQLEngine framework doesn't yet have a strategy or interface for dealing with one of  the limitations of DBD::Sybase: each connection can only have one statement handle active. If AutoCommit is on, then it silently opens up another database handle for each additional statement handle. However, transactions can't span connections, so if AutoCommit is off, it dies with this message: C<DBD::Sybase: Can't have multiple statement handles on a single database handle when AutoCommit is OFF>.

=head2 About Driver Subclasses

You do not need to use this package directly; when you connect to a database, the SQLEngine object is automatically re-blessed in to the appropriate subclass.

For more information about the underlying driver class, see L<DBD::Sybase>.

=cut

########################################################################

package DBIx::SQLEngine::Driver::Sybase;

use strict;
use Carp;

########################################################################

=head2 About DBMS Flavors

This driver uses the DatabaseFlavors trait. For more information, see L<DBIx::SQLEngine::Driver::Trait::DatabaseFlavors>.

It does this in order to support use of DBD::Sybase with Microsoft SQL Server. For more information, see L< DBIx::SQLEngine::Driver::Sybase::MySQL>.

=cut

use DBIx::SQLEngine::Driver::Trait::DatabaseFlavors ':all';

########################################################################

########################################################################

=head1 FETCHING DATA (SQL DQL)

=head2 Methods Used By Complex Queries 

=over 4

=item sql_limit()

Not yet supported. 

See http://www.isug.com/Sybase_FAQ/ASE/section6.2.html#6.2.12

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

Implemented using Sybase's "select @@IDENTITY". 

Note that this doesn't fetch the current sequence value for a given
table, since it doesn't respect the table and field arguments, but
merely returns the last sequencial value created during this session.

For more information see http://www.isug.com/Sybase_FAQ/ASE/section6.2.html#6.2.9

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

=head2 Column Type Methods

=over 4

=item dbms_create_column_types()

  $sqldb->dbms_create_column_types () : %column_type_codes

Implemented using Sybase's blob and identity types.

=item dbms_create_column_text_long_type()

  $sqldb->dbms_create_column_text_long_type () : $col_type_str

Implemented using Sybase's blob type.

=back

=cut

sub dbms_create_column_types {
  'sequential' => 'numeric(5,0) identity', 
  'binary' => 'blob',
}

sub dbms_create_column_text_long_type {
  'blob'
}

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
