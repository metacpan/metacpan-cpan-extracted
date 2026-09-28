# Cloudflare::API #

# NAME #

Cloudflare::API - Perl client for Cloudflare resource management

# SYNOPSIS #

```perl
use Cloudflare::API;

my $api=Cloudflare::API->new(
    token      => $ENV{'CLOUDFLARE_API_TOKEN'},
    account_id => $ENV{'CLOUDFLARE_ACCOUNT_ID'}
);

my $buckets_ar=$api->r2()->list_buckets();
my $page_or=$api->r2()->list_buckets_page(per_page => 100);
my $page_hr=$api->r2()->list_buckets_page_response(per_page => 100);
my $response_or=$api->response('GET', '/accounts');
my $zone=$api->zones()->get($zone_id);
```

# DESCRIPTION #

`Cloudflare::API` supplies a bearer-authenticated HTTP client and accessors for the resource modules below. It requires Perl 5.10 or later, HTTP::API::Core 1.08 or later, and HTTPS support through IO::Socket::SSL. Resource objects share the same client and transport. The module manages resources through Cloudflare's REST API; it does not build Worker projects or perform R2 object transfers.

An API token is required. Supply `token` to `new()` or set `CLOUDFLARE_API_TOKEN`. Account-scoped methods also need `account_id` or `CLOUDFLARE_ACCOUNT_ID`; account and zone lookups work without a default account ID. Use a token with the permissions required by the selected Cloudflare operations.

# RESOURCE MODULES #

Each accessor creates a resource object. Consult its own man page for arguments, return values, and service-specific limits.

* **[Cloudflare::API::Accounts](API/Accounts.pm.md)** (`accounts()`) lists and retrieves accounts visible to the token.
* **[Cloudflare::API::Zones](API/Zones.pm.md)** (`zones()`) lists and retrieves zones.
* **[Cloudflare::API::Workers](API/Workers.pm.md)** (`workers()`) manages scripts, versions, assets, deployments, secrets, subdomains, and zone routes.
* **[Cloudflare::API::R2](API/R2.pm.md)** (`r2()`) manages R2 buckets.
* **[Cloudflare::API::KV](API/KV.pm.md)** (`kv()`) manages Workers KV namespaces, keys, and raw values.
* **[Cloudflare::API::D1](API/D1.pm.md)** (`d1()`) manages D1 databases and runs REST SQL queries.
* **[Cloudflare::API::Queues](API/Queues.pm.md)** (`queues()`) manages queues and consumers.
* **[Cloudflare::API::Hyperdrive](API/Hyperdrive.pm.md)** (`hyperdrive()`) manages database connection configurations.
* **[Cloudflare::API::SecretsStore](API/SecretsStore.pm.md)** (`secrets_store()`) manages stores and write-only secrets.
* **[Cloudflare::API::Error](API/Error.pm.md)** represents a Cloudflare JSON response reporting failure despite HTTP success.
* **[Cloudflare::API::Resource](API/Resource.pm.md)** is the shared base class for resource objects; applications normally use the accessors above rather than constructing it.

# METHODS #

* **new(%options)**

    Construct the client. `token` is a non-empty scalar and is mandatory after environment fallback. `account_id` is an optional non-empty scalar. `base_url` defaults to `https://api.cloudflare.com/client/v4` and must be an HTTPS URL. `timeout`, `retry`, `hooks`, and `transport` pass through to HTTP::API::Core. Unknown options and invalid credentials or URL cause an exception. Automatic retries are disabled by default (`attempts => 1`), since management writes can have side effects; pass `retry` explicitly to change that policy. Returns a `Cloudflare::API` object.

* **account_id()**

    Return the configured account ID, or `undef` if none was supplied.

* **workers(), r2(), kv(), d1(), queues(), hyperdrive(), secrets_store(), accounts(), zones()**

    Return a new object of the corresponding resource class, retaining this client. Resource modules are loaded when their accessor is called.

* **request($method, $path, %options)**

    Call a JSON endpoint and return the decoded Cloudflare response's `result`, which may be a hash reference, array reference, scalar, or `undef` according to the endpoint. `full_response => 1` returns the complete decoded response hash instead. Other options, including `query`, `json`, `content`, and `headers`, pass to HTTP::API::Core. The path must begin with exactly one slash and cannot be an absolute URL.

* **request_full($method, $path, %options)**

    Return the complete decoded Cloudflare JSON hash reference, including fields such as `success`, `errors`, `messages`, and `result_info` when Cloudflare supplies them. An empty successful body yields `{ success => 1, result => undef }`. A non-object JSON body causes an exception.

* **response($method, $path, %options)**

    Return an `HTTP::API::Core::Response` object without decoding the body. Use this for non-JSON responses. It enforces the same single-slash relative-path rule as `request()`.

* **raw_request($method, $path, %options)**

    Compatibility alias for `response()`.

* **account_path(@segments)**

    Return `/accounts/<configured ID>/...` with each component percent-encoded. It throws if no account ID was configured. Resource modules use this helper; callers using `response()` can use it to build account-scoped paths.

* **segment($value)**

    Return a non-empty scalar as one percent-encoded UTF-8 URL path component. It rejects references, empty strings, and undefined values. Encode dynamic components when building low-level paths yourself.

# RETURN VALUES AND ERRORS #

Named non-list resource methods normally return the JSON `result`; pass `full_response => 1` to retain the complete decoded Cloudflare response. List methods automatically follow every page reported by Cloudflare and return a flat array reference containing all items. This can issue many requests and holds the complete collection in memory.

Every list method has two additional forms. Its `_page()` form returns a lazy `HTTP::API::Core::Pagination` object whose `next()` method yields one item and fetches subsequent pages as needed; `all()` collects its remaining items. Its `_page_response()` form makes exactly one request and returns the complete decoded Cloudflare response hash, including `result` and any `result_info`. A supplied `page` or `cursor` selects the starting point for `list()` and `_page()`, but selects only that page for `_page_response()`. `full_response` is unavailable on the list method family.

List filters are named arguments sent as query parameters. Exceptions from HTTP or transport failures remain `HTTP::API::Core::Error` objects; their decoded Cloudflare body is available through `json()`. A successful HTTP status with `success: false` throws `Cloudflare::API::Error`, including while a paginator is fetching a later page. Input validation errors throw plain Perl exceptions. No resource write is automatically rolled back.

# SEE ALSO #

[Cloudflare API documentation](https://developers.cloudflare.com/api/), HTTP::API::Core, the resource module man pages above, and the `cloudflare-api` command.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

Copyright (c) 2026 Andrew Speer. This software is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
