# Catalyst::Plugin::OpenIDConnect Implementation Guide

## Overview

This is a comprehensive implementation of the OpenID Connect 1.0 specification as a Catalyst plugin architecture. The plugin provides complete OAuth 2.0 and OpenID Connect authentication capabilities.

## Architecture

### Component Structure

```
Catalyst::Plugin::OpenIDConnect/
├── Root Plugin (OpenIDConnect.pm)
│   ├── JWT Handler (Utils/JWT.pm)
│   ├── State Store (Utils/Store.pm)
│   └── Controllers
│       └── Root.pm (Protocol Endpoints)
```

### Core Components

#### 1. **Main Plugin Module** (`Catalyst::Plugin::OpenIDConnect`)

A Moose role that integrates OIDC into Catalyst applications.

**Key Methods:**
- `openidconnect()` - Returns OIDC context for use in controllers
- `_oidc_build_jwt_handler()` - Configures JWT signing/verification
- `setup_component()` - Initializes the plugin
- `finalize_setup()` - Finalizes setup after bootstrapping

**Features:**
- Automatic key loading from configuration
- Public key derivation from private key
- Configurable per-Catalyst-app
- Non-intrusive Moose role architecture

#### 2. **JWT Utility Module** (`Catalyst::Plugin::OpenIDConnect::Utils::JWT`)

Handles JSON Web Token (JWT) operations using RS256 (RSA SHA-256).

**Key Methods:**
- `sign_token(%payload)` - Signs a JWT with the private key
- `verify_token($token)` - Verifies and decodes a JWT
- `create_id_token(%claims)` - Creates an ID token
- `create_access_token(%claims)` - Creates an access token
- `create_refresh_token(%claims)` - Creates a refresh token

**Features:**
- RS256 algorithm (RSA + SHA256)
- RFC 4648 URL-safe Base64 encoding
- Automatic expiration validation
- Standard claims management (iss, aud, exp, iat)
- Signature verification

#### 3. **State Store Module** (`Catalyst::Plugin::OpenIDConnect::Utils::Store`)

In-memory storage for authorization codes, sessions, and tokens.

**Current Implementation:**
- In-memory Perl hashes
- Can be extended for database backends

**Key Methods:**
- `create_authorization_code($client_id, $user, $scope, $redirect_uri, $nonce, $pkce)` - Creates short-lived auth codes; accepts an optional `$pkce` hashref with `code_challenge` and `code_challenge_method` fields
- `consume_authorization_code($code)` - Atomically fetches and deletes the code (one-step); returns the code data hashref or `undef` if not found or expired

**Features:**
- 10-minute authorization code expiration
- Atomic fetch-and-delete prevents TOCTOU races (in-memory uses `delete`; Redis uses `GETDEL`)
- PKCE `code_challenge` persisted with the code and returned by `consume_authorization_code`

#### 4. **Protocol Controller** (`Catalyst::Plugin::OpenIDConnect::Controller::Root`)

Implements the OpenID Connect protocol endpoints.

**Endpoints:**

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/.well-known/openid-configuration` | Discovery endpoint |
| GET | `/openidconnect/authorize` | Authorization endpoint |
| POST | `/openidconnect/token` | Token endpoint |
| GET | `/openidconnect/userinfo` | UserInfo endpoint |
| GET | `/openidconnect/jwks` | JSON Web Key Set |
| POST | `/openidconnect/logout` | Logout endpoint |

## OpenID Connect Flow Implementation

### Authorization Code Flow

The standard, most secure flow for web applications:

```
1. Client redirects user to /openidconnect/authorize with:
   - response_type=code
   - client_id
   - redirect_uri
   - scope
   - state (CSRF protection)
   - nonce (optional, binds to session)
   - code_challenge (required for public clients; recommended for all — see PKCE below)
   - code_challenge_method=S256 (required when code_challenge is supplied)

2. User authenticates (handled by application)

