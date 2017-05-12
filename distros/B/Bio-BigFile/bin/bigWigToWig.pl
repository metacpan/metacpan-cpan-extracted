#!/usr/bin/perl

use strict;
use lib './lib','./blib/lib','./blib/arch';

use Bio::DB::BigWig;

my $file = shift or die <<USAGE;
Usage: $0 in.bw

Given the path to a BigWig file, dumps its contents as a regular WIG
file (but without the track lines)
USAGE

my $wig  = Bio::DB::BigWig->new(-bigwig=>$file) or die "$file: $!";
my $iterator = $wig->get_seq_stream();
while (my $p = $iterator->next_seq) {
    my $seqid = $p->seq_id;
    my $start = $p->start;
    my $end   = $p->end;
    my $val   = $p->score;
    print join("\t",$seqid,$start,$end,$val),"\n";
}


