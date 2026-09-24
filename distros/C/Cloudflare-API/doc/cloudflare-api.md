# Introduction {#introduction}

Want to list your R2 buckets, inspect a Worker, or create a D1 database from a Perl script? `Cloudflare::API` gives you a small client for those everyday Cloudflare management tasks. It uses `HTTP::API::Core` for the HTTPS transport, authentication header, and HTTP response handling; the resource modules add Cloudflare paths and request shapes on top. Thanks to the authors of that module for providing the foundation.

You can call the module from Perl or use the accompanying `cloudflare-api` command when a shell is more convenient. Both talk to Cloudflare's management API. Neither builds a Worker project or runs npm. The command can use a Wrangler login when you request it with `--auth=wrangler`. Prepare Worker code with your usual tools, then supply the resulting files if you want to upload them.

If you only need a quick look, the next example shows the whole idea. The later sections explain credentials, resource methods, uploads, responses, and command-line options. A module-by-module reference is near the end.

``` perl
use strict;
use warnings;
use Cloudflare::API;

my $api_or=Cloudflare::API->new();
my $buckets_hr=$api_or->r2()->list_buckets();
my $scripts_ar=$api_or->workers()->list_scripts();
```

With `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` set, the client supplies the account path and bearer token. Each JSON method normally gives you Cloudflare's decoded `result`, so the shape of `$buckets_hr` or `$scripts_ar` is the shape returned by that Cloudflare endpoint.

!!! note

    The distribution requires Perl 5.10 or later, `HTTP::API::Core` 1.01 or
    later, and Perl HTTPS support through `IO::Socket::SSL`. Install it with
    a CPAN client in the usual way.

# Credentials and account context {#credentials}

Create an API token in the Cloudflare dashboard with only the permissions and account or zone access your script needs. Cloudflare offers user tokens and account tokens; the endpoint and your account permissions determine which is appropriate. Copy the token when it is created and keep it in your normal secret store. The [Cloudflare token guide](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) explains the dashboard steps and permission scoping.

``` sh
# Load CLOUDFLARE_API_TOKEN from your secret manager first.
export CLOUDFLARE_ACCOUNT_ID='your-account-id'
cloudflare-api --resource r2 --action list_buckets
```

The account ID above is a placeholder. Load the token through your secret manager so it does not enter a repository or a pasted command. The module also accepts explicit `token` and `account_id` constructor options:

``` perl
my $api_or=Cloudflare::API->new(
    token      => $ENV{'CLOUDFLARE_API_TOKEN'},
    account_id => $ENV{'CLOUDFLARE_ACCOUNT_ID'},
    timeout    => 30
);
```

You can omit `account_id` for account and zone lookup, but account-scoped methods need it. The command has `--account-id` to choose another account while continuing to read the token from the environment.

!!! warning

    An API token is a credential, even when it is short lived. Do not commit
    it, paste it into command-line arguments, print it in logs, or include
    it in error reports. Use a narrowly scoped token; a token that can edit
    a resource can change or delete it through the relevant methods.

If you have logged into Wrangler locally, the command can ask Wrangler for a token for each invocation. Wrangler refreshes an expired OAuth token before returning it:

``` sh
cloudflare-api --auth=wrangler --resource workers --action list_scripts
```