3. Server issues authorization code via redirect

4. Client exchanges code for tokens at /openidconnect/token with:
   - grant_type=authorization_code
   - code
   - redirect_uri
   - client_id
   - client_secret (omit for public clients)
   - code_verifier (required when code_challenge was sent in step 1)

5. Server verifies and issues:
   - id_token (JWT with user claims)
   - access_token (JWT for API access)
   - refresh_token (JWT for token refresh)
   - expires_in
```

### Token Types

#### ID Token
- Contains user identity claims (name, email, etc.)
- Signed JWT (RS256)
- Expires in 1 hour
- Includes nonce (if provided) for CSRF protection

#### Access Token
- Authorization token for API access
- Signed JWT
- Expires in 1 hour
- Contains scope information

#### Refresh Token
- Long-lived token for refreshing access tokens
- Signed JWT
- Expires in 30 days
- Not accessible to browser (HTTP-only cookies in production)

## Configuration

### Issuer Configuration

```perl
<Plugin::OpenIDConnect>
    <issuer>
        url = http://localhost:5000
        private_key_file = /path/to/private.pem
        public_key_file = /path/to/public.pem
        key_id = my-key-123
    </issuer>
```

**Fields:**
- `url` - The issuer identifier (in iss claim)
- `private_key_file` - Path to RSA private key (PEM format)
- `public_key_file` - Path to RSA public key (optional, derived from private)
- `key_id` - Key identifier for JWK Set

### Client Configuration

```perl
<clients>
    <my-client>
        client_secret             = secret123
        redirect_uris             = http://app.example.com/callback
        post_logout_redirect_uris = http://app.example.com/logged-out
        response_types            = code
        grant_types               = authorization_code refresh_token
        scope                     = openid profile email
    </my-client>
</clients>
```

**Fields:**
- `client_secret` - Shared secret for token endpoint
- `redirect_uris` - Arrayref or whitespace-separated string of URIs the client is permitted to redirect to after authorization
- `post_logout_redirect_uris` - Arrayref or whitespace-separated string of URIs the client is permitted to redirect to after logout. Required when the client uses `post_logout_redirect_uri` at the logout endpoint.
- `response_types` - Supported response types (e.g., "code")
- `grant_types` - Supported grant types (e.g., "authorization_code")
- `scope` - Default/allowed scopes

> Both `redirect_uris` and `post_logout_redirect_uris` accept the same formats:
> an arrayref in YAML/JSON/Perl-hash config, or a whitespace-separated string
> in Apache-style (`Config::General`) config. Both are matched by exact string
> comparison — prefix matching and host-only matching are not permitted.

### User Claims Mapping

Map user object attributes to OpenID Connect claims:

```perl
<user_claims>
    sub = id
    name = full_name
    email = email_address
    picture = avatar_url
    email_verified = is_email_verified
