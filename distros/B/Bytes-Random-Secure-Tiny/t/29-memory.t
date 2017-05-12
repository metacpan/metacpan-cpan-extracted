#!/usr/bin/perl -T

# Test for memory leaks

use strict;
use warnings;
use Test::More;
use Bytes::Random::Secure::Tiny;
$Math::Random::ISAAC::Embedded::EMBEDDED_CSPRNG = 1;

plan skip_all => 'This test is not compatible with Devel::Cover'
    if exists $INC{'Devel/Cover.pm'};

eval {require Test::LeakTrace};

plan skip_all => 'Test::LeakTrace required to test memory leaks' if $@;
plan tests    => 1;

Test::LeakTrace->import;

no_leaks_ok(sub {
  my $obj = Math::Random::ISAAC::PP::Embedded->new(time);
  for (0..10) {$obj->irand;}
}, '->irand does not leak memory');

