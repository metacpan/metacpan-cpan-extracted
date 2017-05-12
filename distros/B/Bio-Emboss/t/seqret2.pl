#!/usr/bin/perl 
use ExtUtils::testlib;

# --- don't import any functions into this namespace (the default)
use Bio::Emboss;

use strict;
use vars qw($emboss $seqall $seq $seqout $firstonly);

@ARGV = qw(swissprot:edd_* -stdout -auto) if $ARGV[0] eq "-demo";

Bio::Emboss::embInitPerl("seqret", \@ARGV); 

$seqall = Bio::Emboss::ajAcdGetSeqall("sequence"); 
$seqout = Bio::Emboss::ajAcdGetSeqoutall("outseq"); 

$firstonly = Bio::Emboss::ajAcdGetBool ("firstonly");


while ($seqall->ajSeqallNext($seq)) {
    $seqout->ajSeqAllWrite ($seq);

    last if ($firstonly);
}

$seqout->ajSeqWriteClose();

Bio::Emboss::ajExit();
