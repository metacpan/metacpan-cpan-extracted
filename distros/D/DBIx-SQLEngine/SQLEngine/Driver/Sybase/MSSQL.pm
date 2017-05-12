=head1 NAME

DBIx::SQLEngine::Driver::Sybase::MSSQL - Support Microsoft SQL via DBD::Sybase

=head1 SYNOPSIS

B<DBI Wrapper>: Adds methods to a DBI database handle.

  my $sqldb = DBIx::SQLEngine->new( 'dbi:Sybase:server=MyServer' );

B<Portability Subclasses:> Uses driver's idioms or emulation.

  $sqldb->select_dbms_flavor('MSSQL');

  $hash_ary = $sqldb->fetch_select( 
    table => 'students' 
    limit => 5, offset => 10
  );

=head1 DESCRIPTION

This package provides a subclass of DBIx::SQLEngine::Driver::Sybase which compensates for configurations in which DBD::Sybase is being used to communicate with a Microsoft SQL Server database.

If you are connecting to a Microsoft SQL Server through ODBC, you should use the regular MSSQL driver; see L<DBIx::SQLEngine::Driver::MSSQL>

For more information, see L<DBD::Sybase/"Using DBD::Sybase with MS-SQL">.

=head2 Under Development

Note that this driver class has been added recently and not yet tested in real-world conditions.

=head2 About DBMS Flavors

This subclass of the Sybase driver must be specifically triggered, because the package is unable to automatically detect the difference between using DBD::Sybase with a Sybase server and using it with a Microsoft server.

To do this, call select_dbms_flavor after connecting:

  my $sqldb = DBIx::SQLEngine->new( 'dbi:Sybase:server=MyServer' );
  
  $sqldb->select_dbms_flavor('MSSQL');

For more information, see the documentation for the superclass, L<DBIx::SQLEngine::Driver::Sybase>.

=cut

########################################################################

package DBIx::SQLEngine::Driver::Sybase::MSSQL;

@ISA = qw( DBIx::SQLEngine::Driver::Sybase );

use strict;
use Carp;

########################################################################

########################################################################

=head1 INTERNAL STATEMENT METHODS (DBI STH)

=head2 No Placeholders

When using DBD::Sybase to talk to a Microsoft SQL Server, "?"-style placeholders are not supported.

Uses the NoPlaceholders trait. For more information, see L<DBIx::SQLEngine::Driver::Trait::NoPlaceholders>.

=cut

use DBIx::SQLEngine::Driver::Trait::NoPlaceholders qw( :all !prepare_execute );

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
  my $sth = $self->
	DBIx::SQLEngine::Driver::Trait::NoPlaceholders::prepare_execute( @_ );
  $sth->{LongReadLen} = $self->dbms_longreadlen_bufsize;
  $sth->{LongTruncOk} = 0;
  $sth;
}

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
