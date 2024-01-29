use Test::More;
use MIME::Base64 'encode_base64url';
use strict;

use Authen::WebAuthn;
use Authen::WebAuthn::Test;

require 't/certs.pl';

# Simulate a unix date where the test certificates are still valid
$Authen::WebAuthn::SSLeayChainVerifier::verification_time = 1698765432;

my $webauthn = Authen::WebAuthn->new(
    origin => "http://localhost:5000",
    rp_id  => "localhost",
);
my $reg;

$reg = $webauthn->validate_registration(
    challenge_b64        => "7b1m6n2KgMAuTp-FbOAl6sb0gD_5HZITqDF7ld8tl28",
    requested_uv         => 0,
    client_data_json_b64 =>
"eyJjaGFsbGVuZ2UiOiI3YjFtNm4yS2dNQXVUcC1GYk9BbDZzYjBnRF81SFpJVHFERjdsZDh0bDI4Iiwib3JpZ2luIjoiaHR0cDovL2xvY2FsaG9zdDo1MDAwIiwidHlwZSI6IndlYmF1dGhuLmNyZWF0ZSJ9",
    attestation_object_b64 =>
"o2NmbXRoZmlkby11MmZnYXR0U3RtdKJjeDVjgVkCwjCCAr4wggGmoAMCAQICBFsWqLYwDQYJKoZIhvcNAQELBQAwLjEsMCoGA1UEAxMjWXViaWNvIFUyRiBSb290IENBIFNlcmlhbCA0NTcyMDA2MzEwIBcNMTQwODAxMDAwMDAwWhgPMjA1MDA5MDQwMDAwMDBaMG8xCzAJBgNVBAYTAlNFMRIwEAYDVQQKDAlZdWJpY28gQUIxIjAgBgNVBAsMGUF1dGhlbnRpY2F0b3IgQXR0ZXN0YXRpb24xKDAmBgNVBAMMH1l1YmljbyBVMkYgRUUgU2VyaWFsIDE1MjgyMTE2MzgwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATpUYQzAjn_7c5XI3ZXFEcb0u1FPgjKEAH7Y8YRUB8qoDIPVsMUoTfh2FkOKYqmLm9WKR8d2THVhF1GVcD-qr5Vo2wwajAiBgkrBgEEAYLECgIEFTEuMy42LjEuNC4xLjQxNDgyLjEuMTATBgsrBgEEAYLlHAIBAQQEAwIEMDAhBgsrBgEEAYLlHAEBBAQSBBAUmiAhjvZBM5a4gfjVt_H1MAwGA1UdEwEB_wQCMAAwDQYJKoZIhvcNAQELBQADggEBAKeoJ3kGYlenGfd1JFGnpIysIv8PgxWf2boIzJ46mYh5kdJHz9gBKv7TxEfr6JPxYp_U1tbI-ARrVYzbIlHzham5X96ST8ccBx7q1kv_kMqBI8UALcTXqsGIrQPmnb0qhrPYjwpmys7Yig06Bpb_ezTjzFJL2qq1_CZ7kALsB29f6J-g4o0MbDzPPiHKmDMCg1XnCF2czjTZF-MrsO91weSTgPBqsOGJkcOH7uw16NOu6jsATwufNB4DuT4xHLHAYTLN3J_eZQ_NOshGDQSQVZT_9SLTOtV8zI-UELXolAET45PWt11N118BqVdQvNp0Z1WLv91HgC8eu5ypwps8QFFjc2lnWEcwRQIgDyI59-uZ2IhRx00l9nytskejo35Z2t0ICNsScgCRLu8CIQDcz_mWQbFpKFxYmPspDHMyVJwfhBfWGgEg7HDVQIuIs2hhdXRoRGF0YVjESZYN5YgOjGh0NBcPZHZgW4_krrmihjLHmVzzuoMdl2NBAAAAAAAAAAAAAAAAAAAAAAAAAAAAQBR58XLch_tqbJVweKnALcObkWVGp36E1ViHuGBzjHzcUKtYe2no12yeT5Z2vzNWqHJpuBGWVu810ugLdMUNsL2lAQIDJiABIVggF0OOeN1A_TqYLnu8XSCXSEq5BYZRvuRyRN3EHtfls9siWCCwpc_DLM96Tqp6F0uRkuDUPwu5q-aTnZtHTNJXBuhPeQ",
    trust_anchors => [$main::yubico_u2f_root],
);

is( $reg->{attestation_result}->{success}, 1, "Yubico U2F attestation" );

done_testing();
