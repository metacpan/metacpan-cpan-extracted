package Authen::WebAuthn;
$Authen::WebAuthn::VERSION = '0.004';
use strict;
use warnings;
use Mouse;
use MIME::Base64 qw(encode_base64url decode_base64url);
use JSON qw(decode_json from_json to_json);
use Digest::SHA qw(sha256);
use Crypt::PK::ECC;
use Crypt::PK::RSA;
use Crypt::OpenSSL::X509 1.808;
use CBOR::XS;
use URI;
use Carp;
use Authen::WebAuthn::SSLeayChainVerifier;

has rp_id  => ( is => 'rw', required => 1 );
has origin => ( is => 'rw', required => 1 );

my $ATTESTATION_FUNCTIONS = {
    none       => \&attest_none,
    packed     => \&attest_packed,
    "fido-u2f" => \&attest_u2f,
};

my $KEY_TYPES = {
    ECC => {
        parse_pem     => \&parse_ecc_pem,
        parse_cose    => \&parse_ecc_cose,
        make_verifier => \&make_cryptx_verifier,
    },
    RSA => {
        parse_pem     => \&parse_rsa_pem,
        parse_cose    => \&parse_rsa_cose,
        make_verifier => \&make_cryptx_verifier,
    }
};

my $COSE_ALG = {
    -7 => {
        name              => "ES256",
        key_type          => "ECC",
        signature_options => ["SHA256"]
    },
    -257 => {
        name              => "RS256",
        key_type          => "RSA",
        signature_options => [ "SHA256", "v1.5" ]
    },
    -37 => {
        name              => "PS256",
        key_type          => "RSA",
        signature_options => [ "SHA256", "pss" ]
    },
    -65535 => {
        name              => "RS1",
        key_type          => "RSA",
        signature_options => [ "SHA1", "v1.5" ]
    }
};

