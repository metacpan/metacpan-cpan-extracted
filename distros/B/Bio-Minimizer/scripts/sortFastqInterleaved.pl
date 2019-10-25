#!/usr/bin/env perl

use strict;
use warnings;
use Bio::Minimizer;

my @entry;
while(my $id1 = <STDIN>){
  my $seq1 = <STDIN>;
  my $plus1= <STDIN>;
  my $qual1= <STDIN>;
  my $id2  = <STDIN>;
  my $seq2 = <STDIN>;
  my $plus2= <STDIN>;
  my $qual2= <STDIN>;
  chomp($id1, $seq1, $plus1, $qual1, $id2, $seq2, $plus2, $qual2);

  # Minimizer object
  my $minimizer = Bio::Minimizer->new($seq1,{k=>length($seq1),l=>21});
  my $theOnlyMinimizer = (values(%{$$minimizer{minimizers}}))[0]; 

  # combine the minimum minimizer with the entry, for
  # sorting later.
  # Save the entry as a string so that we don't have to
  # parse it later.
  my $entry = [$theOnlyMinimizer, "$id1\n$seq1\n$plus1\n$qual1\n$id2\n$seq2\n$plus2\n$qual2\n"];
  push(@entry,$entry);
}

# Sort entries by minimizer
for my $e(sort {$$a[0] cmp $$b[0]} @entry){
  # Print entries in order of minimizer
  print $$e[1];
}

