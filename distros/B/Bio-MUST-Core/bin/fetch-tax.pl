#!/usr/bin/env perl
# PODNAME: fetch-tax.pl
# ABSTRACT: Fetch information from the NCBI Taxonomy database

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use List::AllUtils qw(apply each_array);
use Scalar::Util qw(looks_like_number);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:ncbi);
use Bio::MUST::Core::Utils qw(change_suffix);
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Core::Taxonomy';

# TODO: check values of arg --item-type (debug Gepopt::Euclid and --item?)
# TODO: allow for multi-column input with --item-col argument

# build taxonomy object
my $tax = Taxonomy->new_from_cache( tax_dir => $ARGV_taxdir );

# setup org-mapper (or NOM) IDM format if required
my $suffix = '.tax';
my $sep = "\t";
my $sort = 0;
my $classifier;
if ($ARGV_org_mapper) {
    $ARGV_noitem    = 1;
    $ARGV_nomustid  = 0;
    $ARGV_notaxid   = 0;
    $ARGV_nolineage = 1;
    $suffix = '.org-idm';
}
if ($ARGV_legacy_nom) {
    $ARGV_noitem    = 1;
    $ARGV_nomustid  = 0;
    $ARGV_notaxid   = 1;
    $ARGV_nolineage = 0;
    $suffix = '.nom';
    $sep = q{ , };
    $sort = 1;
    $ARGV_missing ||= 'UNKNOWN';            # default to q{} in Euclid...
    @ARGV_levels = ( $ARGV_legacy_nom );

    # build classifier for legacy NOM file if legacy_nom is a readable FRA file
    $classifier = $tax->classifier_from_systematic_frame($ARGV_legacy_nom)
        if $ARGV_legacy_nom =~ m/.fra$/xmgi && -e $ARGV_legacy_nom;
}

if (@ARGV_levels) {
    ### Specified levels: @ARGV_levels
}

### --item-type: $ARGV_item_type

my $method = $ARGV_from_must ? 'load_lis' : 'load';

for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $list = IdList->$method($infile);

    # fetch and clean up list items
    # Note: using apply instead of map for satisfying Perl::Critic
    my @items = apply {
        s{\s+}{ }xmsg;      # convert runs of whitespace to single whitespace
        s{^\s+}{}xmsg;      # trim spaces at beginning...
        s{\s+$}{}xmsg;      # ... and end of items
        $_
    } $list->all_ids;

    # tweak list items to suit mapping methods then fetch taxon_ids
    my @taxon_ids;
    given ($ARGV_item_type) {
        when ('mustid') {
            @taxon_ids = map { $tax->get_taxid_from_seq_id($_)   } @items;
        }
        when ('baseid') {
            @taxon_ids = map { $tax->get_taxid_from_seq_id($_)   }
                         map { $_ . '@1'                         } @items;
        }
        when ('gi')     {
            @taxon_ids = map { $tax->get_taxid_from_seq_id($_)   }
                         map { $_ =~ $PKEYONLY ? 'gi|' . $_ : $_ } @items;
        }       # we let ..._from_seq_id doing the GI number parsing
        when ('name')   {
            @taxon_ids = map { $tax->get_taxid_from_name(  $_)   } @items;
        }       # we directly use ..._from_name to use the whole item
        when ('taxid')  {
            @taxon_ids =                                           @items;
        }
    }

    my @rows;

    # fetch and assemble taxonomy lines
    my $ea = each_array @items, @taxon_ids;
    while (my ($item, $taxon_id) = $ea->() ) {

        my ($must_id, $lineage);
        if ($taxon_id) {

            # fetch full taxonomy and lowest taxon
            my @taxonomy = $tax->get_taxonomy($taxon_id);
            my $org = $taxonomy[-1];

            # proceed only if valid taxon_id
            if ($org) {

                # build base MUST id...
                $must_id = SeqId->new_with(
                    org      => $org,
                    taxon_id => $taxon_id
                )->full_id;

                # ... and NCBI lineage
                # ... using a classifier based on a systematic frame
                if ($classifier) {
                    my $full_id = $taxon_id . '|X';
                    @taxonomy = ( $classifier->classify($full_id) );
                }   # Note: all this part is very inefficient but easy to code

                # ...or using rank or rank numbers
                elsif (@ARGV_levels) {  # optionally filter (and reorder) taxa
                    @taxonomy = map {   # handle both ranks and numeric levels
                        looks_like_number($_) ? $taxonomy[$_-1] // q{}
                            : $tax->get_term_at_level($taxon_id, $_)
                    } @ARGV_levels;
                }
                $lineage = join '; ', @taxonomy;
            }

            # otherwise nullify taxon_id (e.g., user-provided)
            else {
                $taxon_id = q{};
            }
        }

        # ... depending on boolean switches!
        my @data;
        push @data,  $item                       unless $ARGV_noitem;
        push @data, ($must_id  || $ARGV_missing) unless $ARGV_nomustid;
        push @data, ($taxon_id || $ARGV_missing) unless $ARGV_notaxid;
        push @data, ($lineage  || $ARGV_missing) unless $ARGV_nolineage;
        push @rows, \@data;
    }

    # output assembled taxonomy lines
    my $outfile = change_suffix($infile, $suffix);
    open my $out, '>', $outfile;
    @rows = sort { $a->[0] cmp $b->[0] } @rows if $sort;
    say {$out} join $sep, @{$_} for @rows;
}


