# ADR 0067 — A schema always has a driver; finding a driver from a DSN is a function

- Status: accepted (maintainer decision of 2026-10-16, karr k308)
- Date: 2026-10-16
- Tags: storage, drivers, driver-detection, connect-path, schema, replicated, testing, builds-on-0059, relates-0012, relates-0032

## Context

ADR 0059 decided that a schema always declares its driver, by the driver's
shortcut (`use DBIO 'Schema', -pg`) or its component
(`load_components('PostgreSQL')`), and that the declared storage class stands.
It left the detection of a driver from the DSN for the generic
`DBIO::Storage::DBI` as it was (§(e)): the registry of `register_driver`,
`_rebless`, `_determine_connector_driver` with its connector registry, and the
detecting half of `DBIO::Storage::DBI::ODBC`. This ADR decides that no schema
is without a driver, and where that detection goes.

A declaration is any storage class other than the generic one: a driver's
base storage, `DBIO::Test::Storage` (the fake driver of the mock suite), or a
storage built over a driver, `DBIO::Replicated::Storage`.

## Decision

### 1. No schema without a driver

A schema without a declared driver is an error, in every form: with or
without sources, as a class or as a connected object.

Every schema class — made with `use DBIO 'Schema'`, `use base` or
`use parent` — is checked in `DBIO::Schema::connection`: a schema whose
storage class resolves to the generic `DBIO::Storage::DBI` throws, before any
storage is built. A driver set on the class or on a clone before connecting
(`storage_type`) is a declaration; that is how a shared test schema gets its
driver. The message names the class, the shortcut, the driver component,
`storage_type` and `DBIO->driver_for`. There is no warning mode and no guess
from the DSN.

`connection` is the check, and the only one. The pragma does not check when
the class is compiled: the end of a class's compilation comes before its body
runs, so a driver component the body loads is not there yet.

### 2. Finding a driver from a DSN is a function

Where the driver is not known in advance — loading a schema from an existing
database — the question "which driver is this connection" is answered by a
function, not by a schema object:

```perl
my $driver = DBIO->driver_for($dsn, $user, $pass, \%attrs);   # e.g. 'PostgreSQL'
my $schema = DBIO->schema_for($dsn, $user, $pass, \%attrs);   # connected, driver applied, no sources
```

- **`DBIO->driver_for`**, beside `DBIO->apply_driver`, returns the name of
  the driver the connection's DBD is registered for (`register_driver`): the
  DBD named in the DSN, or, for a code reference, the DBD of the handle it
  returns. That is the **exact driver** and nothing else: no question to the
  server, no move to another product. A DBD that names no driver (ODBC, ADO,
  a proxy) throws, telling the caller to declare the driver: a driver that
  can run over such an access path knows it and handles it itself
  (ADR 0059 (b), `_adapt_to_access_path`).
- **`DBIO->schema_for`** takes the same arguments and returns a connected
  schema object of a schema class with that driver applied
  (`apply_driver`) and no sources — the starting point for loading a schema
  from the database. It is an ordinary schema with a driver.

`schema_for` builds one schema class per driver,
`DBIO::SchemaFor::<Driver>`, shared by later calls; the sources a load
registers belong to the returned object. The generic `DBIO::Storage::DBI` is
no longer a class a schema's storage can have.

`dbiogen` needs neither: it writes classes from a plain DBI handle and picks
its introspector by the handle (`DBIO::Introspect::DBI->class_for_dbh`), with
the generic DBI introspector where no driver introspector is installed.

No part of core needs a schema object without a driver: `dbiogen` connects
with DBI, `dbioadmin` takes the application's schema class, and the mock
suite declares its fake driver (§4).

### 3. Replicated runs on the declared driver

`DBIO::Replicated` is loaded on a schema that declared its driver. The
master and every replicant are storages of that driver:
`backend_storage_class` defaults to the declared driver's storage class, read
from the schema before `DBIO::Replicated::connection` sets
`+DBIO::Replicated::Storage`. Each backend is a declared storage, so
ADR 0059 applies to it: it adapts to its access path within the driver, and a
replicant whose DSN leads to another driver is reported by `driver_strict` /
`driver_warnings` like any declared storage. A replicated schema without a
declared driver is refused by rule 1. `backend_storage_class` given in the
connect info still wins; it is itself a declaration.

### 4. The test storage is a driver

`DBIO::Test::Storage` is the fake driver of core's mock suite, declared like
any other: the mock path of `DBIO::Test->init_schema` declares it on the
schema before connecting. `DBIO::Test::Schema` is shared by the driver suites
and keeps no driver in its class; each use declares one. A test against a
real database (`init_schema(dsn => ...)`) names its driver (`storage_type`);
without one it is refused by rule 1, with the hint to pass `storage_type`. A
driver's test helper (`DBIO::SQLite::Test` and its siblings) declares its own
driver by default.

## Rationale

- **The driver decides everything after connect.** SQL dialect, deploy,
  introspection, async transport and storage layers are the driver's. A
  schema that names its driver gets exactly what it declared, as ADR 0059
  guarantees; a schema that does not is not a DBIO schema.
- **One line every schema passes.** `connection` is the first point at which
  every form of declaration — shortcut, component, `storage_type` on a clone
  — has taken effect, and every schema goes through it before it can do
  anything.
- **Detection is a question, not a state.** Asking which driver a DSN leads
  to is needed once, before a schema exists. As a function it has no object
  that could be half a schema.
- **Replicated is a storage over a driver, not a driver.** Its backends are
  the driver's storages, so a replicated schema behaves like the same schema
  unreplicated, connection by connection.
- **A fake driver is a driver.** The mock suite exercises the same connect
  path as every other schema, with a declaration.

## Consequences

- `DBIO::Schema::connection` gains the refusal of rule 1.
- `DBIO->driver_for` and `DBIO->schema_for` are the only way from a DSN to a
  driver; ADR 0059 §(e) is answered by this ADR. `driver_for` knows the
  drivers of the registry: those in its default mapping and those whose
  storage is loaded.
- The product-changing parts of the detection — `_rebless` on the generic
  path, `_determine_connector_driver` with the connector registry, the
  detecting half of `DBIO::Storage::DBI::ODBC` — are retired. The rest of
  `DBIO::Storage::DBI::ODBC` stays: it is the base of the ODBC storages of
  drivers that run over ODBC (MSSQL, Firebird).
- `use base 'DBIO::Schema'` stays a way to make a schema class, for classes
  that set their driver per use (the shared test schema); it is checked at
  connect. The documentation shows `use DBIO 'Schema', -<driver>` only.
- `DBIO::Replicated` reads the declared driver and passes it on as the
  backend storage class.
- `DBIO::Test->init_schema` declares `DBIO::Test::Storage` on the mock path
  and requires `storage_type` on a real DSN.
- Every schema example in the documentation names its driver.
- Driver distributions: the driver's test helper declares its driver by
  default, and a test that calls `DBIO::Test->init_schema` with a DSN passes
  `storage_type`. The follow-ups are filed per repository after acceptance.