For an account-scoped named method, `--auth=wrangler` also uses `wrangler whoami --json` to obtain the account ID when the login has exactly one available account. If it has several, select one with `--account-id` or `CLOUDFLARE_ACCOUNT_ID`; either value takes precedence and skips account discovery. Run `wrangler login` separately if you have not logged in. Wrangler returns an existing `CLOUDFLARE_API_TOKEN` in preference to its OAuth login; it does not mint a newly scoped API token. API key and email credentials are not supported by `--auth=wrangler`. When you rely on a Wrangler login, the returned OAuth token has the permissions of that login. The module does not refresh a token passed to its constructor; the command asks Wrangler again on each invocation. See the [Wrangler auth token reference](https://developers.cloudflare.com/workers/wrangler/commands/general/#auth-token) for the current command behaviour.

!!! tip

    For unattended scripts, use a dedicated, limited API token supplied by a
    secret manager. The Wrangler shortcut is best suited to an interactive
    session you control.

# A first Perl script {#perl-synopsis}

Let's list two resources without changing anything. Resource accessors are named for the Cloudflare service, and their methods follow the action you want to perform:

``` perl
use strict;
use warnings;
use Cloudflare::API;

my $api_or=Cloudflare::API->new();
my $zones_ar=$api_or->zones()->list(status => 'active');
my $namespaces_ar=$api_or->kv()->list_namespaces(per_page => 20);

foreach my $zone_hr (@$zones_ar) {
    print $zone_hr->{'name'}, "\n";
}
```

zones()-&gt;list() is not account-scoped; kv()-&gt;list_namespaces() is. List methods accept Cloudflare query fields as named arguments. The exact result shape differs by endpoint, so consult the Cloudflare endpoint documentation when reading fields.

To create something, pass Cloudflare's JSON request body as a hash reference. Here are two independent examples:

``` perl
my $bucket_hr=$api_or->r2()->create_bucket({
    name => 'my-app-assets'
});

my $database_hr=$api_or->d1()->create_database({
    name => 'my-app-data'
});
```

!!! caution

    These calls create real Cloudflare resources. The module does not check
    whether a name already exists, make writes idempotent, or roll back
    later calls if a script fails.

# Exploring the resource API {#resource-api}

The client has accessors for accounts(), zones(), workers(), r2(), kv(), d1(), queues(), hyperdrive(), and secrets_store(). Each returns a small resource object tied to the same client and token. The examples below show representative operations rather than every method.

## Lists, detail, and changes {#read-and-write}

Most resources offer a familiar list, get, create, update, and delete pattern. For example, you can list R2 buckets, get one by name, then update or delete it using that name. Queues, Hyperdrive configurations, and Secrets Store resources follow the same general pattern, with bodies specific to the Cloudflare endpoint.

``` perl
my $bucket_hr=$api_or->r2()->get_bucket('my-app-assets');
my $queue_hr=$api_or->queues()->create_queue({ name => 'jobs' });
my $config_ar=$api_or->hyperdrive()->list_configs();
```

Accounts and zones are useful starting points when you do not yet know an ID:

``` perl
my $accounts_ar=$api_or->accounts()->list();
my $zones_ar=$api_or->zones()->list(name => 'example.com');
```

The methods that take a body pass the supplied hash reference to Cloudflare. Refer to the relevant Cloudflare API endpoint for its required fields and accepted values. The module deliberately leaves most endpoint-specific payload choices with the caller.

## KV values and D1 queries {#kv-and-d1}

KV has a small convenience API for keys and raw values. The value methods are separate from the JSON management methods because the value body need not be JSON:

``` perl
my $kv_or=$api_or->kv();
$kv_or->put_value('namespace-id', 'greeting', 'Hello', expiration_ttl => 3600);
my $value=$kv_or->get_value('namespace-id', 'greeting');
my $keys_ar=$kv_or->list_keys('namespace-id', prefix => 'greet');
```

get_value() returns raw bytes. put_value() accepts either `expiration` or `expiration_ttl`, and writing a value replaces its previous expiration and metadata. It does not support metadata-bearing writes through this convenience method.

For D1, query_sql() keeps SQL parameters separate from the statement:

``` perl
my $rows_ar=$api_or->d1()->query_sql(
    'database-id',
    'SELECT id, name FROM people WHERE id = ?',
    [42]
);
```

The D1 REST result remains Cloudflare's array of query results. This is a management API call, not a DBI connection or a migration tool. Hyperdrive methods likewise manage connection configuration; SQL for a Hyperdrive-backed application goes through a Worker binding and database driver.

## Worker scripts, versions, and assets {#worker-management}

To upload a Worker, prepare its module files first. The metadata must identify a `main_module` whose name matches one of the supplied file entries. Each entry may contain a local `path` or in-memory `content`. This example uploads an already built module:

``` perl
my $worker_hr=$api_or->workers()->upload_script('my-app',
    metadata => {
        main_module        => 'worker.mjs',
        compatibility_date => '2026-09-22',
        bindings           => [
            { type => 'r2_bucket', name => 'ASSETS',
              bucket_name => 'my-app-assets' }
        ]
    },
    files => [
        { name => 'worker.mjs', path => 'dist/worker.mjs' }
    ]
);
```

!!! warning

    upload_script() deploys immediately. If you want to inspect a version
    before activating it, use upload_version() with the same `metadata` and
    `files` arguments, then call create_deployment() when you are ready.

Static assets can be uploaded from a directory, a list of files, or a URL-path map. The returned value includes a manifest and a short-lived completion JWT for the version metadata:

``` perl
my $assets_hr=$api_or->workers()->upload_assets(
    'my-app', 'dist/site', prefix => '/docs'
);
my $version_hr=$api_or->workers()->upload_version('my-app',
    metadata => {
        main_module        => 'worker.mjs',
        compatibility_date => '2026-09-22',
        assets             => { jwt => $assets_hr->{'jwt'} },
        bindings           => [{ type => 'assets', name => 'ASSETS' }]
    },
    files => [{ name => 'worker.mjs', path => 'dist/worker.mjs' }]
);
```

Neither upload_assets() nor upload_version() activates a new deployment. Asset uploads are assembled in memory, so consider the size of the files in a large upload. Treat the completion JWT as a credential and keep it out of logs. Worker routes use a zone ID; script upload does not create a route automatically.

Other Worker methods inspect scripts and versions, manage deployments and secret bindings, and control routes or the workers.dev subdomain. download_script() returns a raw response because its body is source content. Secret values are write-only; do not expect a later list or get call to return them.

# Responses, pagination, and errors {#responses-and-errors}

Cloudflare commonly wraps data in an envelope with `success`, `result`, and sometimes `result_info`. Named JSON methods return only `result` by default. Ask for the full envelope when you need page information or messages:

``` perl
my $page_hr=$api_or->r2()->list_buckets(
    per_page => 20,
    full_response => 1
);
my $buckets_ar=$page_hr->{'result'}{'buckets'};
```

The envelope shape and pagination fields depend on the endpoint. The command-line client's `--paginate` option can follow numbered or cursor pages for list actions, while Perl callers can use the returned `result_info` to implement the traversal they need.

An HTTP or transport failure is thrown as an `HTTP::API::Core::Error`. A successful HTTP response whose Cloudflare envelope says `success: false` is thrown as `Cloudflare::API::Error`; it retains errors(), messages(), and the underlying response(). For example:

``` perl
my $result_hr=eval { $api_or->r2()->get_bucket('my-app-assets') };
if (my $error=$@) {
    if (ref($error) && $error->isa('Cloudflare::API::Error')) {
        warn "Cloudflare rejected the request: $error\n";
    }
    else {
        die $error;
    }
}
```

!!! note

    A missing account ID or invalid local argument may also raise an
    ordinary Perl exception before any request is made. Keep tokens and
    secret request bodies out of exception logs.

# When there is no named method {#lower-level-api}

The named methods cover a useful part of Cloudflare's API, not every endpoint. Use request() for a JSON endpoint that does not yet have a wrapper. It accepts an HTTP method, a path relative to the Cloudflare API root, and `HTTP::API::Core` request options:

``` perl
my $accounts_ar=$api_or->request('GET', '/accounts',
    query => { per_page => 20 }
);
my $envelope_hr=$api_or->request_full('GET', '/accounts');
my $response_or=$api_or->raw_request('GET', '/accounts');
```

request() unwraps `result`, request_full() keeps the decoded envelope, and raw_request() returns the `HTTP::API::Core::Response` object. Use the raw form for non-JSON content or when you need response details that the JSON helpers do not expose.

!!! important

    Paths must start with one slash and cannot be absolute URLs, so a
    caller-supplied path cannot send the bearer token to another host. If
    you put a dynamic value in a low-level path, percent-encode that segment
    yourself. Named resource methods encode their own path segments.

# Using the command-line script {#command-line}

`cloudflare-api` is useful for a quick lookup or a shell script that already has credentials in its environment. Choose a resource and action for a named method. Output is pretty JSON unless you ask for `dumper`:

``` sh
cloudflare-api --resource zones --action list --param status=active
cloudflare-api --resource r2 --action list_buckets --full-response
cloudflare-api --resource zones --action list --output dumper
```

A `--param` passes a named string argument, usually a list filter. `--arg` passes a positional string argument, in the order given. For a method expecting a JSON body, use a typed argument rather than a string:

``` sh
cloudflare-api --resource kv --action create_namespace \
    --arg-json '{"title":"my-app-cache"}'
cloudflare-api --resource workers --action upload_assets \
    --arg my-app --arg dist/site --param prefix=/docs
```

For selected files, give the Worker name with `--arg`, then combine repeatable `--asset FILE`, `--asset-list-json FILE`, and `--asset-list-text FILE`. Use `--asset-list-stdin` once to read one filename per line from standard input. Text lists ignore blank lines and preserve spaces in filenames. JSON lists contain arrays of filenames or objects with `path`, optional URL `name`, and optional `content_type`. Bare filenames use their basenames as URL paths; use a directory source or explicit JSON names to preserve nested paths. Do not mix these list options with a second source argument.

``` sh
cloudflare-api --resource workers --action upload_assets \
    --arg my-app --asset dist/index.html --asset-list-text images.txt \
    --param prefix=/docs
```

Typed positional forms include `--arg-bool`, `--arg-array`, `--arg-hash`, `--arg-json`, and `--arg-json-file`. Named forms include `--param-bool`, `--param-json`, and `--param-json-file`. The JSON file forms are handy for longer bodies; for example, a Worker upload can take its name through `--arg` and prepared `metadata` and `files` through `--param-json-file`.

To read multiple pages, use `--paginate` on a list action. The command returns an array of page results, preserving each page boundary. Without `--max-pages`, it follows every page Cloudflare reports:

``` sh
cloudflare-api --resource kv --action list_namespaces \
    --paginate --per-page 20 --max-pages 2 --full-response
```

The lower-level form uses `--method` and `--path` instead of a resource and action:

``` sh
cloudflare-api --method GET --path /accounts --full-response
```

Use `--help` for a short reminder, `--man` for the complete option reference, or `--version` for the installed version. The command also has `--account-id` and `--output json|dumper`.

!!! warning

    The `--arg-dumper-file` and `--param-dumper-file` options evaluate the
    file as Perl code. Use them only with files you trust; prefer JSON for
    data from elsewhere. `--dump-opt` prints parsed arguments and can expose
    values. For secret-bearing bodies, avoid shell arguments and output
    logs; the script's manual describes how to read a JSON body from
    standard input.

# Module reference {#module-reference}

The examples above are a starting point. For the actual method names, arguments, and return conventions, follow the Markdown reference kept beside each module's Perl source. Those sidecars are the maintained method reference; this article stays focused on how the pieces fit together. Cloudflare defines the fields inside many request bodies and returned `result` values, so consult the relevant Cloudflare endpoint when you need its complete schema.

[`Cloudflare::API`](lib/Cloudflare/API.pm.md)

: Constructor options, environment defaults, resource accessors, low-level requests, and response handling.

[`Cloudflare::API::Accounts`](lib/Cloudflare/API/Accounts.pm.md)

: List accounts or retrieve one by ID.

[`Cloudflare::API::Zones`](lib/Cloudflare/API/Zones.pm.md)

: List zones or retrieve one by ID.

[`Cloudflare::API::Workers`](lib/Cloudflare/API/Workers.pm.md)

: Scripts, staged versions, deployments, assets, secrets, subdomains, and routes. Start here for upload arguments and return values.

[`Cloudflare::API::R2`](lib/Cloudflare/API/R2.pm.md)

: Bucket management through the REST API.

[`Cloudflare::API::KV`](lib/Cloudflare/API/KV.pm.md)

: Namespace management, key lists, and raw value reads and writes.

[`Cloudflare::API::D1`](lib/Cloudflare/API/D1.pm.md)

: Database management and REST queries with separate SQL parameters.

[`Cloudflare::API::Queues`](lib/Cloudflare/API/Queues.pm.md)

: Queue and consumer management.

[`Cloudflare::API::Hyperdrive`](lib/Cloudflare/API/Hyperdrive.pm.md)

: Connection configuration management, including the distinction between configuration and SQL access.

[`Cloudflare::API::SecretsStore`](lib/Cloudflare/API/SecretsStore.pm.md)

: Stores, secret metadata, write-only values, and quota information.

[`Cloudflare::API::Error`](lib/Cloudflare/API/Error.pm.md)

: The exception raised for a Cloudflare envelope that reports failure despite an HTTP success response.

For the script's full option reference, run `cloudflare-api --man`. The `--help` form is shorter when you only need to recall an option name.

# Utility reference {#utility-reference}

The [`cloudflare-api` utility reference](bin/cloudflare-api.md) documents the command's options, argument formats, pagination, output, and authentication in one place.

# Licensing and credits {#licensing-and-credits}

`Cloudflare::API` is copyright © 2026 Andrew Speer. It is free software, available under the same terms as the Perl 5 programming language system itself.

This client depends on `HTTP::API::Core` for its HTTP work and on other Perl modules for JSON, HTTPS, and Worker upload support. Thanks to their authors and maintainers. Dependencies retain their own licenses; consult their distributions for the applicable terms. Cloudflare and Wrangler are services and tools supplied by Cloudflare, Inc.
