# ADR 0001 — Native graph surface lives on Storage as `cypher`/`create_graph`/`drop_graph`

- Status: accepted
- Date: 2026-06-21
- Tags: drivers, storage, native-features, escape-hatch, age, graph, agtype

## Context

DBIO is a row-oriented, DBI-shaped ORM: Result classes, `$rs->search`, scalar
binds, a row cursor. Apache AGE is an openCypher graph engine bolted onto
PostgreSQL through a single SQL function, `cypher(graph, $$ ... $$, params)`,
that returns `agtype` (AGE's JSON-superset representing vertices, edges, paths
and scalars). Graph traversal, vertex/edge creation and graph lifecycle do not
fit the relational contract: there are no tables to map to Result classes, the
return shape is a free-form Cypher projection, not a fixed column set, and the
query language is not SQL at all. Trying to smuggle Cypher through `$rs->search`
would force a non-relational engine through the portable API and lose everything
that makes the API portable.

Core ADR 0017 (native escape-hatch methods on Storage) settles the family-wide
*pattern* for exactly this situation — engine features that cannot and should
not travel through the ORM — and its scope boundary explicitly leaves each
driver's *concrete native surface* to that driver's own ADR (precedent:
dbio-duckdb ADR 0002 for `duckdb_*`/`quack_*`). This ADR records the AGE surface
against that pattern; it does not restate the pattern.

## Decision

Expose the entire AGE graph surface as direct methods on the driver's Storage
class, `DBIO::PostgreSQL::Age::Storage` (the object that already owns the
connection), never through the relational ORM API and never via a second
transport object:

- `cypher($graph, $query, \@columns, \%params)` — executes one openCypher query
  against the named graph (`Storage.pm:97-106`). It builds `SELECT * FROM
  cypher('graph', $$ ... $$ [, ?]) AS (col agtype, ...)` and runs it through the
  core `dbh_do` wrapper. **Every** result column is declared `agtype`
  (`Storage.pm:119`) — AGE's only column type for `cypher()` output — and rows
  come back as an arrayref of hashrefs of `agtype` strings for the caller to
  decode (JSON for projected maps; the SYNOPSIS shows `JSON::MaybeXS`).
- `create_graph($name)` / `drop_graph($name, $cascade)` — graph lifecycle, thin
  wrappers over `ag_catalog.create_graph` / `ag_catalog.drop_graph`
  (`Storage.pm:66-85`).

The SQL/bind construction is split into a **pure** helper `_cypher_sql_bind`
(`Storage.pm:110-129`) so the generated SQL and binds are unit-tested with no
database (`t/20-cypher.t`); `cypher()` is the thin wrapper that adds execution.
This is the offline-testability seam for the one method that builds SQL by hand.

### Divergence from ADR 0017 point 2 (recorded, not hidden)

Core ADR 0017 prescribes a per-feature-family method prefix (`duckdb_*`,
`quack_*`) so a reader sees at the call site that a call is engine-specific.
This driver does **not** prefix its methods (`cypher`, `create_graph`,
`drop_graph`, not `age_*`). The names are kept because they read as the domain
verbs (a Cypher query *is* `cypher`; a graph *is* created and dropped) and the
distribution is single-purpose — every method on this Storage subclass is
AGE-specific, so the class name already carries the "engine-specific" signal the
prefix exists to provide. The trade is accepted: a call to `$storage->cypher`
is no less obviously non-portable than `$storage->duckdb_read_csv`, because the
storage is an `DBIO::PostgreSQL::Age::Storage`. The POD obligation (ADR 0017
point 4) is still met — each method is documented as AGE-specific.

## Rationale

Storage is the blessed home (ADR 0017 point 1): the application already holds
the schema's storage object, so graph work and ordinary PostgreSQL ORM work
share one connection and one object — no parallel graph client, no question of
which connection a `cypher()` runs on relative to an in-flight transaction.
Declaring all `cypher()` columns as `agtype` is not a choice so much as AGE's
contract — the `AS (...)` clause of an AGE query may only name `agtype` columns
— so the driver surfaces it honestly rather than pretending to map types it
cannot know ahead of a free-form `RETURN`. Splitting `_cypher_sql_bind` out is
what lets the one hand-built SQL string be pinned offline; the live test
(`t/10-age-live.t`) covers the execution half against a real AGE cluster.

This surface is shipped and test-pinned (offline SQL/bind in `t/20-cypher.t`,
live create/match/param in `t/10-age-live.t`), hence **accepted**.

## Consequences

- Graph code is engine-specific by construction. A schema that calls
  `cypher`/`create_graph`/`drop_graph` does not port to a non-AGE driver — the
  intended trade for reaching a graph engine, identical in spirit to the
  `duckdb_*`/`listen`/`notify` escape hatches.
- The caller owns `agtype` decoding. `cypher()` returns strings; vertices/edges
  carry graph annotations in text form, so the documented guidance is to RETURN
  projected maps and decode with a JSON parser rather than parse full
  vertex/edge text.
- The no-prefix divergence from ADR 0017 point 2 is a deliberate, recorded
  exception scoped to this single-purpose distribution, not a precedent for
  multi-feature drivers — a driver that mixes AGE with other native families
  would need the prefix back to keep the call-site signal.
- `_cypher_sql_bind` is the offline-test seam: any change to the emitted AGE SQL
  must keep `t/20-cypher.t` honest, and the security boundary it enforces is the
  subject of ADR 0002.

## Addendum 2026-10-05 — Wording and references brought up to date

The decision stands (graph surface as direct methods on the AGE storage, no
`age_*` prefix). Corrections to the text above:

- "Storage subclass" / "subclass" is outdated wording: `DBIO::PostgreSQL::Age::Storage`
  is a storage **layer** composed over the resolved PostgreSQL driver storage
  (see the addendum of 2026-10-05 in ADR 0003). The "storage is an
  `DBIO::PostgreSQL::Age::Storage`" argument for the no-prefix choice still holds
  for the layer's own methods.
- The line references (`Storage.pm:97-106`, `:119`, `:66-85`, `:110-129`) are
  obsolete; the subs are `cypher`, `create_graph`, `drop_graph` and
  `_cypher_sql_bind` in `lib/DBIO/PostgreSQL/Age/Storage.pm`.
- The surface has grown since: `cypher` takes an optional fifth `\%opts`
  argument, and `auto_decode => 1` applies `decode_agtype` to every cell of the
  result rows. `decode_agtype` is also callable directly to decode a single
  agtype text value. The default (no option) still returns raw agtype strings,
  so "the caller owns agtype decoding" holds unless `auto_decode` is requested.
- `cypher_async`, `create_graph_async` and `drop_graph_async` exist as async
  counterparts of the three methods.
