use Test::More;
use MIME::Base64 'encode_base64url';
use strict;

use Authen::WebAuthn;

require 't/certs.pl';

# Simulate a unix date where the test certificates are still valid
$Authen::WebAuthn::SSLeayChainVerifier::verification_time = 1698765432;

# Registration tests, interoperability data from
# https://github.com/duo-labs/py_webauthn

my $webauthn = Authen::WebAuthn->new(
    origin => "http://localhost:5000",
    rp_id  => "localhost",
);
my $reg;

my %none_attestation_response = (
    challenge_b64 =>
"TwN7n4WTyGKLc4ZY-qGsFqKnHM4nglqsyV0ICJlN2TO9XiRyFtrkaDwUvsql-gkLJXP6fnF1MlrZ53Mm4R7Cvw",
    requested_uv           => "required",
    attestation_object_b64 =>
"o2NmbXRkbm9uZWdhdHRTdG10oGhhdXRoRGF0YVjESZYN5YgOjGh0NBcPZHZgW4_krrmihjLHmVzzuoMdl2NFAAAAFwAAAAAAAAAAAAAAAAAAAAAAQPctcQPE5oNRRJk_nO_371mf7qE7qIodzr0eOf6ACvnMB1oQG165dqutoi1U44shGezu5_gkTjmOPeJO0N8a7P-lAQIDJiABIVggSFbUJF-42Ug3pdM8rDRFu_N5oiVEysPDB6n66r_7dZAiWCDUVnB39FlGypL-qAoIO9xWHtJygo2jfDmHl-_eKFRLDA",
    client_data_json_b64 =>
"eyJ0eXBlIjoid2ViYXV0aG4uY3JlYXRlIiwiY2hhbGxlbmdlIjoiVHdON240V1R5R0tMYzRaWS1xR3NGcUtuSE00bmdscXN5VjBJQ0psTjJUTzlYaVJ5RnRya2FEd1V2c3FsLWdrTEpYUDZmbkYxTWxyWjUzTW00UjdDdnciLCJvcmlnaW4iOiJodHRwOi8vbG9jYWxob3N0OjUwMDAiLCJjcm9zc09yaWdpbiI6ZmFsc2V9",
);

subtest "None attestation type, None is allowed" => sub {
    $reg = $webauthn->validate_registration(%none_attestation_response);
    is( $reg->{attestation_result}->{success},
        1, "Attestation validation succeeded" );
    is( $reg->{attestation_result}->{type}, "None",
        "Attestation type is None" );
};

subtest " None attestation type, None is not allowed " => sub {
    eval {
        $webauthn->validate_registration( %none_attestation_response,
            allowed_attestation_types => ["Basic"] );
    };
    like( $@, qr/Attestation type None is not allowed/, "Died: $@" );
};

