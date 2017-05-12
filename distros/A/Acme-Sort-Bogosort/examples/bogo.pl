#!/usr/bin/perl

use strict;
use warnings;
use Acme::Sort::Bogosort;

my @unsorted  = qw/ E B A C D /;
my @ascending = bogosort( @unsorted );

my @descending = bogosort(
  sub { return $_[1] cmp $_[0] },
  @unsorted
);

print "@ascending\n";
print "@descending\n";
 