sub validate_registration {
    my ( $self, %params ) = @_;

    my (
        $challenge_b64,             $requested_uv,
        $client_data_json_b64,      $attestation_object_b64,
        $token_binding_id_b64,      $trust_anchors,
        $allowed_attestation_types, $allow_untrusted_attestation,
      )
      = @params{ qw(
          challenge_b64        requested_uv
          client_data_json_b64 attestation_object_b64
          token_binding_id_b64 trust_anchors
          allowed_attestation_types allow_untrusted_attestation
        )
      };

    my $client_data_json = decode_base64url($client_data_json_b64);
    my $client_data      = eval { decode_json($client_data_json) };
    if ($@) {
        croak("Error deserializing client data: $@");
    }

    # 7. Verify that the value of C.type is webauthn.create
    unless ( $client_data->{type} eq "webauthn.create" ) {
        croak("Type is not webauthn.create");
    }

    # 8. Verify that the value of C.challenge equals the base64url encoding
    # of options.challenge.
    unless ($challenge_b64) {
        croak("Empty registration challenge");
    }

    unless ( $challenge_b64 eq $client_data->{challenge} ) {
        croak(  "Challenge received from client data "
              . "($client_data->{challenge}) "
              . "does not match server challenge "
              . "($challenge_b64)" );
    }

    # 9. Verify that the value of C.origin matches the Relying Party's origin.

    unless ( $client_data->{origin} ) {
        croak("Empty origin in client data");
    }

    unless ( $client_data->{origin} eq $self->origin ) {
        croak(  "Origin received from client data "
              . "($client_data->{origin}) "
              . "does not match server origin " . "("
              . $self->origin
              . ")" );
    }

    # 10. Verify that the value of C.tokenBinding.status matches the state of
    # Token Binding for the TLS connection over which the assertion was
    # obtained. If Token Binding was used on that TLS connection, also verify
    # that C.tokenBinding.id matches the base64url encoding of the Token
    # Binding ID for the connection.
    $self->check_token_binding( $client_data->{tokenBinding},
        $token_binding_id_b64 );

    # 11. Let hash be the result of computing a hash over
    # response.clientDataJSON using SHA-256.
    my $client_data_hash = sha256($client_data_json);

    # 12. Perform CBOR decoding on the attestationObject field of the
    # AuthenticatorAttestationResponse structure to obtain the attestation
    # statement format fmt, the authenticator data authData, and the
    # attestation statement attStmt.
    my $attestation_object = getAttestationObject($attestation_object_b64);
    my $authenticator_data = $attestation_object->{authData};

    unless ($authenticator_data) {
        croak("Authenticator data not found in attestation object");
    }

    unless ( $authenticator_data->{attestedCredentialData} ) {
        croak("Attested credential data not found in authenticator data");
    }

    # 13. Verify that the rpIdHash in authData is the SHA-256 hash of the RP ID
    # expected by the Relying Party.
    my $hash_rp_id = sha256( $self->rp_id );
    unless ( $authenticator_data->{rpIdHash} eq $hash_rp_id ) {
        croak(  "RP ID hash received from authenticator " . "("
              . unpack( "H*", $authenticator_data->{rpIdHash} ) . ") "
              . "does not match the hash of this RP ID " . "("
              . unpack( "H*", $hash_rp_id )
              . ")" );
    }

    # 14. Verify that the User Present bit of the flags in authData is set.
    unless ( $authenticator_data->{flags}->{userPresent} == 1 ) {
        croak("User not present during WebAuthn registration");
    }

    # 15. If user verification is required for this registration, verify that
    # the User Verified bit of the flags in authData is set.
    $requested_uv ||= "preferred";
    if (    $requested_uv eq "required"
        and $authenticator_data->{flags}->{userVerified} != 1 )
    {
        croak("User not verified during WebAuthn registration");
    }

    # 16. Verify that the "alg" parameter in the credential public key in
    # authData matches the alg attribute of one of the items in
    # options.pubKeyCredParams.
    # TODO For now, allow all known key types

    # 17. Verify that the values of the client extension outputs in
    # clientExtensionResults and the authenticator extension outputs in the
    # extensions in authData are as expected
    # TODO

    # 18. Determine the attestation statement format by performing a USASCII
    # case-sensitive match on fmt against the set of supported WebAuthn
    # Attestation Statement Format Identifier values.
    my $attestation_statement_format = $attestation_object->{'fmt'};
    my $attestation_function =
      $ATTESTATION_FUNCTIONS->{$attestation_statement_format};
    unless ( ref($attestation_function) eq "CODE" ) {
        croak( "Unsupported attestation format during WebAuthn registration: "
              . $attestation_statement_format );
    }

    # 19. Verify that attStmt is a correct attestation statement, conveying a
    # valid attestation signature, by using the attestation statement format
    # fmt’s verification procedure given attStmt, authData and hash.
    my $attestation_statement  = $attestation_object->{attStmt};
    my $authenticator_data_raw = $attestation_object->{authDataRaw};
    my $attestation_result     = eval {
        $attestation_function->(
            $attestation_statement,  $authenticator_data,
            $authenticator_data_raw, $client_data_hash
        );
    };
    croak( "Failed to validate attestation: " . $@ ) if ($@);

    unless ( $attestation_result->{success} == 1 ) {
        croak(
            "Failed to validate attestation: " . $attestation_result->{error} );
    }

    # 20. If validation is successful, obtain a list of acceptable trust
    # anchors (i.e. attestation root certificates) for that attestation type
    # and attestation statement format fmt, from a trusted source or from
    # policy.
    if ( defined($trust_anchors) and ref($trust_anchors) eq "SUB" ) {

        my $aaguid = $authenticator_data->{attestedCredentialData}->{aaguid};

        $trust_anchors = $trust_anchors->(
            aaguid             => $aaguid,
            attestation_type   => $attestation_result->{type},
            attestation_format => $attestation_statement_format,
        );

        if ( ref($trust_anchors) ne "ARRAY" ) {
            croak("trust_anchors sub must return an ARRAY reference");
        }
    }
    elsif ( defined($trust_anchors) and ref($trust_anchors) ne "ARRAY" ) {
        croak("trust_anchors parameter must be a SUB or ARRAY reference");
    }

    # 21. Assess the attestation trustworthiness using the outputs of the
    # verification procedure in step 19, as follows:
    $self->check_attestation_trust( $attestation_result, $trust_anchors,
        $allow_untrusted_attestation );
    $self->check_attestation_type( $allowed_attestation_types,
        $attestation_result->{type} );

    # 22. Check that the credentialId is not yet registered to any other user
    # TODO

    # 23. If the attestation statement attStmt verified successfully and is
    # found to be trustworthy, then register the new credential with the
    # account that was denoted in options.user:
    my $credential_id_bin =
      $authenticator_data->{attestedCredentialData}->{credentialId};
    my $credential_pubkey_cose =
      $authenticator_data->{attestedCredentialData}->{credentialPublicKey};
    my $signature_count = $authenticator_data->{signCount};
    return {
        credential_id      => encode_base64url($credential_id_bin),
        credential_pubkey  => encode_base64url($credential_pubkey_cose),
        signature_count    => $signature_count,
        attestation_result => $attestation_result
    };
}

