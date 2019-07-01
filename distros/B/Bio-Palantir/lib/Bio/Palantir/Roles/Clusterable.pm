package Bio::Palantir::Roles::Clusterable;
# ABSTRACT: Clusterable Moose role for Cluster and ClusterPlus objects
$Bio::Palantir::Roles::Clusterable::VERSION = '0.191800';
use Moose::Role;

use autodie;

requires qw(
    modules genes rank type sequence 
       genomic_prot_begin genomic_prot_end genomic_prot_size
       genomic_prot_coordinates genomic_dna_begin genomic_dna_end
       genomic_dna_size genomic_dna_coordinates 
);


no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::Palantir::Roles::Clusterable - Clusterable Moose role for Cluster and ClusterPlus objects

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