# TODO: add option keep-strain!

__END__

=pod

=head1 NAME

fetch-tax.pl - Fetch information from the NCBI Taxonomy database

=head1 VERSION

version 0.180190

=head1 USAGE

    fetch-tax.pl <infiles> --tax=<dir> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input IDL files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=item --taxdir=<dir>

Path to local mirror of the NCBI Taxonomy database.

=for Euclid: dir.type: string

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --from-must

Consider the input file as generated by ed/treeplot [default: no]. Currently,
this switches to the legacy .lis format (instead of the modern .idl format).

=item --item-type=<str>

Type of the items listed in the infile [default: mustid]. The following
types are available:

    - mustid (standard MUST ids, including the '@')
    - baseid (base MUST ids, truncated before the '@')
    - name   (NCBI names)
    - taxid  (NCBI taxon ids or GCA/GCF accessions)
    - gi     (NCBI GIs, complete accessions are allowed)

C<mustid> and C<baseid> items will both be analyzed by the
L<Bio::MUST::Core::Taxonomy> heuristics, whereas C<name> items will be
considered in full as NCBI names (which may correspond to higher taxa or
include very detailed strain information). In contrast, C<taxid> items will
be directly used to get the corresponding NCBI taxa.

As an additional possibility, C<gi> items can be used. These are given either
as mere GI numbers (e.g., 158280253 or gi|158280253) or as complete NCBI
accessions beginning with the GI number (e.g., gi|158280253|gb|EDP06011.1|),
which helps analysing BLAST reports obtained from searches against NCBI
databases.

Using C<gi> items requires having installed the GI-to-taxid mapper during
setup of the local mirror of the NCBI Taxonomy database (see
L<setup-taxdir.pl> for details).

=for Euclid: str.type:       /mustid|baseid|name|taxid|gi/
    str.type.error: <str> must be one of mustid, baseid, name, taxid or gi (not str)
    str.default:    'mustid'

=item --missing=<str>

String to substitute for missing taxonomies [default: none].

=for Euclid: str.type: string
    str.default: q{}

=item --[no]item

[Don't] include list item in output [default: yes].

=for Euclid: false: --noitem

=item --[no]taxid

[Don't] include NCBI taxon id in output [default: yes].

=for Euclid: false: --notaxid

=item --[no]mustid

[Don't] include base MUST id in output [default: yes].

=for Euclid: false: --nomustid

=item --[no]lineage

[Don't] include NCBI lineage in output [default: yes].

=for Euclid: false: --nolineage

=item --levels=<level>...

List of whitespace-separated levels to be displayed in NCBI lineages
[default: all].

Only taxa corresponding to specified levels will be conserved; others will be
pruned out. Taxon order will follow the input level order. Beware that invalid
or missing levels will result in undef values at the corresponding slots.

Valid levels are: superkingdom, kingdom, subkingdom, superphylum, phylum,
subphylum, superclass, class, subclass, infraclass, superorder, order,
suborder, infraorder, parvorder, superfamily, family, subfamily, tribe,
subtribe, genus, subgenus, 'species group', 'species subgroup', species,
subspecies, varietas, forma.

Levels can also be specified as numbers but this only makes sense for the
highest levels in the hierarchy (i.e., 3 to 5).

=item --org-mapper

IDM output switch [default: no]. When specified, the output can be used as an
IDM file listing the base MUST id => NCBI taxon id pairs. This option
overrides all other output switches except the next one.

=item --legacy-nom=<level|file.fra>

Enable generation of a NOM file associating base MUST ids to groups for using
with MUSTED. Groups will be set to the taxa ranked at the specified level.
Again, the level can be given as a number. When specified, this option
overrides all other output switches.

Alternatively, the leaves of the systematic frame contained in the specified
FRA file can be used to fine-tune the rank for each taxon, i.e., each base
MUST id is associated to the first terminal taxon that is part of its lineage.

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
