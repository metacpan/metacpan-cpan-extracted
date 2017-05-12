#!/usr/bin/env perl
use strict;
use warnings;
use Crypt::Random::Seed;

# NOTE: Just like random_bytes, try to read as little as possible.

use Test::More  tests => 9;

my $source = Crypt::Random::Seed->new(NonBlocking=>1);

{
  my @vals = $source->random_values();
  is( scalar @vals, 0, "random_values() returns empty array");
}
{
  my @vals = $source->random_values(undef);
  is( scalar @vals, 0, "random_values(undef) returns empty array");
}
{
  my @vals = $source->random_values(-1);
  is( scalar @vals, 0, "random_values(-1) returns empty array");
}
{
  my @vals = $source->random_values(0);
  is( scalar @vals, 0, "random_values(0) returns empty array");
}
{
  my @vals = $source->random_values(0.8);
  is( scalar @vals, 0, "random_values(0.8) returns empty array");
}
{
  my @vals = $source->random_values(2);
  is( scalar @vals, 2, "random_values(2) returns two values");
  ok( $vals[0] >= 0 && $vals[0] <= 4294967295, "  first value in range");
  ok( $vals[1] >= 0 && $vals[1] <= 4294967295, "  second value in range");
}

# All in one.
my @seeds = Crypt::Random::Seed->new->random_values(2);
is( scalar @seeds, 2, "random_values(2) returns two values");
