package Bio::MUST::Drivers::Exonerate::Aligned;
# ABSTRACT: Bio::MUST driver for running the exonerate alignment program
$Bio::MUST::Drivers::Exonerate::Aligned::VERSION = '0.191910';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say switch);
use experimental qw(smartmatch);        # to suppress warnings about 'when'

# use Smart::Comments '###';

use Carp;
use Const::Fast;
use IPC::System::Simple qw(system);
use Module::Runtime qw(use_module);
use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:gaps);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::Seq';


has 'dna_seq' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Seq',
    required => 1,
);

has 'pep_seq' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Seq',
    required => 1,
);

# TODO: homogeneize with main class
has 'code' => (
    is       => 'ro',
    isa      => 'Str',
    default  => '1',
);

has 'model' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    writer   => '_set_model',
);

has $_ => (
    is       => 'ro',
    isa      => 'Num',
    init_arg => undef,
    writer   => '_set_' . $_,
) for qw(
     query_start  query_end
    target_start target_end
    score
);

has $_ . '_seq' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Seq',
    init_arg => undef,
    writer   => '_set_' . $_,
) for qw(query target spliced);


# TODO: subclass this to avoid code repetition with main class
# TODO: handle reverse complement

sub BUILD {
    my $self = shift;

    # provision executable
    my $app = use_module('Bio::MUST::Provision::Exonerate')->new;
       $app->meet();

    # build temp Ali file for input DNA seq
    my $dna = Ali->new(
        seqs => [ $self->dna_seq ],
        guessing => 0,
    );
    my $dnafile = $dna->temp_fasta;

    # build temp Ali file for input PEP seq
    my $pep = Ali->new(
        seqs => [ $self->pep_seq ],
        guessing => 0,
    );
    my $pepfile = $pep->temp_fasta;

    # execute exonerate
    my $outfile = $self->_exonerate($dnafile, $pepfile);

    # parse outfile and populate seqs
    $self->_parse_outfile($outfile);

    # check that everything ran fine
    unless ( $self->query_seq->seq_len ) {
        carp '[BMD] Warning: exonerate could not align seqs;'
            . ' returning empty seqs!';
        ### dnafile: join q{}, "\n", file($dnafile)->slurp
        ### pepfile: join q{}, "\n", file($pepfile)->slurp
    }
    elsif  ( $self->query_seq->seq_len != $self->target_seq->seq_len ) {
        carp '[BMD] Warning: query and target seqs not of same length!';
        ### dnafile: join q{}, "\n", file($dnafile)->slurp
        ### pepfile: join q{}, "\n", file($pepfile)->slurp
    }
    elsif  ( $self->spliced_seq->seq_len != 3 * $self->target_seq->seq_len ) {
        carp '[BMD] Warning: DNA and protein target seqs not of same length!';
        ### dnafile: join q{}, "\n", file($dnafile)->slurp
        ### pepfile: join q{}, "\n", file($pepfile)->slurp
    }

    # unlink temp files
    file($_)->remove for ($dnafile, $pepfile, $outfile);

    return;
}


const my %ARGS_FOR => (
    'lc' => 'protein2genome',
    'bf' => 'protein2genome:bestfit --exhaustive',
);

const my $NEW_HSP => qr{C4 \s Alignment:}xms;

