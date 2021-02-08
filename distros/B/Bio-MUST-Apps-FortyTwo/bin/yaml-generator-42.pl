#!/usr/bin/env perl
# PODNAME: yaml-generator-42.pl
# ABSTRACT: Interactive or batch generator for 42 YAML config files
# CONTRIBUTOR: Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>

use autodie;
use Modern::Perl '2011';

use Smart::Comments;
use Getopt::Euclid qw(:vars);

use Template;
use Path::Class;
use Tie::IxHash;
use List::AllUtils;
use File::Basename;
use File::Find::Rule;

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Core::Taxonomy';
use Bio::FastParsers::Constants qw(:files);

use Term::Completion::Path;
use IO::Prompter [
    -verbatim,
    -style => 'blue strong ',
    -must  => { 'be a string' => qr{\S+} }
];
#    bold      => [qw<boldly strong heavy emphasis emphatic highlight highlighted fort forte>],
#    dark      => [qw<darkly dim deep>],
#    faint     => [qw<faintly light soft>],
#    underline => [qw<underlined underscore underscored italic italics>],
#    blink     => [qw<blinking flicker flickering flash flashing>],
#    reverse   => [qw<reversed inverse inverted>],
#    concealed => [qw<hidden blank invisible>],
#    reset     => [qw<normal default standard usual ordinary regular>],
#    bright_   => [qw< bright\s+ vivid\s+ >],
#    red       => [qw< scarlet vermilion crimson ruby cherry cerise cardinal carmine
#                      burgundy claret chestnut copper garnet geranium russet
#                      salmon titian coral cochineal rose cinnamon ginger gules >],
#    yellow    => [qw< gold golden lemon cadmium daffodil mustard primrose tawny
#                      amber aureate canary champagne citrine citron cream goldenrod honey straw >],
#    green     => [qw< olive jade pea emerald lime chartreuse forest sage vert >],
#    cyan      => [qw< aqua aquamarine teal turquoise ultramarine >],
#    blue      => [qw< azure cerulean cobalt indigo navy sapphire >],
#    magenta   => [qw< amaranthine amethyst lavender lilac mauve mulberry orchid periwinkle
#                      plum pomegranate violet purple aubergine cyclamen fuchsia modena puce
#                      purpure >],
#    black     => [qw< charcoal ebon ebony jet obsidian onyx raven sable slate >],
#    white     => [qw< alabaster ash chalk ivory milk pearl silver argent >],



# define config file template
my $tt_str = <<'EOT';
# ===Run mode===
# Two values are available: 'phylogenomic' and 'metagenomic'.
# The phylogenomic mode is designed to enrich multiple sequence alignements
# (ALIs) with orthologues for subsequent phylogenomic analysis. In contrast,
# the metagenomic mode is designed to probe contamination in transcriptomic
# data using reference ribosomal protein ALIs; it produces a taxonomic report
# per ALI listing the lineage of each identified orthologous sequence.
# When not specified, 'run_mode' internally defaults to 'phylogenomic'.
run_mode: [% run_mode %]

# ===Suffix to append to infile basenames for deriving outfile names===
# When not specified 'outsuffix' internally defaults to '-42'.
# Use a bare 'out_suffix:' to reuse the ALI name and to preserve the original
# file by appending a .bak extension to its name.
out_suffix: [% out_suffix %]


# ===Orgs from where to select BLAST queries===
# Depending on availability at least one query by family and by org will be
# picked for the 'homologues' and 'references' BLAST rounds.
query_orgs: [% FOREACH org IN query_orgs.sort %]
    - [% org %] [% END %]


# ===Optional args for each BLAST step===
# Any valid command-line option can be specified (see NCBIBLAST+ docs).
# Note the hyphens (-) before option names (departing from API consistency).
# -query, -db, -out, -outfmt, -db_gencode, -query_gencode will be ignored as
# they are directly handled by forty-two itself. -max_target_seqs may be
# specified at step 'homologues' to speed up things.
blast_args:
    # TBLASTN vs banks
    homologues:
        -evalue: [% evalue %]
        [% UNLESS SSUrRNA -%]-seg: [% homologues_seg %][%- END %]
        -num_threads: 1
        -max_target_seqs: [% max_target_seqs %]
    [%- IF ref_brh == 'on' %]
    # BLASTP vs ref banks (for transitive BRH ; actually two steps)
    references:
        -evalue: [% evalue %]
        -num_threads: 1
    # BLASTX vs ref banks (for transitive BRH)
    orthologues:
        -evalue: [% evalue %]
        -num_threads: 1[% END %]
    # BLASTX vs ALI (for tax filters and alignment)
    templates:
        -evalue: [% evalue %]
        [% UNLESS SSUrRNA -%]-seg: [% templates_seg  %][%- END %]
        -num_threads: 1


# ===BRH switch for assessing orthology===
# Two values are available: 'on' and 'off'.
# If set to 'on', a candidate seq must be in BRH with all reference proteomes
# to be considered as an orthologous seq. In contrast, all candidate seqs are
# considered as orthologous seqs when this parameter is set to 'off'.
# When not specified, 'ref_brh' internally defaults to 'on'.
# To limit the number of candidate seqs, use the '-max_target_seqs' option of
# the BLAST executable(s) at the 'homologues' step.
ref_brh: [% ref_brh %]

[% IF ref_brh == 'on' %]
# ===Path to dir holding complete proteome BLAST databases===
# Only required when setting 'ref_brh' to 'on'.
ref_bank_dir: [% ref_bank_dir %]

# ===Basenames of complete proteome BLAST databases (keyed by org name)===
# Only required when setting 'ref_brh' to 'on'.
# You can list as many databases as needed here. Only those specified as
# 'ref_orgs' below will actually be used for BRH.
ref_org_mapper: [% FOREACH bank IN ref_org_for.keys.sort %]
    [% ref_org_for.$bank %]: [% bank %] [% END %]

# ===Orgs to be used for BRH checks===
# Only required when setting 'ref_brh' to 'on'.
# To be considered as an orthologue, a candidate seq must be in transitive BRH
# for all listed orgs (and not for only one of them). Listing more orgs thus
# increases the stringency of the BRH check. Note that 'ref_orgs' may but DO
# NOT NEED to match 'query_orgs'.
ref_orgs: [% FOREACH bank IN ref_org_for.keys.sort %]
    - [% ref_org_for.$bank %] [% END %]

