package Catalyst::Plugin::OpenIDConnect::Utils::JWT;

use strict;
use warnings;
use Moose;
use namespace::autoclean;

use JSON::MaybeXS qw(encode_json decode_json);
use MIME::Base64 qw(encode_base64 decode_base64);
use Digest::SHA qw(sha256);
use Crypt::OpenSSL::RSA;
use DateTime;
use Try::Tiny;

=head1 NAME

Catalyst::Plugin::OpenIDConnect::Utils::JWT - JWT handling for OpenID Connect

=head1 DESCRIPTION

Provides JWT signing and verification functionality using RS256 (RSA SHA-256) algorithm
for OpenID Connect token creation and validation.

=head1 ATTRIBUTES

=head2 private_key

The RSA private key for signing tokens.

=cut

has private_key => (
    is       => 'ro',
    isa      => 'Crypt::OpenSSL::RSA',
    required => 1,
);

=head2 public_key

The RSA public key for verifying tokens.

=cut

has public_key => (
    is       => 'ro',
    isa      => 'Crypt::OpenSSL::RSA',
    required => 1,
);

=head2 key_id

The key ID (kid) used in JWT headers.

=cut

has key_id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 issuer

The issuer URL/identifier for the iss claim.

=cut

has issuer => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 logger

Optional logger instance for debug/info logging.

=cut

has logger => (
    is       => 'ro',
    isa      => 'Maybe[Object]',
    required => 0,
);

=head1 METHODS

=head2 sign_token(%payload)

Signs a JWT token with the configured private key using RS256 algorithm.

Returns the complete JWT (header.payload.signature).

=cut

sub sign_token {
    my ( $self, %payload ) = @_;

    $self->logger->debug('Signing JWT token') if $self->logger;

    # Set standard claims
    $payload{iss} = $self->issuer unless defined $payload{iss};
    $payload{iat} = time() unless defined $payload{iat};

    # Log only non-sensitive metadata — never log PII-bearing claims (MED-2).
    if ( $self->logger ) {
        $self->logger->debug( sprintf(
            'Signing JWT: sub=%s aud=%s exp=%s',
            $payload{sub} // '?', $payload{aud} // '?', $payload{exp} // '?',
        ));
    }

    # Prep header
    my %header = (
        alg => 'RS256',
        typ => 'JWT',
        kid => $self->key_id,
    );

    # Encode header and payload
    my $header_json   = encode_json( \%header );

    # Perl's JSON serialiser encodes a scalar as a JSON string if the SvPOK
    # (string) flag is set, even when the value is also numeric.  Reading a
    # number through a string context — e.g. the sprintf() debug statement
    # above — sets that flag.  Explicitly numify all timestamp claims with
    # int() to clear SvPOK before serialisation so they are always encoded
    # as JSON integers (e.g. 1746000000, not "1746000000").  Python's authlib and
    # other compliant RPs reject string-typed exp/iat/nbf values.
    $payload{$_} = int( $payload{$_} )
        for grep { defined $payload{$_} } qw(exp iat nbf);

    my $payload_json  = encode_json( \%payload );

    my $header_b64   = _urlsafe_b64_encode($header_json);
    my $payload_b64  = _urlsafe_b64_encode($payload_json);

    # Create signature (explicitly use SHA256 for RS256)
    my $signing_input = "$header_b64.$payload_b64";
    my $priv_key = $self->private_key;
    # Ensure consistent RSA configuration for signing (RFC 3447 PKCS1v15)
    $priv_key->use_pkcs1_padding();
    $priv_key->use_sha256_hash();
    my $signature = $priv_key->sign($signing_input);
    my $signature_b64 = _urlsafe_b64_encode($signature);

    my $token = "$signing_input.$signature_b64";
    
    if ( $self->logger ) {
        $self->logger->debug( sprintf(
            'JWT signed: header_b64_len=%d, payload_b64_len=%d, sig_b64_len=%d, total_len=%d',
            length($header_b64), length($payload_b64), length($signature_b64), length($token),
        ));
        $self->logger->debug("JWT token (first 80 chars): " . substr($token, 0, 80) . "...");
    }
    
    return $token;
}

=head2 verify_token($token, %opts)

Verifies a JWT token with the configured public key.

Mandatory claims C<exp> and C<iss> are always validated.  The C<nbf>
claim is validated when present.  Pass C<expected_audience> to also
validate the C<aud> claim:

  $jwt->verify_token($token, expected_audience => 'my-client-id');

Returns a hashref with decoded claims on success.
Raises an exception on verification failure.

=cut

