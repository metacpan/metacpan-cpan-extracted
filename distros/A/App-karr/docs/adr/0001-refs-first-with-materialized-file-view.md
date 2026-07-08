# 1. Refs-first storage with a materialized file view

Date: 2026-07-02

## Status

Accepted

## Context

karr reimplements kanban-md, whose boards live as Markdown+YAML files in a
`tasks/` directory. karr instead keeps canonical state in `refs/karr/*`
(task payloads, config, next-id, locks, activity log) — refs sync atomically
through normal Git remotes, never collide with working-tree checkouts, and
allow multi-agent claim semantics without a dirty repo.

That leaves the file story open. The task *format* is kanban-md-compatible
either way (the ref payloads are the same Markdown+YAML documents), but
kanban-md tooling reads a `tasks/` directory, not refs. The code has long
carried `BoardStore::materialize_to` / `serialize_from` and the
`Task::file_path`/`from_file`/`save` API — tested, but exposed by no CLI
command, so the documented "file-compatible" identity was not observable by
users. The alternatives were: cut the file layer and become refs-only, keep
it as dormant internal API, or commit to it as a user-facing feature.

## Decision

Refs stay the single source of truth. The file layer is a first-class
**bridge**, not a storage backend: a `karr materialize` command writes the
`tasks/` directory as a disposable, gitignored view of the refs, and an
import counterpart (`serialize_from` surface) reads such a directory back
into refs — for interop with kanban-md tooling and for humans who want to
grep files. The view is regenerated on demand and never committed; writes
through the view are an explicit import step, never implicit.

## Consequences

- `Task::file_path`/`from_file`/`save` and
  `BoardStore::materialize_to`/`serialize_from` are load-bearing and stay.
- The materialized view must be faithful: nothing may rewrite task fields on
  export (guarded since the `updated`-bump fix; pinned by t/39).
- `tasks/` remains in `.gitignore`; the import path must preserve
  timestamps verbatim (pinned by t/39).
- CONTEXT.md's "file-compatible … materialized view" identity statement is
  true once the CLI commands ship (tracked as a board task).
- A future decision to go refs-only would be breaking for interop users.
