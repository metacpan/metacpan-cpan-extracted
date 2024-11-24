#!/usr/bin/env perl
# PODNAME: frameshiftSimul_final.pl
# ABSTRACT: Simulation for HmmCleaner
# CONTRIBUTOR: Denis BAURAIN <denis.baurain@uliege.be>

use Modern::Perl;
use autodie;

use Carp;
use Path::Class;
use File::Basename;
#~ use File::Temp qw(tempfile); my $template = 'tmpfile_XXXX';
use List::AllUtils qw(shuffle sum0 any firstidx);
use IPC::System::Simple qw(system);
use Getopt::Euclid qw(:vars);
use Template;


use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:gaps);
use Bio::MUST::Core::Utils qw(change_suffix);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::Seq';
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::SeqMask';
use aliased 'Bio::MUST::Core::GeneticCode::Factory';

## no critic (RequireLocalizedPunctuationVars)
BEGIN{
    $ENV{Smart_Comments} = $ARGV_verbosity
        ? join q{ }, map { '#' x (2 + $_) } 1..$ARGV_verbosity
        : q{}
    ;
}
## use critic
use Smart::Comments -ENV;

use Bio::MUST::Apps::HmmCleaner;
use aliased 'Bio::MUST::Apps::HmmCleaner';

### %ARGV

my $sf = $ARGV_sf // undef;
my $nf = $ARGV_nf // undef;

my $base_global_name = join '_',('stat', 'global', 'nf'.((defined $nf) ? $nf : 'rand'), 'sf'.((defined $sf) ? $sf : 'rand'), 'sub'.((defined $ARGV_subset) ? $ARGV_subset : 'all'), 'r'.$ARGV_rep);

my $outfile_global = $base_global_name.'.out';
my $outfile_frameshift_global = (join '_',($base_global_name, 'frameshift')).'.out';
my $outfile_fp_global = (join '_',($base_global_name, 'fp')).'.out';
my $simul_file_global = file($outfile_global);
my $simul_file_frameshift_global = file($outfile_frameshift_global);
my $simul_file_fp_global = file($outfile_fp_global);
my $out_global = $simul_file_global->openw;
my $out_frameshift_global = $simul_file_frameshift_global->openw;
my $out_fp_global = $simul_file_fp_global->openw;

#~ say {$out_global} '#'.join "\t",(
    #~ qw(File #Replicate #Frameshift Frameshift_size Threshold #Seq Ali_width #AA TruePositive TrueNegative FalsePositive FalseNegative MeanWithAllFrameshift)
#~ );
#~ say {$out_frameshift_global} '#'.join "\t",(
    #~
#~ );
#~ say {$out_fp_global} '#'.join "\t",(
    #~
#~ );


my $factory = Factory->new( tax_dir => $ARGV_taxdir );
my $code    = $factory->code_for('Standard');

