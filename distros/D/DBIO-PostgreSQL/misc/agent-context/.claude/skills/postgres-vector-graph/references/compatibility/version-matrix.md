# Compatibility is a gate, not a slogan

## Documentation snapshot: 2026-09-30

| Component | Verified upstream evidence | Package policy |
|---|---|---|
| PostgreSQL 18 | Version-specific PostgreSQL 18 documentation | Baseline; install an approved, patched 18.x build |
| pgvector | Upstream installation uses 0.8.6; changelog dates it 2026-07-29 | Lab target 0.8.6; do not use the unreleased 0.8.7 entry as a release |
| Apache AGE on PG18 | Published “Release v1.8.0 for PG18”, dated 2026-07-09; tag `PG18/v1.8.0-rc0` | Lab target extension version 1.8.0 and the PG18-specific artifact |
| PostgreSQL 19+ | Not established by this package | Refresh the matrix and run integration/security tests; never silently downgrade to 17 |
| Managed database | Upstream support alone does not establish provider availability | Confirm allowlist, binaries, privileges, preload policy, and upgrade path |

The `-rc0` suffix is the actual tag used by the published AGE release. Preserve
both the release title and exact tag in deployment records; do not invent a
`v1.8.0` tag or infer maturity only from the tag spelling. An extension's SQL
version string does not identify its PostgreSQL build target.

## Four independent checks

1. **Upstream:** release/branch targets the server major and required features.
2. **Artifact:** architecture, libc, compiler/runtime and `pg_config` match the
   installed server. Record package version or immutable image/source digest.
3. **Database:** inspect `pg_extension`, extension schema and update paths.
4. **Behavior:** execute representative vector, Cypher, composition, permissions,
   prepared-statement, rollback and recovery tests under the real application role.

`pg_available_extensions` means an installation control file is present, not that
the extension is enabled or functional. `CREATE EXTENSION IF NOT EXISTS` does
not upgrade a previously installed version. A successful compilation does not
prove SQL semantics, RLS behavior, or compatibility with another extension.

## Feature gates

The examples use pgvector iterative scans and AGE 1.8 JSONB casts. If a platform
only offers AGE 1.7, basic SQL/Cypher may still work, but the 1.8-specific lab must
stop rather than silently apply the wrong expressions. Do not copy generic
“AGE has no RLS” or “agtype can never cast to JSONB” claims from older articles.

Every reported result should identify server version, extension versions,
artifact provenance, driver version, pool mode and role. Use
[the fingerprint template](../../templates/environment-fingerprint.json).

## Sources

- [PostgreSQL 18 release notes](https://www.postgresql.org/docs/18/release-18.html)
- [pgvector release history](https://github.com/pgvector/pgvector/blob/master/CHANGELOG.md)
- [Apache AGE PG18 1.8.0 release](https://github.com/apache/age/releases/tag/PG18%2Fv1.8.0-rc0)
- [Apache AGE upstream repository](https://github.com/apache/age)
