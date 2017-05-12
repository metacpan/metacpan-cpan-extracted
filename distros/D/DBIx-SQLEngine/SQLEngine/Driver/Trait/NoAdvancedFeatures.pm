=head1 NAME

DBIx::SQLEngine::Driver::Trait::NoAdvancedFeatures - For Very Simple Databases

=head1 SYNOPSIS

  # Classes can import this behavior if they don't have many features
  use DBIx::SQLEngine::Driver::Trait::NoAdvancedFeatures ':all';

=head1 DESCRIPTION

This package supports SQL database servers which do natively provide any advanced capabilities, like transactions, indexes, or stored procedures. 

=head2 About Driver Traits

You do not need to use this package directly; it is used internally by those driver subclasses which need it. 

For more information about Driver Traits, see L<DBIx::SQLEngine::Driver/"About Driver Traits">.

=cut

########################################################################

package DBIx::SQLEngine::Driver::Trait::NoAdvancedFeatures;

use Exporter;
sub import { goto &Exporter::import } 
@EXPORT_OK = qw( 
  dbms_transactions_unsupported 
  dbms_indexes_unsupported 
  dbms_storedprocs_unsupported
);
%EXPORT_TAGS = ( all => \@EXPORT_OK );

use strict;
use Carp;

########################################################################

=head1 ADVANCED CAPABILITIES

=cut

########################################################################

=head2 Database Capability Information

The following methods are provided:

=over 4

=item dbms_transactions_unsupported()

  $sqldb->dbms_transactions_unsupported() : 1

Capability Limitation: This driver does not support transactions.

=item dbms_indexes_unsupported()

  $sqldb->dbms_indexes_unsupported() : 1

Capability Limitation: This driver does not support indexes.

=item dbms_storedprocs_unsupported()

  $sqldb->dbms_storedprocs_unsupported() : 1

Capability Limitation: This driver does not support stored procedures.

=back

=cut

sub dbms_transactions_unsupported    { 1 }

sub dbms_indexes_unsupported         { 1 }

sub dbms_storedprocs_unsupported     { 1 }

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;

