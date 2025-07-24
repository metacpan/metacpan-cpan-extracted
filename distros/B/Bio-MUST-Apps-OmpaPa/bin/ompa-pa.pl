#!/usr/bin/env perl
# PODNAME: ompa-pa.pl
# ABSTRACT: Extract seqs from BLAST/HMMER interactively or in batch mode
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>

use Modern::Perl '2011';
use autodie;

use Config::Any;
use Getopt::Euclid qw(:vars);
use Smart::Comments;

use IO::Prompter [
    -verbatim,
    -style => 'blue strong',
    -must  => { 'be a string' => qr{\S+}xms }
];

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::Ali::Stash';
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::Taxonomy';
use aliased 'Bio::MUST::Core::Taxonomy::ColorScheme';
use aliased 'Bio::MUST::Apps::OmpaPa::Parameters';
use aliased 'Bio::MUST::Apps::OmpaPa::Blast';
use aliased 'Bio::MUST::Apps::OmpaPa::Hmmer';

# TODO: re-implement BLAST parsing and nr extraction; done?

die <<'EOT' if !$ARGV_database && $ARGV_extract_seqs;
Missing required arguments:
    --database=<file>
EOT

die <<'EOT' if !$ARGV_taxdir && ($ARGV_skip_config || $ARGV_colorize || $ARGV_extract_tax);
Missing required arguments:
    --taxdir=<dir>
EOT

# setup OmpaPa sub-class based on report type
my $class = $ARGV_report_type eq 'blastxml' ? Blast : Hmmer;

# setup Taxonomy-related objects
my $scheme;
my $skip_classifier;
if ($ARGV_taxdir) {
    my $tax = Taxonomy->new_from_cache( tax_dir => $ARGV_taxdir );
    $scheme = $ARGV_colorize ? $tax->load_color_scheme($ARGV_colorize)
            : ColorScheme->new(
                   tax => $tax,
                 names => [ qw(Archaea Bacteria Eukaryota Viruses) ],
                colors => [ qw(   blue    green       red  orange) ],
            )
    ;

    if ($ARGV_skip_config) {
        # read configuration file
        my $skip_config = Config::Any->load_files( {
            files           => [ $ARGV_skip_config ],
            flatten_to_hash => 1,
            use_ext         => 1,
        } );
        ### skip_config: $skip_config->{$ARGV_skip_config}
        $skip_classifier
            = $tax->tax_classifier( $skip_config->{$ARGV_skip_config} );
    }
}

# build args hash for Bio::MUST::Apps::OmpaPa::XXX constructor
my %args;
$args{gnuplot_term}        = $ARGV_gnuplot_term;
$args{database}            = $ARGV_database   if $ARGV_database;
$args{extract_seqs}        = 1                if $ARGV_extract_seqs;
$args{extract_taxs}        = 1                if $ARGV_extract_tax;
$args{restore_last_params} = 1                if $ARGV_restore_last_params;
$args{scheme}              = $scheme          if $scheme;

### Silencing most Taxonomy-related warnings to reduce interactive clutter
local $SIG{__WARN__} = Taxonomy->no_warnings;

