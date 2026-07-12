# ADR 0002 — The forked child reuses the inherited sync storage

- Status: accepted
- Date: 2026-06-28
- Tags: async, fork, storage, fork-safety, access-broker

## Context

A fork-based backend has to run a real DB operation in the child. The naive
route is for `DBIO::Forked` to do everything itself: build SQL (its own
SQLMaker), reconnect fresh from `connect_info`, and handle the fork trap (a
child must not destroy the parent's shared DBI socket).

But DBIO is a DBIx::Class fork and inherited its **fork handling**:
`_verify_pid` (`DBIO::Storage::DBI` line ~259) sets `InactiveDestroy` on the
inherited handle when the PID changes and `_get_dbh` reconnects fresh — run
automatically before every CRUD / transaction op.

## Decision

The child calls the **ordinary sync CRUD of the inherited primary sync storage**
— `$self->{schema}->storage->$op(@args)`. It re-implements no SQL, touches no
DBI handle, sets no `InactiveDestroy`, and replays no `connect_info`.

- The inherited `_verify_pid` fork handling does the `InactiveDestroy` + fresh
  reconnect in the child by itself.
- That reconnect runs through the sync storage's normal connect path, so a
  configured **AccessBroker** is honoured too — each child reconnects with fresh
  credentials, for free.
- **Anti-recursion**: the child calls the *sync* method (`select`), never
  `select_async` — sync does not route to the async backend (ADR 0028), so there
  is no re-fork.

## Consequences

- Forked is extremely thin: `fork` → inherited sync CRUD → `Storable::freeze` →
  `_exit`. All the heavy lifting (SQL, reconnect, fork-safety, broker) is the
  real driver's, done once in the child.
- The `connect_info` the core resolver hands Forked is **dead weight in Model A**
  — never consumed. It is stored verbatim as latent diagnostics / raw material
  for a possible future "fresh storage" variant, and the POD marks it as
  informational.
- This relies on the inherited sync storage surviving the `fork()` in the
  child's memory (a strong schema ref exists at call time). For Model A's
  short-lived child this holds.