for my $f ( @ARGV_infiles ) {

    ### file is : $f
    my $file = file($f);
    my $basename = basename($file->stringify, qw(.fasta .fa .ali .fna .faa) );
    my $ali = Ali->load($file);

    my @aa_base_seqs;
    for my $s ($ali->all_seqs) {
        push @aa_base_seqs, $code->translate($s,'+1');
    }
    #~ my $aa_base_ali = Ali->new( seqs => \@aa_base_seqs , file => $basename.'_aligned.ali');
    my $aa_base_ali = Ali->new( seqs => \@aa_base_seqs , file => change_suffix($file, '_aligned.ali'));
    $aa_base_ali->store($aa_base_ali->file);

    my $gapnseq = get_gapnseq($aa_base_ali);

    ### aligned ref file is : $aa_base_ali->file->stringify

    ### Gblocks...
    my $gblocks_loose = SeqMask->gblocks_mask($aa_base_ali, 'loose');
    my $gblocks_medium = SeqMask->gblocks_mask($aa_base_ali, 'medium');
    my $gblocks_strict = SeqMask->gblocks_mask($aa_base_ali, 'strict');

# quickest way to fill the mask for now
    my $gblocks_loose_neg = $gblocks_loose->negative_mask($aa_base_ali);
    $gblocks_loose = $gblocks_loose_neg->negative_mask($aa_base_ali);
    my $gblocks_medium_neg = $gblocks_medium->negative_mask($aa_base_ali);
    $gblocks_medium = $gblocks_medium_neg->negative_mask($aa_base_ali);
    my $gblocks_strict_neg = $gblocks_strict->negative_mask($aa_base_ali);
    $gblocks_strict = $gblocks_strict_neg->negative_mask($aa_base_ali);

    undef $gblocks_loose_neg;
    undef $gblocks_medium_neg;
    undef $gblocks_strict_neg;
    ###### mask gblocks loose : join ' ', $gblocks_loose->all_states

    ### BMGE...
    my $bmge_loose = SeqMask->bmge_mask($aa_base_ali, 'loose');
    ###### mask bmge loose    : join ' ', $bmge_loose->all_states
    my $bmge_medium = SeqMask->bmge_mask($aa_base_ali, 'medium');
    my $bmge_strict = SeqMask->bmge_mask($aa_base_ali, 'strict');
    ### Done...

    my $nseq = $aa_base_ali->count_seqs;
    #### $nseq
    my $width = $aa_base_ali->width;
    #### $width
    my $frequencies = gap_frequencies($aa_base_ali);
    ####### $frequencies : join ' ', @$frequencies

    # Missing substitution rates per site, investigating PAML codeml

    ### CODEML...
    my $rate_file = run_paml($aa_base_ali);
    my $rates = extract_rates($rate_file);
    ####### $rates : join ' ', @$rates

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    #~ my @frameshift_size = (30,99,150,300);
    #~ my @frameshift_n    = (1,5,10,$nseq);
    # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ## INITIATING SIMULATION
    # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    #~ my $sf = (shuffle(@frameshift_size))[0];
    #~ my $nf = (shuffle(@frameshift_n))[0];

    ### $nf
    ### $sf

    INITIATION:
    my $min_start = 0;

    if ($ARGV_rep) {


        my $bmge_loose_mean = sum0(($bmge_loose->all_states))/$aa_base_ali->width;
        my $bmge_medium_mean = sum0(($bmge_medium->all_states))/$aa_base_ali->width;
        my $bmge_strict_mean = sum0(($bmge_strict->all_states))/$aa_base_ali->width;
        my $gblocks_loose_mean = sum0(($gblocks_loose->all_states))/$aa_base_ali->width;
        my $gblocks_medium_mean = sum0(($gblocks_medium->all_states))/$aa_base_ali->width;
        my $gblocks_strict_mean = sum0(($gblocks_strict->all_states))/$aa_base_ali->width;
        my $gaps_mean = sum0(@$frequencies)/$aa_base_ali->width;
        my $rates_mean = sum0(@$rates)/$aa_base_ali->width;

        REPLICATE:
        for my $nrep (1..$ARGV_rep) {

            ## no critic (ProhibitReusedNames)
            my $nf = defined($nf) ? $nf : (shuffle((1..5)))[0];
            my $sf = defined($sf) ? $sf : ((shuffle((10..100)))[0]);
            ## use critic

            my $simul_info = {
                nf          => $nf,
                sf          => $sf,
            };

            # Random pick of subset sequences
            my $subset = defined( $ARGV_subset ) ? $ARGV_subset : scalar($ali->all_seqs);

            my $ali = Ali->load($file);     ## no critic (ProhibitReusedNames)
            my $lookup = $ali->new_lookup;
            my @new = (map { $_->full_id } shuffle($ali->all_seqs))[0..$subset-1];
            my $list = IdList->new( ids => \@new);
            $ali = $list->reordered_ali($ali, $lookup);
            #### List of picked seq : @new

            ### Replicate number : $nrep
            $ali->degap_seqs;

            my @pick;
            goto TRAD unless ($nf);
            if ($nf < $nseq) {
                #~ for my $i (1..$nf) {
                    #~ push @pick, int(rand($nseq-1));
                #~ }
                @pick = (shuffle($ali->all_seqs))[0..($nf-1)];

            } else {
                #~ @pick = (0..$nseq-1);
                @pick = $ali->all_seqs;
            }

            # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            ## RANDOMLY MODIFYING SEQ
            # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            for my $p (@pick) {
                my $seq = $p->clone->degap;
                my $codons = $seq->codons;

                ### SeqId : $seq->full_id

                my $n_codons = scalar(@$codons);
                #### $n_codons
                # !!!!!! Watch out this; should not be able to start the frameshift too early in seq
                my $start = (shuffle(($min_start..($n_codons-1))))[0];
                #### $start
                my $newframe = (shuffle(('+2','+3')))[0] ;
                #### $newframe
                my @range_new = ($newframe eq '+3') ? $start-1..$start-2+$sf : $start..$start-1+$sf;
                ###### @range_new : join ' ', @range_new
                my @toChange = @$codons[$start..$start-1+$sf];
                ###### @toChange
                my $frame_codons = $seq->codons($newframe);
                my @part = @$frame_codons[@range_new];
                ###### @part

                # >>>>>>>>>>>>>>>>>>>>>>
                ## If inserting STOP
                # <<<<<<<<<<<<<<<<<<<<<<
                my $haltat = -1;
                if ($ARGV_noStop) {
                    my $first_undef = firstidx { !defined($_) } @part;
                    ###### $first_undef
                    $haltat = ($first_undef!=0) ? $first_undef-1 : 0;
                } else {
                    my $first_stop = firstidx { $_  eq 'TAG' || $_  eq 'TAA' || $_  eq 'TGA' } @part;
                    my $first_undef = firstidx { !defined($_) } @part;
                    ###### $first_stop
                    ###### $first_undef
                    $haltat = ($first_stop==-1) ? ( ($first_undef!=0) ? $first_undef-1 : 0 ) : $first_stop;
                }
                ### $haltat
                splice( @$codons, $start, scalar(@part), @part); # @codons modified
                my $end;
                if ($haltat >= 0) {
                    ### in halt at
                    #~ $ali->get_seq($i)->_set_seq(join('',@$codons[0..$start+$haltat]));
                    $p->_set_seq(join('',@$codons[0..$start+$haltat]));
                    $end = $start+$haltat;
                } else {
                    ### not halt at
                    #~ $ali->get_seq($i)->_set_seq(join('',@$codons));
                    $p->_set_seq(join('',@$codons));
                    $end = $start+scalar(@part)-1;
                }

                FRAMESHIFT:
                ##### BASE    : $seq->seq
                ##### NEW     : $p->seq

                carp 'New seq is not the same size. Not an issue if frameshift at end of seq' if ($seq->seq_len != $p->seq_len);
                ##### AA_BASE : $code->translate( $seq, '+1')->seq
                ##### AA_NEW  : $code->translate( $p, '+1')->seq

                # Should I consider the supposed frameshift position or the actual one due to STOP codon
                my ($s,$e) = get_real_position($aa_base_ali, $seq->full_id, [$start,$end]);
                #~ my ($s,$e) = get_real_position($aa_base_ali, $i, [$start,$end);

                #### old start and end : ($start,$end)
                #### new start and end : ($s,$e)

                # TODO: mask out of blocks so shorter than alignment
                # It means that it can recover undef value for the sum0 -> warning
                # but not changing the Mean value
                my $bmge_loose_fmean = sum0(($bmge_loose->all_states)[$s..$e])/(($e+1-$s));
                my $bmge_medium_fmean = sum0(($bmge_medium->all_states)[$s..$e])/(($e+1-$s));
                my $bmge_strict_fmean = sum0(($bmge_strict->all_states)[$s..$e])/(($e+1-$s));
                my $gblocks_loose_fmean = sum0(($gblocks_loose->all_states)[$s..$e])/(($e+1-$s));
                my $gblocks_medium_fmean = sum0(($gblocks_medium->all_states)[$s..$e])/(($e+1-$s));
                my $gblocks_strict_fmean = sum0(($gblocks_strict->all_states)[$s..$e])/(($e+1-$s));
                my $gaps_fmean = sum0(@$frequencies[$s..$e])/(($e+1-$s));
                my $rates_fmean = sum0(@$rates[$s..$e])/(($e+1-$s));
                my $gc_fmean = get_gc_mean($seq->edit_seq($start*3,$sf*3));
                #### $gc_fmean

                push @{$simul_info->{frameshifts}}, {
                    id=>$seq->full_id, span => [$start+1,$end+1], type => $newframe, stop => ($haltat>=0)?1:0,
                    gaps_mean => $gaps_fmean, rates_mean => $rates_fmean, gc_mean => $gc_fmean,
                    gblocks_loose_mean => $gblocks_loose_fmean, gblocks_medium_mean => $gblocks_medium_fmean, gblocks_strict_mean => $gblocks_strict_fmean,
                    bmge_loose_mean => $bmge_loose_fmean, bmge_medium_mean => $bmge_medium_fmean, bmge_strict_mean => $bmge_strict_fmean,
                };
                #~ say {$out} join "\t", ($f, $seq->full_id, (($start+1).'-'.($start+$sf)) );
            }
            #~ next;

            # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            ## TRADUCTION
            # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            TRAD:
            ### Translating and aligning...
            my @aa_degap_seqs;
            for my $s ($ali->all_seqs) {
                push @aa_degap_seqs, $code->translate($s->clone->degap,'+1');
            }
            my $aa_degap_ali = Ali->new( seqs => \@aa_degap_seqs );

            my $nuc_gapped_ali = apply_gapnseq($ali, $gapnseq);
            my @aa_gapped_seqs;
            for my $s ($nuc_gapped_ali->all_seqs) {
                push @aa_gapped_seqs, $code->translate($s->clone,'+1');
            }
            my $aa_gapped_ali = Ali->new( seqs => \@aa_gapped_seqs );


            #~ my $simufile = $basename.'-exonAA.fasta';
            #~ my $simuNucfile = $basename.'-exonNUC.fasta';
            #~ my $simualignedfile = $basename.'-exonAA_aligned.fasta';
            my $simufile = change_suffix($file, '-exonAA.fasta');
            my $simuNucfile = change_suffix($file, '-exonNUC.fasta');
            my $simualignedfile = change_suffix($file, '-exonAA_aligned.fasta');
            $ali->store_fasta($simuNucfile);
            $aa_degap_ali->store_fasta($simufile);

            my $cmd = "mafft --localpair --quiet --maxiterate 1000 --reorder --anysymbol --thread 2 $simufile > $simualignedfile";

            # try to robustly execute hmmsearch
            my $ret_code = system( [ 0..127 ], $cmd);
            if ($ret_code != 0) {
                carp 'Warning: cannot execute mafft command';
                return;
            }

            my $ali_simu = Ali->load($simualignedfile);

            #~ my $ali_simu = align_ali($aa_ali);

            $simul_info->{width} = $ali_simu->width;
            $simul_info->{width_gapped} = $aa_gapped_ali->width;
            $simul_info->{nseq} = $ali_simu->count_seqs;

            # RECOVERING alignement information test

            $ali_simu->degap_seqs;
            my $count_aa;
            for my $seq ($ali_simu->all_seqs) {
                $count_aa += $seq->seq_len;
            }
            $simul_info->{count_aa} = $count_aa;

            # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            ## CLEANER
            # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            CLEANER:

            my $t = $ARGV_threshold // 1;
            my $c1 = $ARGV_cost1 // -0.15;
            my $c2 = $ARGV_cost2 // -0.08;
            my $c3 = $ARGV_cost3 // 0.15;
            my $c4 = $ARGV_cost4 // 0.45;

            my $thresh = $t;
            my $costs = [$c1, $c2, $c3, $c4];

            my $args_global = {
                ali             => $simualignedfile,
                ali_model       => $simualignedfile,
                threshold       => $thresh,
                changeID        => 0,
                delchar         => ' ',
                costs           => $costs,
                consider_X      => 1,
                perseq_profile  => 0,
            };

            ### Running HmmCleaner global for : $simualignedfile
            my $cleaner_global = HmmCleaner->new($args_global);

            # For parameter testing

            #~ my @t_list = (1);
            #~ my @c1_list = (-0.05,-0.075,-0.1,-0.125,-0.15,-0.175,-0.2,-0.225,-0.25);
            #~ my @c2_list = (-0.02,-0.03,-0.04,-0.05,-0.06,-0.07,-0.08);
            #~ my @c3_list = (0.05,0.075,0.1,0.125,0.15,0.175,0.2,0.225,0.25);
            #~ my @c4_list = (0.4,0.45,0.5,0.55,0.6);



            #~ for my $t (@t_list) {
                #~ for my $c1 (@c1_list) {
                    #~ for my $c2 (@c2_list) {
                        #~ for my $c3 (@c3_list) {
                            #~ for my $c4 (@c4_list) {
#~
                                #~ #### Threshold : $t
                                #~ #### Cost1  ' ': $c1
                                #~ #### Cost2  '+': $c2
                                #~ #### Cost3  'a': $c3
                                #~ #### Cost4  'A': $c4
                                #~
                                #~ $cleaner_global->update_cleaners($t, [$c1, $c2, $c3, $c4] );

            my $log_global = $cleaner_global->get_log_simu;

            unless (defined $log_global) {
                ## Could not work anymore without the eval but bug was found
                carp 'Warning: HmmCleaner global failed; Current file '.$f.' replicate '.$nrep.' will be missing';
                next REPLICATE;
            }
            ##### $log_global
            for my $clean ($cleaner_global->all_cleaners) {
                if (any { $_->{id} eq $clean->seq->full_id } @{$simul_info->{frameshifts}}) {
                    ##### Seqid        : $clean->seq->full_id
                    ##### nogap_shifts : $clean->nogap_shifts
                }
            }

            ### Cleaning tmpfile...

            if ($ARGV_verbosity <= 5) {
                my $dir = dir();
                my @tmpfiles = grep {substr($_->stringify,0,9) eq "./tmpfile"} $dir->children;
                $_->remove for (@tmpfiles);
            }

            # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            ## COMPARE
            # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            COMPARE:

            ##### Simulation information : $simul_info
            if ($nf) {
                my ($results_file, $results_frameshifts, $fps);

                ## Global
                ($results_file, $results_frameshifts, $fps) = get_stat_file($simul_info, $log_global, $simualignedfile, $aa_base_ali);
                # File  #Replicate  #Frameshift Frameshift_size Threshold  cost1 cost2 cost3 cost4 #Seq Ali_width   #AA
                # TruePositive    TrueNegative    FalsePositive   FalseNegative   gaps rates
                # gb_loose  gb_medium   gb_strict   bmge_loose  bmge_medium bmge_strict
                say {$out_global} join "\t", (
                    $f, $nrep, $nf, $sf, $t, $c1, $c2, $c3, $c4, $nseq, $simul_info->{width}, $count_aa,
                    $results_file->{vp}, $results_file->{vn}, $results_file->{fp}, $results_file->{fn}, $gaps_mean, $rates_mean,
                    $gblocks_loose_mean, $gblocks_medium_mean, $gblocks_strict_mean, $bmge_loose_mean, $bmge_medium_mean, $bmge_strict_mean);
                for my $frameshift ( @{ $results_frameshifts } ) {

                    # File  SeqId   Threshold   cost1 cost2 cost3   cost4  FrameshiftType
                    # #Frameshift   TruePositive    Frameshift_size FalsePositive
                    # Start     End     Interrupted
                    # gaps      rates   GC
                    # gb_loose  gb_medium   gb_strict   bmge_loose  bmge_medium bmge_strict
                    say {$out_frameshift_global} join "\t", (
                        $f, $frameshift->{id}, $t, $c1, $c2, $c3, $c4, $frameshift->{type},
                        $nf, $frameshift->{vp}, 1+$frameshift->{span}->[1]-$frameshift->{span}->[0], $frameshift->{fp},
                        $frameshift->{span}->[0], $frameshift->{span}->[1], $frameshift->{stop},
                        $frameshift->{gaps_mean}, $frameshift->{rates_mean}, $frameshift->{gc_mean},
                        $frameshift->{gblocks_loose_mean}, $frameshift->{gblocks_medium_mean}, $frameshift->{gblocks_strict_mean},
                        $frameshift->{bmge_loose_mean}, $frameshift->{bmge_medium_mean}, $frameshift->{bmge_strict_mean},
                    );
                }

                for my $fp (@$fps) {
                    say {$out_fp_global} join "\t", (
                        $f, $fp->{id}, $fp->{start}, $fp->{end}, $t, $c1, $c2, $c3, $c4,
                        sum0(@$frequencies[$fp->{start}-1..$fp->{end}-1])/(($fp->{end}+1-$fp->{start})),    # gaps
                        sum0(@$rates[$fp->{start}-1..$fp->{end}-1])/(($fp->{end}+1-$fp->{start})),          # rates
                        sum0(($bmge_loose->all_states)[$fp->{start}-1..$fp->{end}-1])/(($fp->{end}+1-$fp->{start})),  # bmge loose
                        sum0(($bmge_medium->all_states)[$fp->{start}-1..$fp->{end}-1])/(($fp->{end}+1-$fp->{start})), # bmge medium
                        sum0(($bmge_strict->all_states)[$fp->{start}-1..$fp->{end}-1])/(($fp->{end}+1-$fp->{start})), # bmge strict
                        sum0(($gblocks_loose->all_states)[$fp->{start}-1..$fp->{end}-1])/(($fp->{end}+1-$fp->{start})),  # gblocks loose
                        sum0(($gblocks_medium->all_states)[$fp->{start}-1..$fp->{end}-1])/(($fp->{end}+1-$fp->{start})), # gblocks medium
                        sum0(($gblocks_strict->all_states)[$fp->{start}-1..$fp->{end}-1])/(($fp->{end}+1-$fp->{start})), # gblocks strict
                    );
                }
            }

        }
    } else {
        # In case of preflight run without replicate
    }

}

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
## SUB
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


