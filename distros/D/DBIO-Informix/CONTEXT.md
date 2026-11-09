# CONTEXT — DBIO::Informix domain language

Shared vocabulary for this driver. Use these terms exactly in code, commits,
and architecture reviews.

## Core concepts

- **Introspected model** — the unified hashref produced by
  `DBIO::Informix::Introspect` from the live database (`tables`, `columns`,
  `indexes`, `foreign_keys`). The shared substrate consumed by both **Diff**
  and the **generation contract**.

- **Generation contract** — the seven normalized methods from
  `DBIO::Introspect::Base` (`table_keys`, `table_columns`,
  `table_columns_info`, `table_pk_info`, `table_uniq_info`, `table_fk_info`,
  `table_is_view`) that let an introspector act as a `DBIO::Generate` source.

- **Test-deploy-and-compare** — the deploy strategy: introspect live, deploy
  the desired DDL into a throwaway, introspect that, diff the two
  introspected models.

- **Column-definition renderer** (`DBIO::Informix::ColumnDef`) — the single
  module that owns the grammar of one Informix column definition
  (`name type [NOT NULL] [DEFAULT ...]`). `DDL`, `Diff::Table` and
  `Diff::Column` all delegate to it. It owns three dialect rules:
  - `SERIAL` is a *type*, not a modifier — it is never doubled and never
    combined with a base type.
  - default quoting is *type-aware*: character types quote a plain-scalar
    default, numeric types emit it raw.
  - a `SCALAR` ref default is literal SQL (e.g. `\'today'`), emitted unquoted.

  Type *normalization* deliberately stays with each caller: the diff path
  carries a full SQL type string (`varchar(255)`); the DDL path resolves a
  logical type via `_informix_column_type`.

- **Type vocabulary** (`DBIO::Informix::Types`) — the single source of truth
  for Informix types, mapping both ends of the round-trip: the
  `syscolumns.coltype` number to a **logical type name**
  (`logical_for_coltype`, used by introspection) and a logical type name to
  the Informix SQL type string (`ddl_type`, used by DDL). The logical type
  name is the shared contract between the two sides.
