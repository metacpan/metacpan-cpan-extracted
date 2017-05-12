#!/usr/bin/perl

# launch it like "perl indexer_test.pl Homo_sapiens" (Homo_sapiens can be downloaded
# and decompressed from ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/ASN/Mammalia/Homo_sapiens.gz)
# or use the included test file "perl indexer_test.pl ../t/input.asn ../t/input1.asn"

use strict;
use lib 'lib';
use lib '/home/liu/cvs/bioperl-1.5.0';
use lib '/home/liu/important/scripts/ari_geneindex';
use Bio::ASN1::EntrezGene::Indexer;
use Dumpvalue;
use Benchmark;

# creation of index:
my $file = 'entrezgene.idx';
my $inx = Bio::ASN1::EntrezGene::Indexer->new(
  -filename => $file,
  -write_flag => 'WRITE');
my $t0 = new Benchmark;
$inx->make_index(@ARGV);
my $t1 = new Benchmark;
print "Indexing @ARGV took:",timestr(timediff($t1, $t0)),"\n";

# using the index:
my $geneid = 3;
# below is not needed in this script but it's the preferred calling way if
# one's just using an existing index file
# my $inx = Bio::ASN1::EntrezGene::Indexer->new(-filename => 'entrezgene.idx');
print "there are a total of " . $inx->count_records . " records\n";
my $t0 = new Benchmark;
# uncomment below to test retrieving Bio::Seq obj
# my $seq = $inx->fetch($geneid); # Bio::Seq obj returned by Bio::SeqIO::entrezgene.pm
my $seq1 = $inx->fetch_hash($geneid); # a hash produced by Bio::ASN1::EntrezGene
                           # that contains all data in the Entrez Gene record
my $t1 = new Benchmark;
print "Retrieving Entrez Gene #$geneid took:",timestr(timediff($t1, $t0)),"\n";
# Dumpvalue->new->dumpValue($seq);
Dumpvalue->new->dumpValue($seq1);

