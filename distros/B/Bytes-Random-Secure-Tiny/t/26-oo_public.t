## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;
use Data::Dumper;
use Test::More;
use Bytes::Random::Secure::Tiny;

$Math::Random::ISAAC::Embedded::EMBEDDED_CSPRNG = 1;

# Public methods tested here (bytes(), etc.).
# Much of this has already been put through the paces via the "functions" layer
# tests in 20-functions.t, so we're only going for coverage here.

my $random = Bytes::Random::Secure::Tiny->new(bits => 64);

is( length $random->bytes(10), 10, 'bytes(10) returns ten bytes.' );

like( $random->bytes_hex(16), qr/^[1234567890abcdef]{32}$/,
      'bytes_hex() returns only hex digits, of correct length.' );

like( $random->string_from('abc', 100 ), qr/^[abc]{100}$/,
      'string_from() returns proper length and proper string.' );

my $rv = $random->irand;

ok( $rv == int( $rv ), 'irand produces an integer.' );

{
  my( $min, $max );
  for( 1 .. 10000 ) {
    my $ir = $random->irand;
    $min = $ir if ! defined $min;
    $min = $ir < $min ? $ir : $min;
    $max = $ir if ! defined $max;
    $max = $ir > $max ? $ir : $max;
  }
  ok( $min >= 0, 'irand(): Minimum return value is >= 0.' );
  ok( $max <= 2**32-1, 'irand(): Maximum return value is <= 2**32-1.' );
}

my $newirand = Bytes::Random::Secure::Tiny->new(bits =>64)->irand;

ok( $newirand == int( $newirand ),
    'irand instantiates a new RNG on first call with fresh object.' );

ok( $newirand >= 0 && $newirand <= 2**32-1,
    'First irand call with a new RNG is in range.' );
    
done_testing();