sub size_overlap {
    #~ ### In Size_overlap...
    my $simu_span = shift;
    my $clean_spans = shift;

    my $count_overlap;
    SPAN:
    for my $cspan (@$clean_spans) {
        my $ret = _overlap(@$simu_span,@$cspan);
        #~ ### $ret
        $count_overlap += $ret;
        #~ ### $count_overlap
    }

    return $count_overlap;
}

# Given two segment a-b and c-d, give the common part size
# assume a<b and c<d
# This sub is coming from the original script
sub _overlap {
    #~ ### In _overlap...
    my ($a, $b, $c, $d) = @_;
    my $ret = 0;
    if( ($c <= $b) and ($b <= $d) ){
        $ret = $b-$c+1;
    }
    if( ($c <= $a) and ($a <= $d) ){
        if($ret == 0){
            $ret = $d-$a+1;
        }
        else{
            $ret-=$a-$c;
        }
    }
    if( ($a < $c) and ($d < $b) ){
        $ret = $d-$c+1;
    }
    return $ret;
}

sub gap_frequencies {
    my $ali = shift;

    my @frequencies;
    for my $pos_idx (0..$ali->width-1) {
        my @col = map { $_->state_at($pos_idx) } $ali->all_seqs;

        my $freq = (grep{ $_ =~ $GAP }@col)/scalar(@col);

        push @frequencies, $freq;
    }

    return \@frequencies;
}

