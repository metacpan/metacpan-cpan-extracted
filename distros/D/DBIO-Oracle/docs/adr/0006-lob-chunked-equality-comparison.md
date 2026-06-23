# ADR 0006 — LOB equality predicates rewritten into chunked DBMS_LOB.SUBSTR comparisons

- Status: accepted
- Date: 2026-06-22
- Tags: storage, lob, blob, clob, comparison, oracle

## Context

Oracle does not let you compare a LOB column directly to a bind value in SQL —
`WHERE blob_col = ?` against a BLOB/CLOB is not valid the way it is for ordinary
columns. But DBIO routinely generates exactly that shape: an `update` whose WHERE
clause references a LOB column, or a `select`/`delete` matching on a LOB. The
storage layer therefore has to rewrite any equality predicate on a LOB column
into something Oracle accepts, transparently, without the ORM caller knowing the
column is a LOB.

Oracle's portable building block for reading a LOB piecewise is
`DBMS_LOB.SUBSTR`, and the comparable VARCHAR2 form of a chunk is
`UTL_RAW.CAST_TO_VARCHAR2(RAWTOHEX(...))`. Oracle also limits a VARCHAR2 to a few
thousand bytes, so a large LOB cannot be compared in one piece — it must be split
into bounded chunks compared with AND.

## Decision

`DBIO::Oracle::Storage::LOBSupport::_prep_for_execute` detects LOB binds in the
WHERE clause and rewrites each `<col> = ?` predicate into an AND of 2000-byte
chunk comparisons (`Storage/LOBSupport.pm:55-146`):

- It runs only for `update` / `select` / `delete` (insert is passed straight
  through, `LOBSupport.pm:59`); for `update` it splits SET binds off from WHERE
  binds first and refuses complex multi-WHERE clauses
  (`LOBSupport.pm:76-94`).
- For each LOB bind it splits the bound value into 2000-char parts
  (`unpack '(a2000)*'`) and, for part *i*, emits
  `UTL_RAW.CAST_TO_VARCHAR2(RAWTOHEX(DBMS_LOB.SUBSTR(<col>, 2000, <offset>))) = ?`
  joined with `AND` inside parentheses, replacing the original `<col> = ?`
  (`LOBSupport.pm:99-130`). Each chunk becomes its own bind, tagged with
  `_ora_lob_autosplit_part => <i>` and `dbd_attrs => undef`.
- The chunk-part tag drives a separate cache decision: `_dbh_execute` disables
  statement-handle caching for the duration when any bind's
  `_ora_lob_autosplit_part` exceeds `__cache_queries_with_max_lob_parts` (= 2)
  (`Storage.pm:34`, `133-161`) — i.e. multi-chunk LOB comparisons run uncached.

Binding itself is handled by `bind_attribute_by_data_type` returning
`ora_type => ORA_BLOB/ORA_CLOB` for LOB columns (`LOBSupport.pm:31-53`,
delegating to `DBIO::Oracle::Type::oracle_lob_bind_attrs`).

## Rationale

Rewriting the predicate in `_prep_for_execute` is the right seam because it is
the last point before SQL leaves the storage layer and it already sees the
final SQL and bind list — so the rewrite is invisible to every higher layer
(ResultSet, the SQLMaker, the user). Doing it anywhere higher would leak
Oracle-specific SQL into portable code.

The 2000-char chunking is forced by Oracle's VARCHAR2 size ceiling: a LOB larger
than one chunk *cannot* be compared in a single expression, so the AND-of-chunks
is not an optimisation but a correctness requirement. The
`UTL_RAW.CAST_TO_VARCHAR2(RAWTOHEX(...))` wrapping makes binary BLOB chunks
comparable as text and keeps CLOB and BLOB on one code path.

Disabling sth caching for multi-chunk comparisons is the load-bearing pairing:
the rewritten SQL's shape (number of AND'd chunks) varies with the LOB's length,
so caching a prepared handle keyed on the statement would cache a statement
whose placeholder count is wrong for the next value — and would also risk cursor
exhaustion as each distinct length produces a distinct statement. The
`_ora_lob_autosplit_part` tag is the signal that couples the rewrite to that
cache decision; the two must stay in sync.

## Consequences

- Equality matching on LOB columns "just works" through the normal DBIO API for
  update/select/delete, with no caller awareness of the rewrite.
- Multi-chunk LOB comparisons are **uncached** by design — a deliberate
  throughput trade to keep placeholder counts correct and avoid cursor
  exhaustion. The threshold lives in `__cache_queries_with_max_lob_parts`
  (`Storage.pm:34`).
- `update` with a complex multi-WHERE clause involving LOB columns is explicitly
  unsupported and throws (`LOBSupport.pm:77-78`).
- The rewrite, the chunk tag, and the cache-disable in `_dbh_execute` are a
  single mechanism spread across `LOBSupport.pm` and `Storage.pm`; changing the
  chunk size, the tag name, or the threshold requires touching all three in
  lock-step.
- `_prep_for_execute` overrides a `DBIO::Storage::DBI` method and chains via
  `next::method`, so `LOBSupport` must precede the base in the MRO (ADR 0001).

## Related

- ADR 0001 (storage mixin composition + MRO ordering — why `LOBSupport` precedes
  `DBIO::Storage::DBI`, the exact case the ordering rule protects)
- ADR 0008 (offline loadability — LOB *binding* lazy-loads DBD::Oracle, while the
  LOB *type predicates* are pure and load offline)