# ===Fraction of ref_orgs to really use when assessing orthology===
# Only meaningful when setting 'ref_brh' to 'on'.
# This parameter introduces some flexibility when using reference proteomes.
# If set to a fractional value (below 1), only the best proteomes will be
# considered during BRHs. The best proteomes are those against which the
# queries have the highest average scores. This helps discarding ref_orgs that
# might hinder orthology assessment because they lack the orthologous gene(s).
# When not specified, 'reg_org_mul' internally defaults to 1.0, which is the
# strictest mode since all reference proteomes are used during BRHs.
ref_org_mul: [% ref_org_mul %]

# ===Bit score reduction allowed when including non-1st hits among best hits===
# Only meaningful when setting 'ref_brh' to 'on'.
# This parameter applies when collecting best hits for queries to complete
# proteomes, so that close in-paralogues can all be included in the set of
# best hits. The allowed bit score reduction of any hit is expressed
# relatively to the score of the previous hit. During BRH checks, only the
# very first hit for the candidate seq is actually tested for inclusion in
# this set but for all complete proteomes. By default at most 10 hits are
# considered. To change this, use the '-max_target_seqs' option of the BLAST
# executable(s) at the 'reference' step.
# When not specified 'ref_score_mul' internally defaults to 1.0, which is the
# strictest mode since only equally-best hits are retained.
ref_score_mul: [% ref_score_mul %][% END %]

[% IF tol_check == 'on' -%]
# ===TreeOfLife check===
#
#
tol_check: [% tol_check %]

# ===Path to TreeOfLife database===
#
#
tol_bank_dir: [% tol_bank_dir %]
tol_bank: [% tol_bank %][%- END %]

# ===Homologues trimming switch===
# Two values are available: 'on' and 'off'.
# If set to 'on', each candidate seq is first trimmed to the range covered by
# the HSPs that retrieved it. This makes the orthology assessment more robust
# and helps exonerate to splice genes correctly. The details of this trimming
# step can be fine-tuned by editing the other trim_* parameters of this
# configuration file.
# When not specified, 'trim_homologues' internally defaults to 'on'.
trim_homologues: [% trim_homologues %]

[% IF trim_homologues == 'on' -%]
# ===Max distance between HSPs allowed when defining a hit range===
# Only meaningful when setting 'trim_homologues' to 'on'.
# HSPs define ranges that will be used to extract one or more candidate seq(s)
# from each hit. Before extraction, neighboring ranges are merged if they lie
# at max this distance (in nt) apart. This distance can thus be seen as the
# max length allowed for an intron within a gene to be added.
# When not specified 'trim_max_shift' internally defaults to 20000 nt.
trim_max_shift: [% trim_max_shift %]

# ===Extra margin to hit range===
# Only meaningful when setting 'trim_homologues' to 'on'.
# Since HSPs can sometimes miss the beginning or end of the best hit, this
# parameter extends the range of the candidate seq to be extracted at both
# extremities (in nt) to allow for a potentially more complete seq.
# When not specified 'trim_extra_margin' internally defaults to 15 nt.
trim_extra_margin: [% trim_extra_margin %][%- END %]

# ===Orthologues merging switch===
# Two values are available: 'on' and 'off'.
# If set to 'on', each batch of orthologous seqs from the same org is first
# fed to CAP3 in an attempt to merge some of them into contigs. Successfully
# merged orthologous seqs are identified by a trailing +N tag where N is the
# number of orthologous seqs removed in the merging process. The contig itself
# is named after the longest orthologous seq composing it.
# The details of this merging step can be fine-tuned by editing the other
# merge_* parameters of this configuration file.
# When not specified, 'merge_orthologues' internally defaults to 'off'.
# The YAML wizard automatically sets it to 'off' if 'run_mode' is 'metagenomic'.
merge_orthologues: [% merge_orthologues %]

[% IF merge_orthologues == 'on' -%]
# ===Min identity in overlap for merging two orthologous seqs===
# Only meaningful when setting 'merge_orthologues' to 'on'.
# This parameter is the CAP3 '-p' parameter except that it is specified as a
# fractional number (between 0 and 1).
# When not specified, 'merge_min_ident' internally defaults to 0.9 (= 90%).
merge_min_ident: [% merge_min_ident %]

# ===Min length of overlap for merging two orthologous seqs===
# Only meaningful when setting 'merge_orthologues' to 'on'.
# This parameter is the CAP3 '-o' parameter (in nt).
# When not specified, 'merge_min_len' internally defaults to 40 nt.
merge_min_len: [% merge_min_len %][%- END %]


# ===Engine to be used for aligning new seqs===
# Four values are available: 'blast', 'exonerate', 'exoblast' and 'off'.
# If the alignment engine is 'off', new seqs are added 'as is' to the ALI.
# Consequently, they will be full length but not aligned to existing seqs.
# This mode is meant for protein seqs only and thus cannot be used when adding
# transcripts from nucleotide banks.
# The 'exonerate' mode sometimes fails to align orthologous seqs due to a bug
# in exonerate executable. This causes new seqs to be lost. To automatically
# retry aligning them with BLAST in case of failure, use the 'exoblast' mode.
# When not specified, 'aligner_mode' internally defaults to 'blast'.
# The YAML wizard automatically sets it to 'off' if 'run_mode' is 'metagenomic'.
aligner_mode: [% aligner_mode %]

[% UNLESS aligner_mode == 'off' %]
# ===Self-template selection switch for aligning new seqs===
# Only meaningful when setting 'aligner_mode' to a value other than 'off'.
# Two values are available: 'on' and 'off'.
# If set to 'on', closest relatives belonging to the same org as the new seqs
# will not be selected as templates, thus allowing the latter to align better.
# When not specified, 'ali_skip_self' internally defaults to 'off'.
ali_skip_self: [% ali_skip_self %]

# ===Coverage improvement required to consider non-1st hits as templates===
# Only meaningful when setting 'aligner_mode' to a value other than 'off'.
# This parameter applies when collecting templates for aligning the new seqs.
# Templates get considered as long as query coverage improves at least of this
# value (relatively to the previous template). The exact effect of this
# parameter depends on the 'aligner_mode' engine: 'exonerate' will try to use
# the longest template for alignment while 'blast' will use each hit in turn
# (as a fall-back with 'exoblast'). New seqs can thus be added more than once
# to the ALI (with ids *.H1.N, *.H2.N etc).
# When not specified 'ali_cover_mul' internally defaults to 1.1., which means
# that if the BLAST alignment with the second template is at least 110% of the
# BLAST alignment with the first template, both templates are retained.
ali_cover_mul: [% ali_cover_mul %][% END %]

