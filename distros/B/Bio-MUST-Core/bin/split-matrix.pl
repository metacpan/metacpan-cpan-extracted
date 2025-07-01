#!/usr/bin/env perl
# PODNAME: split-matrix.pl
# ABSTRACT: Extract individual gene ALIs from a SCaFoS supermatrix

use Modern::Perl '2011';
use autodie;

use File::Basename;
use Getopt::Euclid qw(:vars);
use Path::Class qw(dir file);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:files);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::SeqMask';


### Gene ALIs extracted from: $ARGV_alifile
my $ali = Ali->load($ARGV_alifile);
   $ali->gapify_seqs;

for my $infile (@ARGV_infiles) {

    ### Processing: $infile

    # create directory named after filename
    my ($filename) = fileparse($infile, qr{\.[^.]*}xms);
    my $dir = dir($filename)->relative;
    $dir->mkpath();

    open my $in, '<', $infile;

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # skip empty lines and other comment lines
        next LINE if $line =~ $EMPTY_LINE
                  || $line =~ $COMMENT_LINE;

        # build mask from gene coordinates
        my ($gene, $begin, $end) = split /\t+/xms, $line;
        my $mask = SeqMask->blocks2mask( [ [ $begin, $end ] ] );

        # extract gene and filter empty seqs
        my $masked = $mask->filtered_ali($ali);
        my @seqs = $masked->filter_seqs( sub { $_->nomiss_seq_len > 1 } );
        my $gene_ali = Ali->new( seqs => \@seqs );

        ### Output gene ALI in: $gene
        my $outfile = file($dir, $gene);
        $gene_ali->store($outfile);
    }
}

__END__

=pod

=head1 NAME

split-matrix.pl - Extract individual gene ALIs from a SCaFoS supermatrix

=head1 VERSION

version 0.251810

=head1 USAGE

    split-matrix.pl <infiles> --alifile=<file> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input SCaFoS LEN files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=item --alifile=<file>

Path to the ALI file containing the sequence alignment.

=for Euclid: file.type: readable

=back

=head1 OPTIONAL ARGUMENTS

=over

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
