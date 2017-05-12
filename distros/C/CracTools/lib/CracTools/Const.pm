package CracTools::Const;
{
  $CracTools::Const::DIST = 'CracTools';
}
# ABSTRACT: Constants for the CracTools-core
$CracTools::Const::VERSION = '1.25';
use strict;
use warnings;
use Exporter qw(import);


our $NOT_AVAILABLE = 'NA';


our $NUCLEOTIDES = ['A', 'C', 'G', 'T' ];


our $CRAC_BINARY = "crac";


our $INDEX_DEFAULT = "/data/indexes/crac/GRCh38";


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CracTools::Const - Constants for the CracTools-core

=head1 VERSION

version 1.25

=head1 SYNOPSIS

  # get a constant variable
  my $NA = $CracTools::Const::NOT_AVAILABLE;

=head1 DESCRIPTION

This module contains some constants that are defined for all the
CracTools pipelines.

=head1 CONSTANTS

=over

=item NOT_AVAILABLE

=item NUCLEOTIDES => [ A, C, G, T ]

=item CRAC_BINARY => "crac'

=item INDEX_DEFAULT => "GRCh38"

=back

=head1 AUTHORS

=over 4

=item *

Nicolas PHILIPPE <nphilippe.research@gmail.com>

=item *

Jérôme AUDOUX <jaudoux@cpan.org>

=item *

Sacha BEAUMEUNIER <sacha.beaumeunier@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by IRMB/INSERM (Institute for Regenerative Medecine and Biotherapy / Institut National de la Santé et de la Recherche Médicale) and AxLR/SATT (Lanquedoc Roussilon / Societe d'Acceleration de Transfert de Technologie).

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
