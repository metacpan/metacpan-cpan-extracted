package Bio::Palantir::Roles::Geneable;
# ABSTRACT: Geneable Moose role for Gene and GenePlus objects
$Bio::Palantir::Roles::Geneable::VERSION = '0.191800';
use Moose::Role;

use autodie;

requires qw(
    domains rank name genomic_dna_begin 
    genomic_dna_end genomic_dna_coordinates
    genomic_dna_size genomic_prot_begin 
    genomic_prot_end genomic_prot_coordinates 
    genomic_prot_size protein_sequence 
);


no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::Palantir::Roles::Geneable - Geneable Moose role for Gene and GenePlus objects

=head1 VERSION

version 0.191800

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Loic MEUNIER <lmeunier@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by University of Liege / Unit of Eukaryotic Phylogenomics / Loic MEUNIER and Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
