# ADR 0017 — Native escape-hatch methods on Storage

- Status: accepted — superseded for LISTEN/NOTIFY by [ADR 0056](0056-listen-notify-is-a-core-async-contract.md) (see addendum)
- Date: 2026-06-20
- Tags: drivers, storage, native-features, escape-hatch, security, portability, family-policy

## Context

DBIO inherits a portable, row-oriented, DBI-shaped storage contract from its
DBIx::Class heritage: prepare/execute, a row cursor, scalar bind, ResultSet
sugar. That contract is the whole point of the ORM — it is what makes a result
class run unchanged across drivers. But every interesting database engine also
ships features that do not fit that contract and are *not* portable by nature:
PostgreSQL's `LISTEN`/`NOTIFY` and `COPY`, DuckDB's columnar Appender, Arrow
transport, file/table functions, extension management, and the Quack RPC
extension. These cannot be smuggled through `$rs->search` without either being
impossible (Appender, Arrow buffers) or quietly forcing engine-specific SQL
through the portable API.

Two drivers have already needed an exit and chose the same shape independently:

- **`dbio-postgresql-ev`** (the first instance, async-protocol-driven; originally
  shipped as `dbio-postgresql-async` and since renamed — the old
  `DBIO::PostgreSQL::Async::*` classes are now die-on-load tombstones in
  `dbio-deprecated`) puts
  native-protocol operations directly on its Storage object —
  `DBIO::PostgreSQL::EV::Storage` has `listen`, `unlisten`, `notify`,
  `copy_in`. It abandons DBI
  wholesale for protocol reasons (ADR 0014), so native ops live where the rest
  of its storage already lives.
- **`dbio-duckdb`** (a larger surface, blocking/DBI-based) puts a `duckdb_*`
  family (`duckdb_appender`, `duckdb_arrow_fetch`, `duckdb_read_csv`,
  `duckdb_read_parquet`, `duckdb_read_json`, `duckdb_version`,
  `duckdb_install_extension`, `duckdb_checkpoint`) and a `quack_*` family
  (`quack_serve`, `quack_attach`, `quack_detach`) directly on
  `DBIO::DuckDB::Storage`. It keeps the DBI
  plumbing for all ordinary ORM work and only the columnar/server features take
  the exit. This is documented driver-locally in **dbio-duckdb ADR 0002**.

The question this ADR settles is not *whether* either of those is correct — both
are shipped — but whether the *shape they share* is the family's blessed answer,
so the third and fourth drivers do not reinvent it (a separate transport object,
a side connection, a magic-SQL convention) and so the security obligation that
comes with it is stated once, family-wide, rather than rediscovered per driver.
This is a sibling decision to ADR 0014 (async storage interface): 0014 blesses
the portable async contract; this one blesses the escape hatch for the
deliberately non-portable.

## Decision

A driver **MAY** expose database-native, non-portable features as direct methods
on its Storage object. This is the blessed home for such features family-wide.
The convention has four load-bearing parts.

1. **Storage methods are the home, not a separate transport/object.** Native
   features that do not fit the DBI/ORM contract are exposed as direct methods on
   the driver's Storage class (the class that already owns the connection), not
   routed through the portable ORM API and not pushed into a second
   transport layer or a side connection. The schema/Storage object the
   application already holds is the one that answers. Precedent:
   `DBIO::PostgreSQL::EV::Storage` and `DBIO::DuckDB::Storage`.

2. **Naming: a per-feature-family prefix.** Each family of native methods carries
   a prefix that names its origin, so a reader of calling code sees immediately
   that the call is engine-specific and to which subsystem it belongs:
   `duckdb_*` (the engine itself) and `quack_*` (the Quack RPC extension) in
   dbio-duckdb; the PostgreSQL protocol verbs `listen`/`notify`/`copy_in` in
   dbio-postgresql-ev. The prefix is the signal at the call site that this is
   an exit from the portable contract.