sub align_ali {
    my $ali = shift;

    my $tmpfilename = $ali->filename.'tmp';

    $ali->store_fasta($tmpfilename);

    my $outfile_name = $ali->file;

    my $cmd = "mafft --localpair --quiet --maxiterate 1000 --reorder --anysymbol --thread 2 $tmpfilename > $outfile_name";

    # try to robustly execute hmmsearch
    my $ret_code = system( [ 0, 127 ], $cmd);
    if ($ret_code == 127) {
        carp 'Warning: cannot execute mafft command';
        return;
    }

    my $aligned_ali = Ali->load($outfile_name);
    #~ $aligned_ali->restore_ids($mapper);

    return $aligned_ali;
}

sub get_gc_mean {
    my $str = shift;
    #### GC string : $str
    my @residues = split //, uc($str);
    my $gc_count = grep { $_ eq 'G' || $_ eq 'C' } @residues;
    return @residues ? $gc_count/scalar(@residues) : 0;
}

sub get_stat_file {

    my $simul_info  = shift;
    my $log         = shift;
    my $simualignedfile = shift;
    my $aa_base_ali = shift;

    my %results_file;
    my @results_frameshifts;

    my $vp          = 0;
    my $simu_aa     = 0;
    my $clean_aa    = 0;

    ##### Number of frameshift in simul_info : scalar( @{ $simul_info->{frameshifts} } )

    for (my $j=0; $j<@{ $simul_info->{frameshifts} }; $j++) {

        my $frameshift = $simul_info->{frameshifts}->[$j];
        ##### $frameshift
        my $simu_span = $frameshift->{span};
        ##### $simu_span
        my $cleaner_spans = $log->{$simualignedfile}->{ $frameshift->{id} };
        ##### $cleaner_spans

        # True positive calc
        my $actual_vp = (defined $cleaner_spans) ? size_overlap($simu_span, $cleaner_spans) : 0 ;

        $frameshift->{vp} = $actual_vp;
        $frameshift->{sf} = $simul_info->{sf};
        $vp += $actual_vp;

        # False negative
        $simu_aa += 1+$simu_span->[1]-$simu_span->[0];

        my $frameshift_clean_aa = 0;
        # False positive
        for my $span ( @$cleaner_spans ) {
            $frameshift_clean_aa += 1+$$span[1]-$$span[0];
        }
        my $actual_fp = $frameshift_clean_aa-( 1+$simu_span->[1]-$simu_span->[0] );
        $frameshift->{fp} = $actual_fp;

        push @results_frameshifts, $frameshift;
    }

    # True positive
    $results_file{vp} = $vp;
    #### $vp

    # False negative
    #### $simu_aa
    $results_file{fn} = $simu_aa-$vp;

    croak 'VP is wrong, larger than simu_aa' if ($vp > $simu_aa);

    ### False positive...
    my @frameshifts = @{$simul_info->{frameshifts}};

    my @fp;
    my %all_cleaners_span = %{ $log->{$simualignedfile} };
    for my $org (keys %all_cleaners_span) {
        ### $org
        if (my @gf = grep {$_->{id} eq $org} @frameshifts) {
            for my $span ( @{ $all_cleaners_span{$org} } ) {
                $clean_aa += 1+$$span[1]-$$span[0];
                ### $span

                unless (_overlap( @{ $gf[0]->{span} }, @$span)) {
                    ### not overlapping with : $gf[0]->{span}
                    my ($s,$e) = get_real_position($aa_base_ali, $org, $span);
                    push @fp, {
                        id      => $org,
                        start   => $s,
                        end     => $e,
                    };

                } else {
                    ### overlapping with : $gf[0]->{span}
                }

            }
        } else {
            for my $span ( @{ $all_cleaners_span{$org} } ) {
                $clean_aa += 1+$$span[1]-$$span[0];
                ### $span
                my ($s,$e) = get_real_position($aa_base_ali, $org, $span);
                    push @fp, {
                        id      => $org,
                        start   => $s,
                        end     => $e,
                    };
            }
        }
    }
    #### $clean_aa
    $results_file{fp} = $clean_aa-$vp;

    # True Negative
    $results_file{vn} = $simul_info->{count_aa}-( $results_file{vp} + $results_file{fp} + $results_file{fn} );

    return (\%results_file,\@results_frameshifts, \@fp);
}


