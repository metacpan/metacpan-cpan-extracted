#!/usr/bin/env perl
use strict;
use warnings;
use Crypt::Random::Seed;

use Test::More  tests => 3;

# Expect croak if Only isn't an array reference
ok(!eval {Crypt::Random::Seed->new(Never=>0);}, "Only with non-array reference croaks");

# Find out what source it normally returns
my $source = Crypt::Random::Seed->new();
ok(defined $source, "Source found");
my $method = $source->name();

# Now blacklist that source
my $source2 = Crypt::Random::Seed->new(Never=>[$method]);
my $newmethod = (defined $source2) ? $source2->name() : "";
isnt($newmethod, $method, "Old method $method was blacklisted.  Chose '$newmethod'");
