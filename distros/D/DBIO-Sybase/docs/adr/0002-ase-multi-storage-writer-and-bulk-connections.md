# ADR 0002 — ASE storage owns auxiliary writer and bulk connections

- Status: accepted
- Date: 2026-06-20
- Tags: storage, ase, transactions, blob, bulk

## Context

Every other DBIO driver (PostgreSQL, MySQL, SQLite, Oracle) follows the
standard pattern: one `Storage` object wraps exactly one DBI handle. Sybase
ASE breaks that model. `DBIO::Sybase::Storage::ASE` (`_init`) provisions up to
**three** sibling storage objects from one logical connection:

- the *primary* storage (the user-facing object);
- a `_writer_storage` — a second full storage/connection used to run
  insert/update operations that must be wrapped in their own transaction;
- a `_bulk_storage` — a third connection opened with `;bulkLogin=1` appended to
  the DSN, used for the `DBD::Sybase` bulk-copy (BCP) API.

The auxiliary storages hold a weakened `_parent_storage` backref, and a static
list (`@also_proxy_to_extra_storages`) installs proxy wrappers so that
connection-affecting calls (`disconnect`, `_connect_info`, `debug`, `schema`,
the `connect_call_*` setup hooks, ...) fan out to all three handles.

## Decision

Keep the three-connection architecture in `Storage::ASE`. Do **not** try to
collapse it to a single DBH to match the other drivers.

## Rationale

Two ASE constraints make a single connection insufficient, and both are
correctness issues, not optimisations:

1. **Atomic blob + identity writes.** TEXT/IMAGE columns cannot be bound as
   placeholders; they are written in a second round-trip
   (`ct_send_data`, see `Storage::ASE::LOBWriter`) *after* the row exists, and
   the generated identity is recovered with `SELECT MAX(col)` (ADR 0004). The
   row-insert, the identity read, and the blob write must sit inside one
   transaction that the *primary* connection's own (possibly autocommit, possibly
   already-open) transaction state must not perturb. `insert`/`update` therefore
   delegate to `_writer_storage->txn_scope_guard` whenever a blob or a
   dumb-last-insert-id is in play.
2. **Bulk login is a connection-level mode.** `;bulkLogin=1` changes the whole
   session and a bulk-login connection is permanently inside a transaction
   (`TxnManager::_exec_txn_begin` guards the once-only `BEGIN TRAN`). It cannot
   be the connection that also services ordinary queries, so BCP needs its own
   handle.

Folding these onto one DBH would either corrupt the caller's transaction state
or make blob/bulk support impossible — exactly the breakage this structure
exists to prevent.

## Consequences

- `Storage::ASE` is heavier than a typical driver storage and the proxy-fanout
  in `@also_proxy_to_extra_storages` is load-bearing: any new
  connection-affecting setter that must stay coherent across handles has to be
  added to that list, or the writer/bulk connections will silently drift from
  the primary.
- The auxiliary storages are created lazily in `_init` and skipped when
  `_parent_storage` is already set (they must not recurse) and when
  `connect_info` is a CODEREF (bulk is disabled, with a `carp_unique`).
  Bulk is also skipped under FreeTDS, whose blk-library cannot do BCP
  (`Type '7' not implemented`, and `BULK INSERT` is rejected inside the
  permanently-open bulk transaction); `_insert_bulk` then falls back to
  regular array inserts (karr #20).
- This is **Sybase-only**. No other DBIO driver should grow a writer/bulk
  storage; if a future engine needs the same, lift the pattern into a shared
  base rather than copying it.
- Coverage is live-DB only (`t/10-sybase.t`, `t/20-sybase-core.t`, skipped
  without a server); there is no offline harness for the three-connection
  dance.
