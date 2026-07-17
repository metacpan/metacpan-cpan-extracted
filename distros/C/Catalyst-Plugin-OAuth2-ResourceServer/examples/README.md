# OAuth2 resource-server example

A minimal Catalyst app that protects a single endpoint, `/api/whoami`, with
`Catalyst::Plugin::OAuth2::ResourceServer`. The client is self-contained: it
mints its own demo bearer token with `Crypt::JWT` (HS256, using the same
signing key configured in the app), so no separate authorization server is
needed to try this out.

It calls `/api/whoami` three times to show the three outcomes the resource
server distinguishes:

1. **valid token**, a JWT signed with the app's `signing_key`. Verified and
   accepted: `200` with the resolved subject and scopes.
2. **wrong token**, the same claims but signed with a *different* key, so its
   HS256 signature fails to verify. Rejected: `401` with body
   `{"error":"invalid_token"}`.
3. **no token**, no `Authorization` header at all. Rejected with a bare `401`
   (no error body), which is distinct from the bad-signature case above.

## Run it

```
plackup -p 5000 examples/app.psgi
perl examples/client.pl            # or: perl examples/client.pl http://127.0.0.1:5000
```

## Expected output

```
valid token    -> HTTP 200 {"scopes":["example:read"],"subject":"demo-user"}
wrong token    -> HTTP 401 {"error":"invalid_token"}
no token       -> HTTP 401 {}
```