# ===Preservation switch for '#NEW#' tags from preexisting sequences===
# Two values are available: 'on' and 'off'.
# If set to 'on' (default), #NEW# tags will be preserved. Note that
# preexisting new sequences are invisible to 42 (they cannot be used as
# queries etc).
ali_keep_old_new_tags: [% ali_keep_old_new_tags %]

# ===Action to perform when a preexisting lengthened seq is identified===
# Currently, two values are available: 'remove' and 'keep'.
# The option is quite self-explanatory. It is useful when one runs 42 multiple
# times on the sames ALIs to repeatedly enrich the same orgs, assuming that
# org banks are updated between runs.
# When not specified, 'ali_keep_lengthened_seqs' internally defaults to
# 'keep'.
ali_keep_lengthened_seqs: [% ali_keep_lengthened_seqs %]


# ===Taxonomic report switch===
# Two values are available: 'on' and 'off'.
# If set to 'on', the lineage of new seqs is inferred by analyzing the
# taxonomy of their ALI closest relatives and one '.tax-report' file is
# generated for each ALI processed (see 'run_mode' above).
# The details of this taxonomic analysis can be fine-tuned by editing the
# other tax_* parameters of this configuration file.
# When not specified, 'tax_reports' internally defaults to 'off'. Yet, the
# The YAML wizard automatically sets it to 'on' if 'run_mode' is 'metagenomic'.
[% IF tax_reports %]tax_reports: [% tax_reports %][% ELSE %]tax_reports: on[% END -%]

[% IF tax_dir %]
# ===Path to dir holding NCBI Taxonomy database===
# Only required when enabling 'tax_reports' or specifying 'tax_filter'.
# It can be installed using setup-taxdir.pl.
tax_dir: [% tax_dir %]

# ===Min number of relatives to use when inferring taxonomy of new seqs===
# Only meaningful when enabling 'tax_reports' or specifying 'tax_filter'.
# This parameter is a lower bound. The real number will depend both on the
# four thresholds below ('tax_min_ident', 'tax_min_len', 'tax_min_score' and
# 'tax_score_mul') and on the ability of 42 to deduce the taxonomy of each
# individual relative to compute the LCA of the new seq.
# When not specified, 'tax_min_hits' internally defaults to 1.
[% IF tax_min_hits %]tax_min_hits: [% tax_min_hits %][% ELSE %]tax_min_hits: 1[% END %]

# ===Max number of relatives to use when inferring taxonomy of new seqs===
# Only meaningful when enabling 'tax_reports' or specifying 'tax_filter'.
# As for 'tax_min_hits' above, this parameter is a upper bound.
# When not specified, 'tax_max_hits' internally defaults to unlimited.
[% IF megan_like %]tax_max_hits: 100
[%- ELSIF best_hit %]tax_max_hits: 1
[%- ELSIF tax_max_hits %]tax_max_hits: [% tax_max_hits %][%- END %]

# ===Min identity of relatives to use when inferring taxonomy of new seqs===
# Only meaningful when enabling 'tax_reports' or specifying 'tax_filter'.
# This parameter is the traditional BLAST 'percent identity' statistics except
# that it is specified as a fractional number (between 0 and 1). It is
# evaluated on the first HSP of potential relatives.
# When not specified, 'tax_min_ident' internally defaults to 0.
[% IF megan_like %]tax_min_ident: 0[% ELSIF best_hit %]tax_min_ident: 0[% ELSIF tax_min_ident %]tax_min_ident: [% tax_min_ident %][% END -%]

# ===Min length of relatives to use when inferring taxonomy of new seqs===
# Only meaningful when enabling 'tax_reports' or specifying 'tax_filter'.
# This parameter is the traditional BLAST 'alignment length' statistics. It is
# evaluated on the first HSP of potential relatives.
# When not specified, 'tax_min_len' internally defaults to 0.
[% IF megan_like %]tax_min_len: 0[% ELSIF best_hit %]tax_min_len: 0[% ELSIF tax_min_len %]tax_min_len: [% tax_min_len %][% END -%]

# ===Min bit score of relatives to use when inferring taxonomy of new seqs===
# Only meaningful when enabling 'tax_reports' or specifying 'tax_filter'.
# This parameter is the traditional BLAST 'bit score' statistics. It is
# evaluated on the first HSP of potential relatives.
# When not specified, 'tax_min_score' internally defaults to 0.
[% IF megan_like %]tax_min_score: 80[% ELSIF best_hit %]tax_min_score: 0[% ELSIF tax_min_score %]tax_min_score: [% tax_min_score %][% END %]

# ===Bit score reduction allowed when inferring taxonomy of new seqs===
# Only meaningful when enabling 'tax_reports' or specifying 'tax_filter'.
# The allowed bit score reduction of any relative is expressed relatively to
# the score of the FIRST relative (as in MEGAN algorithm).
# When not specified, 'tax_score_mul' internally defaults to 0.
[% IF megan_like %]tax_score_mul: 0.95[% ELSIF best_hit %]tax_score_mul: 0[% ELSIF tax_score_mul %]tax_score_mul: [% tax_score_mul %][% END %][%- END -%]


# ===Path to dir holding transcript BLAST databases===
bank_dir: [% bank_dir %]

# ===Default args applying to all orgs unless otherwise specified===
# Some of these args can be thus specified on a per-org basis below if needed.
# This especially makes sense for 'code'.
defaults:
    # ===Genetic code for translated BLAST searches===
    # When not specified 'code' internally defaults to 1 (standard).
    # See ftp://ftp.ncbi.nih.gov/entrez/misc/data/gc.prt for other codes.
    code: [% code %]

# ===Org-specific args===
# The only mandatory args are 'org' and 'banks'. All other args are taken from
# the 'defaults:' section described above.
# This part can be concatenated on a per-run basis to the previous part, which
# would be the same for several runs. In the future, forty-two might support
# two different configuration files to reflect this conceptual distinction.
orgs: [% FOREACH bank IN org_for.keys.sort %]
  - org: [% org_for.$bank %]
    banks:
        - [% bank %]
    [% tax_filter_for.$bank %] [% END %]

