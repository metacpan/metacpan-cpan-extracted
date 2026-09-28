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

* **list(%query)** — List every visible account. Named arguments become Cloudflare query parameters. The method follows all pages and returns one flat array reference; a large account set can require many requests and substantial memory.
* **list_page(%query)** — Return a lazy `HTTP::API::Core::Pagination` object for the account list. Use `next()` to consume one account at a time or `all()` to collect the remaining accounts.
* **list_page_response(%query)** — Make one list request and return the complete decoded Cloudflare response hash, including `result_info` when Cloudflare supplies it.
* **get($account_id, %options)** — Retrieve one account by ID. Returns the decoded account `result`. The ID is percent-encoded as a path component; `full_response => 1` returns the complete decoded Cloudflare response.

# ERRORS #

See `Cloudflare::API` for HTTP, transport, Cloudflare response, and invalid path-component exceptions.

# SEE ALSO #

[Cloudflare::API](../API.pm.md), [Cloudflare::API::Zones](Zones.pm.md)

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.