sub validate_assertion {
    my ( $self, %params ) = @_;
    my (
        $challenge_b64,        $credential_pubkey_b64,
        $stored_sign_count,    $requested_uv,
        $client_data_json_b64, $authenticator_data_b64,
        $signature_b64,        $extension_results,
        $token_binding_id_b64,
      )
      = @params{
        qw(challenge_b64  credential_pubkey_b64
          stored_sign_count  requested_uv
          client_data_json_b64 authenticator_data_b64
          signature_b64 extension_results
          token_binding_id_b64)
      };

    # 7. Using credential.id (or credential.rawId, if base64url encoding is
    # inappropriate for your use case), look up the corresponding credential
    # public key and let credentialPublicKey be that credential public key.
    my $credential_verifier =
      eval { getPubKeyVerifier( decode_base64url($credential_pubkey_b64) ) };
    croak "Cannot get signature validator for assertion: $@" if ($@);

    # 8. Let cData, authData and sig denote the value of response’s
    # clientDataJSON, authenticatorData, and signature respectively.
    my $client_data_json       = decode_base64url($client_data_json_b64);
    my $authenticator_data_raw = decode_base64url($authenticator_data_b64);
    my $authenticator_data     = getAuthData($authenticator_data_raw);
    my $signature              = decode_base64url($signature_b64);

    # 9. Let JSONtext be the result of running UTF-8 decode on the value of
    # cData.
    # 10. Let C, the client data claimed as used for the signature, be the
    # result of running an implementation-specific JSON parser on JSONtext.
    my $client_data = eval { decode_json($client_data_json) };
    if ($@) {
        croak("Error deserializing client data: $@");
    }

    # 11. Verify that the value of C.type is the string webauthn.get.
    unless ( $client_data->{type} eq "webauthn.get" ) {
        croak("Type is not webauthn.get");
    }

    # 12. Verify that the value of C.challenge equals the base64url encoding of
    # options.challenge.
    unless ($challenge_b64) {
        croak("Empty registration challenge");
    }

    unless ( $challenge_b64 eq $client_data->{challenge} ) {
        croak(  "Challenge received from client data "
              . "($client_data->{challenge}) "
              . "does not match server challenge "
              . "($challenge_b64)" );
    }

    # 13. Verify that the value of C.origin matches the Relying Party's origin.
    unless ( $client_data->{origin} ) {
        croak("Empty origin");
    }

    unless ( $client_data->{origin} eq $self->origin ) {
        croak(  "Origin received from client data "
              . "($client_data->{origin}) "
              . "does not match server origin " . "("
              . $self->origin
              . ")" );
    }

    # 14. Verify that the value of C.tokenBinding.status matches the state of
    # Token Binding for the TLS connection over which the attestation was
    # obtained. If Token Binding was used on that TLS connection, also verify
    # that C.tokenBinding.id matches the base64url encoding of the Token
    # Binding ID for the connection.
    $self->check_token_binding( $client_data->{tokenBinding},
        $token_binding_id_b64 );

    # 15. Verify that the rpIdHash in authData is the SHA-256 hash of the RP ID
    # expected by the Relying Party.
    # If using the appid extension, this step needs some special logic. See
    # § 10.1 FIDO AppID Extension (appid) for details.

    my $hash_rp_id;
    if ( $extension_results->{appid} ) {
        $hash_rp_id = sha256( $self->origin );
    }
    else {
        $hash_rp_id = sha256( $self->rp_id );
    }

    unless ( $authenticator_data->{rpIdHash} eq $hash_rp_id ) {
        croak(  "RP ID hash received from authenticator " . "("
              . unpack( "H*", $authenticator_data->{rpIdHash} ) . ") "
              . "does not match the hash of this RP ID " . "("
              . unpack( "H*", $hash_rp_id )
              . ")" );
    }

    # 16. Verify that the User Present bit of the flags in authData is set.
    unless ( $authenticator_data->{flags}->{userPresent} == 1 ) {
        croak("User not present during WebAuthn authentication");
    }

    # 17. If user verification is required for this assertion, verify that the
    # User Verified bit of the flags in authData is set.
    $requested_uv ||= "preferred";
    if (    $requested_uv eq "required"
        and $authenticator_data->{flags}->{userVerified} != 1 )
    {
        croak("User not verified during WebAuthn authentication");
    }

    # 18. Verify that the values of the client extension outputs in
    # clientExtensionResults and the authenticator extension outputs in the
    # extensions in authData are as expected,
    # TODO

    # 19. Let hash be the result of computing a hash over the cData using
    # SHA-256.
    my $client_data_hash = sha256($client_data_json);

    # 20. Using credentialPublicKey, verify that sig is a valid signature over
    # the binary concatenation of authData and hash.
    my $to_sign = $authenticator_data_raw . $client_data_hash;

    unless ( $credential_verifier->( $signature, $to_sign ) ) {
        croak("Webauthn signature was not valid");
    }

    # 21. Let storedSignCount be the stored signature counter value associated
    # with credential.id. If authData.signCount is nonzero or storedSignCount
    # is nonzero, then run the following sub-step:
    $stored_sign_count //= 0;
    my $signature_count = $authenticator_data->{signCount};
    if ( $signature_count > 0 or $stored_sign_count > 0 ) {
        if ( $signature_count <= $stored_sign_count ) {
            croak(  "Stored signature count $stored_sign_count "
                  . "higher than device signature count $signature_count" );
        }
    }

    return { success => 1, signature_count => $signature_count, };
}

