# Changelog

All notable changes to this project will be documented in this file.

## [0.08] - 2026-04-29 (Security Fix: MED-6)

### Security

- **MED-6 fixed — Missing HTTP security headers on all responses**
  (`Controller::Root`).  A `begin : Private` action now runs before every OIDC
  endpoint and sets five response headers:
  - `Cache-Control: no-store` — mandatory per RFC 6749 §5.1 on token responses;
    applied globally so future endpoints cannot accidentally omit it.
  - `Pragma: no-cache` — HTTP/1.0 compatibility.
  - `X-Content-Type-Options: nosniff` — prevents MIME-type sniffing on all
    OIDC responses.
  - `X-Frame-Options: DENY` — guards the authorization endpoint HTML page
    against clickjacking.
  - `Content-Security-Policy: frame-ancestors 'none'` — modern equivalent of
    `X-Frame-Options` for browsers that support CSP Level 2+.

## [0.07] - 2026-04-29 (Security Fix: MED-1)

### Security

- **MED-1 fixed — Non-revocable refresh tokens** (`Controller::Root`,
  `Utils::Store`, `Utils::Store::Redis`, `Role::Store`).  Refresh tokens are
  now bound to a unique JTI (UUID v4) that is stored server-side with a TTL
  matching the 30-day token lifetime.  On every use the JTI is atomically
  consumed from the store (Perl `delete` for the in-memory backend;
  Redis `GETDEL` for the Redis backend) and a new JTI + refresh token are
  issued immediately (refresh token rotation).  A second attempt to use the
  same refresh token receives `invalid_grant`.  On logout, all outstanding JTIs
  for the user are deleted via a secondary per-subject index, invalidating any
  stolen tokens immediately.  The `Role::Store` interface gains three new
  required methods: `store_refresh_token`, `consume_refresh_token`, and
  `revoke_refresh_tokens_for_user`.

## [0.06] - 2026-04-29 (Security Fixes: MED-2, MED-3, MED-4, MED-5)

### Security

- **MED-2 fixed — Sensitive claims logged at debug level** (`Utils::JWT`).
  `sign_token` previously serialised the entire JWT payload (which may include
  PII such as email addresses, names, and user identifiers) to the debug log.
  The log statement now emits only non-sensitive metadata: `sub`, `aud`, and
  `exp`. PII-bearing claims are never written to any log output.

- **MED-3 fixed — Package-level global state shared across application classes**
  (`Catalyst::Plugin::OpenIDConnect`). The JWT handler and store were stored in
  `our $_oidc_jwt_instance` / `our $_oidc_store_instance` — package-level
  globals shared across all Catalyst applications in the same interpreter.
  These are replaced by per-application-class lexical hashes
  (`%_oidc_jwt_by_class`, `%_oidc_store_by_class`) keyed by the consuming
  class name (`ref($self) || $self`). Multiple Catalyst apps in the same process
  now each hold their own isolated JWT and store instances.

- **MED-4 fixed — Implicit grant/response types advertised in discovery**
  (`Context`). The discovery document listed `implicit` in
  `grant_types_supported` and `id_token`/`token` values in
  `response_types_supported`. The implicit flow is deprecated by OAuth 2.0
  Security BCP (RFC 9700) and removed from OAuth 2.1. Both lists now advertise
  only the flows this server actually implements: `authorization_code` and
  `refresh_token` grants, and `code` as the sole response type.

- **MED-5 fixed — Session copy of authorization code never cleaned up**
  (`Controller::Root`). The authorize endpoint wrote a copy of each issued code
  and its associated claims/scope/nonce into `$c->session->{oidc_code}`. This
  entry was never removed, causing stale PII to accumulate in the session store
  indefinitely. `_handle_authorization_code_grant` now calls
  `delete $c->session->{oidc_code}->{$code}` immediately after the code is
  successfully consumed.

### Tests

- **`t/01_jwt.t`** (4 new tests, 24 total) — MED-2: capturing logger verifies
  the `sign_token` debug message does not contain email or name fields, and does
  contain `sub` and `aud`.
