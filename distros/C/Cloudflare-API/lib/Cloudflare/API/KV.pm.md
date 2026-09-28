# Cloudflare::API::KV #

# NAME #

Cloudflare::API::KV - manage Workers KV namespaces, keys, and values

# SYNOPSIS #

```perl
my $kv=$api->kv();
my $namespace=$kv->create_namespace({ title => 'my-cache' });
$kv->put_value($namespace->{'id'}, 'greeting', 'hello');
my $bytes=$kv->get_value($namespace->{'id'}, 'greeting');
```

# DESCRIPTION #

All operations use the account ID configured on `Cloudflare::API`. Namespace and key-list methods use Cloudflare JSON responses. Values are handled as raw bytes; they are not JSON-decoded by `get_value()`.

# METHODS #

* **list_namespaces(%query)** — List every namespace with named query filters. The method follows all pages and returns one flat array reference; a large result set can require many requests and substantial memory.
* **list_namespaces_page(%query)** — Return a lazy `HTTP::API::Core::Pagination` object. Use `next()` to consume one namespace at a time.
* **list_namespaces_page_response(%query)** — Make one list request and return the complete decoded Cloudflare response hash, including `result_info` when supplied.
* **get_namespace($id, %options)** — Retrieve a namespace by ID and return its `result`.
* **create_namespace(\%body, %options)** — POST a namespace definition, normally `{ title => '...' }`, and return its `result`.
* **rename_namespace($id, \%body, %options)** — PUT a namespace definition with the new `title` and return its `result`.
* **delete_namespace($id, %options)** — DELETE a namespace and return the endpoint's `result`, possibly `undef` for an empty body.
* **list_keys($namespace_id, %query)** — List every key in a namespace. Query options such as `prefix`, `limit`, and `cursor` pass to Cloudflare. The method follows cursor pages and returns one flat array reference; a large namespace can require many requests and substantial memory.
* **list_keys_page($namespace_id, %query)** — Return a lazy `HTTP::API::Core::Pagination` object. Use `next()` to consume one key at a time. A supplied `cursor` selects the starting page.
* **list_keys_page_response($namespace_id, %query)** — Make one list request and return the complete decoded Cloudflare response hash, including any next cursor in `result_info`.
* **get_value($namespace_id, $key)** — Return the raw response content as a byte string. This method has no `full_response` mode or other request options.
* **put_value($namespace_id, $key, $value, %options)** — PUT a scalar value as raw content and return the decoded JSON `result`. A Perl character string is encoded as UTF-8 bytes. Optional `expiration` and `expiration_ttl` become query parameters and are mutually exclusive. `full_response => 1` retains the complete decoded Cloudflare response. A write replaces the existing expiration and metadata; this convenience method does not support metadata-bearing writes.
* **delete_value($namespace_id, $key, %options)** — DELETE one key and return the endpoint's `result`, possibly `undef` for an empty body.

Non-list JSON methods accept `full_response => 1` for the complete decoded Cloudflare response. Namespace IDs and key names are percent-encoded as path components. Create and rename bodies must be hash references; `put_value()` requires a defined non-reference scalar.

# ERRORS #

Missing account context, invalid identifiers, bodies, values, or options cause Perl exceptions. HTTP, transport, and Cloudflare response failures follow `Cloudflare::API`.

# SEE ALSO #

[Cloudflare::API](../API.pm.md)

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.
