#!/usr/bin/perl 
use ExtUtils::testlib;

# --- import all EMBOSS functions into this namespace
use Bio::Emboss qw(:all);

use strict;
use vars qw($emboss $seqall $seq $seqout $firstonly);

@ARGV = qw(swissprot:edd_* -stdout -auto) if $ARGV[0] eq "-demo";

embInitPerl("seqret", \@ARGV); 

$seqall = ajAcdGetSeqall("sequence"); 
$seqout = ajAcdGetSeqoutall("outseq"); 

$firstonly = ajAcdGetBool ("firstonly");


while ($seqall->ajSeqallNext($seq)) {
    $seqout->ajSeqAllWrite ($seq);

    last if ($firstonly);
}

$seqout->ajSeqWriteClose();

ajExit();
