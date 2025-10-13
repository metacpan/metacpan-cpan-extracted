#!/usr/bin/env perl
# PODNAME: annotate-ali.pl
# ABSTRACT: Annotate sequences by homology search using BLAST
# CONTRIBUTOR: Valerian LUPO <valerian.lupo@uliege.be>

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments '###';

use Tie::IxHash;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(secure_outfile);
use Bio::MUST::Drivers;


# TODO: add support for prebuilt reference database (e.g. nr)

# convert fractional identity threshold to percentage (see Euclid)
$ARGV_identity *= 100.0 if 0 < $ARGV_identity && $ARGV_identity <= 1;

### Building database: $ARGV_ref_file
my $blastdb = Bio::MUST::Drivers::Blast::Database::Temporary->new(
    seqs => $ARGV_ref_file
);

for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $queries = Bio::MUST::Core::Ali::Temporary->new( seqs => $infile );

    # let driver decide BLAST flavor except if nucl:nucl and --tblastx option
    my $method = $queries->type eq 'nucl' && $blastdb->type eq 'nucl'
        && $ARGV_tblastx ? 'tblastx' : 'blast';

    #### Performing BLAST...
    my $parser = $blastdb->$method($queries, {
        -outfmt => 6,
        -evalue => $ARGV_evalue,
        -max_target_seqs => $ARGV_max_hits
    } );

    #### Parsing BLAST report...
    tie my %ann_for,    'Tie::IxHash';
    tie my %hit_id_for, 'Tie::IxHash';
    my $curr_id = q{};

    HIT:
    while ( my $hit = $parser->next_hit ) {
        my ($qid, $hid, $identity)
            = map { $hit->$_ } qw(query_id hit_id percent_identity);

        next HIT if $identity < $ARGV_identity;     # skip weak-identity hits

        unless ($ARGV_hit_list) {                   # optionally
            next HIT if $qid eq $curr_id;           # skip non-first hits
            $curr_id = $qid;
        }

        # capture annotation bit in ref seq_id using regex
        my ($annotation) = $blastdb->long_id_for($hid) =~ $ARGV_ref_regex;
        my $full_qid = $queries->long_id_for($qid);
        $ann_for{$full_qid} //= $annotation;        # use only first hit

        # extract additional (optionally) wanted fields
        my @wanted_fields = map { $hit->$_ } @ARGV_fields;

        # collect all hits for at specified (E-value and) identity thresholds
        push @{ $hit_id_for{$full_qid} }, {
            annotation => $annotation,
            fields     => \@wanted_fields,
        };
    }
    ##### Annotations: %ann_for

    # output annotation report
    my @header = ('tag', 'id', @ARGV_fields);
    say '# ' . join "\t", @header;
    while (my ($id, $hits) = each %hit_id_for) {
        for my $hit ( @{$hits} ) {
            say join "\t", $hit->{annotation}, $id, @{ $hit->{fields} };
        }
    }

    # optionally output annotated file
    if ($ARGV_ann_file) {
        my $ali = Bio::MUST::Core::Ali->load($infile);
        $ali->dont_guess if $ARGV_noguessing;
        my $outfile = secure_outfile($infile, $ARGV_out_suffix);
        #### Writing annotated file: $outfile->stringify
        prefix_ids($ali, \%ann_for)->store_fasta($outfile);
    }
}

# TODO: replace by or add some --store-id-mapper option?
# TODO: move into BMC::Ali
sub prefix_ids {
    my $ali     = shift;
    my $ann_for = shift;

    for my $seq ($ali->all_seqs) {
        my $prefix = $ann_for->{$seq->full_id};
        $seq->set_seq_id( $prefix . q{-} . $seq->full_id ) if $prefix;
    }

    return $ali;
}

# TODO: check coherence of option layout with cdhit-tax-filter.pl
# e.g., replace --ann-file by --store-id-mapper

__END__

=pod

=head1 NAME

annotate-ali.pl - Annotate sequences by homology search using BLAST

=head1 VERSION

version 0.252830

=head1 USAGE

    annotate-ali.pl <infiles> --database=<file> --regex=<regex> [options]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input ALI files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=item --ref-file [=] <file> | --database [=] <file>

Path to the FASTA file containing the sequence database.

=for Euclid: file.type: readable

=item --[ref-]regex [=] <regex>

Regular expression for capturing the reference seq id fragment that has to be
used for annotating infile seq ids.

=for Euclid: regex.type: string

=back

=head1 OPTIONS

=over

=item --evalue [=] <float>

E-value threshold for annotating a sequence [default: 1e-10].

=for Euclid: float.type: number
    float.default: 1e-10

=item --identity [=] <number>

Identity threshold for annotating a sequence [default: 0]. When specified as a
fraction between 0 and 1 (included), it is first multiplied by 100 to be
interpreted in percentage.

=for Euclid: number.type: number
    number.default: 0

=item --max-hits [=] <number>

Number of hits to return for each query (BLAST -max_target_seqs option)
[default: 10]. Mostly useful in conjunction with the C<--hit-list> option.

=for Euclid: number.type: number
    number.default: 10

=item --tblastx

Enforce using TBLASTX (instead of the auto-selected BLASTN) when both the
infile and the database contain nucleotide sequences [default: no].

=item --ann-file

Write an annotated version (with prefixed ids) of the infile [default: no].

=item --hit-list

Print a list of id/hit pairs (at the specified E-value and identity thresholds)
instead of the standard annotation report [default: no].

=item --fields [=] <str>...

List of whitespace-separated BLAST fields to be displayed in final report
[default: no].

Valid fields are: percent_identity, hsp_length, mismatches, gaps, query_from,
query_to, hit_from, hit_to, evalue, bit_score, query_start, query_end,
hit_start, hit_end.

=for Euclid: str.type: string, str eq "percent_identity" || str eq "hsp_length" || str eq "mismatches" || str eq "gaps" || str eq "query_from" || str eq "query_to" || str eq "hit_from" || str eq "hit_to" || str eq "evalue" || str eq "bit_score" || str eq "query_start" || str eq "query_end" || str eq "hit_start" || str eq "hit_end"
    str.default: []

=item --out[-suffix] [=] <suffix>

Suffix to append to infile basenames for deriving outfile names [default:
-ann]. When not specified, outfile names are taken from infiles but original
infiles are preserved by being appended a .bak suffix.

=for Euclid: suffix.type: string
    suffix.default: '-ann'

=item --[no]guessing

[Don't] guess whether sequences are aligned or not [default: yes].

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
