# Quick Start Guide

Get started with Catalyst::Plugin::OpenIDConnect in 5 minutes.

## 1. Install

```bash
cd /path/to/catalyst-plugin-openidconnect
cpanm --installdeps .
```

## 2. Generate Keys

```bash
# Generate RSA key pair (2048-bit, suitable for development)
openssl genrsa -out /path/to/private.pem 2048
openssl rsa -in /path/to/private.pem -pubout -out /path/to/public.pem

# Or use the example script
bash example/generate_keys.sh
```

## 3. Configure Your App

Add to your Catalyst application:

```perl
package MyApp;
use Catalyst qw/
    OpenIDConnect
    Session
    Session::Store::File
    Session::State::Cookie
/;

__PACKAGE__->config(
    'Plugin::OpenIDConnect' => {
        issuer => {
            url                => 'http://localhost:5000',
            private_key_file   => '/path/to/private.pem',
            public_key_file    => '/path/to/public.pem',
            key_id             => 'my-key-1',
        },
        clients => {
            'my-client' => {
                client_secret             => 'my-secret',
                redirect_uris             => ['http://localhost:3000/callback'],
                post_logout_redirect_uris => ['http://localhost:3000/logged-out'],
            },
        },
    },
);

# Load the OpenIDConnect controller before setup
use MyApp::Controller::OpenIDConnect;

__PACKAGE__->setup;
```

## 3a. Create the OpenIDConnect Controller

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

This allows Catalyst to properly discover and register all OpenIDConnect routes.

## 3b. Create a Login Action

Your app must have a login action that handles the `back` parameter. The plugin redirects unauthenticated users to your login page, which should redirect back to complete the authentication flow:

```perl
package MyApp::Controller::Auth;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub login : Local {
    my ( $self, $c ) = @_;

    if ( $c->request->method eq 'POST' ) {
        my $username = $c->request->params->{username};

        # In development, accept any username
        if ($username) {
            $c->session->{user} = { username => $username, id => $username };

            # Redirect to 'back' parameter to resume OIDC flow.
            # Validate it to prevent open redirect (only allow relative paths).
            my $back = $c->request->params->{back} || '/';
            $back = '/' unless $back =~ m{^/[^/]};
            return $c->response->redirect( $c->uri_for($back) );
        }

        $c->stash->{error} = 'Username required';
    }

    $c->stash->{template} = 'login.html';
}

1;
```

## 4. Test the Flow

### Step 1: Start Authorization

```bash
curl "http://localhost:5000/openidconnect/authorize?
  response_type=code&
  client_id=my-client&
  redirect_uri=http://localhost:3000/callback&
  scope=openid"
```

When deployed, users visit this URL in their browser and log in.

### Step 2: Simulate Login (get authorization code)

In development, you'd have a login page. For testing, let's assume you got an authorization code: `auth123`

### Step 3: Exchange Code for Tokens

```bash
curl -X POST http://localhost:5000/openidconnect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code&
      code=auth123&
      redirect_uri=http://localhost:3000/callback&
      client_id=my-client&
      client_secret=my-secret"
```

Response:
```json
{
  "access_token": "eyJ...",
  "token_type": "Bearer",
  "id_token": "eyJ...",
  "expires_in": 3600,
  "refresh_token": "eyJ..."
}
```

### Step 4: Get User Info

```bash
curl http://localhost:5000/openidconnect/userinfo \
  -H "Authorization: Bearer <access_token>"
```

Response:
```json
{
  "sub": "user-123",
  "name": "John Doe",
  "email": "john@example.com"
}
```

## 5. Protect Routes

In your controllers, check for authentication:

```perl
sub protected : Local {
    my ( $self, $c ) = @_;
    
    unless ( $c->session->{user} ) {
        return $c->response->redirect( $c->uri_for('/login') );
    }
    
    # User is authenticated
}
```

## 6. Run the Example App

```bash
# Generate keys
bash example/generate_keys.sh

# Run the app
perl example/app.pl

# Visit http://localhost:3000
```

## Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/.well-known/openid-configuration` | GET | Discovery |
| `/openidconnect/authorize` | GET | Authorization |
| `/openidconnect/token` | POST | Token Exchange |
| `/openidconnect/userinfo` | GET | User Info |
| `/openidconnect/jwks` | GET | Public Keys |
| `/openidconnect/logout` | POST | Logout |

## Common Tasks

### Refresh an Access Token

```bash
curl -X POST http://localhost:5000/openidconnect/token \
  -d "grant_type=refresh_token&
      refresh_token=<your_refresh_token>&
      client_id=my-client&
      client_secret=my-secret"
```

### Get Provider Configuration

```bash
curl http://localhost:5000/.well-known/openid-configuration
```

### Use in Your Own Client

See the example app (`example/app.pl`) for a complete implementation.

## Next Steps

1. **Read** [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) for architecture details
2. **Review** [API_REFERENCE.md](API_REFERENCE.md) for complete endpoint documentation
3. **Check** [DEPLOYMENT.md](DEPLOYMENT.md) for production setup
4. **Explore** `example/app.pl` for a working implementation

## Troubleshooting

### Keys not loading
```
Error: "Cannot read private key file"
```
- Check file path is correct
- Verify file exists and is readable
- Ensure it's in PEM format

### Token verification fails
```
Error: "Token verification failed"
```
- Clock skew: sync NTP on all servers
- Wrong issuer: check config URL
- Token expired: check iat/exp claims

### Invalid client
```
Error: "Unknown client"
```
- Verify client_id is in configuration
- Check spelling exactly matches

### CORS errors
```
XMLHttpRequest: No 'Access-Control-Allow-Origin' header
```
- This endpoint doesn't support CORS yet
- For now, the server must redirect rather than XHR request

## Need Help?

- Review the included documentation
- Check the example app for reference implementation
- Look at test files for usage examples
- See DEPLOYMENT.md for production setup

---

**Ready to secure your app with OpenID Connect? You're all set!**
