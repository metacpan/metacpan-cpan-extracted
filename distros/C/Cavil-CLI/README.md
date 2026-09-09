# Cavil CLI

[![CI](https://github.com/openSUSE/cavil-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/openSUSE/cavil-cli/actions/workflows/ci.yml)

Get a legal review for the project you are working on. Cavil CLI uploads your working tree to
[Cavil](https://github.com/openSUSE/cavil), runs its standard legal review (unpack, index, analyze), and
reports the licensing risk, for a developer's laptop or a CI gate. The uploaded tree includes the vendored
dependencies actually on disk (`node_modules` and the like), which a full review must cover.

## Usage

```
# Save the server and token once (prompts for the token without echoing it)
cavil-cli config --url https://legaldb.suse.de

# Confirm it works (and time the round trip)
cavil-cli whoami

# Upload the current directory for a legal review and print the verdict
cavil-cli check

# Check another directory, and also download the SBOM
cavil-cli check ./project --sbom
```

Credentials come from the saved config in `~/.config/cavil-cli`, or from `CAVIL_URL` and `CAVIL_API_KEY` in CI
- always as a pair, from one source. There is no `--token`, because an argument is world-readable in `ps` and
stays in your shell history, and no `--url` outside `config`, because pointing at another server would send it
a token saved for this one. `cavil-cli config --show` displays what is saved, with the token masked.

A check prints a headline tied to the CI gate, a one-line tally, then the licenses found, highest risk first:

```
$ cavil-cli check ./project
✗ project - risk 6 (restrictive obligations) ≥ threshold 5
  4 licenses · 0 unresolved · review state: new

  ✗  SSPL-1.0                       risk 6 (restrictive obligations)
  •  GPL-3.0-only                   risk 4 (strong copyleft)
  ✓  Apache-2.0                     risk 2 (permissive)
  ✓  MIT                            risk 2 (permissive)

  Report: https://legaldb.suse.de/reviews/details/1234
```

`✓` is obligation-free (permissive or public domain), `•` carries obligations but is below the gate, `✗` is at
or above the gate. The web report link has the full detail.

## Access

Submitting a package runs Cavil's full review and enters its legal backlog, so `check` needs a read-write API
key whose user has admin access, the same bar as Cavil's web upload form. Generate a key from the "API Keys"
menu after logging in. (A lighter, backlog-free path for ordinary users is planned.)

## Commands

```
cavil-cli <command> [DIR] [options]
```

| Command | Purpose |
| --- | --- |
| `check [DIR]` | Upload a project for a legal review and report its licensing risk (default DIR: `.`) |
| `whoami` | Verify the configured URL and token |
| `config` | Save the URL and token |

### `check [DIR]`

```sh
cavil-cli check              # the current directory
cavil-cli check ./project    # another directory
```

| Option | Description |
| --- | --- |
| `--name <name>` | Package name to review under (default: the directory name) |
| `--priority <n>` | Review priority 1-8 (default 5) |
| `--fail-on-risk <n>` | Exit non-zero at this risk or above (default: the instance's acceptable risk + 1) |
| `--sbom [<file>]` | Download the SPDX SBOM (default file: `<name>.spdx.json`) |
| `--notice [<file>]` | Download the NOTICE attribution file (default file: `<name>.NOTICE.txt`) |
| `--respect-gitignore` | Also drop `.gitignore`'d paths from the archive (off by default, to keep vendored code) |
| `--exclude-path <p>` | Drop this path from the archive (a `tar` pattern). Repeatable; also `CAVIL_EXCLUDE_PATHS` |
| `--external-link <s>` | Source label for traceability (default: the git remote and commit, if any) |
| `--timeout <n>` | Seconds to wait for the review before giving up (default 900) |
| `--format text\|json` | Output format; `json` for CI to police or store |
| `--no-color` | Never colour the output (also honours `NO_COLOR`) |
| `--quiet` | No progress output |
| `-h`, `--help` | Show usage |

The archive is the working tree as it sits on disk, minus `.git` and anything in a `.cavilignore` file (one
`tar` pattern per line) or given with `--exclude-path`. Vendored dependencies are kept on purpose; use
`--respect-gitignore` for the leaner case.

To catch an accidental large file (a build artifact, a data dump), `check` refuses before uploading if the
archive exceeds the server's upload limit (250 MiB by default), telling you to trim it. Set `CAVIL_MAX_UPLOAD_MB`
to match an instance configured to accept more.

The default gate is one above the instance's own acceptable risk, so a project the instance would accept passes
without any configuration. Raise `--fail-on-risk` if you already ship higher-risk code, lower it to be stricter.

### `whoami`

```sh
cavil-cli whoami
```

Shows who the token belongs to, its roles and write access, and the round-trip time to the instance.

### `config`

```sh
cavil-cli config --url https://legaldb.suse.de   # prompts for the token
cavil-cli config --show
```

| Option | Description |
| --- | --- |
| `--url <url>` | Server to save |
| `--show` | Print the saved settings, with the token masked |

Settings are stored in `~/.config/cavil-cli`. The token is read from a hidden prompt (or stdin when piped),
never from the command line, where it would linger in shell history and process listings.

## Exit codes

| Code | Meaning |
| --- | --- |
| `0` | Within the risk gate |
| `1` | The risk gate failed |
| `2` | Usage or configuration problem |
| `3` | Server or connection error |

## Documentation

See the [docs](docs) directory, starting with the [architecture](docs/Architecture.md) guide for how it works
and why it is built this way.
