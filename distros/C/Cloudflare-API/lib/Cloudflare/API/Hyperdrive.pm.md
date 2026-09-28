# Cloudflare::API::Hyperdrive #

# NAME #

Cloudflare::API::Hyperdrive - manage Hyperdrive connection configurations

# SYNOPSIS #

```perl
my $configs=$api->hyperdrive()->list_configs();
my $config=$api->hyperdrive()->get_config($config_id);
```

# DESCRIPTION #

These account-scoped REST methods manage Hyperdrive configurations for external PostgreSQL or MySQL databases. They do not run SQL. Applications query through a Worker Hyperdrive binding and a database driver. Cloudflare's origin password is write-only; keep request bodies and credentials out of logs and source control.

# METHODS #

* **list_configs(%query)** — List every configuration. Named filters become query parameters. The method follows all pages and returns one flat array reference; a large result set can require many requests and substantial memory.
* **list_configs_page(%query)** — Return a lazy `HTTP::API::Core::Pagination` object. Use `next()` to consume one configuration at a time.
* **list_configs_page_response(%query)** — Make one list request and return the complete decoded Cloudflare response hash, including `result_info` when supplied.
* **get_config($id, %options)** — Retrieve a configuration by ID and return its `result`.
* **create_config(\%body, %options)** — POST a Cloudflare configuration body and return its `result`.
* **replace_config($id, \%body, %options)** — PUT a replacement configuration and return its `result`.
* **update_config($id, \%body, %options)** — PATCH a configuration and return its `result`.
* **delete_config($id, %options)** — DELETE a configuration and return the endpoint's `result`, possibly `undef` for an empty body.

Non-list JSON methods accept `full_response => 1` for the complete decoded Cloudflare response. IDs are percent-encoded. Write bodies must be hash references; Cloudflare defines the accepted fields.

# ERRORS #

Missing account context, invalid bodies or IDs, HTTP and transport failures, and Cloudflare response failures cause exceptions as described in `Cloudflare::API`.

# SEE ALSO #

[Cloudflare::API](../API.pm.md)

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.
