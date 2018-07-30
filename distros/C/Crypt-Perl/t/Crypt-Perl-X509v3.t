package t::Crypt::Perl::X509v3;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
use Test::NoWarnings;
use Test::Deep;
use Test::Exception;

use Try::Tiny;

use File::Temp;

use lib "$FindBin::Bin/lib";

use OpenSSL_Control ();

use parent qw(
    Test::Class
    NeedsOpenSSL
);

use Crypt::Perl::ECDSA::Generate ();
use Crypt::Perl::PK ();

use Crypt::Perl::X509v3 ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new();

    $self->num_method_tests( 'test_creation', 2 * _key_combos() );

    return $self;
}

sub _key_combos {
    my $rsa1 = <<END;
-----BEGIN RSA PRIVATE KEY-----
MIICXgIBAAKBgQDfjCeysJZyne/M7Zzvl3Ym2dVcu3eXh19/2Z4C/ZkPnLFrbOht
MgqKJ7qFtK961laVlmwhI/mnnzaCuYhkOH1COBT6jIdAMvzzBDoDyf6DBLjgSxlw
Q2BGD/JWRKbKSRVBSPtMkuDynHAxYpyY6i73iBLUiHcN7mZ7uq4WFPJEaQIDAQAB
AoGBAJ4XFP/2h/74mFyZcZGy0Fi7VntlDDc6Ahx9PpSo2XTEAGiTNW/7op5/aBYk
aLD7IXJaVY++TFDxdHBQWxddJ565gNcP7QRfS7IGt3QNiRb86m1SvjGfvYuVZfPy
DI62wTvSeqcxTCKBaUJLQr3uAI2atrNuT2Q+X/D7zf0IUllxAkEA8Yk5Mn2dicEa
uHSFlRipmv9PmDk1lPicoEW9Zfu0fP9MlO4cO6sgSg/nFzLEXsH3xoyeMtpQcaka
WQHBnlE9NQJBAOzvKj7HSlZ38HnOvwf1G6KCnC/Q1UODIlutDb+EqiWiRHcJJyZW
B82lgeiJP0Wnt3CuDYVWM43wZ6ycgBYw9OUCQQCsTdgfzLy1qKwHKhihZBaaG8gM
L8OpojEZpKaYOhdnlDhthe9eIZXHP9D7G5w6fOTlHys728HHU3sYQ8h7yDiBAkEA
vaHJ+Qb+e2hxgrwzbwYBQTcyFJ8bIXbCOAewujlPCOHv1CnyOJ+gjTpLWDcI+hH7
IudbkP1mM9NW1vNHHPu/9QJAS52UIkaqTcfmwXSRFO9B27dN1SXpLfGEqVN+4V6f
owy+09/YdTipcfDokqMjabERaUwG+iEananaTW2nAkx3Kg==
-----END RSA PRIVATE KEY-----
END

    my $rsa2 = <<END;
-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQC0MBqPIL1O2rq0geMyOvdGNdO6oKFNA26HE3YhJG4oDCBqYFkN
XTqs+E6fSdrqd/QLCGXTVrIb3VRwAZWPMbrGH4ZiHVO4ZNBlPN0uaEdYD753Jo/c
SXSx2qFtwLNhuobwC3BNBMlGfLKkw4Bb89Fg6VLFI5bpxz7xNxzPRosLoQIDAQAB
AoGBAIxL+CIBR+UiAcWSbKgrqWUNfDIP6Afi6ChcSto7V1nvNz4cjroNISaUoAL+
qmltxKLigwYutrdjed9MHHtGKTnTlCNaUnAyjRSmW7z2L/7zxqsO/a5sYytXIdFk
0T/ztPhgGcGS9gBf8wjJO7rsVJNc6c/aGl4/cZFEjC2SmJpRAkEA30h3Uzlm0Th9
LJfeCeER7IXPHFrRddScPXKXTUwFjR2gsaqSjghGJmvqvSQKlu2PQjGOosknLtZT
FSas1gfIDwJBAM6XGiLfP2P3jULmHhcYXdadqVsip0grO7XhUIw74+N1VHZl26G4
anGXSyvNxzftoip3DrW6/s7+MlcIUzWfwU8CQAPJ3vxyhOQX6UfQa9wPDZbNzm3U
vKkbKmuAfkC5gX6behaJpmLykP4l5p2+9s8IyN1+qcTpVNjemhpJxbT7/NECQDGl
JBW/OleGlL6/1/lK1LoPVzRcZoC0SvwRMi8Q8Vmmx25QWfBKBeJYLitPnxE0nOTB
iZpoXnVVprk9eemIA4cCQC0XNVsz5y2ioy+Qxd+vFU6Zw/Ix4iPda3OCEUHWs/MD
vMr6yzbX+HwUjqXLeypAKHWr6ddKxCHnSIktPU3RRbQ=
-----END RSA PRIVATE KEY-----
END

    my $p256_1 = <<END;
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIGCTWYFg2FHNSKR/tEYr0LN4ryn2YKtePfd07nPH8WpIoAoGCCqGSM49
AwEHoUQDQgAE79n9nyJFXF0Y2q194fMIfVK2z7rrArVuG+lqBPL3XYFPCF6sq6vz
D1uuOqE557XcIdX7obVgm32N0gIw9z9GIw==
-----END EC PRIVATE KEY-----
END

    my $p256_2 = <<END;
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEINjIWS5I+XmOJU1It7foTAJKS6YGdmz5AY38eZ/AoRiQoAoGCCqGSM49
AwEHoUQDQgAEg6+uydLOn111ZuewGShPwh4B9pqy+A/vYjnQljnihc2LkNTQKCRl
PE/rmAMQA9R8iRuOFOlzr4hkYDQX8ZlqbA==
-----END EC PRIVATE KEY-----
END

    my $ed25519_1 = <<END;
-----BEGIN PRIVATE KEY-----
MC4CAQAwBQYDK2VwBCIEIPP7sBjvqBSTr/WyIXc0PnDKpRSfPbQWq6gYDDBcuvr/
-----END PRIVATE KEY-----
END

    my $ed25519_2 = <<END;
-----BEGIN PRIVATE KEY-----
MC4CAQAwBQYDK2VwBCIEIDX2w1Pe1GTPfLYdZypIJ5clRAiDNs0BCmwjB2kBz3II
-----END PRIVATE KEY-----
END

    # user and signing key
    my @key_combos = (
        [ 'self-sign - RSA', $rsa1, $rsa1 ],
        [ 'two RSAs', $rsa1, $rsa2 ],
    );

    if (OpenSSL_Control::can_ecdsa()) {
        push @key_combos, (
            [ 'self-sign - ECC', $p256_1, $p256_1 ],
            [ 'two ECCs', $p256_1, $p256_2 ],
            [ 'subject RSA, signer ECC', $rsa1, $p256_1 ],
            [ 'subject ECC, signer RSA', $p256_1, $rsa1 ],
        );
    }

    if (OpenSSL_Control::can_ed25519()) {

        # Any OpenSSL that supports Ed25519 also supports ECC.
        push @key_combos, (
            [ 'self-sign - Ed25519', $ed25519_1, $ed25519_2 ],
            [ 'two Ed25519s', $ed25519_1, $ed25519_2 ],
            [ 'subject RSA, signer Ed25519', $rsa1, $ed25519_1 ],
            [ 'subject Ed25519, signer RSA', $ed25519_1, $rsa1 ],
            [ 'subject ECC, signer Ed25519', $p256_1, $ed25519_1 ],
            [ 'subject Ed25519, signer ECC', $ed25519_1, $p256_1 ],
        );
    }

    return @key_combos;
}

