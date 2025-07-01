#!/usr/bin/env perl
# PODNAME: format-tree.pl
# ABSTRACT: Format (and annotate) trees for printing
# CONTRIBUTOR: Valerian LUPO <valerian.lupo@uliege.be>

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use List::AllUtils qw(pairfirst);
use Smart::Comments;
use Try::Tiny;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(:filenames secure_outfile);
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::IdMapper';
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Core::Taxonomy';
use aliased 'Bio::MUST::Core::Tree';

# TODO: implement numbered taxonomic levels as in fetch-tax.pl
# check for conditionally required arguments
die <<'EOT' if !$ARGV_annotate && ($ARGV_collapse || $ARGV_colorize);
Missing required arguments:
    --annotate=<level>
EOT

die <<'EOT' if !$ARGV_taxdir && ($ARGV_root_on_taxon || $ARGV_annotate || $ARGV_auto_final_ids);
Missing required arguments:
    --taxdir=<dir>
EOT

# optionally read global org-mapper
my $org_mapper;
if ($ARGV_org_mapper) {
    ### Mapping organisms from: $ARGV_org_mapper
    $org_mapper = IdMapper->load($ARGV_org_mapper);
}

# optionally build taxonomy object
my $tax;
if ($ARGV_taxdir) {
    ### Annotating trees using: $ARGV_taxdir
    $tax = Taxonomy->new_from_cache( tax_dir => $ARGV_taxdir );
}

# setup potential rooting strategy
my $filter;
my ($component, $target) = pairfirst { $b }
    map { $_ => $ARGV{"--root-on-$_"} } qw(taxon genus species family tag);
if ($component) {
    ### Rooting strategy: "$component = $target"
    $filter = $component eq 'taxon' ? $tax->tax_filter(     ["+$target"] )
            :        SeqId->${\ ($component . '_filter') }( ["+$target"] )
    ;
}

# setup collapsing and group naming
my $annotate_key;
my $collapse_key;
if ($ARGV_collapse && ($ARGV_collapse =~ m/label|color/xms)) {
    $annotate_key  = 'taxon_label' if $ARGV_annotate eq 'missing';
    $collapse_key  = 'taxon_label' if $ARGV_collapse eq 'label';
    $collapse_key  = '!color'      if $ARGV_collapse eq 'color';
    $ARGV_collapse = 'no rank';
}
$ARGV_annotate = 'no rank' if $ARGV_annotate && $ARGV_annotate eq 'missing';
my %opts = (name  => $ARGV_annotate);
$opts{  collapse} =  $ARGV_collapse if $ARGV_collapse;

