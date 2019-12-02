# -*-Perl-*- Test Harness script for Bioperl
# $Id$

use strict;

BEGIN {
		use Test::Most tests => 9;
		use Test::RequiresInternet;
		use_ok('Bio::SeqIO::entrezgene');
		use_ok('Bio::DB::EntrezGene');
}

my %params;

if (defined $ENV{BIOPERLEMAIL}) {
    $params{'-email'} = $ENV{BIOPERLEMAIL};
    $params{'-delay'} = 2;
}

$params{'-verbose'} = $ENV{BIOPERLDEBUG};


my ($gb, $seq, $seqio);
ok $gb = Bio::DB::EntrezGene->new(-retrievaltype => 'tempfile', %params);

#
# Bio::DB::EntrezGene
#

SKIP: {
	eval {$seqio = $gb->get_Stream_by_id([2,3064]);};
    skip "Couldn't connect to Entrez with Bio::DB::EntrezGene. Skipping those tests", 6 if $@;
    $seq = $seqio->next_seq;
    is $seq->display_id, "A2M";
    is $seq->accession_number, 2;
    $seq = $seqio->next_seq;
    is $seq->display_id, "HTT";
    is $seq->accession_number, 3064;
    eval {$seq = $gb->get_Seq_by_id(6099);};
    skip "Couldn't connect to Entrez with Bio::DB::EntrezGene. Skipping those tests", 2 if $@;
    is $seq->display_id, "RP";
    is $seq->accession_number, 6099;
}
