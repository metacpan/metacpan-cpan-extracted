#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Crypt::JWS ();
use Crypt::JWS::Key;

# generation
for my $alg (qw(ES256 ES384 ES512)) {
    my $k = Crypt::JWS::Key->generate($alg);
    is $k->kty, 'EC', "$alg generates EC";
    is $k->curve_bits, ($alg eq 'ES512' ? 521 : substr($alg, 2) + 0),
        "$alg curve";
    ok $k->is_private, "$alg private";
}
{
    my $k = Crypt::JWS::Key->generate('RS256');
    is $k->kty, 'RSA', 'RS256 generates RSA';
    ok $k->is_private, 'RSA private';
}
{
    my $k = Crypt::JWS::Key->generate('HS256');
    is $k->kty, 'oct', 'HS256 generates oct';
}
ok !eval { Crypt::JWS::Key->generate('none'); 1 }, 'generate none croaks';
ok !eval { Crypt::JWS::Key->generate('RS256', bits => 512); 1 },
    'weak RSA rejected';

# PEM round trips
for my $alg (qw(ES256 RS256)) {
    my $k = Crypt::JWS::Key->generate($alg);
    my $priv_pem = $k->to_pem(1);
    like $priv_pem, qr/BEGIN PRIVATE KEY/, "$alg private PEM";
    my $pub_pem = $k->to_pem;
    like $pub_pem, qr/BEGIN PUBLIC KEY/, "$alg public PEM";

    my $k2 = Crypt::JWS::Key->from_pem($priv_pem);
    ok $k2->is_private, "$alg private PEM reimports";
    my $k3 = Crypt::JWS::Key->from_pem($pub_pem);
    ok !$k3->is_private, "$alg public PEM reimports as public";
    is $k3->thumbprint, $k->thumbprint,
        "$alg thumbprint survives the PEM round trip";

    my $t = Crypt::JWS::sign($k2, 'x', alg => $alg);
    is Crypt::JWS::verify($t, $k3, algs => [$alg]), 'x',
        "$alg reimported pair signs and verifies";
}

# JWK round trips
for my $alg (qw(ES256 ES384 ES512 RS256)) {
    my $k = Crypt::JWS::Key->generate($alg);
    my $jwk = $k->to_jwk;
    my $k2 = Crypt::JWS::Key->from_jwk($jwk);
    ok !$k2->is_private, "$alg JWK is public";
    is $k2->thumbprint, $k->thumbprint, "$alg JWK thumbprint matches";
    my $t = Crypt::JWS::sign($k, 'y', alg => $alg);
    is Crypt::JWS::verify($t, $k2, algs => [$alg]), 'y',
        "$alg verifies via JWK-imported public key";
}
ok !eval { Crypt::JWS::Key->generate('HS256')->to_jwk; 1 },
    'oct public JWK refused';
ok !eval { Crypt::JWS::Key->generate('ES256')->to_jwk(private => 1); 1 },
    'private JWK export refused';
{
    my $jwk = Crypt::JWS::Key->generate('ES256')->to_jwk(
        kid => 'k1', alg => 'ES256', use => 'sig');
    is $jwk->{kid}, 'k1', 'kid carried';
    is $jwk->{use}, 'sig', 'use carried';
}

# RFC 7638 thumbprint vector (the RSA key from the RFC's example)
{
    my $k = Crypt::JWS::Key->from_jwk({
        kty => 'RSA',
        n   => '0vx7agoebGcQSuuPiLJXZptN9nndrQmbXEps2aiAFbWhM78LhWx4cbbfAAt'
             . 'VT86zwu1RK7aPFFxuhDR1L6tSoc_BJECPebWKRXjBZCiFV4n3oknjhMstn6'
             . '4tZ_2W-5JsGY4Hc5n9yBXArwl93lqt7_RN5w6Cf0h4QyQ5v-65YGjQR0_FD'
             . 'W2QvzqY368QQMicAtaSqzs8KJZgnYb9c7d0zgdAZHzu6qMQvRL5hajrn1n9'
             . '1CbOpbISD08qNLyrdkt-bFTWhAI4vMQFh6WeZu0fM4lFd2NcRwr3XPksINH'
             . 'aQ-G_xBniIqbw0Ls1jF44-csFCur-kEgU8awapJzKnqDKgw',
        e   => 'AQAB',
    });
    is $k->thumbprint, 'NzbLsXh8uDCcd-6MNwXF4W_7noWXFZAfHkxZsRGC9Xs',
        'RFC 7638 thumbprint vector';
}

# oct / secret keys
{
    my $k = Crypt::JWS::Key->from_secret('a shared secret');
    is $k->kty, 'oct', 'from_secret is oct';
    ok !eval { $k->to_pem; 1 }, 'oct has no PEM form';
    ok $k->thumbprint, 'oct thumbprint works';
}

# croaks
ok !eval { Crypt::JWS::Key->from_pem('not a pem'); 1 }, 'garbage PEM croaks';
ok !eval { Crypt::JWS::Key->from_jwk({ kty => 'EC', crv => 'P-999',
                                       x => 'AA', y => 'AA' }); 1 },
    'unknown curve croaks';
ok !eval {
    my $pub = Crypt::JWS::Key->from_pem(
        Crypt::JWS::Key->generate('ES256')->to_pem);
    $pub->to_pem(1);
    1;
}, 'private export of a public key croaks';
ok !eval { Crypt::JWS::Key->from_jwk({ kty => 'EC', crv => 'P-256',
    x => Crypt::JWS::b64url("\x01" x 32),
    y => Crypt::JWS::b64url("\x02" x 32) }); 1 },
    'point not on curve croaks';

done_testing();
