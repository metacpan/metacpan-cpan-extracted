=head1 NAME

DBIx::SQLEngine::Driver::CSV - Support DBD::CSV driver

=head1 SYNOPSIS

B<DBI Wrapper>: Adds methods to a DBI database handle.

  my $sqldb = DBIx::SQLEngine->new( 'dbi:CSV:f_dir=my_data_path' );
  
B<Portability Subclasses:> Uses driver's idioms or emulation.
  
  $hash_ary = $sqldb->fetch_select( 
    table => 'students' 
    limit => 5, offset => 10
  );

=head1 DESCRIPTION

This package provides a subclass of DBIx::SQLEngine which compensates for
some of DBD::CSV's idiosyncrasies.

Note that DBD::CSV does not support the normal full range of SQL DBMS
functionality. Upgrade to the latest versions of DBI and SQL::Statement and
consult their documentation to understand their current limits.

=head2 About Driver Subclasses

You do not need to use this package directly; when you connect to a database, the SQLEngine object is automatically re-blessed in to the appropriate subclass.

=cut

########################################################################

package DBIx::SQLEngine::Driver::CSV;

use strict;
use Carp;

########################################################################

use DBIx::SQLEngine::Driver::Trait::PerlDBLib qw( :all !sql_seq_increment );

use DBIx::SQLEngine::Driver::Trait::NoJoins ':all';

########################################################################

=head2 sql_seq_increment

Overrides behavior of DBIx::SQLEngine::Driver::Trait::NoSequences.

=cut

# $sql, @params = $sqldb->sql_seq_increment( $table, $field, $current, $next );
sub sql_seq_increment {
  my ($self, $table, $field, $current, $next) = @_;
  my $seq_table = $self->seq_table_name;
  $self->sql_update(
    table => $seq_table,
    values => { seq_value => $next },
    criteria => ['seq_name = ?', "$table.$field"]
  );
}

########################################################################

=head2 sql_detect_table

  $sqldb->sql_detect_table ( $tablename )  : %sql_select_clauses

Implemented using DBD::CSV's "select * from $tablename where 1 = 0".

=cut

sub sql_detect_table {
  my ($self, $tablename) = @_;
  return ( table => $tablename, criteria => '1 = 0' )
}

########################################################################

=head2 dbms_null_becomes_emptystring

  $sqldb->dbms_null_becomes_emptystring () : 1

Capability Limitation: This driver does not store real null or undefined values, converting them instead to empty strings.

=cut

sub dbms_null_becomes_emptystring    { 1 }

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