</user_claims>
```

The format is: `<oidc_claim> = <user_attribute_path>`

Nested attributes use dot notation: `claims = user.profile.claims`

## Standard OpenID Connect Claims

The plugin supports the following standard claims:

**Profile Claims:**
- `sub` - Subject (unique user identifier)
- `name` - Full name
- `given_name` - Given (first) name
- `family_name` - Family (last) name
- `middle_name` - Middle name
- `nickname` - Nickname
- `preferred_username` - Preferred username
- `profile` - Profile URL
- `picture` - Picture/avatar URL
- `website` - Website URL
- `gender` - Gender
- `birthdate` - Birth date (YYYY-MM-DD)
- `zoneinfo` - Timezone (IANA tz identifier)
- `locale` - Locale/language
- `updated_at` - Profile update time (Unix timestamp)

**Email Claims:**
- `email` - Email address
- `email_verified` - Whether email is verified (boolean)

**Phone Claims:**
- `phone_number` - Phone number (E.164 format)
- `phone_number_verified` - Whether phone is verified (boolean)

**Address Claims:**
- `address` - Physical address (JSON object with formatted, street_address, etc.)

## Extension Points

### Custom Claims Provider

Override claims generated for tokens:

```perl
$c->openidconnect->claims_provider(sub {
    my ($c, $user) = @_;
    return {
        sub => $user->id,
        name => $user->full_name,
        profile_url => $user->profile_link,
        custom_claim => $user->custom_field,
    };
});
```

### Scope Handler

Add custom scope validation:

```perl
$c->openidconnect->scope_handler(sub {
    my ($c, $scope_string) = @_;
    my @scopes = split /\s+/, $scope_string;
    
    # Validate scopes
    for my $scope (@scopes) {
        die "Unknown scope: $scope" unless valid_scope($scope);
    }
    
    return @scopes;
});
```



## Usage in Controllers

### Setting Up the Plugin in Your Application

The plugin provides all OpenIDConnect functionality through a reusable controller. To use it, create an extending controller in your application's namespace.

**Step 1: Create the extending controller** at `lib/MyApp/Controller/OpenIDConnect.pm`:

```perl
package MyApp::Controller::OpenIDConnect;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Plugin::OpenIDConnect::Controller::Root' }

__PACKAGE__->meta->make_immutable;

1;
```

**Step 2: Load the controller in your main app module:**

```perl
package MyApp;
use Catalyst qw/
    OpenIDConnect
    Session
    Session::Store::File
    Session::State::Cookie
/;

# Load the controller before setup
use MyApp::Controller::OpenIDConnect;

MyApp->config(
    'Plugin::OpenIDConnect' => {
        issuer => { ... },
        clients => { ... },
    },
);

MyApp->setup;
```

**Why this approach?**

Catalyst only auto-discovers controllers in the application's namespace. By creating an extending controller in your app's namespace, Catalyst can properly register the routes with the dispatcher. This ensures compatibility with ACL and other route-processing plugins.

### Protecting Routes

Check for authentication in your controllers:

```perl
sub protected : Local {
    my ($self, $c) = @_;
    
    unless ( $c->session->{user} ) {
        return $c->response->redirect( $c->uri_for('/login') );
    }
    
    # User is authenticated
    my $user = $c->session->{user};
}
```

### Accessing OIDC Context

From any controller:

```perl
my $oidc = $c->openidconnect;

# Get client config
my $client = $oidc->get_client('client-id');

# Get user claims
my $claims = $oidc->get_user_claims($user);

# Access JWT handler
my $token = $oidc->jwt->sign_token(sub => 'user-123');

