=head1 NAME

DBIx::SQLEngine::Driver::Trait::NoJoins - For databases without join ability

=head1 SYNOPSIS

  # Classes can import this behavior if they can't join
  use DBIx::SQLEngine::Driver::Trait::NoJoins ':all';
  
=head1 DESCRIPTION

This package works with DBD drivers which lack the basic ability to join tables.

=head2 About Driver Traits

You do not need to use this package directly; it is used internally by those driver subclasses which need it. 

For more information about Driver Traits, see L<DBIx::SQLEngine::Driver/"About Driver Traits">.

=cut

########################################################################

package DBIx::SQLEngine::Driver::Trait::NoJoins;

use strict;
use Carp;
use vars qw( @EXPORT_OK %EXPORT_TAGS );

########################################################################

use Exporter;
sub import { goto &Exporter::import } 
@EXPORT_OK = ( 
  qw( 
    sql_join
    dbms_joins_unsupported
    dbms_join_on_unsupported 
    dbms_outer_join_unsupported
  ),
);
%EXPORT_TAGS = ( all => \@EXPORT_OK );

########################################################################

=head1 REFERENCE

The following methods are provided:

=head2 Select to Retrieve Data

=over 4

=item sql_join()

Dies with an "Unsupported" message.

=back

=cut

sub sql_join { die "Unsupported" }

########################################################################

=head2 Database Capability Information

=over 4

=item dbms_joins_unsupported

  $sqldb->dbms_joins_unsupported () : 1

Capability Limitation: This driver does not support joins.

=item dbms_join_on_unsupported

  $sqldb->dbms_join_on_unsupported() : 1

Capability Limitation: This driver does not support the "join ... on ..." syntax.

=item dbms_outer_join_unsupported

  $sqldb->dbms_outer_join_unsupported() : 1

Capability Limitation: This driver does not support any type of outer joins.

=back

=cut

sub dbms_joins_unsupported      { 1 }
sub dbms_join_on_unsupported    { 1 }
sub dbms_outer_join_unsupported { 1 }

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

See L<DBIx::Sequence> for another version of the sequence-table functionality, which greatly inspired this module.

=cut

########################################################################

1;

