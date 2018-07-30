#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan tests => 3;

use Test::Exception;

use File::Temp;

use FindBin;
use lib "$FindBin::Bin/lib";

use OpenSSL_Control;

use Crypt::Perl::PK ();
use Crypt::Perl::X509v3 ();

my $key = <<END;
-----BEGIN PRIVATE KEY-----
MC4CAQAwBQYDK2VwBCIEIP0u+iUo7N1rD9jwFUujZpIkAbPLuosVwUkWOLGPaZme
-----END PRIVATE KEY-----
END

my $ed25519 = Crypt::Perl::PK::parse_key($key);

my $cert_pem;

lives_ok(
    sub {
        my $cert = Crypt::Perl::X509v3->new(
            issuer => [ commonName => 'issuer' ],
            subject => [ commonName => 'subject' ],
            not_before => time,
            not_after => time + 123,
            key => $ed25519->get_public_key(),
        );

        $cert->sign( $ed25519 );

        $cert_pem = $cert->to_pem();
    },
    'Certificate is created as expected.',
);

SKIP: {
    my $bin = OpenSSL_Control::openssl_bin();

    skip "$bin can’t handle ed25519 keys.", 2 if !OpenSSL_Control::can_ed25519();

    my ($tfh, $temppath) = File::Temp::tempfile( CLEANUP => 1 );
    print { $tfh } $cert_pem;
    close $tfh;

    my $parse = `$bin x509 -noout -text -in $temppath`;
    die 'Failed parse?' if $?;

    like( $parse, qr<ed25519>i, 'parse gives expected output' );

    like(
        $parse,
        qr<ec.*2a.*f5.*a7.*b7.*9f.*65.*d3>i,
        'public key is in the output as expected',
    );
}
