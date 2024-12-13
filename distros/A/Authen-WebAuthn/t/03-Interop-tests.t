use Test::More;
use MIME::Base64 'encode_base64url';
use strict;

use Authen::WebAuthn;

use lib ".";
require 't/certs.pl';

# Simulate a unix date where the test certificates are still valid
$Authen::WebAuthn::SSLeayChainVerifier::verification_time = 1698765432;

# Authentication interoperability tests, data from
# https://github.com/duo-labs/py_webauthn

my $webauthn = Authen::WebAuthn->new(
    origin => "http://localhost:5000",
    rp_id  => "localhost",
);
my $reg;

# Auth ECC key
my $val = $webauthn->validate_assertion(
    challenge_b64 =>
"xi30GPGAFYRxVDpY1sM10DaLzVQG66nv-_7RUazH0vI2YvG8LYgDEnvN5fZZNVuvEDuMi9te3VLqb42N0fkLGA",
    credential_pubkey_b64 =>
"pQECAyYgASFYIIeDTe-gN8A-zQclHoRnGFWN8ehM1b7yAsa8I8KIvmplIlgg4nFGT5px8o6gpPZZhO01wdy9crDSA_Ngtkx0vGpvPHI",
    stored_sign_count    => 10,
    requested_uv         => 1,
    client_data_json_b64 =>
"eyJjaGFsbGVuZ2UiOiJ4aTMwR1BHQUZZUnhWRHBZMXNNMTBEYUx6VlFHNjZudi1fN1JVYXpIMHZJMll2RzhMWWdERW52TjVmWlpOVnV2RUR1TWk5dGUzVkxxYjQyTjBma0xHQSIsImNsaWVudEV4dGVuc2lvbnMiOnt9LCJoYXNoQWxnb3JpdGhtIjoiU0hBLTI1NiIsIm9yaWdpbiI6Imh0dHA6Ly9sb2NhbGhvc3Q6NTAwMCIsInR5cGUiOiJ3ZWJhdXRobi5nZXQifQ",
    authenticator_data_b64 =>
      "SZYN5YgOjGh0NBcPZHZgW4_krrmihjLHmVzzuoMdl2MBAAAATg",
    signature_b64 =>
"MEUCIGisVZOBapCWbnJJvjelIzwpixxIwkjCCb5aCHafQu68AiEA88v-2pJNNApPFwAKFiNuf82-2hBxYW5kGwVweeoxCwo",
);
is( $val->{success}, 1, "Authentication with ECC key" );

# Auth RSA key
my $val = $webauthn->validate_assertion(
    challenge_b64 =>
"iPmAi1Pp1XL6oAgq3PWZtZPnZa1zFUDoGbaQ0_KvVG1lF2s3Rt_3o4uSzccy0tmcTIpTTT4BU1T-I4maavndjQ",
    credential_pubkey_b64 =>
"pAEDAzkBACBZAQDfV20epzvQP-HtcdDpX-cGzdOxy73WQEvsU7Dnr9UWJophEfpngouvgnRLXaEUn_d8HGkp_HIx8rrpkx4BVs6X_B6ZjhLlezjIdJbLbVeb92BaEsmNn1HW2N9Xj2QM8cH-yx28_vCjf82ahQ9gyAr552Bn96G22n8jqFRQKdVpO-f-bvpvaP3IQ9F5LCX7CUaxptgbog1SFO6FI6ob5SlVVB00lVXsaYg8cIDZxCkkENkGiFPgwEaZ7995SCbiyCpUJbMqToLMgojPkAhWeyktu7TlK6UBWdJMHc3FPAIs0lH_2_2hKS-mGI1uZAFVAfW1X-mzKL0czUm2P1UlUox7IUMBAAE",
    stored_sign_count    => 0,
    requested_uv         => 1,
    client_data_json_b64 =>
"eyJ0eXBlIjoid2ViYXV0aG4uZ2V0IiwiY2hhbGxlbmdlIjoiaVBtQWkxUHAxWEw2b0FncTNQV1p0WlBuWmExekZVRG9HYmFRMF9LdlZHMWxGMnMzUnRfM280dVN6Y2N5MHRtY1RJcFRUVDRCVTFULUk0bWFhdm5kalEiLCJvcmlnaW4iOiJodHRwOi8vbG9jYWxob3N0OjUwMDAiLCJjcm9zc09yaWdpbiI6ZmFsc2V9",
    authenticator_data_b64 =>
      "SZYN5YgOjGh0NBcPZHZgW4_krrmihjLHmVzzuoMdl2MFAAAAAQ",
    signature_b64 =>
"iOHKX3erU5_OYP_r_9HLZ-CexCE4bQRrxM8WmuoKTDdhAnZSeTP0sjECjvjfeS8MJzN1ArmvV0H0C3yy_FdRFfcpUPZzdZ7bBcmPh1XPdxRwY747OrIzcTLTFQUPdn1U-izCZtP_78VGw9pCpdMsv4CUzZdJbEcRtQuRS03qUjqDaovoJhOqEBmxJn9Wu8tBi_Qx7A33RbYjlfyLm_EDqimzDZhyietyop6XUcpKarKqVH0M6mMrM5zTjp8xf3W7odFCadXEJg-ERZqFM0-9Uup6kJNLbr6C5J4NDYmSm3HCSA6lp2iEiMPKU8Ii7QZ61kybXLxsX4w4Dm3fOLjmDw",
);
is( $val->{success}, 1, "Authentication with RSA key" );

