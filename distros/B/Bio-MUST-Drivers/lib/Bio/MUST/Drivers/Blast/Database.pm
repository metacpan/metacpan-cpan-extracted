package Bio::MUST::Drivers::Blast::Database;
# ABSTRACT: Internal class for BLAST driver
$Bio::MUST::Drivers::Blast::Database::VERSION = '0.242720';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Carp;

extends 'Bio::FastParsers::Base';


has 'type' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    writer   => '_set_type',
);

has 'remote' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
);

with 'Bio::MUST::Drivers::Roles::Blastable';

# http://ncbiinsights.ncbi.nlm.nih.gov/2013/03/19/blastdbinfo-api-access-to-a-database-of-blast-databases/
# updated with ChatGPT in Sept 2024
my %type_for = (
    core_nt        => 'nucl',   # Core nucleotide database (streamlined version of nt)
    nt             => 'nucl',   # Non-redundant nucleotide sequences
    refseq_rna     => 'nucl',   # RefSeq RNA sequences
    refseq_genomic => 'nucl',   # RefSeq genomic sequences
    pdbnt          => 'nucl',   # Nucleotide sequences from the Protein Data Bank (PDB)
    env_nt         => 'nucl',   # Non-redundant environmental nucleotide sequences
    '16SMicrobial' => 'nucl',   # 16S ribosomal RNA sequences (bacteria and archaea)
    pat            => 'nucl',   # Nucleotide sequences from patents
    tsa_nr         => 'nucl',   # Transcriptome Shotgun Assembly nucleotide sequences
    wgs            => 'nucl',   # Whole Genome Shotgun contigs
    est            => 'nucl',   # Expressed Sequence Tags
    metagenomes    => 'nucl',   # Metagenomic nucleotide sequences
    sra            => 'nucl',   # Sequence Read Archive
    swissprot      => 'prot',   # Swiss-Prot manually curated protein sequences
    nr             => 'prot',   # Non-redundant protein sequences
    refseq_protein => 'prot',   # RefSeq protein sequences
    refseq_select  => 'prot',   # Streamlined RefSeq, one representative transcript per gene
    pdbaa          => 'prot',   # Protein sequences from the PDB
    env_nr         => 'prot',   # Non-redundant environmental protein sequences
    pataa          => 'prot',   # Protein sequences from patents
);

sub BUILD {
    my $self = shift;

    my $basename = $self->filename;

    # check for existence of BLAST database and set its type (nucl or prot)
    if ($self->remote) {
        $self->_set_type( $type_for{$basename} );
    }
    elsif (-e "$basename.psq" || -e "$basename.pal") {
        $self->_set_type('prot');
    }
    elsif (-e "$basename.nsq" || -e "$basename.nal") {
        $self->_set_type('nucl');
    }
    else {
        croak "[BMD] Error: BLAST database not found at $basename; aborting!";
    }

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Blast::Database - Internal class for BLAST driver

=head1 VERSION

version 0.242720

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
