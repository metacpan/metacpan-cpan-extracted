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

* **list_configs(%query)** — List configurations. Named filters become query parameters. Returns `result`; `full_response => 1` retains pagination information.
* **get_config($id, %options)** — Retrieve a configuration by ID and return its `result`.
* **create_config(\%body, %options)** — POST a Cloudflare configuration body and return its `result`.
* **replace_config($id, \%body, %options)** — PUT a replacement configuration and return its `result`.
* **update_config($id, \%body, %options)** — PATCH a configuration and return its `result`.
* **delete_config($id, %options)** — DELETE a configuration and return the endpoint's `result`, possibly `undef` for an empty body.

Every JSON method accepts `full_response => 1` for the complete decoded envelope. IDs are percent-encoded. Write bodies must be hash references; Cloudflare defines the accepted fields.

# ERRORS #

Missing account context, invalid bodies or IDs, HTTP and transport failures, and Cloudflare envelope failures cause exceptions as described in `Cloudflare::API`.

# SEE ALSO #

[Cloudflare::API](../API.pm.md)

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.