# process infiles
FILE:
for my $infile (@ARGV_infiles) {
    ### Processing: $infile

    # enforce precedence order for Parameters (supercede class defaults)
    if ($ARGV_restore_last_params) {
        delete $args{parameters};
    }
    elsif ($ARGV_restore_params_from) {
        $args{parameters} = $ARGV_restore_params_from;
    }
    else {
        $args{parameters} = Parameters->new(
            max_hits => $ARGV_max_hits,
            max_copy => $ARGV_max_copy,
             min_cov => $ARGV_min_cov,
        );
    }

    # read and parse report
    my $oum = $class->new( %args, file => $infile );
    say '[' . $oum->count_hits . ' hits processed] ';

    # optionally skip report
    if ($skip_classifier) {

        # extract all hit ids
        my @hits = map { $_->{acc} } $oum->all_hits;
        my $listable = IdList->new( ids => \@hits );

        # classify report
        my $cat_label = $skip_classifier->classify($listable);
        if ($cat_label) {
            ### Skipping report: "$infile | $cat_label"
            next FILE;
        }
    }

    if ($ARGV_print_plots) {
        my $suf = 'before';
        my $all = 'Y';

        ### print graph with all hits and with all possible colorations...
        $oum->print_plot( $suf, $all );
    }

    # BATCH MODE
    if ($ARGV_restore_params_from) {
        say q{Here's the selection based on restored parameters...};
        say $oum->list_selection('all');
        say '[' . $oum->count_selection . ' hits selected] ';
        say '[' . $oum->count_filter . ' hits selected after filtering] ';
    }

    elsif ($ARGV_restore_last_params) {
        say q{Here's the selection based on restored parameters...};
        say $oum->list_selection('keep');
        say '[' . $oum->count_filter . ' hits selected after filtering] ';
    }

    # INTERACTIVE MODE
    else {

        # repeat until user's confirmation of selected bounds
        my $ans;
        do {
            $oum->change_filter if $ans;
            $oum->select_bounds;

            say q{Here's your current selection...};
            say $oum->list_selection('all');
            say '[' . $oum->count_selection . ' hits selected] ';
            say '[' . $oum->count_filter . ' hits selected after filtering] ';
            say 'Threshold for minimum coverage: ' . $oum->min_cov;
            say 'Threshold for maximum gene copy number: ' . $oum->max_copy;

            my $opt = prompt 'Do you want to see the filtered selection?',
                -def => 'Y';
            say $oum->list_selection('keep') if uc $opt eq 'Y';

            $ans = prompt 'Are you satisfied with your current selection?',
                -def => 'Y';
        } until uc $ans eq 'Y';
    }

    if ($ARGV_print_plots) {
        my $suf = 'after';

        ### print graphical selection with all possible colorations...
        $oum->print_plot($suf);
    }

    # write accession file corresponding to current selection
    $oum->save_selection;
}

__END__

=pod

=head1 NAME

ompa-pa.pl - Extract seqs from BLAST/HMMER interactively or in batch mode

=head1 VERSION

version 0.252040

=head1 USAGE

    ompa-pa.pl <infiles> --database=<file> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input BLAST/HMMER report files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --report-type=<str>

Type of the reports used as infiles [default: blastxml]. Currently, the
following types are available:

    - blastxml (XML BLAST reports generated with -outfmt 5)
    - hmmertbl (tabular HMMER reports generated with -domtblout)

=for Euclid: str.type:       /blastxml|hmmertbl/
    str.type.error: <str> must be one of blastxml or hmmertbl (not str)
    str.default:    'blastxml'

=item --database=<file>

Path to the sequence database used to generate the reports. For efficiency,
this argument must always be the basename of a BLAST database, even when the
reports where obtained using C<hmmsearch> on a FASTA file.

To build such a database, use one of the following commands:

    $ makeblastdb -in database.fasta -out database -dbtype prot -parse_seqids
    $ makeblastdb -in database.fasta -out database -dbtype nucl -parse_seqids

This argument is required when the option C<--extract-seqs> is enabled.

=for Euclid: file.type: string

=item --skip-config=<file>

Path to an optional configuration file specifying the reports to skip based on
their raw taxonomic content [default: none]. The assessment is made before any
filtering other than C<--max-hits>.

The configuration file follows the classifier format (often YAML) of
<classify-ali.pl>. This requires enabling taxonomic annotation and thus a
local mirror of the NCBI Taxonomy database

=for Euclid: file.type: readable

=item --colorize=<scheme>

When specified, sequence points are colored after their taxon using the
specified CLS file. As above, this requires enabling taxonomic annotation and
thus a local mirror of the NCBI Taxonomy database.

=for Euclid: scheme.type: readable

=item --taxdir=<dir>

Path to local mirror of the NCBI Taxonomy database.

To build such a directory, use the following command:

    $ setup-taxdir.pl --taxdir=taxdir

=for Euclid: dir.type: string

=item --max-hits=<n>

Maximum number of hits to read from the report [default: 200000]. This limit
is implemented for efficiency. It applies before any other filter.

=for Euclid: n.type:    0+integer
    n.default: 200000

=item --min-cov=<n>

Minimum BLAST query or HMMER model coverage for selected hits [default: 0.7].

=for Euclid: n.type:    num
    n.default: 0.7

=item --max-copy=<n>

Maximum gene copy number per organism for selected hits [default: 3].

=for Euclid: n.type:    0+integer
    n.default: 3

=item --extract-seqs

Sequence extraction switch [default: no]. When specified, selected sequences
are stored into a FASTA file using the same basename as other output files.
This requires a BLAST database (see option C<--database> above).

=item --extract-tax

Taxonomy extraction switch [default: no]. When specified, NCBI taxons of
selected sequences are stored into a file using the same basename as other
output files. This requires a local mirror of the NCBI Taxonomy database.

=item --restore-params-from=<file>

Batch-mode switch [default: no]. When specified, parameters are restored from
the user-specified JSON file. This option takes precedence on any command-line
specified option, such as C<--max-hits>, C<--min-cov> and C<--max-copy>.

=for Euclid: file.type: string

=item --restore-last-params

Batch-mode switch [default: no]. When specified, parameters are restored from
the last saved JSON file for each report. This option takes precedence over
all other command-line options.

=item --print-plots

When specified, plots are printed in PDF format [default: no].

=item --gnuplot-term=<str>

gnuplot terminal to use for the interactive mode [default: x11]. Other
possible choices include qt but the option is open to experiment. On macOS,
to avoid the font warning, use C<--gnuplot-term='qt font "Arial"'>.

If needed the gnuplot executable can be specified through the environment
variable C<OUM_GNUPLOT_EXEC>.

=for Euclid: str.type:    string
    str.default: 'x11'

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Amandine BERTRAND

Amandine BERTRAND <amandine.bertrand@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
