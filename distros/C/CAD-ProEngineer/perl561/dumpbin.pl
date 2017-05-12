#!/bin/perl

print "EXPORTS", "\n";

while (<>) {
  chomp;
  @F = split /\s+/;
  ($Symbol = $F[$#F]) =~ s/^_//;
  if (m/External/ and m/ _(Pro|user_)/ and not m/_1$/) {
    $SymbolHash{$Symbol}++;
  }
}

foreach $Symbol (sort keys %SymbolHash) {
  print $Symbol, "\n";
}

