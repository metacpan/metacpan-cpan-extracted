# Cloudflare::API::Accounts #

# NAME #

Cloudflare::API::Accounts - list and retrieve Cloudflare accounts

# SYNOPSIS #

```perl
my $accounts=$api->accounts()->list();
my $account=$api->accounts()->get($account_id);
```

# DESCRIPTION #

Account lookups use the token configured on `Cloudflare::API`. They do not require a default account ID on the parent client.

# METHODS #

* **list(%query)** — List visible accounts. Named arguments become Cloudflare query parameters. Returns the decoded `result`; use `full_response => 1` to retain the envelope and pagination `result_info`.
* **get($account_id, %options)** — Retrieve one account by ID. Returns the decoded account `result`. The ID is percent-encoded as a path component; `full_response => 1` returns the envelope.

# ERRORS #

See `Cloudflare::API` for HTTP, transport, Cloudflare envelope, and invalid path-component exceptions.

# SEE ALSO #

[Cloudflare::API](../API.pm.md), [Cloudflare::API::Zones](Zones.pm.md)

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.