TREE:
for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $tree;
    try   { $tree = Tree->load($infile) }
    catch { warn "Warning: cannot load '$infile' as a Tree; skipping!\n" };
    next TREE unless $tree;

    $infile =~ s/$_//xms for @ARGV_in_strip;

    if ($ARGV_map_ids) {
        my $idmfile = change_suffix($infile, '.idm');
        my $idm = IdMapper->load($idmfile);
        ### Restoring seq ids from: $idmfile

        if ($org_mapper) {      # TODO: move into module for testing?
            # build preliminary mapper from infile idm and global org_mapper
            my $idl = IdList->new( ids => [ $idm->all_long_ids ] );
            my $pre_idm = $idl->org_mapper_from_abbr_ids($org_mapper);
            # update infile mapper to replace abbr_ids by longer_ids
            $idm = IdMapper->new(
                long_ids => [
                    map { $pre_idm->long_id_for($_) } $idm->all_long_ids
                ],
                abbr_ids => [ $idm->all_abbr_ids ],
            );
        }
        $tree->restore_ids($idm);
    }

    if ($ARGV_from_consense) {
        my $bl = $ARGV_arb ? 1 : undef;     # treeplot wants branch lengths
        $tree->switch_branch_lengths_and_labels_for_entities($bl);
    }

    if ($ARGV_ultrametrize) {
        $tree->tree->chronompl;
    }

    if ($filter) {
        ### Rooting on: $target
        $tree->root_tree($filter, -1, 1);
        # Note: rerooting must occur before propagating taxonomy to nodes
    }

    if ($ARGV_ladderize) {
        $tree->tree->ladderize($ARGV_ladderize eq 'asc');
    }

    if ($ARGV_annotate) {
        $tax->attach_taxonomies_to_terminals($tree);
        $tax->attach_taxonomies_to_internals($tree);
        $tax->attach_taxa_to_entities($tree, \%opts);

        if ($ARGV_colorize) {
            ### Coloring tree using: $ARGV_colorize
            my $scheme = $tax->load_color_scheme($ARGV_colorize);
            $scheme->attach_colors_to_entities($tree);
        }

        if ($ARGV_collapse) {
            $tree->collapse_subtrees($collapse_key);
        }

        # iTOL output
        if ($ARGV_itol) {
            $tree->store_itol_datasets(
                insert_suffix($infile, $ARGV_out_suffix), $annotate_key
            );
        }

        # TRE or ARB output
        unless ($ARGV_figtree || $ARGV_itol) {
            $tree->switch_attributes_and_labels_for_internals('taxon');
        }
    }

    if ($ARGV_map_final_ids) {
        my $idmfile = change_suffix($infile, '.final-idm');
        my $idm = IdMapper->load($idmfile);
        ### Final seq ids taken from: $idmfile
        $tree->restore_ids($idm);
    }

    elsif ($ARGV_auto_final_ids) {
        ### Building final ids using NCBI Taxonomy
        my $idm = $tax->tax_mapper($tree, { append_acc => 1 } );
        $tree->restore_ids($idm);
    }

    # TODO: add PDF export

    my $args;

    my  $outfile = change_suffix($infile, '.tre');
    my  $store_method = 'store';
    if ($ARGV_arb) {
        $outfile = change_suffix($infile, '.arb');
        $store_method = 'store_arb';
        $args = { alifile => change_suffix($infile, '.ali') };
    } elsif ($ARGV_figtree) {
        $outfile = change_suffix($infile, '.nex');
        $store_method = 'store_figtree';
    }
    $outfile = secure_outfile($outfile, $ARGV_out_suffix);
    ### Output tree in: $outfile
    $tree->$store_method($outfile, $args);

    if ($ARGV_grp) {
        my $grpfile = change_suffix($infile, '.grp');
           $grpfile = secure_outfile($grpfile, $ARGV_out_suffix);
        $tree->store_grp($grpfile);
        my $nbsfile = change_suffix($infile, '.nbs');
           $nbsfile = secure_outfile($nbsfile, $ARGV_out_suffix);
        $tree->store_nbs($nbsfile);
    }
}

# TODO: include iqtree2mapper?

__END__

=pod

=head1 NAME

format-tree.pl - Format (and annotate) trees for printing

=head1 VERSION

version 0.251810

=head1 USAGE

    format-tree.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input TRE files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --in[-strip]=<str>

Substring(s) to strip from infile basenames before attempting to derive other
infile (e.g., IDM files) and outfile names [default: none].

=for Euclid: str.type: string
    repeatable

=item --out[-suffix]=<suffix>

Suffix to append to (possibly stripped) infile basenames for deriving
outfile names [default: none]. When not specified, outfile names are taken
from infiles but original infiles are preserved by being appended a .bak
suffix.

=for Euclid: suffix.type: string

=item --map-ids

Sequence id mapping switch [default: no]. When specified, sequence ids are
restored from the corresponding IDM files.

=item --org-mapper=<file>

Path to an optional IDM file associating organism names to abbreviations
(see C<change-ids-ali.pl>). When specified, ids to be restored from
individual IDM files are first expanded using the long_org => abbr_org pairs
listed in this global IDM file.

=for Euclid: file.type: readable

=item --map-final-ids

Final sequence id mapping switch [default: no]. When specified, final
sequence ids are taken from additional IDM files named as *.final-idm.

A two-step mapping strategy allows annotating the tree by taxonomy while
using custom sequence ids in the output tree. When both are specified, this
argument takes precedence on the next one (C<--auto-final-ids>).

=item --auto-final-ids

