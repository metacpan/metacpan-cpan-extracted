#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Test::More tests=>5;
use FindBin qw/$RealBin/;
use lib "$RealBin/../lib";

use_ok 'Bio::Minimizer';

srand(42);
my @nt = qw(A T C G);
my $alphabetSize = scalar(@nt);
my $sequence = "";
for(1..240){
  $sequence .= $nt[int(rand($alphabetSize))]
}

my $minimizer = Bio::Minimizer->new($sequence);

is($$minimizer{k}, 31, "Expected default kmer length");
is($$minimizer{l}, 21, "Expected default lmer length");

subtest 'Kmer => minimizer' => sub{
  plan tests=>3;
  is($$minimizer{minimizers}{TCAGTCACAAGAGGCGCTCAGACCGACCTGC}, "GAGGCGCTCAGACCGACCTGC");
  is($$minimizer{minimizers}{TTGCTTCACCGCTACGCAGGCCTCTATTCCA}, "GCTACGCAGGCCTCTATTCCA");
  is($$minimizer{minimizers}{GTCCAGCGTCTTTGAGGGTAATCATTCGAGG}, "TTTGAGGGTAATCATTCGAGG");
};

subtest 'Minimizer => kmer' => sub{
  plan tests=>3;

  is($$minimizer{kmers}{TTATGAAGGGTTGCTTCACCG}[0], "GGGCTGATTGTTATGAAGGGTTGCTTCACCG");
  is($$minimizer{kmers}{AGGAACCGGACCTTTAATCAC}[2], "ATCATTCGAGGAACCGGACCTTTAATCACGG");
  is($$minimizer{kmers}{CCAGAATCACTTTTAATACTT}[5], "GGGCCCCAGAATCACTTTTAATACTTTAGTC");
};

