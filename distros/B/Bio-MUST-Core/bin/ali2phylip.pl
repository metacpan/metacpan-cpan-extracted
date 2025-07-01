#!/usr/bin/env perl
# PODNAME: ali2phylip.pl
# ABSTRACT: Convert (and filter) ALI files to PHYLIP files for tree building
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
# CONTRIBUTOR: Raphael LEONARD <rleonard@doct.uliege.be>

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use List::Compare;
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::IdMapper';
use aliased 'Bio::MUST::Core::SeqMask';


# optionally setup test outfile
my $out;
if ($ARGV_test_out) {
    open $out, '>', $ARGV_test_out;
    say {$out} join "\t", qw(
        file gb bmge pars max min
        Q0.len Q1.len Q2.len Q3.len Q4.len
         in.seqs  in.sites in.miss
        out.seqs out.sites out.miss
    );
}

for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $ali = Ali->load($infile);
    $ali->gapify_seqs if $ARGV_from_scafos;

    dump_stats($infile, $ali, 'in');

    # remove shared gaps (and more if asked to do so)
    _apply_mask( $ali, SeqMask->ideal_mask($ali, $ARGV_max_res_drop_site) );

    # TODO: allow deleting #NEW# sequences made identical to existing seqs
    # of the same org after mask application (to handle 42 mini-inserts)

    # apply Gblocks mask
    _apply_mask( $ali, SeqMask->gblocks_mask($ali, $ARGV_gb_mask) )
        if $ARGV_gb_mask;

    # apply BMGE mask
    _apply_mask( $ali, SeqMask->bmge_mask($ali, $ARGV_bmge_mask) )
        if $ARGV_bmge_mask;

    # apply parsimony mask
    _apply_mask( $ali, SeqMask->parsimony_mask($ali) )
        if $ARGV_pars_mask;

    # discard partial sequences and report their ids
    if ($ARGV_min_res_seq) {
        my @ali_list = map { $_->full_id } $ali->all_seq_ids;
        $ali->apply_list( $ali->complete_seq_list($ARGV_min_res_seq) );
        my @phy_list = map { $_->full_id } $ali->all_seq_ids;
        my $lc = List::Compare->new( { lists => [\@ali_list, \@phy_list] } );
        for my $full_id ($lc->get_unique) {
            ### Discarding seq: $full_id
        }
    }

    # generate mapping file and map ids
    if ($ARGV_map_ids) {
        my $idm = $ali->std_mapper;
        my $idmfile = change_suffix($infile, '.idm');
        $idm->store($idmfile);
        $ali->shorten_ids($idm);
    }

    # optionally delete constant sites
    _apply_mask( $ali, SeqMask->variable_mask($ali) )
        if $ARGV_del_const;

    # export Ali to phylip format (or ALI) format
    my $outfile = change_suffix($infile,
        $ARGV_ali ? '-a2p.ali' :
        $ARGV_p80 ? '.p80'     :
                    '.phy'
    );

    dump_stats($outfile, $ali, 'out');

    # only write actual phylip file if not in test mode
    unless ($out) {
        my $method = $ARGV_ali ? 'store' : 'store_phylip';
        my $args = { clean => 1, $ARGV_p80 ? (short => 0, chunk => -1) : () };
        $ali->$method($outfile, $args);
    }
}

# wrapper to native methods to transparently handle codon_mask
sub _apply_mask {
    my $ali  = shift;
    my $mask = shift;

    if ($ARGV_keep_codons) {
        $mask = $mask->codon_mask( {
            frame => $ARGV_coding_frame,
              max => $ARGV_codon_max_nt_drop,
        } );

        # frame should be fixed only once
        $ARGV_coding_frame = 1;
    }

    $ali->apply_mask($mask);
    return;
}

sub dump_stats {
    my $file = shift;
    my $ali  = shift;
    my $mode = shift;

    # output tabular stats line when in test mode
    if ($out) {
        print {$out} join "\t", (
            $file,
            $ARGV_gb_mask // q{} , $ARGV_bmge_mask // q{},
            $ARGV_pars_mask // q{},
            $ARGV_max_res_drop_site, $ARGV_min_res_seq,
            $ali->seq_len_stats
        ) if $mode eq 'in';
        print {$out} "\t" . join "\t",
            $ali->count_seqs, $ali->width, $ali->perc_miss;
        print {$out} "\n" if $mode eq 'out';
        return;
    }

    # output regular Smart::Comments stats line
    my $str = "$file has " . $ali->count_seqs . ' seqs x ' . $ali->width
        . ' sites (' . sprintf('%.2f', $ali->perc_miss) . '% missing states)';
    if ($mode eq 'in') {
        ### [ALI] file: $str
    } else {
        ### [PHY] file: $str
    }

    return;
}