Auto final sequence id switch [default: no]. When specified, final sequence
ids are automatically set to organism names fetched from the NCBI Taxonomy
database on the basis of taxonomic information contained in the original
sequence ids. This requires a local mirror of the NCBI Taxonomy database.

=item --from-consense

PHYLIP's consense import switch [default: no]. When specified, branch
lengths of internal nodes are interpreted as statistical support values
(e.g., BP). Note that the formatted tree will be devoid of branch lengths
and should thus be displayed as a cladogram.

=item --ultrametrize

When specified, the tree is made ultrametric using the method of Britton et
al. (2002), as implemented in C<Bio::Phylo>.

=item --root-on-taxon=<taxon>

When specified, the tree is rooted on the branch best separating the outgroup
taxon from the remaining of the tree [default: none]. This requires a local
mirror of the NCBI Taxonomy database but not necessarily enabling taxonomic
annotation. Other rooting options are available below. These are mutually
exclusive and enabled in decreasing listing order in this documentation.

=for Euclid: taxon.type: string

=item --root-on-genus=<genus>

When specified, the tree is rooted on the branch best separating the outgroup
genus from the other genera of the tree [default: none]. This does not rely on
a full taxonomic analysis but only on L<Bio::MUST::Core::SeqId> methods

=for Euclid: genus.type: string

=item --root-on-species=<species>

When specified, the tree is rooted on the branch best separating the outgroup
species from the other species of the tree [default: none]. This does not rely
on a full taxonomic analysis but only on L<Bio::MUST::Core::SeqId> methods

=for Euclid: species.type: string

=item --root-on-family=<family>

When specified, the tree is rooted on the branch best separating the outgroup
family from the other families of the tree [default: none]. This works better
when family information is available for most sequences.

=for Euclid: family.type: string

=item --root-on-tag=<tag>

When specified, the tree is rooted on the branch best separating the outgroup
tag from the other tags of the tree [default: none]. This works better when
tag information is available for most sequences.

=for Euclid: tag.type: string

=item --ladderize=<dir>

Direction of the node sorting operation [default: none]. The following
directions are available: asc and desc.

=for Euclid: dir.type:       string, dir eq 'asc' || dir eq 'desc'
    dir.type.error: <dir> must be one of asc or desc (not dir)

=item --annotate[=][<level>]

When specified, a taxonomic analysis of all nodes is carried out and the
nodes are named after their taxon at (or above) the specified taxonomic
level. This requires a local mirror of the NCBI Taxonomy database.

Available levels are: superkingdom, kingdom, subkingdom, superphylum, phylum,
subphylum, superclass, class, subclass, infraclass, superorder, order,
suborder, infraorder, parvorder, superfamily, family, subfamily, tribe,
subtribe, genus, subgenus, species group, species subgroup, species,
subspecies, varietas, forma and 'no rank' (don't forget the quotes).

=for Euclid: level.type: string
    level.opt_default: 'missing'

=item --collapse=<level>

When specified, monophyletic nodes are collapsed exactly at the specified
taxonomic level. This requires enabling taxonomic annotation.

Two special levels are also supported: label and color. With label, subtrees
are collapsed on the various taxa of the CLS file (see C<--colorize> option
just below), whereas with color, subtrees colored in the same color are
collapsed. This allows collapsing nodes at various taxonomic levels and even
non-monophyletic nodes composed of taxa identically colored on purpose.

=for Euclid: level.type: string

=item --colorize=<scheme>

When specified, branches of the tree are colored after their taxon using the
specified CLS file. This requires enabling taxonomic annotation.

=for Euclid: scheme.type: readable

=item --taxdir=<dir>

Path to local mirror of the NCBI Taxonomy database.

=for Euclid: dir.type: string

=item --arb

Output tree in MUST pseudo-Newick ARB format [default: no].

=item --grp

Output BP/PP support values in MUST pseudo-consense GRP format [default: no].
When specified, this option also generates companion NBS files.

=item --figtree

Output tree in FigTree enhanced NEXUS format [default: no].

=item --itol

Output tree metadata for upload and vizualisation in iTOL [default: no].

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Valerian LUPO

Valerian LUPO <valerian.lupo@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
