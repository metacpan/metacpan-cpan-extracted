#! /usr/bin/perl -T

use Test::More tests => 4;

use Bio::GeneDesign;
use Bio::Seq;

use strict;
use warnings;

my $GD = Bio::GeneDesign->new();

#TESTING import_seqs
my $seq = "ATGACCGACCAAGCGACGCCCAACCTGCCATCACGAGATTTCGATTCCACCGCCGCCTTCTATGAAA";
$seq .= "GGTTGGGCTTCGGAATCGTTTTCCGGGACGCCCTCGCGGACGTGCTCATAGTCCACGACGCCCGTGATT";
$seq .= "TTGTAGCCCTGGCCGACGGCCAGCAGGTAGGCCGACAGGCTCATGCCGGCCGCCGCCGCCTTTTCCTCA";
$seq .= "ATCGCTCTTCGTTCGTCTGGAAGGCAGTACACCTTGATAGGTGGGCTGCCCTTCCTGGTTGGCTTGGTT";
$seq .= "TCATCAGCCATCCGCTTGCCCTCATCTGTTACGCCGGCGGTAGCCGGCCAGCCTCGCAGAGCAGGATTC";
$seq .= "CCGTTGAGCACCGCCAGGTGCGAATAAGGGACAGTGAAGAAGGAACACCCGGTCGCGGGTGGGCCTACT";
$seq .= "TCACCTATCCTGCCCCGCTGACGCCGTTGGATACACCAAGGAAAGTCTACACGAACCCTTTGGCAAAAT";
$seq .= "CCTGTATATCGTGCGAAAAAGGATGGATATACCGAAAAAATCGCTATAATGACCCCGAAGCAGGGTTAT";
$seq .= "GCAGCGGAAAAGCCATGACCAAAATCCCTTAA";
my $seqobj = Bio::Seq->new( -seq => $seq, -id => "testa");

my $rfilename = "testagene";
my $rsuffix = "fasta";
my ($titerator, $tfilename, $tsuffix) = $GD->import_seqs('t/testagene.fasta');
is($tfilename, $rfilename, 'grab filename');
is($tsuffix, $rsuffix, 'grab suffix');
my @tobjs = ();
while ( my $tobj = $titerator->next_seq() )
{
  push @tobjs, $tobj;
}
is(scalar @tobjs, 1, 'object count');
is($tobjs[0]->seq, $seqobj->seq, 'sequence');