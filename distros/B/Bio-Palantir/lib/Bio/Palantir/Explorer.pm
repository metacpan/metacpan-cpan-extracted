package Bio::Palantir::Explorer;
# ABSTRACT: front-end class for Bio::Palantir::Explorer module, wich handles the NRPS/PKS domain exploration without pre-existing consensus architecture
$Bio::Palantir::Explorer::VERSION = '0.191800';
use warnings;
use strict;

use Bio::Palantir::Explorer::ClusterFasta;


1;

__END__

=pod

=head1 NAME

Bio::Palantir::Explorer - front-end class for Bio::Palantir::Explorer module, wich handles the NRPS/PKS domain exploration without pre-existing consensus architecture

=head1 VERSION

version 0.191800

=head1 DESCRIPTION

This module implements classes and their methods for B<exploring NRPS/PKS domain
architecture> without any previous consensus imposed. Note that this application
mode is only based on the expertise of the user. The input used by
C<Palantir::Refiner> is the B<FASTA file> of a NRPS/PKS BGC (e.g.,
F<nrps_bgc.fasta>), which can be extracted from B<antiSMASH HTML webpages> or
with the script C<bin/extract_fasta.pl> (which uses C<Palantir::Parser>).

The exploratory B<Biosynthetic Gene Cluster (BGC) information> is hierarchically
organized as follows:

C<ClusterFasta.pm>: contains attributes and methods for the BGC B<Cluster>
level, including an array of GeneFasta objects 

C<GeneFasta.pm>:    contains attributes and methods for the BGC B<Gene> level,
including an array of DomainPlus objects (if NRPS/PKS BGCs)

C<DomainPlus.pm>:   contains attributes and methods for the BGC B<Domain> level

The B<Domain> information is inherited from C<Palantir::Refiner::DomainPlus>,
and as no consensus architecture is defined, B<Module> information is not
applicable.

=head1 AUTHOR

Loic MEUNIER <lmeunier@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by University of Liege / Unit of Eukaryotic Phylogenomics / Loic MEUNIER and Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
