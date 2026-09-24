# Cloudflare::API::Queues #

# NAME #

Cloudflare::API::Queues - manage queues and their consumers

# SYNOPSIS #

```perl
my $queues=$api->queues()->list_queues();
my $consumers=$api->queues()->list_consumers($queue_id);
```

# DESCRIPTION #

These methods use the account ID configured on `Cloudflare::API`. They manage queue resources and consumers, including Worker consumers; they do not push or pull messages.

# METHODS #

* **list_queues(%query)** — List queues using named query filters. Returns `result`; `full_response => 1` retains pagination information.
* **get_queue($id, %options)** — Retrieve a queue by ID and return its `result`.
* **create_queue(\%body, %options)** — POST a queue definition, normally including `queue_name`, and return its `result`.
* **update_queue($id, \%body, %options)** — PATCH a queue and return its `result`.
* **delete_queue($id, %options)** — DELETE a queue and return the endpoint's `result`, possibly `undef` for an empty body.
* **list_consumers($queue_id, %query)** — List consumers for one queue, using named query filters. Returns `result`; `full_response => 1` retains pagination information.
* **create_consumer($queue_id, \%body, %options)** — POST a consumer definition and return its `result`.
* **delete_consumer($queue_id, $consumer_id, %options)** — DELETE a consumer and return the endpoint's `result`, possibly `undef` for an empty body.

Every JSON method accepts `full_response => 1`. IDs are percent-encoded. Create and update bodies must be hash references.

# ERRORS #

Missing account context, invalid IDs or bodies, HTTP and transport failures, and Cloudflare envelope failures cause exceptions as described in `Cloudflare::API`.

# SEE ALSO #

[Cloudflare::API](../API.pm.md)

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.
