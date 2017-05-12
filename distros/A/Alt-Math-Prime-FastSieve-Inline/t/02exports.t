## no critic(RCS,VERSION,explicit,Module,ProhibitMagicNumbers)
use strict;
use warnings;

use Test::More;
use Math::Prime::FastSieve qw( primes );

my @exports = (
    [ 'primes', \&primes ],
);

my %small_tests = (
    -3 => [],
    -1 => [],
    0  => [],
    1  => [],
    2  => [2],
    3  => [ 2, 3 ],
    4  => [ 2, 3 ],
    5  => [ 2, 3, 5 ],
    6  => [ 2, 3, 5 ],
    7  => [ 2, 3, 5, 7 ],
    11 => [ 2, 3, 5, 7, 11 ],
    18 => [ 2, 3, 5, 7, 11, 13, 17 ],
    19 => [ 2, 3, 5, 7, 11, 13, 17, 19 ],
    20 => [ 2, 3, 5, 7, 11, 13, 17, 19 ],
);

my %big_tests = (
    1000       => 168,
    5_000_000  => 348_513,
    50_000_000 => 3_001_134,
);

# Verify that export occurred.
can_ok( 'main', 'primes' );

# Test known lists of primes.
foreach my $param ( sort { $a <=> $b } keys %small_tests ) {
    my $expect = $small_tests{$param};
    local $" = ', ';
    foreach my $function (@exports) {
        is_deeply( $function->[1]($param),
            $expect, "$function->[0]( $param ) returns [ @{$expect} ]." );
    }
}

# Test known large quantities of primes.
foreach my $param ( sort { $a <=> $b } keys %big_tests ) {
    my $expect = $big_tests{$param};
    is( @{ primes($param) },
        $expect,
        "primes( $param ) returns a ref to a list with $expect elements." );
}

done_testing();