sub _ecc_obj_to_cose {
    my ($key) = @_;

    $key = $key->key2hash;
    unless ( $key->{curve_name} eq "secp256r1" ) {
        croak "Invalid ECC curve: " . $key->{curve_name};
    }

    # We want to be compatible with old CBOR::XS versions that don't have as_map
    # The correct code should be
    #return encode_cbor CBOR::XS::as_map [
    #    1  => 2,
    #    3  => -7,
    #    -1 => 1,
    #    -2 => pack( "H*", $key->{pub_x} ),
    #    -3 => pack( "H*", $key->{pub_y} ),
    #];

    # Manually encode the COSE key
    return "\xa5" .                                 #Map of 5 items
      "\x01\x02" .                                  # kty => EC2
      "\x03\x26" .                                  # alg => ES256
      "\x20\x01" .                                  # crv => P-256
      "\x21" .                                      # x =>
      "\x58\x20" . pack( "H*", $key->{pub_x} ) .    # x coordinate as a bstr
      "\x22" .                                      # y =>
      "\x58\x20" . pack( "H*", $key->{pub_y} )      # y coordinate as a bstr
      ;

}

# This function converts public keys from U2F format to COSE format. It can be useful
# for applications who want to migrate existing U2F registrations
sub convert_raw_ecc_to_cose {
    my ($raw_ecc_b64) = @_;

    my $key = Crypt::PK::ECC->new;
    $key->import_key_raw( decode_base64url($raw_ecc_b64), "secp256r1" );
    return encode_base64url( _ecc_obj_to_cose($key) );
}

# Check Token Binding in client data against Token Binding in incoming TLS
# connection. This only works if the web server supports it.
sub check_token_binding {
    my ( $self, $client_data_token_binding, $connection_tbid_b64 ) = @_;
    $connection_tbid_b64 //= "";

    # Token binding is not used
    if ( ref($client_data_token_binding) ne "HASH" ) {
        return;
    }

    my $token_binding_status = $client_data_token_binding->{status};

    if ( $token_binding_status eq "present" ) {
        my $client_data_cbid_b64 = $client_data_token_binding->{id};

        # Token binding is in use: the "id" field must be present and must
        # match the connection's Token Binding ID
        if ($client_data_cbid_b64) {
            if ( $client_data_cbid_b64 eq $connection_tbid_b64 ) {

                # All is well
                return;
            }
            else {
                croak "The Token Binding ID from the current connection "
                  . "($connection_tbid_b64) "
                  . "does not match Token Binding ID in client data "
                  . "($client_data_cbid_b64)";
            }

        }
        else {
            croak "Missing tokenBinding.id in client data "
              . "while tokenBinding.status == present";
        }

    }
    else {
        # Token binding "supported" but not used, or unknown/missing value
        return;
    }
}

sub check_attestation_type {
    my ( $self, $allowed_attestation_types, $attestation_type ) = @_;

    if ( ref($allowed_attestation_types) eq "ARRAY"
        and @$allowed_attestation_types )
    {
        if ( !grep { lc($_) eq lc($attestation_type) }
            @$allowed_attestation_types )
        {
            croak("Attestation type $attestation_type is not allowed");
        }
    }
}

sub check_attestation_trust {
    my ( $self, $attestation_result, $trust_anchors,
        $allow_untrusted_attestation )
      = @_;

    return 1 if $attestation_result->{type} eq "Self";
    return 1 if $attestation_result->{type} eq "None";

    #Otherwise, use the X.509 certificates returned as the attestation trust
    #path from the verification procedure to verify that the attestation public
    #key either correctly chains up to an acceptable root certificate, or is
    #itself an acceptable certificate (i.e., it and the root certificate
    #obtained in Step 20 may be the same).

    my $attn_cert = $attestation_result->{trust_path}->[0];
    unless ($attn_cert) {
        croak("Missing attestation certificate");
    }

    my @trust_chain = @{ $attestation_result->{trust_path} };
    shift @trust_chain;

    if ( $self->matchCertificateInList( $attn_cert, $trust_anchors ) ) {
        return 1;
    }

    my $verify_result =
      Authen::WebAuthn::SSLeayChainVerifier::verify_chain( $trust_anchors,
        $attn_cert, \@trust_chain );

    if ( $verify_result->{result} == 1 ) {
        return 1;
    }
    else {
        # If the attestation statement attStmt successfully verified but is not
        # trustworthy per step 21 above, the Relying Party SHOULD fail the
        # registration ceremony.
        if ( !$allow_untrusted_attestation ) {
            croak( "Could not validate attestation trust: "
                  . $verify_result->{message} );
        }
        else {
         # NOTE: However, if permitted by policy, the Relying Party MAY register
         # the credential ID and credential public key but treat the credential
         # as one with self attestation
         %$attestation_result = (
             success    => 1,
             type       => "Self",
             trust_path => [],
         );
         return 1;
     }
 }
}

