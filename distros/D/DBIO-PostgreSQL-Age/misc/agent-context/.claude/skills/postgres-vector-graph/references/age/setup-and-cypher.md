# AGE setup and the SQL/Cypher boundary

## Separate installation, database enablement and session setup

Binary installation targets a PostgreSQL major. `CREATE EXTENSION age` enables
AGE in one database. A backend must then have AGE loaded or appropriately
preloaded before using its parser hooks. A connection pool's client connection
is not necessarily a persistent server session.

For the self-hosted administrator lab:

```sql
CREATE EXTENSION age;
LOAD 'age';
SET search_path = pg_catalog, ag_catalog, public;
SELECT ag_catalog.create_graph('skill_graph');
```

These statements change database/session state; do not run them as a blind probe.
The examples qualify application table creation explicitly, avoiding accidental
creation inside `ag_catalog`. Audit the privileges of every schema in the path.
A restricted managed role may be unable to execute `LOAD`; arrange supported
preloading/initialization instead of granting superuser.

## Query shape

```sql
SELECT *
FROM ag_catalog.cypher('skill_graph', $$
  MATCH (a:document)-[r:related]->(b:document)
  WHERE a.tenant_id = 1 AND r.tenant_id = 1 AND b.tenant_id = 1
  RETURN a.doc_id, b.doc_id
$$) AS g(source_id ag_catalog.agtype, target_id ag_catalog.agtype);
```

The SQL record definition must match the Cypher return columns. Even graph writes
without returned values need a record definition. Cypher belongs in the FROM
position (or an appropriate subquery), not as an arbitrary scalar SQL function.

Keep graph writes as explicit statements in an explicit transaction. Do not hide
CREATE/SET/MERGE effects inside an apparently read-only join. Review the exact
AGE limitations before composing mutating Cypher with SQL constructs.

## Scope the language

Support for openCypher does not mean every Neo4j feature exists. Do not invent
APOC, GDS, driver protocols, schema commands, vector functions or shortest-path
syntax from another product. Inspect labels/properties before generating a
query and validate newer AGE capabilities against the pinned release.

Use lowercase graph/label names in the lab to keep SQL identifier handling
visible. Production identifiers may differ; quote SQL identifiers correctly and
never use a user-provided label as unchecked query text.

## Sources

- [Apache AGE upstream repository](https://github.com/apache/age)
- [Apache AGE Cypher query format](https://age.apache.org/age-manual/master/intro/cypher.html)
- [Apache AGE SQL and Cypher composition](https://age.apache.org/age-manual/master/advanced/advanced.html)
- [PostgreSQL 18 schemas and search_path](https://www.postgresql.org/docs/18/ddl-schemas.html)
