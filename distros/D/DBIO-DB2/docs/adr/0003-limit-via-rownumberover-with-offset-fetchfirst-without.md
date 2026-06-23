# ADR 0003 — `apply_limit` branches on offset: `ROW_NUMBER() OVER` with an offset, `FETCH FIRST` without

- Status: accepted
- Date: 2026-06-21
- Tags: sqlmaker, limit, dialect, db2

## Context

This ADR is the DB2 specialisation of core ADR 0003 (*apply_limit replaces
limit_dialect*). Core removed the DBIx::Class `sql_limit_dialect` string +
`emulate_limit()` per-dialect matrix and replaced it with a single overridable
`apply_limit($sql, $rs_attrs, $rows, $offset)` method on the driver's SQLMaker —
the limit decision *is* the override, owned by the driver, with no central
dialect registration.

DB2 supports two windowing/pagination forms with different capabilities:

- `FETCH FIRST n ROWS ONLY` — a top-n clause. Simple, broadly supported, but it
  has **no offset**: it can take the first n rows but cannot skip a prefix.
- `ROW_NUMBER() OVER (...)` wrapped in a subquery — assigns a row number and
  filters on a range, which **does** express an offset (`OFFSET m` ≡ keep row
  numbers `> m`).

A resultset with no offset (a plain `LIMIT n`) only needs the cheaper top-n
form; a resultset *with* an offset needs the windowed form. So the right branch
key is **whether an offset is present**, not anything about the server.

## Decision

`DBIO::DB2::SQLMaker::apply_limit` (`SQLMaker.pm:16-25`) branches on the
presence of an offset:

    sub apply_limit {
      my ($self, $sql, $rs_attrs, $rows, $offset) = @_;
      if ($offset) {
        return $self->_RowNumberOver($sql, $rs_attrs, $rows, $offset);
      }
      return $self->_FetchFirst($sql, $rs_attrs, $rows, $offset);
    }

- **Offset present → `_RowNumberOver`.** When `$offset` is truthy, delegate to
  the `ROW_NUMBER() OVER` windowed rewrite, which is the only one of the two that
  can skip a prefix.
- **No offset → `_FetchFirst`.** When there is no offset, delegate to the
  `FETCH FIRST n ROWS ONLY` top-n form, which is sufficient and cheaper for a
  plain `LIMIT`.

**Offset-based branching is the intended, correct design** (maintainer-confirmed).

## Rationale

The branch key is a capability question, decided per query: `FETCH FIRST` cannot
express an offset, so any paged query that skips rows *must* go through
`ROW_NUMBER() OVER`, and a query that skips nothing should take the simpler
top-n clause. Selecting on `$offset` routes each query to the cheapest form that
can express it. This is the same shape as MSSQL (mssql ADR 0002) settling on a
single windowed path, except DB2 keeps both forms because, unlike pre-2012
MSSQL, DB2 has a genuinely useful no-offset top-n clause worth using when no
offset is needed.

**Doc-drift resolution.** Earlier prose (the `SQLMaker.pm` DESCRIPTION POD, the
`Storage.pm` DESCRIPTION, and `CLAUDE.md`) framed this as "auto-detected by
server version — `ROW_NUMBER() OVER` for DB2 5.4+, `FETCH FIRST` for older
versions." That framing is **inaccurate documentation, not a code bug**: the
code has never inspected a server version; it has always branched on `$offset`.
The misleading in-code comments at `SQLMaker.pm:19-20` describe a version story
the surrounding code does not implement. This ADR records the resolution: the
**offset-based branch is correct as written**, and the version-detection prose
is the thing to fix. The accompanying doc-drift fix corrects `CLAUDE.md` and the
`SQLMaker.pm` POD to describe the offset branch; the executable code in
`apply_limit` is unchanged.

## Consequences

- Two pagination code paths, selected per query by offset presence:
  unpaged/top-n queries get `FETCH FIRST`; offset/paged queries get
  `ROW_NUMBER() OVER`. Both reach DB2's standard pagination forms.
- The selection is **not** version-gated. There is no server-version probe and
  none is needed; a future maintainer must not add one on the strength of the
  old prose. `_RowNumberOver` requires a DB2 that supports `ROW_NUMBER() OVER`
  (DB2 V8 / 5.x-era and later), which is the same broad floor the rest of the
  driver assumes.
- The in-code comments at `SQLMaker.pm:19-20` still narrate the version story;
  they are POD-adjacent line comments left untouched here per scope. They are
  descriptive only and do not affect behaviour, but they are the residual
  carrier of the inaccurate framing this ADR resolves and should be corrected
  the next time `SQLMaker.pm` is edited for behaviour.
- See core ADR 0003 for the cross-driver `apply_limit` mechanism this
  specialises, and mssql ADR 0002 for the sibling single-windowed-path
  precedent.

## Related

- core ADR 0003 (`apply_limit` replaces `limit_dialect` — the mechanism)
- mssql ADR 0002 (LIMIT via `ROW_NUMBER() OVER` only — sibling windowed-path
  precedent)