#~ sub get_stat_falsepositive {
#~
    #~ my $simul_info  = shift;
    #~ my $log         = shift;
    #~ my $simualignedfile = shift;
#~
    #~ my @frameshifts = @{$simul_info->{frameshifts}};
    #~
    #~ for my $org ( sort keys %{$log->{$simualignedfile}} ) {
#~
        #~ grep { $_->{id} eq $org } @frameshifts;
        #~
        #~
    #~ }
    #~
    #~ return (\%results_file,\@results_frameshifts);
#~ }

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
##  SUB for gap toggling
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

sub get_gapnseq {

    my $ali = shift;

    my %hash;
    for my $seq ($ali->all_seqs) {
        my $id = $seq->full_id;
        $hash{$id} = get_part_length($seq->seq);
    }

    return \%hash;
}

sub get_part_length {
    my $str = shift;

    ## Looking for gaps in full sequence...
    my @gaps_n_seqs;
    my $push = 0;
    foreach my $tab ( split /$GAP/xms, $str ) {
        if( length($tab) == 0){
            $push++;
        }else{
            push(@gaps_n_seqs, $push); # gap_length
            push(@gaps_n_seqs, length($tab)); # seq_length
            $push = 1;
        }
    }

    return \@gaps_n_seqs;
}

# Push gap from aa alignment onto nucleotide
sub apply_gapnseq {

    my $ali     = shift;
    my $gapnseq = shift;

    my @gap_nuc;
    for my $seq ($ali->all_seqs) {
        my $id = $seq->full_id;
        #~ ### $id

        my $codons = $seq->codons;

        my @new;
        my @gaps_n_seqs = @{ $$gapnseq{$id} };

        my $last_start = 0;
        for (my $i=0; $i < @gaps_n_seqs; $i+=2) {

            my $gap_number = $gaps_n_seqs[$i];
            if ($gap_number) {
                push(@new, '***' ) for 1..$gap_number;
            }
            my $codons_number = $gaps_n_seqs[$i+1];
            push @new, @$codons[$last_start..($last_start+$codons_number-1)];

            $last_start += $codons_number;

            #~ ### Seq at the moment: join '', @new
        }

        push @gap_nuc, Seq->new( seq => join( '', @new), seq_id => $id );
    }

    my $new_ali = Ali->new( seqs => \@gap_nuc );

    return $new_ali;
}

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
## SUB for PAML
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

