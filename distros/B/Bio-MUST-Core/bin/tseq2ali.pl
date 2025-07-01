#!/usr/bin/env perl
# PODNAME: tseq2ali.pl
# ABSTRACT: Convert NCBI TinySeq XML files to ALI files

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix);
use aliased 'Bio::MUST::Core::Ali';


for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $ali = Ali->load_tinyseq($infile, { keep_strain => $ARGV_keep_strain } );
    my $outfile = change_suffix( change_suffix( $infile, q{} ), '.ali' );
    $ali->store($outfile);              # original suffix is .fasta.xml
}

__END__

=pod

=head1 NAME

tseq2ali.pl - Convert NCBI TinySeq XML files to ALI files

=head1 VERSION

version 0.251810

=head1 USAGE

    tseq2ali.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input TINYSEQ files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --keep-strain

Include the NCBI strain in the generated mustid [default: no]. The original
strain is slightly transformed and stripped of its non-alphanumeric characters
for maximal compatibility with other software.

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
