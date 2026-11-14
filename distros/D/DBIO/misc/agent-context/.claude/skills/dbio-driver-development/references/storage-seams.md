# Storage seams a driver may override

Reference for `dbio-driver-development`. Each seam has its POD in `DBIO::Storage::DBI`
(or `::Capabilities`); this lists the trigger and the contract in one line.

## Capabilities (ADR 0041, three tiers)

`$storage->_use_X` answers with the first defined of:

1. the instance force `$storage->_use_X(0|1)` — the caller's slot; `_use_X(undef)` clears it;
2. the class declaration `__PACKAGE__->_use_X(0|1)` in the driver storage — a static fact,
   answerable before any connection;
3. `sub _determine_supports_X` — a probed fact (e.g. `_server_info->{normalized_dbms_version}`),
   cached in `_supports_X`, wiped on reconnect.

A driver uses 2 or 3 and never writes 1. Read `_use_X`, not `_supports_X`. A capability
nobody declared reads 0 and the core method that depends on it **throws** (upsert, exists
query, set operations) — declare every one the engine has. A driver's own capability:
`mk_group_accessors(dbms_capability => '_supports_X')` plus
`mk_group_accessors(use_dbms_capability => '_use_X')`; declare it on the
class before the first connection (`DBIO::X::Storage->_use_X(1)`) or `set_use_dbms_capability('_use_X', 1)`.

## Seams

| Seam | Trigger |
|---|---|
| `_connect_params_dsn($driver, \%params)` | DBD does not take `dbi:<DBD>:dbname=…;host=…;port=…` (ADR 0057) |
| `_bind_host_into_dsn($driver, $dsn, $host, $port)` | host must go into a finished DSN for a HostBound broker/replica; refuse forms you cannot translate (ADR 0013 addendum) |
| `_dbd_attribute_prefixes($driver)` | DBD attribute prefix DBI does not know |
| `register_access_path_dbd(@dbd)` | transport is a foreign driver's DBD (ClickHouse over mysql) — instead of overriding `_check_access_path_dbd` |
| `_set_connection_schema($name)` | engine has namespaces; connect key `schema` (ADR 0065). Default throws; set the namespace via `_do_query` so it reaches pool connections |
| `_dbio_storage_option_names` (+ `_dbio_storage_option_accessor_map`) | the driver adds connect options of its own: extend the SUPER list, register an accessor per name (ADR 0048) |
| `connect_call_*` / `disconnect_call_*` | session setup; send statements through `_do_query` so pool connections get them (ADR 0049). Examples: `connect_call_set_strict_mode` (MySQL), `connect_call_use_foreign_keys` (SQLite) |
| `_explain_query($sql, \@bind)` → `\@rows` | EXPLAIN is not "`EXPLAIN $sql` returns rows" (ADR 0040). Run statements through `_execute_rendered` / `_prepare_rendered` |
| `_prep_rendered_for_execute($sql, $bind)` | the driver rewrites statements in `_prep_for_execute`; mirror it for the rendered path |
| `_set_operation_keyword($op)` | engine spells or lacks `union_all`/`intersect(_all)`/`except(_all)` (ADR 0039); spell it, or throw naming engine and version, else `next::method` |
| `supports_exists_query` + `_exists_value_sql($inner)` | `results_exist*` throws without the declaration; override the SQL when FROM-less SELECT is refused (ADR 0037) |
| `_random_function` | no `RANDOM()` |
| `supports_upsert`, `supports_upsert_where`; SQLMaker `_insert_on_conflict`, `_upsert_attempted_sql`, `_upsert_condition_sql` | engine renders `on_conflict` (ADR 0036); declare only what the generator renders |
| `_dbi_error_fields($handle)` | DBD reports more than SQLSTATE (ADR 0062) |

## Cake and types

`cake_defaults` gives flags; component and type information comes from the type registry
on the storage (`register_type`, `type_info`, `all_type_names` — PostgreSQL registers
`jsonb` that way). `DBIO::Cake` collects `cake_options`/`components` from it.

## Messages and test frames

Text carrying connect info goes through `DBIO::Util::mask_connect_secrets`; stack traces
through `masked_longmess` / `masked_confess` / `masked_cluck`, not Carp's. Core test
frames: `DBIO::Test::Storage` (mock), `DBIO::Test::Conformance`, `DBIO::Test::StorageLayer`
(structural check for extension dists), `DBIO::Test::AsyncHarness` (live harness for
transports), `DBIO::Test::AsyncParity` (sync-vs-async parity cases; a transport's test class
inherits it and declares deviations and capabilities, POD section *WRITING A TRANSPORT'S
CLASS*), `DBIO::Test::Future`.

Error text names keys, columns and options, never values; engine text runs through
`_mask_error_values($text, \@values, $statement)`, which a driver overrides (with
`next::method`) for a value form of its own.
