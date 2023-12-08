#!perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;
use Test::MockObject;
use JSON qw/ encode_json /;

use FindBin qw/ $Bin /;
use Crypt::JWT qw/ decode_jwt /;
use Crypt::PK::ECC;

use_ok( 'Business::TrueLayer::Signer' );

# private key for test generated with:
#     openssl ecparam -genkey -name secp521r1 -noout \
#     -out ec512-private-key-FOR-TEST.pem
my $private_key = "$Bin/../../ec512-private-key-FOR-TEST.pem";
my $public_key  = "$Bin/../../ec512-public-key-FOR-TEST.pem";

isa_ok(
    my $Signer = Business::TrueLayer::Signer->new(
        kid => "9f2b7bd6-c055-40b5-b616-120ccfd33c49",
        private_key => $private_key,
    ),
    'Business::TrueLayer::Signer',
);

foreach my $serialized_http_request_body (
    '{"currency":"GBP","amount_in_minor":100}',
    undef,
) {
    ok(
        my ( $jws_detached,$jws_full ) = $Signer->sign_request(
            'post',
            '/payouts',
            '619410b3-b00c-406e-bb1b-2982f97edb8b',
            $serialized_http_request_body,
        ),
        '->sign_request',
    );

    my ( $header,$payload,$signature) = split( /\./,$jws_full );
    is( $jws_detached,"$header..$signature","detached JWS" );

    my $content = decode_jwt(
        token => $jws_full,
        key   => Crypt::PK::ECC->new( $public_key ),
    );

    is(
        $content,
        "POST /payouts
Idempotency-Key: 619410b3-b00c-406e-bb1b-2982f97edb8b"
        . (
            $serialized_http_request_body
                ? "\n$serialized_http_request_body"
                : ""
        ),
        'JWS decodes with public key'
    );
}

done_testing();
