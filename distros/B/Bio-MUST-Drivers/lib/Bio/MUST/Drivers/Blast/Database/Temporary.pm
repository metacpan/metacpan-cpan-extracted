package Bio::MUST::Drivers::Blast::Database::Temporary;
# ABSTRACT: Internal class for BLAST driver
$Bio::MUST::Drivers::Blast::Database::Temporary::VERSION = '0.242720';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments '###';

use Carp;
use IPC::System::Simple qw(system);
use Module::Runtime qw(use_module);
use Path::Class qw(file);

extends 'Bio::MUST::Core::Ali::Temporary';

with 'Bio::MUST::Drivers::Roles::Blastable';


# overload equivalent attribute in plain Database
sub remote {
    return 0;
}

sub BUILD {
    my $self = shift;

    # provision executable
    my $app = use_module('Bio::MUST::Provision::Blast')->new;
       $app->meet();

    my $in = $self->filename;
    my $dbtype = $self->type;

    # create makeblastdb command
    # -parse_seqids now required for blastdbcmd to work (side effects?)
    my $pgm = file($ENV{BMD_BLAST_BINDIR}, 'makeblastdb');
    my $cmd = "$pgm -in $in -dbtype $dbtype -parse_seqids"
        . ' > /dev/null 2> /dev/null';
    #### $cmd

    # try to robustly execute makeblastdb
    my $ret_code = system( [ 0, 127 ], $cmd);
    if ($ret_code == 127) {
        # TODO: do something to abort construction
        carp "[BMD] Warning: cannot execute $pgm command; returning!";
        return;
    }

    return;
}

sub DEMOLISH {
    my $self = shift;

    # updated with ChatGPT in Sept 2024
    # The following is valid for BLAST 2.16.0:
    # Core Nucleotide Database Files:
    # - .ndb – Nucleotide database file: Contains the actual nucleotide sequences.
    # - .nhr – Nucleotide header file: Stores sequence descriptions and identifiers (like the protein .phr file).
    # - .nin – Nucleotide index file: Contains indexing information for fast lookup (analogous to the .pin file for proteins).
    # - .nsq – Nucleotide sequence file: Holds the nucleotide sequences in a compact format for efficient searching (similar to the .psq file for proteins).
    # Partitioning and Multi-threading Support Files (Nucleotide Version):
    # - .nog – Group partition index file: Manages partitioned groups of nucleotide sequences.
    # - .not – Partition offset table: Contains offsets for different partitions within the nucleotide database.
    # - .ntf – Partition table file: The reference table for nucleotide database partitions.
    # - .nto – Partition offset file: Holds the positions of nucleotide partitions.
    # Metadata and Optimization Files:
    # - .njs – Nucleotide JSON schema file: Similar to the .pjs file in protein databases, it contains metadata in JSON format about the nucleotide database.
    # - .nos – Nucleotide offset file: Similar to .pos, it stores sequence offsets for optimized retrieval.

    # unlink temp files
    my @suffices = map { ( $self->type eq 'prot' ? 'p' : 'n' ) . $_ }
        qw(db hr in sq og ot tf to js os);
    my $basename = $self->filename;
    #### $basename
    file($_)->remove for map { "$basename.$_" } @suffices;

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Blast::Database::Temporary - Internal class for BLAST driver

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