# Try to find a DER-encoded certificate in a list of PEM-encoded certificates
sub matchCertificateInList {
    my ( $self, $attn_cert, $trust_anchors ) = @_;
    return if ref($trust_anchors) ne "ARRAY";

    for my $candidate (@$trust_anchors) {
        my $candidate_x509 = eval {
            Crypt::OpenSSL::X509->new_from_string( $candidate,
                Crypt::OpenSSL::X509::FORMAT_PEM );
        };
        next unless $candidate_x509;
        if ( $attn_cert eq
            $candidate_x509->as_string(Crypt::OpenSSL::X509::FORMAT_ASN1) )
        {
            return 1;
        }
    }
    return;
}

# Used by u2f assertion types
sub _getU2FKeyFromCose {
    my ($cose_key) = @_;
    $cose_key = decode_cbor($cose_key);

    # TODO: do we need to support more algs?
    croak( "Unexpected COSE Alg: " . $cose_key->{3} )
      unless ( $COSE_ALG->{ $cose_key->{3} }->{name} eq "ES256" );

    my $pk = parse_ecc_cose($cose_key);
    return $pk->export_key_raw('public');
}

sub parse_ecc_cose {
    my ($cose_struct) = @_;

    my $curve       = $cose_struct->{-1};
    my $x           = $cose_struct->{-2};
    my $y           = $cose_struct->{-3};
    my $id_to_curve = { 1 => 'secp256r1', };

    my $pk         = Crypt::PK::ECC->new();
    my $curve_name = $id_to_curve->{$curve};
    unless ($curve_name) {
        croak "Unsupported curve $curve";
    }

    $pk->import_key( {
            curve_name => $curve_name,
            pub_x      => unpack( "H*", $x ),
            pub_y      => unpack( "H*", $y ),
        }
    );
    return $pk;
}

# This generic method generates a two-argument signature method from
# the public key (RSA, ECC, etc.) and signature options from the COSE_ALG hash
sub make_cryptx_verifier {
    my ( $public_key, @signature_options ) = @_;

    return sub {
        my ( $signature, $message ) = @_;
        return $public_key->verify_message( $signature, $message,
            @signature_options );
    };
}

sub parse_ecc_pem {
    my ($pem) = @_;
    my $pk = Crypt::PK::ECC->new();
    $pk->import_key( \$pem );
    return $pk;
}

sub parse_rsa_pem {
    my ($pem) = @_;
    my $pk = Crypt::PK::RSA->new();
    $pk->import_key( \$pem );
    return $pk;
}

sub parse_rsa_cose {
    my ($cose_struct) = @_;
    my $n             = $cose_struct->{-1};
    my $e             = $cose_struct->{-2};

    my $pk = Crypt::PK::RSA->new();

    $pk->import_key( {
            N => unpack( "H*", $n ),
            e => unpack( "H*", $e ),
        }
    );

    return $pk;
}

# This function returns a verification method that is used like this:
# verifier->($signature, $message) returns 1 iff the message matches the
# signature
# Arguments are the COSE alg number from
# https://www.iana.org/assignments/cose/cose.xhtml#algorithms
# some key data, and the name of the function that converts the key data into a
# CryptX key (in KEY_TYPE array)
sub get_verifier_for_alg {
    my ( $alg_num, $key_data, $parse_method ) = @_;

    my $alg_config = $COSE_ALG->{$alg_num};
    unless ($alg_config) {
        croak "Unsupported algorithm $alg_num";
    }

    my $key_type        = $alg_config->{key_type};
    my $key_type_config = $KEY_TYPES->{$key_type};
    unless ($key_type_config) {
        croak "Unsupported key type $key_type";
    }

    # Get key conversion function
    my $key_function = $key_type_config->{$parse_method};
    unless ( ref($key_function) eq "CODE" ) {
        croak "No conversion method named $parse_method for key type $key_type";
    }

    # Get key
    my $public_key = $key_function->($key_data);
    unless ($public_key) {
        croak "Could not parse public key";
    }

    my @signature_options = @{ $alg_config->{signature_options} };
    return $key_type_config->{make_verifier}
      ->( $public_key, @signature_options );
}

# This function takes a Base64url encoded COSE key and returns a verification
# method

sub getPubKeyVerifier {
    my ($pubkey_cose) = @_;
    my $cose_key = decode_cbor($pubkey_cose);

    my $alg_num = $cose_key->{3};
    return get_verifier_for_alg( $alg_num, $cose_key, "parse_cose" );
}

