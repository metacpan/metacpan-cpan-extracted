#!/usr/bin/env perl
# created on 2014-01-09

use warnings;
use strict;
use 5.010;

$| = 1;
my @data;
my $i = 0;
while (1) {

  for ( my $i = 0; $i < 100000; $i++ ) {
    push @data, join( "", 'a' .. 'z', 'A' .. 'Z' );
  }
  say calc_pi(10000);

  undef @data if($i++ > 100);
  sleep 1;
}

sub calc_pi {
  my $cycles = shift;
  my ( $i, $yespi, $pi ) = 0;
  srand;
  while ( $i < $cycles ) {
    my ( $x, $y, $cdnt ) = 0;
    $x    = rand;
    $y    = rand;
    $cdnt = $x**2 + $y**2;
    if ( $cdnt <= 1 ) {
      ++$yespi;
    }
    ++$i;
  }
  $pi = ( $yespi / $cycles ) * 4;
  return $pi;
}
