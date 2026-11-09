# Choose a composition and make ownership explicit

## Decision table

| Requirement | Starting design | Question to prove |
|---|---|---|
| Exact filters, constraints, simple joins | PostgreSQL tables and indexes | Is a graph or embedding actually needed? |
| Similar meanings or approximate neighbors | SQL + pgvector | Does it improve relevance over lexical search? |
| Known entities and relationship traversal | SQL + AGE | Is traversal more expressive or maintainable than a recursive SQL query? |
| Exact terms plus paraphrases | FTS + pgvector | Does fusion improve held-out relevance? |
| Eligibility is determined by relationships | AGE first, vector ranking second | Is the eligible set complete and authorized? |
| Discover related material around semantic matches | Vector first, bounded AGE expansion | Does expansion add evidence rather than noise? |
| Three independently useful relevance signals | FTS + vector + AGE rank fusion | Does the graph channel improve the two-channel baseline? |

These are engineering starting points, not automatic performance rankings. Keep
an SQL-only or two-channel baseline in the benchmark. A graph is not mandatory
for retrieval-augmented generation.

## Default ownership model

The relational record owns `(tenant_id, document_id)`, content version, lifecycle,
authorization, and embedding-space identity. AGE vertices repeat a stable business
key and relationship metadata. `graphid` is an implementation identity, not the
application foreign key. Vector columns remain typed SQL columns with a declared
metric and index operator class.

Example logical mapping, not extra DDL to run:

```text
SQL document (tenant_id, document_id, content_version)
SQL embedding (tenant_id, document_id, space_id, source_version, vector)
AGE document {tenant_id, document_id}
AGE related  {tenant_id, evidence_id, extractor_version, valid_from}
```

A separate embedding table permits multiple spaces and migrations without
pretending vectors from different models are comparable. The small lab combines
one embedding with each document only to keep the executable examples readable.
For multiple chunks, use chunk identities and define whether results are ranked
as chunks or aggregated to documents. Prevent documents with many chunks from
receiving accidental multiple fusion contributions.

## Query boundaries

Put hard authorization and lifecycle filters in every candidate channel. Recheck
returned IDs against authoritative relational records before returning content.
This final check is defense in depth, not permission to expose unauthorized graph
neighborhoods, counts, intermediate results, or derived explanations.

The SQL optimizer does not promise a single fused HNSW-plus-graph access path.
Explicitly materialized candidate sets are useful boundaries, but can prevent
index use. For large graph-defined sets, benchmark exact subset ranking, an
ANN-then-intersection approximation, or a maintained relational membership
projection. The latter requires its own freshness and deletion contract.

## Required design record

Record owners, keys, source versions, tenant boundary, candidate budgets, graph
hop/edge limits, ranking unit, freshness tolerance, deletion propagation, and
fallback behavior. Use the [architecture template](../../templates/architecture-decision.md).

## Sources

- [pgvector upstream reference](https://github.com/pgvector/pgvector)
- [Apache AGE SQL and Cypher composition](https://age.apache.org/age-manual/master/advanced/advanced.html)
- [PostgreSQL 18 WITH queries](https://www.postgresql.org/docs/18/queries-with.html)
- [PostgreSQL 18 row security](https://www.postgresql.org/docs/18/ddl-rowsecurity.html)
