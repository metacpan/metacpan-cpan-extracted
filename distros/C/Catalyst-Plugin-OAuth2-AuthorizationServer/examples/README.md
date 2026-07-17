# OAuth 2.0 authorization-server example

A minimal Catalyst app that mounts the plugin's authorization-server endpoints
(metadata, dynamic client registration, authorize, token) with an in-memory
`Store` and a fixed-user auto-consent hook. The client walks the full
authorization-code + PKCE (S256) flow: it dynamically registers a client,
drives the `/oauth/authorize` request, captures the redirected `code`, and
exchanges it at `/oauth/token` for a JWT access token.

## Run it

```
plackup -p 5000 examples/app.psgi
perl examples/client.pl            # or: perl examples/client.pl http://127.0.0.1:5000
```

## Expected output

```
registered client_id=2rdgYIz_Fmef4h4ooaJreA
got authorization code=peipyr0wDuNt-8cadWiMPbTgRLLJyGpBjbvhTGEWZqk
access_token (JWT): eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJ1cm46ZXhhbXBsZTpyZXNvdXJjZSIsImV4cCI6MTc4NDEyMTg2NCwiaWF0IjoxNzg0MTIwOTY0LCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjUwMDAiLCJzY29wZSI6ImV4YW1wbGU6cmVhZCIsInN1YiI6ImRlbW8tdXNlciJ9.Dzew9--rhw0I48AcPg_H0wKrUVukCX9uEP3EZ4_D9dw
token_type=Bearer expires_in=900 scope=example:read
```

`client_id`, the authorization `code`, and the JWT are freshly generated on
every run, so the exact values above will differ between runs; the shape
(a `client_id`, a `code`, then a JWT `access_token` with `expires_in=900` and
`scope=example:read`) is what to expect.
