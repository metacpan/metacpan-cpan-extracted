#!/usr/bin/perl

use strict;
use warnings;
use Acme::Sort::Bozo;

my @unsorted  = qw/ E B A C D /;
my @ascending = bozo( @unsorted );

my @descending = bozo(
  sub { return $_[1] cmp $_[0] },
  @unsorted
);

print "@ascending\n";
print "@descending\n";
 
