package Catalyst::Plugin::OAuth2::AuthorizationServer::Server;
use v5.36;
use Moo;
use Carp ();
use Crypt::JWT qw/encode_jwt/;
use Bytes::Random::Secure qw/random_bytes/;
use MIME::Base64 qw/encode_base64url/;
use Digest::SHA qw/sha256 sha256_hex/;
use JSON::MaybeXS ();
use URI ();
use Catalyst::Plugin::OAuth2::AuthorizationServer::Error;
use namespace::clean;
use MooX::StrictConstructor;

our $VERSION = '0.003';

has store       => ( is => 'ro', required => 1 );
has signing_key => ( is => 'ro', required => 1 );
has issuer      => ( is => 'ro', required => 1 );
has resource    => ( is => 'ro', required => 1 );

has jwt_alg     => ( is => 'ro', default => 'HS256' );
has access_ttl  => ( is => 'ro', default => 900 );
has refresh_ttl => ( is => 'ro', default => 2592000 );
has code_ttl    => ( is => 'ro', default => 60 );

has scopes_supported        => ( is => 'ro' );          # arrayref or undef
has metadata_max_bytes      => ( is => 'ro', default => 8192 );
has redirect_uris_max       => ( is => 'ro', default => 5 );
has redirect_uri_max_length => ( is => 'ro', default => 2048 );

has authorize_endpoint    => ( is => 'lazy' );
has token_endpoint        => ( is => 'lazy' );
has registration_endpoint => ( is => 'lazy' );

sub _build_authorize_endpoint    ( $self ) { $self->issuer . '/authorize' }
sub _build_token_endpoint        ( $self ) { $self->issuer . '/token' }
sub _build_registration_endpoint ( $self ) { $self->issuer . '/register' }

sub BUILD ( $self, $args ) {
    Carp::croak 'resource must be a non-empty scalar or arrayref'
        unless @{ $self->_resource_list };
    for my $ttl (qw/access_ttl refresh_ttl code_ttl/) {
        my $v = $self->$ttl;
        Carp::croak "$ttl must be a positive integer"
            if !$v || $v <= 0;
    }
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
    return ref $r eq 'ARRAY' ? $r : defined $r && length $r ? [$r] : [];
}

sub _now ( $self ) { return time }

# A URL-safe random token of $bytes entropy, base64url with no padding.
sub _random_token ( $self, $bytes = 32 ) {
    my $b64 = encode_base64url( random_bytes($bytes) );
    $b64 =~ s/=+\z//;       # encode_base64url already drops padding; belt + braces
    return $b64;
}

# Mint a signed access-token JWT. Caller supplies sub + scope (+ any extras);
# the engine stamps iss, aud, iat, exp, jti.
sub mint_access_token ( $self, $claims, $aud = undef ) {
    my $now = $self->_now;
    # aud is the AUTHORIZED resource (from the code/refresh binding); fall back
    # to the configured resource list only when the caller passes none.
    my @aud =
          !defined $aud       ? @{ $self->_resource_list }
        : ref $aud eq 'ARRAY' ? @$aud
        :                       ($aud);
    my %payload = (
        %$claims,
        iss => $self->issuer,
        aud => ( @aud == 1 ? $aud[0] : \@aud ),
        iat => $now,
        exp => $now + $self->access_ttl,
        # Nothing reads jti yet. It exists so a revocation denylist can be
        # added later without changing the token format for issued tokens.
        jti => $self->_random_token(16),
    );
    return encode_jwt(
        payload => \%payload,
        alg     => $self->jwt_alg,
        key     => $self->signing_key,
    );
}

# Authorize errors are redirect-safe only AFTER the client and redirect_uri
# have been validated (RFC 6749 4.1.2.1). Pass redirect_uri (+ state) for
# those so the seam can 302 the error back to the client; omit it for
# unknown-client / bad-redirect errors so the seam renders them directly and
# never redirects to an untrusted URI.
sub _authz_error ( $self, $error, $desc, %opt ) {
    Catalyst::Plugin::OAuth2::AuthorizationServer::Error->throw(
        error             => $error,
        error_description => $desc,
        ( exists $opt{redirect_uri} ? ( redirect_uri => $opt{redirect_uri} ) : () ),
        ( exists $opt{state}        ? ( state        => $opt{state} )        : () ),
        http_status       => 400,
    );
}

