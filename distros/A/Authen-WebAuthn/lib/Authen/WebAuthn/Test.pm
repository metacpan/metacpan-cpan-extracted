package Authen::WebAuthn::Test;
$Authen::WebAuthn::Test::VERSION = '0.004';
use Mouse;
use CBOR::XS;
use MIME::Base64 qw(encode_base64url decode_base64url);
use Digest::SHA qw(sha256);
use Crypt::PK::ECC;
use Hash::Merge::Simple qw/merge/;
use JSON qw(encode_json decode_json);
use Authen::WebAuthn;
use utf8;

has origin => ( is => 'rw' );
has rp_id  => ( is => 'rw', lazy => 1, default => sub { $_[0]->origin } );
has credential_id => ( is => 'rw' );
has aaguid        => ( is => 'rw' );
has key           => ( is => 'rw' );
has sign_count    => ( is => 'rw', default => 0 );

use constant {
    FLAG_UP => 1,
    FLAG_UV => 4,
    FLAG_AT => 64,
    FLAG_ED => 128,
};

sub makeAttestedCredentialData {
    my ($acd) = @_;
    return '' unless ($acd);

    my $aaguid              = exportAaguid( $acd->{aaguid} );
    my $credentialIdLength  = pack( 'n', length( $acd->{credentialId} ) );
    my $credentialId        = $acd->{credentialId};
    my $credentialPublicKey = $acd->{credentialPublicKey};
    my $attestedCredentialData =
      ( $aaguid . $credentialIdLength . $credentialId . $credentialPublicKey );

    return $attestedCredentialData;
}

sub makeAuthData {
    my ($authdata) = @_;

    my $rpIdHash  = $authdata->{rpIdHash};
    my $flags     = pack( 'C', makeFlags( $authdata->{flags} ) );
    my $signCount = pack( 'N', $authdata->{signCount} );
    my $acd = makeAttestedCredentialData( $authdata->{attestedCredentialData} );
    my $ed =
      $authdata->{extensions} ? encode_cbor( $authdata->{extensions} ) : '';
    my $res = $rpIdHash . $flags . $signCount . $acd . $ed;

    return $res;
}

sub makeAttestationObject {
    my ($dat) = @_;

    my $attestationObject = {
        'fmt'      => $dat->{fmt},
        'authData' => makeAuthData( $dat->{authData} ),
        'attStmt'  => {}                                  # TODO
    };

    my $cbor = CBOR::XS->new;
    $cbor->text_keys(1);
    return $cbor->encode($attestationObject);
}

sub makeFlags {
    my ($flags) = @_;
    my $up = $flags->{userPresent}  ? 1 : 0;
    my $uv = $flags->{userVerified} ? 1 : 0;
    my $at = $flags->{atIncluded}   ? 1 : 0;
    my $ed = $flags->{edIncluded}   ? 1 : 0;
    return ( FLAG_UP * $up + FLAG_UV * $uv + FLAG_AT * $at + FLAG_ED * $ed );
}

# Transform string GUID into binary
sub exportAaguid {
    my ($aaguid) = @_;
    $aaguid =~ s/-//g;

    if ( length($aaguid) == 32 ) {
        return pack( 'H*', $aaguid );
    }
    else {
        die "Invalid AAGUID length";
    }
}

sub encode_credential {
    my ( $self, $credential ) = @_;

    # Encode clientDataJSON
    if ( $credential->{response}->{clientDataJSON} ) {
        $credential->{response}->{clientDataJSON} =
          encode_base64url( $credential->{response}->{clientDataJSON} );
    }

    # Encode attestationObject
    if ( $credential->{response}->{attestationObject} ) {
        $credential->{response}->{attestationObject} =
          encode_base64url( $credential->{response}->{attestationObject} );
    }

    # Encode authenticatorData
    if ( $credential->{response}->{authenticatorData} ) {
        $credential->{response}->{authenticatorData} =
          encode_base64url( $credential->{response}->{authenticatorData} );
    }

    # Encode signature
    if ( $credential->{response}->{signature} ) {
        $credential->{response}->{signature} =
          encode_base64url( $credential->{response}->{signature} );
    }

    # Encode rawId
    if ( $credential->{rawId} ) {
        $credential->{rawId} = encode_base64url( $credential->{rawId} );
    }

    return JSON->new->utf8->pretty->encode($credential);
}

