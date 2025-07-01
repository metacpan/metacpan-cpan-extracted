#!/usr/bin/env perl
# PODNAME: phylip2ali.pl
# ABSTRACT: Convert PHYLIP files to ALI files

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::IdMapper';


for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $ali = Ali->load_phylip($infile);

    if ($ARGV_map_ids) {
        my $idmfile = change_suffix($infile, '.idm');
        my $idm = IdMapper->load($idmfile);
        ### Restoring seq ids from: $idmfile
        $ali->restore_ids($idm);
    }

    my $outfile = change_suffix($infile, '.ali');
    $ali->store($outfile);
}

__END__

=pod

=head1 NAME

phylip2ali.pl - Convert PHYLIP files to ALI files

=head1 VERSION

version 0.251810

=head1 USAGE

    phylip2ali.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input PHYLIP files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --map-ids

Sequence id mapping switch [default: no]. When specified, sequence ids are
restored from the corresponding IDM files.

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
