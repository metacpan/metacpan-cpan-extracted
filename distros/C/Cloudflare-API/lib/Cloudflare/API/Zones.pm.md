# Cloudflare::API::Zones #

# NAME #

Cloudflare::API::Zones - list and retrieve Cloudflare zones

# SYNOPSIS #

```perl
my $zones=$api->zones()->list(status => 'active');
my $zone=$api->zones()->get($zone_id);
```

# DESCRIPTION #

Zone lookups use the token configured on `Cloudflare::API` and do not require its default account ID. Worker routes are managed by `Cloudflare::API::Workers` using an explicit zone ID.

# METHODS #

* **list(%query)** — List visible zones. Named arguments become Cloudflare query parameters. Returns the decoded `result`; use `full_response => 1` to retain the envelope and pagination `result_info`.
* **get($zone_id, %options)** — Retrieve one zone by ID. Returns the decoded zone `result`. The ID is percent-encoded as a path component; `full_response => 1` returns the envelope.

# ERRORS #

See `Cloudflare::API` for HTTP, transport, Cloudflare envelope, and invalid path-component exceptions.

# SEE ALSO #

[Cloudflare::API](../API.pm.md), [Cloudflare::API::Workers](Workers.pm.md)

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.
