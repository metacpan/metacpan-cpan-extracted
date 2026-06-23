# ADR 0009 — Database-level DDL via the DBD::Firebird native API, not DSQL

- Status: accepted
- Date: 2026-06-22
- Tags: deploy, temp-database, ddl, dbd, mechanism

## Context

`DBIO::Firebird::Deploy` inherits the test-deploy-and-compare orchestration from
`DBIO::Deploy::Base::TempDatabase`: it creates a uniquely-named scratch database,
deploys the desired schema into it, introspects it, diffs against the live DB,
then drops the scratch database. Every other DDL statement DBIO emits — `CREATE
TABLE`, `ALTER TABLE`, `CREATE INDEX` — is *table-level* and goes through the
ordinary statement path (`$dbh->do(...)`, i.e. DSQL prepare/execute).

The two `DATABASE`-level statements are different. In DBD::Firebird, DSQL cannot
prepare them at all:

- `do("CREATE DATABASE ...")` fails with SQLCODE **-530**
  ("Cannot prepare a CREATE DATABASE/SCHEMA statement").
- `do("DROP DATABASE")` fails with SQLCODE **-104** ("Token unknown - DATABASE").

This is not a quoting or dialect problem — DATABASE-level DDL is simply outside
what the DSQL prepare path accepts in this driver. So `_create_temp_db` /
`_drop_temp_db` cannot be expressed as `$dbh->do(...)` the way the rest of the
DDL is. (Verified live against Firebird 3.0.11 / DBD::Firebird 1.39 under karr
#12.)

A second, coupled problem is *where* the scratch database lives. Firebird names
a database with a `host[/port]:/abs/path.fdb` identifier, and
`DBD::Firebird->create_database` creates the file **server-side** at that path.
A bare name lands in the server's working directory (unpredictable); an
arbitrary client-side path is meaningless to the server. The scratch DB must
land somewhere predictable and server-writable.

## Decision

Database-level DDL goes through the DBD::Firebird **native API**, not DSQL:

- **Create** — `_create_temp_db` calls the `DBD::Firebird->create_database`
  *class method* (dialect 3, `page_size => 4096`, `character_set => 'UTF8'`,
  reusing the live connection's user/password). It is out-of-band: it opens no
  DBI handle and no transaction, and croaks on error.
- **Drop** — `_drop_temp_db` calls `$temp_dbh->func("ib_drop_database")` on a
  handle connected to the scratch database (see ADR 0007 for *why a throw-away
  handle* — that is the drop-safety decision; this ADR owns *which call*).

The scratch DB is placed **server-side, co-located with the live database**. The
new `_live_db_location` helper parses the live storage `connect_info` DSN's
`dbname=`/`database=` component into `($hostport, $dir)` — the same host[/port]
and the directory of the live db file — and `_create_temp_db` builds the scratch
identifier as `($hostport ? "$hostport:" : "") . "$dir/$name"`, where `$name`
is `temp_db_prefix . $$ . '_' . time() . '.fdb'`. `_live_db_location` reuses the
inherited coderef-DSN guard semantics by `die`-ing on a coderef DSN, the same
case `DBIO::Deploy::Base::TempDatabase` refuses.

`_create_temp_db` returns that full `host[/port]:/abs/path.fdb` identifier, and
`_temp_dsn` wraps it as `dbi:Firebird:dbname=$id`, so create, connect and drop
all reference the same database. `DBD::Firebird` is therefore a compile-time
dependency of `Deploy.pm` (`use DBD::Firebird;`), since the create path is a
class-method call, not a lazy DBI connect.

## Rationale

The mechanism is forced, not chosen: DSQL cannot prepare DATABASE-level DDL in
DBD::Firebird (-530 / -104), so the only way to create and drop the scratch DB
is the driver's out-of-band native calls. The earlier `do("CREATE DATABASE")` /
`do("DROP DATABASE")` spelling was never reachable on a live server; the whole
deploy/upgrade/install path was inert until this was fixed.

Server-side co-location is the simplest placement that is guaranteed reachable:
the live DSN already names a server and a directory that the server can write
(it holds the live DB there), so the scratch DB beside it inherits the same
reachability and credentials without any extra configuration. Deriving the path
from the live DSN rather than a fixed temp dir keeps the strategy working for
both local and remote (`host/port:`) servers with no per-deployment tuning.

## Consequences

- `_create_temp_db` / `_drop_temp_db` must never be "simplified" back into
  `$dbh->do("CREATE DATABASE")` / `do("DROP DATABASE")` — those do not prepare
  on a live server (-530 / -104). There is no AutoCommit toggle or `COMMIT` in
  `_create_temp_db`, because `create_database` is out-of-band and opens no
  transaction.
- The scratch database lands in the live database's server-side directory.
  On a hardened server (`DatabaseAccess=Restrict`, or a non-writable data dir),
  `create_database` can fail; that is a deployment concern to document, not a
  code bug.
- The temp-db identifier carries the full `host[/port]:/abs/path.fdb` form, so
  create / connect (`_temp_dsn`) / drop all agree on one spelling.
- A coderef DSN is unsupported for temp-database deploy: `_live_db_location`
  dies on it, matching the base's coderef-DSN guard.
- This path hits real DATABASE-level DDL and cannot be exercised with a mock
  handle, so it is covered by the live, opt-in `t/17-deploy-live.t`
  (`skip_all` without `DBIO_TEST_FIREBIRD_DSN`), which asserts the
  create → connect → write → drop roundtrip and that no scratch db leaks.

## See also

- ADR 0007 — temp-DB **drop safety** (the throw-away-handle pattern; *why* the
  drop runs on a disposable handle, not the live one). This ADR owns the
  *mechanism* (`create_database` / `ib_drop_database`) and *placement*; 0007
  owns the *safety* of the drop target.
- karr #12 — live root-cause analysis and fix (the source of this decision).
