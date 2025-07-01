#!/usr/bin/env perl
# PODNAME: mask-ali.pl
# ABSTRACT: Mask an ALI file according to BLOCKS file(s)

use Modern::Perl '2011';
use autodie;

use File::Basename;
use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(insert_suffix);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::SeqMask';


### Sequences taken from: $ARGV_alifile
my $ali = Ali->load($ARGV_alifile);

for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $mask = SeqMask->load_blocks($infile);
    my $masked = $mask->filtered_ali($ali);

    # create suffix named after filename
    my ($filename) = fileparse($infile, qr{\.[^.]*}xms);
    my $outfile = insert_suffix($ARGV_alifile, "-$filename");
    ### Output alignment in: $outfile
    $masked->store($outfile);
}

__END__

=pod

=head1 NAME

mask-ali.pl - Mask an ALI file according to BLOCKS file(s)

=head1 VERSION

version 0.251810

=head1 USAGE

    mask-ali.pl <infiles> --alifile=<file> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input BLOCKS files [repeatable argument].

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