sub validate_authorize ( $self, $params ) {
    my $state = $params->{state};

    # Client + redirect_uri first; their failures are NOT redirect-safe.
    my $client = $self->store->find_client( $params->{client_id} // '' );
    $self->_authz_error( 'invalid_client', 'unknown client' ) unless $client;

    my $redirect = $params->{redirect_uri} // '';
    my $known = $client->{redirect_uris} || [];
    $self->_authz_error( 'invalid_client', 'redirect_uri mismatch' )
        unless grep { $_ eq $redirect } @$known;

    # From here the redirect_uri is trusted, so further errors are redirect-safe.
    my %rd = ( redirect_uri => $redirect, state => $state );

    $self->_authz_error( 'invalid_request', 'response_type must be code', %rd )
        unless ( $params->{response_type} // '' ) eq 'code';

    my $challenge = $params->{code_challenge};
    $self->_authz_error( 'invalid_request', 'code_challenge required', %rd )
        unless defined $challenge && length $challenge;
    $self->_authz_error( 'invalid_request', 'code_challenge_method must be S256', %rd )
        unless ( $params->{code_challenge_method} // '' ) eq 'S256';
    $self->_authz_error( 'invalid_request',
        'code_challenge must be 43-character base64url (S256)', %rd )
        unless $challenge =~ m{\A[A-Za-z0-9_-]{43}\z};

    my $scope = $params->{scope};
    if ( defined $scope && length $scope && $self->scopes_supported ) {
        my %ok = map { $_ => 1 } @{ $self->scopes_supported };
        for my $s ( split ' ', $scope ) {
            $self->_authz_error( 'invalid_scope',
                'one or more requested scopes are not supported', %rd )
                unless $ok{$s};
        }
    }

    my $resource = $params->{resource} // '';
    my %valid_res = map { $_ => 1 } @{ $self->_resource_list };
    $self->_authz_error( 'invalid_target', 'unknown resource', %rd )
        unless $valid_res{$resource};

    my $rid  = $self->_random_token(24);
    my $data = {
        client_id             => $params->{client_id},
        redirect_uri          => $redirect,
        response_type         => 'code',
        code_challenge        => $challenge,
        code_challenge_method => 'S256',
        scope                 => $scope,
        resource              => $resource,
        state                 => $state,
    };
    $self->store->save_authorization_request(
        $rid, $data, $self->_now + 600 );
    return { request_id => $rid };
}

sub issue_code ( $self, $subject, $request_id ) {
    my $req = $self->store->take_authorization_request( $request_id );
    Catalyst::Plugin::OAuth2::AuthorizationServer::Error->throw(
        error             => 'invalid_request',
        error_description => 'unknown or expired authorization request',
        http_status       => 400,
    ) unless $req;

    my $code    = $self->_random_token(32);
    my $binding = {
        client_id      => $req->{client_id},
        subject        => $subject,
        redirect_uri   => $req->{redirect_uri},
        code_challenge => $req->{code_challenge},
        scope          => $req->{scope},
        resource       => $req->{resource},
    };
    $self->store->create_auth_code(
        $code, $binding, $self->_now + $self->code_ttl );

    return {
        code         => $code,
        redirect_uri => $req->{redirect_uri},
        state        => $req->{state},
    };
}

sub _grant_error ( $self, $desc ) {
    Catalyst::Plugin::OAuth2::AuthorizationServer::Error->throw(
        error             => 'invalid_grant',
        error_description => $desc,
        http_status       => 400,
    );
}

sub _pkce_s256 ( $self, $verifier ) {
    return encode_base64url( sha256($verifier) );
}

# Constant-time string equality, so the PKCE challenge comparison does not
# leak a byte-prefix match via short-circuit timing.
sub _ct_eq ( $self, $a, $b ) {
    return 0 unless length($a) == length($b);
    my $d = 0;
    $d |= ord( substr $a, $_, 1 ) ^ ord( substr $b, $_, 1 )
        for 0 .. length($a) - 1;
    return $d == 0;
}

sub _hash_token ( $self, $raw ) { return sha256_hex($raw) }

# Mint an access + refresh pair from a binding ({ subject, scope, ... }).
sub _issue_token_pair ( $self, $binding ) {
    # Birth is the caller's job (see exchange_authorization_code); inheritance
    # is the rotated binding's. Defaulting here with // would silently birth a
    # new family per rotation, so revoke_family would revoke exactly one token
    # and detection would look like it works while protecting nothing.
    Carp::croak 'internal: _issue_token_pair requires a family_id'
        unless defined $binding->{family_id} && length $binding->{family_id};

    my $access = $self->mint_access_token(
        {
            sub => $binding->{subject},
            ( defined $binding->{scope} ? ( scope => $binding->{scope} ) : () ),
        },
        $binding->{resource},
    );
    my $refresh = $self->_random_token(32);
    my $created = $self->store->create_refresh_token(
        $self->_hash_token($refresh),
        {
            client_id => $binding->{client_id},
            subject   => $binding->{subject},
            scope     => $binding->{scope},
            resource  => $binding->{resource},
            family_id => $binding->{family_id},
        },
        $self->_now + $self->refresh_ttl,
    );
    # The family was revoked while this rotation was in flight: a concurrent
    # replay was detected. Same generic error as any other dead token.
    $self->_grant_error('unknown or revoked refresh token') unless $created;
    return {
        access_token  => $access,
        token_type    => 'Bearer',
        expires_in    => $self->access_ttl,
        refresh_token => $refresh,
        ( defined $binding->{scope} ? ( scope => $binding->{scope} ) : () ),
    };
}

sub exchange_authorization_code ( $self, $params ) {
    my $code = $params->{code};
    $self->_grant_error('code is required')
        unless defined $code && length $code;

    my $binding = $self->store->consume_auth_code($code);
    $self->_grant_error('unknown or used authorization code') unless $binding;

    # When the request identifies its client, it must match the code's bound
    # client (RFC 6749 4.1.3 defence-in-depth on top of PKCE).
    if ( defined $params->{client_id} && length $params->{client_id} ) {
        $self->_grant_error('client_id mismatch')
            unless $params->{client_id} eq $binding->{client_id};
    }

    $self->_grant_error('redirect_uri mismatch')
        unless ( $params->{redirect_uri} // '' ) eq $binding->{redirect_uri};

    my $verifier = $params->{code_verifier};
    $self->_grant_error('code_verifier required')
        unless defined $verifier && length $verifier;
    # RFC 7636 4.1: 43-128 characters of the unreserved set.
    $self->_grant_error(
        'code_verifier must be 43-128 characters of [A-Za-z0-9._~-]')
        unless $verifier =~ m{\A[A-Za-z0-9._~-]{43,128}\z};
    $self->_grant_error('PKCE verification failed')
        unless $self->_ct_eq( $self->_pkce_s256($verifier),
        $binding->{code_challenge} );

    # A code exchange births a new family; a rotation inherits one.
    return $self->_issue_token_pair(
        { %$binding, family_id => $self->_random_token(16) } );
}

sub refresh ( $self, $params ) {
    my $raw = $params->{refresh_token};
    $self->_grant_error('refresh_token is required')
        unless defined $raw && length $raw;

    my $result = $self->store->rotate_refresh_token( $self->_hash_token($raw) );
    $self->_grant_error('unknown or revoked refresh token') unless $result;

    # RFC 9700: a replay means the chain is compromised and we cannot tell the
    # legitimate client from the attacker, so the whole family goes. Revoke
    # before erroring, and let a failing revoke_family surface as a 500: a
    # Store that cannot revoke is broken, and answering invalid_grant while
    # leaving the family alive fails the wrong way.
    if ( $result->{reused} ) {
        Carp::croak 'internal: reused refresh token binding has no family_id'
            unless defined $result->{binding}{family_id}
            && length $result->{binding}{family_id};
        $self->store->revoke_family( $result->{binding}{family_id} );
        # Same error and description as an unknown token: telling an attacker
        # that reuse was detected confirms they hold a real token.
        $self->_grant_error('unknown or revoked refresh token');
    }

    my $binding = $result->{binding};

    # Mirror the code-exchange client binding check (RFC 6749 6).
    if ( defined $params->{client_id} && length $params->{client_id} ) {
        $self->_grant_error('client_id mismatch')
            unless $params->{client_id} eq $binding->{client_id};
    }

    return $self->_issue_token_pair($binding);
}

sub _invalid_metadata ( $self, $desc ) {
    Catalyst::Plugin::OAuth2::AuthorizationServer::Error->throw(
        error             => 'invalid_client_metadata',
        error_description => $desc,
        http_status       => 400,
    );
}

sub metadata_document ( $self ) {
    my %doc = (
        issuer                                => $self->issuer,
        authorization_endpoint                => $self->authorize_endpoint,
        token_endpoint                        => $self->token_endpoint,
        registration_endpoint                 => $self->registration_endpoint,
        response_types_supported              => ['code'],
        grant_types_supported                 => [ 'authorization_code', 'refresh_token' ],
        code_challenge_methods_supported      => ['S256'],
        token_endpoint_auth_methods_supported => ['none'],
    );
    $doc{scopes_supported} = $self->scopes_supported if $self->scopes_supported;
    return \%doc;
}

sub register_client ( $self, $metadata ) {
    my $uris = $metadata->{redirect_uris};
    $self->_invalid_metadata('redirect_uris is required')
        unless ref $uris eq 'ARRAY' && @$uris;
    $self->_invalid_metadata('too many redirect_uris')
        if @$uris > $self->redirect_uris_max;
    for my $u (@$uris) {
        $self->_invalid_metadata('redirect_uri not a string')
            if ref $u || !defined $u || !length $u;
        $self->_invalid_metadata('redirect_uri too long')
            if length $u > $self->redirect_uri_max_length;

        my $parsed = URI->new($u);
        my $scheme = lc( $parsed->scheme // '' );
        my $ok_scheme =
              $scheme eq 'https' ? 1
            : $scheme eq 'http'
                && $parsed->can('host')
                && ( $parsed->host // '' )
                    =~ m{\A(?:localhost|127\.\d+\.\d+\.\d+|::1)\z} ? 1
            : 0;
        $self->_invalid_metadata('redirect_uri scheme not allowed')
            unless $ok_scheme;
        $self->_invalid_metadata('redirect_uri must not contain a fragment')
            if $parsed->can('fragment') && defined $parsed->fragment;
    }

    $self->_validate_client_metadata($metadata);

    my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
    $self->_invalid_metadata('client metadata too large')
        if length( $json->encode($metadata) ) > $self->metadata_max_bytes;

    my $client = { %$metadata, client_id => $self->_random_token(16) };
    return $self->store->create_client($client);
}

# RFC 7591 3.2.1: reject a registration whose metadata asks for something this
# AS does not support. The allow-lists are read straight off metadata_document,
# so registration can never accept a value discovery does not advertise. Fields
# RFC 7591 leaves free-form (client_name, logo_uri, contacts, extensions, and
# scope when no scopes_supported is configured) are left alone: a value is only
# rejected where the AS has actually declared what it supports.
sub _validate_client_metadata ( $self, $metadata ) {
    my $doc = $self->metadata_document;

    if ( exists $metadata->{token_endpoint_auth_method} ) {
        my $method = $metadata->{token_endpoint_auth_method};
        my %ok = map { $_ => 1 }
            @{ $doc->{token_endpoint_auth_methods_supported} };
        $self->_invalid_metadata('unsupported token_endpoint_auth_method')
            if ref $method || !defined $method || !$ok{$method};
    }

    for my $field (qw/grant_types response_types/) {
        next unless exists $metadata->{$field};
        my $values = $metadata->{$field};
        $self->_invalid_metadata(
            "$field must be a non-empty array of strings")
            unless ref $values eq 'ARRAY' && @$values;
        my %ok = map { $_ => 1 } @{ $doc->{"${field}_supported"} };
        for my $v (@$values) {
            $self->_invalid_metadata("unsupported $field value")
                if ref $v || !defined $v || !$ok{$v};
        }
    }

    # scope is only constrained when the AS advertises scopes_supported.
    if ( exists $metadata->{scope} && $self->scopes_supported ) {
        my $scope = $metadata->{scope};
        $self->_invalid_metadata('scope must be a string')
            if ref $scope || !defined $scope;
        my %ok = map { $_ => 1 } @{ $self->scopes_supported };
        for my $s ( split ' ', $scope ) {
            $self->_invalid_metadata(
                'one or more requested scopes are not supported')
                unless $ok{$s};
        }
    }
    return;
}

=head1 NAME

Catalyst::Plugin::OAuth2::AuthorizationServer::Server - Pure-logic OAuth 2.1
Authorization Server engine

=head1 DESCRIPTION

The pure-logic OAuth 2.1 engine behind the Catalyst seam. Holds the Store
reference, the signing key, and configuration; is otherwise stateless (the
only mutable state lives in the injected Store).

Access tokens are signed with a symmetric HMAC algorithm only: C<jwt_alg> may
be C<HS256> (the default), C<HS384> or C<HS512>. Asymmetric signing (C<RS*>,
C<ES*>, C<PS*>) and C<alg=none> are not supported, and no JWKS is published:
this is deliberate for the MCP single-server profile, where the Authorization
Server and Resource Server share one deployment and one key. C<signing_key>
must be at least as long as the algorithm's hash output (32, 48 or 64 bytes
respectively, per RFC 7518 3.2); a shorter key is rejected at construction.

=head1 METHODS

=head2 mint_access_token( \%claims, $aud )

Mint a signed JWT access token. The engine stamps C<iss>, C<aud>, C<iat>,
C<exp> and C<jti>, and they are stamped after C<\%claims>, so a caller cannot
override them. C<$aud> defaults to the configured C<resource> list. Returns the
encoded JWT string.

=head2 register_client( \%metadata )

Dynamic Client Registration (RFC 7591). Validates C<redirect_uris> (must be
present; each must be HTTPS or loopback HTTP; no fragments; within length
limits). Generates a C<client_id>, calls C<Store::create_client>, and returns
the stored client hashref.

Per RFC 7591 3.2.1, registration also rejects metadata asking for anything
this AS does not support, with C<invalid_client_metadata>. The allow-lists are
taken from L</metadata_document>, so registration can never accept a value the
discovery document does not advertise:

=over

=item *

C<token_endpoint_auth_method> must be one of
C<token_endpoint_auth_methods_supported> (C<none>: this profile registers
public PKCE clients, so C<client_secret_basic> and friends are rejected).

=item *

C<grant_types> must be a non-empty arrayref, each value one of
C<grant_types_supported> (C<authorization_code>, C<refresh_token>).

=item *

C<response_types> must be a non-empty arrayref, each value one of
C<response_types_supported> (C<code>).

=item *

C<scope> is checked against C<scopes_supported> B<only> when the AS is
configured with one; with no C<scopes_supported> the server declares no
constraint, so C<scope> is left free-form.

=back

Everything else RFC 7591 leaves free-form (C<client_name>, C<client_uri>,
C<logo_uri>, C<contacts>, C<software_id>, extension fields) is stored as
given and never rejected merely for being present.

=head2 validate_authorize( \%params )

Validate an authorization request (RFC 6749 4.1.1 + PKCE RFC 7636). Checks
client, redirect_uri, response_type, code_challenge (must be a 43-character
base64url string), code_challenge_method (must be C<S256>), scope, and
resource. On success, stashes the request via
C<Store::save_authorization_request> and returns C<{ request_id }>.

=head2 issue_code( $subject, $request_id )

Atomically consume the stashed authorization request and mint a single-use
authorization code bound to C<$subject>. Returns C<{ code, redirect_uri,
state }>. Throws C<invalid_request> if the request is unknown or expired.

=head2 exchange_authorization_code( \%params )

Authorization-code grant (RFC 6749 4.1.3). Validates code, redirect_uri,
client_id binding, and PKCE verifier. Returns C<{ access_token, token_type,
expires_in, refresh_token }> (plus C<scope> if the request carried one).

=head2 refresh( \%params )

Refresh-token grant (RFC 6749 6). Rotates the refresh token via
C<Store::rotate_refresh_token> and mints a new access + refresh pair.
Optionally validates a C<client_id> parameter against the binding.

=head2 metadata_document

Return the RFC 8414 Authorization Server Metadata hashref.

=cut

1;
