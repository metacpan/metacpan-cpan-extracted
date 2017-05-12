#!/usr/bin/env perl 
# SSF 112412 - test Math::Prime::FastSieve

use strict;
use warnings;

use Test::More;

use Math::Prime::FastSieve;

# Create a new sieve and flag all primes less or equal to n.
my $sieve = Math::Prime::FastSieve::Sieve->new( 5_000_000 );
isa_ok( $sieve, 'Math::Prime::FastSieve::Sieve' );

is( $sieve->count_sieve, 348513, 'count_sieve accurate on a clean sieve.' );

# Obtain a ref to an array containing all primes <= 5 Million.
my $aref = $sieve->primes( 5_000_000 );
is( scalar @$aref, 348513,
    '$sieve->primes( 5_000_000 ) returns correct number of elements.' );

is( $sieve->count_sieve, 348513, 'count_sieve still correct after primes().' );

# Obtain a ref to an array containing all primes >= 5, and <= 16.
$aref = $sieve->ranged_primes( 5, 16 );
is_deeply( $aref, [ 5, 7, 11, 13 ], 'Correct range from ranged_primes' );


# Query the sieve: Is 17 prime? Return a true or false value.
my $result = $sieve->isprime( 17 );
ok( $result, 'isprime(17) returns true.' );

# Get the value of the nearest prime less than or equal to 42.
my $less_or_equal = $sieve->nearest_le( 42 );
is( $less_or_equal, 41, 'nearest_le(42) is 41.' );

# Get the value of the nearest prime greater than or equal to 42.
my $greater_or_equal = $sieve->nearest_ge( 42 );
is( $greater_or_equal, 43, 'nearest_ge(42) is 43.' );


# Count how many primes exist within the sieve (ie, count all primes less
# than or equal to 5 Million, assuming we instantiated the sieve with
# Math::Prime::FastSieve::Sieve->new( 5_000_000 );.
my $num_found = $sieve->count_sieve();
is( $num_found, 348513,
    'count_sieve() returns 348513 on a sieve of 5_000_000 after other sieve ' .
    'operations.' );

# Count how many primes fall between 1 and 42 inclusive.
my $quantity_le = $sieve->count_le( 42 );
is( $quantity_le, 13, 'count_le(42) accurate.' );

# Return the value of the 42nd prime number.
my $forty_second_prime = $sieve->nth_prime( 42 );
is( $forty_second_prime, 181, 'nth_prime(42) is 181.' );

done_testing();
