#!/usr/bin/env perl
use strict;
use warnings;
use Crypt::Random::Seed;

use Test::More  tests => 2;

my $source = Crypt::Random::Seed->new();
isa_ok $source, 'Crypt::Random::Seed';

my $source2 = new Crypt::Random::Seed;  ## no critic (ProhibitIndirectSyntax)
isa_ok $source, 'Crypt::Random::Seed';