# Access store
my $code = $oidc->store->create_authorization_code(...);
```

### Implementing the Login Action

When the OpenID Connect plugin redirects an unauthenticated user to your login page, it includes a `back` parameter specifying where to return after successful authentication. Your login action **must support the `back` parameter** to resume the authorization flow.

```perl
sub login : Local {
    my ( $self, $c ) = @_;

    if ( $c->request->method eq 'POST' ) {
        my $username = $c->request->params->{username};
        my $password = $c->request->params->{password};

        # Validate credentials against your user store
        if ( validate_user($username, $password) ) {
            my $user = get_user($username);
            
            # Store user in session
            $c->session->{user} = $user;
            $c->session->{user_id} = $user->id;

            # IMPORTANT: Redirect to the 'back' parameter if provided
            # This resumes the authorization flow after authentication.
            # Validate it to prevent open redirect (only allow relative paths).
            my $back = $c->request->params->{back} || '/';
            $back = '/' unless $back =~ m{^/[^/]};
            return $c->response->redirect( $c->uri_for($back) );
        }

        $c->stash->{error} = 'Invalid credentials';
    }

    # Display login form
    $c->stash->{template} = 'login.html';
}
```

The plugin will redirect to your login page like: `/login?back=/openidconnect/authorize`. After successful authentication, redirect back to the `back` URL to resume the authorization process.

## Security Considerations

### HTTPS Requirement
- In production, always use HTTPS for all OIDC endpoints
- Tokens are sensitive and must be transmitted over encrypted connections

### Key Management
- Store private keys securely (file permissions, secrets management)
- Rotate keys periodically
- Publish public keys via JWK Set endpoint

### Token Security
- ID tokens should be verified by clients using the public key
- Access tokens are bearer tokens - handle with care
- Refresh tokens should be stored securely (HTTP-only cookies)

### CSRF Protection
- Always verify the `state` parameter matches the session
- Nonce binding support (client responsibility to validate nonce matches)

### Code Security
- Authorization codes are one-time use only
- Codes expire after 10 minutes
- Code exchange requires client authentication
- Atomic fetch-and-delete in the store layer prevents TOCTOU race conditions

### PKCE (Proof Key for Code Exchange — RFC 7636)
- Public clients (those without a registered `client_secret`) **must** send `code_challenge` and `code_challenge_method=S256` in the authorization request
- Confidential clients are also strongly encouraged to use PKCE
- Only the `S256` method is supported; `plain` is rejected per OAuth 2.1 / security BCP
- The verifier must be 43–128 characters using only unreserved URI characters (`A-Z`, `a-z`, `0-9`, `-`, `.`, `_`, `~`)
- The server verifies `BASE64URL(SHA256(ASCII(code_verifier))) == code_challenge` with a constant-time comparison before issuing tokens

## Testing

Run the included tests:

```bash
# JWT functionality
prove -l t/01_jwt.t

# Store functionality
prove -l t/02_store.t

# All tests
prove -l t/
```

## Example Application

Start the example app:

```bash
# Generate RSA keys
bash example/generate_keys.sh

# Run the application
perl example/app.pl

# Visit http://localhost:3000
```

The example includes:
- Simple login page
- Protected resource
- Catalyst integration demo
- Fully working OIDC endpoints

## Database Integration

The current implementation uses in-memory storage. For production, extend the Store:

```perl
package MyApp::Store::OIDC;
use Moose;
extends 'Catalyst::Plugin::OpenIDConnect::Utils::Store';

sub create_authorization_code {
    my ($self, $client_id, $user, $scope, $redirect_uri, $nonce) = @_;
    
    # Store in database instead of memory
    my $code = $self->_generate_code();
    
    $c->model('DB::AuthCode')->create({
        code => $code,
        client_id => $client_id,
        user_id => $user->id,
        # ...
    });
    
    return $code;
}
```

## Troubleshooting

### Keys not loading
- Verify file paths in configuration
- Check file permissions (should be readable)
- Ensure PEM format (-----BEGIN RSA PRIVATE KEY-----)

### Token verification fails
- Check that public/private keys are paired
- Verify issuer URL matches configuration
- Check token expiration

### Code not found
- Authorization codes are one-time use
- Codes expire after 10 minutes
- Verify code value is correct (typos)

### CSRF errors
- Always include `state` parameter
- Verify state value matches session
- Check redirect_uri matches registered URI

## References

- OpenID Connect 1.0 Specification: https://openid.net/connect/
- OAuth 2.0 RFC 6749: https://tools.ietf.org/html/rfc6749
- JWT RFC 7519: https://tools.ietf.org/html/rfc7519
- JWA RFC 7518: https://tools.ietf.org/html/rfc7518

## Future Enhancements

- [ ] Implicit and Hybrid flows
- [ ] Form post response mode
- [ ] PKCE support
- [ ] Client registration endpoint
- [ ] Introspection endpoint
- [ ] Revocation endpoint
- [ ] DB-backed session store
- [ ] Multi-key support
- [ ] HS256 algorithm support
- [ ] Request object support
- [ ] Token endpoint authentication methods
- [ ] Subject type pairwise support

## License

This implementation is available under The Artistic License 2.0 (GPL Compatible). See LICENSE file for details.

## Author

Tim F. Rayner
