#!/usr/bin/env perl

use strict;
use warnings;
use Bytes::Random::Secure::Tiny;
$Math::Random::ISAAC::Embedded::EMBEDDED_CSPRNG = 1;
use Test::More;

my $s = new_ok 'Crypt::Random::Seed::Embedded';
can_ok 'Crypt::Random::Seed::Embedded', 'new';
can_ok $s, qw(random_values);

done_testing();
