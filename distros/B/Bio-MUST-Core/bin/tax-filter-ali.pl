#!/usr/bin/env perl
# PODNAME: tax-filter-ali.pl
# ABSTRACT: Apply a taxonomic filter to ALI files

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(secure_outfile);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::Taxonomy';

# build taxonomy and filter objects
my $tax = Taxonomy->new_from_cache( tax_dir => $ARGV_taxdir );
my $filter = $tax->tax_filter($ARGV_filter);
### Active filter: $filter->all_specs

for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $ali = Ali->load($infile);
    $ali->apply_list( $filter->tax_list($ali) );
    my $outfile = secure_outfile($infile, $ARGV_out_suffix);
    $ali->store($outfile);
}

__END__

=pod

=head1 NAME

tax-filter-ali.pl - Apply a taxonomic filter to ALI files

=head1 VERSION

version 0.251810

=head1 USAGE

    tax-filter-ali.pl --filter=<file> --taxdir=<dir> <infiles>
        [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input ALI files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=item --filter=<file>

Path to an IDL file specifying the taxonomic filter to be applied.

In a tax_filter, wanted taxa are to be prefixed by a '+' symbol, whereas
unwanted taxa are to be prefixed by a '-' symbol. Wanted and unwanted taxa
are linked by logical ORs.

An example IDL file follows:

    -Viridiplantae
    -Opisthokonta
    +Ascomycota
    +Oomycota

=for Euclid: file.type: readable

=item --taxdir=<dir>

Path to local mirror of the NCBI Taxonomy database.

=for Euclid: dir.type: string

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --out[-suffix]=<suffix>

Suffix to append to infile basenames for deriving outfile names [default:
none]. When not specified, outfile names are taken from infiles but original
infiles are preserved by being appended a .bak suffix.

=for Euclid: suffix.type: string

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
