## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;

use MIME::Base64;
use MIME::QuotedPrint;
use Data::Dumper;

use Test::More;

use Bytes::Random::Secure;

# Public methods tested here (bytes(), etc.).
# Much of this has already been put through the paces via the "functions" layer
# tests in 20-functions.t, so we're only going for coverage here.

my $random = Bytes::Random::Secure->new( Bits => 64, NonBlocking=>1, Weak=>1 );

is( length $random->bytes(10), 10, 'bytes(10) returns ten bytes.' );

is( length decode_base64($random->bytes_base64(111)), 111,
    'decode_base64() can be decoded, and returns correct number of bytes.');
like( $random->bytes_base64(111,"\n\n"), qr/\n\n/,
      'bytes_base64(111,"\n\n"): EOL handled properly.' );

is( length decode_qp( $random->bytes_qp(200) ), 200,
    'bytes_qp(): Decodable Quoted Printable returned.'
    . ' Decodes to proper length.' );

like( $random->bytes_qp(200, "\n\n"), qr/\n\n/,
      'bytes_qp(): EOL handled properly.' );

like( $random->bytes_hex(16), qr/^[1234567890abcdef]{32}$/,
      'bytes_hex() returns only hex digits, of correct length.' );

like( $random->string_from('abc', 100 ), qr/^[abc]{100}$/,
      'string_from() returns proper length and proper string.' );

{
  local $@;
  eval {
    my $bytes = $random->bytes( -5 );
  };
  like( $@, qr/Byte count must be a positive integer/,
        'bytes() throws on invalid input.' );
}

{
  local $@;
  eval {
    my $bytes = $random->string_from( 'abc', -5 );
  };
  like( $@, qr/Byte count must be a positive integer/,
        'string_from(): Throws an exception on invalid byte count.' );
}

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

my $newirand
  = Bytes::Random::Secure->new( NonBlocking => 1, Bits => 64 )->irand;

ok( $newirand == int( $newirand ),
    'irand instantiates a new RNG on first call with fresh object.' );

ok( $newirand >= 0 && $newirand <= 2**32-1,
    'First irand call with a new RNG is in range.' );
    

done_testing();
