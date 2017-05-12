#!/usr/bin/perl 
use ExtUtils::testlib;

use Bio::Emboss;

use strict;
use vars qw($seqall $seqobj);

@ARGV = qw(swissprot:edd_* -stdout -auto);

Bio::Emboss::embInitPerl("seqret", \@ARGV); 

$seqall = Bio::Emboss::ajAcdGetSeqall("sequence"); 

while ($seqall->ajSeqallNext($seqobj)) {
    my ($begin, $end, $len);

    $seqobj->ajSeqGetRange($begin, $end);
    $len = $seqobj->ajSeqLen();

    my $seqchar  = $seqobj->ajSeqChar();

    my $seqchar2 = $seqobj->ajSeqStrCopy()->ajStrStr();

    die ("wrong copy") if $seqchar ne $seqchar2;

    print (">", $seqobj->ajSeqName(),
	   " len:$len begin:$begin end:$end\n"); 

    my $width  = 70;
    my $offset = 0;

    my ($substr);
    while ($substr = substr($seqchar, $offset, $width)) {
	$offset += $width;
	print ($substr, "\n");
    }

}
