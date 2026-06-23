# ADR 0003 — AGE storage extends and re-registers the `Pg` driver, and bootstraps AGE per connection

- Status: accepted
- Date: 2026-06-21
- Tags: drivers, storage, registry, coexistence, connect-call, age, postgresql

## Context

AGE is not a separate DBD — it speaks to PostgreSQL over `DBD::Pg` like any
other PostgreSQL connection. So the AGE driver does not introduce a new driver
name; it has to coexist with the base `DBIO::PostgreSQL` driver on the same
`dbi:Pg:` DSN. The standard driver pattern (skill `dbio-driver-development`)
and core ADR 0016 establish how a storage class is selected: a Schema component
overrides `connection()` to set `storage_type`, *and/or* a Storage class calls
`register_driver($dbd => $class)` so the registry auto-detects it from the DSN.
The base PostgreSQL driver does both — `register_driver('Pg')` in
`DBIO::PostgreSQL::Storage` and a `connection()` override in `DBIO::PostgreSQL`.

The sibling PostgreSQL-extension driver, `dbio-postgresql-postgis`, makes a
*different* choice: its `DBIO::PostgreSQL::PostGIS::Storage` extends
`DBIO::PostgreSQL::Storage` via `use base` but does **not** call
`register_driver` — it relies purely on the `storage_type` its `connection()`
override sets. So the family already contains two answers to "how does a
PostgreSQL-extension storage get selected", and this driver has to pick one.

Separately, AGE has a hard per-session bootstrap: every connection must run
`LOAD 'age'` and put `ag_catalog` on the `search_path` before any graph
operation, or `cypher()` and the `ag_catalog.*` functions are not visible.

## Decision

**ISA-extend and re-register `Pg`.** `DBIO::PostgreSQL::Age::Storage` does
`use base 'DBIO::PostgreSQL::Storage'` (`Storage.pm:7`) so it inherits the full
PostgreSQL storage behaviour (RETURNING, JSONB SQLMaker, introspect/deploy,
`sqlt_type`, `dbh_do`, `_do_query`) and adds only the graph surface. It then
calls `__PACKAGE__->register_driver('Pg' => __PACKAGE__)` (`Storage.pm:13`),
re-pointing the `Pg` auto-detection slot at the AGE storage class. Combined with
the component's own `connection()` override setting
`storage_type('+DBIO::PostgreSQL::Age::Storage')` (`Age.pm:51-55`), loading this
component makes the AGE storage the storage for any `Pg` connection in that
process — both the explicit (`storage_type`) and the auto-detected
(`register_driver`) selection paths land on the AGE class. This is broader than
the postgis sibling's `storage_type`-only approach and is recorded as the
deliberate difference.

**Per-connection AGE bootstrap as a connect-call.** AGE's session requirement is
implemented as the connect callback `connect_call_load_age`
(`Storage.pm:50-54`), activated by `{ on_connect_call => 'load_age' }` at
`connect()` time. It runs `LOAD 'age'` and `SET search_path = ag_catalog,
"$user", public` via the core `_do_query` helper, so the bootstrap re-runs on
every (re)connection, not once, matching how the rest of DBIO handles
connect-time session setup.

## Rationale

Extending `DBIO::PostgreSQL::Storage` rather than `DBIO::Storage::DBI` directly
is the whole point: AGE *is* PostgreSQL plus a graph function, so an AGE schema
must keep every PostgreSQL behaviour and only gain the graph methods — ISA gives
that for free and keeps this distribution to two small modules. Re-registering
`Pg` is the choice that makes auto-detection (a bare `connect('dbi:Pg:...')`
with the component loaded) resolve to AGE storage, so a user does not have to
remember to set `storage_type` by hand; the cost is that it is last-loaded-wins
process-wide, accepted because mixing the AGE component and a plain-PG schema in
one process that relies on auto-detection is not a supported shape (the user
loads the component precisely because they want AGE storage). The postgis sibling
omits `register_driver` and so makes the opposite trade; this driver records its
choice rather than silently diverging.

Making the AGE load a connect-call rather than a one-shot at create time is the
only correct option: connections drop and reconnect, pools hand out fresh
sessions, and `LOAD 'age'` / `search_path` are *session* state — they must be
reapplied on every connection, which is exactly the connect-call contract.

Shipped; the storage selection and `isa` chain are asserted in `t/10-age-live.t`
(`isa_ok ... 'DBIO::PostgreSQL::Age::Storage'` and `... 'DBIO::PostgreSQL::Storage'`)
and the connect-call drives that live test. Hence **accepted**.

## Consequences

- Loading `PostgreSQL::Age` makes AGE storage the `Pg` driver for the process.
  Both selection paths (explicit `storage_type`, registry auto-detect) resolve
  to `DBIO::PostgreSQL::Age::Storage`. A process that also wanted plain-PG
  auto-detected storage on `Pg` cannot have both via the registry — set
  `storage_type` explicitly per schema if that mix is ever needed.
- The driver inherits everything from `DBIO::PostgreSQL::Storage` and overrides
  nothing relational. Behaviour decided in the base PG driver's ADRs (exact PG
  type strings, JSONB operators, temp-database deploy, etc.) applies unchanged;
  this driver adds the graph surface and the AGE bootstrap, nothing more — which
  is why there is no redundant `sqlt_type` here (it lives in the base, karr #1).
- `on_connect_call => 'load_age'` is mandatory for graph operations. Without it
  `cypher()` and `ag_catalog.*` are not in scope on the session; the requirement
  is documented in both the component and storage POD and exercised live.
- The coexistence choice differs from `dbio-postgresql-postgis` on purpose. A
  future third PG-extension driver should read both this ADR and the postgis
  source before deciding whether to `register_driver`, rather than assume one
  pattern.
