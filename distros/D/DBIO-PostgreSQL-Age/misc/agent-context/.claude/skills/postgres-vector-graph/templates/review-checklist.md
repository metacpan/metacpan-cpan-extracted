# Deployment review checklist

Record evidence or an explicit untested status for every item.

- [ ] PG18/build/provider compatibility and exact extension versions verified.
- [ ] Extension schemas, trusted search path, AGE initialization and pool mode verified.
- [ ] Stable tenant/business keys and source/embedding-space versions defined.
- [ ] Appropriate vector metric/operator class; dimensions and zero/NULL handling checked.
- [ ] Raw ANN ordering, iterative scan limits, underfill and exact baseline measured.
- [ ] Lexical language/rank semantics documented; no accidental BM25 claim.
- [ ] Graph traversal direction, type, depth, fan-out and truncation semantics bounded.
- [ ] Prepared parameter maps verified through the actual driver and pool.
- [ ] SQL and graph policies tested independently as non-owner, non-bypass roles.
- [ ] Direct label/base-table/unlabeled/edge/new-label paths reviewed.
- [ ] Tenant GUC cannot substitute for authentication of arbitrary SQL callers.
- [ ] Atomic rollback, duplicate replay, concurrent writers and stale jobs tested.
- [ ] Deletion tombstones, graph/embedding reconciliation and lag monitoring defined.
- [ ] Fusion deduplicates per document/channel and distinguishes scores from confidence.
- [ ] Load, memory, maintenance and ingestion interference measured on target hardware.
- [ ] Restore and upgrade rehearsal includes extensions, policies and known queries.
- [ ] Companion sources/commits reviewed; no unintended MCP/tool/network activation.
- [ ] Claims distinguish source review, static checks, unit tests, integration and benchmarks.
