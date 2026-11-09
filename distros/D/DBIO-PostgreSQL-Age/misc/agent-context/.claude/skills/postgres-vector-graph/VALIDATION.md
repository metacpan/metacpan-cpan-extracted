# Validation report

Review and package date: **2026-09-30**. Python used for offline checks: **3.13.5**.

## Executed successfully

| Check | Result | Scope |
|---|---|---|
| Offline unittest suite | **57 tests passed** | RRF, duplicate handling, weights, recall, nDCG, cosine, input validation, and package contracts |
| Package validator | Passed | Local files/links/heading anchors, reference routing, context budgets, JSON parsing, Python AST, optional-dependency policy |
| YAML frontmatter | Parsed with PyYAML during creation | Required name/description and metadata inspected; not a universal host certification |
| Metrics CLI | Executed on bundled synthetic input | Arithmetic only; no measured database retrieval |
| Inventory | SHA-256 hashes and sizes recorded | MANIFEST.json covers every distributable file except itself |

The reproducible unit-test log is in [offline-results.txt](tests/offline-results.txt).
Run the manifest validator after extraction to verify the delivered files.

## Not executed

There was no matching PostgreSQL 18 + pgvector + Apache AGE environment available
for live tests. The following are **source-reviewed or specified, not passed**:

- Extension compilation/regression and combined PG18 initialization.
- SQL/Cypher execution, prepared maps through psycopg, and connection-pool behavior.
- RLS tests, cross-model rollback, concurrent replay/deletion interleavings.
- Query plans, ANN recall on a real corpus, relevance evaluation, and load measurements.
- Backup/restore, replication, upgrade, and disaster-recovery rehearsal.
- The 22 agent scenarios; these are evaluation prompts and criteria, not model-run results.

No external companion skill was installed, vendored, invoked, or security-certified.
No MCP server or database connection was activated. Referenced external URL health
is not comprehensively checked by the offline validator.

## Interpretation

The skill and its references can be installed independently of running the lab.
The SQL examples share an internally consistent synthetic schema and were reviewed
against primary documentation and selected AGE release sources, but must be tested
on the target build before reuse. In particular, a static AST/link test does not
parse or prove PostgreSQL/Cypher semantics.

The toy vectors and metrics input are deliberately synthetic. Their successful
arithmetic tests establish neither semantic-search quality nor production latency.
Use the [acceptance matrix](references/testing/acceptance-matrix.md) to record
additional target-specific evidence without erasing these limits.