sub test_creation : Tests() {
    my @key_combos = _key_combos();

    my @needs_64bit;
    if (try { pack 'Q' }) {
        push @needs_64bit, (
            [
                'ct_precert_scts',
                {
                    timestamp => 1,
                    key_id => pack( 'H*', 'ee4bbdb775ce60bae142691fabe19e66a30f7e5fb072d88300c47b897aa8fdcb'),
                    hash_algorithm => 'sha256',
                    signature_algorithm => 'ecdsa',
                    signature => pack( 'H*', '3045022100e6fd1355f87c62d18d3f9628ffd074223764c947092bf3965c2584415b91472002200173b64dee1dcba40bd871c53073efd931acceec59368bdb97979ff07f9301c5'),
                },
                {
                    timestamp => 100100,
                    key_id => pack( 'H*', 'db74afeecb29ecb1feca3e716d2ce5b9aabb36f7847183c75d9d4f37b61fbf64' ),
                    hash_algorithm => 'sha256',
                    signature_algorithm => 'ecdsa',
                    signature => pack( 'H*', '3046022100ac559e93ccd09148e802e54ad3f7832e0464c0c071eb64b6d3fd52f2cf7fabe0022100d83199b57a1c4f80267901984525970757213a44b982d4a3c4903b3a62552fb2'),
                },
            ],
        );
    }

    for my $kc (@key_combos) {
        my ($label, $subject_pem, $signer_pem) = @$kc;

        diag $label;

        my $user_key = Crypt::Perl::PK::parse_key( $subject_pem );

        my $i = 2;

        my $cert = Crypt::Perl::X509v3->new(
            issuer => [
                [ commonName => "Felipe" . (1 + $i), surname => 'theIssuer' ],
                [ givenName => 'separate RDNs' ],
            ],
            subject => [ commonName => "Felipe" . (1 + $i), surname => 'theSubject' ],
            key => $user_key->get_public_key(),
            not_after => time + 360000000,

            extensions => [
                [ 'basicConstraints', 1 ],
                [ 'keyUsage', 'keyCertSign', 'keyEncipherment', 'keyAgreement', 'digitalSignature', 'keyAgreement' ],
                [ 'extKeyUsage', qw( serverAuth clientAuth codeSigning emailProtection timeStamping OCSPSigning ) ],
                [ 'subjectKeyIdentifier', "\x00\x01\x02" ],
                [ 'issuerAltName',
                    [ dNSName => 'fooissuer.com' ],
                    [ directoryName => [
                        givenName => 'Ludwig',
                        surname => 'van Beethoven',
                    ] ],
                ],
                [ 'subjectAltName',
                    [ dNSName => 'foo.com' ],
                    [ directoryName => [
                        givenName => 'Felipe',
                        surname => 'Gasper',
                    ] ],
                    #[ ediPartyName => {
                    #    nameAssigner => 'the nameAssigner',
                    #    partyName => 'the partyName',
                    #} ],
                ],
                [ 'authorityKeyIdentifier',
                    keyIdentifier => "\x77\x88\x99",
                    authorityCertIssuer => [
                        [ dNSName => 'foo.com' ],
                        [ directoryName => [
                            givenName => 'Margaret',
                            surname => 'Attia',
                        ] ],
                    ],
                    authorityCertSerialNumber => 2566678,
                ],
                [ 'authorityInfoAccess',
                    [ 'ocsp', uniformResourceIdentifier => 'http://some.ocsp.uri' ],
                    [ 'caIssuers', uniformResourceIdentifier => sprintf("http://caissuers.x%d.tld", 1 + $i) ],
                ],
                [ 'certificatePolicies',
                    [ 'organization-validated' ],
                    [ '1.3.6.1.4.1.6449.1.2.2.52',
                        [ cps => 'https://cps.uri' ],
                        [ unotice => {
                            noticeRef => {
                                organization => 'FooFoo',
                                noticeNumbers => [ 12, 23, 34 ],
                            },
                            explicitText => 'apple',
                        } ],
                    ],
                ],
                [ 'nameConstraints',
                    permitted => [
                        [ dNSName => 'haha.tld', 1, 4 ],
                    ],
                    excluded => [
                        [ dNSName => 'fofo.tld', 7 ],
                        [ rfc822Name => 'haha@fofo.tld' ],
                    ],
                ],
                [ 'policyConstraints', requireExplicitPolicy => 4, inhibitPolicyMapping => 6 ],
                [ inhibitAnyPolicy => 7 ],
                [ 'subjectInfoAccess',
                    [ 'caRepository', uniformResourceIdentifier => 'http://some.car.uri' ],
                    [ 'timeStamping', uniformResourceIdentifier => 'http://some.timeStamping.uri' ],
                ],
                [ 'tlsFeature' => 'status_request_v2' ],
                [ 'noCheck' ],
                [ 'policyMappings',
                    {
                        subject => 'anyPolicy',
                        issuer => '1.2.3.4',
                    },
                    {
                        subject => '5.6.7.8',
                        issuer => 'anyPolicy',
                    },
                ],
                [ 'cRLDistributionPoints',
                    {
                        distributionPoint => {
                            fullName => [
                                [ uniformResourceIdentifier => 'http://myhost.com/myca.crl' ],
                                [ dNSName => 'full.name2.tld' ],
                            ],
                        },
                        reasons => [ 'unused', 'privilegeWithdrawn' ],
                    },
                    {
                        distributionPoint => {
                            nameRelativeToCRLIssuer => [
                                commonName => 'common',
                                surname => 'Jones',
                            ],
                        },
                        cRLIssuer => [
                            [ directoryName => [ commonName => 'thecommon' ] ],
                        ],
                    },
                ],
                [ 'freshestCRL',
                    {
                        distributionPoint => {
                            fullName => [
                                [ uniformResourceIdentifier => 'http://myhost.com/myca.crl' ],
                                [ dNSName => 'full.name2.tld' ],
                            ],
                        },
                        reasons => [ 'unused', 'privilegeWithdrawn' ],
                    },
                    {
                        distributionPoint => {
                            nameRelativeToCRLIssuer => [
                                commonName => 'common',
                                surname => 'Jones',
                            ],
                        },
                        cRLIssuer => [
                            [ directoryName => [ commonName => 'thecommon' ] ],
                        ],
                    },
                ],
                [ 'ct_precert_poison' ],

                @needs_64bit,

                [ 'acmeValidation-v1' => join( q<>, map { chr } 0 .. 31 ) ],
                #[ 'subjectDirectoryAttributes',
                #    [ commonName => 'foo', 'bar' ],
                #],
            ],
        );

        my $signing_key = Crypt::Perl::PK::parse_key( $signer_pem );

        $cert->sign($user_key, 'sha256');

        my $pem = $cert->to_pem() or die "No PEM?!?";

        my ($wfh, $fpath) = File::Temp::tempfile( CLEANUP => 1 );
        print {$wfh} $pem or die $!;
        close $wfh;

        my $ossl_bin = OpenSSL_Control::openssl_bin();

        my $asn1parse = `$ossl_bin asn1parse -i -dump -in $fpath`;
        cmp_ok($?, '==', 0, "$label: asn1parse succeeds" ) or diag $asn1parse;

        my $x509parse = `$ossl_bin x509 -text -in $fpath -noout`;
        cmp_ok($?, '==', 0, "$label: x509 parses OK") or diag $x509parse;
    }

    return;
}
