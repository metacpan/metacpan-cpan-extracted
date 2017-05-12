## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;

use Test::More;
use Bytes::Random::Secure::Tiny;

use 5.006000;

$Math::Random::ISAAC::Embedded::EMBEDDED_CSPRNG = 1;
my @methods = qw/ bytes bytes_hex string_from /;

can_ok( 'Bytes::Random::Secure::Tiny', @methods );

my $r = Bytes::Random::Secure::Tiny->new(bits => 64);

foreach my $want ( qw/ 0 1 2 3 4 5 6 7 8 16 17 1024 10000 / ) {
  my $correct = $want >= 0 ? $want : 0;
  is( length $r->bytes( $want ), $correct,
      "bytes($want) method returns $correct bytes." );
}

# bytes_hex tests.

foreach my $want ( qw/ 0 1 2 3 4 5 6 7 8 16 17 1024 10000 / ) {
  my $result  = $r->bytes_hex( $want );
  my $correct = $want >= 0 ? $want * 2 : 0;
  is( length $r->bytes_hex( $want ), $correct,
      "bytes_hex($want) returned $correct hex digits." );
};

ok( $r->bytes_hex(128) =~ /^[[:xdigit:]]+$/,
    'bytes_hex only produces hex digits.' );

is( length $r->bytes(), 0,
    'random_bytes() No param defaults to zero bytes.' );

# Basic tests for random_string_from
# (More exhaustive tests in 22-random_string_from.t)

my $MAX_TRIES = 1_000_000;
my %bag;
my $tries = 0;
while( scalar( keys %bag ) < 26 && $tries++ < $MAX_TRIES ) {
  $bag{ $r->string_from( 'abcdefghijklmnopqrstuvwxyz', 1 ) }++;
}

is( scalar( keys %bag ), 26,
   'string_from() returned all bytes from bag, and only bytes from bag.'
);

ok( ! scalar( grep{ $_ =~ m/[^abcdefghijklmnopqrstuvwxyz]/ } keys %bag ),
    'No out of range characters in output.' );
like( $r->string_from( 'abc', 100 ), qr/^[abc]{100}$/,
      'string_from() returns only correct digits, and length.' );

done_testing();
