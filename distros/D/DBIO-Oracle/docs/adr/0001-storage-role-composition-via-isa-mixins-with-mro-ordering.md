# ADR 0001 — Storage cross-cutting behaviour composed via ISA mixins, not Exporter roles

- Status: accepted
- Date: 2026-06-22
- Tags: storage, composition, mro, oracle, drivers, architecture

## Context

Oracle's storage layer carries an unusually large amount of cross-cutting
behaviour for a single driver: LOB binding and chunked comparison,
sequence/auto-increment discovery, savepoints, FK-constraint deferral, and
NLS-format connect-time setup. Lumping all of it into one
`DBIO::Oracle::Storage` body would make the file hard to navigate and would
mix five unrelated concerns in one namespace.

The DBIO base `DBIO::Storage::DBI` is itself a composition of mixin packages,
and the upstream DBIx::Class Sybase driver uses the same idiom. The seductive
wrong turn is to factor the concerns into "roles" and pull them in with an
Exporter import (`use Role qw(method)`). That is fatal here: an imported sub's
CV still reports the *role* package as its origin, and the role is in no MRO —
so any role method that calls `$self->next::method(...)` cannot find the next
implementation and dies with "No next::method 'X' found". Several Oracle
concerns (`LOBSupport::_prep_for_execute`, `Savepoints::_dbh_execute_for_fetch`,
`LOBSupport::_dbi_attrs_for_bind`) *override* a `DBIO::Storage::DBI` method and
chain forward via `next::method`, so they must be reachable through the MRO.
This bit Oracle's `_prep_for_execute` in practice — latent in the live driver,
fatal under the offline `DBIO::Test::Storage` hybrid.

## Decision

Decompose each concern into its own plain package under
`DBIO::Oracle::Storage::*` and compose them into `DBIO::Oracle::Storage` via
`use base` (ISA) under `use mro 'c3'` — never via Exporter import
(`Storage.pm:7-20`):

    use base qw/
      DBIO::Oracle::Storage::LOBSupport
      DBIO::Oracle::Storage::AutoIncrement
      DBIO::Oracle::Storage::Savepoints
      DBIO::Oracle::Storage::FKDeferral
      DBIO::Oracle::Storage::ConnectSetup
      DBIO::Storage::DBI
    /;
    use mro 'c3';

- The mixin packages are plain `package` files with no `Exporter`, no
  `@EXPORT`; each defines methods and documents in a header comment what the
  consuming class must provide.
- **Ordering is load-bearing.** Any mixin that *overrides* a
  `DBIO::Storage::DBI` method (then calls `next::method`) must precede
  `DBIO::Storage::DBI` in the `use base` list so its override wins and its
  `next::method` chains forward to the base — hence `LOBSupport` and
  `Savepoints` come before `DBIO::Storage::DBI`. The in-code comment
  (`Storage.pm:7-11`) records this.
- `DBIO::Oracle::Storage::WhereJoins` extends the composed `Storage` and itself
  uses `mro 'c3'` (`Storage/WhereJoins.pm:7-8`) — see ADR 0007.

## Rationale

ISA + C3 puts every mixin method in the resolution order, so `next::method`
resolves and the override-then-delegate pattern works both live and offline.
The Exporter-import alternative is not merely less tidy — it is broken for any
method that delegates upward, which is most of Oracle's interesting overrides.
Choosing ISA mirrors how `DBIO::Storage::DBI` and the Sybase driver compose
their own behaviour, so a maintainer who knows one knows all.

The ordering constraint is not stylistic: place an overriding mixin *after*
`DBIO::Storage::DBI` and the base method wins instead, silently dropping the
Oracle behaviour (LOB splitting, savepoint fetch quirk) with no error. The
comment block at the top of `Storage.pm` exists to stop a future "alphabetise
the base list" cleanup from reordering it.

## Consequences

- New cross-cutting Oracle behaviour goes in its own `Storage::*` mixin and is
  added to the `use base` list — before `DBIO::Storage::DBI` if it overrides a
  base method, after the other concern mixins otherwise.
- **Do not** convert these mixins to Exporter-style roles, and do not reorder
  the `use base` list without checking which mixins override a base method.
  Point such proposals here.
- The mixins are not standalone storage classes — they are abstract behaviour
  carriers with no `register_driver` and assume the composed `Storage`'s
  helpers (e.g. `_is_lob_type`, see ADR 0008).

## Related

- ADR 0006 (LOB chunked comparison — lives in the `LOBSupport` mixin and is one
  of the override-then-delegate methods this ordering protects)
- ADR 0007 (WhereJoins storage subclass layered on top of the composed Storage)
- ADR 0008 (offline loadability — the same `_prep_for_execute` path that the
  MRO bug broke is what must stay reachable without DBD::Oracle)
- firebird ADR 0001 (three-layer storage inheritance — the other driver that
  documents a non-default storage class shape)
