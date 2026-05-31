package Catalyst::Plugin::OpenIDConnect::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use JSON::MaybeXS qw(encode_json decode_json);
use MIME::Base64 qw(encode_base64 decode_base64 encode_base64url);
use Digest::SHA qw(sha256);
use Crypt::PK::RSA;
use Crypt::Misc qw(slow_eq);
use URI;
use DateTime;
use Try::Tiny;
use Data::UUID;

# Set the namespace for OpenIDConnect routes
__PACKAGE__->config(namespace => 'openidconnect');

# Module-level UUID generator for refresh token JTI claims (MED-1).
my $_uuid = Data::UUID->new();

=head1 NAME

Catalyst::Plugin::OpenIDConnect::Controller::Root - OIDC Protocol Endpoints

=head1 SYNOPSIS

Handles OpenID Connect protocol endpoints:

    /.well-known/openid-configuration - Discovery endpoint
    /openidconnect/authorize     - Authorization endpoint
    /openidconnect/token         - Token endpoint
    /openidconnect/userinfo      - UserInfo endpoint  
    /openidconnect/logout        - Logout endpoint
    /openidconnect/jwks          - JWKS endpoint for key discovery

=cut

=head1 DESCRIPTION

This controller implements the core OpenID Connect protocol endpoints.  To use it in your application, create a controller that extends this one:

    package MyApp::Controller::Auth;
    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Plugin::OpenIDConnect::Controller::Root'; }

    __PACKAGE__->meta->make_immutable;

=head1 METHODS

=head2 begin

Called automatically before every action in this controller.  Sets HTTP
security headers that must be present on all OIDC endpoint responses.

=cut

sub begin : Private {
    my ( $self, $c ) = @_;

    # RFC 6749 §5.1 requires Cache-Control: no-store on token responses;
    # applied globally so new endpoints can't accidentally omit it.
    # Pragma: no-cache is the HTTP/1.0 equivalent.
    $c->response->header( 'Cache-Control'          => 'no-store' );
    $c->response->header( 'Pragma'                 => 'no-cache' );

    # Prevent MIME sniffing.
    $c->response->header( 'X-Content-Type-Options' => 'nosniff' );

    # Clickjacking protection on the authorize endpoint HTML page.
    # Both headers are set for broadest browser compatibility (MED-6).
    $c->response->header( 'X-Frame-Options'        => 'DENY' );
    $c->response->header( 'Content-Security-Policy' => "frame-ancestors 'none'" );
}

=head2 discovery

GET /.well-known/openid-configuration

Returns the OpenID Connect provider configuration.

=cut

sub discovery : Path('/.well-known/openid-configuration') {
    my ( $self, $c ) = @_;

    my $config = $c->openidconnect->config;

    $c->log->debug('OpenID Connect discovery endpoint accessed') if $config->{debug};
    $self->_json_response( $c, $c->openidconnect->get_discovery() );
}

=head2 authorize

GET /openidconnect/authorize

OpenID Connect authorization endpoint.

Query parameters:

    - response_type (REQUIRED): "code"
    - client_id (REQUIRED): The client ID
    - redirect_uri (REQUIRED): Where to redirect after authorization
    - scope (RECOMMENDED): Space-separated scopes (default: "openid")
    - state (RECOMMENDED): CSRF protection state parameter
    - nonce (OPTIONAL): String to bind to the ID token

=cut