sub run_paml {
    my $ali = shift;

    my $rates_file = file(change_suffix($ali->file, '.rates'));

    if (-e $rates_file->stringify) {
        ### Found Rates file, skipping RAxML and PAML...
        return $rates_file;
    } else {
        my $idm = $ali->std_mapper;
        $ali->shorten_ids($idm);
        my $idmfile = change_suffix($ali->file, '.idm');
        $idm->store($idmfile);

        my $phyfile = substr(change_suffix($ali->file, '.p80'),2);
        my $treefile = file(change_suffix($ali->file, '.tre'));
        unless ( -e $treefile) {
            my $args = { clean => 1, short => 0, chunk => -1 };
            $ali->store_phylip($phyfile, $args);
            $treefile = run_raxml($phyfile);
        } else {
            ### Found tree file, skipping RAxML...
        }
        my $pamlfile = store_paml($ali);
        $ali->restore_ids($idm);

            # fill-in template
        my $vars = {
            seqfile => $pamlfile->stringify,
            treefile => $treefile->stringify,
        };
        ### $vars

my $tt_str = <<'EOT';
seqfile = [% seqfile %]
outfile = test_codeml.rst * main result file
treefile = [% treefile %]
noisy = 0
verbose = 0
runmode = 0
seqtype = 2
aaRatefile = /home/adf/lg.dat
model = 3
Mgene = 0
fix_alpha = 0 * 0: estimate gamma shape parameter; 1: fix it at alpha
alpha = 0.1 * initial or fixed alpha, 0:infinity (constant rate)
Malpha = 0 * different alphas for genes
ncatG = 8 * # of categories in dG of NSsites models
getSE = 0 * 0: don't want them, 1: want S.E.s of estimates
RateAncestor = 1 * (0,1,2): rates (alpha>0) or ancestral states (1 or 2)
Small_Diff = .5e-6
cleandata = 0 * remove sites with ambiguity data (1:yes, 0:no)?
method = 1 * 0: simultaneous; 1: one branch at a time
EOT

        my $tt = Template->new;
        $tt->process(\$tt_str, $vars, "codeml.ctl");

        my $cmd = "codeml codeml.ctl";

        # try to robustly execute codeml
        my $ret_code = system( [ 0, 127 ], $cmd);
        if ($ret_code == 127) {
            carp 'Warning: cannot execute codeml command';
            return;
        }

        $rates_file = file('rates')->move_to($rates_file->stringify);

        return $rates_file;
    }
}

