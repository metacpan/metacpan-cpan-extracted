# Backup, recovery, replication, and upgrades

## Back up a usable system, not only tables

Record extension versions, binaries/source provenance, schemas, roles/grants,
policies, graph definitions/labels, embedding-space registry, application schema,
and server configuration alongside the recovery procedure. A dump does not
magically install the target extension's shared library.

Decide whether embeddings and graph projections are authoritative or reproducible.
Reproducibility needs source data, model/version access, extraction configuration,
and deterministic-enough rebuilding or a documented tolerance—not merely the
claim that the data was once generated. Rebuilding can also be costly or impossible
when an external embedding model changes.

## Restore drill

Provision a clean target with the approved PG18/extension builds. Restore using the
chosen logical or physical method according to PostgreSQL and extension guidance.
Do not casually pre-create extension-managed objects in conflict with the dump's
creation order. Preserve a restore log and investigate every error.

After restoration, verify relational counts and constraints, graph business-key
mappings and endpoint integrity, embedding dimensions/spaces, known-query results,
index validity, grants/policies, and no cross-tenant visibility. Run reads and
writes as the actual application role. Document recovery time and data-loss
window from measurements, not assumptions.

## Upgrade sequence

For a minor extension update or major PostgreSQL upgrade: read target release
notes, confirm the upgrade path, rehearse on a restored clone, run extension and
cross-model tests, compare plans/recall, and repeat role/restore tests. An installed
`extversion` is not proof that libraries on every replica match.

Do not prescribe `ALTER EXTENSION UPDATE` to an invented version or assume every
AGE release has an in-place upgrade script from every older version. Discover
`pg_extension_update_paths()` for the installed package and follow upstream
instructions. A major PostgreSQL upgrade also requires compatible extension
binaries and a tested rollback plan.

## Replication boundaries

Physical replication, logical replication, and application projection replication
have different requirements. PostgreSQL logical replication does not replicate
all DDL, sequences, or extension setup automatically. AGE's generated graph/label
objects and their identities require an explicitly tested strategy; do not claim
that publishing a few label tables constitutes supported graph replication.

For asynchronous graph/embedding projections, restore outbox and checkpoint state
consistently. Verify that replay after recovery cannot duplicate identities,
republish stale embeddings, or resurrect deleted records. Keep recovery and
projection-reconciliation tests separate from ordinary query benchmarks.

## Sources

- [PostgreSQL 18 SQL dump](https://www.postgresql.org/docs/18/backup-dump.html)
- [PostgreSQL 18 logical-replication restrictions](https://www.postgresql.org/docs/18/logical-replication-restrictions.html)
- [Apache AGE PG18 1.8.0 release](https://github.com/apache/age/releases/tag/PG18%2Fv1.8.0-rc0)
- [pgvector release history](https://github.com/pgvector/pgvector/blob/master/CHANGELOG.md)
