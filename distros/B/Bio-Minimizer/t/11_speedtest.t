#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Test::More tests=>4;
use FindBin qw/$RealBin/;
use lib "$RealBin/../lib";
use List::MoreUtils qw/uniq/;
use Benchmark ':all';

use Bio::Minimizer;

my $sequence="CTATAGTTCGTCCAGCGTCTTTGAGGGTAATCATTCGAGGAACCGGACCTTTAATCACGGCTTACTTCAGTCACAAGAGGCGCTCAGACCGACCTGCATCTGGTCAGGGCCCCAGAATCACTTTTAATACTTTAGTCGGTACGTGAGGGACAGACCCAAAGGTACCGGGGCTGATTGTTATGAAGGGTTGCTTCACCGCTACGCAGGCCTCTATTCCAGACCGCTAGGCTTCTAACCTGC";

sub speedPerThread{
  my($thread) = @_;
  my $stderr="";
  open(local *STDERR, '>', \$stderr); # suppress cpus warning
  my $minimizer = Bio::Minimizer->new($sequence,{numcpus=>$thread});
  return $$minimizer{minimizers}{TCAGTCACAAGAGGCGCTCAGACCGACCTGC};
}

is(speedPerThread(1), "AAGAGGCGCTCAGACCGACCT", "1 thread");
is(speedPerThread(2), "AAGAGGCGCTCAGACCGACCT", "2 thread");
is(speedPerThread(4), "AAGAGGCGCTCAGACCGACCT", "4 thread");
is(speedPerThread(8), "AAGAGGCGCTCAGACCGACCT", "8 thread");

note "Testing random 1kb sequence with differing thread counts";
my $cmpChart = "";
{
  open(local *STDOUT, '>', \$cmpChart) or die "ERROR writing to string: $!";
  cmpthese(1e3, {
      "1-thread" => sub{speedPerThread(1)},
      "2-thread" => sub{speedPerThread(2)},
      "4-thread" => sub{speedPerThread(4)},
      "8-thread" => sub{speedPerThread(8)},
    }
  );
};
diag $cmpChart;

