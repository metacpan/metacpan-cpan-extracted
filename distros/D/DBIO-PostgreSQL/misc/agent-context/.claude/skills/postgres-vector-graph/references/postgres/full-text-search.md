# Native full-text search without false BM25 claims

## Establish a lexical baseline

Use an explicit text-search configuration consistently at ingestion and query
time. The lab uses English, weighted title/body lexemes and a stored `tsvector`.
A GIN index narrows lexical matches; ranking still has a cost on broad matches.

```sql
SELECT doc_id,
       ts_rank_cd(search_document,
                  websearch_to_tsquery('english', 'connection pooling')) AS score
FROM skill_lab.document
WHERE tenant_id = 1
  AND search_document @@ websearch_to_tsquery('english', 'connection pooling')
ORDER BY score DESC, doc_id
LIMIT 50;
```

Native `ts_rank` and `ts_rank_cd` are not BM25 and do not become BM25 by changing
a normalization argument. Use their names accurately. A true BM25 extension is
an additional dependency with its own PG18 build, SQL, license and upgrade gates.
It is intentionally not required by this skill.

## Design decisions that need tests

Language detection, multilingual corpora, identifier tokenization, stop words,
prefixes, phrases and stemming can all change the lexical candidate set. Test
error codes, model numbers, acronyms and quoted phrases from the real workload.
Do not treat a document-only ranking function as a universal relevance oracle.

Preserve positions when using proximity-based ranking. For multilingual content,
choose separate indexed representations or an explicit per-row configuration;
avoid accidentally indexing with one configuration and querying with another.

## Hybrid boundary

A vector distance and an FTS score have different scales and directions. Rank
fusion is a convenient baseline because it uses each channel's order rather than
adding incomparable raw scores. It still requires labeled evaluation and a
candidate budget. A lexical channel that emits no hits should remain empty, not
be replaced with fabricated neutral matches.

See [hybrid SQL](../../examples/sql/03_hybrid_fts_vector.sql) and
[the fusion design](../combinations/hybrid-fts-vector.md).

## Sources

- [PostgreSQL 18 text-search controls](https://www.postgresql.org/docs/18/textsearch-controls.html)
- [PostgreSQL 18 generated columns](https://www.postgresql.org/docs/18/ddl-generated-columns.html)
