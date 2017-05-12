#!/usr/bin/env perl
# created on 2015-01-30

use warnings;
use strict;
use 5.010;



use Bio::Gonzales::Seq;
use Bio::Gonzales::Seq::Filter qw/clean_dna_seq/;

my $fait = faiterate(\*STDIN);
while ( my $so = $fait->() ) {
  clean_dna_seq($so);
  print $so;
}
