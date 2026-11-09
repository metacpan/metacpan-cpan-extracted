# Vector seeds followed by bounded graph expansion

## Explicit two-stage implementation

The [Python example](../../examples/python/vector_first_graph.py) retrieves
semantic seeds, passes their business IDs through a prepared AGE parameter map,
expands one authorized edge, and joins returned IDs back to SQL content. It uses
one connection and one short repeatable-read, read-only transaction. It does not
invent a correlated `LATERAL cypher()` API.

```text
query vector + space + tenant
  -> bounded vector seed IDs
  -> prepared Cypher map {tenant, seed_ids, expansion_limit}
  -> bounded one-hop relationships
  -> relational reauthorization and content lookup
  -> seeds + related evidence, with their roles kept distinct
```

The example intentionally does not present every neighbor as a nearest neighbor.
A graph-expanded record may be semantically distant but useful supporting context.
Return a result role, seed ID, relationship evidence, and provenance rather than
assigning the seed's cosine distance to the neighbor.

## Budget each stage

Bound seed count, hop depth, allowed labels/types, expansion count, and final
context size. A small hop count does not bound work on a high-degree vertex.
Timeouts and expansion caps are still necessary. Limit and order behavior must
be explicit: a bounded query can return only a subset of a neighborhood.

For more than one hop, add a per-depth frontier budget, visited-set deduplication,
cycle handling, and an explanation of which paths are truncated. A path count is
not an independent evidence count. Duplicated extraction of the same source must
not inflate confidence.

## Transaction and driver requirements

With psycopg, start from `autocommit=True` and enter `conn.transaction()` before
issuing `SET TRANSACTION` or `SET LOCAL`. Otherwise initialization can leave an
implicit transaction open and turn the intended transaction into a savepoint.
The connection is retained for the whole multi-stage request.

The Cypher query text and graph name are fixed SQL literals. `%s` binds the
serialized map to `ag_catalog.agtype` *outside* the dollar-quoted body;
`prepare=True` requests a prepared statement. `$tenant` and `$seed_ids` are Cypher
map keys, not SQL bind placeholders. Verify this path on the deployed driver,
AGE build, and pool. Session initialization/preloading remains a separate gate.

## Failure semantics

If the graph is unavailable, return semantic-only results only when graph
expansion is an optional relevance feature. If the graph determines permissions,
failure must not broaden access. If graph projection lag exceeds the product's
freshness budget, disclose degraded evidence or decline that channel according
to policy. Recheck authoritative deletion and tenant status before content leaves
the service, and do not log raw vectors or document contents by default.

## Sources

- [Apache AGE prepared statements](https://age.apache.org/age-manual/master/advanced/prepared_statements.html)
- [Psycopg prepared statements](https://www.psycopg.org/psycopg3/docs/advanced/prepare.html)
- [Psycopg transaction management](https://www.psycopg.org/psycopg3/docs/basic/transactions.html)
- [PostgreSQL 18 SET](https://www.postgresql.org/docs/18/sql-set.html)
- [PgBouncer feature compatibility](https://www.pgbouncer.org/features.html)