sub _exonerate {
    my $self    = shift;
    my $dnafile = shift;
    my $pepfile = shift;

    # first try with heuristic 'protein2genome' model
    # if it yields > 1 HSPs try with exhaustive 'protein2genome:bestfit' model
    # it this better model fails then return first HSP from lesser model

    my $pgm = 'exonerate';
    my $code = $self->code;

    my $return = q{};
    my $remove = q{};

    my %outfile_for;
    my $hsp_n;

    MODEL:
    for my $model ( qw(lc bf) ) {

        $remove = $return;          # lesser model failed (if any)
        $return = $model;           # try better model

        # create exonerate command
        my $outfile = $dnafile . ".exo.$model.out";
        $outfile_for{$model} = $outfile;
        my $cmd = qq{$pgm --showvulgar no --showalignment yes}
            . ' --alignmentwidth 100000'    # needed for robust splicing
            . " --verbose 0 --geneticcode $code --model " . $ARGS_FOR{$model}
            . " --target $dnafile --query $pepfile > $outfile 2> /dev/null"
        ;
        #### $cmd

        # Note: we ask for a single-line alignment to avoid the difficult
        # parsing of linebreak-interrupted runs of spaces within introns

        # try to robustly execute exonerate
        my $ret_code = system( [ 0, 1, 127, 139 ], $cmd);
        if ($ret_code == 127) {
            carp "[BMD] Warning: cannot execute $pgm command;"
                . ' returning nothing!';
            return;     # This will likely crash calling code but that's OK.
        }
        if ($ret_code == 139) {
            carp "[BMD] Warning: $pgm crashed; skipping model: $model!";
            # do nothing more to leave loop with accurate $hsp_n
        }
        if ($ret_code == 1) {
            carp "[BMD] Warning: $pgm crashed because of a bad nt seq!";
            return $outfile_for{$model};
        }
        # TODO: try to bypass shell (need for absolute path to executable then)

        # check number of HSPs in outfile
        my @lines = file($outfile)->slurp;
        $hsp_n = grep { m/$NEW_HSP/xms } @lines;

        # stop here if only one; otherwise possibly try better model
        last MODEL if $hsp_n == 1;
    }

    # if no HSP then better model was tried and finally failed
    # thus switch back to lesser model (with > 1 HSPs)
    if ($hsp_n == 0) {
        carp "[BMD] Warning: cannot get only one HSP from $pgm;"
            . ' returning first one!';
        ($return, $remove) = ($remove, $return);
    }

    #### $remove
    #### $return

    # delete unused file (if any) and return outfile
    file( $outfile_for{ $remove} )->remove;
    $self->_set_model(  $return);

    return $outfile_for{$return};
}


#      Raw score: 1215
#    Query range: 0 -> 247
#   Target range: 1429 -> 2184

#    43 : ysGlyIleValLysGluIleIle<->AspProGlyArgGlyAlaProLeuAlaArgValVal :   61
#         |||||||||||||||||||||||   ||||||||||||||||||||||||||||||||||||
#         ysGlyIleValLysGluIleIleHisAspProGlyArgGlyAlaProLeuAlaArgValVal
#  1554 : AGGGCATAGTGAAAGAAATCATACACGACCCAGGAAGAGGCGCTCCCTTAGCCAGAGTTGTT : 1613
#
# ...
#
#   145 : sThrArgValArgLeuProSerGlySerLysLysValLeuSerSerThrAsnArg-AlaVal :  164
#         |||||||||||||||||||||||||||||||||||||||||||||||||||||||#.!!|||
#         sThrArgValArgLeuProSerGlySerLysLysValLeuSerSerThrAsnArg#UnkVal
#  1863 : AACGCGCGTGCGTCTTCCGTCAGGATCGAAAAAGGTGCTATCGTCGACGAATCGAGNCCGTG : 1923
#
# ...
#
#  177 : gGlnArgLysAlaHisLeuIleGluIleGlnValAsnGlyGlyThrValAlaGlnLysValAsp : 197
#        ||||!:!||||||||||||!!:|||||||||||||||||||||:!!|||||| !!|||||||||
#        gGlnLysLysAlaHisLeuMetGluIleGlnValAsnGlyGlySerValAla***LysValAsp
#  321 : GCAAAAGAAGGCCCACCTTATGGAAATCCAAGTCAATGGTGGATCCGTTGCGTAAAAGGTCGAC : 383
#
# ...
#
#   91 : rgLysHisProTrpHisValIleArgIleAsnLysMetLeuSerCysAlaGlyAlaAspArg{L : 111
#        ||:!!|||||||||||||||:!!|||||||||||||||||||||||||||||||||||||||{|
#        rgGlnHisProTrpHisValLeuArgIleAsnLysMetLeuSerCysAlaGlyAlaAspArg{L
#  257 : GACAACATCCATGGCACGTTCTTAGAATCAACAAGATGCTTTCCTGCGCAGGTGCCGATAGA{C : 319
#
#  112 : e}  >>>> Target Intron 1 >>>>  {u}GlnGlnGlyMetArgGlyAlaPheGlyLys : 121
#        |}            86 bp            {|}      |||||||||  !||||||||||||
#        e}++                         --{u}UnkUnkGlyMetArgHisAlaPheGlyLys
#  320 : T}gt.........................nn{N}NNNNNCGGTATGAGACATGCTTTCGGAAAG : 435
#
# ...
#
#  126 : SerGlnAlaLeuAspValIleHisGluTyrPheLys :  137
#        !!!! !||||||!!: !!:!!     !     !|||
#        ThrProAlaLeuGluPheValUnkUnkValHisLys
#  689 : ACGCCAGCTCTGGAGTTCGTAAKGRGAGTACATAAG :  652

