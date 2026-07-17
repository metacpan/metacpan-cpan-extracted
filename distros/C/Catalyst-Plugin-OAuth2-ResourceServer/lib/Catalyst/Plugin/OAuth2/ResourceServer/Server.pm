package Catalyst::Plugin::OAuth2::ResourceServer::Server;
use v5.36;
use Moo;
use Carp ();
use Try::Tiny;
use Crypt::JWT qw/decode_jwt/;
use Catalyst::Plugin::OAuth2::ResourceServer::Error;

our $VERSION = '0.003';

has signing_key => ( is => 'ro', required => 1 );
has resource    => ( is => 'ro', required => 1 );
has issuer      => ( is => 'ro', required => 1 );
has jwt_alg     => ( is => 'ro', default => 'HS256' );
has leeway      => ( is => 'ro', default => 0 );

use namespace::clean;
use MooX::StrictConstructor;

sub BUILD ( $self, $args ) {
    Carp::croak 'resource must be a non-empty scalar or arrayref'
        unless @{ $self->_resource_list };
    state %ALLOWED_ALG = map { $_ => 1 } qw/HS256 HS384 HS512/;
    Carp::croak 'jwt_alg must be one of HS256, HS384, HS512'
        unless $ALLOWED_ALG{ $self->jwt_alg };
    state %MIN_KEY_BYTES = ( HS256 => 32, HS384 => 48, HS512 => 64 );
    Carp::croak sprintf(
        'signing_key must be at least %d bytes for %s',
        $MIN_KEY_BYTES{ $self->jwt_alg }, $self->jwt_alg )
        if length( $self->signing_key ) < $MIN_KEY_BYTES{ $self->jwt_alg };
}

# resource may be a scalar or arrayref; normalise to a list.
sub _resource_list ( $self ) {
    my $r = $self->resource;
    return ref $r eq 'ARRAY' ? [ @$r ] : defined $r && length $r ? [$r] : [];
}

sub _invalid ( $self, $desc ) {
    Catalyst::Plugin::OAuth2::ResourceServer::Error->throw(
        error             => 'invalid_token',
        error_description => $desc,
        http_status       => 401,
    );
}

# Verify a bearer JWT: signature + alg allowlist + exp/nbf/iat (with leeway) +
# iss, then an explicit aud-membership check against our own resource(s).
# Returns the claims, or throws a 401 invalid_token (reason never leaked).
#
# Crypt::JWT verify_* semantics (see its POD): 1 = claim REQUIRED and valid,
# undef = "validate only if present". exp is required (a token with no expiry
# is never acceptable here). nbf and iat are optional per RFC 7519 4.1.5/4.1.6
# and the companion AuthorizationServer mints no nbf at all, so both are
# validate-if-present: requiring them would reject legitimate tokens. Note
# verify_iat is asymmetric in Crypt::JWT -- omitting the key entirely disables
# the iat check completely, so it must be passed explicitly as undef.
sub verify_token ( $self, $jwt ) {
    my $claims = try {
        decode_jwt(
            token        => $jwt,
            key          => $self->signing_key,
            accepted_alg => [ $self->jwt_alg ],
            verify_exp   => 1,
            verify_nbf   => undef,
            verify_iat   => undef,
            leeway       => $self->leeway,
            verify_iss   => $self->issuer,
        );
    }
    catch {
        $self->_invalid('token verification failed');
    };

    $self->_invalid('token payload is not a claims object')
        unless ref $claims eq 'HASH';

    my @aud =
          ref $claims->{aud} eq 'ARRAY' ? @{ $claims->{aud} }
        : defined $claims->{aud}        ? ( $claims->{aud} )
        :                                 ();
    my %ok = map { $_ => 1 } @{ $self->_resource_list };
    $self->_invalid('audience mismatch')
        unless grep { $ok{$_} } @aud;

    return $claims;
}

=head1 NAME

Catalyst::Plugin::OAuth2::ResourceServer::Server - bearer-JWT verification
engine for the ResourceServer plugin

=head1 DESCRIPTION

Pure-logic engine (a Moo object) that holds the verification parameters and
performs bearer-JWT validation independently of Catalyst.  Attributes:
C<signing_key> (required), C<resource> (required: scalar or arrayref),
C<issuer> (required), C<jwt_alg> (default C<HS256>), C<leeway> (default 0).

The engine is constructed per request by the Catalyst seam
(L<Catalyst::Plugin::OAuth2::ResourceServer>) from the app config, so there is
no persistent state between requests.

=head1 METHODS

=head2 verify_token( $jwt )

    my $claims = $engine->verify_token($bearer_token_string);

Verifies a bearer JWT string. Steps performed:

=over 4

=item * Signature verification using C<signing_key> and the HS-alg allowlist
(C<HS256>, C<HS384>, C<HS512> only: C<alg=none> and asymmetric algorithms
are always rejected).

=item * Expiry (C<exp>) check with optional C<leeway> seconds of clock-skew
tolerance. C<exp> is B<required>: a token carrying no expiry is rejected.

=item * Not-before (C<nbf>) and issued-at (C<iat>) checks, also honouring
C<leeway>. Both claims are optional (RFC 7519 4.1.5 and 4.1.6), so they are
validated only when present: a token whose C<nbf> is in the future, or whose
C<iat> is in the future, is rejected, but a token omitting either verifies
normally. This matches what
L<Catalyst::Plugin::OAuth2::AuthorizationServer> mints, which stamps C<iss>,
C<aud>, C<iat> and C<exp> but no C<nbf>.

=item * Issuer (C<iss>) match against the configured C<issuer>. The match is
an exact string comparison, not a substring or prefix match: an C<iss> of
C<https://as.exampleEVIL> does not satisfy a configured issuer of
C<https://as.example>.

=item * Payload type guard: the decoded payload must be a claims hashref.

=item * Audience (C<aud>) membership check: at least one C<aud> value must
match one of the configured C<resource> identifiers.

=back

Returns the claims hashref on success.  Throws a 401
L<Catalyst::Plugin::OAuth2::ResourceServer::Error> with C<error =
'invalid_token'> on any failure; the error description is never forwarded to
clients.

=cut

1;
