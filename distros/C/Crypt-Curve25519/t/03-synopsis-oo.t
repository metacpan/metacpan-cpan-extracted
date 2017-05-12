
use Test::More;
BEGIN { use_ok('Crypt::Curve25519') };

my $c = Crypt::Curve25519->new();

# Alice:
my $alice_secret_key_hex = $c->secret_key(random_hexencoded_32_bytes());
my $alice_public_key_hex = $c->public_key( $alice_secret_key_hex );

# Bob:
my $bob_secret_key_hex = $c->secret_key(random_hexencoded_32_bytes());
my $bob_public_key_hex = $c->public_key( $bob_secret_key_hex );

# Alice and Bob exchange their public keys

# Alice calculates shared secret to communicate with Bob
my $shared_secret_with_bob_hex = $c->shared_secret(
                                $alice_secret_key_hex,
                                $bob_public_key_hex);

# Bob calculates shared secret to communicate with Alice
my $shared_secret_with_alice_hex = $c->shared_secret(
                                $bob_secret_key_hex,
                                $alice_public_key_hex);

# Shared secrets are equal
is( $shared_secret_with_bob_hex, $shared_secret_with_alice_hex,
    "Shared secrets match: $shared_secret_with_bob_hex");

sub random_32_bytes {
    return join('', map { chr(int(rand(255))) } 1 .. 32);
}

sub random_hexencoded_32_bytes {
    return unpack('H64', random_32_bytes());
}

done_testing();