$webauthn = Authen::WebAuthn->new(
    origin => "https://example.org",
    rp_id  => "example.org",
);

# Test vectors from W3C spec
my %android_key_params = (
    challenge_b64 => encode_base64url(
        pack( 'H*',
            '3de1f0b7365dccde3ff0cbf25e26ffa7baff87ef106c80fc865dc402d9960050' )
    ),
    client_data_json_b64 => encode_base64url(
        pack( 'H*',
'7b2274797065223a22776562617574686e2e637265617465222c226368616c6c656e6765223a2250654877747a5a647a4e345f384d76795869625f7037725f682d385162494438686c334541746d57414641222c226f726967696e223a2268747470733a2f2f6578616d706c652e6f7267222c2263726f73734f726967696e223a66616c73652c22657874726144617461223a22636c69656e74446174614a534f4e206d617920626520657874656e6465642077697468206164646974696f6e616c206669656c647320696e20746865206675747572652c207375636820617320746869733a205656316351755232714c4d5f616d50666f487a4c30673d3d227d',
        )
    ),
    attestation_object_b64 => encode_base64url(
        pack( 'H*',
'a363666d746b616e64726f69642d6b65796761747453746d74a363616c672663736967584630440220592bbc3c4c5f6158b52be1e085c92848986d7844245dfc9512e1a7e9ff7a2cd8022015bdd0852d3bd091e1c22da4211f4ccf0fdf4d912599d1c6630b1f310d3166f5637835638159026d3082026930820210a00302010202101ff91f76b63f44812f998b250b0286bf300a06082a8648ce3d0403023062311e301c06035504030c15576562417574686e207465737420766563746f7273310c300a060355040a0c0357334331253023060355040b0c1c41757468656e74696361746f72204174746573746174696f6e204341310b30090603550406130241413020170d3234303130313030303030305a180f33303234303130313030303030305a305f311e301c06035504030c15576562417574686e207465737420766563746f7273310c300a060355040a0c0357334331223020060355040b0c1941757468656e74696361746f72204174746573746174696f6e310b30090603550406130241413059301306072a8648ce3d020106082a8648ce3d0301070342000499169657036d089a2a9821a7d0063d341f1a4613389359636efab5f3cbf1accfdd91c55543176ea99b644406dd1dd63774b6af65ac759e06ff40b1c8ab02df6ba381a83081a5300c0603551d130101ff04023000300e0603551d0f0101ff040403020780301d0603551d0e041604141ac81e50641e8d1339ab9f7eb25f0cd5aac054b0301f0603551d2304183016801445aff715b0dd786741fee996ebc16547a3931b1e3045060a2b06010401d679020111043730350202012c0201000201000201000420b20e943e3a7544b3a438943b6d5655313a47ef1af34e00ff3261aeb9ed155817040030003000300a06082a8648ce3d040302034700304402206f4609c9ffc946c418cef04c64a0d07bcce78f329b99270b822f2a4d1e3b75330220093c8d18328f36ef157f296393bdc7721dd2bd67438ffeaa42f051a044b7457168617574684461746158a4bfabc37432958b063360d3ad6461c9c4735ae7f8edd46592a5e0f01452b2e4b55d00000000ade9705e1ce7085b899a540d02199bf800200a4729519788b6ed8a2d772b494e186244d8c798c052960dbc8c10c915176795a501020326200121582099169657036d089a2a9821a7d0063d341f1a4613389359636efab5f3cbf1accf225820dd91c55543176ea99b644406dd1dd63774b6af65ac759e06ff40b1c8ab02df6b'
        )
    ),
);

eval { my $reg = $webauthn->validate_registration( %android_key_params, ); };
like(
    $@,
qr/Unsupported attestation format during WebAuthn registration: android-key/,
    "Validation fails on unknown attestation format"
);

my $reg = $webauthn->validate_registration( %android_key_params,
    allow_unknown_attestation_format => 1 );

is(
    $reg->{credential_id},
    encode_base64url(
        pack( 'H*',
            '0a4729519788b6ed8a2d772b494e186244d8c798c052960dbc8c10c915176795' )
    ),
    "Expected credential ID"
);
is( $reg->{attestation_result}->{success},
    1, "Attestation validation successful" );
is( $reg->{attestation_result}->{type},
    "None", "None type used for unknown attestation format" );

done_testing();
