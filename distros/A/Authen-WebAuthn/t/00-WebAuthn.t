use Test::More;
use MIME::Base64 'encode_base64url';
use Crypt::URandom qw( urandom );
use Hash::Merge::Simple qw/merge/;
use Carp;
use strict;

use Authen::WebAuthn;
use Authen::WebAuthn::Test;

# The RP lib used for these tests
my $rp = Authen::WebAuthn->new(
    origin => "http://auth.example.com",
    rp_id  => "auth.example.com",
);

my $ecdsa_key = <<ENDKEY;
-----BEGIN EC PRIVATE KEY-----
MIIBUQIBAQQgWEGujn2kkOVckTIKhIJDSqH99bxydPGloXvbeaq9swiggeMwgeAC
AQEwLAYHKoZIzj0BAQIhAP////8AAAABAAAAAAAAAAAAAAAA////////////////
MEQEIP////8AAAABAAAAAAAAAAAAAAAA///////////////8BCBaxjXYqjqT57Pr
vVV2mIa8ZR0GsMxTsPY7zjw+J9JgSwRBBGsX0fLhLEJH+Lzm5WOkQPJ3A32BLesz
oPShOUXYmMKWT+NC4v4af5uO5+tKfA+eFivOM1drMV7Oy7ZAaDe/UfUCIQD/////
AAAAAP//////////vOb6racXnoTzucrC/GMlUQIBAaFEA0IABM/oQXEUzjPwEhM4
gWmIbCuOXc4Ja8jPDKxbQaZckal7/9a693/nkf7flk1S9AV2tjrtJPF6kg8TCGbF
KoeD9Wc=
-----END EC PRIVATE KEY-----
ENDKEY

# The authenticator simulator
my $authenticator = Authen::WebAuthn::Test->new(
    origin        => "http://auth.example.com",
    rp_id         => "auth.example.com",
    credential_id => "lZYltP9MtoRNuXK8f8tWf",
    aaguid        => "00000000-0000-0000-0000-000000000000",
    key           => $ecdsa_key,
);

my $res;

# This method generates a registration response from the authenticator and
# attempts to validate it with the RP.
# $option lets you override options for the validation method
# Use the $override hash to manipulate the authenticator response and do funky
# stuff
sub validate_registration {
    my ( $authenticator, $rp, $options, $override ) = @_;

    my $challenge  = encode_base64url( urandom(10) );
    my $credential = $authenticator->get_credential_response( {
            request => {
                challenge              => $challenge,
                authenticatorSelection => { (
                        $options->{requested_uv}
                        ? ( userVerification => $options->{requested_uv} )
                        : ()
                    ),
                },
            },
        },
        $override
    );

    my $registration_params = merge {
        challenge_b64        => $challenge,
        client_data_json_b64 =>
          encode_base64url( $credential->{response}->{clientDataJSON} ),
        attestation_object_b64 =>
          encode_base64url( $credential->{response}->{attestationObject} ),
    }, $options;
    return $rp->validate_registration( %{$registration_params} );
}

# This method generates an authentication response from the authenticator and
# attempts to validate it with the RP.
# Use the override hash to manipulate the authenticator response and do funky
# stuff
sub validate_authentication {
    my ( $authenticator, $rp, $options, $override ) = @_;

    my $challenge  = encode_base64url( urandom(10) );
    my $credential = $authenticator->get_assertion_response( {
            request => {
                challenge => $challenge,
                (
                    $options->{requested_uv}
                    ? ( userVerification => $options->{requested_uv} )
                    : ()
                ),
            },
        },
        $override
    );

    my $assertion_params = merge {
        challenge_b64         => $challenge,
        credential_pubkey_b64 =>
          encode_base64url( $authenticator->encode_cosekey ),
        client_data_json_b64 =>
          encode_base64url( $credential->{response}->{clientDataJSON} ),
        authenticator_data_b64 =>
          encode_base64url( $credential->{response}->{authenticatorData} ),
        signature_b64 =>
          encode_base64url( $credential->{response}->{signature} ),
    }, $options;

    return $rp->validate_assertion( %{$assertion_params} );
}

sub test_registration {
    my ( $options, $override, $test_name, $exception_message ) = @_;

    my $res;
    eval {
        $res =
          validate_registration( $authenticator, $rp, $options, $override );
    };
    my $exception = $@;
    if ($exception_message) {
        like( $exception, $exception_message,
            "$test_name fails with expected message" );
    }
    elsif ($exception) {
        fail($test_name);
        diag("Exception: $exception");
    }
    else {
        is( $res->{attestation_result}->{success}, 1, "$test_name succeeds" );
    }
    return $res;
}

