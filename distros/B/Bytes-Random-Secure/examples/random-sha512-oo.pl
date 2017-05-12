
use strict;
use warnings;
use Bytes::Random::Secure qw();
use Digest::SHA qw( sha512_base64 );

my $quantity = 128;

# Instantiate a random generator with a customized seed:

my $random = Bytes::Random::Secure->new( Bits => 64, NonBlocking => 1 );

# Get a string of 128 random bytes.
my $bytes    = $random->bytes($quantity);

# And just for fun, generate a base64 encoding of a sha2-512 digest of the
# random byte string.
my $digest   = sha512_base64( $bytes );

print "$digest\n";

