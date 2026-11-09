# Schema and integrity across three models

## Own the truth once

A practical default is relational ownership of documents/entities/relationships,
with vector rows and AGE graph structures as indexed or rebuildable projections.
This is a design choice, not a requirement imposed by AGE. A graph-native system
may own its truth in AGE, but then its export, constraints and recovery contract
must be explicit.

Start with tenant-scoped composite keys and composite foreign keys. A foreign key
on `doc_id` alone can accidentally connect rows across tenants when IDs are only
locally unique. Use typed columns for authorization, identity, status and values
that must be constrained. Use JSONB for genuinely variable attributes, not to
avoid deciding the data model.

## Separate identity from representation

Suggested production shape:

- `document(tenant_id, doc_id, source_version, title, body, deleted_at)` owns text.
- `embedding_space(space_id, model, revision, dimensions, metric, normalization)`
  identifies a coordinate system, not just a vector length.
- `document_embedding(tenant_id, doc_id, space_id, source_version, embedding)` owns
  one versioned representation with a composite foreign key to its source.
- `relationship(tenant_id, edge_key, source_id, target_id, relation_type,
  provenance_id, source_version)` optionally owns the graph projection input.

The lab deliberately co-locates a single embedding with each document to keep
SQL readable. It is not the recommended shape for many models/chunks per source.

## Invariants before indexes

Specify uniqueness, nullability, referential integrity, update/delete behavior,
source-version monotonicity and embedding eligibility. Reject zero-norm cosine
inputs, wrong dimensions, non-finite values and mismatched model versions at the
boundary. Do not normalize blindly: the model/metric contract determines whether
normalization is appropriate.

For chunked content, include a stable chunk key and source version. A document
with many chunks must not receive extra fusion weight accidentally. Define whether
ranking is per chunk, per entity, or per document and where deduplication occurs.

## Retention and deletion

Deletion is an end-to-end workflow: source row, embedding, graph vertices/edges,
caches, queued events and derived explanations. Decide whether deletion must be
immediate or may wait for projection lag. A deleted source must never remain
servable merely because a graph projection has not caught up.

Use [the architecture worksheet](../../templates/architecture-decision.md) to
record ownership and [the outbox reference](../combinations/consistency-and-outbox.md)
for retries and projection ordering.

## Sources

- [PostgreSQL 18 row security](https://www.postgresql.org/docs/18/ddl-rowsecurity.html)
- [PostgreSQL 18 CREATE INDEX](https://www.postgresql.org/docs/18/sql-createindex.html)
- [Apache AGE SQL and Cypher composition](https://age.apache.org/age-manual/master/advanced/advanced.html)
