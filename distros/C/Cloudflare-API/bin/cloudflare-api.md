# cloudflare-api #

# NAME #

cloudflare-api - call Cloudflare::API resource methods from the command line

# SYNOPSIS #

```sh
cloudflare-api zones list --param status=active
cloudflare-api workers inspect_script --param name=my-worker
cloudflare-api workers list_deployments my-worker
cloudflare-api --resource r2 --action list_buckets --paginate --max-pages 2
cloudflare-api --resource kv --action create_namespace --arg-json '{"title":"demo"}'
cloudflare-api --resource workers --action upload_assets --arg my-app --arg dist --param prefix=/docs
cloudflare-api --method GET --path /accounts --full-response
cloudflare-api --generate-completion=zsh > ~/.zfunc/_cloudflare-api
```

# DESCRIPTION #

`cloudflare-api` calls a supported `Cloudflare::API` resource method or makes a low-level JSON request. It reads `CLOUDFLARE_API_TOKEN` and, for account-scoped methods, `CLOUDFLARE_ACCOUNT_ID` from the environment. It prints the decoded Cloudflare `result` as pretty JSON by default; `--full-response` retains the entire Cloudflare envelope. The script does not build Worker code or transfer R2 objects.

Choose one mode: `RESOURCE ACTION [ARG ...]` (or `--resource NAME --action NAME`) for a named method, or `--method VERB --path /relative/path` for a low-level request. The resource or action may be given positionally when its named option is omitted. Further bare operands become literal string method arguments, equivalent to `--arg`; they retain their command-line order when mixed with typed `--arg*` options. Named arguments supplied with `--param*` become method options, or query parameters in low-level mode. Bare arguments remain unavailable in low-level request mode.

# OPTIONS #

## Selection and authentication ##

* **RESOURCE ACTION [ARG ...], --resource NAME, --action NAME**

    Call a named method on `accounts`, `zones`, `workers`, `r2`, `kv`, `d1`, `queues`, `hyperdrive`, or `secrets_store`. The resource and action can be two positional operands, two named options, or one of each. Subsequent bare operands become string method arguments. Only methods in the script's allowlist can be called; missing or unknown selections list the valid resources or actions. Consult the resource module sidecars for arguments and results. The script does not expose every module method, including `workers()->download_script()`, whose body is not JSON.

* **--method VERB, --path /relative/path**

    Call a low-level JSON endpoint through `Cloudflare::API->request()`. Both options are required and cannot be combined with `--resource` or `--action`. The method is uppercased. The path must begin with exactly one slash and cannot be an absolute URL. At most one body argument supplied with `--arg*` is accepted; named parameters become query parameters. Bare operands are rejected. Dynamic path segments must be percent-encoded by the caller.

* **--account-id ID**

    Override `CLOUDFLARE_ACCOUNT_ID` and Wrangler account discovery for this invocation. Account-scoped methods require an ID; account and zone lookups do not.

* **--auth=wrangler**

    Run `wrangler auth token --json` and use its API token or refreshed OAuth token instead of the environment token. For an account-scoped named method, also run `wrangler whoami --json` and use the account ID when exactly one account is available. Select among multiple accounts with `--account-id` or `CLOUDFLARE_ACCOUNT_ID`; these explicit values take precedence and skip account discovery. Wrangler must be installed and logged in. Run `wrangler login` separately if necessary. Wrangler itself prioritizes an existing `CLOUDFLARE_API_TOKEN` over its OAuth login. API key and email credentials are not supported. No token option is accepted on the command line.

## Positional and named arguments ##

* **--arg VALUE**

    Append a literal string method argument. Repeat to supply several arguments in order. For named resource actions, bare operands after the resource and action are equivalent; use `--arg` or `--` when a value could be mistaken for an option.

* **--arg-bool true|false, --arg-array JSON, --arg-hash JSON, --arg-json JSON, --arg-json-file FILE**

    Append a typed positional argument. Boolean values are case-insensitive; array and hash forms require the matching JSON container. The JSON forms accept any JSON value, directly or read from a file. To pass a private JSON body without putting it in the process arguments, pipe it to `--arg-json-file /dev/stdin`.

* **--arg-dumper-file FILE**

    Evaluate a trusted Data::Dumper file as Perl and append its result. The file can execute arbitrary Perl code; use JSON for data from other sources.

* **--param NAME=VALUE**

    Pass one literal string named argument. The first `=` separates the name from the value, so a value may contain further equals signs. Names must begin with a letter or underscore and contain only letters, digits, or underscores. A repeated name replaces its earlier value.

* **--param-bool NAME=true|false, --param-json NAME=JSON, --param-json-file NAME=FILE**

    Pass a typed named argument. JSON file content is decoded before the method call. For list actions these usually become Cloudflare query filters; for other actions they can be method options such as `metadata` and `files` for a Worker upload.

* **--param-dumper-file NAME=FILE**

    Evaluate a trusted Data::Dumper file as Perl and pass its result under `NAME`. This can execute arbitrary Perl code; prefer JSON for untrusted input.

## Worker static assets ##

* **--asset FILE**

    Append a local file to the asset source list. Repeat as needed. A bare filename uses its basename as its URL path.

* **--asset-list-json FILE**

    Append entries from a JSON array of filenames or objects with `path`, optional URL `name`, and optional `content_type`. Repeat for multiple files.

