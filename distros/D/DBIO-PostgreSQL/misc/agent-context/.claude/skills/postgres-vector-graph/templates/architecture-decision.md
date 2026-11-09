# Architecture decision: relational / vector / graph composition

Status: proposed / accepted / superseded
Decision owner and review date:

## Workload and measurable goal

Describe users, ranking unit, corpus size, update rate, concurrency, latency and
recall/relevance targets. Distinguish hard eligibility constraints from optional
ranking signals. Record the SQL-only or simpler baseline.

## Version and deployment gate

Record PostgreSQL major/minor, extension versions and resolved source commits,
provider/OS/architecture, extension schemas, session initialization, pool mode,
prepared-statement behavior, and actual application role.

## Data ownership and identities

Record relational keys, tenant boundary, graph projection keys, vector dimensions,
metric and embedding-space identity, source versions, provenance, chunk/document
mapping, deletion behavior, and uniqueness/concurrency strategy.

## Chosen retrieval path

Specify SQL-only, FTS/vector, graph-first, vector-first, or three-way fusion.
State whether ranking is exact within a subset or approximate; bound every
candidate stage and traversal. Describe authorization inside every channel.

## Consistency and failure behavior

Choose synchronous atomic projection or an asynchronous outbox. Define maximum
lag, retries, deduplication, stale-job rejection, tombstones, reauthorization,
reconciliation, timeout/cancellation behavior, and channel fallback semantics.

## Evidence and alternatives

Attach query plans, offline arithmetic checks, live integration and role results,
held-out retrieval judgments, latency/resource measurements, concurrency tests,
and restore rehearsal. Label every unexecuted test explicitly.

## Operational change plan

State rollout, monitoring, rollback, recovery, expected lock/load impact, approval
requirements, and next review triggers. Explain why the simpler alternatives
were insufficient; do not justify the graph merely by naming GraphRAG.
