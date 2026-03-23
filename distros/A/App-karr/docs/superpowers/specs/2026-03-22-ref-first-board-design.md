# Ref-First Board Design

## Goal

Move `karr` from a local-file-first board with Git ref sync to a Git-ref-first
board where `refs/karr/*` is the only source of truth. The repository must no
longer contain a persistent `karr/` working tree that can collide across
machines or agents.

## Current problem

Today `karr init` creates `karr/config.yml` and `karr/tasks/*.md` in the working
tree, and command handlers materialize refs into those files before writing
them back. That creates the exact class of collisions the tool is supposed to
avoid:

- a board directory appears in the repo and can be committed accidentally
- multiple machines can diverge in local state before sync
- config and task writes collide with ordinary working tree operations
- the Git-ref backend is only a mirror, not the primary model

For this project, that is the wrong architectural center.

## Design summary

`refs/karr/*` becomes the sole persisted state for board data. Commands read
from refs, operate on in-memory objects or temporary snapshots, and write the
result back to refs. No command should require or maintain a durable `karr/`
directory in the repository.

`karr` also becomes Git-only. Running it outside a Git repository should fail
fast with a clear message.

## Ref layout

The ref layout should be explicit and stable:

- `refs/karr/config`
  Stores only config overrides and schema metadata, not a full copy of all
  default values.
- `refs/karr/meta/next-id`
  Stores the next numeric task id as a standalone scalar payload.
- `refs/karr/tasks/<id>/data`
  Stores the canonical markdown representation of a task.
- `refs/karr/log/<identity>`
  Stores append-only activity log data.

Helper refs outside the protected namespace remain separate and are unaffected.

## Config model

Defaults remain in code. `refs/karr/config` stores only:

- `version`
- explicit overrides from the defaults
- any future fields that must be persisted because they are runtime intent, not
  code defaults

This avoids freezing old defaults into long-lived board config. If the code
later changes a default, boards that did not override it should see the new
behavior automatically.

`next_id` must not live in config, because it changes frequently and should not
conflict with actual board settings.

## Command behavior

### Init

`karr init` requires a Git repository. It should:

- verify the current directory is inside a Git worktree
- fail if `refs/karr/config` already exists
- write the initial config override ref
- write `refs/karr/meta/next-id`
- optionally push those refs if that becomes the standard write path for all
  mutating commands

It should not create `karr/` in the working tree.

### Read commands

Commands such as `list`, `show`, `board`, `context`, and `config` should read
directly from refs after a fetch/materialize step that exists only in memory or
in a temporary directory.

### Write commands

Commands such as `create`, `edit`, `move`, `archive`, `delete`, `pick`,
`handoff`, and `config set` should follow this sequence:

1. fetch current refs
2. load canonical state from refs
3. apply the requested mutation
4. write only the affected refs
5. push updated refs

There should be no persistent repo-local board cache.

## Temporary materialization

The pragmatic implementation path is to keep task/config parsing formats but
move any file materialization into a temp area created per command execution.

That gives us:

- minimal parser churn
- reuse of existing task markdown format
- no persistent `karr/` directory

This is preferable to rewriting every command to manipulate raw YAML strings in
one step.

## Backup and restore

Add explicit snapshot commands:

- `karr backup [FILE|-]`
- `karr restore [FILE|-] --yes`

Backup writes a YAML snapshot of all `refs/karr/*`.

Restore is destructive by design. With `--yes`, it should:

1. fetch current refs
2. delete every existing `refs/karr/*`
3. recreate refs from the YAML snapshot
4. push the resulting ref set

Without `--yes`, restore must fail with a strong warning. The command should
make it obvious that refs missing from the backup will be removed.

## Skill installation and Docker

Skill installation must keep working when `karr` is run through Docker. The
important requirement is that the target `HOME` inside the container is the one
that actually contains mounted `.codex`, `.claude`, or `.cursor` directories,
and that the final process runs as a non-root user where appropriate.

This is separate from board storage, but it should be verified during the same
cleanup pass because the current vendor-style usage depends on it.

## Migration

Boards created under the current local-file-first model need a migration path.
The tool should support one of these:

- detect a legacy `karr/` directory and import it once into refs
- provide an explicit migration command

The safe default is explicit migration, because silent import can hide bad
state.

## Risks

- many commands currently assume `board_dir`, `tasks_dir`, and `config.yml`
- tests are heavily built around a local directory
- `next_id` needs atomic handling so concurrent `create` operations stay safe
- restore is intentionally destructive and needs strong UX guardrails

## Recommendation

Implement the ref-first architecture in stages:

1. introduce a ref-backed board store abstraction
2. move config and task loading off persistent `karr/`
3. make `init` Git-only and ref-only
4. add backup/restore
5. remove remaining local board assumptions from docs, tests, and help text
