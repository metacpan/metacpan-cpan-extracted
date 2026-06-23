# ADR 0002 — Force SQL dialect 3 on connect

- Status: accepted
- Date: 2026-06-20
- Tags: storage, interbase, dsn, dialect, connect

## Context

Firebird/InterBase has three SQL dialects. Dialect 1 is the legacy InterBase
compatibility mode; dialect 3 is the modern mode that enables double-quoted
delimited identifiers, the `BIGINT` / `TIMESTAMP` / `TIME` types and exact
`DECIMAL`/`NUMERIC` semantics. **DBD::InterBase connects in dialect 1 by
default.**

DBIO::Firebird depends on dialect-3 behaviour throughout: the storage base sets
the quote char to `"` (`Storage/Common.pm:17`), and the type system and
introspection assume dialect-3 type semantics. Running against the DBD default
(dialect 1) would break identifier quoting and type handling.

## Decision

Force SQL dialect 3 at connect time. `DBIO::Firebird::Storage::InterBase`
overrides `_init` to call `_set_sql_dialect(3)`
(`Storage/InterBase.pm:50-71`):

- `_init` runs `_set_sql_dialect(3)`.
- `_set_sql_dialect` rewrites the DSN: if the DSN does not already contain
  `ib_dialect=`, it appends `;ib_dialect=$val` to
  `_dbi_connect_info->[0]`, then disconnects and (if it had been connected)
  reconnects so the new dialect takes effect.
- A code-ref DSN is left untouched (`return if ref($dsn) eq 'CODE'`), and an
  explicit `ib_dialect=` already in the DSN is respected (the rewrite is
  guarded by `if ($dsn !~ /ib_dialect=/)`).

The in-code comment states the reason plainly: "We want dialect 3 for new
features and quoting to work, DBD::InterBase uses dialect 1 (interbase compat)
by default" (`Storage/InterBase.pm:50-51`).

## Rationale

The rest of the driver is written for dialect 3 — double-quote identifier
quoting, modern types, exact decimals — so dialect must be pinned, not left to
the DBD default. Doing it by DSN rewrite (rather than a post-connect `SET SQL
DIALECT`) means the dialect is established by the connection itself and survives
the disconnect/reconnect the storage layer performs. Guarding on an existing
`ib_dialect=` lets a caller who deliberately wants a different dialect override
it, and skipping code-ref DSNs avoids mangling a connect-coderef the storage
layer cannot safely string-edit.

## Consequences

- Connecting through this driver always uses dialect 3 unless the caller
  pins a different `ib_dialect=` in the DSN. Code that assumed dialect-1
  semantics (e.g. unquoted case-folding, dialect-1 date type) will behave
  differently.
- The dialect is applied by mutating `_dbi_connect_info->[0]` and forcing a
  reconnect inside `_set_sql_dialect`; this disconnect/reconnect is intrinsic
  to making the dialect stick and must not be "optimised away".
- Both the DBD::Firebird (`Storage`) and DBD::InterBase
  (`Storage::InterBase`) backends get dialect 3, because the override lives on
  the shared `Storage::InterBase` layer (ADR 0001).