sub test_authentication {
    my ( $options, $override, $test_name, $exception_message ) = @_;

    my $res;
    eval {
        $res =
          validate_authentication( $authenticator, $rp, $options, $override );
    };
    my $exception = $@;
    if ($exception_message) {
        like( $exception, $exception_message,
            "$test_name fails with expected message" );
    }
    else {
        is( $res->{success}, 1, "$test_name succeed as expected" );
    }

    return $res;
}

# Registration tests

test_registration( {}, {}, "Success with default options" );

test_registration( { requested_uv => "required" },
    {}, "Success with required UV" );

test_registration(
    { requested_uv => "required" },
    {
        response => {
            attestationObject =>
              { authData => { flags => { userVerified => 0 } } }
        }
    },
    "Fail when authenticator does not send required UV",
    qr,User not verified during WebAuthn registration,
);

$authenticator->rp_id('invalid');
test_registration( {}, {}, "Fails with wrong RP ID",
qr,RP ID hash received from authenticator.*does not match the hash of this RP ID,
);
$authenticator->rp_id('auth.example.com');

$authenticator->origin('invalid');
test_registration(
    {}, {},
    "Fails with wrong Origin",
    qr,Origin received from client data.*does not match server origin,
);
$authenticator->origin('http://auth.example.com');

test_registration(
    {},
    { response => { clientDataJSON => { challenge => "xxx" } } },
    "Fails with wrong challenge",
    qr,Challenge received from client data.*does not match server challenge,
);

test_registration(
    { allowed_attestation_types => ["Basic"] },
    {},
    "Fails with disallowed attestation type",
    qr,Attestation type None is not allowed,
);

# Authentication tests
test_authentication( {}, {}, "Success with default options" );
test_authentication( { requested_uv => "required" },
    {}, "Success with required UV" );
test_authentication(
    { requested_uv => "required" },
    { response => { authenticatorData => { flags => { userVerified => 0 } } } },
    "Fail when authenticator does not send required UV",
    qr,User not verified during WebAuthn authentication,
);

$authenticator->rp_id('invalid');
test_authentication( {}, {}, "Fails with wrong RP ID",
qr,RP ID hash received from authenticator.*does not match the hash of this RP ID,
);
$authenticator->rp_id('auth.example.com');

$authenticator->origin('invalid');
test_authentication(
    {}, {},
    "Fails with wrong Origin",
    qr,Origin received from client data.*does not match server origin,
);
$authenticator->origin('http://auth.example.com');

test_authentication(
    {},
    { response => { clientDataJSON => { challenge => "xxx" } } },
    "Fails with wrong challenge",
    qr,Challenge received from client data.*does not match server challenge,
);

$authenticator->sign_count(10);
$res = test_authentication( { stored_sign_count => 5 },
    {}, "Success with normal signature count" );
is( $res->{signature_count}, 10, "Signature count is updated" );

$authenticator->sign_count(10);
test_authentication(
    { stored_sign_count => 20 },
    {},
    "Fails with wrong signature count",
    qr,Stored signature count.*higher than device signature count,
);

test_authentication(
    { stored_sign_count => 10 },
    {},
    "Fails with wrong signature count",
    qr,Stored signature count.*higher than device signature count,
);
$authenticator->sign_count(0);

test_authentication(
    { token_binding_id_b64 => "YWJjCg" },
    {
        response => {
            clientDataJSON =>
              { tokenBinding => { status => "present", id => "ZmFpbAo" } }
        }
    },
    "Mismatching token binding ID fails",
    qr,Token Binding ID.*does not match,
);

test_authentication(
    {},
    {
        response => {
            clientDataJSON =>
              { tokenBinding => { status => "present", id => "ZmFpbAo" } }
        }
    },
    "Token binding used in Client Data JSON but not in TLS connection",
qr,The Token Binding ID from the current connection.*does not match Token Binding ID in client data,
);

test_authentication(
    { token_binding_id_b64 => "YWJjCg" },
    {
        response => {
            clientDataJSON =>
              { tokenBinding => { status => "present", id => "YWJjCg" } }
        }
    },
    "Correct token binding ID works",
);

test_authentication(
    { signature_b64 => "" },
    {},
    "Empty signature fails to validate",
    qr,Webauthn signature was not valid,
);

test_authentication(
    { signature_b64 => "xxxyyy" },
    {},
    "Invalid signature fails to validate",
    qr,Webauthn signature was not valid,
);

test_authentication( {
        signature_b64        => "xxxyyy",
        client_data_json_b64 => ""
    },
    {},
    "Invalid client data fails to validate",
    qr,Error deserializing client data,
);

done_testing();
