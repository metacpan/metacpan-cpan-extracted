#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use constant _backend => 0;
{
    local $ENV{BRST_EMBEDDED_CSPRNG} = 1;
    require Bytes::Random::Secure::Tiny;
    isa_ok new_ok('Bytes::Random::Secure::Tiny', [bits=>64])->{_rng}[_backend], 'Math::Random::ISAAC::PP::Embedded'; 
}

done_testing();
