# Transactions, snapshots, locking and retries

## Connection scope is part of correctness

`SET LOCAL` applies within the current transaction. A setting on connection A
cannot tune a query issued on connection B. In an autocommit client, sending
`SET LOCAL` as a separate statement does not establish the intended next-query
scope. Pin a connection, start a transaction, set tenant and tuning values, then
execute all dependent statements before committing or rolling back.

For vector-first graph retrieval, a short `REPEATABLE READ READ ONLY` transaction
is a useful design when both stages must see one database snapshot. It does not
repair graph projection lag that already existed when that snapshot began.

## Atomic changes versus consistent projections

When relational and graph mutations run in the same PostgreSQL database and the
same transaction, commit/rollback can cover both. Separate autocommit calls,
connections, databases or queue consumers do not have that property. Avoid
embedding API/network calls while holding transaction locks: compute externally,
then write with a source-version precondition.

## Psycopg's implicit transaction trap

A setup statement can open an implicit outer transaction. Entering
`connection.transaction()` afterward may create only a savepoint. Releasing that
savepoint is not a durable outer commit. The executable Python example opens the
connection in autocommit mode, then starts an explicit transaction, so its scope
is unambiguous.

## Concurrency contract for graph writes

Do not describe Cypher `MERGE` as equivalent to a verified concurrent unique
constraint. Choose one controlled writer per entity/partition, a transaction-level
advisory lock keyed by a stable business identity, or a tested unique-index and
retry strategy supported by the pinned AGE build. Use relational uniqueness for
the authoritative key registry where possible.

Retries need an idempotency key, bounded attempt count, backoff, and an identified
class of transient errors. Retry the entire transaction on serialization/deadlock
failure, not the last graph statement in an already-aborted transaction. Never
swallow all exceptions and mark a projection event delivered.

The rollback example proves neither contention behavior nor exactly-once
processing. Run the concurrency cases in the acceptance matrix separately.

## Sources

- [PostgreSQL 18 SET](https://www.postgresql.org/docs/18/sql-set.html)
- [Psycopg transaction management](https://www.psycopg.org/psycopg3/docs/basic/transactions.html)
- [Apache AGE upstream repository](https://github.com/apache/age)
