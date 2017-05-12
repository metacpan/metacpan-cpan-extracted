#!/usr/bin/perl

# launch it like "perl parse_sequence_example.pl seq.asn1"
# one can use the included test file "perl parse_sequence_example.pl ../t/seq.asn"

use strict;
use Dumpvalue;
use Bio::ASN1::Sequence;
use Benchmark;

my $parser = Bio::ASN1::Sequence->new(file => $ARGV[0]); # instantiate a parser object
my ($t0, $end, $i) = (new Benchmark, 10, 0); # process the first 10 records in the input file
while(my $value = $parser->next_seq)
{
  Dumpvalue->new->dumpValue($value); # uncomment to dump the data structure out
  last if ++$i >= $end; # only process the first 20 records
}
my $t1 = new Benchmark;
print "The first $i records in $ARGV[0] took Sequence parser:",timestr(timediff($t1, $t0)),"\n";

