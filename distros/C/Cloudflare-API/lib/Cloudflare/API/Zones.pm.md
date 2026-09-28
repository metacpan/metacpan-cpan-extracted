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

* **list(%query)** — List every visible zone. Named arguments become Cloudflare query parameters. The method follows all pages and returns one flat array reference; a large zone set can require many requests and substantial memory.
* **list_page(%query)** — Return a lazy `HTTP::API::Core::Pagination` object for the zone list. Use `next()` to consume one zone at a time or `all()` to collect the remaining zones.
* **list_page_response(%query)** — Make one list request and return the complete decoded Cloudflare response hash, including `result_info` when Cloudflare supplies it.
* **get($zone_id, %options)** — Retrieve one zone by ID. Returns the decoded zone `result`. The ID is percent-encoded as a path component; `full_response => 1` returns the complete decoded Cloudflare response.

# ERRORS #

See `Cloudflare::API` for HTTP, transport, Cloudflare response, and invalid path-component exceptions.

# SEE ALSO #

[Cloudflare::API](../API.pm.md), [Cloudflare::API::Workers](Workers.pm.md)

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.
