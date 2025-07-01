#!/usr/bin/env perl
# PODNAME: fasta2ali.pl
# ABSTRACT: Convert FASTA files to ALI files

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix);
use aliased 'Bio::MUST::Core::Ali';


for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $ali = Ali->load($infile);
    $ali->dont_guess if $ARGV_noguessing;
    $ali->degap_seqs if $ARGV_degap;
    my $outfile = change_suffix($infile, '.ali');
    $ali->store($outfile);
}

__END__

=pod

=head1 NAME

fasta2ali.pl - Convert FASTA files to ALI files

=head1 VERSION

version 0.251810

=head1 USAGE

    fasta2ali.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input FASTA files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --degap

Discard gaps when converting sequences [default: no].

=item --[no]guessing

[Don't] guess whether sequences are aligned or not [default: yes].

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
