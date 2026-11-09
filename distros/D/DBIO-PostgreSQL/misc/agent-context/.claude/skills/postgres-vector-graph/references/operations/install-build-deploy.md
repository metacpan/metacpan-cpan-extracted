# Installation and deployment gates

## Four artifacts must agree

Verify the PostgreSQL server major, development headers/`pg_config`, extension
source/build, and deployed shared-library/control/SQL files. An extension compiled
for another major is not a portable binary. A package available on a developer
machine is not evidence that a managed provider permits it.

For the reviewed baseline, use pgvector **0.8.6** and the Apache AGE PG18 release
whose actual tag is **`PG18/v1.8.0-rc0`**. Record the complete resolved commit and
artifact digest in your deployment lock; a tag alone can move. Verify release
provenance before building. This package contains no binaries, Docker image,
installer, or automatically executed dependency download.

The build shape is schematic and must be adapted to the approved build image:

```sh
/path/to/pg18/bin/pg_config --version
# After fetching and verifying each approved source artifact:
make PG_CONFIG=/path/to/pg18/bin/pg_config
make install PG_CONFIG=/path/to/pg18/bin/pg_config
# Run the extension's documented regression process in a disposable environment.
```

Compilation success is not coexistence validation. Run extension regression tests,
create both extensions in a disposable PG18 database, and execute the cross-model
and role tests. Record OS/architecture, compiler, libc, extension versions, and
server minor. Repeat for every supported architecture and major.

## Database and session initialization

`CREATE EXTENSION` is a database operation; it does not download a missing binary.
AGE session initialization (`LOAD 'age'` or supported preloading) is a separate
concern. Non-superuser permissions and managed-service configuration may prevent
manual loading. Do not grant superuser to the application as a workaround.

The SQL lab assumes vector objects are in `public` and that `public` is trusted in
a disposable database. Production should discover extension schemas and qualify
types/operators or use a carefully controlled search path. Installing an extension
in an unexpected schema is not fixed by scattering unreviewed search-path changes.

## Self-hosted versus managed

On self-hosted systems, package/source builds and server library configuration
are operator responsibilities. On managed systems, use the provider's current
extension version allowlist, PostgreSQL major support, parameter mechanism, and
restart procedure. Generic AGE instructions do not establish Azure, Supabase,
RDS, or another provider's product availability.

Do not turn companion-skill provider assumptions into deployment requirements.
Capture configuration in an environment fingerprint and require a successful
backup/restore drill before production adoption.

## Sources

- [pgvector upstream reference](https://github.com/pgvector/pgvector)
- [Apache AGE PG18 1.8.0 release](https://github.com/apache/age/releases/tag/PG18%2Fv1.8.0-rc0)
- [Apache AGE setup](https://age.apache.org/age-manual/master/intro/setup.html)
- [PostgreSQL 18 schemas and search_path](https://www.postgresql.org/docs/18/ddl-schemas.html)
