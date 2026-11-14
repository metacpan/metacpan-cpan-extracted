# Capabilities: contract version, DDL, upsert, EXISTS, set operations

Reference for `dbio-core`. Load when changing a capability or the shape of a driver base
class. The tier mechanics and the full seam table are in `dbio-driver-development`,
`references/storage-seams.md`; this file holds the contracts behind them.

## Driver contract versioning (ADR 0024)

The five base classes out-of-tree drivers subclass carry `$CONTRACT_VERSION` and a
`contract_version()` accessor:

- `DBIO::Introspect::Base`
- `DBIO::Diff::Base`
- `DBIO::Deploy::Base`
- `DBIO::SQLMaker`
- `DBIO::Storage::DBI::Capabilities`

The contract version advances when the public shape changes in a way drivers can observe
(new method, new capability, signature change). The current values are the ones
`t/test/12_contract_version.t` asserts; that test is the tripwire, and a bump updates it in
the same change.

## DDL transactional safety + IF EXISTS (ADR 0026)

Two capabilities on `DBIO::Storage::DBI::Capabilities`, both default 0 (conservative):

- `transactional_ddl` — `__PACKAGE__->_use_transactional_ddl(1)` opts in. True for engines
  that honour DDL inside a transaction (Pg yes; MySQL, Oracle, DB2, Sybase, Informix no;
  SQLite explicitly no — its rebuild path needs `AutoCommit=on`).
- `supports_if_exists` — `__PACKAGE__->_use_supports_if_exists(1)` opts in. Engines that
  parse `DROP TABLE IF EXISTS` and the like.

Deploy::Base and DeploymentHandler probe the capability before wrapping DDL in
`$storage->txn_do`; a driver that does not opt in is non-transactional. For diff
renderers, `Diff::Op::should_emit_if_exists($storage)` is the single emit site of the
IF-EXISTS question. It probes `_use_supports_if_exists`, the accessor the capability
registration mints: a capability named `X` mints `_use_X` and `_supports_X`, and probing a
name nobody registers is silently inert.

## Atomic upsert (ADR 0036) and the EXISTS / set-operation seam (ADR 0037, 0039)

Capabilities that refuse rather than degrade: an engine whose driver has not declared one
throws instead of falling back to a racier or differently-shaped query. Both default 0.

- `supports_upsert` — `__PACKAGE__->_use_supports_upsert(1)`. Gates `$rs->upsert`, the
  single-statement server-side upsert. Rendering the `on_conflict` clause belongs to the
  driver SQLMaker; the base generator throws rather than silently dropping it.
- `supports_exists_query` — `__PACKAGE__->_use_supports_exists_query(1)`. Gates
  `results_exist` and its two siblings, paired with the storage hook
  `_exists_value_sql($inner_sql)` that returns a complete statement yielding 1 or 0. Core's
  base rendering is the standard `SELECT CASE WHEN EXISTS <inner> THEN 1 ELSE 0 END`; an
  engine that also refuses a `FROM`-less `SELECT` overrides it with its dummy table
  (Oracle `DUAL`, DB2 `SYSIBM.SYSDUMMY1`, Firebird `RDB$DATABASE`).

All six set operations run through one hook without a flag (ADR 0039):
`_set_operation_keyword($op)`, asked with the canonical op name — `union`, `union_all`,
`intersect`, `intersect_all`, `except`, `except_all` — and answering that operation's ANSI
keyword by default (`'MINUS'` for `except` on Oracle). It **spells** the operation for the
engine or **refuses** it: an engine without `EXCEPT ALL` (Oracle before 21c, SQLite,
SQL Server) throws from its own driver, naming engine and version, because a refusal that
names a version can only be written where that version is known. Override only the ops you
have an opinion about and delegate the rest to `$self->next::method($op)`; an unknown op is
a core programming error and the base throws, listing the six.
