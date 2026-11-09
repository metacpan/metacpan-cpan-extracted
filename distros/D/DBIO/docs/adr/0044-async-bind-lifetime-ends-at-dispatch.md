# ADR 0044 — A bind arrayref's life ends at dispatch, not at settle

- Status: accepted
- Date: 2026-08-28
- Tags: async, storage, driver-contract, memory, cross-repo

> Accepted by maintainer decision in karr k156 (2026-08-28, option A).

## Context

Every async transport builds its query seam the same way since
`DBIO::Storage::PoolBase::acquire` became a Future (the connection-readiness
seam, karr k75): the body of `_query_async` moved inside a `->then` callback,
because the connection is not in hand until the acquire resolves.

    return $self->pool->acquire->then(sub {          # closure over $sql, $bind
      my $conn = shift;
      ...
    });

That `then` callback is a **closure over `$bind`**. Any anonymous sub created
*inside* it — the completion callback, or the `on_ready` that returns the
connection to the pool — carries a strong `CvOUTSIDE` pointer to that closure,
and therefore keeps its whole pad alive. The bind arrayref stays reachable for
as long as the transport holds that callback, i.e. for the entire flight of the
query, even though no callback mentions `$bind`.

Nothing about this is visible in the code. It is a property of Perl's closure
cloning, not of anything DBIO writes down, and the three async drivers all
acquired it silently when they adopted the readiness seam:

| dist | shape | retains `$bind` in flight |
|---|---|---|
| `dbio-async` | `_await_query_result(...)->on_ready(sub { ...release... })` inside the `then` | yes — via the `on_ready` sub |
| `dbio-postgresql-ev` | `query_params(..., sub { ... })` built inside the `then` | yes — via the completion callback |
| `dbio-mysql-ev` | `_executor->execute(...)`, then `on_ready(sub { ...release... })` inside the `then` | yes — via the `on_ready` sub |

The family had also drifted into two contradictory test contracts. The
`bind-release` suites in `dbio-async` and `dbio-postgresql-ev` assert that no
bind arrayref is retained while queries are in flight; `dbio-mysql-ev`'s
`t/12-bind-release.t` asserts the opposite — that each in-flight query keeps its
bind payload intact, and that the caller's array is *emptied* when the query
settles. Both cannot hold, and the second one structurally requires the
retention the first one forbids.

## Decision

**A bind arrayref's life ends when the statement is dispatched to the
transport, not when it settles.** By the time `query_params` / `execute`
returns, the transport has serialised the values into its own wire buffer;
nothing on the Perl side may keep the arrayref reachable afterwards.

The rule this imposes on every driver: **build no callback inside the `then`
closure.** Any sub that the transport will hold — the completion callback, the
pool-release `on_ready` — must be created in a **named** sub that takes what it
needs as arguments. A named sub's pad is not a closure pad, so the callback
cloned inside it captures only what it references.

    # WRONG -- the on_ready sub pins the then closure's pad, and $bind with it
    return $self->pool->acquire->then(sub {
      my $conn = shift;
      return $self->_await_query_result($conn, $sql, $bind)
        ->on_ready(sub { $self->pool->release($conn) });
    });

    # RIGHT -- the callback is built in a named sub; the then closure is
    # released as soon as it has fired, and $bind goes with it
    sub _release_on_ready {
      my ($self, $conn) = @_;
      return sub { $self->pool->release($conn) };
    }
    ...
    return $self->pool->acquire->then(sub {
      my $conn = shift;
      return $self->_await_query_result($conn, $sql, $bind)
        ->on_ready($self->_release_on_ready($conn));
    });

The `then` closure still closes over `$bind` — it must, to issue the query —
but it is freed the moment it has fired, so the retention window shrinks from
"the flight of the query" to "until the acquire resolves".

Consequently the caller's bind array is **not** the driver's to mutate.
Emptying it at settle (`dbio-mysql-ev`) was a way to bound memory under the old
retention; with the retention gone it is an unnecessary side effect on data the
caller still owns, and it goes.

## Rationale

The retention was never unbounded — it is bounded by the number of outstanding
queries, not by the total ever issued, so it is not a leak. It is still worth
removing:

- The bound that matters is *count × payload*. A pipeline of a few thousand
  in-flight inserts with large bind payloads doubles its peak for no reason:
  once for libpq's buffer, once for the Perl arrayref nobody will read again.
- The alternative contract (retain, then wipe the caller's array) buys the same
  bound by mutating data the caller handed in. That is a surprising API
  side effect, and it only exists to compensate for the retention.
- The cost of the rule is one named sub per driver. Verified on a minimal Perl
  test case: with the callback built inside the `then` closure the bind is held
  in flight; with it built in a named sub it is freed at dispatch. Nothing else
  about the seam changes.

## Consequences

- `DBIO::Storage::Async`'s `_query_async` / `_query_async_pinned` seam
  documentation states the rule, because the readiness seam is what created the
  trap and the naive implementation is the retaining one.
- The `bind-release` suites in `dbio-async` and `dbio-postgresql-ev` keep the
  assertion they were written with (zero retained in flight); it is now
  reachable rather than accidental.
- `dbio-mysql-ev` follows the same rule, and its `t/12-bind-release.t` loses the
  in-flight-intact and empty-on-settle assertions along with the wipe they
  described.
- A driver that genuinely needs the bind values after dispatch (tracing,
  retry-on-reconnect) must take its own copy and say so — it may not keep the
  caller's arrayref alive by accident.

## Future architecture work (tracked cross-repo, not here)

The three driver-side changes are owned by their own repos and tracked there:
`dbio-async` k9, `dbio-postgresql-ev` k29, `dbio-mysql-ev` k27. This ADR is the
head; none of them restates it.
