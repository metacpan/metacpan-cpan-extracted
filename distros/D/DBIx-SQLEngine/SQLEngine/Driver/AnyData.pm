=head1 NAME

DBIx::SQLEngine::Driver::AnyData - Support DBD::AnyData driver

=head1 SYNOPSIS

B<DBI Wrapper>: Adds methods to a DBI database handle.

  my $sqldb = DBIx::SQLEngine->new( 'dbi:AnyData:test' );
  
B<Portability Subclasses:> Uses driver's idioms or emulation.
  
  $hash_ary = $sqldb->fetch_select( 
    table => 'students' 
    limit => 5, offset => 10
  );

=head1 DESCRIPTION

This package provides a subclass of DBIx::SQLEngine which compensates for DBD::AnyData's idiosyncrasies.

=head2 About Driver Subclasses

You do not need to use this package directly; when you connect to a database, the SQLEngine object is automatically re-blessed in to the appropriate subclass.

=cut

########################################################################

package DBIx::SQLEngine::Driver::AnyData;

use strict;
use Carp;

########################################################################

use DBIx::SQLEngine::Driver::Trait::PerlDBLib ':all';

########################################################################

=head2 sql_detect_table

  $sqldb->sql_detect_table ( $tablename )  : %sql_select_clauses

Implemented using AnyData's "select * from $tablename limit 1".

=cut

sub sql_detect_table {
  my ($self, $tablename) = @_;
  return ( table => $tablename, limit => 1 )
}

########################################################################

=head2 ad_catalog

  $ds->ad_catalog( $table_name, $any_data_format, $file_name );

Uses AnyData's 'ad_catalog' function to map in a new data file.

=cut

# $ds->ad_catalog('TableName', 'AnyDataFormat', 'FileName');
sub ad_catalog { 
  (shift)->func( @_, 'ad_catalog' );
}

########################################################################

=head2 recoverable_query_exceptions

  $sqldb->recoverable_query_exceptions() : @common_error_messages

Provides a list of error messages which represent common
communication failures or other incidental errors.

=cut

sub recoverable_query_exceptions {
  'resource',
}

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
