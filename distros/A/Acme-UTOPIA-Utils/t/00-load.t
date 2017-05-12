#!perl -T
use v5.10.1;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
  foreach my $pkg ( qw( Acme::UTOPIA::Utils ) ) {
    use_ok( $pkg ) || print "Bail out!\n";
  }
}
