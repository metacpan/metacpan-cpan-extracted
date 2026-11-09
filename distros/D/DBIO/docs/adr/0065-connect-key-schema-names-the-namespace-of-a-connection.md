# ADR 0065 — The connect key `schema` names the namespace a connection works in

- Status: accepted
- Date: 2026-10-13
- Tags: storage, connect-info, drivers, cross-driver, namespace

## Context

Several engines group tables into namespaces below the database: PostgreSQL
and DuckDB schemas, Oracle users' schemas, DB2 schemas. A multi-tenant or
multi-schema application needs to say, per connection, which namespace its
queries run in and into which namespace a deploy installs. Each engine
spells that differently (`search_path`, `CURRENT_SCHEMA`, `SET SCHEMA`,
`USE`).

The storage already has an accessor `schema`, the back-reference to the DBIO
schema class, and a storage option is set by calling the accessor of its own
name (`DBIO::Storage::_dbio_storage_option_names`).

Maintainer decision 2026-10-12 (karr k336, from the discussion of dbio-postgresql k103).

## Decision

1. **One generic connect key `schema`**, a single plain name (no array
   reference, no list). It is the namespace in which this connection works and
   into which a deploy over it installs.
2. **Core defines the word and the contract; the driver defines the meaning.**
   A driver gives the key meaning by overriding the storage seam
   `_set_connection_schema($name)`. It runs on every new connection — the sync
   connect (`_run_connection_actions`) and each async pool connection
   (`_run_pool_connect_actions`) — before the user's `on_connect_call` /
   `on_connect_do`, and only when the connect info gave the key. It issues its
   statements through `_do_query`, which lands on the sync handle or the pool
   connection as the case may be.
3. **A driver without namespaces refuses.** The default of
   `_set_connection_schema` throws a `DBIO::Exception` naming the storage
   class. Nothing is ignored silently.
4. **The key never determines the driver.** It is a storage option like
   `on_connect_do`; it does not select, change or re-compose a storage class.
5. **Mapping from key to accessor.** The storage keeps the name under the
   accessor `connection_schema`, because `schema` is taken. The mapping lives
   once beside the names, in `_dbio_storage_option_accessor_map`; the accessor
   registration, the reset on `connect_info` (ADR 0050) and the setter all ask
   `_dbio_storage_option_accessor`. The sync normaliser and the async strip
   (`_strip_private_connect_attrs`) share the name list, so the key reaches
   neither `DBI->connect` nor a transport's conninfo.
6. **Validation** happens in `connect_info`: a value that is not a defined,
   non-empty, non-reference scalar throws.
7. **Deploy** works on the connection it is given; installing into the
   connection's namespace is the driver Deploy's use of
   `connection_schema` and of the namespace the connection was set to.

## Consequences

- A driver opts in with one method; PostgreSQL's implementation is
  dbio-postgresql k128.
- The key is in the storage-option name list, so a connect info naming it is
  no longer refused as an unknown attribute.
- Drivers adding storage options of their own map a name to an accessor with
  `_dbio_storage_option_accessor_map` (SUPER's map plus their entries); the
  default is the accessor of the same name.