sub authorize : Local {
    my ( $self, $c ) = @_;

    my $config = $c->openidconnect->config;

    $c->log->debug('Authorization endpoint accessed') if $config->{debug};

    my $response_type        = $c->request->params->{response_type};
    my $client_id            = $c->request->params->{client_id};
    my $redirect_uri         = $c->request->params->{redirect_uri};
    my $scope                = $c->request->params->{scope};
    my $state                = $c->request->params->{state};
    my $nonce                = $c->request->params->{nonce};
    my $code_challenge       = $c->request->params->{code_challenge};
    my $code_challenge_method = $c->request->params->{code_challenge_method};

    $c->log->debug("Authorization request - client_id: $client_id, response_type: $response_type, redirect_uri: $redirect_uri") if $config->{debug};

    my $stored_auth_request = $c->session->{oidc_auth_request} || {};
    $response_type         //= $stored_auth_request->{response_type};
    $client_id             //= $stored_auth_request->{client_id};
    $redirect_uri          //= $stored_auth_request->{redirect_uri};
    $scope                 ||= $stored_auth_request->{scope} || 'openid';
    $state                 //= $stored_auth_request->{state};
    $nonce                 //= $stored_auth_request->{nonce};
    $code_challenge        //= $stored_auth_request->{code_challenge};
    $code_challenge_method //= $stored_auth_request->{code_challenge_method};

    # --- Phase 1: validate client_id and redirect_uri BEFORE using either in a
    # redirect-based error response (NEW-HIGH-1 / RFC 6749 §4.1.2.1).
    # Any error raised here returns a direct HTTP 400; we must never redirect
    # to a URI that has not yet been confirmed as registered for the client.

    unless ($client_id) {
        $c->log->warn('Missing client_id parameter');
        return $self->_json_error( $c, 'invalid_request', 'client_id is required' );
    }

    unless ($redirect_uri) {
        $c->log->warn('Missing redirect_uri parameter');
        return $self->_json_error( $c, 'invalid_request', 'redirect_uri is required' );
    }

    # Resolve client — must succeed before redirect_uri can be validated.
    my $client = $c->openidconnect->get_client($client_id);
    unless ($client) {
        $c->log->error("Unknown client: $client_id");
        return $self->_json_error( $c, 'invalid_client', 'Unknown client' );
    }

    # Validate redirect_uri against the registered list.
    # Only after this check is it safe to use $redirect_uri in _error_response.
    my @allowed_uris = _normalize_uri_list( $client->{redirect_uris} );
    unless ( grep { $_ eq $redirect_uri } @allowed_uris ) {
        $c->log->error("Redirect URI mismatch for client $client_id: $redirect_uri");
        return $self->_json_error( $c, 'invalid_request',
            'Redirect URI not registered' );
    }

    # --- Phase 2: remaining parameter validation — redirect_uri is now
    # confirmed registered so _error_response redirects are safe from here on.

    unless ( $response_type && $response_type eq 'code' ) {
        $c->log->warn("Invalid response_type: $response_type");
        return $self->_error_response(
            $c, $redirect_uri, 'invalid_request',
            'response_type must be "code"', $state
        );
    }

    # Restrict scope to the intersection of what was requested and what this
    # client is registered for (NEW-MED-2 / RFC 6749 §3.3).
    # Accepting arbitrary scope strings allows clients to obtain tokens
    # bearing scopes they were never granted (e.g. "admin").
    {
        my @registered = split /\s+/, ( $client->{scope} // 'openid' );
        my @requested  = split /\s+/, $scope;
        my %allowed    = map { $_ => 1 } @registered;
        my @effective  = grep { $allowed{$_} } @requested;
        unless (@effective) {
            $c->log->warn(
                "No permitted scopes in request for client $client_id: $scope"
            );
            return $self->_error_response(
                $c, $redirect_uri, 'invalid_scope',
                'None of the requested scopes are registered for this client',
                $state
            );
        }
        # OIDC Core §3.1.2.1 — openid scope is mandatory for OIDC requests.
        unless ( grep { $_ eq 'openid' } @effective ) {
            $c->log->warn("Missing openid scope for client $client_id");
            return $self->_error_response(
                $c, $redirect_uri, 'invalid_scope',
                'openid scope is required', $state
            );
        }
        $scope = join ' ', @effective;
        $c->log->debug("Effective scope for client $client_id: $scope")
            if $config->{debug};
    }

    # Check if user is authenticated
    unless ( $c->user ) {
        $c->log->debug('User not authenticated, redirecting to login') if $config->{debug};
        $c->session->{oidc_auth_request} = {
            response_type         => $response_type,
            client_id             => $client_id,
            redirect_uri          => $redirect_uri,
            scope                 => $scope,
            state                 => $state,
            nonce                 => $nonce,
            code_challenge        => $code_challenge,
            code_challenge_method => $code_challenge_method,
        };

        return $c->response->redirect( $c->uri_for('/login', { back => '/openidconnect/authorize' }) );
    }

    $c->log->info("Authorization granted for user: " . $c->user->id . " to client: $client_id");

    # PKCE validation (RFC 7636, OAuth 2.1).
    # Public clients (no client_secret) MUST supply a code_challenge.
    # Confidential clients MAY supply one; if they do, it is validated.
    # Only S256 is accepted — 'plain' provides no meaningful security.
    my $is_public_client = !( $client->{client_secret} && length $client->{client_secret} );
    if ( $is_public_client && !$code_challenge ) {
        $c->log->warn("PKCE code_challenge required for public client: $client_id");
        return $self->_error_response(
            $c, $redirect_uri, 'invalid_request',
            'code_challenge is required for public clients', $state
        );
    }
    if ( $code_challenge ) {
        my $method = $code_challenge_method // 'plain';
        unless ( $method eq 'S256' ) {
            $c->log->warn("Unsupported code_challenge_method '$method' for client: $client_id");
            return $self->_error_response(
                $c, $redirect_uri, 'invalid_request',
                'code_challenge_method must be S256', $state
            );
        }
        # Validate the challenge value format (NEW-LOW-1 / RFC 7636 §4.2).
        # An S256 challenge is BASE64URL(SHA256(verifier)) — exactly 43 chars
        # from the BASE64URL alphabet with no padding.  Reject malformed values
        # before they reach the store or any downstream comparison.
        unless ( $code_challenge =~ /\A[A-Za-z0-9\-_]{43}\z/ ) {
            $c->log->warn("Malformed code_challenge for client $client_id");
            return $self->_error_response(
                $c, $redirect_uri, 'invalid_request',
                'code_challenge must be a 43-character BASE64URL-encoded string',
                $state
            );
        }
    }

    # Extract user claims now, while the live user object is available.
    # Storing the plain claims hashref (rather than the user object itself)
    # means the store never needs to serialise application-specific objects
    # such as DBIx::Class rows or LDAP entries — it always receives and
    # returns plain data.
    my $user_claims = $c->openidconnect->get_user_claims( $c->user );

    # Create authorization code, passing any PKCE challenge so it is stored
    # alongside the code and can be verified at the token endpoint.
    my $pkce = $code_challenge
        ? { code_challenge => $code_challenge, code_challenge_method => 'S256' }
        : undef;
    my $code = $c->openidconnect->store->create_authorization_code(
        $client_id, $user_claims, $scope, $redirect_uri, $nonce, $pkce
    );

    # Store authorization in session for later token request
    $c->session->{oidc_code}->{$code} = {
        client_id             => $client_id,
        user                  => $user_claims,
        scope                 => $scope,
        redirect_uri          => $redirect_uri,
        nonce                 => $nonce,
        code_challenge        => $code_challenge,
        code_challenge_method => $code_challenge ? 'S256' : undef,
    };

    # Clear the stored authorization request after resuming the flow.
    delete $c->session->{oidc_auth_request};

    # Build redirect URI with code and state
    my $callback_uri = URI->new($redirect_uri);
    $callback_uri->query_form(
        code  => $code,
        state => $state,
    );

    $c->log->debug("Redirecting to: " . $callback_uri->as_string) if $config->{debug};
    $c->response->redirect( $callback_uri->as_string );
}

=head2 token

POST /openidconnect/token

Token endpoint for exchanging authorization code for tokens.

Parameters (form-encoded):

    - grant_type (REQUIRED): "authorization_code" or "refresh_token"
    - code (REQUIRED for authorization_code): The authorization code
    - redirect_uri (REQUIRED): Must match authorization request
    - client_id (OPTIONAL): The client ID (extracted from code if not provided)
    - client_secret (OPTIONAL): The client secret (required for confidential clients, optional for public clients)

Returns:

    - access_token: The access token
    - token_type: "Bearer"
    - id_token: The ID token
    - expires_in: Token expiration in seconds
    - refresh_token: (optional) Refresh token

=cut

sub token : Local {
    my ( $self, $c ) = @_;

    my $config = $c->openidconnect->config;

    $c->response->content_type('application/json');
    $c->log->debug('Token endpoint accessed') if $config->{debug};

    my $grant_type = $c->request->params->{grant_type};

    unless ($grant_type) {
        $c->log->warn('Missing grant_type parameter');
        return $self->_json_error( $c, 'invalid_request', 'grant_type is required' );
    }

    $c->log->debug("Token request with grant_type: $grant_type") if $config->{debug};

    if ( $grant_type eq 'authorization_code' ) {
        return $self->_handle_authorization_code_grant($c);
    } elsif ( $grant_type eq 'refresh_token' ) {
        return $self->_handle_refresh_token_grant($c);
    } else {
        $c->log->warn("Unsupported grant_type: $grant_type");
        return $self->_json_error( $c, 'unsupported_grant_type', "Unsupported grant_type: $grant_type" );
    }
}

=head2 userinfo

GET /openidconnect/userinfo
Authorization: Bearer <access_token>

UserInfo endpoint returning authenticated user's claims.

=cut

sub userinfo : Local {
    my ( $self, $c ) = @_;

    my $config = $c->openidconnect->config;
    $c->log->debug('UserInfo endpoint accessed') if $config->{debug};

    # Get bearer token
    my $auth_header = $c->request->header('Authorization') || '';
    my ($token) = $auth_header =~ /^Bearer\s+(\S+)$/;

    unless ($token) {
        $c->log->warn('Missing or invalid Authorization header');
        return $self->_json_error( $c, 'invalid_token', 'Missing or invalid Authorization header' );
    }

    # Verify token
    my $payload;
    try {
        $payload = $c->openidconnect->jwt->verify_token($token);
        $c->log->debug('Access token verified successfully') if $config->{debug};
    }
    catch {
        $c->log->warn("Token verification failed: $_");
        return $self->_json_error( $c, 'invalid_token', "Token verification failed: $_" );
    };

    # Reject ID tokens and refresh tokens presented as access tokens (NEW-MED-1).
    # Access tokens carry typ=at+JWT (RFC 9068); all other token types must be refused.
    unless ( ( $payload->{typ} // '' ) eq 'at+JWT' ) {
        $c->log->warn('Presented token is not an access token (typ=' . ($payload->{typ} // 'missing') . ')');
        return $self->_json_error( $c, 'invalid_token', 'Presented token is not an access token' );
    }

    # Get user and claims
    my $user_id = $payload->{sub};
    unless ($user_id) {
        $c->log->error('Token missing sub claim');
        return $self->_json_error( $c, 'invalid_token', 'Token missing sub claim' );
    }

    $c->log->debug("UserInfo requested for user: $user_id") if $config->{debug};

    # This would normally fetch the user from database
    # For now, we'll use the claims already in the token
    my %claims = (
        sub => $payload->{sub},
    );

    # Add other standard claims from token
    for my $claim (qw(name email email_verified picture phone_number phone_number_verified)) {
        $claims{$claim} = $payload->{$claim} if exists $payload->{$claim};
    }

    $c->log->debug('UserInfo response prepared') if $config->{debug};
    $self->_json_response( $c, \%claims );
}

=head2 logout

POST /openidconnect/logout

Logout endpoint to invalidate tokens and clear sessions.

Implements OpenID Connect RP-Initiated Logout 1.0.

Parameters:

    - id_token_hint (REQUIRED when post_logout_redirect_uri is supplied): A
      previously issued ID Token identifying the client requesting logout.
      The token's signature is verified to confirm it was issued by this server.
      Expiry is intentionally not checked; hint tokens are often expired.
    - post_logout_redirect_uri (OPTIONAL): URL to redirect to after logout.
      Must be registered in the client's C<post_logout_redirect_uris> list.
      Providing this parameter without a valid C<id_token_hint> is rejected
      with an C<invalid_request> error to prevent open-redirect attacks.
    - state (OPTIONAL): Opaque value returned verbatim in the redirect query
      string (only when post_logout_redirect_uri is also provided).

=cut

sub logout : Local {
    my ( $self, $c ) = @_;

    my $config = $c->openidconnect->config;

    $c->log->debug('Logout endpoint accessed') if $config->{debug};

    my $redirect_uri   = $c->request->params->{post_logout_redirect_uri};
    my $id_token_hint  = $c->request->params->{id_token_hint};
    my $state          = $c->request->params->{state};

    # Decode the hint early — before the session is destroyed — so that we
    # have the subject identifier available for refresh token revocation (MED-1).
    my $hint_claims;
    if ($id_token_hint) {
        $hint_claims = $c->openidconnect->jwt->decode_id_token_hint($id_token_hint);
    }

    # Determine the subject identifier for refresh token revocation.  Prefer
    # the hint (authoritative); fall back to the live session so that
    # logout-without-hint still revokes tokens when the session is present.
    my $logout_sub = do {
        if ( $hint_claims && $hint_claims->{sub} ) {
            $hint_claims->{sub};
        }
        else {
            my $sess_user = eval { $c->session->{user} };
            $sess_user ? ( $sess_user->{sub} || $sess_user->{id} ) : undef;
        }
    };

    # Clear user session
    if ( $c->user ) {
        $c->log->info('Logging out user: ' . $c->user->id);
        $c->user->logout();
    }

    # Destroy session
    if ( $c->sessionid ) {
        $c->log->debug('Destroying session: ' . $c->sessionid) if $config->{debug};
        $c->delete_session('User session destroyed');
    }

    # Revoke all outstanding refresh tokens for this user (MED-1).
    if ($logout_sub) {
        $c->openidconnect->store->revoke_refresh_tokens_for_user($logout_sub);
        $c->log->debug("Refresh tokens revoked for user: $logout_sub")
            if $config->{debug};
    }

    if ($redirect_uri) {
        # id_token_hint is required when a redirect is requested so that we
        # can identify the client and verify the URI is registered for it.
        # Without this check an attacker could redirect to any arbitrary URL.
        unless ($id_token_hint) {
            $c->log->warn('post_logout_redirect_uri provided without id_token_hint');
            return $self->_json_error( $c, 'invalid_request',
                'id_token_hint is required when post_logout_redirect_uri is provided' );
        }

        # $hint_claims was decoded above; reject if invalid.
        unless ($hint_claims) {
            $c->log->warn('Invalid id_token_hint provided at logout');
            return $self->_json_error( $c, 'invalid_request', 'Invalid id_token_hint' );
        }

        # aud may be a string or an array per RFC 7519 §4.1.3.
        my $aud       = $hint_claims->{aud};
        my $client_id = ref $aud eq 'ARRAY' ? $aud->[0] : $aud;

        unless ($client_id) {
            $c->log->warn('id_token_hint is missing the aud claim');
            return $self->_json_error( $c, 'invalid_request',
                'id_token_hint does not contain an aud claim' );
        }

        # Look up the client and validate the redirect URI against its
        # registered post_logout_redirect_uris list.
        my $client = $c->openidconnect->get_client($client_id);
        unless ($client) {
            $c->log->warn("Unknown client in id_token_hint aud claim: $client_id");
            return $self->_json_error( $c, 'invalid_request',
                'Unknown client in id_token_hint' );
        }

        my @allowed = _normalize_uri_list( $client->{post_logout_redirect_uris} );
        unless ( grep { $_ eq $redirect_uri } @allowed ) {
            $c->log->warn(
                "Unregistered post_logout_redirect_uri for client $client_id: $redirect_uri"
            );
            return $self->_json_error( $c, 'invalid_request',
                'post_logout_redirect_uri is not registered for this client' );
        }

        # Build the final redirect URI, appending state if supplied.
        my $final_uri = URI->new($redirect_uri);
        $final_uri->query_form( $final_uri->query_form, state => $state )
            if defined $state && $state ne '';

        $c->log->debug( 'Redirecting to post-logout URI: ' . $final_uri->as_string )
            if $config->{debug};
        return $c->response->redirect( $final_uri->as_string );
    }

    # Return success JSON response
    $c->log->info('Logout completed successfully');
    $self->_json_response( $c, {
        message => 'Logged out successfully',
    });
}

# Verify a PKCE code_verifier against a stored code_challenge.
# Only S256 (SHA-256) is supported; 'plain' is intentionally rejected.
# Returns a true value on success, false on failure.
sub _verify_pkce {
    my ( $code_verifier, $code_challenge ) = @_;
    return 0 unless defined $code_verifier && defined $code_challenge;
    # Verifier must contain only unreserved URI chars and be 43-128 chars (RFC 7636 §4.1)
    return 0 unless $code_verifier =~ /\A[A-Za-z0-9\-._~]{43,128}\z/;
    # S256: BASE64URL( SHA256( ASCII( code_verifier ) ) )
    my $computed = encode_base64url( sha256($code_verifier) );
    return slow_eq( $computed, $code_challenge );
}

# Normalise a redirect-URI config field.
# Accepts either an arrayref (YAML / JSON / Perl hash config) or a
# whitespace-delimited string (Config::General / Apache-style config).
# Returns a flat list of URI strings.
# Used for both redirect_uris and post_logout_redirect_uris so that both
# fields behave identically regardless of config format.
sub _normalize_uri_list {
    my ($field) = @_;
    return () unless defined $field;
    return ref $field eq 'ARRAY' ? @$field : split /\s+/, $field;
}

=head2 jwks

GET /openidconnect/jwks

JSON Web Key Set endpoint for key discovery.

Returns the public key(s) for verifying signatures.

=cut

sub jwks : Local {
    my ( $self, $c ) = @_;

    my $config = $c->openidconnect->config;

    $c->log->debug('JWKS endpoint accessed') if $config->{debug};

    # Get JWT handler and public key
    my $jwt = $c->openidconnect->jwt;
    my $public_key = $jwt->public_key;

    $c->log->debug('Extracting public key parameters for JWKS') if $config->{debug};

    # Convert OpenSSL public key to Crypt::PK::RSA for easier parameter extraction
    my $public_key_pem = $public_key->get_public_key_string();
    my $pk = Crypt::PK::RSA->new(\$public_key_pem);

    # Get key parameters for JWK generation
    my $keydata = $pk->key2hash();

    # Convert modulus and exponent to base64url
    # Note: key2hash() returns lowercase keys (e, N, etc.)
    my $n = $self->_bigint_to_base64url($keydata->{N});
    my $e = $self->_bigint_to_base64url($keydata->{e});

    # Create JWK with all required fields
    my %jwk = (
        kty => 'RSA',
        use => 'sig',
        kid => $jwt->key_id,
        alg => 'RS256',
        n   => $n,
        e   => $e,
    );

    $c->log->debug('JWKS response prepared with key ID: ' . $jwt->key_id) if $config->{debug};
    $self->_json_response( $c, { keys => [ \%jwk ] } );
}

# Private helper methods

sub _handle_authorization_code_grant {
    my ( $self, $c ) = @_;

    my $config = $c->openidconnect->config;

    $c->log->debug('Processing authorization_code grant') if $config->{debug};

    my $code          = $c->request->params->{code};
    my $redirect_uri  = $c->request->params->{redirect_uri};
    my $client_id     = $c->request->params->{client_id};
    my $client_secret = $c->request->params->{client_secret};
    my $code_verifier = $c->request->params->{code_verifier};

    unless ( $code && $redirect_uri ) {
        $c->log->warn('Missing code or redirect_uri in token request');
        return $self->_json_error( $c, 'invalid_request', 'code and redirect_uri are required' );
    }

    $c->log->debug("Token request - code: $code, client_id: $client_id") if $config->{debug};

    # Atomically consume (fetch + delete) the authorization code.
    # Using consume_authorization_code rather than a separate get + delete
    # eliminates the TOCTOU race that would otherwise allow two concurrent
    # requests carrying the same code to both succeed (HIGH-4).
    # Per RFC 6749 §4.1.2 any code that fails subsequent validation must
    # also be treated as used, which this pattern naturally enforces.
    my $code_data = $c->openidconnect->store->consume_authorization_code($code);
    unless ($code_data) {
        $c->log->warn("Authorization code not found, expired, or already used: $code");
        return $self->_json_error( $c, 'invalid_grant', 'Authorization code not found or expired' );
    }
    $c->log->debug("Authorization code consumed: $code") if $config->{debug};

    # Remove session copy of this code so stale claims/scope/nonce do not
    # accumulate in the session store beyond the code's 10-minute lifetime (MED-5).
    delete $c->session->{oidc_code}->{$code};

    # Use client_id from authorization code if not provided in request (public client flow)
    $client_id ||= $code_data->{client_id};

    # Enforce that the client presenting the token request is the same client
    # the authorization code was issued to (RFC 6749 §4.1.3, NEW-HIGH-2).
    # Without this check a confidential client that obtains another client's
    # code could redeem it by authenticating with its own valid secret.
    if ( $client_id ne $code_data->{client_id} ) {
        $c->log->warn(
            "client_id mismatch at token endpoint: "
            . "request=$client_id stored=$code_data->{client_id}"
        );
        return $self->_json_error( $c, 'invalid_grant',
            'client_id does not match the authorization code' );
    }

    # Verify redirect URI matches
    unless ( $code_data->{redirect_uri} eq $redirect_uri ) {
        $c->log->error("Redirect URI mismatch for code: $code (expected: " . $code_data->{redirect_uri} . ", got: $redirect_uri)");
        return $self->_json_error( $c, 'invalid_grant', 'Redirect URI mismatch' );
    }

    # PKCE verification (RFC 7636)
    if ( $code_data->{code_challenge} ) {
        unless ( defined $code_verifier ) {
            $c->log->warn("PKCE code_verifier missing for client: $client_id");
            return $self->_json_error( $c, 'invalid_grant', 'code_verifier is required' );
        }
        unless ( _verify_pkce( $code_verifier, $code_data->{code_challenge} ) ) {
            $c->log->warn("PKCE verification failed for client: $client_id");
            return $self->_json_error( $c, 'invalid_grant', 'code_verifier is invalid' );
        }
        $c->log->debug('PKCE verification passed') if $config->{debug};
    }

    # If client_secret is provided, verify client credentials (confidential client)
    if ($client_secret) {
        $c->log->debug("Verifying client credentials for: $client_id") if $config->{debug};
        my $client = $c->openidconnect->get_client($client_id);
        unless ( $client && slow_eq( $client->{client_secret}, $client_secret ) ) {
            $c->log->warn("Client authentication failed for: $client_id");
            return $self->_json_error( $c, 'invalid_client', 'Client authentication failed' );
        }
    } else {
        # For public clients (no secret provided), at least verify client exists
        my $client = $c->openidconnect->get_client($client_id);
        unless ($client) {
            $c->log->warn("Unknown client: $client_id");
            return $self->_json_error( $c, 'invalid_client', 'Unknown client' );
        }
    }

    # User claims were extracted and stored at authorization time, so
    # $code_data->{user} is already the mapped claims hashref.
    my $user_claims = $code_data->{user};

    # Create tokens
    my $now = time();
    my %id_token_payload = (
        %$user_claims,
        aud => $client_id,
        exp => $now + 3600,  # 1 hour
    );

    $id_token_payload{nonce} = $code_data->{nonce} if $code_data->{nonce};

    my $id_token = $c->openidconnect->jwt->create_id_token(%id_token_payload);
    $c->log->debug('ID token created') if $config->{debug};

    my %access_token_payload = (
        sub => $user_claims->{sub},
        aud => $client_id,
        scp => $code_data->{scope},
        typ => 'at+JWT',  # RFC 9068 — distinguishes access tokens from ID/refresh tokens (NEW-MED-1)
        exp => $now + 3600,
    );

    my $access_token = $c->openidconnect->jwt->create_access_token(%access_token_payload);
    $c->log->debug('Access token created') if $config->{debug};

    # Issue a refresh token with a unique JTI and register the JTI in the
    # store so the token endpoint can enforce single-use semantics (MED-1).
    my $rt_jti = $_uuid->create_str();
    my $rt_ttl = 30 * 24 * 3600;  # 30 days
    my %refresh_token_payload = (
        sub => $user_claims->{sub},
        aud => $client_id,
        jti => $rt_jti,
        exp => $now + $rt_ttl,
    );

    my $refresh_token = $c->openidconnect->jwt->create_refresh_token(%refresh_token_payload);
    $c->openidconnect->store->store_refresh_token(
        $rt_jti, $user_claims->{sub}, $client_id, $rt_ttl,
    );
    $c->log->debug('Refresh token created and JTI registered') if $config->{debug};

    $c->log->info("Tokens issued for client: $client_id, user: " . $user_claims->{sub});

    # Return tokens
    $self->_json_response( $c, {
        access_token  => $access_token,
        token_type    => 'Bearer',
        id_token      => $id_token,
        expires_in    => 3600,
        refresh_token => $refresh_token,
    });
}

sub _handle_refresh_token_grant {
    my ( $self, $c ) = @_;

    my $config = $c->openidconnect->config;

    $c->log->debug('Processing refresh_token grant') if $config->{debug};

    my $refresh_token = $c->request->params->{refresh_token};
    my $client_id     = $c->request->params->{client_id};
    my $client_secret = $c->request->params->{client_secret};

    unless ( $refresh_token && $client_id && $client_secret ) {
        $c->log->warn('Missing required parameters for refresh token grant');
        return $self->_json_error( $c, 'invalid_request', 'Missing required parameters' );
    }

    $c->log->debug("Refresh token request for client: $client_id") if $config->{debug};

    # Verify client
    my $client = $c->openidconnect->get_client($client_id);
    unless ( $client && slow_eq( $client->{client_secret}, $client_secret ) ) {
        $c->log->warn("Client authentication failed for: $client_id");
        return $self->_json_error( $c, 'invalid_client', 'Client authentication failed' );
    }

    # Verify refresh token
    my $payload;
    try {
        $payload = $c->openidconnect->jwt->verify_token($refresh_token);
        $c->log->debug('Refresh token verified') if $config->{debug};
    }
    catch {
        $c->log->warn("Invalid refresh token: $_");
        return $self->_json_error( $c, 'invalid_grant', 'Invalid refresh token' );
    };

    # Enforce single-use via JTI (MED-1).  All tokens issued after this fix
    # carry a jti registered in the store.  Tokens without a jti (issued before
    # the fix) are rejected to prevent indefinite re-use of old long-lived tokens.
    my $jti = $payload->{jti};
    unless ( defined $jti ) {
        $c->log->warn("Refresh token missing jti claim for client: $client_id");
        return $self->_json_error( $c, 'invalid_grant',
            'Refresh token is not valid (missing jti)' );
    }

    unless ( $c->openidconnect->store->consume_refresh_token($jti) ) {
        $c->log->warn("Refresh token jti already used or revoked: $jti");
        return $self->_json_error( $c, 'invalid_grant',
            'Refresh token has already been used or revoked' );
    }
    $c->log->debug("Refresh token jti consumed: $jti") if $config->{debug};

    # Create new access token
    my $now = time();
    my %new_payload = (
        sub => $payload->{sub},
        aud => $client_id,
        typ => 'at+JWT',  # RFC 9068 — distinguishes access tokens from ID/refresh tokens (NEW-MED-1)
        exp => $now + 3600,
    );

    my $access_token = $c->openidconnect->jwt->create_access_token(%new_payload);
    $c->log->debug('New access token created from refresh token') if $config->{debug};

    # Rotate refresh token: issue a new one with a fresh JTI (MED-1).
    my $new_rt_jti = $_uuid->create_str();
    my $rt_ttl     = 30 * 24 * 3600;
    my %new_rt_payload = (
        sub => $payload->{sub},
        aud => $client_id,
        jti => $new_rt_jti,
        exp => $now + $rt_ttl,
    );
    my $new_refresh_token = $c->openidconnect->jwt->create_refresh_token(%new_rt_payload);
    $c->openidconnect->store->store_refresh_token(
        $new_rt_jti, $payload->{sub}, $client_id, $rt_ttl,
    );
    $c->log->debug('Refresh token rotated') if $config->{debug};

    $c->log->info("Access token refreshed for client: $client_id, user: " . $payload->{sub});

    $self->_json_response( $c, {
        access_token  => $access_token,
        token_type    => 'Bearer',
        expires_in    => 3600,
        refresh_token => $new_refresh_token,
    });
}

sub _error_response {
    my ( $self, $c, $redirect_uri, $error, $error_description, $state ) = @_;

    my $config = $c->openidconnect->config;

    $c->log->warn("OAuth error: $error - $error_description");

    if ($redirect_uri) {
        my $callback_uri = URI->new($redirect_uri);
        $callback_uri->query_form(
            error             => $error,
            error_description => $error_description,
            state             => $state,
        );
        $c->log->debug("Redirecting error response to: " . $callback_uri->as_string) if $config->{debug};
        return $c->response->redirect( $callback_uri->as_string );
    } else {
        return $self->_json_response( $c, {
            error             => $error,
            error_description => $error_description,
        });
    }
}

sub _json_error {
    my ( $self, $c, $error, $error_description ) = @_;

    $c->log->warn("JSON error response: $error - $error_description");
    $c->response->status(400);
    return $self->_json_response( $c, {
        error             => $error,
        error_description => $error_description,
    });
}

sub _json_response {
    my ( $self, $c, $data ) = @_;

    $c->response->content_type('application/json');
    $c->response->body( encode_json($data) );
}

sub _hex_to_base64url {
    my ( $self, $hex_string ) = @_;

    # Remove any spaces or newlines
    $hex_string =~ s/\s+//g;

    # Convert hex to binary
    my $binary = pack('H*', $hex_string);

    # Encode to base64
    my $base64 = encode_base64($binary, '');

    # Convert to base64url (- instead of +, _ instead of /)
    $base64 =~ tr/+\//\-_/;

    # Remove padding
    $base64 =~ s/=+$//;

    return $base64;
}

sub _bigint_to_base64url {
    my ( $self, $hex_str ) = @_;

    return '' unless $hex_str;  # Handle empty/undef

    # Crypt::PK::RSA returns big integers as hex strings (lowercase)
    # Convert directly using the hex-to-base64url method
    return $self->_hex_to_base64url($hex_str);
}

__PACKAGE__->meta->make_immutable;

1;

=head1 AUTHOR

Tim F. Rayner

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of The Artistic License 2.0.

=cut
