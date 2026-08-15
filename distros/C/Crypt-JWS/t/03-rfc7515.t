#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Crypt::JWS qw(verify peek);
use Crypt::JWS::Key;

# RFC 7515 appendix A.1: HS256. The key and token are the spec's own.
{
    my $key = Crypt::JWS::Key->from_jwk({
        kty => 'oct',
        k   => 'AyM1SysPpbyDfgZld3umj1qzKObwVMkoqQ-EstJQLr_T-1qS0gZH75'
             . 'aKtMN3Yj0iPS4hcgUuTwjAzZr1Z9CAow',
    });
    my $token = 'eyJ0eXAiOiJKV1QiLA0KICJhbGciOiJIUzI1NiJ9'
              . '.'
              . 'eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6'
              . 'Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ'
              . '.'
              . 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
    my $payload = verify($token, $key, algs => ['HS256']);
    ok defined $payload, 'A.1 HS256 vector verifies';
    like $payload, qr/"iss":"joe"/, 'A.1 payload content';
    is peek($token)->{alg}, 'HS256', 'A.1 header alg';

    (my $bad = $token) =~ s/\w\z/x/;
    ok !defined verify($bad, $key, algs => ['HS256']),
        'A.1 tampered signature rejected';
}

# RFC 7515 appendix A.3: ES256, verified with the spec's public key.
{
    my $key = Crypt::JWS::Key->from_jwk({
        kty => 'EC',
        crv => 'P-256',
        x   => 'f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU',
        y   => 'x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a0',
    });
    my $token = 'eyJhbGciOiJFUzI1NiJ9'
              . '.'
              . 'eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6'
              . 'Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ'
              . '.'
              . 'DtEhU3ljbEg8L38VWAfUAqOyKAM6-Xx-F4GawxaepmXFCgfTjDxw5djx'
              . 'La8ISlSApmWQxfKTUJqPP3-Kg6NU1Q';
    my $payload = verify($token, $key, algs => ['ES256']);
    ok defined $payload, 'A.3 ES256 vector verifies';
    like $payload, qr/example\.com\/is_root/, 'A.3 payload content';

    # the spec's private half signs a fresh token that the public
    # half verifies (ECDSA signatures are randomized; the vector above
    # is the fixed one from the RFC)
    my $priv = Crypt::JWS::Key->from_jwk({
        kty => 'EC',
        crv => 'P-256',
        x   => 'f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU',
        y   => 'x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a0',
        d   => 'jpsQnnGQmL-YBIffH1136cspYG6-0iY7X1fCE9-E9LI',
    });
    my $fresh = Crypt::JWS::sign($priv, 'hello', alg => 'ES256');
    is verify($fresh, $key, algs => ['ES256']), 'hello',
        'A.3 private key signs, public key verifies';
}

done_testing();