sub encode_cosekey {

    my ($self) = @_;

    my $key_str = $self->key;
    my $key     = Crypt::PK::ECC->new( \$key_str );

    return Authen::WebAuthn::_ecc_obj_to_cose($key);
}

sub sign {
    my ( $self, $message ) = @_;
    my $key_str = $self->key;
    my $key     = Crypt::PK::ECC->new( \$key_str );

    return $key->sign_message( $message, 'SHA256' );
}

sub get_credential_response {
    my ( $self, $input, $override ) = @_;

    my $challenge = $input->{request}->{challenge};
    my $uv = $input->{request}->{authenticatorSelection}->{userVerification}
      || "preferred";

    # Everything is build from this array, you can override it for testing
    # various scenarios
    my $credential = merge {
        response => {
            type           => "public-key",
            rawId          => $self->credential_id,
            id             => encode_base64url( $self->credential_id ),
            clientDataJSON => {
                type        => "webauthn.create",
                challenge   => "$challenge",
                origin      => $self->origin,
                crossOrigin => JSON::false,
            },
            attestationObject => {
                'fmt'      => 'none',
                'authData' => {
                    rpIdHash => sha256( $self->rp_id ),
                    flags    => {
                        userPresent => 1,
                        ( $uv eq "required" ? ( userVerified => 1 ) : () ),
                        atIncluded => 1,
                    },
                    signCount              => $self->sign_count,
                    attestedCredentialData => {
                        aaguid              => $self->aaguid,
                        credentialId        => $self->credential_id,
                        credentialPublicKey => $self->encode_cosekey,
                    },
                },
                'attStmt' => {}
            }
        }
    }, $override;

    $credential->{response}->{clientDataJSON} =
      encode_json $credential->{response}->{clientDataJSON};
    $credential->{response}->{attestationObject} =
      makeAttestationObject $credential->{response}->{attestationObject};

    return $credential;
}

sub get_assertion_response {
    my ( $self, $input, $override ) = @_;

    my $challenge = $input->{request}->{challenge};
    my $uv        = $input->{request}->{userVerification} || "preferred";

    # Everything is build from this array, you can override it for testing
    # various scenarios
    my $credential = merge {
        type     => "public-key",
        rawId    => $self->credential_id,
        id       => encode_base64url( $self->credential_id ),
        response => {
            clientDataJSON => {
                type        => "webauthn.get",
                challenge   => "$challenge",
                origin      => $self->origin,
                crossOrigin => JSON::false,
            },
            authenticatorData => {
                rpIdHash => sha256( $self->rp_id ),
                flags    => {
                    userPresent => 1,
                    ( $uv eq "required" ? ( userVerified => 1 ) : () ),
                },
                signCount => $self->sign_count,
            },
            userHandle => "",    #TODO
        }
    }, $override;

    my $clientData = {
        type        => "webauthn.get",
        challenge   => "$challenge",
        origin      => $self->origin,
        crossOrigin => JSON::false,
    };
    $credential->{response}->{clientDataJSON} =
      encode_json $credential->{response}->{clientDataJSON};
    $credential->{response}->{authenticatorData} =
      makeAuthData $credential->{response}->{authenticatorData};

    my $hash      = sha256( $credential->{response}->{clientDataJSON} );
    my $authData  = $credential->{response}->{authenticatorData};
    my $signature = $self->sign( $authData . $hash );

    # Add signature to hash unless we have overriden it
    unless ( $credential->{response}->{signature} ) {
        $credential->{response}->{signature} = $signature;
    }

    return $credential;
}

1;

