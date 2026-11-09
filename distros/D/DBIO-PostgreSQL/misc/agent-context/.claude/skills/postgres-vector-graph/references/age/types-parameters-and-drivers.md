# agtype, JSONB, parameters and drivers

## Keep types explicit at the boundary

AGE returns `agtype` values. Convert scalars deliberately before SQL joins;
`g.doc_id::bigint` is appropriate only when the stored property is an integer.
JSON-shaped output does not make the entire type interchangeable with JSONB.

AGE 1.8 adds bidirectional JSONB casts. The pinned regression suite tests scalar,
array, object and graph-object conversions. Use `value::jsonb` after checking the
feature, and extract a JSON string with `#>> '{}'` or object fields with `->>`.
Do not strip quotes with `trim('"' ...)`: that corrupts legitimate content and
escapes. SQL NULL, JSON null and a missing property need separate tests.

## Prepared parameter-map pattern

```sql
PREPARE find_document(ag_catalog.agtype) AS
SELECT g.doc_id::bigint
FROM ag_catalog.cypher('skill_graph', $$
  MATCH (d:document)
  WHERE d.tenant_id = $tenant AND d.doc_id = $document_id
  RETURN d.doc_id
$$, $1) AS g(doc_id ag_catalog.agtype);
EXECUTE find_document('{"tenant":1,"document_id":101}');
DEALLOCATE find_document;
```

`$tenant` is a Cypher parameter inside the Cypher source. SQL `$1` is the external
map argument. A host `%s` or `$1` written inside dollar quotes is merely part of
the quoted text; it does not bind application input. The documented parameter-map
path requires prepared execution; do not replace it with arbitrary row-correlated
JSON expressions and assume it works.

## Psycopg integration

The Python example passes a serialized JSON map to `%s::ag_catalog.agtype` and
requests server preparation with `prepare=True`. It binds values, not identifiers,
and uses a literal, application-controlled graph name. Prove this with the pinned
AGE/driver/pool combination, including repeated executions and tenant switching.

Use the official AGE driver when richer value decoding is needed, but inspect
its supported Python and connection APIs at the chosen version. Do not assume
that a driver for another Cypher database works unchanged.

The executable example needs a direct connection or a tested session-pool path.
SQL PREPARE and protocol-level preparation have different pool compatibility;
read the pooling reference rather than treating them as interchangeable.

## Sources

- [AGE PG18 1.8.0 JSONB-cast regression](https://github.com/apache/age/blob/PG18/v1.8.0-rc0/regress/sql/agtype_jsonb_cast.sql)
- [Apache AGE prepared statements](https://age.apache.org/age-manual/master/advanced/prepared_statements.html)
- [Apache AGE Cypher query format](https://age.apache.org/age-manual/master/intro/cypher.html)
- [Psycopg prepared statements](https://www.psycopg.org/psycopg3/docs/advanced/prepare.html)
- [PgBouncer feature compatibility](https://www.pgbouncer.org/features.html)
