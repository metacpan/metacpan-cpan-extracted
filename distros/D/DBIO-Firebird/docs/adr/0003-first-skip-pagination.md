# ADR 0003 — FIRST/SKIP pagination via apply_limit override

- Status: accepted
- Date: 2026-06-20
- Tags: sqlmaker, limit, pagination, firstskip

## Context

Firebird has no `LIMIT`/`OFFSET` keyword. It slices a result set with
`SELECT FIRST n SKIP m ...`, placed immediately after `SELECT`. The default
DBIO SQL maker emits the SQL-standard `LIMIT ? OFFSET ?`
(`DBIO::SQLMaker::ClassicExtensions::apply_limit`,
`lib/DBIO/SQLMaker/ClassicExtensions.pm:617` in dbio core), which Firebird does
not understand.

Upstream DBIx::Class expressed Firebird's slicing by setting
`sql_limit_dialect = 'FirstSkip'`, a *string* that the storage layer's central
limit-dialect matrix dispatched on. DBIO removed that mechanism entirely:
core ADR 0003 (apply_limit replaces limit_dialect / emulate_limit) moved the
limit decision out of storage and onto an overridable `apply_limit` method on
the SQLMaker subclass.

## Decision

`DBIO::Firebird::SQLMaker` (subclass of `DBIO::SQLMaker`) overrides
`apply_limit` to emit FIRST/SKIP, replacing the upstream `'FirstSkip'` dialect
string with a method override (`lib/DBIO/Firebird/SQLMaker.pm:32-35`):

    sub apply_limit {
      my ($self, $sql, $rs_attrs, $rows, $offset) = @_;
      return $self->_FirstSkip($sql, $rs_attrs, $rows, $offset);
    }

`_FirstSkip` is the inherited implementation from core's
`DBIO::SQLMaker::ClassicExtensions` (`ClassicExtensions.pm:725`); this driver
selects it by override rather than by registering a dialect name. The SQL maker
class is wired in once on the shared storage base
(`Storage/Common.pm:18`, `sql_maker_class('DBIO::Firebird::SQLMaker')`), so
both the Firebird and InterBase backends use it.

## Rationale

Firebird's slicing syntax is fundamentally different from `LIMIT`/`OFFSET`, so
some override is unavoidable. Doing it as an `apply_limit` method override is
the post-fork DBIO idiom (core ADR 0003): the behaviour *is* the override,
owned by the driver's SQLMaker, with no string round-trip through a central
storage matrix. Delegating to the inherited `_FirstSkip` keeps the actual
SQL-shaping logic in core where the other emulated dialects live, so this
driver carries only the one-line decision "Firebird uses FIRST/SKIP", not a
re-implementation of it.

## Cross-repo: apply_limit as the sanctioned extension point

Whether `apply_limit` is the sanctioned, stable core extension point for
per-driver limit syntax — and whether `_FirstSkip` is a public-enough seam for
drivers to call — is a **core-owned decision**, recorded in dbio core ADR 0003
(apply_limit replaces limit_dialect / emulate_limit). This ADR consumes that
contract; it does not re-decide it. If the extension point's name or signature
changes upstream, that is tracked on the core board, not here.

## Consequences

- Firebird LIMIT/OFFSET is a SQLMaker concern; pagination changes go in
  `DBIO::Firebird::SQLMaker`, not in storage and not by reintroducing a
  dialect string.
- The override must keep the 4-argument core signature
  `apply_limit($sql, $rs_attrs, $rows, $offset)` — it consumes `$rs_attrs`
  and forwards all four to `_FirstSkip`.
- This driver is coupled to core continuing to provide `_FirstSkip`; that
  coupling is the cross-repo contract noted above.