- **`t/03_plugin.t`** (7 new tests) — MED-3: two distinct "application class"
  objects verified to hold isolated JWT instances; MED-4: discovery document
  verified to not contain `implicit` in grant types or implicit response types,
  and to still contain `authorization_code` / `code`.

---

## [0.05] - 2026-04-29 (Security Fixes: HIGH-1 through HIGH-5)

### Security

- **HIGH-1 fixed — Open Redirect in example login action** (`example/app.pl`).
  The `back` parameter was forwarded to `$c->response->redirect` without
  validation, allowing an attacker to craft a login URL that redirected the
  victim to an arbitrary external site after authentication. The parameter is
  now validated with `m{^/[^/]}` (must start with `/` followed by a
  non-`/` character) to reject both absolute URLs and protocol-relative `//`
  paths, and the redirect is issued via `$c->uri_for($back)`.

- **HIGH-2 fixed — Missing mandatory JWT claim validation** (`Utils::JWT`).
  `verify_token` previously only checked `exp` and `iss` when those claims were
  present. Both are now mandatory: tokens missing `exp` or `iss` are rejected;
  an expired `exp` is always rejected; an `iss` that does not match the
  configured issuer URL is rejected; `nbf` (not-before), when present, is
  enforced. An optional `expected_audience` parameter was also added: when
  supplied, the `aud` claim must be present and must match.

- **HIGH-3 fixed — Timing-vulnerable client secret comparison** (`Controller::Root`).
  The `eq` operator was used to compare client secrets at the token endpoint,
  leaking secret length and prefix information through timing side-channels.
  Both the authorization-code grant and the refresh-token grant now use
  `Crypt::Misc::slow_eq()` for constant-time comparison. `Crypt::Misc` added to
  `cpanfile`.

- **HIGH-4 fixed — TOCTOU race in authorization code redemption** (`Utils::Store`,
  `Utils::Store::Redis`, `Controller::Root`). The previous implementation called
  `get_authorization_code` followed by a separate `consume_authorization_code`,
  creating a window where two concurrent requests could both read the same code
  before either deleted it. `consume_authorization_code` is now a single atomic
  operation that fetches and deletes in one step (Perl `delete` for the
  in-memory store; Redis `GETDEL` (≥ 6.2) for the Redis store) and returns the
  code data hashref. The controller now calls only `consume_authorization_code`;
  the two-step pattern has been removed. `Role::Store` updated accordingly.

- **HIGH-5 fixed — No PKCE support** (`Controller::Root`, `Utils::Store`,
  `Utils::Store::Redis`, `Role::Store`). Full RFC 7636 PKCE implementation added:

  - **Authorize endpoint**: reads `code_challenge` and `code_challenge_method`
    from request parameters; persists them in the session so they survive the
    login redirect; enforces that public clients (those without a `client_secret`)
    **must** supply `code_challenge`; rejects any method other than `S256`
    (`plain` is not supported per OAuth 2.1 / security BCP); stores the
    challenge with the authorization code in both store backends.
  - **Token endpoint**: reads `code_verifier` from the POST body; after atomically
    consuming the code, verifies the challenge with
    `BASE64URL(SHA256(ASCII(code_verifier))) == code_challenge` using a
    constant-time comparison (`Crypt::Misc::slow_eq`); returns `invalid_grant`
    on failure.
  - **`_verify_pkce($verifier, $challenge)`** — private helper enforces verifier
    format (43–128 unreserved URI characters: `A-Z`, `a-z`, `0-9`, `-`, `.`,
    `_`, `~`) before computing and comparing the S256 challenge.
  - Both `Utils::Store` and `Utils::Store::Redis` accept an optional `$pkce`
    hashref in `create_authorization_code` and persist `code_challenge` /
    `code_challenge_method` with the code entry.

### Tests

- **`t/01_jwt.t`** (10 new tests, 20 total) — tests for `verify_token` mandatory
  claim enforcement: missing `exp`, expired token, missing `iss`, wrong issuer,
  future `nbf`, past `nbf`, `expected_audience` match, wrong audience, missing
  `aud` with `expected_audience`, missing `aud` without `expected_audience`.

