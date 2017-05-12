
use Test::More;
BEGIN { use_ok('Crypt::Curve25519') };

eval {
    Crypt::Curve25519::curve25519( pack('x32') );
};
like($@, qr/\QUsage: Crypt::Curve25519::curve25519(secret, public)/, "curve25519(): Using primitive function requires two arguments");

eval {
    curve25519_secret_key( "secret too short" );
};
like($@, qr/Secret key requires 32 bytes/, "curve25519_secret_key(): Secret key requires 32 bytes");

eval {
    curve25519_public_key( "secret too short" );
};
like($@, qr/Secret key requires 32 bytes/, "curve25519_public_key(): Secret key requires 32 bytes");

eval {
    curve25519_shared_secret( pack('x32') );
};
like($@, qr/\QUsage: Crypt::Curve25519::curve25519_shared_secret(secret, public)/, "curve25519_shared_secret:() Calculating shared secret requires public key");

eval {
    curve25519_public_key( pack('x32'), "basepoint too short" );
};
like($@, qr/Basepoint requires 32 bytes/, "curve25519_public_key(): Basepoint requires 32 bytes");

eval {
    curve25519_shared_secret( pack('x32'), "pub key too short" );
};
like($@, qr/Public key requires 32 bytes/, "curve25519_shared_secret(): Public key requires 32 bytes");

done_testing();

