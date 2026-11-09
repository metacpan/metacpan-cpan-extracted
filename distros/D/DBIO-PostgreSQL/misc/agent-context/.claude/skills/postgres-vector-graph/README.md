# PostgreSQL / Vector / Graph Engineering

An English, standalone Agent Skill for **PostgreSQL 18, pgvector, and Apache AGE**,
with particular emphasis on their composition rather than three unrelated manuals.

Start with [SKILL.md](SKILL.md). Its routing table directs the agent to focused
references; it should normally load only one to three at a time. The complete
[reference index](references/INDEX.md) is organized by subsystem and workflow.

## Package layout

```text
postgres-vector-graph/
  SKILL.md                      Entry point, routing, invariants, two small examples
  references/
    compatibility/              Version/build/provider gates
    postgres/                   PG18, schema, plans, transactions, FTS, security
    pgvector/                   Metrics, indexes, filtered ANN, model migrations
    age/                        Cypher, types, parameters, ingestion, RLS, features
    combinations/               Architecture, hybrid search, graph/vector order, outbox
    operations/                 Installation, pooling, resources, recovery, diagnosis
    integrations/               Reviewed companion skills and conflict resolution
    testing/                    Evidence levels and acceptance matrix
  examples/sql/                 Opt-in disposable database lab
  examples/python/              Prepared-map vector-first graph retrieval
  scripts/                      Offline validation and retrieval arithmetic
  tests/                        Offline unit tests and agent evaluation scenarios
  templates/                    Fingerprint, design decision, review, benchmark headers
  dependencies.json             Optional composition profiles; not an installer
  sources.json                  Reviewed primary-source registry
  VALIDATION.md                 What was actually checked, and what was not
  MANIFEST.json                 File inventory and SHA-256 hashes
```

## Install the skill

Extract the ZIP and install the **entire `postgres-vector-graph` directory** in the
skill location documented by your agent host. Preserve the nested references and
examples. Do not copy SKILL.md alone or concatenate every reference into it.
This package does not assume a particular repository, operating system, MCP
server, database connection, or agent tool name. Installation of the skill does
not authorize executing its SQL or connecting it to a database.

The default profile is **standalone**. The optional **composed** profile adds
Supabase `supabase-postgres-best-practices` and Microsoft `pg-graph`. Reviewed
commits, scope, and caveats are recorded in [companion research](references/integrations/companion-skills.md)
and [dependencies.json](dependencies.json). No external skills are bundled or
automatically installed. A missing companion never makes the standalone skill
unusable. This is not a universal `requires:` dependency mechanism.

## Reviewed baseline

Documentation and examples target PostgreSQL **18**, pgvector **0.8.6**, and Apache
AGE's **PG18 1.8.0 release**, whose actual tag is `PG18/v1.8.0-rc0`. The release title
and the tag are recorded separately on purpose. See the [version matrix](references/compatibility/version-matrix.md)
and primary sources there. PostgreSQL 19 or another later major requires a new
extension/build/provider/behavior gate; “18+” is a scope policy, not an untested
compatibility promise.

The lab fixes vector objects in `public`, graph objects in `skill_graph`, and
application objects in `skill_lab`. These are disposable examples, **not** a
recommendation to rely on an untrusted production `public` schema. Adapt extension
schemas and session initialization deliberately for the target deployment.

## Run the offline checks

Python 3.10+ and the standard library are sufficient. From this directory:

```sh
python -m unittest discover -s tests -v
python scripts/validate_package.py
python scripts/retrieval_metrics.py examples/metrics-input.json
```

No command above connects to a database or downloads anything. The arithmetic
fixture is synthetic, not measured retrieval quality. The validator checks local
links/anchors, JSON, Python AST, context budgets, dependency policy, and manifest
hashes. It does **not** validate PostgreSQL/Cypher semantics or external URL health.

## Optional live SQL lab

