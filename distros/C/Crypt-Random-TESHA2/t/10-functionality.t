#!/usr/bin/env perl
use strict;
use warnings;
use Crypt::Random::TESHA2 qw/random_bytes random_values irand/;

use Test::More  tests => 2+1+2+10;

{
  my $r;
  $r = Crypt::Random::TESHA2::rand();
  ok( $r >= 0 && $r < 1, "rand() = $r in [0,1)" );
  $r = Crypt::Random::TESHA2::rand(1000);
  ok( $r >= 0 && $r < 1000, "rand(1000) = $r in [0,1000)" );
}

{
  my $i;
  $i = irand();
  ok( $i >= 0 && $i <= 4294967295, "irand() = $i in [0,2**32-1]" );
}

{
  my @values = random_values(10);
  is( scalar @values, 10, "random_values(10) produces 10 values" );
  my $min = ~0;
  my $max = 0;
  foreach my $n (@values) {
    $min = $n if $n < $min;
    $max = $n if $n > $max;
  }
  ok( $min <= 4294967295 && $max >= 0, "All values are in 32-bit range, min $min, max $max" );
}

{
  my $s;
  $s = random_bytes(0);
  is( $s, '', "random_bytes(0) produces the empty string" );
  foreach my $bytes (1 .. 8, 17) {
    $s = random_bytes($bytes);
    is( length($s), $bytes, "random_bytes($bytes) is length $bytes" );
  }
}