* **--asset-list-text FILE, --asset-list-stdin**

    Append one filename per line from a text file or standard input. Empty lines are ignored; spaces in filenames are preserved. The stdin option may appear only once. Sources combine in option order.

    All four asset-list options require `--resource workers --action upload_assets` and exactly one string `--arg` naming the Worker. They create the method's second positional argument as a file array; do not also pass a directory, array, or path-map source argument. The array cannot be empty. Alternatively, pass a directory with a second `--arg`, or an asset array with `--arg-json-file`. `--param prefix=/docs` sets a URL prefix. The command prints the manifest and short-lived completion JWT returned by `upload_assets()`; asset upload alone does not deploy a Worker. Treat the JWT as a credential.

## Output and pagination ##

* **--output json|dumper**

    Print pretty, canonical JSON (the default) or Perl Data::Dumper output to standard output.

* **--full-response, --no-full-response**

    Select the complete decoded Cloudflare envelope or its `result`. The default is the unwrapped `result`. With pagination, the selection applies to each page; the output is still an array. `upload_assets()` returns its own manifest and JWT structure rather than a Cloudflare envelope.

* **--paginate, --no-paginate**

    Follow cursor-based or numbered pages for named actions starting with `list`, and for `workers search_scripts`. The output is an array of page results, preserving page boundaries. Without a limit, every page reported by Cloudflare is fetched. Pagination is unavailable for raw requests and other actions.

* **--max-pages N, --per-page N**

    Limit pagination to a positive number of pages, or send positive `per_page=N` as a named list filter. `--max-pages` requires `--paginate`. Pagination stops when Cloudflare supplies no next page; a repeated cursor causes an error.

## Help and diagnostics ##

* **--help, -h, -?**

    Print brief help and exit.

* **--man**

    Print the script's embedded manual and exit.

* **--version**

    Print the script name and `Cloudflare::API` version and exit.

* **--dump-opt, --dump_opt, --opt**

    Print parsed options, arguments, and parameters as Data::Dumper without creating a client or requiring a token. This output can disclose values. The script rejects this mode for selected Secrets Store, Worker secret, and Hyperdrive write actions, but other actions may also carry private data; do not use it with secrets.

* **--generate-completion bash|zsh|fish**

    Print a self-contained completion script for the selected shell and exit. Completion covers resources, their supported actions, command options, enumerated option values, and filenames accepted by file options. It performs no authentication, network access, or Cloudflare resource discovery. Generate the file once and load it through the shell's normal completion mechanism:

    ```sh
    cloudflare-api --generate-completion=bash > ~/.local/share/bash-completion/completions/cloudflare-api
    cloudflare-api --generate-completion=zsh > ~/.zfunc/_cloudflare-api
    cloudflare-api --generate-completion=fish > ~/.config/fish/completions/cloudflare-api.fish
    ```

    The destination directories must already be configured for the relevant shell. Regenerate the file after upgrading `Cloudflare::API` so that newly supported resources, actions, or options are included.

# ENVIRONMENT #

* **CLOUDFLARE_API_TOKEN** — Bearer token used unless `--auth=wrangler` is supplied. Obtain a token with only the permissions needed for the requested action.
* **CLOUDFLARE_ACCOUNT_ID** — Default account ID for account-scoped resource methods; overridden by `--account-id` and used in preference to Wrangler account discovery.

# EXAMPLES #

```sh
cloudflare-api zones list --param status=active
cloudflare-api workers search_scripts --param name=orders --paginate
cloudflare-api workers list_scripts --param tags=production:yes
cloudflare-api workers inspect_script --param name=orders-api
cloudflare-api workers inspect_script --param tag=IMMUTABLE_WORKER_ID
cloudflare-api workers inspect_script --param etag=CONTENT_HASH
cloudflare-api workers get_settings orders-api
cloudflare-api workers list_deployments orders-api
cloudflare-api --resource kv --action list_namespaces \
    --paginate --per-page 20 --max-pages 2 --full-response
cloudflare-api --resource workers --action upload_assets \
    --arg my-app --asset dist/index.html --asset-list-text images.txt \
    --param prefix=/docs
cloudflare-api --resource secrets_store --action create_secret \
    --arg my-store --arg-json-file /dev/stdin < secrets.json
```

For a Worker version upload, pass the Worker name through `--arg` and prepared `metadata` and `files` through `--param-json-file NAME=FILE`. Version upload does not activate a deployment; consult `Cloudflare::API::Workers` for the staging and deployment sequence. A secret body supplied through standard input still appears in the command's output if Cloudflare returns it; handle the output accordingly.

Worker inspection accepts exactly one of `--param name=...`, `--param tag=...`, or `--param etag=...`. The name is the `id` printed by `list_scripts`; `tag` is Cloudflare's immutable Worker ID, while `etag` identifies current script content. Inspection returns the matching inventory entry, combined script/version settings, and Worker-level settings. It does not download source or include versions and deployments.

# RETURN VALUES AND ERRORS #

Successful requests print the result followed by a newline and exit with status zero. JSON output preserves Cloudflare's response shape; a paginated list prints an array of pages. The CLI checks the number of `--arg` values required by supported methods before authentication or network access. Input validation, missing credentials or account context, HTTP and transport errors, and Cloudflare responses reporting failure terminate with a non-zero status and a diagnostic on standard error. No write is automatically rolled back.

# SEE ALSO #

[Cloudflare::API](../lib/Cloudflare/API.pm.md), [Cloudflare::API::Workers](../lib/Cloudflare/API/Workers.pm.md), the other resource module sidecars, and `cloudflare-api --man`.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.
