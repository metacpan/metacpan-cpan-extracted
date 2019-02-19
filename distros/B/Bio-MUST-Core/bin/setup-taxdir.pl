#!/usr/bin/env perl
# PODNAME: setup-taxdir.pl
# ABSTRACT: Setup a local mirror of the NCBI Taxonomy database

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::Taxonomy';


unless ($ARGV_update_cache) {
    my %args;
    $args{gi_mapper} = 1 if $ARGV_gi_mapper;
    Taxonomy->setup_taxdir($ARGV_taxdir, \%args);
}

my $tax = Taxonomy->new( tax_dir => $ARGV_taxdir );
$tax->update_cache;

__END__

=pod

=head1 NAME

setup-taxdir.pl - Setup a local mirror of the NCBI Taxonomy database

=head1 VERSION

version 0.190500

=head1 USAGE

    setup-taxdir.pl --tax=<dir> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item --taxdir=<dir>

Path to the directory to be created.

=for Euclid: dir.type: string

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --update-cache

Rebuild the binary cache file (C<cachedb.bin>) without re-downloading NCBI
Taxonomy files. This is useful to enable custom C<.dmp> files (e.g.,
C<misleading.dmp>) that were manually added to the directory [default: no].

=item --gi-mapper

Additionally setup optional mapper file associating taxids to GI numbers for
all nucleotide and protein sequences stored in GenBank [default: no].

This file is compiled from two large NCBI archives (1GB and 388 MB as of
12/2014) that can be lengthy to download. Once built, the GI-to-taxid mapper
does not occupy a lot of disk space (2 GB as of 12/2014). However, its
building process currently requires about 10x more free space.

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
