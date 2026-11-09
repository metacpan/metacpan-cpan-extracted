# Atomic cross-model writes and asynchronous projections

## Same database does not mean every workflow is automatically atomic

Relational DML and AGE graph mutations can participate in the same PostgreSQL
transaction when executed on the same connection. Use explicit statements with
clear dependencies. The [rollback example](../../examples/sql/07_atomic_rollback.sql)
creates a relational record and graph vertex, rolls back, and checks both are
absent. This is a target-environment integration test, not a claim of local testing.

Do not hide graph writes in a SELECT join, assume SQL expression evaluation order,
or execute the graph step through a second pooled connection. Generate embeddings
outside the write transaction; a remote model call should not hold locks and an
open database transaction for its full latency.

## Outbox design for projections

When graph extraction or embeddings are asynchronous, commit the authoritative
record change and an outbox event atomically. An event needs at least a stable
event ID, tenant/business ID, source version, operation, and payload/schema version.
A uniqueness constraint or deduplication record handles at-least-once delivery.

A worker claims a bounded batch using an explicitly designed locking/lease
protocol. It processes remote inference outside long-held database locks, then
uses a short transaction to verify the source version and publish the result.
Older work must not overwrite a newer embedding, resurrect a deleted vertex, or
replay a superseded relationship. Persist completion only after the projection
change commits. Reclaim crashed work safely and bound retries.

`MERGE` on a business key helps replay behavior but does not itself establish
concurrent uniqueness across workers. Serialize conflicting identity creation,
use a relational identity registry, and test interleavings on the actual AGE
version. A graph property that looks unique is not a relational UNIQUE constraint.

## Versioned invariants

Define these conditions explicitly:

- Every published embedding has the intended space ID and current source version.
- Every projected vertex maps to a live authorized source key, unless a documented
  historical retention policy intentionally keeps it.
- Every relationship has source provenance and valid endpoints.
- A deletion tombstone is ordered after older create/update work and survives
  retries long enough to prevent resurrection.

An audit job compares source versions, missing/duplicate keys, orphaned edges,
and outbox lag. Repair jobs must be idempotent and reviewed, not automatic
whole-graph rebuilds against production.

## Tradeoff record

Choose synchronous atomic projection, asynchronous eventual projection, or a
hybrid. Record latency, failure isolation, lag budget, read behavior during lag,
reconciliation ownership, and rollback strategy. PostgreSQL replication and
backup mechanisms do not replace application-level projection correctness.

## Sources

- [Psycopg transaction management](https://www.psycopg.org/psycopg3/docs/basic/transactions.html)
- [Apache AGE Cypher query format](https://age.apache.org/age-manual/master/intro/cypher.html)
- [PostgreSQL 18 row security](https://www.postgresql.org/docs/18/ddl-rowsecurity.html)
- [PostgreSQL 18 logical-replication restrictions](https://www.postgresql.org/docs/18/logical-replication-restrictions.html)