sub run_raxml {
    my $file = shift;

    ### RAxML...
    #~ my $cmd = "raxml -m PROTGAMMALGF -p 12345 -s $file -n tree";
    my $cmd = "raxml-thread -m PROTGAMMALGF -p 12345 -s $file -n ".$file." -T 16";

    # try to robustly execute raxml
    my $ret_code = system( [ 0, 127 ], $cmd);
    if ($ret_code == 127) {
        carp 'Warning: cannot execute RAxML command';
        return;
    }

    my $treefile = 'RAxML_bestTree.'.$file;
    my $lines = file($treefile)->slurp(iomode => '<:encoding(UTF-8)');
    $lines =~ s/Node\d+//xmsg;
    #~ my $result = system("perl -i.bak -nle 's/Node\d+//g; print;' $treefile");
    my $filename = change_suffix($file, '.tre');
    my $pamltree = file($filename);
    $pamltree->spew($lines);

    return $pamltree if -e $pamltree->stringify;
    return;
}

sub store_paml {
    my $self    = shift;                # BMC::Ali
    my $args    = shift // {};          # HashRef (should not be empty...)

    my $outfile = basename($self->file, qw(.fa .fasta .ali .faa .fna)).'.paml';
    my $degap = $args->{degap} // 0;
    my $clean = $args->{clean} // 0;
    my $chunk = $args->{chunk} // 60;
    my $nowrap = $chunk < 0 ? 1 : 0;
    my $is_aligned = $self->is_aligned;

    open my $out, '>', $outfile;

    say {$out} join ' ', ($self->count_seqs, $self->width);

    for my $seq ($self->all_seqs) {
        say {$out} $seq->foreign_id;

        # optionally clean and/or degap seq
        $seq = $seq->clone  if $clean || $degap;    # clone seq only if needed
        $seq->gapify('X')   if $clean;
        $seq->degap         if $degap;

        my $width = $seq->seq_len;
        $chunk = $width     if $nowrap;             # optionally disable wrap

        for (my $site = 0; $site < $width; $site += $chunk) {
            my $str = $seq->edit_seq($site, $chunk);
            $str =~ s{$GAP}{-}xmsg if $is_aligned;  # restore '-' when aligned
            say {$out} $str;
        }
    }

    return file($outfile);
}