# Same, but input is a PEM and a COSE alg name (used in assertion validation)
sub getPEMPubKeyVerifier {
    my ( $pem, $alg_num ) = @_;

    return get_verifier_for_alg( $alg_num, $pem, "parse_pem" );
}

sub getCoseAlgAndLength {
    my ($cbor_raw) = @_;

    my ( $cbor, $length ) = CBOR::XS->new->decode_prefix($cbor_raw);

    my $alg_num = $cbor->{3};
    my $alg     = $COSE_ALG->{$alg_num}->{name};

    if ($alg) {
        return ( $alg, $length );
    }
    else {
        croak "Unsupported algorithm $alg_num";
    }
}

# Transform binary AAGUID into string representation
sub formatAaguid {
    my ($aaguid) = @_;
    if ( length($aaguid) == 16 ) {
        return lc join "-",
          unpack( "H*", substr( $aaguid, 0,  4 ) ),
          unpack( "H*", substr( $aaguid, 4,  2 ) ),
          unpack( "H*", substr( $aaguid, 6,  2 ) ),
          unpack( "H*", substr( $aaguid, 8,  2 ) ),
          unpack( "H*", substr( $aaguid, 10, 6 ) ),
          ;
    }
    else {
        croak "Invalid AAGUID length";
    }
}

sub getAttestedCredentialData {
    my ($attestedCredentialData) = @_;

    check_length( $attestedCredentialData, "Attested credential data", 18 );

    my $res    = {};
    my $aaguid = formatAaguid( substr( $attestedCredentialData, 0, 16 ) );
    $res->{aaguid} = $aaguid;
    $res->{credentialIdLength} =
      unpack( 'n', substr( $attestedCredentialData, 16, 2 ) );
    $res->{credentialId} =
      substr( $attestedCredentialData, 18, $res->{credentialIdLength} );
    my ( $cose_alg, $length_cbor_pubkey ) = getCoseAlgAndLength(
        substr( $attestedCredentialData, 18 + $res->{credentialIdLength} ) );

    $res->{credentialPublicKeyAlg} = $cose_alg;
    $res->{credentialPublicKey} =
      substr( $attestedCredentialData, 18 + $res->{credentialIdLength},
        $length_cbor_pubkey );
    $res->{credentialPublicKeyLength} = $length_cbor_pubkey;
    return $res;
}

sub check_length {
    my ( $data, $name, $expected_len ) = @_;

    my $len = length($data);
    if ( $len < $expected_len ) {
        croak("$name has incorrect length $len (min: $expected_len)");
    }
}

sub getAuthData {
    my ($ad) = @_;
    my $res = {};

    check_length( $ad, "Authenticator data", 37 );

    $res->{rpIdHash}  = substr( $ad, 0, 32 );
    $res->{flags}     = resolveFlags( unpack( 'C', substr( $ad, 32, 1 ) ) );
    $res->{signCount} = unpack( 'N', substr( $ad, 33, 4 ) );

    my $attestedCredentialDataLength = 0;
    if ( $res->{flags}->{atIncluded} ) {
        my $attestedCredentialData =
          getAttestedCredentialData( substr( $ad, 37 ) );
        $res->{attestedCredentialData} = $attestedCredentialData;
        $attestedCredentialDataLength =
          18 + $attestedCredentialData->{credentialIdLength} +
          $attestedCredentialData->{credentialPublicKeyLength};
    }

    if ( $res->{flags}->{edIncluded} ) {
        my $ext = substr( $ad, 37 + $attestedCredentialDataLength );

        if ($ext) {
            $res->{extensions} = decode_cbor($ext);
        }
    }
    else {
        # Check for trailing bytes
        croak("Trailing bytes in authenticator data")
          if ( length($ad) > ( 37 + $attestedCredentialDataLength ) );
    }

    return $res;
}

sub resolveFlags {
    my ($bits) = @_;
    return {
        userPresent  => ( ( $bits & 1 ) == 1 ),
        userVerified => ( ( $bits & 4 ) == 4 ),
        atIncluded   => ( ( $bits & 64 ) == 64 ),
        edIncluded   => ( ( $bits & 128 ) == 128 ),
    };
}

sub getAttestationObject {
    my ($dat)   = @_;
    my $decoded = decode_base64url($dat);
    my $res     = {};
    my $h       = decode_cbor($decoded);
    $res->{authData}    = getAuthData( $h->{authData} );
    $res->{authDataRaw} = $h->{authData};
    $res->{attStmt}     = $h->{attStmt};
    $res->{fmt}         = $h->{fmt};
    return $res;
}

# https://www.w3.org/TR/webauthn-2/#sctn-none-attestation
sub attest_none {
    my (
        $attestation_statement,  $auhenticator_data,
        $authenticator_data_raw, $client_data_hash
    ) = @_;
    return {
        success    => 1,
        type       => "None",
        trust_path => [],
    };

}