- **`t/02_store.t`** (updated) — `consume_authorization_code` verified to return
  code data; second consume verified to return `undef`. Added PKCE round-trip
  tests: `code_challenge`/`code_challenge_method` stored and returned; no-PKCE
  case verified to leave those fields absent.

- **`t/04_store_redis.t`** (updated) — `MockRedis` gained a `getdel` method;
  tests confirm `GETDEL` is used (not `del`), consume returns data, second
  consume returns `undef`. Added PKCE round-trip tests through JSON
  serialization.

- **`t/06_pkce.t`** (new, 11 tests) — unit tests for `_verify_pkce`: correct
  verifier/challenge pair accepted; wrong verifier rejected; verifier too short
  (< 43) rejected; verifier too long (> 128) rejected; verifier with disallowed
  characters rejected; `undef` verifier rejected; `undef` challenge rejected;
  minimum (43-char) and maximum (128-char) length cases accepted; all unreserved
  char types accepted; tampered challenge rejected.

### Documentation

- **`API_REFERENCE.md`** — Authorization endpoint parameter table updated with
  `code_challenge` (Conditional) and `code_challenge_method` rows; token
  endpoint authorization-code grant table updated with `code_verifier`
  (Conditional) row and `client_secret` changed from Required to Conditional.
  New "PKCE-Protected Authorization Code Flow" example section added.
- **`IMPLEMENTATION_GUIDE.md`** — Authorization Code Flow steps updated with
  PKCE parameters; State Store module docs updated with accurate signatures and
  atomic-operation note; login action example updated with safe `back`
  validation; new PKCE subsection added under Security Considerations.
- **`QUICKSTART.md`** — Login action example updated with validated `back`
  redirect pattern.

---

## [0.04] - 2026-04-29 (Security Fix: Open Redirect in Logout Endpoint)

### Security

- **CRIT-1 fixed — Open Redirect in logout endpoint** (`Controller::Root`,
  `Utils::JWT`). The `post_logout_redirect_uri` parameter was previously
  forwarded without any validation, allowing an attacker to redirect victims to
  an arbitrary external URL after logout (phishing / credential harvesting).

  The logout flow now enforces the following rules, in line with OpenID Connect
  RP-Initiated Logout 1.0:

  1. `post_logout_redirect_uri` is rejected with `invalid_request` unless
     `id_token_hint` is also supplied.
  2. The hint token's RSA signature is verified to confirm it was genuinely
     issued by this server. Expiry is intentionally **not** checked — hint
     tokens are frequently expired at logout time by design.
  3. The `aud` claim of the verified hint identifies the requesting client.
     The `post_logout_redirect_uri` is then compared by **exact string match**
     against that client's registered `post_logout_redirect_uris` list.
     Prefix matching and host-only matching are not permitted.
  4. Any mismatch returns an `invalid_request` OAuth error; no redirect is
     issued.
  5. When a redirect is permitted, the optional `state` parameter is appended
     verbatim to the redirect URI as required by the specification.

### Added

- **`JWT::decode_id_token_hint($token)`** — new method on
  `Catalyst::Plugin::OpenIDConnect::Utils::JWT`. Verifies the token signature
  against the configured public key and returns the decoded claims hashref, or
  `undef` if the token is malformed or the signature is invalid. Distinct from
  `verify_token` in that it does not reject expired tokens.

- **`Controller::Root::_allowed_post_logout_uris($client)`** — private helper
  that normalises the `post_logout_redirect_uris` client config field from
  either an arrayref (YAML/JSON config) or a whitespace-delimited string
  (Config::General-style config) into a flat list of URIs.

- **`post_logout_redirect_uris` client config key** — each client may now
  declare a list of permitted post-logout redirect URIs. This key is required
  for clients that use `post_logout_redirect_uri` at the logout endpoint.

### Tests

