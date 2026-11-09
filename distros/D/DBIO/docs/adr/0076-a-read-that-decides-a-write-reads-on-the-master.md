# ADR 0076 — A read that decides a write reads on the master

- Status: accepted (coordinator decision of 2026-10-30, karr k390, under the maintainer's order to resolve the security findings before the release)
- Date: 2026-10-30
- Tags: replicated, read-modify-write, locks, routing
- Relates to: ADR 0070 (find and the `*_or_*` helpers)

## Context

`DBIO::Replicated::Storage` sends writes, transactions and `discard_changes` to
the master and balances reads over the replicants. A read that exists to decide
a write, and a read that takes a lock, belong to the master: the lookup has to
see what the writers see, and a lock only holds where the writers contend.

## Decision

### 1. Storage hook `_read_pool_for_read_modify_write`

`DBIO::Storage` defines `_read_pool_for_read_modify_write`; it answers nothing
(`undef`). `DBIO::Replicated::Storage` answers `'master'`.

`find_or_create`, `find_or_new`, `update_or_create`, `update_or_new` (and their
`_async` variants, which share the lookup) and the `upsert` fallback
`update_or_create` set the answer as `force_pool` in the attributes of their
lookup. It is set when the hook answers a value and the caller's attributes
name no `force_pool`; a `force_pool` of the caller stays. `DBIO::ResultSet`
knows the hook and nothing of Replicated.

### 2. The balancer routes a lock to the master

A select whose attributes carry `for` with any defined value (`'update'`,
`'shared'`, a driver's own lock word) is answered by the master. This holds for
`select`, `select_single` and `_select` of `DBIO::Replicated::Balancer`, in
and outside a transaction. `for => undef` is no lock.

### 3. Documented

`DBIO::Replicated` states the lag semantics of a replicant read,
`execute_reliably` and the methods that read on the master by themselves:
`discard_changes`, the four `*_or_*` helpers, the `upsert` fallback and every
select with a lock.

## Rationale

- **The lookup and the write meet on one database.** A row that only the
  master has yet is found, so `find_or_create` does not insert it twice.
- **One seam, no Replicated knowledge in the ResultSet.** The storage names the
  pool; the ResultSet passes it on as the attribute the balancer already honours.
- **The attribute is visible in the select arguments.** The balancer decides on
  `for`, the same value the SQL generator renders.
