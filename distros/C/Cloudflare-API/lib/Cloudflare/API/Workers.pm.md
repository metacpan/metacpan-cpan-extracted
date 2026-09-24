# Cloudflare::API::Workers #

# NAME #

Cloudflare::API::Workers - manage Worker scripts, versions, assets, and routes

# SYNOPSIS #

```perl
my $workers=$api->workers();
my $version=$workers->upload_version('my-app',
    metadata => {
        main_module        => 'worker.mjs',
        compatibility_date => '2026-09-22'
    },
    files => [{ name => 'worker.mjs', path => 'dist/worker.mjs' }]
);
$workers->create_deployment('my-app', {
    strategy => 'percentage',
    versions => [{ version_id => $version->{'id'}, percentage => 100 }]
});
```

# DESCRIPTION #

Most Worker methods use the account ID configured on `Cloudflare::API`. Route methods instead take a zone ID explicitly. The module sends prepared modules and Cloudflare metadata; it does not build scripts, invoke npm or Wrangler, generate a Worker entry point, or create routes automatically.

Cloudflare's Worker identifiers have distinct purposes. The `id` returned by `list_scripts()` is the script name used in API paths, `tag` is the immutable Worker ID, `tags` contains user-assigned labels, and `etag` identifies the current script content. The search API calls the immutable `tag` value `id`. `inspect_script()` uses the unambiguous selector names `name`, `tag`, and `etag`.

JSON methods return Cloudflare's decoded `result` by default. Except where noted, pass `full_response => 1` to return the complete parsed envelope. List methods take named Cloudflare query parameters alongside `full_response`; this retains pagination information such as `result_info`. Script names, version IDs, secret names, and route IDs are percent-encoded in URLs.

# METHODS #

* **list_scripts(%query)** — List account Worker scripts. Returns `result`; `full_response => 1` retains pagination information.
* **search_scripts(%query)** — Search scripts through Cloudflare's discovery endpoint. `name` accepts exact or partial names; `id` is an exact immutable Worker ID (called `tag` in list results). Ordering and pagination parameters pass through. Returns `result`; `full_response => 1` retains pagination information.
* **get_settings($name, %options)** — Return the named Worker's combined script and current-version settings, including bindings, compatibility configuration, annotations, placement, and runtime limits.
* **get_script_settings($name, %options)** — Return Worker-level settings such as user-assigned tags, Logpush, observability, and tail consumers.
* **inspect_script(name => $name | tag => $tag | etag => $etag)** — Resolve exactly one Worker from the account inventory and return `{ script => ..., settings => ..., script_settings => ... }`. Exactly one non-empty selector is required. `name` matches the script name exactly; `tag` matches the immutable Worker ID; `etag` matches the current content hash. Zero or multiple matches cause an exception. This convenience method makes three read requests, has no `full_response` mode, and does not include source, versions, or deployments.
* **download_script($name)** — Return an `HTTP::API::Core::Response` object. Read its `content()` for Worker source or multipart content; this response is not JSON-decoded and has no `full_response` option.
* **upload_script($name, metadata => \%metadata, files => \@files)** — PUT a prepared module upload to the script endpoint, **deploying it immediately**. Returns `result`, or the envelope with `full_response => 1`. See **Module uploads** below for required metadata and file entries.
* **upload_version($name, metadata => \%metadata, files => \@files, %options)** — POST a prepared module upload as a version without activating it. Returns the version `result`, or the envelope with `full_response => 1`. Optional `bindings_inherit => 'strict'` asks Cloudflare to reject unresolved inherited bindings; no other value is accepted.
* **list_versions($name, %query)** — List versions for a script. Returns `result`; `full_response => 1` retains pagination information.
* **get_version($name, $version_id, %options)** — Retrieve a version and return its `result`.
* **upload_assets($name, $source, %options)** — Register and upload a static asset set. Returns `{ jwt => $completion_token, manifest => \%manifest }`, not a normal Cloudflare response envelope. `prefix` chooses a URL prefix; `full_response` is accepted but has no effect. See **Static assets** below.
* **delete_script($name, %options)** — DELETE a script and return the endpoint's `result`, possibly `undef` for an empty body.
* **list_deployments($name, %query)** — List deployments of a script. Returns `result`; `full_response => 1` retains pagination information.
* **get_deployment($name, $deployment_id, %options)** — Retrieve a deployment and return its `result`.
* **create_deployment($name, \%body, %options)** — POST a deployment definition, such as a `strategy` and `versions` array. This activates the specified version mix and returns `result`.
* **list_secrets($name, %options)** — List a Worker's secret bindings and return `result`.
* **add_secret($name, \%body, %options)** — PUT a secret binding and return `result`. Keep secret values out of logs and source control.
* **delete_secret($name, $secret_name, %options)** — DELETE a secret binding and return the endpoint's `result`.
* **get_subdomain($name, %options)** — Retrieve a Worker's workers.dev subdomain setting and return `result`.
* **set_subdomain($name, \%body, %options)** — POST a subdomain setting, including `enabled` when changing reachability, and return `result`.
* **list_routes($zone_id, %query)** — List routes in a zone. Returns `result`; `full_response => 1` retains pagination information.
* **create_route($zone_id, \%body, %options)** — POST a zone route and return `result`.
* **update_route($zone_id, $route_id, \%body, %options)** — PUT a replacement route and return `result`.
* **delete_route($zone_id, $route_id, %options)** — DELETE a route and return the endpoint's `result`.
* **asset_content_type($extension)** — Return the built-in MIME type for a lowercase extension, or `application/octet-stream` when unknown. `upload_assets()` calls this for entries without an explicit `content_type`.

