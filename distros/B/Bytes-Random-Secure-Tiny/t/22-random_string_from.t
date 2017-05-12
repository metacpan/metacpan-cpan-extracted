## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;
use Test::More;

use Bytes::Random::Secure::Tiny;

$Math::Random::ISAAC::Embedded::EMBEDDED_CSPRNG = 1;

# We'll use a weaker source because we're testing for function, quality
# isn't being contested here.
my $random = Bytes::Random::Secure::Tiny->new(bits=>64);

for my $count ( 0 .. 11 ) {
  is( scalar @{$random->_ranged_randoms(16,$count)}, $count,
      "Requested $count ranged randoms, and got $count." );
}

is( scalar @{$random->_ranged_randoms(16)}, 0,
    'Requested undefined quantity of ranged randoms, and got zero (default).' );

my( $min, $max );
$min = $max = @{$random->_ranged_randoms(200, 1)};

my $MAX_TRIES = 1_000_000;
my $tries     = 0;
while( ( $min > 0 || $max < 199 ) && $tries++ < $MAX_TRIES ) {
  my $random = $random->_ranged_randoms(200,1)->[0];
  $min = $random < $min ? $random : $min;
  $max = $random > $max ? $random : $max;
}
is( $min, 0, '_ranged_randoms generates range minimum.' );
is( $max, 199, '_ranged_randoms generates range maximum.' );
if( $min > 0 || $max < 199 ) {
    fail "Range error: \$min was $min, \$max was $max" }
else {
    pass "It took $tries tries to hit both min and max."
}

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
