=head1 NAME

DBIx::SQLEngine::Driver::XBase - Support DBD::XBase driver

=head1 SYNOPSIS

B<DBI Wrapper>: Adds methods to a DBI database handle.

  my $sqldb = DBIx::SQLEngine->new( 'dbi:XBase:my_data_path' );
  
B<Portability Subclasses:> Uses driver's idioms or emulation.
  
  $hash_ary = $sqldb->fetch_select( 
    table => 'students',
    where => { name => 'Dave' },
  );

=head1 DESCRIPTION

This package provides a subclass of DBIx::SQLEngine which compensates for
some of DBD::XBase's idiosyncrasies.

Note that DBD::XBase does not support the normal full range of SQL DBMS
functionality. Consult the documentation to understand its current limits.

=head2 About Driver Subclasses

You do not need to use this package directly; when you connect to a database, the SQLEngine object is automatically re-blessed in to the appropriate subclass.

=cut

########################################################################

package DBIx::SQLEngine::Driver::XBase;

use strict;
use Carp;

########################################################################

use DBIx::SQLEngine::Driver::Trait::PerlDBLib qw( :all !sql_limit );

use DBIx::SQLEngine::Driver::Trait::NoJoins ':all';

use DBIx::SQLEngine::Driver::Trait::NoLimit ':all';

sub _init {
  (shift)->get_dbh()->{FetchHashKeyName} = 'NAME_lc';
}

########################################################################

=head2 sql_detect_table

  $sqldb->sql_detect_table ( $tablename )  : %sql_select_clauses

Implemented using DBD::XBase's "select * from $tablename where 1 = 0".

=cut

sub sql_detect_table {
  my ($self, $tablename) = @_;
  return ( table => $tablename )
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