Write bodies must be hash references. Missing account context, invalid identifiers, selectors or body shapes, ambiguous inspection matches, and unknown upload options cause exceptions before or during the request. The `Cloudflare::API` man page describes HTTP, transport, and Cloudflare envelope failures.

# MODULE UPLOADS #

`upload_script()` and `upload_version()` require metadata with a non-empty `main_module` that matches the name of one uploaded file. Supply Cloudflare fields such as `compatibility_date` and `bindings` in the metadata. `files` must be a non-empty array of entries with a `name` and exactly one of `path` or `content`; each entry may also set `content_type` (default `application/javascript+module`). Names may contain letters, numbers, dots, dashes, underscores, and slashes for nested modules. Duplicate names are rejected. Module content and the multipart request are assembled in memory, so large uploads need enough process memory.

Use `upload_script()` when immediate deployment is intended. To stage a version, use `upload_version()`, inspect it with `get_version()` if needed, then call `create_deployment()` to make it active. Version upload alone does not change traffic.

# STATIC ASSETS #

`upload_assets($name, $source, %options)` accepts a directory path, an array reference of filenames or `{ path => $file, name => 'nested/page.html', content_type => 'image/jxl' }` entries, or a hash reference mapping absolute URL paths to content scalars or `{ path => $file }` entries. Directory uploads recurse and preserve paths relative to the directory. Array filenames use their basenames unless `name` is supplied. Duplicate URL paths are rejected; directory and file-list uploads reject symlinks. The source must not be empty. `prefix => '/docs'` places every URL path under `/docs`.

The method hashes the content, registers a manifest, uploads the buckets Cloudflare requests, and returns a manifest plus a short-lived completion `jwt`. Uploads are assembled in memory. Common HTML, CSS, JavaScript, JSON, text, font, PDF, WASM, and image extensions receive a MIME type; unknown extensions use `application/octet-stream`. An entry may override the MIME type with `content_type`.

Asset upload does not deploy a Worker. Put the returned token into a version's metadata, along with an assets binding, then deploy that version:

```perl
my $assets=$workers->upload_assets('my-app', 'dist', prefix => '/docs');
my $version=$workers->upload_version('my-app',
    metadata => {
        main_module        => 'worker.mjs',
        compatibility_date => '2026-09-22',
        assets             => { jwt => $assets->{'jwt'} },
        bindings           => [{ type => 'assets', name => 'ASSETS' }]
    },
    files => [{ name => 'worker.mjs', path => 'dist/worker.mjs' }]
);
```

The prepared Worker must route requests to its asset binding, for example with `env.ASSETS.fetch(request)`. Treat the JWT as a credential and keep it out of logs. See `cloudflare-api --man` for command-line asset source options.

# SEE ALSO #

[Cloudflare::API](../API.pm.md), [Cloudflare::API::Zones](Zones.pm.md), [Cloudflare::API::SecretsStore](SecretsStore.pm.md)

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.
