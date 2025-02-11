# Catalyst::Plugin::OIDC

This plugin makes it easy to integrate the OpenID Connect protocol into a Catalyst application.

It essentially uses the [OIDC-Client](https://metacpan.org/dist/OIDC-Client) distribution.

## Features

- creates the endpoint used by the provider to redirect the user back to your application
- retrieves the provider metadata and JWK keys when the application is launched
- redirects the browser to the authorize URL to initiate an authorization code flow
- gets the token(s) from the provider
- manages the session : the tokens are stored to be used for next requests
- refreshes access token if needed
- verifies a JWT token with support for automatic JWK key rotation
- gets the user information from the *userinfo* endpoint
- exchanges the access token
- redirects the browser to the logout URL

## Documentation

- [Plugin documentation](https://metacpan.org/pod/Catalyst::Plugin::OIDC)
- [Configuration](https://metacpan.org/pod/OIDC::Client::Config)

## Security Recommendation

When using Catalyst::Plugin::OIDC, it is highly recommended to configure the framework to store session data, including sensitive tokens such as access and refresh tokens, on the backend rather than in client-side cookies. Although cookies can be signed and encrypted, storing tokens in the client exposes them to potential security threats.

## Limitations

- no multi-audience support
- no support for Implicit or Hybrid flows (applicable to front-end applications only and deprecated)
