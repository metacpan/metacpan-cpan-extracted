#!/usr/bin/env perl
# PODNAME: debrief-42.pl
# ABSTRACT: Summarize the results of a 42 metagenomic run
# CONTRIBUTOR: Mick VAN VLIERBERGHE <mvanvlierberghe@doct.ulg.ac.be>

use autodie;
use Modern::Perl '2011';

use Getopt::Euclid qw(:vars);

use File::Basename;
use File::Find::Rule;
use List::AllUtils qw(uniq);
use Path::Class qw(dir file);
use Tie::IxHash;

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::Taxonomy';
use aliased 'Bio::MUST::Apps::Debrief42::TaxReport';


## no critic (RequireLocalizedPunctuationVars)
BEGIN{
    $ENV{Smart_Comments} = $ARGV_verbosity
        ? join q{ }, map { '#' x (2 + $_) } 1..$ARGV_verbosity
        : q{}
    ;
}
use Smart::Comments -ENV;


die <<'EOT' if !$ARGV_taxdir && ($ARGV_seq_labeling || $ARGV_contam_labeling);
Missing required arguments:
    --taxdir=<dir>
EOT

# optionally build taxonomy object
my $tax;
if ($ARGV_taxdir) {
    $tax = Taxonomy->new_from_cache( tax_dir => $ARGV_taxdir );
}

# optionally build classifier objects
my ($seq_classifier, $contam_classifier);
if ($ARGV_seq_labeling) {
    my    $seq_labeling_list = IdList->load($ARGV_seq_labeling);
       $seq_classifier = $tax->tax_labeler_from_list($seq_labeling_list);
}
if ($ARGV_contam_labeling) {
    my $contam_labeling_list = IdList->load($ARGV_contam_labeling);
    $contam_classifier = $tax->tax_labeler_from_list($contam_labeling_list);
}

### Processing: $ARGV_indir
my @tax_reports = File::Find::Rule
    ->file()
    ->name( qr{ $ARGV_in_strip \.tax-report\z}xmsi )
    ->maxdepth(1)
    ->in($ARGV_indir)
;
my $ali_test = @tax_reports;
#### @tax_reports

# TODO: rewrap long lines (>80 chars)
my %data_for;

### Processing tax-reports...
for my $report (@tax_reports) {
    ### Processing: $report

    # Loading file as a TaxReport object
    my $tax_report = TaxReport->new( file => file($report) );
    #### $tax_report

    # Deriving MSA/OG basename
    $report   =~ s/$ARGV_in_strip//xms;
    my ($ali) = fileparse($report, qr{\.[^.]*}xms);
    #### $ali

    NEWSEQ:
    while ( my $new_seq = $tax_report->next_seq ) {

        next NEWSEQ unless $new_seq->lca || $new_seq->lineage;
        my $full_id = $new_seq->seq_id;
           $full_id =~ s/(GC[AF])\s/$1_/xms;
        my $seq_id = SeqId->new(full_id => $full_id);

        # TODO: check that literal strings are still up-to-date with current tax
        my ($contam, $unclass, $unknown, $self) = (0, 0, 0, 0);
        $unknown = 1 if map { $new_seq->lca =~ m/$_/xmsg } 'cellular\sorganisms', 'Eukaryota', 'Bacteria', 'Archaea' , 'unclassified sequences';
        $unclass = 1 if $new_seq->lineage eq 'unclassified sequences';
        #### $new_seq
        #### $full_id
        #### $seq_id
        #### $unknown
        #### $unclass

        unless ( $unknown or $unclass ) {

            if ($seq_classifier) {
                #### new_seq: $full_id
                #### affiliation: $new_seq->lineage
                ($self, $contam) = $tax->eq_tax($full_id, $new_seq->lineage, $seq_classifier) ? (1, 0) : (0, 1);
                #### $self
                #### $contam
            }
            else {
                $contam  = 1 if defined $seq_id->tag && $seq_id->tag eq 'c';
                $unclass = 1 if defined $seq_id->tag && $seq_id->tag eq 'u';
                $self    = 1 unless $contam || $unclass;
                #### tag#: $seq_id->tag
            }
        }

        my $bank = $seq_id->full_org || $seq_id->taxon_id;
        #### $bank

        # Fill up data hash...
        $data_for{$bank}{seq}{phyla}{$new_seq->lca}++ if $contam;
        $data_for{$bank}{lineages}{$new_seq->lineage}++ if $contam;

        $data_for{$bank}{seq}{c}++  if $contam;
        $data_for{$bank}{seq}{nc}++ if $self;
        $data_for{$bank}{seq}{uc}++ if $unclass;
        $data_for{$bank}{seq}{uk}++ if $unknown;
        $data_for{$bank}{seq}{total}++;
        #### get: $data_for{$bank}{seq}

        $data_for{$bank}{ali}{c}{$ali}     = 1 if $contam;
        $data_for{$bank}{ali}{uc}{$ali}    = 1 if $unclass;
        $data_for{$bank}{ali}{uk}{$ali}    = 1 if $unknown;
        $data_for{$bank}{ali}{nc}{$ali}    = 1 if $self;
        $data_for{$bank}{ali}{total}{$ali} = 1;
    }
}
#### %data_for

