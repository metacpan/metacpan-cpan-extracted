#!/usr/bin/env perl
# PODNAME: map-gis-ali.pl
# ABSTRACT: Build a GI-to-taxid id mapper from GI numbers in ALI files
# CONTRIBUTOR: Loic MEUNIER <loic.meunier@doct.uliege.be>

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use List::AllUtils qw(uniq);
use Smart::Comments '###';

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::Taxonomy';


# build taxonomy object
my $tax = Taxonomy->new_from_cache( tax_dir => $ARGV_taxdir );

# setup cumulative full_ids list
my @full_ids;

for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $ali = Bio::MUST::Core::Ali->load($infile);
    push @full_ids, map { $_->full_id } $ali->all_seq_ids;
}

# build and store mapper from non-redundant full_id list
my $list = IdList->new( ids => [ uniq @full_ids ] );
my $mapper = $tax->gi_mapper($list);
$mapper->store($ARGV_idm_out);

__END__

=pod

=head1 NAME

map-gis-ali.pl - Build a GI-to-taxid id mapper from GI numbers in ALI files

=head1 VERSION

version 0.202070

=head1 USAGE

	map-gis-ali.pl --tax=<dir> --idm-out=<out> <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input ALI files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=item --taxdir=<dir>

Path to local mirror of the NCBI Taxonomy database.

=for Euclid: dir.type: string

=item --idm-out=<file>

Path to consolidated GI-to-taxid IDM outfile.

=back

=head1 OPTIONS

=over

=item --save-mem[ory]

Save computer memory by using GI-to-taxid mapper directly from disk [default:
no]. This option only applies when using C<gi> items.

Not loading the mapper into memory spares 2 GB of system memory but results in
GI mapping being (about 20%) slower. On a MacBook Air (8 GB), loading the
whole mapper into memory actually fails.

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Loic MEUNIER

Loic MEUNIER <loic.meunier@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
