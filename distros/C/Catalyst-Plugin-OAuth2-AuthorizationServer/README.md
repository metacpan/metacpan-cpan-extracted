# Catalyst::Plugin::OAuth2::AuthorizationServer

An MCP-profile OAuth 2.1 Authorization Server for Catalyst: Dynamic Client
Registration, PKCE-S256 `authorization_code` + `refresh_token` grants, RFC 8414
metadata, and HS256 JWT access tokens. Storage, authentication/consent, and
DCR rate-limiting are app-supplied hooks; the distribution carries no
application specifics.

See the module POD for configuration and the hook contract. Designed to layer
alongside `Catalyst::Plugin::JSONRPC::Server` and `Catalyst::Plugin::MCP`.

## Limitations (v1)

Access tokens are signed with a symmetric HMAC algorithm only (`HS256` by
default, or `HS384`/`HS512`). Asymmetric signing and `alg=none` are not
supported and no JWKS is published: this is deliberate for the MCP
single-server profile, where the Authorization Server and Resource Server
share a deployment and a key.

Refresh-token rotation revokes the presented token but does not revoke the
whole token family on a detected reuse (planned enhancement). Apps can call
`revoke_refresh_tokens_for_subject` on logout/deactivation.

Garbage-collecting abandoned Dynamic Client Registrations (clients that never
completed a token exchange) is the host app's concern: the Store has the
visibility to identify them and run the cleanup; this plugin tracks no client
usage.

## Author

Mike Whitaker <mike@altrion.org>

Built with tool assistance from Claude Code/(mostly) Opus 4.8 to accelerate
code generation and maximise test coverage (and reduce typing :D).

With thanks to

- Jesse Vincent for `/superpowers` (<https://github.com/obra/superpowers>) and the
  `AGENTS.md` boilerplate
- Curtis "Ovid" Poe for `/paad` (<https://github.com/Ovid/paad>)

for providing an agentic development framework that keeps code authority
firmly where it belongs.

Iteratively reviewed by Finn Kempers <finn@shadow.cat> with analysis from
ZCode/GLM-5.2.

## License

This library is free software; you can redistribute it and/or modify it
under the terms of the Artistic License, as distributed with Perl.
