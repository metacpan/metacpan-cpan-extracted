#!/usr/bin/env perl

use strict;
use warnings;
use Math::Prime::FastSieve;

use constant {
    MAX_SIEVE => 300_000,
    FIND      => 50_000,
};

# Build a sieve that flags all primes from 2 .. 300000.
my $sieve = Math::Prime::FastSieve::Sieve->new(MAX_SIEVE);

# Return the closest prime greater or equal to 50000.
my $next_prime = $sieve->nearest_ge(FIND);

print 'The nearest prime greater or equal to ' . FIND . " is: $next_prime.\n";