sub verify_token {
    my ( $self, $token, %opts ) = @_;
    my $expected_audience = $opts{expected_audience};

    $self->logger->debug('Verifying JWT token') if $self->logger;

    return try {
        my @parts = split /\./, $token;
        die 'Invalid JWT format' unless @parts == 3;

        my ( $header_b64, $payload_b64, $signature_b64 ) = @parts;

        $self->logger->debug('JWT format validated (3 parts)') if $self->logger;

        # Verify signature (explicitly use SHA256 for RS256)
        my $signing_input = "$header_b64.$payload_b64";
        my $signature = _urlsafe_b64_decode($signature_b64);

        my $pub_key = $self->public_key;
        # Ensure consistent RSA configuration for verification (RFC 3447 PKCS1v15)
        $pub_key->use_pkcs1_padding();
        $pub_key->use_sha256_hash();
        die 'Invalid signature' unless $pub_key->verify(
            $signing_input,
            $signature
        );

        $self->logger->debug('JWT signature verified') if $self->logger;

        # Decode payload
        my $payload_json = _urlsafe_b64_decode($payload_b64);
        my $payload = decode_json($payload_json);

        $self->logger->debug('JWT payload decoded successfully') if $self->logger;

        # --- Mandatory claim validation (RFC 7519 §4.1, OIDC Core §2) ---
        # exp and iss must be present and valid; a token that omits them
        # must be rejected regardless of its signature.
        die 'Missing exp claim' unless defined $payload->{exp};
        die 'Token expired'     if $payload->{exp} < time();
        die 'Missing iss claim' unless defined $payload->{iss};
        die 'Invalid issuer'    unless $payload->{iss} eq $self->issuer;

        # nbf (not-before) is optional but must be honoured when present
        die 'Token not yet valid'
            if defined $payload->{nbf} && $payload->{nbf} > time();

        # aud — validated when the caller supplies an expected value
        if ( defined $expected_audience ) {
            die 'Missing aud claim' unless defined $payload->{aud};
            die 'Invalid audience'  unless $payload->{aud} eq $expected_audience;
        }

        $self->logger->debug('JWT claims validated') if $self->logger;

        return $payload;
    }
    catch {
        $self->logger->warn("Token verification failed: $_") if $self->logger;
        die "Token verification failed: $_";
    };
}

=head2 create_id_token(%claims)

Creates a signed ID token with the specified claims.

The following claims are automatically set if not provided:
- exp: Expiration time (1 hour from now, required by OIDC/JWT spec)
- iat: Issued at time (current time)
- iss: Issuer URL

=cut

sub create_id_token {
    my ( $self, %claims ) = @_;

    # Ensure exp is set - this is MANDATORY per RFC 7519 and OIDC spec
    # If not provided, default to 1 hour from now
    unless ( defined $claims{exp} ) {
        $claims{exp} = time() + 3600;
    }

    my %payload = (
        typ => 'JWT',
        %claims,
    );

    return $self->sign_token(%payload);
}

=head2 create_access_token(%claims)

Creates a signed access token with the specified claims.

The exp (expiration) claim is mandatory and will be set to 1 hour from now
if not explicitly provided.

=cut

sub create_access_token {
    my ( $self, %claims ) = @_;

    # Ensure exp is set - this is MANDATORY per RFC 7519
    unless ( defined $claims{exp} ) {
        $claims{exp} = time() + 3600;
    }

    return $self->sign_token(%claims);
}

=head2 create_refresh_token(%claims)

Creates a signed refresh token with the specified claims.

The exp (expiration) claim is mandatory and will be set to 30 days from now
if not explicitly provided.

=cut

sub create_refresh_token {
    my ( $self, %claims ) = @_;

    # Ensure exp is set - this is MANDATORY per RFC 7519
    # Refresh tokens have a longer lifetime (30 days)
    unless ( defined $claims{exp} ) {
        $claims{exp} = time() + (30 * 24 * 3600);
    }

    return $self->sign_token(%claims);
}

=head2 decode_id_token_hint($token)

Decodes a JWT passed as an C<id_token_hint> during logout.

Verifies the token signature against the configured public key to confirm
it was genuinely issued by this server, but deliberately skips expiry
validation; hint tokens are frequently expired at logout time by design.

Returns a hashref of the token's claims on success, or C<undef> if the
token is malformed or the signature cannot be verified.

=cut

sub decode_id_token_hint {
    my ( $self, $token ) = @_;

    return try {
        my @parts = split /\./, $token;
        return undef unless @parts == 3;

        my ( $header_b64, $payload_b64, $signature_b64 ) = @parts;

        # Verify signature — ensures the token was genuinely issued by us
        # and was not crafted by an attacker to spoof a client_id.
        my $signing_input = "$header_b64.$payload_b64";
        my $signature     = _urlsafe_b64_decode($signature_b64);
        my $pub_key       = $self->public_key;
        # Ensure consistent RSA configuration for verification (RFC 3447 PKCS1v15)
        $pub_key->use_pkcs1_padding();
        $pub_key->use_sha256_hash();
        return undef unless $pub_key->verify( $signing_input, $signature );

        my $payload_json = _urlsafe_b64_decode($payload_b64);
        return decode_json($payload_json);
    }
    catch {
        $self->logger->warn("id_token_hint decode failed: $_") if $self->logger;
        return undef;
    };
}

# Helper: URL-safe base64 encode (RFC 4648 Section 5)
sub _urlsafe_b64_encode {
    my ($data) = @_;
    my $b64 = encode_base64($data, '');
    $b64 =~ tr|+/|-_|;
    $b64 =~ s/=+$//;
    return $b64;
}

# Helper: URL-safe base64 decode (RFC 4648 Section 5)
sub _urlsafe_b64_decode {
    my ($data) = @_;
    $data =~ tr|-_|+/|;
    my $padding = length($data) % 4;
    $data .= '=' x ( 4 - $padding ) if $padding;
    return decode_base64($data);
}

__PACKAGE__->meta->make_immutable;
1;

=head1 AUTHOR

Tim F. Rayner

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of The Artistic License 2.0.

=cut
