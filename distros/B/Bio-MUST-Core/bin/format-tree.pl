#!/usr/bin/env perl
# PODNAME: format-tree.pl
# ABSTRACT: Format trees for printing

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;
use Try::Tiny;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix secure_outfile);
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::IdMapper';
use aliased 'Bio::MUST::Core::Taxonomy';
use aliased 'Bio::MUST::Core::Tree';

# TODO: implement numbered taxonomic levels as in fetch-tax.pl

# check for conditionally required arguments
die <<'EOT' if !$ARGV_annotate && ($ARGV_collapse || $ARGV_colorize);
Missing required arguments:
    --annotate=<level>
EOT

die <<'EOT' if !$ARGV_taxdir && ($ARGV_annotate || $ARGV_auto_final_ids);
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
    ### Annotating tree using: $ARGV_taxdir
    $tax = Taxonomy->new_from_cache( tax_dir => $ARGV_taxdir );
}

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

    if ($ARGV_ladderize) {
        $tree->tree->ladderize($ARGV_ladderize eq 'asc');
    }

    if ($ARGV_annotate) {
        $tax->attach_taxonomies_to_terminals($tree);
        $tax->attach_taxonomies_to_internals($tree);

        my %opts = (name  => $ARGV_annotate);
        $opts{  collapse} =  $ARGV_collapse if $ARGV_collapse;
        $tax->attach_taxa_to_entities($tree, \%opts);

        # FigTree output
        if ($ARGV_figtree) {
            $tree->collapse_subtrees if $ARGV_collapse;
            if ($ARGV_colorize) {
                ### Coloring tree using: $ARGV_colorize
                my $scheme = $tax->load_color_scheme($ARGV_colorize);
                $scheme->attach_colors_to_entities($tree);
            }
        }

        # TRE or ARB output
        else {
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
        my $idm = $tax->tax_mapper($tree, { append_acc => 1} );
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

__END__

=pod

=head1 NAME

format-tree.pl - Format trees for printing

=head1 VERSION

version 0.190500

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

=item --ladderize=<dir>

Direction of the node sorting operation [default: none]. The following
directions are available: asc and desc.

=for Euclid: dir.type:       /asc|desc/
    dir.type.error: <dir> must be one of asc or desc (not dir)

=item --annotate=<level>

When specified, a taxonomic analysis of all nodes is carried out and the
nodes are named after their taxon at (or above) the specified taxonomic
level. This requires a local mirror of the NCBI Taxonomy database.

Available levels are: superkingdom, kingdom, subkingdom, superphylum,
phylum, subphylum, superclass, class, subclass, infraclass, superorder,
order, suborder, infraorder, parvorder, superfamily, family, subfamily,
tribe, subtribe, genus, subgenus, species group, species subgroup, species,
subspecies, varietas, forma and 'no rank' (don't forget the quotes).

=for Euclid: level.type: string

=item --collapse=<level>

When specified, monophyletic nodes are collapsed exactly at the specified
taxonomic level. This requires enabling taxonomic annotation.

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
