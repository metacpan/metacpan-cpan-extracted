# Catalyst::Plugin::OAuth2::ResourceServer

An MCP-profile OAuth 2.1 Resource Server for Catalyst: HS256 bearer-JWT
verification (signature, `aud`, `exp`, `iss`), an app subject-resolver hook for
per-request re-validation, scope assertion, and RFC 6750 challenges + an
RFC 9728 protected-resource metadata document. Verification config is
app-supplied; the distribution carries no application specifics.

Pairs with `Catalyst::Plugin::OAuth2::AuthorizationServer` (it mints, this
verifies) via a shared signing key. See the module POD for configuration and
the hook contract.

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
