#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Test::More tests=>2;
use FindBin qw/$RealBin/;
use lib "$RealBin/../lib";

use_ok 'Bio::Minimizer';

subtest 'sorting fastqs to make smaller filesize' => sub{
  my $numTests = 3;
  plan tests => $numTests;

  for(1..$numTests){
    # Create a reference genome
    my @nt = qw(A T C G);
    my $alphabetSize = scalar(@nt);
    my $sequence = "";
    my $genomeSize = 1000000;
    for(1..$genomeSize){ # 5Mbp genome
      $sequence .= $nt[int(rand($alphabetSize))]
    }

    note "Simulating reference genome ".substr($sequence,0,10)."...${genomeSize}bp...".substr($sequence,-10,10);

    # Simulate the reference genome into 100k reads
    my $readLength = 250;
    my $qual = 'I' x $readLength;
    open(my $fh, '>', "$RealBin/simulated.fastq") or die "ERROR: could not write to $RealBin/simulated.fastq: $!";
    for(my $i=0;$i<100000;$i++){
      my $start = int(rand($genomeSize-$readLength));
      my $seq = substr($sequence, $start, $readLength);
      # Revcom half of the reads
      if(rand(1) < 0.5){
        $seq = reverse($seq);
        $seq =~ tr/ATCG/TAGC/;
      }

      print $fh "\@read$i pos$start\n$seq\n+\n$qual\n";
    }
    close $fh;

    # Sort the simulated file
    system("gzip -f $RealBin/simulated.fastq"); # gzip first

    system("zcat $RealBin/simulated.fastq.gz | perl -I$RealBin/../lib scripts/sortFastq.pl | gzip -fc > $RealBin/sorted.fastq.gz");
    die if $?;

    my $simulatedSize = (stat("$RealBin/simulated.fastq.gz"))[7];
    my $sortedSize    = (stat("$RealBin/sorted.fastq.gz"))[7];
    my $reduction = sprintf("%0.2f",$sortedSize/$simulatedSize * 100);

    diag "Filesize reduction when sorted: $reduction%";
    cmp_ok($simulatedSize, '>', $sortedSize, "File sizes ($simulatedSize > $sortedSize, $reduction%)");
  }
};

