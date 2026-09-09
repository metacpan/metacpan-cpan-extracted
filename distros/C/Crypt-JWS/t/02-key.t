#!perl
use 5.010;
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

# X.509 certificates: the public key out of DER, which is the form
# XML-DSig's <ds:X509Certificate> carries and the form from_pem refuses.
{
    my ($dir) = grep { -d } ('t/data', 'data');
    my $slurp = sub {
        open my $fh, '<:raw', "$dir/$_[0]" or die "$dir/$_[0]: $!";
        local $/; <$fh>;
    };
    my $der_of = sub {
        my ($pem) = @_;
        my ($b64) = $pem =~ /-----BEGIN CERTIFICATE-----(.*?)-----END/s
            or die 'no CERTIFICATE block';
        require MIME::Base64;
        MIME::Base64::decode_base64($b64);
    };

    for my $case ([RSA => 'rsa', 'RS256'], [EC => 'ec', 'ES256']) {
        my ($kty, $stem, $alg) = @$case;
        my $cert = $slurp->("test-$stem-cert.pem");
        my $der  = $der_of->($cert);

        # from_pem refuses a certificate: this is the gap the entry fills,
        # and the test asserts it so the entry cannot quietly become
        # redundant without someone noticing.
        ok !eval { Crypt::JWS::Key->from_pem($cert); 1 },
            "$kty: from_pem refuses a CERTIFICATE block";

        my $pub = Crypt::JWS::Key->from_x509_der($der);
        is $pub->kty, $kty, "$kty: from_x509_der gives the right kty";
        ok !$pub->is_private, "$kty: a certificate key is public";

        # the point of the entry: the extracted key is the certificate's
        # key, proven against a signature only its private half could make
        my $priv = Crypt::JWS::Key->from_pem($slurp->("test-$stem-key.pem"));
        my $tok  = Crypt::JWS::sign($priv, 'payload', alg => $alg);
        is Crypt::JWS::verify($tok, $pub, algs => [$alg]), 'payload',
            "$kty: the extracted key verifies what the private key signed";
    }

    # refusals: nothing here may croak in C or return a key
    my $rsa_der = $der_of->($slurp->('test-rsa-cert.pem'));
    for my $bad (['empty', ''], ['garbage', 'not a certificate'],
                 ['PEM where DER belongs', $slurp->('test-rsa-cert.pem')],
                 ['a private key', $slurp->('test-rsa-key.pem')],
                 ['DER with a trailing byte', $rsa_der . "\x00"]) {
        my ($name, $bytes) = @$bad;
        ok !eval { Crypt::JWS::Key->from_x509_der($bytes); 1 },
            "from_x509_der refuses $name";
    }

    # truncation at every byte offset: the family's habit, and the one
    # shape that finds a read past the end of the buffer
    my $survived = 0;
    for my $n (0 .. length($rsa_der) - 1) {
        my $k = eval { Crypt::JWS::Key->from_x509_der(substr $rsa_der, 0, $n) };
        $survived++ if !defined $k;
    }
    is $survived, length($rsa_der),
        'every truncation of the DER is refused, and none crashes';
}

done_testing();