__END__

=pod

=head1 NAME

ali2phylip.pl - Convert (and filter) ALI files to PHYLIP files for tree building

=head1 VERSION

version 0.251810

=head1 USAGE

    ali2phylip.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input ALI files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --test-out=<file>

Path to main outfile collecting statistics for all infiles [default: none].
When specified, the script does not produce any outfile but instead reports
statistics in a tabular output suitable to further analysis in R. This option
is useful for evaluating the effects of various parameter settings. It
overrides all the options pertaining to outfiles.

=for Euclid: file.type: writable

=item --from-scafos

Consider the input ALI file as generated by SCaFoS [default: no]. Currently,
specifying this option results in turning all ambiguous and missing character
states to gaps.

=item --max[-res-drop-site]=<n>

Number of non-gap character states allowed in a site to be dropped [default:
0]. When specified as a fraction between 0 and 1, it is interpreted as
relative to the number of sequences in the ALI. By default, only shared gaps
are dropped. To completely disable deletion of shared gaps, use -1.

=for Euclid: n.type:    number
    n.default: 0

=item --gb-mask=<mode>

Stringency of the Gblocks mask to be applied [default: none]. The following
modes are available: strict, medium and loose. This option requires to have a
C<Gblocks> executable in the C<$PATH>.

=for Euclid: mode.type:       string, mode eq 'strict' || mode eq 'medium' || mode eq 'loose'
    mode.type.error: <mode> must be one of strict, medium or loose (not mode)

=item --bmge-mask=<mode>

Stringency of the BMGE mask to be applied [default: none]. The following
modes are available: strict, medium and loose. This option requires to have a
C<bmge.sh> script in the C<$PATH>.

The C<bmge.sh> script should be as follows:

    #!/bin/sh
    java -jar path-to-bmge/BMGE.jar -i $1 -t $2 -h $3 -g $4 -oh $5

=for Euclid: mode.type:       string, mode eq 'strict' || mode eq 'medium' || mode eq 'loose'
    mode.type.error: <mode> must be one of strict, medium or loose (not mode)

=item --pars-mask

Apply a simple parsimony mask where only parsimony-informative sites are
retained [default: no].

=item --keep-codons

When specified, this option forces the various applied masks to follow the
codon structure [default: no]. This option only makes sense with nt seqs. See
options C<--codon-max> and C<--coding-frame> for more control on this
behavior.

=item --codon-max[-nt-drop]=<n>

Number of non-dropped nt sites allowed in a codon to be dropped [default: 1].
Allowed values are 0, 1 and 2. To be used when the option C<--keep-codons> is
also specified.

=for Euclid: n.type:    integer, 0 <= n && n <= 2
    n.default: 1

=item --coding-frame=<n>

Reading frame to be used when determining the ALI codon structure [default:
+1]. Allowed values are -3 to -1 and +1 to +3. To be used when the option
C<--keep-codons> is also specified.

=for Euclid: n.type:    integer, -3 <= n && n <= 3 && n != 0
    n.default: +1

=item --min[-res-seq]=<n>

Number of known character states required by a sequence for it to be
exported [default: 0]. When specified as a fraction between 0 and 1, it is
interpreted as relative to the longest ungapped sequence of the ALI. Note
that this optional filtering step takes place after the optional
Gblocks-based masking step.

=for Euclid: n.type:    number
    n.default: 0

=item --del-const

Delete constant sites just as the C<-dc> option of PhyloBayes [default: no].

=item --map-ids

Sequence id mapping switch [default: no]. When specified, sequence ids are
renamed to 'seqN' and IDM files are created. Enabling this option is highly
recommended when exporting to PHYLIP.

=item --p80

Output file in P80 format instead of PHYLIP [default: no]. This option is
useful for keeping full-length ids without mapping.

=item --ali

Output file in ALI format instead of PHYLIP [default: no]. This option is
useful for generating filtered ALI files usable by SCaFoS.

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTORS

=for stopwords Arnaud DI FRANCO Raphael LEONARD

=over 4

=item *

Arnaud DI FRANCO <arnaud.difranco@gmail.com>

=item *

Raphael LEONARD <rleonard@doct.uliege.be>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
