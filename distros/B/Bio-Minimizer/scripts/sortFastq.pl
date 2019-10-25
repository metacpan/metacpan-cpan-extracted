#!/usr/bin/env perl

use strict;
use warnings;
use Bio::Minimizer;

my @entry;
while(my $id = <STDIN>){
  chomp($id);
  my $seq = <STDIN>;
  my $plus= <STDIN>;
  my $qual= <STDIN>;
  chomp($seq, $plus, $qual);

  # Minimizer object
  my $minimizer = Bio::Minimizer->new($seq,{k=>length($seq),l=>21});
  my $theOnlyMinimizer = (values(%{$$minimizer{minimizers}}))[0]; 

  # combine the minimum minimizer with the entry, for
  # sorting later.
  # Save the entry as a string so that we don't have to
  # parse it later.
  my $entry = [$theOnlyMinimizer, "$id\n$seq\n$plus\n$qual\n"];
  push(@entry,$entry);
}

# Sort entries by minimizer
for my $e(sort {$$a[0] cmp $$b[0]} @entry){
  # Print entries in order of minimizer
  print $$e[1];
}