# analyse contaminating phyla and try to remap them to a higher level...
# ... in order to alleviate contam reports
my %contam_data_for;
my @banks = keys %data_for;
PROCESS_DATA:
for my $bank ( @banks ) {

    my %lineages_for;
    my $contam_lineage_count = $data_for{$bank}{lineages};

    for my $lineage ( keys %$contam_lineage_count ) {

        my $contam_taxon = $contam_classifier ? $contam_classifier->classify($lineage) : (split /;\s/xms, $lineage)[-1];
           $contam_taxon ||= 'other taxa';
        push @{ $lineages_for{$contam_taxon} }, $lineage for 1..$contam_lineage_count->{$lineage};
        #### $lineage
        #### classification: $contam_taxon
    }
    #### Considering: $bank
    #### $contam_lineage_count
    #### %lineages_for

    for my $contam_taxon ( keys %lineages_for ) {
        my $seq_count = eval { scalar @{ $lineages_for{$contam_taxon} } } || 0;
        $contam_data_for{$bank}{$contam_taxon} = $seq_count;
    }
}
#### %contam_data_for

# TODO: consolidate KRONA output with Physeter's subs

my $dir = '.';      # default to working dir
if ($ARGV_outdir) {
    $dir = dir($ARGV_outdir)->relative;
    $dir->mkpath();
}

### Writing output TSV files for KRONA...
for my $bank (@banks) {
    ( my $serie = $bank ) =~ s/\s/_/xmsg;
    open my $lineout, '>', file($dir, $serie . $ARGV_in_strip . $ARGV_out_suffix . '.tsv');
    say {$lineout} join "\t", $serie, 'domain;phylum;class;order;family;genus;species';
    say {$lineout} join "\t", ( $data_for{$bank}{lineages}{$_}, $_ ) for keys %{ $data_for{$bank}{lineages} };
    say {$lineout} join "\t", $data_for{$bank}{seq}{nc} || 0, 'SELF';
    say {$lineout} join "\t", $data_for{$bank}{seq}{uk} || 0, 'unknown';
    say {$lineout} join "\t", $data_for{$bank}{seq}{uc} || 0, 'unclassified';
}

my @elected_lineages = uniq( sort map { keys %{ $contam_data_for{$_} } } @banks );
my @phyla            = map { (split /;\s/xms)[-1] } @elected_lineages;
my @mod_phyla        = map { $_ =~ s/\s/_/xmsg; $_ } @phyla;
#### @elected_lineages
#### @phyla

### Writing summary output files...
STATS_FILES:

open my $out,     '>', file($dir, 'per-genome' . $ARGV_in_strip . $ARGV_out_suffix . '.stats');
open my $out_sum, '>', file($dir, 'per-genome' . $ARGV_in_strip . $ARGV_out_suffix . '.stats-sum');

say {$out} join "\t", 'bank', 'tested_genes', 'added_ali', 'clean_ali',
                        'contam_ali', 'completeness', 'added_seq', 'clean_seq', 'contam_seq',
                        'unclass_contam_seq', 'unknown_seq', @mod_phyla, 'foreign_phyla',
                        'contam_perc', 'class_contam_perc', 'unclass_contam_perc', 'unknown_perc'
                        ;

say {$out_sum} join "\t", 'bank', 'tested_genes', 'added_ali', 'clean_ali',
                            'contam_ali', 'completeness', 'added_seq', 'clean_seq', 'contam_seq',
                            'unclass_contam_seq', 'unknown_seq', 'foreign_phyla', 'contam_perc',
                            'class_contam_perc', 'unclass_contam_perc', 'unknown_perc';