# regexes for parsing outfile
const my  $LEFT_NUM => qr{-?\d+\s+:}xms;
const my $RIGHT_NUM => qr{:\s+-?\d+}xms;
const my   $SEQ_STR => qr{[A-Za-z0-9\.\#\*\+\-\<\>\{\}\ ]+}xms;

sub _parse_outfile {
    my $self    = shift;
    my $outfile = shift;

    # read output file (human-readable alignment)
    open my $out, '<', $outfile;
    #### $outfile

    my   $query_seq = q{};
    my  $target_seq = q{};
    my $spliced_seq = q{};

    my    $hsp_n = 0;
    my $in_block = 0;

    LINE:
    while (my $line = <$out>) {
        chomp $line;
        ##### $line

        given ($line) {

            # header lines
            when (/$NEW_HSP/xms) {
                $hsp_n++;
                last LINE if $hsp_n > 1;        # process only first HSP
            }
            when (/^ \s*Raw \s score:\s (\d+) /xms) {
                $self->_set_score( $1 );
            }
            when (/^ \s*Query  \s range:\s (\d+) \s->\s (\d+) /xms) {
                $self->_set_query_start( $1 + 1 );
                $self->_set_query_end(   $2);
            }   # Note: coordinates are converted to BLAST/GFF standard
            when (/^ \s*Target \s range:\s (\d+) \s->\s (\d+) /xms) {
                $self->_set_target_start( $1 + 1 );
                $self->_set_target_end(   $2);
            }   # Note: coordinates are converted to BLAST/GFF standard

            # alignment lines
            when (/^ \s* $LEFT_NUM \s ($SEQ_STR) \s $RIGHT_NUM \s* $/xms) {
                unless ($in_block) {
                    # this is query line
                    $query_seq .= $1;
                    $in_block = 1;
                    <$out>;             # skip midline (may be hard to parse)
                }
                else {
                    # this is DNA
                    $spliced_seq .= $1;
                    $in_block = 0;
                }
            }
            when (/^ \s+              ($SEQ_STR)               \s* $/xms) {
                # this is likely target line
                $target_seq .= $1 if $in_block;
            }
        }
    }

    # remove introns and frameshifts in all seqs simultaneously
    ($query_seq, $target_seq, $spliced_seq)
        = _splice_seqs($query_seq, $target_seq, $spliced_seq);

    # store aligned pep seqs
    $self->_set_query(
        Seq->new(
            seq_id => $self->pep_seq->full_id,
            seq    => _canonize_seq(1,   $query_seq)
        )
    );
    $self->_set_target(
        Seq->new(
            seq_id => $self->dna_seq->full_id,
            seq    => _canonize_seq(1,  $target_seq)
        )
    );
    $self->_set_spliced(
        Seq->new(
            seq_id => $self->dna_seq->full_id,
            seq    => _canonize_seq(0, $spliced_seq)
        )
    );

    return;
}


# regexes for splicing seqs
const my $ANGLES    => qr{(?:<|>){4}}xms;
const my $TARGET    => qr{Target \s Intron \s \d+}xms;
const my $INTRON    => qr{\s{2} $ANGLES \s $TARGET \s $ANGLES \s{2}}xms;

sub _splice_seqs {
    my   $query_seq = shift;
    my  $target_seq = shift;
    my $spliced_seq = shift;
    ####   $query_seq
    ####  $target_seq
    #### $spliced_seq

    # preserve framshifts in target_seq
    # Note: this is needed to avoid splicing out real frameshifts below
    $target_seq =~ s/\#{2}\-{3}/##Unk/xmsg;     # 1-nt deletion frameshifts
    $target_seq =~ s/\#{3}       /Unk/xmsg;     # ???

    # store intron pos and 'lengths' in query_seq
    my @introns;
    while ($query_seq =~ m/($INTRON)/xmsg) {
        my $len = length $1;
        my $pos = pos($query_seq) - $len;
        push @introns, [ $pos, $len ];
    }

    # store frameshift pos and 'lengths' in target_seq
    while ($target_seq =~ m/(\#+)/xmsg) {
        my $len = length $1;
        my $pos = pos($target_seq) - $len;
        push @introns, [ $pos, $len ];
    }

    # splice out introns starting from seq ends
    # @introns
    for my $intron (sort { $b->[0] <=> $a->[0] } @introns) {
        my ($pos, $len) = @{$intron};
        my   $query_in = substr   $query_seq, $pos, $len, q{};
        my  $target_in = substr  $target_seq, $pos, $len, q{};
        my $spliced_in = substr $spliced_seq, $pos, $len, q{};

        ####   $query_in
        ####  $target_in
        #### $spliced_in
    }

    ####   $query_seq
    ####  $target_seq
    #### $spliced_seq

    return ($query_seq, $target_seq, $spliced_seq);
}


const my %SHORT_FOR => (
    Ala  => 'A',
    Asx  => 'B',
    Cys  => 'C',
    Asp  => 'D',
    Glu  => 'E',
    Phe  => 'F',
    Gly  => 'G',
    His  => 'H',
    Ile  => 'I',
    Lys  => 'K',
    Leu  => 'L',
    Met  => 'M',
    Asn  => 'N',
    Pro  => 'P',
    Gln  => 'Q',
    Arg  => 'R',
    Ser  => 'S',
    Thr  => 'T',
    Val  => 'V',
    Trp  => 'W',
    Xaa  => 'X',
    Tyr  => 'Y',
    Glx  => 'Z',
    Unk  => $FRAMESHIFT,
   '---' => '-',
);

sub _canonize_seq {
    my $prot = shift;
    my $seq3 = shift;
    #### $seq3

    # example of 1-nt deletion
    # ArgGlyAsnAla--GlyGlyGlnHisHisHisArgIle...LysPhePheThrArgArgAlaGlu--GluLysIleLys
    #
    # ArgGlyAsnAla##---GlyGlnHisHisHisArgIle...LysPhePheThrArgArgAlaGlu##---LysIleLys
    # CGTGGTAATGCTGT---GGTCAGCACCACCACAGAATT...AAGTTCTTCACACGCCGTGCTGAGGA---AAGATCAAG

    # ensure no residual frameshift
    $seq3 =~ tr/\{\}//d;                # spliced codons
    $seq3 =~ s/\<\-\>/---/xmsg;         # insertion
    $seq3 =~ s/\*{3} /Unk/xmsg;         # STOP
    #### $seq3

    return $seq3 unless $prot;

    # 'translate' 3-letter AAs to 1-letter AAs
    my $seq1 = q{};
    for (my $i = 0; $i < length $seq3; $i += 3) {
        my $triplet = substr $seq3, $i, 3;
        $seq1 .= $SHORT_FOR{ $triplet };
    }
    #### $seq1

    return $seq1;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Exonerate::Aligned - Bio::MUST driver for running the exonerate alignment program

=head1 VERSION

version 0.191910

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
