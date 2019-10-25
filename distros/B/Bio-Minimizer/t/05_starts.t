#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Test::More tests=>3;
use FindBin qw/$RealBin/;
use lib "$RealBin/../lib";

use_ok 'Bio::Minimizer';

my $sequence = "CTATAGTTCGTCCAGCGTCTTTGAGGGTAATCATTCGAGGAACCGGACCTTTAATCACGGCTTACTTCAGTCACAAGAGGCGCTCAGACCGACCTGCATCTGGTCAGGGCCCCAGAATCACTTTTAATACTTTAGTCGGTACGTGAGGGACAGACCCAAAGGTACCGGGGCTGATTGTTATGAAGGGTTGCTTCACCGCTACGCAGGCCTCTATTCCAGACCGCTAGGCTTCTAACCTGC";

subtest 'minimizer => starts (k=>19,l=>5)' => sub{
  plan tests=>7;
  my $minimizer = Bio::Minimizer->new($sequence,{numcpus=>1,k=>19,l=>5});
  is($$minimizer{k}, 19, "Expected kmer length");
  is($$minimizer{l},  5, "Expected lmer length");

  my $starts = $minimizer->{starts};
  is_deeply([sort {$a <=> $b } @{ $$starts{AATCA}}], [28,52,64,115], "AATCA");
  is_deeply([sort {$a <=> $b } @{ $$starts{AGCCT}}], [10], "AGCCT");
  is_deeply([sort {$a <=> $b } @{ $$starts{ACGTA}}], [96], "ACGTA");
  is_deeply([sort {$a <=> $b } @{ $$starts{AGACC}}], [217], "AGACC");
  is_deeply([sort {$a <=> $b } @{ $$starts{AGATG}}], [139], "AGATG");
};

subtest 'minimizer => starts (k=>31,l=>21)' => sub{
  plan tests=>5;

  my $minimizer = Bio::Minimizer->new($sequence,{numcpus=>1});
  is($$minimizer{k}, 31, "Expected default kmer length");
  is($$minimizer{l}, 21, "Expected default lmer length");

  my $starts = $minimizer->{starts};

  is_deeply($$starts{ACTTTAGTCGGTACGTGAGGG}, [128], "ACTTTAGTCGGTACGTGAGGG");
  is_deeply($$starts{AGCCTAGCGGTCTGGAATAGA}, [10],  "AGCCTAGCGGTCTGGAATAGA");
  is_deeply($$starts{CCGGTTCCTCGAATGATTACC}, [194], "CCGGTTCCTCGAATGATTACC");
};