Read [installation](references/operations/install-build-deploy.md) and select an
approved **disposable PG18 database** with the correct extension binaries already
installed. Use a direct connection or a tested session pool. Configure credentials
through a libpq service file or another approved secret mechanism; do not put a
password in shell command history. Commands below assume `PGSERVICE` identifies
that reviewed target. Read each file before running it.

| Order | File | Effect |
|---|---|---|
| 1 | [00 preflight](examples/sql/00_preflight.sql) | Read-only discovery; no installation or LOAD |
| 2 | [01 bootstrap](examples/sql/01_bootstrap.sql) | Administrator-approved extension creation and AGE initialization |
| 3 | [02 schema/seed](examples/sql/02_schema_and_seed.sql) | Creates SQL schema, table, indexes and eight synthetic documents |
| 4 | [03 FTS/vector](examples/sql/03_hybrid_fts_vector.sql) | Read-only two-channel rank fusion |
| 5 | [04 graph seed](examples/sql/04_graph_seed.sql) | Creates graph, labels, eight vertices and five edges |
| 6 | [05 graph-first](examples/sql/05_graph_first_vector.sql) | Exact ranking inside a one-hop graph-defined subset |
| 7 | [06 three-way](examples/sql/06_three_way_fusion.sql) | Read-only FTS/vector/graph fusion |
| 8 | [07 rollback](examples/sql/07_atomic_rollback.sql) | Writes both layers, rolls back, then asserts absence |
| 9 | [10 filtered ANN](examples/sql/10_filtered_ann.sql) | Read-only exact/ANN/relaxed-order query shapes |
| Optional | [08 RLS setup](examples/sql/08_rls_setup.sql) | **Separate approval:** creates a cluster role and policies |
| Optional | [09 RLS assertions](examples/sql/09_rls_assertions.sql) | Selected checks as the restricted role |

Example invocation, after approval for the file's effects:

```sh
psql -X -v ON_ERROR_STOP=1 -f examples/sql/00_preflight.sql
```

Run the remaining approved files individually in the order above, not through an
unreviewed wildcard. Setup intentionally fails on existing lab objects rather than
repurposing them. There is no automatic destructive cleanup. RLS setup creates a
cluster-level role that is not removed merely by deleting the database. Have the
operator handle disposal of the isolated test environment.

Run ordinary fixture queries before enabling the optional policies. After RLS
setup, use the restricted role with the intended tenant context for application
tests, or an explicitly authorized administrator for cross-tenant auditing.
The `app.tenant_id` GUC demonstrates trusted service context; it is **not** secure
authentication for callers that can issue arbitrary SQL and change it themselves.

## Optional Python integration example

Install an approved **psycopg 3** build separately in your example environment.
There is intentionally no unreviewed network installer or claim of a tested
package lock. After SQL setup, use the fixed synthetic vector/graph space:

```sh
python examples/python/vector_first_graph.py --service YOUR_LAB_SERVICE --tenant 1 --execute
```

Add `--load-age` only for an authorized direct/session backend that requires it;
managed/preloaded targets may not permit LOAD. The example requests a prepared
parameter map, keeps all read stages in one short transaction, and does not assign
semantic seed distances to graph-expanded neighbors. Transaction pooling requires
separate verification of initialization and preparation behavior.

## Validation and limitations

See [VALIDATION.md](VALIDATION.md) for executed checks. This environment did not
have a PG18 server with both extensions, so the SQL/AGE/driver integration tests,
RLS scenarios, index plans, restore drill, concurrency tests, and load benchmarks
were **not executed here**. They are supplied as explicit deployment acceptance
work, not advertised as passed.

Use [architecture decisions](templates/architecture-decision.md), the
[acceptance matrix](references/testing/acceptance-matrix.md), and the
[review checklist](templates/review-checklist.md) when applying the skill to a real
system. Original package content is MIT-licensed; external source and companion
licensing is addressed in [THIRD_PARTY.md](THIRD_PARTY.md).
