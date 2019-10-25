#!/usr/bin/env perl

use strict;
use warnings;
use Bio::Minimizer;
use Data::Dumper;

my $sequence = "";
while(<STDIN>){
  s/^\s+|\s+$//g;  # whitespace trim
  next if(/^>/);

  $sequence .= $_;
}
close STDIN;

$sequence =~ s/\s+//g; # remove any whitespace in the sequence

print STDERR "Getting minimizers on a sequence of length ".length($sequence)."\n";

my $minObj    = Bio::Minimizer->new($sequence);

print STDERR "Printing\n";
my $starts    = $$minObj{starts};
my @minimizer = sort{$$starts{$a}[0] <=> $$starts{$b}[0]} keys(%$starts);
for my $m(@minimizer){
  print "$m\t";
  print join(",", @{$$starts{$m}})."\n";
}

