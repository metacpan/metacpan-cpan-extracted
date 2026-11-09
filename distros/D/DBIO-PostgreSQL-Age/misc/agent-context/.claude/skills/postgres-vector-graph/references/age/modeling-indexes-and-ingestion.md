# Graph modeling, indexes and ingestion

## Model a question, not a drawing

Use a graph when relationships, path constraints or provenance are central to
the query. For one simple parent/child relationship, a relational edge table and
a recursive CTE may be sufficient. Define labels, relationship directions,
cardinality, stable business keys and deletion rules before loading a corpus.

Properties should carry identifiers, source versions and needed graph predicates.
Do not duplicate every document body or embedding into the graph by default.
Record evidence IDs on extracted relationships and distinguish an observed fact,
a proposed link and a model-generated inference.

## Concurrency and idempotency

A replayable loader uses stable tenant-scoped identities. `MERGE` is useful for
repeat execution, but concurrency still needs a tested uniqueness/locking design.
Run two concurrent writers creating the same logical entity and verify the final
count. Do not assume a graph property automatically becomes a SQL foreign key.

The lab's graph-creation script is one-time fixture setup. It deliberately fails
on an existing graph rather than dropping or silently merging an unknown graph.
Production projection logic belongs behind the outbox/atomic-write contract.

## Index the actual expressions

AGE labels are backed by relations; inspect `ag_catalog.ag_label` and actual
index definitions rather than guessing table names or existing indexes. For
traversal, inspect source/target edge access paths. For property filters, compare
expression/GIN index choices with the exact expression produced by Cypher.

A B-tree over `(properties::jsonb ->> 'doc_id')` is not automatically equivalent
to the expression used by a Cypher integer property predicate. A mismatch can
make a plausible index useless. Inspect EXPLAIN and verify the plan on real
cardinalities. Never alter AGE's internal storage layout casually.

## Bulk ingestion and backfill

Batch ingestion with progress, bounded transactions and explicit commit points.
Treat server-side CSV/file loading as privileged file access; a client upload and
a server filesystem path are not the same operation. Validate encoding, types,
missing endpoints and duplicate edges before publication. Quarantine malformed
records rather than creating synthetic endpoints silently.

After loading, analyze the relevant relations, audit dangling business references,
compare counts and test a known path. Large path fan-out must be tested before
making graph expansion part of every user request.

## Sources

- [Apache AGE upstream repository](https://github.com/apache/age)
- [Apache AGE PG18 1.8.0 release](https://github.com/apache/age/releases/tag/PG18%2Fv1.8.0-rc0)
- [Apache AGE SQL and Cypher composition](https://age.apache.org/age-manual/master/advanced/advanced.html)
- [PostgreSQL 18 CREATE INDEX](https://www.postgresql.org/docs/18/sql-createindex.html)
- [PostgreSQL 18 WITH queries](https://www.postgresql.org/docs/18/queries-with.html)
