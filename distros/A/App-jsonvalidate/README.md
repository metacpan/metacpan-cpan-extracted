# NAME

jsonvalidate - Validate JSON instances against a JSON Schema (Draft 2020-12)

# SYNOPSIS

    jsonvalidate --schema schema.json --instance data.json
    jsonvalidate -s schema.json -i instances.array.json
    jsonvalidate -s schema.json -i - < data.jsonl --jsonl --json
    jsonvalidate -s root.json -s subdefs.json -i items.ndjson --jsonl --compile --register-formats

# DESCRIPTION

A lean CLI powered by [JSON::Schema::Validate](https://metacpan.org/pod/JSON%3A%3ASchema%3A%3AValidate). It supports arrays of instances, JSON Lines, local file `$ref`, optional HTTP(S) fetch for `$ref` (when [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) is available), and useful output modes.

# OPTIONS

## Selection

- **--schema**, **-s** FILE1, FILE2, FILE3, etc...

    Root schema; additional `--schema` files are made available to the resolver, such as when their `` `'$id'` `` is referenced.

- **--instance**, **-i** FILE1, FILE2, FILE3, etc...

    Instances to validate. Use `-` for STDIN. An instance may be a single object, a single array (each element validated), or JSON Lines with `--jsonl`.

    Not that you can either use `-` (STDIN), or one or more files, but you cannot mix both.

- **--jsonl**

    Treat each line as an instance (NDJSON).

## Output

- **--quiet**, **-q**

    Suppress per-record output; still returns non-zero exit on failures.

- **--errors-only**

    Only print failed records (ignored when `--json` is used).

- **--json**

    Emit JSON objects (one per instance) with `{ index, ok, errors[] }`.

## Behavior

- **--compile** / **--no-compile**

    Enable compiled fast-path for repeated validation.

- **--content-checks**

    Enable `contentEncoding`, `contentMediaType`, `contentSchema`. Registers a basic `application/json` validator/decoder.

- **--register-formats**

    Register built-in `format` validators (date, email, hostname, ip, uri, uuid, JSON Pointer, regex, etc.).

- **--trace**

    Record lightweight trace; cap with `--trace-limit`; sample with `--trace-sample`.

- **--trace-limit N**

    Max number of trace entries per validation (0 = unlimited).

- **--trace-sample P**

    Sampling percentage for trace events.

- **--max-errors N**

    Maximum recorded errors per validation (default 200).

- **--normalize** / **--no-normalize**

    Round-trip instances through [JSON](https://metacpan.org/pod/JSON) to enforce strict JSON typing (default on).

- **--ignore-unknown-required-vocab**

    Ignore unknown vocabularies listed in schema `` `'$vocabulary'` `` _required_.

- **--schema-base DIR**

    A base directory to resolve relative file `$ref` (defaults to the directory of the first `--schema`).

# EXIT CODES

- `0`

    All instances validated.

- `1`

    At least one instance failed.

- `2`

    Usage error.

# SEE ALSO

[JSON::Schema::Validate](https://metacpan.org/pod/JSON%3A%3ASchema%3A%3AValidate), [JSON](https://metacpan.org/pod/JSON)

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# COPYRIGHT

Copyright(c) 2025 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