- **`t/05_logout.t`** (new, 19 tests) — covers `decode_id_token_hint` for valid
  tokens, expired tokens, tampered tokens, wrong-key tokens, and structurally
  invalid JWTs; and `_allowed_post_logout_uris` for arrayref config, string
  config, missing config, and exact-match security semantics (prefix-of-registered
  and extended-path attacks).

### Documentation

- **`API_REFERENCE.md`** — Logout endpoint section rewritten with updated
  parameter table (marking `id_token_hint` as conditionally required), security
  note on exact-match validation, split request/response examples, full error
  response examples, and a client registration code snippet.
- **`README.md`** — Client configuration reference updated with the new
  `post_logout_redirect_uris` field.
- **`IMPLEMENTATION_GUIDE.md`** — Client configuration example and field list
  updated with `post_logout_redirect_uris`.
- **`DEPLOYMENT.md`** — Production `catalyst.conf` example updated with
  `post_logout_redirect_uris`.
- **`QUICKSTART.md`** — Quick-start Perl config example updated with
  `post_logout_redirect_uris`.
- **`example/app.pl`** — Both example clients now include
  `post_logout_redirect_uris`.

---

## [0.03] - 2026-04-24 (FastCGI / Multi-Process Store Support)

### Added

- **Catalyst::Plugin::OpenIDConnect::Role::Store** - New Moose role defining the
  pluggable store interface. Any store backend must `with` this role and implement
  three methods: `create_authorization_code`, `get_authorization_code`,
  `consume_authorization_code`. This decouples the plugin from a specific
  backend implementation.

- **Catalyst::Plugin::OpenIDConnect::Utils::Store::Redis** - Redis-backed store
  implementation for multi-process deployments (FastCGI, pre-forking servers).
  - Stores authorization codes in Redis with native TTL expiry via `SETEX`
  - Lazy Redis connection (opened after `fork()` so each worker has its own socket)
  - Supports `Redis::Fast` (preferred) or `Redis` client, auto-detected at runtime
  - Configurable key prefix for namespace isolation on shared Redis instances
  - Configurable code TTL (default 600 s)
  - Optional Redis `AUTH` password support
  - Blessed user objects serialised via `convert_blessed` JSON encoding

- **Configurable store class in plugin setup** - `Plugin::OpenIDConnect` config
  now accepts `store_class` and `store_args` keys, allowing any Role::Store
  consumer to be used as the backend without touching application code.

- **`Module::Runtime::require_module`** used for dynamic store class loading,
  replacing manual `s{::}{/}g` path mangling. Works correctly regardless of
  `@INC` ordering or non-filesystem module sources.

- **`Bytes::Random::Secure`** used for authorization code generation in both the
  memory and Redis store backends, replacing the previous `rand`-based generator.
  Codes are now drawn from the OS CSPRNG (`/dev/urandom`) and are safe to
  generate after `fork()`.

### Changed

- **`Catalyst::Plugin::OpenIDConnect::Utils::Store`** now consumes
  `Role::Store`, documents its multi-process limitation, and uses
  `Bytes::Random::Secure` for code generation.

- **`_oidc_store` accessor** now validates via `DOES('Role::Store')` instead of
  `isa('Utils::Store')`, accepting any conforming backend.

- **`Catalyst::Plugin::OpenIDConnect::Context::store()`** lazy initialisation
  now respects `store_class`/`store_args` config rather than always instantiating
  the in-memory store.

- **`Module::Runtime`** added as a declared dependency in `cpanfile`.
  `Bytes::Random::Secure` added as a core dependency. `Redis::Fast`/`Redis`
  listed as optional recommended dependencies under the `redis` feature.

### Tests

- **`t/02_store.t`** extended with: Role::Store compliance check, expiry
  enforcement, double-consume safety, CSPRNG uniqueness across 20 codes,
  `created_at`/`expires_at` field assertions, and missing-code undef check.

- **`t/04_store_redis.t`** (new) — 46 tests for the Redis store using an
  in-process `MockRedis` stub (no live Redis required). Covers: role compliance,
  create/get/consume lifecycle, `setex`/`del` call verification, key prefix and
  TTL configuration, code uniqueness, and corrupt-JSON graceful handling.