#[% USE date %]
# This config file has been generated automatically on [% date.format %].
# We advise not to modify directly this file manually but rather to modify the
# yaml-generator command instead for traceability and reproducibility.
#
#yaml-generator-42.pl --run_mode=[% run_mode %][% IF SSUrRNA %] --SSUrRNA[% END %] --out_suffix=[% out_suffix %] \
#--queries [% queries %] \
#--evalue=[% evalue %][% UNLESS SSUrRNA %] --homologues_seg=[% homologues_seg %][% END %] --max_target_seqs=[% max_target_seqs %][% UNLESS SSUrRNA %] --templates_seg=[% templates_seg %][% END %] \
#--bank_dir [% bank_dir %] --bank_suffix=[% bank_suffix %] --bank_mapper [% bank_mapper %] --code=[% code %]\
#--ref_brh=[% ref_brh -%][% IF ref_brh == 'on' %] --ref_bank_dir [% ref_bank_dir %] --ref_bank_suffix=[% ref_bank_suffix %] --ref_bank_mapper [% ref_bank_mapper %] \
#--ref_org_mul=[% ref_org_mul %] --ref_score_mul=[% ref_score_mul %][%- END %] \
#--trim_homologues=[% trim_homologues %][% IF trim_homologues == 'on' %] --trim_max_shift=[% trim_max_shift %] --trim_extra_margin=[% trim_extra_margin %][%- END %] \
#--merge_orthologues=[% merge_orthologues %][% IF merge_orthologues == 'on' %] --merge_min_ident=[% merge_min_ident %] --merge_min_len=[% merge_min_len %][%- END %] \
#--aligner_mode=[% aligner_mode %][% UNLESS aligner_mode == 'off' %] --ali_skip_self=[% ali_skip_self %] --ali_cover_mul=[% ali_cover_mul %][% END %] --ali_keep_old_new_tags=[% ali_keep_old_new_tags %] --ali_keep_lengthened_seqs=[% ali_keep_lengthened_seqs %] \
#--tax_reports=[% tax_reports %][% IF tax_dir %] --tax_dir [% tax_dir %][% END %] \
#[% IF megan_like %]--megan_like \[% ELSIF best_hit %]--best_hit \[% ELSE %]--tax_min_score=[% tax_min_score %] --tax_score_mul=[% tax_score_mul %] --tax_min_ident=[% tax_min_ident %] --tax_min_len=[% tax_min_len %] \[% END %]
#--tol_check=[% tol_check %][% IF tol_check == 'on' %] --tol_db [% tol_db %] \[%- END %]
[% IF levels %]#--levels=[% levels.join(' ') %][%- END %]
EOT

# CMD TEMPLATE
my $tt_cmd = <<'EOT';
[% USE date %]
# This config file has been generated automatically on [% date.format %].
# We advise not to modify directly this file manually but rather to modify
# the yaml-generator command instead for traceability and reproducibility.

yaml-generator-42.pl --run_mode=[% run_mode %][% IF SSUrRNA %] --SSUrRNA[% END %] --out_suffix=[% out_suffix %] \
--queries [% queries %] \
--evalue=[% evalue %][% UNLESS SSUrRNA %] --homologues_seg=[% homologues_seg %][% END %] --max_target_seqs=[% max_target_seqs %][% UNLESS SSUrRNA %] --templates_seg=[% templates_seg %][% END %] \
--bank_dir [% bank_dir %] --bank_suffix=[% bank_suffix %] --bank_mapper [% bank_mapper %] --code=[% code %]\
--ref_brh=[% ref_brh -%][% IF ref_brh == 'on' %] --ref_bank_dir [% ref_bank_dir %] --ref_bank_suffix=[% ref_bank_suffix %] --ref_bank_mapper [% ref_bank_mapper %] \
--ref_org_mul=[% ref_org_mul %] --ref_score_mul=[% ref_score_mul %][%- END %] \
--trim_homologues=[% trim_homologues %][% IF trim_homologues == 'on' %] --trim_max_shift=[% trim_max_shift %] --trim_extra_margin=[% trim_extra_margin %][%- END %] \
--merge_orthologues=[% merge_orthologues %][% IF merge_orthologues == 'on' %] --merge_min_ident=[% merge_min_ident %] --merge_min_len=[% merge_min_len %][%- END %] \
--aligner_mode=[% aligner_mode %][% UNLESS aligner_mode == 'off' %] --ali_skip_self=[% ali_skip_self %] --ali_cover_mul=[% ali_cover_mul %][% END %] --ali_keep_old_new_tags=[% ali_keep_old_new_tags %] --ali_keep_lengthened_seqs=[% ali_keep_lengthened_seqs %] \
--tax_reports=[% tax_reports %][% IF tax_dir %] --tax_dir [% tax_dir %][% END %] \
[% IF megan_like %]--megan_like \[% ELSIF best_hit %]--best_hit \[% ELSE %]--tax_min_score=[% tax_min_score %] --tax_score_mul=[% tax_score_mul %] --tax_min_ident=[% tax_min_ident %] --tax_min_len=[% tax_min_len %] \[% END %]
--tol_check=[% tol_check %][% IF tol_check == 'on' %] --tol_db [% tol_db %][% END %][% IF levels %] \
--levels=[% levels.join(' ') %][%- END %]
EOT

# HOW TO
my $howto = << "EOT";

