# Cloudflare::API

Cloudflare::API is a pure Perl client for a focused subset of the Cloudflare
API. It covers mainstream compute and storage management, including Workers,
R2, KV, D1, Queues, Hyperdrive, and Secrets Store. HTTP transport is provided
by `HTTP::API::Core`.

The distribution requires Perl 5.10 or later, `HTTP::API::Core` 1.01 or later,
and HTTPS support through `IO::Socket::SSL`.

## Example

```perl
use Cloudflare::API;

my $api=Cloudflare::API->new(
    token      => $ENV{'CLOUDFLARE_API_TOKEN'},
    account_id => $ENV{'CLOUDFLARE_ACCOUNT_ID'}
);

my $bucket=$api->r2()->create_bucket({ name => 'my-app-assets' });
my $database=$api->d1()->create_database({ name => 'my-app-data' });
my $namespaces=$api->kv()->list_namespaces();
```

## Authentication

Pass `token` and `account_id` to the constructor, or set
`CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`. Account and zone lookups do
not require a default account ID. Other account-scoped methods do.

The `cloudflare-api` command can also use `--auth=wrangler` to obtain a token
from an existing Wrangler login. When Wrangler reports one account, the command
uses its account ID automatically. Use `--account-id` or
`CLOUDFLARE_ACCOUNT_ID` to select an account explicitly.

JSON methods return Cloudflare's decoded `result` by default. Pass
`full_response => 1` to retain the complete response envelope and pagination
information. `request()` provides access to JSON endpoints without a named
method, while `raw_request()` returns the `HTTP::API::Core::Response` object for
non-JSON responses.

## Worker uploads

The Workers interface uploads prepared modules, versions, deployments, secrets,
routes, and static asset sets. `upload_assets()` can recursively upload a
directory and return the completion token needed for a Worker version.

The module does not bundle JavaScript, resolve npm dependencies, or build a
Worker project. Continue to use Wrangler for uploads that require bundling or a
project build, and use Cloudflare::API when the Worker modules and metadata are
already prepared.

## Current resource methods

| Resource | Methods |
| --- | --- |
| Accounts | `list`, `get` |
| Zones | `list`, `get` |
| Workers | `list_scripts`, `download_script`, `upload_script`, `upload_version`, `list_versions`, `get_version`, `upload_assets`, `delete_script`, `list_deployments`, `get_deployment`, `create_deployment`, `list_secrets`, `add_secret`, `delete_secret`, `get_subdomain`, `set_subdomain`, `list_routes`, `create_route`, `update_route`, `delete_route` |
| R2 | `list_buckets`, `get_bucket`, `create_bucket`, `update_bucket`, `delete_bucket` |
| KV | `list_namespaces`, `get_namespace`, `create_namespace`, `rename_namespace`, `delete_namespace`, `list_keys`, `get_value`, `put_value`, `delete_value` |
| D1 | `list_databases`, `get_database`, `create_database`, `update_database`, `delete_database`, `query_database`, `query_sql` |
| Queues | `list_queues`, `get_queue`, `create_queue`, `update_queue`, `delete_queue`, `list_consumers`, `create_consumer`, `delete_consumer` |
| Hyperdrive | `list_configs`, `get_config`, `create_config`, `replace_config`, `update_config`, `delete_config` |
| Secrets Store | `list_stores`, `get_store`, `create_store`, `delete_store`, `list_secrets`, `get_secret`, `create_secret`, `update_secret`, `delete_secret`, `get_quota` |

Create and update methods take a hash reference containing Cloudflare's request
body. The named methods intentionally cover a subset of the Cloudflare API; use
`request()` for other JSON endpoints.

## Command-line client

The installed `cloudflare-api` command exposes the same resource methods and
also supports low-level requests:

```sh
cloudflare-api --resource r2 --action list_buckets --paginate --max-pages 2
cloudflare-api --resource kv --action create_namespace --arg-json '{"title":"my-app-cache"}'
cloudflare-api --resource zones --action list --param status=active --output dumper
cloudflare-api --method GET --path /accounts --full-response
```

Arguments and named parameters can be supplied as strings, booleans, JSON, or
JSON files. List actions support numbered and cursor-based pagination. Output is
pretty JSON by default, with Data::Dumper available through `--output dumper`.
Use `cloudflare-api --man` for the complete option reference.

## Documentation

Reference documentation is available in the [`doc/`](doc/) directory and from
the GitHub Pages site linked from the repository. Module-specific Markdown
pages are stored alongside their modules under [`lib/Cloudflare`](lib/Cloudflare/).
