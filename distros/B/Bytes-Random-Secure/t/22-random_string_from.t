## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;
use Test::More;


use Bytes::Random::Secure;

# We'll use a weaker source because we're testing for function, quality
# isn't being contested here.  Weak=>1 should assure we use /dev/urandom where
# it's available.  Low entropy chosen to preserve our source.
my $random = Bytes::Random::Secure->new(
  NonBlocking => 1,
  Weak        => 1,
  Bits        => 64
);


# Tests for _closest_divisor().

my @divisors = (  1,  1,  2,  4,  4,  8,  8,  8,  8,
                 16, 16, 16, 16, 16, 16, 16, 16,
                 32, 32, 32, 32, 32, 32, 32, 32, 32
);

# Nearest factor of 2**32 >= $ix;

for my $ix ( 0 .. $#divisors ) {
  is( $random->_closest_divisor($ix), $divisors[$ix],
      "_closest_divisor($ix) == $divisors[$ix]" );
}

is( $random->_closest_divisor(), 1,
    '_closest_divisor() == 1; No param list defaults to zero.' );

ok( ! eval { $random->_closest_divisor(-1); 1; },
    '_closest_divisor(-1) throws on negative input.' );

ok( ! eval { $random->_closest_divisor(2**33); 1 },
    '_closest_divisor(2**33) throws (out of range input).' );

is( $random->_closest_divisor(2**32), 2**32,
    "_closest_divisor(2**32) == 2**32." );

is( $random->_closest_divisor( 2**32 - 1 ), 2**32,
    '_closest_divisor(2**32-1) == 2**32' );

# Tests for _ranged_randoms().

for my $count ( 0 .. 11 ) {
  is( scalar @{[ $random->_ranged_randoms(16,$count) ]}, $count,
      "Requested $count ranged randoms, and got $count." );
}

is( scalar @{[ $random->_ranged_randoms(16) ]}, 0,
    'Requested undefined quantity of ranged randoms, and got zero (default).' );

my( $min, $max );
$min = $max = $random->_ranged_randoms(200, 1);

my $MAX_TRIES = 1_000_000;
my $tries     = 0;
while( ( $min > 0 || $max < 199 ) && $tries++ < $MAX_TRIES ) {
  my $random = ($random->_ranged_randoms(200,1))[0];
  $min = $random < $min ? $random : $min;
  $max = $random > $max ? $random : $max;
}
is( $min, 0, '_ranged_randoms generates range minimum.' );
is( $max, 199, '_ranged_randoms generates range maximum.' );
note "It took $tries tries to hit both min and max.";

# Testing random_string_from().

is( $random->string_from( 'abc', 0 ), '',
    'string_from() with a quantity of zero returns empty string.' );
    
is( $random->string_from( 'abc' ), '',
    'string_from() with an undefined quantity defaults to zero.' );

is( length( $random->string_from( 'abc', 5 ) ), 5,
    'string_from(): Requested 5, got 5.' );

my %bag;
$tries = 0;
while( scalar( keys %bag ) < 26 && $tries++ < $MAX_TRIES ) {
  $bag{ $random->string_from( 'abcdefghijklmnopqrstuvwxyz', 1 ) }++;
}

is( scalar( keys %bag ), 26,
   'string_from() returned all bytes from bag, and only bytes from bag.'
);

ok( ! scalar( grep{ $_ =~ m/[^abcdefghijklmnopqrstuvwxyz]/ } keys %bag ),
    'string_from(): No out of range characters in output.' );

ok( $tries >= 26,
    'string_from():Test validation: took at least 26 tries to hit all 26.' );

note "It took $tries tries to hit them all at least once.";

ok( ! eval { $random->string_from(); 1; },
    'No bag string passed (or bag of zero length) throws an exception.' );

done_testing();