\e[1;35m============================== Prompting: How To? ==============================

You may use the following control keys for manual input and menu input:\e[0m
    ENTER    yes/default value
    CTRL-C   quit

\e[1;35mYou may use the following control keys for path input:\e[0m
    TAB      complete the word
    CTRL-D   show list of matching choices (same as TAB-TAB)
    CTRL-U   delete the entire input
    CTRL-H   delete a character (backspace)
    CTRL-P   cycle through choices (backward) (also up arrow)
    CTRL-N   cycle through choices (forward) (also down arrow)

\e[1;35m================================================================================
EOT

die "Error: No arguments provided!
Use the '--wizard' for a guided configuration or define at least the following variables: '--bank_dir' '--bank_suffix' '--queries'"
unless
    List::AllUtils::all { defined $ARGV{$_} } qw(--bank_dir --bank_suffix --queries)
    or   defined $ARGV{'--wizard'};

my $tf_auto;
if ( $ARGV{'--wizard'} ) {
    # HOW TO
    say $howto;

    # CONTEXT
    $ARGV{'--run_mode'} = prompt "\nWhich mode would you like to run Forty-Two: ",
        -menu => { 'phylogenomic' => 'phylogenomic', 'metagenomic' => 'metagenomic' },
        '>';

    # OUT_SUFFIX
    $ARGV{'--out_suffix'} = prompt "\nSuffix to append to infile basenames for deriving outfile names [default: -42]: ",
    -def => $ARGV{'--out_suffix'};

    # QUERIES
    $ARGV{'--queries'} = prompt4file("\nEnter path to query organisms list file: ");

    # ALI TYPE
    $ARGV{'--SSUrRNA'} = prompt "\nWould you like to enrich SSU rRNA alignments?", -menu => { Yes => 1, no => 0 }, -def => 0;
    $ARGV{'--ref_brh'} = 'off' if $ARGV{'--SSUrRNA'};

    # BLASTS
    $ARGV{'--evalue'} = prompt "\nSet e-value for all blasts performed by 42 [default: 1e-05]: ",
    -def => $ARGV{'--evalue'};


    unless ( $ARGV{'--SSUrRNA'} ) {

        # REF BANKS
        $ARGV{'--ref_brh'} = prompt "\nWould you like to use a ref_brh: ",
            -menu => { 'on [default]' => $ARGV{'--ref_brh'}, off => 'off'},
            -def => $ARGV{'--ref_brh'},
            '>';

        unless ( $ARGV{'--ref_brh'} eq 'off' ) {
            $ARGV{'--ref_bank_dir'}    = prompt4dir("\nEnter path to reference organisms banks directory: ");
            $ARGV{'--ref_bank_suffix'} = prompt4suffix("\nSet reference banks suffix: ", $ARGV{'--ref_bank_dir'});
            $ARGV{'--ref_bank_mapper'} = prompt4file("\nEnter path to reference bank mapper file: ");

            $ARGV{'--ref_org_mul'} = prompt "\nSet ref org mul [default: 1.0]: ",
                -must => { 'be a number between 0 and 1' => qr{^[0-1](?:\.\d+)?}xms },
                -def => $ARGV{'--ref_org_mul'};

            $ARGV{'--ref_score_mul'} = prompt "\nSet ref score mul [default: 0.99]: ",
            -must => { 'be a number between 0 and 1' => qr{^[0-1](?:\.\d+)?}xms },
            -def  => $ARGV{'--ref_score_mul'};
        }

        my $tax_filter;

        # TreeOfLIfe CHECK
        $ARGV{'--tol_check'} = prompt "\nDo you need to perform the Tree Of Life check before adding an ortholog?",
            -menu => { 'yes' => 'on', 'no [default]' => 'off'},
            -def => $ARGV{'--tol_check'},
            '>';
        if ($ARGV{'--tol_check'} eq 'on') {
            $tax_filter = 1;
            $ARGV{'--tol_db'}   = prompt4dir("\nEnter path to TreeOfLife database: ");

            $tf_auto = prompt "\nSet tax filter input: ",
                -menu =>  { 'from org mapper file' => 0,
                            "from NCBI's taxonomy - auto + prompt for missing" => 1,
                            "from NCBI's taxonomy - auto + prompt for all" => 2,
                          };
            if ( $tf_auto == 1 ) {
                @{ $ARGV{'--levels'} } = split ",", ( prompt "\nLevels separated by a coma (no whitespace): ");
            }
        }

        # TRIMMING HOMOLOGUES
        $ARGV{'--trim_homologues'} = prompt "\nChoose trim_homologues mode: ",
            -menu => { 'on [default]' => $ARGV{'--trim_homologues'}, off => 'off' }, '>',
            -def => $ARGV{'--trim_homologues'};

        unless ( $ARGV{'--trim_homologues'} eq 'off' ) {
            $ARGV{'--trim_max_shift'   } = prompt "\nSet trim_max_shift: ", -def => $ARGV{'--trim_max_shift'};
            $ARGV{'--trim_extra_margin'} = prompt "\nSet trim_extra_margin: ", -def => $ARGV{'--trim_extra_margin'};
        }

        # MERGING ORTHOLOGUES
        $ARGV{'--merge_orthologues'} = prompt "\nChoose merge_orthologues mode: ",
            -menu => { on => 'on', 'off [default]' => $ARGV{'--merge_orthologues'} }, '>',
            -def => $ARGV{'--merge_orthologues'};

        unless ( $ARGV{'--merge_orthologues'} eq 'off' ) {
            $ARGV{'--merge_min_ident' } = prompt "\nSet merge_min_ident: ", -def => $ARGV{'--merge_min_ident'};
            $ARGV{'--merge_min_len'   } = prompt "\nSet merge_min_len: ", -def => $ARGV{'--merge_min_len'};
        }

        # ali_keep_lengthened_seqs
        $ARGV{'--ali_keep_lengthened_seqs'} = prompt "\nAction to perform when a preexisting lengthened seq is identified: ",
            -menu => { 'keep [default]' => 'keep', remove => 'remove' },
            -def => $ARGV{'--ali_keep_lengthened_seqs'}, '>';

        if ($ARGV{'--run_mode'} eq 'phylogenomic') {

            # ALIGNER
            $ARGV{'--tax_reports'} = 'on';

            $ARGV{'--aligner_mode'} = prompt "\nSet aligner_mode: ",
                -menu => { 'blast [default]' => $ARGV{'--aligner_mode'},
                            exonerate => 'exonerate',
                            exoblast => 'exoblast',
                            off => 'off'
                         },
                -def => $ARGV{'--aligner_mode'},
                '>';


            # ali_skip_self
            $ARGV{'--ali_skip_self'} = prompt "\nSet patch mode: ",
                -menu => { 'off [default]' => $ARGV{'--ali_skip_self'}, on => 'on' },
                -def => $ARGV{'--ali_skip_self'}, '>';

            # TAXONOMIC FILTER
            unless ($tax_filter) {
                $tax_filter = prompt "\nIs a taxonomic filter needed?", -menu => { Yes => 1, no => 0 };

                if ($tax_filter) {
                    $tf_auto = prompt "\nSet tax filter input: ",
                        -menu =>  { 'from org mapper file' => 0,
                                    "from NCBI's taxonomy - auto + prompt for missing" => 1,
                                    "from NCBI's taxonomy - auto + prompt for all" => 2,
                                  };

                    if ( $tf_auto == 1 ) {
                        @{ $ARGV{'--levels'} } = split ",", ( prompt "\nLevels separated by a coma (no whitespace): ");
                    }
                }

                # TAXNOMIC AFFILIATION
                $tax_filter = prompt "\nIs taxonomic classification needed?", -menu => { Yes => 1, no => 0 };
            }
        }

        else {
            $ARGV{'--tax_reports'} = 'on';
            $ARGV{'--aligner_mode'} = 'off';
            $ARGV{'--merge_orthologues'} = 'off';
        }

        if ($ARGV{'--run_mode'} eq 'metagenomic' || $tax_filter) {

            # TAX DIR
            $ARGV{'--tax_dir'} = prompt4dir("\nEnter path to taxdump directory: ");

            my $tax_aff = prompt "\nChoose taxonomic affiliation mode: ",
                -menu => { 'megan-like' => '--megan_like', 'best-hit' => '--best_hit' },
                -def => 1;
            $ARGV{"$tax_aff"} = 1;

            # BEST_HIT
            if ( $ARGV{'--best_hit'} ) {
                say "The '--best_hit' flag autosets the following parameter:\n'--tax_max_hits' = 1";
                $ARGV{'--tax_max_hits'} = 1;

                my $hit_filtering = prompt "\nSet hit-filtering mode: ",
                    -menu => { 'default values' => 0, 'length/identity' => 'length_identity', 'Bit score' => 'bitscore' };

                if ($hit_filtering eq 'bitscore') {
                    $ARGV{'--tax_min_score'} = prompt "\nSet minimum bit score to consider a hit: ",
                        -must => { 'be an integer' => qr{^[0-9]+\z} },
                        -def  => $ARGV{'--tax_min_score'};
                }
                if ($hit_filtering eq 'length_identity') {
                    $ARGV{'--tax_min_ident'} = prompt "\nSet minimum percentage of identity to consider a hit: ",
                        -must => { 'be a number between 0 and 1' => qr{^[0-1](?:\.\d+)?}xms },
                        -def  => $ARGV{'--tax_min_ident'};

                    $ARGV{'--tax_min_len'} = prompt "\nSet minimum length to consider a hit: ",
                        -must => { 'be an integer' => qr{^[1-9]+} },
                        -def  => $ARGV{'--tax_min_len'};
                }
            }

            # MEGAN_LIKE
            if ($ARGV{'--megan_like'}) {
                say "\nThe '--megan_like' flag autosets the following parameters:\n'--tax_min_score' = 80,\n'--tax_score_mul' = 0.95,\n'--tax_min_ident' = 0,\n'--tax_min_len' = 0.";
                say "\nFeel free to modify the default settings according to your own flavors.";

                $ARGV{'--tax_min_ident'} = 0;
                $ARGV{'--tax_min_len'}   = 0;
                $ARGV{'--tax_min_score'} = 80;
                $ARGV{'--tax_score_mul'} = 0.95;
            }
        }
    }

    # BANKS
    $ARGV{'--bank_dir'}    = prompt4dir("\nEnter path to your candidate genomes directory: ");
    $ARGV{'--bank_suffix'} = prompt4suffix("\nSet candiate banks suffix: ", $ARGV{'--bank_dir'});
    $ARGV{'--bank_mapper'} = prompt4file("\nEnter path to bank mapper file: ");

    # CODE
    $ARGV{'--code'} = prompt "\nGenetic code for translated BLAST searches [default: 1]: ",
    -must => { 'be an integer' => qr{^[1-9]+} },
    -def => $ARGV{'--code'};

}

### %ARGV

# tol arguments
if ( $ARGV{'--tol_db'} ) {
    my $file = Path::Class::File->new($ARGV{'--tol_db'});
    $ARGV{'--tol_bank'}     = $file->basename;
    $ARGV{'--tol_bank_dir'} = $file->dir->absolute->stringify;
}

# convert arguments to values for placeholders
my %vars = map { tr/-<>//dr => $ARGV{$_} } keys %ARGV;

# bank files
my @bank_files = File::Find::Rule
    ->file()
    ->relative()
    ->maxdepth(1)
    ->name( qr{ $ARGV{'--bank_suffix'} $}xmsi )
    ->in($ARGV{'--bank_dir'})
;
# org mapper: from file names or file
$ARGV{'--choose_tax_filter'} = 1 if $ARGV{'--levels'};
$tf_auto = $ARGV{'--choose_tax_filter'};
my $tax = Taxonomy->new_from_cache( tax_dir => $ARGV{'--tax_dir'} ) if $tf_auto > 0;
### lvl: $ARGV{'--levels'}

my ($org_for, $tax_filter_for) = build_org_n_tax_filter_for();
### $org_for
### $tax_filter_for

# ref_bank files
my $ref_org_for;
my @ref_bank_files;
unless ( $ARGV{'--ref_brh'} eq 'off' ) {
    @ref_bank_files = File::Find::Rule
        ->file()
        ->relative()
        ->maxdepth(1)
        ->name( qr{ $ARGV{'--ref_bank_suffix'} $}xmsi )
        ->in($ARGV{'--ref_bank_dir'})
    ;
    # ref org mapper: from file names or file
    $ref_org_for = build_ref_org_for();
}

# queries
my @query_orgs;
open my $in, '<', $ARGV{'--queries'};
while (my $line = <$in>) {
    chomp $line;
    push @query_orgs, $line;
}
close $in;

# complete %vars
$vars{org_for}        = $org_for;
$vars{query_orgs}     = \@query_orgs;
$vars{ref_org_for}    = $ref_org_for if $ref_org_for;
$vars{tax_filter_for} = $tax_filter_for if $tax_filter_for;
### %vars

# build config filename
my $out_suffix = $ARGV{'--out_suffix'} =~ m/^\-/xms ? $ARGV{'--out_suffix'} : '-' . $ARGV{'--out_suffix'};
my $outyaml    = 'config' . $out_suffix . '.yaml';
my $outcmd     = 'build' . $out_suffix . '-yaml.sh';

# fill-in template
my $tt = Template->new;
$tt->process(\$tt_str, \%vars, $outyaml) or die "Unable to write $outyaml";
$tt->process(\$tt_cmd, \%vars, $outcmd ) or die "Unable to write $outcmd";
# Set read only
#my $mode = "0444";
#chmod $mode, $outyaml;
#chmod $mode, $outcmd;

say "\nSuccessfully wrote files: $outyaml and $outcmd!";

# SUBROUTINES

sub prompt4dir {
    return _prompt4path(\&dir, @_);
}


sub prompt4file {
    return _prompt4path(\&file, @_);
}

sub _prompt4path {
    my $sub    = shift;
    my $string = shift;
       $string = "\e[1;34m$string\e[0m";
    my $path;
    my $areyousure = 0;
    my $tc = Term::Completion::Path->new(
        prompt  => $string,
    );
    while ( $areyousure == 0 ) {
        $path = '' unless $areyousure;
        until (-e $path) {
            $path = $tc->complete();
            say "No such file or directory '$path'. Try again..." unless -e $path;
        }
        $path = $sub->($path)->absolute->resolve->stringify unless $ARGV{'--relative'};
        $areyousure = prompt "\nIs that correct: $path ? ", -menu => { Yes => 1, no => 0 }, -def => 1, -style => 'blue';
    }
    return $path;
}


sub prompt4suffix {
    my $string = shift;
    my $dir    = shift;
    my $areyousure = 0;
    my $suffix;

    while ( $areyousure == 0 ) {
        $suffix = prompt $string;
        say "\n\e[0;33mFiles in directory: ";
        system("ls $dir/*$suffix | xargs -n1 basename");
        $areyousure = prompt "\nIs that correct: $suffix ? ",
                                -menu => { Yes => 1, no => 0 },
                                -def => 1, -style => 'blue';
    }
    return $suffix;
}

sub build_ref_org_for {
    my %ref_org_for;
    if ($ARGV{'--ref_bank_mapper'}) {
        open my $in, '<', $ARGV{'--ref_bank_mapper'};
        while (my $line = <$in>) {
            chomp $line;
            next LINE if $line =~ $COMMENT_LINE
                      || $line =~ $EMPTY_LINE;
            $line =~ s/\s+$//xmsg;
            my ($ref_org, $ref_bank) = split /\t/xms, $line;
            ### $ref_bank
            ### $ref_org
            $ref_bank                = basename($ref_bank, $ARGV{'--ref_bank_suffix'});
            $ref_org_for{$ref_bank}  = $ref_org;
        }
        close $in;
    }
    else {
        my @ref_banks = map { basename($_, $ARGV{'--ref_bank_suffix'}) } @ref_bank_files;
        my @ref_orgs  = map { join " ", (split /_/xms, $_, 2)     } @ref_banks;
        @ref_org_for{@ref_banks} = @ref_orgs;
    }
    return \%ref_org_for;
}

sub build_org_n_tax_filter_for {
    my %org_for;
    my %tax_filter_for;
    if ($ARGV{'--bank_mapper'}) {
        open my $in, '<', $ARGV{'--bank_mapper'};
        while (my $line = <$in>) {
            chomp $line;
            my ($bank, $org, $tax_filters, $lineage);
            if ($tf_auto > 0) {
                ($org, $bank, undef, undef) = split /\t/xms, $line;
                ($tax_filters, $lineage) = _get_tax_filter($org);
            }
            else {
                ($org, $bank, $tax_filters, $lineage) = split /\t/xms, $line;
            }

            $bank                  = basename($bank, $ARGV{'--bank_suffix'});
            $org_for{$bank}        = $org;
            $tax_filter_for{$bank} = "tax_filter: [ $tax_filters ] # " . $lineage if defined $tax_filters;
        }
        close $in;
    }
    else {
        my @banks = map { basename($_, $ARGV{'--bank_suffix'}) } @bank_files;
        ### @banks
        my @orgs  = map { join q{ }, (split /_/xms, $_, 2) } @banks;
        @org_for{@banks} = @orgs;
    }
    return \%org_for, \%tax_filter_for;
}

sub _get_tax_filter {
    my $org = shift;

    my $entity;
    my $method;
    my $lineage;
    if ($org =~ m/^GCA|GCF/xms || $org =~ m/^\d+$/xms) {
        $entity = $org;
        $method = 'get_taxonomy_with_levels';
        ### TID/GCA: $entity
    }
    else {
        $entity = SeqId->new( full_id => $org . '@1');
        $method = 'get_taxonomy_with_levels_from_seq_id';
        ### ORG: $entity
    }
    my @tax = $tax->$method($entity);
    $lineage = join q{; }, map { @{ $tax[$_] }[0] } 0..$#tax;
    ### $lineage

    # Type a name untill it works!
    my $loop;
    while (! @tax) {
        $loop++;
        say "Warning: Unable to retrieve taxonomy for $org.\n"; #TODO
        say "Try with '$org" . "_sp'" if $loop > 1;

        $org = prompt "Please enter a valid species name or taxonomic rank followed by '_sp'...\n", '>';
        my $seq_id = SeqId->new( full_id => $org.'@1');
        @tax = $tax->$method($seq_id);
        $lineage = join q{; }, map { @{ $tax[$_] }[0] } 0..$#tax;
    }

    tie my %tax_for, 'Tie::IxHash';
    for my $tax_n_level (@tax) {
        $tax_for{$$tax_n_level[1]} = $$tax_n_level[0];
    }

    my $tax_filter;
    if ($tf_auto == 1) {
        LEVEL:
        for my $level (@{ $ARGV{'--levels'} }) {
            $tax_filter = $tax_for{$level};
            last LEVEL if defined $tax_filter;
        }
        return '+' . $tax_filter, $lineage if defined $tax_filter;
    }

    unless (defined $tax_filter) {
        say "\nWarning: no taxon defined for level(s): @{ $ARGV{'--levels'} }";
    }

    $tax_filter = '+' . _tax_prompter(\@tax, $org);

    return $tax_filter, $lineage;
}

sub _tax_prompter {
    my ($tax_ref, $org) = @_;
    my @tax = map { @$_[0] } @$tax_ref;
    my $tax_filter = prompt "\nChoose tax_filter for '$org':",
    -menu => \@tax,
    '>';
    return $tax_filter;
}

__END__

=pod

=head1 NAME

yaml-generator-42.pl - Interactive or batch generator for 42 YAML config files

=head1 VERSION

version 0.210370

=head1 USAGE

    # wizard: configuration assistant
    ./yaml-generator-42.pl --wizard

    # basic: derive organisms name directly from filenames
    ./yaml-generator-42.pl --bank_dir ./banks/ --ref_bank_dir ./ref_banks/ \
    --tax_dir ~/taxdump/ --bank_suffix=.nsq --ref_bank_suffix=.psq \
    --queries queries.idl [optional arguments]

    # use IDM files for banks, orgs and eventually tax_filters
    ./yaml-generator-42.pl --bank_dir ./banks/ --ref_bank_dir ./ref_banks/ --tax_dir  \
    ~/taxdump/ --bank_suffix=.nsq --ref_bank_suffix=.psq --queries queries.idl  \
    --bank_mapper banks/bank_mapper.idm  \
    --ref_bank_mapper ref_banks/ref_bank_mapper.idm

    # dynamic choice of tax_filter using NCBI Taxonomy
    ./yaml-generator-42.pl --bank_dir ./banks/ --ref_bank_dir ./ref_banks/ --tax_dir  \
    ~/taxdump/ --bank_suffix=.nsq --ref_bank_suffix=.psq --queries queries.idl  \
    --bank_mapper banks/bank_mapper.idm  \
    --ref_bank_mapper ref_banks/ref_bank_mapper.idm \
    --levels=family

    # interactive choice of tax_filter using NCBI Taxonomy
    ./yaml-generator-42.pl --bank_dir ./banks/ --ref_bank_dir ./ref_banks/ --tax_dir  \
    ~/taxdump/ --bank_suffix=.nsq --ref_bank_suffix=.psq --queries queries.idl  \
    --bank_mapper banks/bank_mapper.idm  \
    --ref_bank_mapper ref_banks/ref_bank_mapper.idm \
    --levels=family --choose_tax_filter

=head1 REQUIRED ARGUMENTS

=over

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --wizard

Activate if you want an interactive step by step configuration.

=item --run_mode=<str>

'phylogenomic' or 'metagenomic'

=for Euclid: str.type: str

=item --out_suffix=<str>

=for Euclid: str.type: str
	str.default: '-42'

=item --queries <file>

=for Euclid: file.type: readable

=item --evalue=<n>

=for Euclid: n.type: number
    n.default: 1e-5

=item --SSUrRNA

=item --homologues_seg=<str>

=for Euclid: str.type: str
	str.default: 'yes'

=item --max_target_seqs=<str>

=for Euclid: str.type: str
	str.default: 10000

=item --templates_seg=<str>

=for Euclid: str.type: str
	str.default: 'no'

=item --ref_brh=<str>

on or off.

=for Euclid: str.type: str
	str.default: 'on'

=item --ref_bank_dir <dir>

Path to reference bank files directory.

=for Euclid: dir.type: readable

=item --ref_bank_suffix=<str>

=for Euclid: str.type: str

=item --ref_bank_mapper <file>

Tab delimited file with bank and org in this order.

=for Euclid: file.type: readable

=item --ref_org_mul=<n>

=for Euclid: n.type: number, n > 0 && n <= 1
    n.default: 1.0

=item --ref_score_mul=<n>

=for Euclid: n.type: number, n >= 0 && n <= 1
    n.default: 0.99

=item --tol_check=<str>

=for Euclid: str.type: str
    str.default: 'off'

=item --tol_db <db>

Path to TreeOfLife database.

=for Euclid: db.type: string

=item --trim_homologues=<str>

=for Euclid: str.type: str
    str.default: 'on'

=item --trim_max_shift=<n>

=for Euclid: n.type: 0+number
    n.default: 20000

=item --trim_extra_margin=<n>

=for Euclid: n.type: 0+number
    n.default: 15

=item --merge_orthologues=<str>

=for Euclid: str.type: str
    str.default: 'off'

=item --merge_min_ident=<n>

=for Euclid: n.type: number, n >= 0 && n <= 1
    n.default: 0.9

=item --merge_min_len=<n>

=for Euclid: n.type: 0+number
    n.default: 40

=item --aligner_mode=<str>

off, blast, exonerate, exoblast.

=for Euclid: str.type: str
	str.default: 'blast'

=item --ali_skip_self=<str>

on or off

=for Euclid: str.type: str
	str.default: 'off'

=item --ali_cover_mul=<n>

=for Euclid: n.type: number, n > 0 && n <= 2
    n.default: 1.1

=item --ali_keep_old_new_tags=<str>

'on' or 'off'

=for Euclid: str.type: str
    str.default: 'off'

=item --bank_dir <dir>

Path to bank files directory.

=for Euclid: dir.type: readable

=item --bank_suffix=<str>

=for Euclid: str.type: str

=item --bank_mapper <file>

Tab delimited file with bank, org and optionnaly tax_filter in this order.

=for Euclid: file.type: readable

=item --tax_dir <dir>

Path to taxdump directory.

=for Euclid: dir.type: readable

=item --levels=<level>...

Taxonomic filter level(s). Several levels are allowed as input; in this case,
the first defined level will be returned.

Available levels are: 'superkingdom'
                      'kingdom'
                      'phylum'
                      'subphylum'
                      'class'
                      'superorder'
                      'order'
                      'suborder'
                      'infraorder'
                      'parvorder'
                      'superfamily'
                      'family'
                      'subfamily'
                      'genus'
                      'species'

=for Euclid: level.type: string

=item --choose_tax_filter=<n>

Interactively choose taxonomic filter.
0 => 'from org mapper file'
1 => "from NCBI's taxonomy - auto + prompt for missing"
2 => "from NCBI's taxonomy - auto + prompt for all"

=for Euclid: n.type: 0+integer
    n.default: 0

=item --tax_reports=<str>

'on' or 'off'

=for Euclid: str.type: str
    str.default: 'on'

=item --best_hit

Overides 'tax_' parameters and auto-sets 'tax_score_mul' to compute LCA in a
MEGAN-like mode i.e. based on bitscore.

=item --megan_like

Overides 'tax_' parameters and auto-sets 'tax_score_mul' to compute LCA in a
MEGAN-like mode i.e. based on bitscore.

=item --tax_max_hits=<n>

=for Euclid: n.type: 0+integer

=item --tax_min_hits=<n>

=for Euclid: n.type: 0+integer

=item --tax_min_ident=<n>

=for Euclid: n.type: number, n >= 0 && n <= 1
    n.default: 0

=item --tax_min_len=<n>

=for Euclid: n.type: 0+integer
    n.default: 0

=item --tax_min_score=<n>

=for Euclid: n.type: 0+integer
    n.default: 0

=item --tax_score_mul=<n>

=for Euclid: n.type: number, n >= 0 && n <= 1
    n.default: 0

=item --ali_keep_lengthened_seqs=<str>

keep or remove

=for Euclid: str.type: str
	str.default: 'keep'

=item --code=<n>

=for Euclid: n.type: +integer
	n.default: 1

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Mick VAN VLIERBERGHE

Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