### Documentation

- **`DEPLOYMENT.md`** updated with a new "Redis Store (FastCGI and Multi-Process
  Deployments)" section covering installation, `catalyst.conf` and Perl hash
  config examples, production Redis hardening checklist (auth, TLS, memory
  policy, AOF persistence, namespacing), fork-safety explanation, custom backend
  table, updated Docker Compose example with a `redis:7-alpine` service, and
  three new troubleshooting entries.

---

## [0.02] - 2026-04-16 (Bug Fixes & Integration Improvements)

### Changed

- **Controller Integration**: Plugin now requires applications to create an extending controller in the app's namespace for proper route discovery. This ensures compatibility with Catalyst::Plugin::ACL and other route-processing plugins.
  - The plugin's controller (`Catalyst::Plugin::OpenIDConnect::Controller::Root`) is now a base class
  - Applications must create `lib/MyApp/Controller/OpenIDConnect.pm` that extends the plugin controller
  - This allows Catalyst to properly auto-discover routes and prevents dispatcher conflicts

- **Plugin Namespace Configuration**: Moved namespace configuration from extending controller to the base plugin controller
  - Base controller now sets `namespace => 'openidconnect'` by default
  - Extending controllers automatically inherit this configuration
  - Simplifies application setup

- **Simplified Plugin Lifecycle**: Changed from `setup_component`/`finalize_setup` to `after 'setup'` method modifier
  - Uses proper Moose role syntax for plugin hooks
  - Ensures correct execution order with other plugins like ACL

### Fixed

- Fixed "traversal hit a dead end" error when using plugin with existing apps that have route-processing plugins (ACL, etc.)
- Fixed plugin initialization to gracefully handle missing configuration
- Improved error handling for missing private key configuration

### Documentation

- Updated QUICKSTART.md with controller setup instructions
- Updated README.md with extending controller example
- Updated IMPLEMENTATION_GUIDE.md with detailed integration steps
- Updated DEPLOYMENT.md with production controller setup

---

## [0.01] - 2026-04-10 (Initial Release)

### Added

#### Core Implementation
- **Catalyst::Plugin::OpenIDConnect** - Main plugin module
  - Moose role for seamless Catalyst integration
  - Configuration management via catalyst.conf
  - Automatic JWT handler initialization
  - State store management
  - OIDC context object for controllers

- **Catalyst::Plugin::OpenIDConnect::Utils::JWT** - JWT utilities
  - RS256 (RSA SHA-256) signing algorithm
  - Token verification with signature validation
  - Support for ID tokens, access tokens, refresh tokens
  - URL-safe Base64 encoding (RFC 4648)
  - Standard claims handling (iss, aud, exp, iat, sub)
  - Debug decoding without verification

- **Catalyst::Plugin::OpenIDConnect::Utils::Store** - State management
  - In-memory authorization code storage
  - User session management
  - UUID-based session IDs
  - Automatic expiration handling
  - Code consumption (one-time use)
  - Cleanup utilities for expired entries

- **Catalyst::Plugin::OpenIDConnect::Controller::Root** - Protocol endpoints
  - Authorization endpoint (GET /openidconnect/authorize)
  - Token endpoint (POST /openidconnect/token)
  - UserInfo endpoint (GET /openidconnect/userinfo)
  - Discovery endpoint (GET /.well-known/openid-configuration)
  - JWKS endpoint (GET /openidconnect/jwks)
  - Logout endpoint (POST /openidconnect/logout)

#### OAuth 2.0 & OpenID Connect Features
- Authorization Code Flow (full implementation)
- Token Exchange
  - authorization_code grant type
  - refresh_token grant type
- State parameter (CSRF protection)
- Nonce binding
- PKCE-ready (for future implementation)
- Standard claims support
  - Profile claims (name, email, picture, etc.)
  - Email verification
  - Phone verification
  - Address claims
- Token types
  - ID tokens (with user claims)
  - Access tokens (for API access)
  - Refresh tokens (for token refresh)