my %packed_attestation_response = (
    challenge_b64 =>
"8LBCiOY3q1cBZHFAWtS4AZZChzGphy67lK7I70zKi4yC7pgrQ2Pch7nAjLk1wq9greshIAsW2AjibhXjjI0TmQ",
    requested_uv         => 0,
    client_data_json_b64 =>
"eyJ0eXBlIjoid2ViYXV0aG4uY3JlYXRlIiwiY2hhbGxlbmdlIjoiOExCQ2lPWTNxMWNCWkhGQVd0UzRBWlpDaHpHcGh5NjdsSzdJNzB6S2k0eUM3cGdyUTJQY2g3bkFqTGsxd3E5Z3Jlc2hJQXNXMkFqaWJoWGpqSTBUbVEiLCJvcmlnaW4iOiJodHRwOi8vbG9jYWxob3N0OjUwMDAiLCJjcm9zc09yaWdpbiI6ZmFsc2V9",
    attestation_object_b64 =>
"o2NmbXRmcGFja2VkZ2F0dFN0bXSjY2FsZyZjc2lnWEcwRQIhAOfrFlQpbavT6dJeTDJSCDzYSYPjBDHli2-syT2c1IiKAiAx5gQ2z5cHjdQX-jEHTb7JcjfQoVSW8fXszF5ihSgeOGN4NWOBWQLBMIICvTCCAaWgAwIBAgIEKudiYzANBgkqhkiG9w0BAQsFADAuMSwwKgYDVQQDEyNZdWJpY28gVTJGIFJvb3QgQ0EgU2VyaWFsIDQ1NzIwMDYzMTAgFw0xNDA4MDEwMDAwMDBaGA8yMDUwMDkwNDAwMDAwMFowbjELMAkGA1UEBhMCU0UxEjAQBgNVBAoMCVl1YmljbyBBQjEiMCAGA1UECwwZQXV0aGVudGljYXRvciBBdHRlc3RhdGlvbjEnMCUGA1UEAwweWXViaWNvIFUyRiBFRSBTZXJpYWwgNzE5ODA3MDc1MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEKgOGXmBD2Z4R_xCqJVRXhL8Jr45rHjsyFykhb1USGozZENOZ3cdovf5Ke8fj2rxi5tJGn_VnW4_6iQzKdIaeP6NsMGowIgYJKwYBBAGCxAoCBBUxLjMuNi4xLjQuMS40MTQ4Mi4xLjEwEwYLKwYBBAGC5RwCAQEEBAMCBDAwIQYLKwYBBAGC5RwBAQQEEgQQbUS6m_bsLkm5MAyP6SDLczAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4IBAQByV9A83MPhFWmEkNb4DvlbUwcjc9nmRzJjKxHc3HeK7GvVkm0H4XucVDB4jeMvTke0WHb_jFUiApvpOHh5VyMx5ydwFoKKcRs5x0_WwSWL0eTZ5WbVcHkDR9pSNcA_D_5AsUKOBcbpF5nkdVRxaQHuuIuwV4k1iK2IqtMNcU8vL6w21U261xCcWwJ6sMq4zzVO8QCKCQhsoIaWrwz828GDmPzfAjFsJiLJXuYivdHACkeJ5KHMt0mjVLpfJ2BCML7_rgbmvwL7wBW80VHfNdcKmKjkLcpEiPzwcQQhiN_qHV90t-p4iyr5xRSpurlP5zic2hlRkLKxMH2_kRjhqSn4aGF1dGhEYXRhWMRJlg3liA6MaHQ0Fw9kdmBbj-SuuaKGMseZXPO6gx2XY0UAAAA0bUS6m_bsLkm5MAyP6SDLcwBAsyGQPDZRUYdb4m3rdWeyPaIMYlbmydGp1TP_33vE_lqJ3PHNyTd0iKsnKr5WjnCcBzcesZrDEfB_RBLFzU3k46UBAgMmIAEhWCBAX_i3O3DvBnkGq_uLNk_PeAX5WwO_MIxBp0mhX6Lw7yJYIOW-1-Fch829McWvRUYAHTWZTx5IycKSGECL1UzUaK_8",
);

subtest "Packed attestation with known CA succeeds" => sub {
    $reg = $webauthn->validate_registration( %packed_attestation_response,
        trust_anchors => [$main::yubico_u2f_root], );
    is( $reg->{attestation_result}->{success}, 1, "Yubico packed attestation" );
};

subtest
  "Packed attestation with explicitely trusted attestation cert succeeds" =>
  sub {
    $reg = $webauthn->validate_registration( %packed_attestation_response,
        trust_anchors => [$main::yubico_cert], );
    is( $reg->{attestation_result}->{success}, 1, "Yubico packed attestation" );
  };

subtest "Packed attestation with unknown CA fails" => sub {
    eval {
        $reg =
          $webauthn->validate_registration( %packed_attestation_response, );
    };
    like( $@, qr/Could not verify X.509 chain/, "Died: $@" );
};

subtest "Packed attestation with wrong CA fails" => sub {
    eval {
        $reg = $webauthn->validate_registration( %packed_attestation_response,
            trust_anchors => [$main::titan_root], );
    };
    like( $@, qr/Could not verify X.509 chain/, "Died: $@" );
};

subtest "Packed attestation with unknown CA,"
  . " but untrusted registration is allowed" => sub {

    # packed attestation, unknown CA, but untrusted registration is allowed
    $reg = $webauthn->validate_registration( %packed_attestation_response,
        allow_untrusted_attestation => 1, );
    is( $reg->{attestation_result}->{success},
        1, "Attestation reported as successful" );
    is( $reg->{attestation_result}->{type},
        "Self", "Attestation reported as Self" );
    is( $reg->{attestation_result}->{aaguid},
        undef, "Untrusted AAGUID is not reported" );
  };

subtest "packed attestation, unknown CA,"
  . " untrusted registration is allowed,"
  . " but Self is not allowed" => sub {
    eval {
        $reg = $webauthn->validate_registration(
            %packed_attestation_response,
            allow_untrusted_attestation => 1,
            allowed_attestation_types   => ["Basic"],
        );
    };
    like( $@, qr/Attestation type Self is not allowed/, "Died: $@" );
  };

done_testing();
