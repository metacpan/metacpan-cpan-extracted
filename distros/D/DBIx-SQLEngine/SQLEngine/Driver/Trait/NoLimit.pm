=head1 NAME

DBIx::SQLEngine::Driver::Trait::NoLimit - For databases without select limit

=head1 SYNOPSIS

  # Classes can import this behavior if they don't have limit
  use DBIx::SQLEngine::Driver::Trait::NoLimit ':all';
  
=head1 DESCRIPTION

This package works with DBD drivers which are implemented in Perl using SQL::Statement. It combines several other traits and methods which can be shared by most such drivers.

=head2 About Driver Traits

You do not need to use this package directly; it is used internally by those driver subclasses which need it. 

For more information about Driver Traits, see L<DBIx::SQLEngine::Driver/"About Driver Traits">.

=cut

########################################################################

package DBIx::SQLEngine::Driver::Trait::NoLimit;

use strict;
use Carp;
use vars qw( @EXPORT_OK %EXPORT_TAGS );

########################################################################

use Exporter;
sub import { goto &Exporter::import } 
@EXPORT_OK = ( 
  qw( 
    sql_limit
  ),
);
%EXPORT_TAGS = ( all => \@EXPORT_OK );

########################################################################

=head1 REFERENCE

The following methods are provided:

=cut

########################################################################

=head2 Select to Retrieve Data

=over 4

=item sql_limit

  $sqldb->sql_limit( $limit, $offset, $sql, @params ) : $sql, @params

Not supported.

=back

=cut

sub sql_limit {
  my $self = shift;
  my ( $limit, $offset, $sql, @params ) = @_;
    
  return ($sql, @params);
}

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

See L<DBIx::Sequence> for another version of the sequence-table functionality, which greatly inspired this module.

=cut

########################################################################

1;

