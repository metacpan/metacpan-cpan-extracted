# Catalyst::Plugin::OpenIDConnect

A Catalyst plugin implementing the OpenID Connect specification. This plugin provides OAuth 2.0 authentication and authorization capabilities with full OIDC compliance.

**Note that this is not an OIDC client plugin**. If that is what you seek, please take a look at the [Catalyst::Plugin::OIDC](https://metacpan.org/pod/Catalyst::Plugin::OIDC) module maintained elsewhere.

**Full disclosure**: this plugin has been written with the aid of Claude Haiku 4.5. A human has been included in the loop throughout, closely monitoring the agent outputs, but this is an early release and mistakes may have crept through. Please create an issue on Github if you find any errors. Thank you!

## Features

- **Authorization Code Flow**: Full support for OpenID Connect authorization code flow
- **Token Endpoint**: Issues ID tokens, access tokens, and refresh tokens
- **UserInfo Endpoint**: Provides authenticated user information claims
- **Discovery Endpoint**: OpenID Connect discovery (/.well-known/openid-configuration)
- **JWT Handling**: Sign and verify JSON Web Tokens with RS256 algorithm
- **State & Nonce**: CSRF protection via state parameter; nonce binding support (client must validate)
- **Session Management**: User session tracking and token refresh
- **Configurable**: Easy configuration via Catalyst config or external files
- **Database Agnostic**: Works with any Catalyst ORM model

## Installation

Install via cpanm:

```bash
cpanm Catalyst::Plugin::OpenIDConnect
```

Or add to your cpanfile:

```
requires 'Catalyst::Plugin::OpenIDConnect';
```

## Quick Start

### 1. Add plugin to your Catalyst app

```perl
package MyApp;
use Catalyst qw/
    -Debug
    OpenIDConnect
    Session
    Session::Store::File
    Session::State::Cookie
/;
```

### 2. Create the OpenIDConnect controller

The plugin requires you to create a controller that extends the plugin's controller.
Create `lib/MyApp/Controller/OpenIDConnect.pm`:

```perl
package MyApp::Controller::OpenIDConnect;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Plugin::OpenIDConnect::Controller::Root' }

__PACKAGE__->meta->make_immutable;

1;
```

Then load it in your main app module before setup:

```perl
package MyApp;
use Catalyst qw/
    -Debug
    OpenIDConnect
    Session
    Session::Store::File
    Session::State::Cookie
/;

# Load the controller before setup
use MyApp::Controller::OpenIDConnect;
```

### 3. Configure in your catalyst.conf

```
<Plugin::OpenIDConnect>
    <issuer>
        url = http://localhost:5000
        private_key_file = /path/to/private_key.pem
        public_key_file = /path/to/public_key.pem
        key_id = my-key-123
    </issuer>
    
    <clients>
        <MyClient>
            client_id = my-client-id
            client_secret = my-client-secret
            redirect_uris = http://localhost:3000/callback
            post_logout_redirect_uris = http://localhost:3000/logged-out
            response_types = code
            grant_types = authorization_code refresh_token
            scope = openid profile email
        </MyClient>
    </clients>
    
    <user_claims>
        sub = user.id
        username = user.username
        name = user.name
        email = user.email
        picture = user.avatar_url
    </user_claims>
</Plugin::OpenIDConnect>
```

### 4. Implement a login action

Your app must have a login action that supports the `back` parameter. When a user is not authenticated, the plugin redirects to your login page with a `back` parameter indicating where to return:

```perl
package MyApp::Controller::Auth;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub login : Local {
    my ( $self, $c ) = @_;

    if ( $c->request->method eq 'POST' ) {
        my $username = $c->request->params->{username};
        my $password = $c->request->params->{password};

        # Validate credentials
        if ( validate_credentials($username, $password) ) {
            my $user = get_user($username);
            $c->session->{user} = $user;

            # IMPORTANT: Redirect to 'back' parameter to resume OIDC flow
            my $back = $c->request->params->{back} || '/';
            return $c->response->redirect($back);
        }

        $c->stash->{error} = 'Invalid credentials';
    }

    $c->stash->{template} = 'login.html';
}

1;
```

### 5. Use in your controllers

```perl
package MyApp::Controller::Protected;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub profile : Local {
    my ( $self, $c ) = @_;
    
    # Check if user is authenticated via OIDC
    unless ( $c->user ) {
        $c->response->redirect( $c->uri_for('/openidconnect/authorize') );
        return;
    }
    
    $c->stash->{user} = $c->user;
}

1;
```

## API Endpoints

### Authorization Endpoint

```
GET /openidconnect/authorize
```

Parameters:
- `response_type` (required): "code"
- `client_id` (required): Client ID
- `redirect_uri` (required): Registered redirect URI
- `scope` (optional): Space-separated list of scopes (default: "openid")
- `state` (recommended): CSRF protection token
- `nonce` (optional): String to bind to session

### Token Endpoint

```
POST /openidconnect/token
Content-Type: application/x-www-form-urlencoded
```

Parameters:
- `grant_type` (required): "authorization_code"
- `code` (required): Authorization code
- `client_id` (required): Client ID
- `client_secret` (required): Client secret
- `redirect_uri` (required): Must match the one used in authorization request

### UserInfo Endpoint

```
GET /openidconnect/userinfo
Authorization: Bearer <access_token>
```

Returns:
```json
{
  "sub": "user-id",
  "name": "User Name",
  "email": "user@example.com",
  "picture": "https://example.com/avatar.jpg"
}
```

### Discovery Endpoint

```
GET /.well-known/openid-configuration
```

Returns the OpenID Connect provider configuration in JSON format.

## Configuration Reference

### Issuer Configuration

- `url`: The issuer URL (used as 'iss' claim in tokens)
- `private_key_file`: Path to RSA private key for signing tokens
- `public_key_file`: Path to RSA public key for verification (auto-derived from private key if not provided)
- `key_id`: Key identifier (used in JWT header)

### Client Configuration

- `client_id`: Unique client identifier
- `client_secret`: Client secret for token endpoint
- `redirect_uris`: Arrayref or whitespace-separated string of URIs the client is permitted to redirect to after authorization. At least one entry is required.
- `post_logout_redirect_uris`: Arrayref or whitespace-separated string of URIs the client is permitted to redirect to after logout. Required when the client will use `post_logout_redirect_uri` at the logout endpoint.
- `response_types`: Space-separated response types (e.g., "code" or "code id_token")
- `grant_types`: Space-separated grant types (e.g., "authorization_code refresh_token")
- `scope`: Space-separated list of scopes the client can request

### User Claims Mapping

Map from OpenID Connect claim names to user object attributes:

```
<user_claims>
    sub = user.id
    name = user.display_name
    email = user.email_address
    email_verified = user.email_confirmed
    phone_number = user.phone
</user_claims>
```

## Standard Claims

Supported OpenID Connect standard claims:

- `sub`: Unique subject identifier
- `name`: Full name
- `given_name`: Given (first) name
- `family_name`: Family (last) name
- `middle_name`: Middle name
- `nickname`: Nickname
- `preferred_username`: Preferred username
- `profile`: Profile URL
- `picture`: Picture/avatar URL
- `website`: Website URL
- `email`: Email address
- `email_verified`: Whether email is verified (boolean)
- `phone_number`: Phone number
- `phone_number_verified`: Whether phone is verified (boolean)
- `gender`: Gender
- `birthdate`: Birth date (YYYY-MM-DD)
- `zoneinfo`: Timezone
- `locale`: Locale/language
- `updated_at`: Profile update timestamp

## Token Refresh

To refresh an access token:

```perl
my $new_tokens = $c->openidconnect->refresh_token(
    client_id     => 'client-id',
    client_secret => 'client-secret',
    refresh_token => 'refresh-token-value'
);
```

## Securing Endpoints

Use Catalyst roles and attributes to protect endpoints:

```perl
sub profile : Local : RequireUser {
    my ( $self, $c ) = @_;
    # User is authenticated, $c->user is available
}
```

## Advanced Topics

### Custom Scope Handling

Implement a custom scope handler:

```perl
$c->openidconnect->scope_handler(sub {
    my ($c, $scope_string) = @_;
    # Custom scope validation/processing
});
```

### Custom Claims Provider

Provide custom user claims:

```perl
$c->openidconnect->claims_provider(sub {
    my ($c, $user) = @_;
    return {
        sub => $user->id,
        name => $user->full_name,
        custom_claim => $user->some_attribute,
    };
});
```



## Testing

Run tests with:

```bash
prove -l t/
```

## License

This module is available under The Artistic License 2.0 (GPL Compatible). See LICENSE file for details.

## Author

Tim F. Rayner
