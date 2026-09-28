# Cloudflare::API::SecretsStore #

# NAME #

Cloudflare::API::SecretsStore - manage Cloudflare Secrets Store resources

# SYNOPSIS #

```perl
my $store=$api->secrets_store();
my $stores=$store->list_stores();
my $secret=$store->create_secret($store_id, [{
    name   => 'API_KEY',
    value  => $secret_value,
    scopes => ['workers']
}]);
```

# DESCRIPTION #

These account-scoped methods manage stores, secret metadata, write-only secret values, and quota. Cloudflare does not return a secret's value through `get_secret()`. Keep values out of logs, command lines, and source control.

# METHODS #

* **list_stores(%query)** — List every store with named query filters. The method follows all pages and returns one flat array reference; a large result set can require many requests and substantial memory.
* **list_stores_page(%query)** — Return a lazy `HTTP::API::Core::Pagination` object. Use `next()` to consume one store at a time.
* **list_stores_page_response(%query)** — Make one list request and return the complete decoded Cloudflare response hash, including `result_info` when supplied.
* **get_store($id, %options)** — Retrieve a store by ID and return its `result`.
* **create_store(\%body, %options)** — POST a store definition and return its `result`.
* **delete_store($id, %options)** — DELETE a store and return the endpoint's `result`, possibly `undef` for an empty body.
* **list_secrets($store_id, %query)** — List all secret metadata in one store with named query filters. The method follows all pages and returns one flat array reference; a large result set can require many requests and substantial memory.
* **list_secrets_page($store_id, %query)** — Return a lazy `HTTP::API::Core::Pagination` object. Use `next()` to consume one secret metadata item at a time.
* **list_secrets_page_response($store_id, %query)** — Make one list request and return the complete decoded Cloudflare response hash, including `result_info` when supplied.
* **get_secret($store_id, $secret_id, %options)** — Return one secret's metadata in `result`; its value is not available.
* **create_secret($store_id, \@secrets, %options)** — POST a non-empty array reference, even when creating one secret. Each entry should supply `name`, `value`, and `scopes` such as `['workers']`; `comment` is optional. Returns `result`.
* **update_secret($store_id, $secret_id, \%body, %options)** — PATCH a secret with fields such as `value`, `scopes`, or `comment`. Returns `result`.
* **delete_secret($store_id, $secret_id, %options)** — DELETE a secret and return the endpoint's `result`, possibly `undef` for an empty body.
* **get_quota(%options)** — Retrieve the account's Secrets Store usage and return `result`.

Non-list JSON methods accept `full_response => 1` for the complete decoded Cloudflare response. IDs are percent-encoded as path components. Create-store and update-secret bodies must be hash references; `create_secret()` requires a non-empty array reference. The module passes accepted field details through to Cloudflare.

# ERRORS #

Missing account context, invalid identifiers or body shapes, HTTP and transport failures, and Cloudflare response failures cause exceptions as described in `Cloudflare::API`.

# SEE ALSO #

[Cloudflare::API](../API.pm.md), [Cloudflare::API::Workers](Workers.pm.md)

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.