3. **Security obligation — validate-or-escape at the method boundary (load-bearing,
   not a nicety).** A native method that bypasses DBI's placeholder binding also
   bypasses DBI's placeholder *quoting*. Any such method that interpolates a
   caller-supplied value into a SQL or protocol string **MUST** validate or
   escape every interpolated value at the method boundary. This is a security
   boundary, not a courtesy: it is the only line of defence these methods have.
   Both live instances honour it — dbio-duckdb matches identifier-shaped
   arguments against `^[A-Za-z_][A-Za-z0-9_]*$`, doubles `'` in string literals,
   and rejects embedded quotes/newlines in addresses/tokens (dbio-duckdb ADR
   0002, points 3 and consequences); dbio-postgresql-ev routes the `NOTIFY`
   payload through bind params (`SELECT pg_notify($1, $2)`, never inlined) and
   quotes table/column identifiers for `COPY` via `sql_maker->_quote`
   (in `DBIO::PostgreSQL::EV::Storage`'s `copy_in`). Any new escape hatch that builds a SQL or
   protocol string follows the same discipline.

4. **Documentation obligation — mark as non-portable in POD.** These methods are
   escape hatches: code that calls them is, by construction, not portable to
   another driver. Each such method **MUST** be documented in its POD as
   engine-specific and non-portable, so the reader chooses the lock-in
   knowingly. The non-portability is the intended trade; hiding it would let a
   caller reach for an escape hatch thinking it is ORM sugar.

### What this ADR does *not* do (scope boundary)

This core ADR blesses only the **pattern** family-wide. It does not own or
enumerate any driver's concrete native surface. The specific DuckDB methods,
their argument shapes, and their per-method escaping rules are owned by
**dbio-duckdb ADR 0002**, which stays in that driver; the PostgreSQL native ops
are owned by dbio-postgresql-ev. When a driver adds a native method, it
records *that surface* in its own repo's ADR, against this pattern — it does not
amend this one.

## Rationale

Putting native features on Storage rather than in a separate transport object
means the application keeps one object — the schema's storage — for both
portable ORM work and the engine's power features: no second connection to
manage, no parallel object graph, no question of which connection a `NOTIFY`
fires on relative to an in-flight transaction. The prefix-per-family naming makes
the portability boundary visible at the call site, which is exactly where a
reader decides whether code is portable. And stating the validate-or-escape
obligation here, once, is the point of promoting this from two driver ADRs to a
family convention: the moment a driver chooses to bypass DBI binding it inherits
DBI's quoting responsibility, and that responsibility must not be rediscovered
(or forgotten) per driver. Two independent drivers arriving at the same shape —
one async/non-DBI, one blocking/DBI — is the convergence evidence that this is
the family's natural answer and worth blessing.

This is shipped in two drivers, hence **accepted**, not proposed. The decision
records the existing convergence as the family rule going forward.

## Consequences

- Drivers have a sanctioned, uniform place for non-portable native features. The
  third driver that needs an exit copies the shape (methods on Storage,
  family prefix, validate-or-escape, POD non-portable mark) instead of inventing
  a transport object or a magic-SQL convention.
- The escape-hatch surface is engine-specific by construction. Code that calls
  `duckdb_*`/`quack_*`/`listen`/`notify`/`copy_in` does not port to another
  driver — that is the intended trade and the reason these are named methods, not
  ORM sugar.
- The validate-or-escape rule is a load-bearing security boundary for every
  driver, not a per-driver nicety. A new escape hatch that builds a SQL or
  protocol string from caller input and skips boundary validation is a security
  defect against this ADR, reviewable as such.
- Concrete native surfaces stay repo-owned: each driver documents its own methods
  in its own ADR (dbio-duckdb ADR 0002 for DuckDB; the PostgreSQL native ops in
  dbio-postgresql-ev). This core ADR is amended only if the *pattern* itself
  changes, not when a driver adds a method.

## Addendum 2026-09-26 — LISTEN/NOTIFY leaves this ADR (see ADR 0056)

The maintainer decided on 2026-09-26 (karr core k219) that LISTEN/NOTIFY is part
of the **core async contract**, standardised in `DBIO::Storage::Async` and
implemented identically by every async transport. That is recorded in
[ADR 0056](0056-listen-notify-is-a-core-async-contract.md), and it contradicts
this ADR for those three methods, so the conflict is stated here rather than
blended:

- `listen` / `unlisten` / `notify` are **no longer escape hatches**. Decision
  points 1 (the dbio-postgresql-ev precedent), 2 (the `listen`/`notify` family)
  and 4 (the non-portable POD mark), and the scope sentence that the
  PostgreSQL native ops are owned by dbio-postgresql-ev, no longer apply to
  them. They are portable async API whose contract core owns.
- **§3 still applies** — carried into the new contract at its seams. Quoting or
  validating the channel is the transport's obligation in `_listen_subscribe` /
  `_listen_unsubscribe`, and the notify payload travels only as a bind value
  through `_notify_send`.
- Everything else here stands unchanged: `copy_in`, the `duckdb_*` and `quack_*`
  families, and the pattern for the next native feature.

The body above is left as written; it records how the family stood on
2026-06-20.
