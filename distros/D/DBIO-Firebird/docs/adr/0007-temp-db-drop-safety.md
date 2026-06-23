# ADR 0007 — Temp-DB drop safety: drop on a throw-away handle, never the live one

- Status: accepted
- Date: 2026-06-20
- Tags: deploy, temp-database, safety

## Context

`DBIO::Firebird::Deploy` uses the shared test-deploy-and-compare orchestration
from `DBIO::Deploy::Base::TempDatabase`: it creates a uniquely-named temp
database, deploys the desired schema into it, introspects it, diffs against the
live DB, then drops the temp database.

Dropping that temp database in Firebird is a **footgun**. The drop operation —
whether spelled `DROP DATABASE` or, as this driver does it,
`func("ib_drop_database")` — takes **no database name**: it drops whatever
database the issuing handle is connected to. Issued on the production handle, it
would drop the **live production database**.

(The *mechanism* of database-level create/drop — that it goes through the
DBD::Firebird native API rather than DSQL, and where the temp DB is placed — is
a separate decision, recorded in ADR 0009. This ADR is only about *which
database the drop targets*.)

## Decision

`_drop_temp_db` does **not** drop on the production handle. It opens a
**throw-away DBI handle connected to the temp database** and drops *that*:

    my ($dsn, $user, $pass) = $self->_temp_connect_info($name);
    my $temp_dbh = DBI->connect($dsn, $user, $pass,
      { RaiseError => 1, AutoCommit => 1 })
      or die "Cannot connect to temp database for drop: $DBI::errstr";
    $temp_dbh->func("ib_drop_database");

The throw-away handle is **not** disconnected afterwards: `ib_drop_database`
invalidates the handle (just like `DROP DATABASE` would), so there is nothing
left to disconnect. The in-code comment states the hazard explicitly: the drop
"drops whatever database the handle is connected to -- it takes no name. Running
it on the production `$dbh` would drop the live database."

## Rationale

`ib_drop_database`'s name-less, connection-targeted semantics make "drop the
temp DB" inseparable from "be connected to the temp DB". The only safe way to
drop the scratch database is to connect a disposable handle to it and drop from
there; doing it on the live handle is not a style choice but a
production-data-loss bug. The drop handle is built from the same
`_temp_connect_info($name)` path that create and connect use (see ADR 0009),
so it is guaranteed to point at the scratch DB and never the live one.

## Consequences

- The temp-DB drop always goes through a fresh, single-purpose handle connected
  to the temp database; the production handle never drops a database. This must
  not be "simplified" into a drop on the live handle — which would target the
  wrong (live) database.
- The throw-away handle is intentionally left undisconnected, because the drop
  invalidates it.
- A crashed run can leak a temp database
  (`temp_db_prefix . pid . '_' . time . '.fdb'`) that must be dropped manually.