my @ali_totals;
tie my %line_for, 'Tie::IxHash';
for my $bank (@banks) {

    # ali stats
    my $ali_c        = scalar keys %{ $data_for{$bank}{ali}{c} } // 0;
    my $ali_nc       = scalar keys %{ $data_for{$bank}{ali}{nc} } // 0;
    my $ali_total    = scalar keys %{ $data_for{$bank}{ali}{total} } // 0;
    my $completeness = eval { ( $ali_nc / $ali_test ) * 100 };

    # seq stats
    my $seq_c     = $data_for{$bank}{seq}{c} // 0;
    my $seq_nc    = $data_for{$bank}{seq}{nc} // 0;
    my $seq_total = $data_for{$bank}{seq}{total} // 0;

    # taxonomic data
    my @phyla_data    = map { $contam_data_for{$bank}{$_} // 0 } @elected_lineages;
    my $foreign_phyla = scalar keys %{ $contam_data_for{$bank} } // 0;
    my $unclassified  = $data_for{$bank}{seq}{uc} // 0;
    my $unknown       = $data_for{$bank}{seq}{uk} // 0;

    my $all_c_p  = eval { ( ($seq_c + $unclassified) * 100)/$seq_total } // 0;
    my $contam_p = eval { (  $seq_c                  * 100)/$seq_total } // 0;
    my $unclas_p = eval { (  $unclassified           * 100)/$seq_total } // 0;
    my $unknwn_p = eval { (  $unknown                * 100)/$seq_total } // 0;

    $bank =~ s/\s/_/xms;

    $line_for{$bank} = [
                        $bank, $ali_test, $ali_total, $ali_nc, $ali_c, $completeness,
                        $seq_total, $seq_nc, $seq_c,  $unclassified, $unknown,
                        @phyla_data, $foreign_phyla >= 0 ?  $foreign_phyla : 0,
                        $all_c_p, $contam_p, $unclas_p, $unknwn_p
                       ];

    push @ali_totals, $ali_total;
}
#### %line_for

my @sort_all_banks = sort { @{ $line_for{$b} }[-3] <=> @{ $line_for{$a} }[-3] } keys %line_for;
#### @sort_all_banks

# Write file contents
say {$out}     join "\t", @{ $line_for{$_} }              for @sort_all_banks;
say {$out_sum} join "\t", @{ $line_for{$_} }[0..8,-7..-1] for @sort_all_banks;

### Done!


##################################### SUBS #####################################

sub compute_percentage {
    my $array = shift;
    my $total = shift;

    my @results;
    my $percentage;
    CALC:
    for my $value (@$array) {
        if ($value == 0) {
            $percentage = 0;
            push @results, '-/-';
            next CALC;
        }
        else {
            $percentage = $value / $total;
#            $percentage = $value * 100 / $total;
        }
        $percentage = sprintf("%.2f", $percentage);
        push @results, $value . '/' . $percentage;
    }
    return \@results;
}

# for testing:
# perl -Ilib bin/debrief-42.pl --indir=xtest/tax_reports/ \
#   --in-strip=-42-camera-megan99-tf --taxdir=../Bio-MUST-Core/test/taxdump
#   --seq_labeling=xtest/seq-labels.idl --contam_labeling=xtest/contam-labels.idl \
#   --outdir=dbout

__END__

=pod

=head1 NAME

debrief-42.pl - Summarize the results of a 42 metagenomic run

=head1 VERSION

version 0.213470

=head1 USAGE

    debrief-taxR-42.pl --indir=<indir> --in=<str> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item --indir=<indir>

Path to input directory containing TAX-REPORT files.

=for Euclid: indir.type: str

=item --in[-strip]=<str>

Substring to strip from infile basenames to derive pre-42 filenames. This
often corresponds to the C<out_suffix> option of the YAML C<config> file for 42
(e.g., C<-42>).

=for Euclid: str.type: string

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --outdir=<dir>

Optional output dir that will contain the computed TSV files (will be created if
needed) [default: none]. Otherwise, output files will be written in the working
directory.

=for Euclid: dir.type: writable

=item --out[-suffix]=<suffix>

Suffix to append to infile basenames for deriving outfile names [default: none].

=for Euclid: suffix.type: string
    suffix.default: q{}

=item --taxdir=<dir>

Path to local mirror of the NCBI Taxonomy database.

=for Euclid: dir.type: string

=item --seq_labeling=<file>

Path to custom IDL file providing low-level taxa for accurate labeling of
the sequences newly added by 42 [default: none].

=for Euclid: file.type: readable

=item --contam_labeling=<file>

Path to custom IDL file providing high-level taxa for broad detection of
contaminant sequences among new sequences [default: none].

=for Euclid: file.type: readable

=item --verbosity=<level>

Verbosity level for logging to STDERR [default: level.default]. Available
levels range from 0 to 6. Level 6 corresponds to debugging mode.

=for Euclid: level.type: int, level >= 0 && level <= 6
    level.default: 1

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

Mick VAN VLIERBERGHE <mvanvlierberghe@doct.ulg.ac.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
