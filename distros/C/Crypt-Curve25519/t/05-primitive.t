
use Test::More;
BEGIN { use_ok('Crypt::Curve25519', qw(curve25519_secret_key curve25519)) };

my $basepoint = pack('H64', '09');

my $alice_rand = pack('H64', '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a');
my $bob_rand = pack('H64', '5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb');

# Alice:
my $alice_secret_key = curve25519_secret_key($alice_rand);
my $alice_public_key = curve25519( $alice_secret_key, $basepoint );

# Bob:
my $bob_secret_key = curve25519_secret_key($bob_rand);
my $bob_public_key = curve25519( $bob_secret_key, $basepoint );

# Alice calculates shared secret to communicate with Bob
my $shared_secret_with_bob = curve25519( $alice_secret_key,
                                $bob_public_key);

# Bob calculates shared secret to communicate with Alice
my $shared_secret_with_alice = curve25519( $bob_secret_key,
                                $alice_public_key);

# Shared secrets are equal
is( $shared_secret_with_bob, $shared_secret_with_alice,
    "Shared secrets match: ". unpack('H*', $shared_secret_with_bob));

done_testing();

