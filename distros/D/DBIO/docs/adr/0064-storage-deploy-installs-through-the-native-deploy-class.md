# ADR 0064 — Storage deploy installs through the native Deploy class; deployment_statements reads a DDL file

- Status: accepted (maintainer decision of 2026-10-12, karr k337)
- Date: 2026-10-13
- Tags: deploy, storage, deployment-statements, drivers, replicated

## Context

A native Deploy class (ADR 0006) is named by the storage's `dbio_deploy_class`.
`DBIO::Schema::deploy` asks for it and installs through it. `deploy` on the storage
is reached directly by callers that do not go through the schema:
`DBIO::Replicated::Storage` hands `deploy` to its master and has no Deploy class
of its own, and any caller invokes `$storage->deploy` on a driver storage.

## Decision

1. **`DBIO::Storage::DBI::deploy` installs through `dbio_deploy_class`.** Given a
   `DBIO::Schema` and a storage that names a Deploy class, it loads the class and
   runs `->new(schema => $schema)->install`. It connects first, so driver
   determination has decided which storage answers. A DDL file in the deploy
   directory is not executed in its place. The routing lives in this one method;
   no driver storage overrides `deploy` for it, and `DBIO::Schema::deploy` and
   `$storage->deploy` end in the same install.
2. **A storage without a Deploy class** keeps the DDL-file route: it executes the
   statements of an existing file and throws when there is none. The same holds
   for a first argument that is not a `DBIO::Schema`.
3. **`deployment_statements` stays the DDL-file reader of ADR 0006** -- for every
   driver, with or without a Deploy class. It reads a pre-existing file and throws
   without one. Install DDL is produced by the Deploy class, by `install_ddl`.

## Rationale

One place decides how a schema is installed, so a storage composed behind another
(Replicated) or called directly installs like the schema does. `deployment_statements`
promises a file's content; having it answer native DDL for some drivers would make
its meaning depend on the driver.

## Consequences

- Driver storages drop any `deploy` override that only forwards to their Deploy
  class; `dbio_deploy_class` is the single source for the class name.
- Tests that relied on `$storage->deploy` executing a DDL file for a storage with a
  Deploy class now see the native install.
- `t/storage/quote_names.t` asserts quoting on the SQL maker only; install DDL
  quoting belongs to the driver's Deploy tests.
- `DBIO::ChangeLog::Schema::deploy_changelog` hands single result sources to
  `$storage->deploy`; those take the DDL-file route (karr k337).
