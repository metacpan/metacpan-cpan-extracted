
use Test::More;
BEGIN { use_ok('Crypt::Curve25519') };

# Alice:
my $alice_secret_key = curve25519_secret_key(random_32_bytes());
my $alice_public_key = curve25519_public_key( $alice_secret_key );

# Bob:
my $bob_secret_key = curve25519_secret_key(random_32_bytes());
my $bob_public_key = curve25519_public_key( $bob_secret_key );

# Alice and Bob exchange their public keys
my $alice_public_key_hex = unpack('H64', $alice_public_key);
my $bob_public_key_hex = unpack('H64', $bob_public_key);

# Alice calculates shared secret to communicate with Bob
my $shared_secret_with_bob = curve25519_shared_secret( $alice_secret_key,
                                pack('H64', $bob_public_key_hex));

# Bob calculates shared secret to communicate with Alice
my $shared_secret_with_alice = curve25519_shared_secret( $bob_secret_key,
                                pack('H64', $alice_public_key_hex));

# Shared secrets are equal
is( $shared_secret_with_bob, $shared_secret_with_alice,
    "Shared secrets match: ". unpack('H64', $shared_secret_with_bob));

sub random_32_bytes {
    return join('', map { chr(int(rand(255))) } 1 .. 32);
}

done_testing();