# https://www.w3.org/TR/webauthn-2/#sctn-packed-attestation
sub attest_packed {
    my (
        $attestation_statement,  $authenticator_data,
        $authenticator_data_raw, $client_data_hash
    ) = @_;

    # Verify that attStmt is valid CBOR conforming to the syntax defined above
    # and perform CBOR decoding on it to extract the contained fields.
    croak "Missing algorithm field in attestation statement"
      unless ( $attestation_statement->{alg} );

    croak "Missing signature field in attestation statement"
      unless ( $attestation_statement->{sig} );

    my $signed_value = $authenticator_data_raw . $client_data_hash;

    #If x5c is present:
    if ( $attestation_statement->{x5c} ) {
        return attest_packed_x5c( $attestation_statement, $authenticator_data,
            $signed_value );

        #If x5c is not present, self attestation is in use.
    }
    else {
        return attest_packed_self( $attestation_statement, $authenticator_data,
            $signed_value );
    }
}

sub attest_packed_x5c {
    my ( $attestation_statement, $authenticator_data, $signed_value ) = @_;

    my $x5c_der = $attestation_statement->{x5c}->[0];
    my $sig_alg = $attestation_statement->{alg};
    my $sig     = $attestation_statement->{sig};

    my ( $x5c, $key, $key_alg );
    eval {
        $x5c = Crypt::OpenSSL::X509->new_from_string( $x5c_der,
            Crypt::OpenSSL::X509::FORMAT_ASN1 );
        $key = $x5c->pubkey();
    };

    croak "Cannot extract public key from attestation certificate: $@" if ($@);

    # Verify that sig is a valid signature over the concatenation of
    # authenticatorData and clientDataHash using the attestation public key in
    # attestnCert with the algorithm specified in alg.
    my $attestation_verifier = eval { getPEMPubKeyVerifier( $key, $sig_alg ) };
    croak "Cannot get signature validator for attestation: $@" if ($@);

    # Verify that attestnCert meets the requirements in § 8.2.1 Packed
    # Attestation Statement Certificate Requirements.
    eval { attest_packed_check_cert_requirements($x5c) };
    croak "Attestation certificate does not satisfy requirements: $@" if ($@);

    # If attestnCert contains an extension with OID 1.3.6.1.4.1.45724.1.1.4
    # (id-fido-gen-ce-aaguid) verify that the value of this extension matches
    # the aaguid in authenticatorData.
    my $aaguid_ext = $x5c->extensions_by_oid->{'1.3.6.1.4.1.45724.1.1.4'};
    if ($aaguid_ext) {
        my $ad_aaguid = $authenticator_data->{attestedCredentialData}->{aaguid};
        my $cert_aaguid = $aaguid_ext->value;
        croak "Invalid id-fido-gen-ce-aaguid extension format"
          unless $cert_aaguid =~ /^#0410.{32}$/;

        # Reformat aaguids so they can be compared
        ($cert_aaguid) = $cert_aaguid =~ /^#0410(.{32})$/;
        $ad_aaguid =~ s/-//g;
        $ad_aaguid = uc($ad_aaguid);

        croak "AAGUID from certificate ($cert_aaguid)"
          . " does not match AAGUID from authenticator data ($ad_aaguid)"
          if $ad_aaguid ne $cert_aaguid;
    }

    # Optionally, inspect x5c and consult externally provided knowledge to
    # determine whether attStmt conveys a Basic or AttCA attestation.
    # TODO

    # If successful, return implementation-specific values representing
    # attestation type Basic, AttCA or uncertainty, and attestation trust path
    # x5c.
    if ( $attestation_verifier->( $sig, $signed_value ) ) {
        return {
            success    => 1,
            type       => "Basic",
            trust_path => $attestation_statement->{x5c},
            aaguid => $authenticator_data->{attestedCredentialData}->{aaguid},
        };
    }
    else {
        croak "Invalid attestation signature";
    }
}

# Implements 8.2.1. Packed Attestation Statement Certificate Requirements
sub attest_packed_check_cert_requirements {
    my ($x5c) = @_;

    my $version = $x5c->version;

    # Version MUST be set to 3
    # (which is indicated by an ASN.1 INTEGER with value 2).
    croak "Invalid certificate version" unless $version eq "02";

    # Subject field
    croak "Missing subject C" unless $x5c->subject_name->get_entry_by_type("C");
    croak "Missing subject O" unless $x5c->subject_name->get_entry_by_type("O");
    croak "Missing subject CN"
      unless $x5c->subject_name->get_entry_by_type("CN");
    croak "Missing subject OU"
      unless $x5c->subject_name->get_entry_by_type("OU");
    croak "Unexpected OU"
      unless $x5c->subject_name->get_entry_by_type("OU")->value eq
      "Authenticator Attestation";

    # The Basic Constraints extension MUST have the CA component set to false.
    my $isCa = $x5c->extensions_by_oid->{"2.5.29.19"}->basicC("ca");
    croak "Basic Constraints CA is true" if $isCa;

    return;
}