#### Configuration
- YAML-based configuration via catalyst.conf
- Issuer configuration
  - URL for iss claim
  - RSA private/public key loading
  - Key ID for JWT headers
- Client configuration
  - client_id and client_secret
  - redirect_uris (multiple allowed)
  - response_types and grant_types
  - Scope declarations
- User claims mapping
  - Flexible attribute mapping to OIDC claims
  - Nested attribute support via dot notation
  - Optional claim definitions

#### Security Features
- HTTPS support (via reverse proxy)
- CSRF protection (state parameter)
- Authorization code expiration (10 minutes)
- One-time code consumption
- Session management with expiration
- Bearer token authentication
- JWT signature verification
- Client secret validation
- Redirect URI validation

#### Documentation
- **README.md** - Feature overview and quick start
- **QUICKSTART.md** - 5-minute getting started guide
- **IMPLEMENTATION_GUIDE.md** - Architecture and design decisions
- **API_REFERENCE.md** - Complete endpoint documentation
- **DEPLOYMENT.md** - Production deployment guide
- Inline POD documentation in all modules

#### Tests
- JWT functionality tests (01_jwt.t)
  - Token signing validation
  - Token verification validation
  - Token decoding
  - Invalid token rejection
  - Payload matching
- Store functionality tests (02_store.t)
  - Authorization code creation
  - Code retrieval and validation
  - Code consumption
  - Session management

#### Example Application
- **example/app.pl** - Working Catalyst application
  - Login page (demo login without password)
  - Protected resource example
  - Logout functionality
  - User session management
  - Three configured example clients
- **example/generate_keys.sh** - RSA key generation script
- **example/root/** - HTML templates
  - index.html (home page)
  - login.html (login form)
  - protected.html (protected resource)

#### Project Files
- **cpanfile** - Comprehensive dependency declarations
  - Catalyst and related modules
  - Cryptography libraries
  - JSON processing
  - Testing dependencies
- **dist.ini** - Distribution configuration for CPAN publishing
- Project structure ready for publication

### Implementation Details

#### Algorithm Support
- RS256 (RSA SHA-256) for all JWT operations
- 2048-bit RSA keys (4096-bit recommended for production)

#### Token Lifetimes
- Authorization codes: 10 minutes
- ID tokens: 1 hour
- Access tokens: 1 hour
- Refresh tokens: 30 days
- Sessions: 24 hours (configurable)

#### Standard Claims
- Supported: sub, name, given_name, family_name, email, picture, phone_number, etc.
- User-configurable mapping from application models
- Optional claims support

#### Endpoints
- All endpoints return JSON except authorization (redirects)
- Proper HTTP status codes (200, 302, 400, 401, 500)
- RFC 6749 & RFC 6750 compliance
- OpenID Connect 1.0 Core compliance

### Known Limitations

- In-memory state store (database integration requires extension)
- Single key at a time (key rotation requires restart)
- No HS256 support (RS256 only)
- No Implicit or Hybrid flows
- No PKCE (for public clients)
- No form_post response mode
- No client registration endpoint
- No introspection endpoint

### Requirements

- Perl 5.20 or higher
- Catalyst 5.90100 or higher
- Moose and related modules
- Crypt::OpenSSL modules
- JSON::MaybeXS
- HTTP::Request and LWP stack

### Testing

All modules have unit test coverage. Run tests with:

```bash
prove -l t/
```

### Future Roadmap

- [ ] PKCE support for public clients
- [ ] Implicit and Hybrid flow support
- [ ] Multiple simultaneous keys
- [ ] Database-backed session store
- [ ] Introspection endpoint
- [ ] Revocation endpoint
- [ ] Client metadata endpoint
- [ ] HS256 algorithm support
- [ ] Multi-signature support
- [ ] Request object support
- [ ] Pushed Authorization Requests (PAR)
- [ ] OpenID Connect Federation support

### Author

Tim F. Rayner

### License

This library is available under The Artistic License 2.0 (GPL Compatible). See LICENSE file for details.
