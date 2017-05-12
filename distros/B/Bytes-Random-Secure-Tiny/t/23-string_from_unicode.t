## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;
use Test::More;
use Bytes::Random::Secure::Tiny;

$Math::Random::ISAAC::Embedded::EMBEDDED_CSPRNG = 1;
$ENV{'BRST_DEBUG'} = 1;

if( ! $^V ||  $^V lt v5.8.9 ) {
  plan skip_all =>
    'Cannot reliably test Unicode support on Perl\'s older than 5.8.9.';
}

binmode STDOUT, ':encoding(UTF-8)';

my $num_octets = 80;
my $random     = Bytes::Random::Secure::Tiny->new(bits=>64);
my $string     = $random->string_from( 'Ѧѧ', $num_octets );

is( length $string, $num_octets,
    'string_from(unicode): Returned proper length string.' );

like( $string, qr/^[Ѧѧ]+$/,
      'string_from(unicode): String contained only Ѧѧ characters.' );

# There's only an 8.27e-23% chance of NOT having both Ѧ and ѧ in the output.
# It would be incredibly poor luck for these tests to fail randomly.
# So we'll take failure to mean there's a bug.

like( $string, qr/Ѧ/,
      'string_from(unicode): Ѧ found in output.' );

like( $string, qr/ѧ/,
      'string_from(unicode): ѧ found in output.' );

done_testing();
