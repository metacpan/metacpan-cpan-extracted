#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Bytes::Random::Secure::Tiny;
$Math::Random::ISAAC::Embedded::EMBEDDED_CSPRNG = 1;

my $src = Crypt::Random::Seed::Embedded->new(NonBlocking=>1);

{
  my @vals = $src->random_values();
  is scalar @vals, 0, "random_values() returns empty array";
}
{
  my @vals = $src->random_values(undef);
  is scalar @vals, 0, "random_values(undef) returns empty array";
}
{
  my @vals = $src->random_values(-1);
  is scalar @vals, 0, "random_values(-1) returns empty array";
}
{
  my @vals = $src->random_values(0);
  is scalar @vals, 0, "random_values(0) returns empty array";
}
{
  my @vals = $src->random_values(0.8);
  is scalar @vals, 0, "random_values(0.8) returns empty array";
}
{
  my @vals = $src->random_values(2);
  is scalar @vals, 2, "random_values(2) returns two values";
  ok $vals[0] >= 0 && $vals[0] <= 4294967295, "  first value in range";
  ok $vals[1] >= 0 && $vals[1] <= 4294967295, "  second value in range";
}

# All in one.
my @seeds = Crypt::Random::Seed::Embedded->new->random_values(2);
is scalar @seeds, 2, "random_values(2) returns two values";

if( $ENV{RELEASE_TESTING} ) {
    my @bseeds
        = Crypt::Random::Seed::Embedded->new(nonblocking=>0)->random_values(2);
    is scalar @seeds, 2, 'non-blocking random_values(2) returned two values.';
}
else {
    note 'Skipping blocking tests unless in RELEASE_TESTING mode.';
}
done_testing();
