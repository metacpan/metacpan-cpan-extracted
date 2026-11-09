# AGE advanced capabilities: version-gated exploration

## Separate release evidence from exercised behavior

The PG18 1.8 release notes include JSONB casts, shortest-path set-returning
functions, subgraph creation, additional MERGE clauses, `reduce()` support,
preloading and traversal improvements. This package exercises JSONB conversion
and basic SQL/Cypher composition; it does not claim runtime validation of every
new facility.

Before using an advanced capability, inspect installed signatures and the
matching release's regression examples:

```sql
SELECT p.oid::regprocedure AS signature
FROM pg_proc AS p
JOIN pg_namespace AS n ON n.oid = p.pronamespace
WHERE n.nspname = 'ag_catalog'
  AND (p.proname LIKE '%shortest_path%' OR p.proname LIKE '%subgraph%'
       OR p.proname LIKE '%upgrade%')
ORDER BY 1;
```

Function discovery is not permission to execute it. Review semantics, privileges,
resource behavior and mutability first. For overloads, capture exact argument
and return types. Do not invent `shortestPath()` syntax based on Neo4j examples
when the observed AGE capability is an SQL set-returning function.

## Bounded traversal design

Define direction, permitted edge types, a maximum hop count, tenant/object
permissions, cycle behavior, output cap and timeout. An outer LIMIT alone may
not bound intermediate path enumeration. Test hubs, cycles, duplicate paths,
zero-hop behavior and a missing target.

Prefer a small expansion depth with measured fan-out for retrieval. Do not label
a path's confidence as a probability merely because each edge stores a number.
A minimum edge score is a possible conservative heuristic, not a generally
valid probabilistic inference rule. Return provenance and uncertainty explicitly.

## No imaginary extension APIs

A source file named `cypher_with.sql` tests the Cypher WITH clause; its name is
not evidence of an installed `cypher_with()` function. Likewise, a roadmap entry,
open PR, driver method or regression-file name is not a released SQL interface.
Only the installed catalog plus matching primary documentation establish the
usable boundary.

## Sources

- [Apache AGE PG18 1.8.0 release](https://github.com/apache/age/releases/tag/PG18%2Fv1.8.0-rc0)
- [AGE PG18 1.8.0 JSONB-cast regression](https://github.com/apache/age/blob/PG18/v1.8.0-rc0/regress/sql/agtype_jsonb_cast.sql)
- [Apache AGE Cypher query format](https://age.apache.org/age-manual/master/intro/cypher.html)
