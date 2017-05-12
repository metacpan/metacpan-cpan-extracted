#!/usr/bin/perl

# launch it like "perl regex_parser_test.pl Homo_sapiens" (Homo_sapiens can be downloaded
# and decompressed from ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/ASN/Mammalia/Homo_sapiens.gz)
# or use the included test file "perl regex_parser_test.pl ../t/input.asn"

use strict;
use Dumpvalue;
use Bio::ASN1::EntrezGene;
use Benchmark;

my $parser = Bio::ASN1::EntrezGene->new(file => $ARGV[0]); # instantiate a parser object
my ($t0, $end, $i) = (new Benchmark, 10, 0); # process the first 10 records in the input file
while(my $value = $parser->next_seq)
{
#   Dumpvalue->new->dumpValue($value); # uncomment to dump the data structure out
  last if ++$i >= $end; # only process the first 20 records
}
my $t1 = new Benchmark;
print "The first $i records in $ARGV[0] took EntrezGene parser:",timestr(timediff($t1, $t0)),"\n";

