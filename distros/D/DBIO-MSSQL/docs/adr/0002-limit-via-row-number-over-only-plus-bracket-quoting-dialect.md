# ADR 0002 — LIMIT/OFFSET only via ROW_NUMBER() OVER (SELECT(1)); no Top path; bracket quoting & SQLServer dialect

- Status: accepted
- Date: 2026-06-20
- Tags: sqlmaker, limit, dialect, quoting

## Context

This ADR is the MSSQL specialisation of core ADR 0003
(*apply_limit replaces limit_dialect*). Core removed the DBIx::Class
`sql_limit_dialect` / `limit_dialect` string-dispatch and replaced it with a
per-driver `apply_limit($sql, $rs_attrs, $rows, $offset)` method on the
driver's SQLMaker.

DBIx::Class's MSSQL support carried **two** limit dialects selected at runtime
from the server version: `RowNumberOver` (SQL Server 2005+) and the older
`Top` rewrite. MSSQL has no `LIMIT`/`OFFSET` keyword before 2012's
`OFFSET ... FETCH`.

There are also two dialect-shape decisions that distinguish MSSQL identifiers
and SQL::Translator naming from the core default.

## Decision

1. **Always `ROW_NUMBER() OVER`, never Top.** `DBIO::MSSQL::SQLMaker`
   implements `apply_limit` (`SQLMaker.pm:32-35`) to unconditionally call
   `_RowNumberOver`. The historical `Top` dialect is deliberately **not**
   implemented in this driver.
2. **Override the empty `OVER()` order.** `_rno_default_order`
   (`SQLMaker.pm:40-42`) returns `\ '(SELECT(1))'`, because MSSQL rejects an
   empty `OVER()` clause — the core base leaves the default order undef
   (empty `OVER()`), which is invalid here.
3. **Bracket quoting (asymmetric).** `DBIO::MSSQL::Storage` sets
   `sql_quote_char([qw/[ ]/])` (`Storage.pm:27`) so identifiers quote as
   `[name]` rather than the core `"name"`.
4. **SQL::Translator name.** `sqlt_type` returns `'SQLServer'`
   (`Storage.pm:224`).

## Rationale

No DBIO driver emits `Top`: the `_Top` rewrite lives only in core for
backward compatibility, and MSSQL's `apply_limit` has a single
`_RowNumberOver` code path. Carrying a server-version branch to a dialect the
driver never selects is dead weight. This was confirmed in the pre-squash
test sweep (karr `dbio-mssql` #7): the stale `t/sqlmaker/limit_dialects/`
tests that exercised the removed `limit_dialect` API were ported —
`rno.t` regenerated against the real `(SELECT(1))` default-order output, and
`toplimit.t` **deleted as obsolete** because no MSSQL path emits `Top`.

`OFFSET ... FETCH` (2012+) is intentionally not used: `ROW_NUMBER() OVER` is
the broadly compatible windowing form supported back to SQL Server 2005.

## Consequences

- One pagination code path to reason about and test; the SQLMaker stays thin.
- MSSQL before 2005 is unsupported for limited queries — acceptable; those
  versions are long out of support.
- The asymmetric `['[', ']']` quote char and `SQLServer` sqlt_type are part
  of the dialect contract; SQL-generation tests assert `[bracketed]`
  identifiers, not double-quoted ones.
- See core ADR 0003 for the cross-driver `apply_limit` mechanism this
  specialises.
