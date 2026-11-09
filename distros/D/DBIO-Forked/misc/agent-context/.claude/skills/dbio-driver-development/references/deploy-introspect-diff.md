# Deploy, Introspect, Diff, DDL

Reference for `dbio-driver-development`. Load when a driver installs, introspects or
diffs a schema. Core's `DBIO::Deploy::Base` carries the machinery; a driver fills hooks.

## Wiring

- **`sub dbio_deploy_class { 'DBIO::X::Deploy' }`** on the storage class (ADR 0064).
  `DBIO::Storage::DBI::deploy` and `DBIO::Schema::deploy` install through it: deploy
  connects first, so the adapted storage answers, then runs
  `->new(schema => $schema)->install`; a DDL file is not executed in its place. A storage
  without a Deploy class keeps the DDL-file route (executes an existing file, throws
  without one). A driver does not override `deploy`. `deployment_statements` stays the
  reader of a DDL file.
- **`dbio_deploy_class` has one owner: the driver storage** (ADR 0066 §4). A storage layer
  does not define it, and the chainable hooks of `DBIO::Storage::Composed` are empty: there
  is no layer chain and no synthesised Deploy class. What database extensions add to a
  deploy comes through the declared extension list, which the driver's Deploy class runs
  (`references/extension-layers.md`).
  **Trap:** define it *after* `use namespace::clean` — a sub declared before it is wiped
  at end of compile and deploy falls back to the unsupported SQL::Translator path
  (`DBIO::SQLite::Storage` carries this comment).
- **`DBIO::Deploy::Base` subclass** supplies `_ddl_class`, `_introspect_class`,
  `_diff_class` (each dies until provided). A temp-database build needs the DSN-shape
  hook `_temp_dsn` (ADR 0020, `Deploy::Base::TempDatabase`); the target model comes from
  `_build_target_model`.
- Layout: `Deploy.pm`, `DDL.pm`, `Introspect.pm` + `Introspect/<Kind>.pm` (the
  subdirectory helper pattern is mandatory, ADR 0018), `Diff.pm` + `Diff/<Kind>.pm`.
  Native deploy owns SQL generation (ADR 0006); introspect/diff layer: ADR 0007.
- The canonical introspect model is described in `DBIO::Introspect::Base`
  ("CANONICAL MODEL"); `data_type` is the type name, `size` the canonical scalar/arrayref.

## Declarations a driver makes

| Declaration | Where | Meaning |
|---|---|---|
| `__PACKAGE__->_use_transactional_ddl(0\|1)` (or `_determine_supports_transactional_ddl`) | storage | state it explicitly; MySQL/MariaDB/SQLite 0 (ADR 0026) |
| `_ddl_statement_is_transactional($stmt)` | storage | return false for statements that must not sit in a transaction (PG `ALTER TYPE … ADD VALUE`, `CREATE INDEX CONCURRENTLY`) |
| `__PACKAGE__->_use_supports_if_exists(0\|1)` | storage | `IF [NOT] EXISTS` guards in diff ops |
| `sub _ddl_sql_dialect { 'postgresql'\|'sqlite'\|'mysql' }` | storage | how the DDL splitter reads backslashes in literals; undef when not declared, unknown name throws |

Split DDL with `DBIO::SQL::Util::_split_statements`, never a private `split /;/`.

## Column and index rules

- **Missing `is_nullable` means NOT NULL** (ADR 0043): emit NOT NULL for `!$info->{is_nullable}`.
- **Index declaration is canonical on the ResultSource** (ADR 0061). The DDL emitter *and*
  the diff's desired-model builder read
  `$source->index_declarations_for($driver, \@allowed_keys)`; hand-written
  `pg_index`/`sqlite_index`/`mysql_index` blocks stay valid, the canonical declaration
  wins on equal names. An attribute the driver cannot implement is refused with class,
  index and attribute — never silently simplified. Optional `index_type` (ADR 0052) is
  filled on both sides (introspect and desired model) or not at all.
- **Conformance** (ADR 0060): `DBIO::Test::Conformance` is the shared case table for the
  areas DDL, Diff and Bind (the DDL list ships; Diff and Bind follow). The driver ships
  `DBIO::<X>::Test::Conformance`, a subclass, with `conformance_refusals`
  (`kind => 'server'|'pending'`, pending carries a card) and `conformance_answered_through`
  (the `table_version` its answers were written against; newer cases are red only under
  `AUTHOR_TESTING`/`RELEASE_TESTING`). Every case ends *correct* or *refuses*; there is no
  declared deviation. Test files call `->run('DDL')`. The async transport dists run the
  Bind list over their transport.

## Errors

A statement the server rejects surfaces as `DBIO::Exception::Server` with `sqlstate`
(ADR 0062). Sync path: override `_dbi_error_fields($handle)` and extend through
`next::method` when the DBD names constraint/table/detail. Async: the transport fails the
Future with the object.