sub attest_packed_self {
    my ( $attestation_statement, $authenticator_data, $signed_value ) = @_;

    my $sig          = $attestation_statement->{sig};
    my $sign_alg_num = $attestation_statement->{alg};
    my $cose_key =
      $authenticator_data->{attestedCredentialData}->{credentialPublicKey};

    # Validate that alg matches the algorithm of the credentialPublicKey in
    # authenticatorData.
    my $cose_alg =
      $authenticator_data->{attestedCredentialData}->{credentialPublicKeyAlg};
    my $sign_alg = $COSE_ALG->{$sign_alg_num}->{name};
    croak "Unknown key type in attestation data: $sign_alg_num"
      unless ($sign_alg);

    unless ( $sign_alg eq $cose_alg ) {
        croak "Attestation algorithm $sign_alg does not match "
          . "credential key type $cose_alg";
    }

    # Verify that sig is a valid signature over the concatenation of
    # authenticatorData and clientDataHash using the credential public key with
    # alg.
    my $credential_verifier = eval { getPubKeyVerifier($cose_key) };
    croak "Cannot get signature validator for attestation: $@" if ($@);

    # If successful, return implementation-specific values representing
    # attestation type Self and an empty attestation trust path.
    if ( $credential_verifier->( $sig, $signed_value ) ) {
        return {
            success    => 1,
            type       => "Self",
            trust_path => [],
        };
    }
    else {
        croak "Invalid attestation signature";
    }
}

# https://www.w3.org/TR/webauthn-2/#sctn-fido-u2f-attestation
sub attest_u2f {
    my (
        $attestation_statement,  $authenticator_data,
        $authenticator_data_raw, $client_data_hash
    ) = @_;

   # 1. Verify that attStmt is valid CBOR conforming to the syntax defined above
   # and perform CBOR decoding on it to extract the contained fields.
    croak "Missing signature field in attestation statement"
      unless ( $attestation_statement->{sig} );

    my $sig = $attestation_statement->{sig};

    # 2. Check that x5c has exactly one element and let attCert be that
    # element. Let certificate public key be the public key conveyed by
    # attCert. If certificate public key is not an Elliptic Curve (EC) public
    # key over the P-256 curve, terminate this algorithm and return an
    # appropriate error.
    unless ($attestation_statement->{x5c}
        and ref( $attestation_statement->{x5c} ) eq "ARRAY"
        and $attestation_statement->{x5c}->[0] )
    {
        croak "Missing certificate field in attestation statement";
    }

    my $x5c_der         = $attestation_statement->{x5c}->[0];
    my $attestation_key = Crypt::PK::ECC->new();
    eval {
        my $x5c = Crypt::OpenSSL::X509->new_from_string( $x5c_der,
            Crypt::OpenSSL::X509::FORMAT_ASN1 );
        my $key_pem = $x5c->pubkey();
        $attestation_key->import_key( \$key_pem );
    };
    croak "Could not extract ECC key from attestation certificate: $@" if ($@);

    if ( $attestation_key->key2hash->{curve_name} ne "secp256r1" ) {
        croak "Invalid attestation certificate curve name: "
          . $attestation_key->key2hash->{curve_name};
    }

    # 3. Extract the claimed rpIdHash from authenticatorData, and the claimed
    # credentialId and credentialPublicKey from
    # authenticatorData.attestedCredentialData.
    my $rp_id_hash = $authenticator_data->{rpIdHash};
    my $credential_id =
      $authenticator_data->{attestedCredentialData}->{credentialId};
    my $credential_public_key =
      $authenticator_data->{attestedCredentialData}->{credentialPublicKey};

    # 4.Convert the COSE_KEY formatted credentialPublicKey (see Section 7 of
    # [RFC8152]) to Raw ANSI X9.62 public key format
    my $public_u2f_key = eval { _getU2FKeyFromCose($credential_public_key) };
    croak "Could not convert attested credential to U2F key: $@" if ($@);

    # 5.Let verificationData be the concatenation of (0x00 || rpIdHash ||
    # clientDataHash || credentialId || publicKeyU2F)
    my $verification_data = "\x00"
      . $rp_id_hash
      . $client_data_hash
      . $credential_id
      . $public_u2f_key;

    if (
        $attestation_key->verify_message( $sig, $verification_data, "SHA256" ) )
    {
        return {
            success    => 1,
            type       => "Basic",
            trust_path => $attestation_statement->{x5c},
        };
    }
    else {
        croak "Signature verification failed";
    }
}

1;
