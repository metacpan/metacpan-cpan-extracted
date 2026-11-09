# AGE security and tenant isolation

## Do not inherit obsolete assumptions

AGE's PG18 1.7 release includes RLS support and permission fixes; the 1.8 release
builds on that work. It is wrong to assert that AGE categorically has no RLS.
It is equally wrong to claim that enabling RLS on an ordinary document table
protects every Cypher traversal automatically.

## Tenant boundary choices

Possible designs include separate databases, separate graphs/schemas, and a
shared graph with carefully tested label-table policies. These have different
administration and isolation costs. Separate graphs still require reviewed role
privileges; a schema name is not an authentication boundary.

For a shared graph, account for vertex labels, edge labels, default/base labels,
newly created labels, explicit SQL access and Cypher access. Policy attachment
must be part of the graph schema migration. Do not assume parent/inherited-table
policy behavior carries over unchanged to every query path.

## A concrete 1.8 policy expression

```sql
-- Illustrative policy after graph creation; requires AGE JSONB casts.
ALTER TABLE skill_graph.document ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_graph.document FORCE ROW LEVEL SECURITY;
CREATE POLICY document_tenant ON skill_graph.document
USING ((properties::jsonb ->> 'tenant_id')::bigint =
       NULLIF(current_setting('app.tenant_id', true), '')::bigint)
WITH CHECK ((properties::jsonb ->> 'tenant_id')::bigint =
            NULLIF(current_setting('app.tenant_id', true), '')::bigint);
```

This protects only this label relation; it is not a complete shared-graph security
configuration. The executable lab role script attaches policies to all existing
fixture labels. Production must also govern future labels and the trusted source
of tenant context. Application users must not create arbitrary labels/schemas.

## Tests that matter

Run labeled MATCH, unlabeled MATCH, direct label-table SQL, incoming/outgoing
edges, optional matches, bounded variable-length paths, writes, deletes, prepared
queries and reused connections as a non-owner/non-BYPASSRLS role. Put a
cross-tenant edge in a dedicated adversarial fixture; assert that neither the
foreign endpoint nor its identity/path evidence is disclosed.

The package includes basic role tests and a broader acceptance matrix. Basic
success is not certification of all traversal shapes. A provider-patched build
needs the same tests. Never make a SECURITY DEFINER/superuser escape hatch the
solution to a failing permission test.

## Sources

- [Apache AGE PG18 1.8.0 release](https://github.com/apache/age/releases/tag/PG18%2Fv1.8.0-rc0)
- [AGE security regression suite](https://github.com/apache/age/blob/fa109ef1ddb1c7a945a1c340195d650000e49713/regress/sql/security.sql)
- [AGE PG18 1.8.0 JSONB-cast regression](https://github.com/apache/age/blob/PG18/v1.8.0-rc0/regress/sql/agtype_jsonb_cast.sql)
- [PostgreSQL 18 row security](https://www.postgresql.org/docs/18/ddl-rowsecurity.html)
- [PostgreSQL 18 schemas and search_path](https://www.postgresql.org/docs/18/ddl-schemas.html)

- [AGE PG18 1.8.0 graph/label catalog definitions](https://github.com/apache/age/blob/PG18/v1.8.0-rc0/sql/age_main.sql)
