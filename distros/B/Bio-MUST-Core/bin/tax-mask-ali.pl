#!/usr/bin/env perl
# PODNAME: tax-mask-ali.pl
# ABSTRACT: Mask ALI files based on taxonomic filters

use Modern::Perl '2011';
use autodie;

use Config::Any;
use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(secure_outfile);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::Taxonomy';


# read configuration file
my $config = Config::Any->load_files( {
    files           => [ $ARGV_config ],
    flatten_to_hash => 1,
    use_ext         => 1,
} );
### config: $config->{$ARGV_config}

die "Error: no config file specified; aborting...\n"
    unless $config;

# build taxonomy and classifier objects
my $tax = Taxonomy->new_from_cache( tax_dir => $ARGV_taxdir );
my $classifier = $tax->tax_classifier( $config->{$ARGV_config} );

for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $ali = Ali->load($infile);

    my $mask_for = $classifier->tax_masks($ali);
    while (my ($cat_label, $mask) = each %{$mask_for} ) {
        my $masked = $mask->filtered_ali($ali);
        my $outfile = secure_outfile($infile, '_' . $cat_label);
        ### Output alignment in: $outfile
        $masked->store($outfile);
    }
}

__END__

=pod

=head1 NAME

tax-mask-ali.pl - Mask ALI files based on taxonomic filters

=head1 VERSION

version 0.251810

=head1 USAGE

    tax-mask-ali.pl <infiles> --config=<file> --taxdir=<dir>
        [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input ALI files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=item --config=<file>

Path to the configuration file specifying the classifier details.

In principle, several configuration file formats are available: XML, JSON,
YAML. However, this program was designed with YAML in mind.

The configuration file defines different 'categories'. The order of
definition is relevant. Hence, if an ALI matches more than one category, it
is classified according to the first one that was defined. Each category has
a 'label' that is used to create the corresponding subdirectory for sorting
ALI files.

A category is characterized by one or more 'criteria'. To match a category,
an ALI must satisfy all criteria. Criteria are thus linked by logical ANDs
(and their order of definition is irrelevant).

Each criterion has a 'tax_filter' describing its taxonomic requirements.
Wanted taxa are to be prefixed by a '+' symbol, whereas unwanted taxa are to
be prefixed by a '-' symbol. Wanted and unwanted taxa are linked by logical
ORs.

Criteria may also have a 'min_seq_count' and a 'max_seq_count' arguments.
These respectively specify the minimum and maximum number of sequences that
must pass the tax_filter for the ALI to match the criterion. Minimum
defaults to 1, while there is no upper bound by default.

Other conditions are available: 'min_org_count' and 'max_org_count' deal
with organisms instead of sequences, whereas 'min_copy_mean' and
'max_copy_mean' allow bounding the mean number of gene copies per organism.
All default not no bound.

An example YAML file follows:

    categories:
    - label: strict
      description: strict species sampling
      criteria:
      - tax_filter: [ +Latimeria ]
        min_seq_count: 1
        max_seq_count:
        min_org_count:
        max_org_count:
        min_copy_mean:
        max_copy_mean:
      - tax_filter: [ +Protopterus ]
      # min_seq_count defaults to 1
      # max_seq_count defaults to no upper bound
      # all other also default to no bound
      - tax_filter: [ +Danio, +Oreochromis ]
      - tax_filter: [ +Xenopus ]
      - tax_filter: [ +Anolis, +Gallus, +Meleagris, +Taeniopygia ]
      - tax_filter: [ +Mammalia ]
    - label: loose
      description: loose species sampling
      criteria:
      - tax_filter: [ +Latimeria ]
      - tax_filter: [ +Protopterus ]
      - tax_filter: [ +Danio, +Oreochromis ]
      - tax_filter: [ +Amphibia, +Amniota ]

=for Euclid: file.type: readable

=item --taxdir=<dir>

Path to local mirror of the NCBI Taxonomy database.

=for Euclid: dir.type: string

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