sub extract_rates {
    my $file = shift;
    my @lines = grep {$_ =~ m/^\s+\d+/xms} $file->slurp( chomp => 1);
    ## no critic (BuiltinFunctions::ProhibitComplexMappings)
    my @rates = map { my @F = split /\s+/xms, $_; $F[4]; } @lines;
    ## use critic

    return \@rates;
}

sub get_real_position {
    my $ali = shift;
    my $seq_id = shift;
    my $span = shift;

    ##### In get Real Position

    my @residues = split //, $ali->get_seq_with_id($seq_id)->seq;
    my @fromstart = @residues[0..$$span[0]];

    my $count_gap_s = grep { $_ =~ $GAP } @fromstart;
    #### $count_gap_s

    if ($count_gap_s) {
        my $nc = grep { $_ =~ $GAP } @residues[0..$$span[0]+$count_gap_s];
        while ( $nc != $count_gap_s ) {
            $count_gap_s = $nc;
            #### $count_gap_s
            $nc = grep { $_ =~ $GAP } @residues[0..$$span[0]+$count_gap_s];
        }
    }

    my $start = $$span[0]+$count_gap_s;

    my $count_gap_e = grep { $_ =~ $GAP } @residues[$start..$$span[1]+$count_gap_s];
    #### $count_gap_e
    if ($count_gap_e && ($$span[1]+$count_gap_s+$count_gap_e)<$#residues) {
        my $nc = grep { $_ =~ $GAP } @residues[$start..$$span[1]+$count_gap_s+$count_gap_e];
        while ( $nc != $count_gap_e ) {
            $count_gap_e = $nc;
            #### $count_gap_e
            $nc = grep { $_ =~ $GAP } @residues[$start..$$span[1]+$count_gap_s+$count_gap_e];
        }
    }

    my $end = ($$span[1]+$count_gap_s+$count_gap_e > $#residues) ? $#residues : $$span[1]+$count_gap_s+$count_gap_e ;

    return ($start , $end);
}


### End of script...

__END__

=pod

=head1 NAME

frameshiftSimul_final.pl - Simulation for HmmCleaner

=head1 VERSION

version 0.243280

=head1 USAGE

frameshiftSimul_final.pl <infiles> --taxdir=<taxdir> [--noX --noStop -nf <nf> -sf <sf> -rep <rep> --profile=<profile>]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

list of alignment file to check with HMMCleaner

=for Euclid: infiles.type: readable
    repeatable

=item --taxdir=<taxdir>

Path to local mirror of the NCBI Taxonomy database as obtain from setup-taxdir.pl

=for Euclid: taxdir.type: string

=back

=head1 OPTIONS

=over

=item -t[hreshold] <threshold>

threshold value determining shifts in sequence compare to HMM model

=for Euclid: threshold.type: 0+integer
    threshold.default: 1

=item -cost1=<cost1>

cost of blank character in profile alignment

=for Euclid: cost1.type: num
    cost1.default: -0.15

=item -cost2=<cost2>

cost of + character in profile alignment

=for Euclid: cost2.type: num
    cost2.default: -0.08

=item -cost3=<cost3>

cost of lowercase character in profile alignment

=for Euclid: cost3.type: num
    cost3.default: 0.15

=item -cost4=<cost4>

cost of uppercase character in profile alignment

=for Euclid: cost4.type: num
    cost4.default: 0.45

=item -nf <nf>

number of frameshift

=for Euclid: nf.type: 0+int

=item -sf <sf>

size of frameshift

=for Euclid: sf.type: +int

=item -rep <rep>

number of replicate for one file

=for Euclid: rep.type: 0+int
    rep.default: 100

=item -subset <subset>

number of seq to keep in file at random

=for Euclid: subset.type: 0+int

=item --noX

Determine that X characters don't have to be consider by HMMER

=item --noStop

Not stopping translation at STOP codon

=item -v[erbosity]=<level>

Verbosity level for logging to STDERR [default: 0]. Available levels range from
0 to 5.

=for Euclid: level.type: int, level >= 0 && level <= 5
    level.default: 0

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Arnaud Di Franco <arnaud.difranco@gmail.fr>

=head1 CONTRIBUTOR

=for stopwords Denis BAURAIN

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Arnaud Di Franco.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
