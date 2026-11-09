# ADR 0055 — `immediate` `txn_do_async` hands the coderef a context and adopts a returned Future

- Status: accepted
- Date: 2026-09-22
- Tags: async, future, storage, immediate, transaction, contract, builds-on-0030, follows-0053

## Context

ADR 0030 made async an explicit per-connection mode and rebuilt the storage-level
`$storage->*_async` methods around a three-way dispatch (`_run_async` in
`lib/DBIO/Storage.pm`): route to the embedded backend on a live async
connection, croak on a sync instance, and — in the `immediate` mode — run the
ordinary synchronous op in-process and wrap its return in an immediately-resolved
`future_class`.

ADR 0053 (karr k201) fixed the *read-result form* of that `immediate` branch: the
value a storage-level `*_async` resolves with is backend-independent. Its audit
also found that `txn_do_async` was **incompatible** between `immediate` and a real
`DBIO::Storage::Async` backend along two further axes — a distinct decision about
the callback's *input* and *return adoption* rather than the resolved read shape —
and deferred it here (ADR 0053 §"`txn_do_async` — audited, incompatible, deferred").

A real backend's `txn_do_async` / `_txn_terminal_chain` (`lib/DBIO/Storage/Async.pm`):

1. **Callback signature.** Calls `$coderef->($txn_ctx, @args)` — the first
   argument is a `DBIO::Storage::Async::TransactionContext` pinned to the
   transaction connection, whose `*_async` methods route CRUD onto that one
   connection. The documented portable pattern is
   `sub { my ($ctx) = @_; $ctx->insert_async(...) }`
   (`lib/DBIO/Manual/AsyncStorage.pod`).
2. **Returned-Future adoption.** Wraps the coderef's return as
   `ref($inner) && $inner->can('then') ? $inner : $fc->done($inner)` and sequences
   into it — commit on the Future's success (resolving with its value(s)),
   rollback on its failure.

The `immediate` branch did neither. `_run_immediate('txn_do', ...)` fell through
to the bare `$self->$op(@args)` pass-through, i.e. the synchronous
`txn_do($coderef, @args)`, which (via `DBIO::Storage::BlockRunner`) calls
`$coderef->(@args)` — **no context object** — and then `_run_async` did
`$fc->done(@r)` on whatever the coderef returned. So:

- the portable pattern died under `immediate`
  (`Can't call method "insert_async" on an undefined value`), because `my ($ctx)
  = @_` took the first *caller* argument (or `undef`);
- a returned inner Future was wrapped as the resolved *value*, so `->get` handed
  back the Future object rather than its resolved value;
- a returned **failed** Future did not roll back — the sync `txn_do` only rolls
  back on a *thrown* exception, and a returned failed-Future object is not a
  throw, so the transaction committed with a failed Future as its value.

The gap stayed latent because no test and no ORM path exercised the storage-level
`txn_do_async` callback contract under `immediate` — the ResultSet/Row tier never
routes a transaction through it.

## Decision

The storage-level `txn_do_async` callback contract is **backend-independent**: the
coderef is called with a context as its first argument, extra arguments follow it,
and a returned Future is adopted — the same across every async mode including
`immediate`. `immediate` is a faithful stand-in of a real backend at the storage
level for transactions, exactly as ADR 0053 made it one for reads.

`_run_immediate` (`lib/DBIO/Storage.pm`) routes the `txn_do` op through a new
`_run_immediate_txn($coderef, @args)` helper — the third op-specific exception
alongside the two reads — which:

- **Context = the storage itself (`$self`).** `immediate` has no event loop and no
  pinned connection: the sync op each `*_async` runs happens in-process, already
  inside the sync transaction the helper opens with `$self->txn_do(...)`. The
  storage's own `*_async` / `txn_do_async` methods are therefore exactly the ones
  a real backend's `TransactionContext` exposes, and CRUD issued through the
  context participates in the transaction — so `$coderef->($self, @args)` makes
  `sub { my ($ctx) = @_; $ctx->*_async(...) }` substitutable across modes. A thin
  `immediate`-specific context wrapper was rejected as speculative surface (house
  rule 2): the documented portable pattern uses only `*_async` / `txn_do_async`,
  all present on `$self`, and a pinned connection or `in_txn` guard is meaningless
  where there is a single in-process transaction and no pool.
- **Adopts a returned Future.** When the coderef returns a Future
  (`blessed($inner) && $inner->can('then') && $inner->can('get')`), the helper
  resolves it with `->get`: the value(s) become the transaction's result, and a
  failure is re-raised as a throw so the enclosing sync `txn_do` rolls back. This
  is what makes the commit-on-success / rollback-on-failure decision match a real
  backend, not only the resolved value. Under `immediate` every `*_async` Future
  is already resolved, so `->get` never blocks. A plain (non-Future) return passes
  straight through, as `$fc->done($inner)` would carry it.

The helper's body runs in the list context `_run_async` invokes `_run_immediate`
under, so `->get` resolves the full value list of a multi-value Future, and
`_run_async`'s `$fc->done(@r)` then carries all of them.

The `blessed(...)` guard is deliberately one notch stricter than the real
backend's `ref($inner) && $inner->can('then')`: `->can` on an unblessed reference
throws, so `blessed` is the safe predicate for a coderef that legitimately returns
a plain hashref/arrayref value, and it detects every real Future (all are blessed)
identically. (The real backend has since taken the same predicate -- see the
addendum of 2026-10-04.)

## Consequences

- `$storage->txn_do_async(sub { my ($ctx) = @_; $ctx->*_async(...) })` behaves the
  same in `immediate` mode as against any real backend: `$ctx` is a usable context,
  extra args pass through, a returned Future is adopted, and a returned failed
  Future rolls back.
- The change is confined to `_run_immediate` + the new `_run_immediate_txn` in
  `lib/DBIO/Storage.pm`, plus the `txn_do_async` POD there. No `@ISA` change, no
  new capability, no driver touch, and `txn_do_async`'s `($coderef, @args)`
  signature is unchanged — so no ADR 0024 contract-version bump (none of the five
  contract-versioned base classes shifts its public shape).
- Existing `immediate` `txn_do_async` tests are unaffected: coderefs that ignore
  their arguments and return a plain value still commit and resolve with that value
  (`t/test/09_async.t`, `t/test/14_async_backend.t`), because a prepended context
  argument an ignoring coderef never reads changes nothing and a plain return still
  passes through.
- New offline regression `t/test/34_async_immediate_txn_contract.t` pins the
  property by comparing `immediate` against a real, fully-synchronous
  `DBIO::Storage::Async` transport (the oracle, same harness shape as
  `t/test/15_async_orchestration.t`) on all three axes — callback signature +
  argument passthrough, single- and multi-value returned-Future adoption, the exact
  portable `ctx->select_async` pattern, and rollback parity for a returned failed
  Future. RED before the fix, GREEN after.

## Relationship to other ADRs

- **ADR 0030** — established the `immediate` mode and the storage-level three-way
  dispatch this refines.
- **ADR 0053** — fixed the `immediate` read-result form and audited, reproduced and
  deferred this `txn_do_async` callback-contract gap to karr k207; this ADR closes it.

## Addendum 2026-09-27 — COMMIT only a transaction whose every statement succeeded (karr k236)

The Decision above settles how the coderef's *result* decides between `COMMIT` and
`ROLLBACK`. That result was the only input. This addendum adds the statements the
transaction ran, and it changes the decision on every backend, `immediate`
included. It is an addendum rather than a new ADR because it refines this ADR's
commit-on-success rule.

### Context

PostgreSQL does not answer a `COMMIT` in an aborted transaction with an error. It
ends the transaction and answers with the command tag `ROLLBACK`: nothing is
committed, and on the client side nothing fails. Since dbio-postgresql-ev k48 a
coderef can issue `$ctx->*_async` statements without chaining them. A statement
that failed where nothing waited for it left the transaction aborted on the
server, and `_txn_terminal_chain` (`lib/DBIO/Storage/Async.pm`) still sent
`COMMIT` on the coderef's success. `txn_do_async` then resolved as if it had
committed. That is silent data loss.

The same decision had three more gaps:

- A coderef that caught a failed statement and returned normally committed. On
  PostgreSQL that `COMMIT` rolls back silently. On MySQL, which undoes only the
  failed statement, it commits a partial transaction. An InnoDB deadlock rolls
  back the whole transaction, and the statements after it run outside it.
- `COMMIT` went out while a statement nobody awaited was still in flight. On the
  `future_io` transport the handle is busy at that point, so `COMMIT` fails with no
  `ROLLBACK`.
- In `immediate` mode the context is the storage (Decision above). A failed
  `*_async` there was a failed Future the coderef could drop, and the enclosing
  sync `txn_do` committed.

### Decision

**(a) The context tracks its statements, and a failed statement fails the
transaction.** This half is transport-independent.

- `_track_statement` in `lib/DBIO/Storage/Async/TransactionContext.pm` keeps the
  Future of every statement the context hands out: `_query_async`, the five
  `*_async` CRUD methods, and `pipeline`. It holds them strongly, so a Future the
  caller dropped still reports how it ended. A context-bound
  `ResultSet`/`Row` (ADR 0045) routes through those methods and is covered by
  them. `_txn_statements` returns the kept Futures in issue order, and
  `_invalidate` drops them.
- Before `COMMIT`, `_txn_statements_settled` in `DBIO::Storage::Async` waits until
  every tracked Future has settled, including any handed out during the wait. It
  runs one class-level `needs_all` per round, over Futures that cannot fail
  (`catch`-wrapped). So it uses only methods of the `DBIO::Future` contract, and a
  long run of statements that have already settled costs no recursion.
- `_txn_commit_if_clean` decides. If a statement failed, it sends `ROLLBACK` and
  fails the transaction with the error of the first failed statement **in issue
  order**. On PostgreSQL that is the statement that aborted the transaction; the
  "current transaction is aborted" errors after it are consequences. A failed
  `ROLLBACK` replaces that error, the same precedence as for a failed callback.
- **Pinned semantics: a handled failure still fails the transaction.** This
  applies when the coderef catches a failed statement's Future and returns
  normally. PostgreSQL has aborted the transaction at that point anyway. The async
  layer has no savepoint (see `TransactionContext::txn_do_async`) that would give
  "carry on after a failed statement" a meaning. So the rule is the same on every
  engine: a statement the transaction ran either succeeded, or the transaction did
  not commit.
- **A cancelled statement Future counts as failed.** Future.pm's `wait_any`
  cancels a statement that lost a race against a timeout, and its outcome is then
  unknown. A cancelled Future runs no `then`/`catch` callback, so a wait built on
  those alone would never end and would hold the pool connection. It is detected
  through `can('is_cancelled')` / `can('on_cancel')`, because the `DBIO::Future`
  contract has no cancel. The transaction fails with a `DBIO::Exception` saying
  `COMMIT` was not sent.
- A synchronous throw from a context method is not tracked. No Future was handed
  out, and the caller already holds the error.
- Only the `COMMIT` path waits. The `ROLLBACK` path (the coderef died, or its
  Future failed) is unchanged. The karr k232 state, a connection a pipeline left
  unusable, is checked before and after the wait, and it keeps its own refusal.
- **`immediate` keeps its parity (Decision above).** While `_run_immediate_txn`
  (`lib/DBIO/Storage.pm`) runs, `_run_async` notes each failed `*_async` in
  `_immediate_txn_failures`. After the coderef returns, the first noted failure is
  rethrown, so the sync `txn_do` rolls back. A failed returned Future throws its
  own error first, as on a real backend.

**(b) A transport seam for a `COMMIT` that rolled back.** A new method on
`DBIO::Storage::Async`:

    _txn_commit_rolled_back($conn, @commit_result)   # default 0

It is asked from the successful `COMMIT` Future's callback, before anything else
runs on `$conn`. If it answers true, the transaction fails with a
`DBIO::Exception`, no `ROLLBACK` follows (the server has already ended the
transaction), and the connection is released as usual.

The seam exists because (a) cannot see a statement the context never handed out:

- one sent on `$ctx->txn_conn` directly;
- a statement inside a pipeline batch whose batch coderef dropped its failure. The
  context tracks only the pipeline's own Future.

Both PostgreSQL transports can fill it. What they document:

- **EV::Pg 0.07** delivers `""` for a `COMMIT` (the `PQcmdTuples` string), so the
  tag is not in the result. `$pg->result_meta->{cmd_status}` has it: the docs say it
  is "refreshed by every successful result (including commands with no columns)".
- **DBD::Pg 3.20** resolves the `future_io` adapter's `COMMIT` with `pg_result`'s
  row count. The statement attribute `pg_cmd_status` is documented as "the type of
  the last command". The XS imports `PQcmdStatus`, and the adapter keeps the
  `COMMIT`'s handle in `$conn->{sth}` until its next submit.

Neither was confirmed against a live server here. Each driver confirms its own
before relying on it. MySQL's `COMMIT` fails when it cannot commit, so the seam
keeps its default there.

### Consequences

- Behaviour changes on every backend. A caught-and-recovered statement failure no
  longer commits. A dropped failed statement fails the transaction. `COMMIT` waits
  for statements still in flight. A cancelled statement fails the transaction.
- No ADR 0024 contract-version bump. `DBIO::Storage::Async` and its contexts are
  not among the five versioned base classes. The new seam is additive with a
  neutral default, and the tracking is inherited by every context that subclasses
  the core one, as both known ones do (dbio-async's `DBIO::Async::TransactionContext`,
  `DBIO::PostgreSQL::EV::TransactionContext`).
- A backend's own context class that does not subclass the core one answers no
  `_txn_statements` (asked through `can()`), and its transactions go without (a).
- Remaining limits, documented on the methods:
  - statements the context did not hand out are covered only by (b);
  - the `ROLLBACK` path does not wait for statements still in flight.
- `t/test/42_async_txn_failed_statement.t` pins all of it on a fake wire with
  PostgreSQL's transaction semantics and a real size-1 `PoolBase`:
  - unawaited, in-flight, handled, pipeline and bound-resultset failures;
  - the success guard;
  - (b) with a transport that reads the tag;
  - cancellation over real Future.pm;
  - `immediate` parity.

  It had 31 of 58 assertions red before the fix, and without the cancel handling
  its in-flight cancel case hangs.

### Future architecture work (tracked cross-repo, not here)

- dbio-postgresql: fill `_txn_commit_rolled_back` in the `future_io` adapter
  (`DBIO::PostgreSQL::Storage::Async`) from `pg_cmd_status`, confirmed live.
- dbio-postgresql-ev: fill it from `result_meta->{cmd_status}`, confirmed live.
  Also correct the `DBIO::PostgreSQL::EV::TransactionContext` POD, which still
  tells users that an unobserved failure makes `COMMIT` roll back without an
  error.

Tickets for both are for the coordinator to file (karr core k236 notes).

## Addendum 2026-09-27 — a failed ROLLBACK is added to the error, and the context ends when COMMIT or ROLLBACK goes out (karr k237)

Two corrections to how a real backend's transaction ends, both found in a
dbio-postgresql-ev run against a real server. The first changes a precedence
this ADR restated in its k236 addendum ("A failed `ROLLBACK` replaces that
error"), and ADR 0045 §7 before it; that sentence no longer holds.

### Context

- **A failed `ROLLBACK` replaced the error it was cleaning up after.** A killed
  backend fails the transaction's statement with *connection lost*; the
  `ROLLBACK` sent after it fails with *not connected*. The caller saw *not
  connected* only: the consequence, never the cause. The rule came from karr
  k194 (ADR 0045 §7), which recorded the precedence as *unchanged*, i.e. kept
  the behaviour it found; no reason for it was ever given. It contradicts the
  synchronous contract of the same operation: `txn_do`
  (`DBIO::Storage::BlockRunner`, and `DBIO::Storage::TxnScopeGuard`) reports
  this case as `Transaction aborted: <error>. Rollback failed: <rollback
  error>`, and `txn_do`'s POD in `lib/DBIO/Storage.pm` tells callers to match
  `/Rollback failed/`. It also broke this ADR's parity: the `immediate` mode
  runs `txn_do` underneath, so it already reported that text, and a real
  backend reported something else.
- **The context stayed active until the connection was released**, that is,
  until `COMMIT` or `ROLLBACK` had been answered. A statement issued on it in
  between -- from a `then` callback of a statement still in flight when the
  coderef died, say -- went out after the transaction's end, outside it.
  dbio-postgresql-ev k48 guarded its own wire against this by recognising the
  literal SQL strings `COMMIT` and `ROLLBACK` in its pinned queue.

### Decision

- **A failed `ROLLBACK` is added to the error, not put in its place.** On every
  path that sends `ROLLBACK` -- the coderef died, its Future failed, or one of
  its statements failed -- a `ROLLBACK` whose Future fails, or whose dispatch
  throws, fails the transaction with a `DBIO::Exception` reading
  `Transaction aborted: <error>. Rollback failed: <rollback error>`: the text
  `txn_do` uses, the original error first. One helper sends every such
  `ROLLBACK`, `_txn_rollback_and_fail` in `lib/DBIO/Storage/Async.pm`. A
  `ROLLBACK` that succeeds leaves the error as it was.
  - The channel is the error the caller already handles, not a warning or a
    hook: a caller that must know the `ROLLBACK` failed (the session may still
    hold the transaction open) finds it where it looks, with the same match in
    every mode.
  - It is a string inside a new exception, as in `txn_do`, so a typed original
    exception is reported by its text. The synchronous path makes the same
    trade; keeping two different shapes for one operation is what this
    corrects.
- **The context ends as `COMMIT` or `ROLLBACK` goes out.** The transaction
  scaffold invalidates it (`_txn_context_ends`) immediately before it
  dispatches either, so `_assert_context_active` refuses every statement from
  then on, before it reaches the transport. The finalizer's invalidation before
  the release stays; it is a no-op by then. `BEGIN` failures and the karr k232
  path (a connection a pipeline left unusable, whose best-effort `ROLLBACK`
  goes out in the finalizer) are unchanged: nothing is sent, or the context is
  already invalidated when it is.

### Consequences

- Behaviour changes on every real backend: the error of a transaction whose
  `ROLLBACK` failed now carries both errors. `immediate` does not change; it
  already reported this.
- A statement issued on a context between the send and the answer of its
  `COMMIT`/`ROLLBACK` now throws `transaction context is no longer active`,
  where before it reached the transport. A transport no longer needs to
  recognise those statements to refuse what follows them. A statement sent on
  `txn_conn` directly, past the context, is still the transport's concern.
- No ADR 0024 contract-version bump: `DBIO::Storage::Async` and its contexts
  are not among the five versioned base classes, and no seam changes.
- `t/test/43_async_txn_end.t` pins both halves (21 of 50 assertions red before
  the change): the killed-backend case with an unawaited and a returned
  statement, the coderef's die and failed Future with a failing and a throwing
  `ROLLBACK`, a succeeding `ROLLBACK` as control, `immediate` parity, and a
  statement refused while `ROLLBACK` and while `COMMIT` is on the wire.
  `t/test/15_async_orchestration.t` asserted the old precedence in three
  places (the error-precedence table, the seam-throw table, the release-throw
  table); those claims are replaced by the new one, openly.

### Future architecture work (tracked cross-repo, not here)

- dbio-postgresql-ev: in `t/43-txn-inflight-mock.t` block 5, "after ROLLBACK"
  asserts that the late statement's Future fails naming `ROLLBACK`. Core now
  refuses that statement synchronously, so `$late` is never assigned, and the
  chain fails with `no longer active` instead. The claim that nothing reaches
  the wire still holds. Whether its `ending` marker in the pinned queue is
  still needed is that repo's call.
- Drivers whose tests match the raw `ROLLBACK` error of a failed transaction
  must match the combined text.

Tickets are for the coordinator to file (karr core k237 notes).

## Addendum 2026-10-04 — the real backend's guard is `blessed` too (karr k228)

The Decision calls `immediate`'s `blessed(...)` guard one notch stricter than
the real backend's `ref($inner) && $inner->can('then')`. That difference is
gone: since karr k228 `_txn_terminal_chain` in `lib/DBIO/Storage/Async.pm`
tests `blessed($inner) && $inner->can('then')` as well. With `ref`, a coderef
that returned an unblessed reference -- the hashref `$ctx->insert` resolves,
say -- died in `->can`, and that die sent neither `COMMIT` nor `ROLLBACK`.
What `_run_immediate_txn` still asks beyond it is `can('get')`, which it needs
to take the value out of the returned Future.

## Addendum 2026-10-08 — a statement's Future is kept until its answer, not until the context ends (karr k292)

The k236 addendum made the transaction context keep the Future of every
statement it hands out, "held strongly, so a Future nobody else keeps still
reports how it ended". The k237 addendum then ended the context as `COMMIT` or
`ROLLBACK` goes out. Together they let go of a Future too early: `_invalidate`
dropped the list as the context ended, and `ROLLBACK` waits for nothing, so a
statement still in flight lost its one holder before it was answered. Found in
dbio-mysql (karr dbio-mysql k69, `t/71-future-io-txn-offline.t` case 4).

### Context

- Under Future.pm a statement's Future is a `->then` sequence, which the
  Future it was made off holds only weakly. Dropped by the context it was
  freed, and Future.pm warned `lost a sequence Future` when the answer came,
  once per statement.
- It was not only a warning. A pipeline run on the transaction is tracked like
  a statement, and its Future is the sequence that leaves pipeline mode once
  the sync is answered. Dropped, it never ran: `_pipeline_exit` was not called.
- The roads a context ends on with something in flight, each executed: the
  coderef dies; it returns a failed Future, or one that fails later; the
  connection was left unusable (k232), where the context ends in the finalizer
  with nothing waited for, whether the coderef died or returned. A
  `disconnect` in between does not end the context; it then ends on one of
  those roads. The `COMMIT` road is not among them: `COMMIT` goes out only
  once every statement has settled (k236), so nothing is in flight there.

### Decision

- **The holding ends with the statement's answer.** As a context ends,
  `_invalidate` still empties its list -- `_txn_statements` stays "empty once
  the transaction has ended", and nothing waits on those statements any more
  -- and hands each Future to itself through its own `retain`, asked through
  `can()` as `txn_do_async` asks for its own Future. Future.pm's `retain`
  keeps a Future until it is ready -- done, failed or cancelled -- and lets go
  of it then.
- One place, `_invalidate`, because every road above goes through it. The
  context classes of dbio-async and the EV drivers inherit it.
- `DBIO::Test::Future` holds a chain from its head and has no `retain`;
  `DBIO::Future::Immediate` is settled from the start. Neither needs anything,
  and neither is asked for more than `can('retain')`.

### Consequences

- No warning on those roads, and a pipeline on a transaction whose coderef
  died leaves pipeline mode when its sync is answered.
- A statement that is never answered keeps its Future, and what that Future
  holds, for good. That is the transport's to prevent: a connection it closes
  fails what is in flight on it (dbio-async ADR 0007).
- The outcome of a statement answered after its transaction ended goes to
  nobody: the transaction has failed with the error that ended it.
- No ADR 0024 contract-version bump, and no seam changes.
- Pinned by `t/test/50_async_txn_statement_held.t` against Future.pm (20 of
  192 assertions red before the change) and DBIO::Test::Future (green before
  and after): each road above, a context subclass, the `COMMIT` road as
  control, the pipeline, a cancelled statement, and that the Future is there
  until its answer and gone after it with the context still in hand.

Not covered:

  - A statement the caller drops where no transaction context tracks it: one
    issued on a `PipelineContext` and dropped by the batch coderef, or a pooled
    `insert_async` called in void context. Future.pm warns `lost a sequence
    Future` there too (measured against a fake wire) -- for `insert_async`
    about the sequence `_run_crud` derives, also where the transport holds
    the Future it handed out -- and for the pooled call `Calling ->then in
    void context` before it. Neither context nor storage ever claimed to hold
    those.

## Addendum 2026-10-08 — the storage is also the context `with_context` takes (karr k282)

The Decision makes the storage the context an `immediate` `txn_do_async` hands
its coderef, and says the portable pattern "uses only `*_async` /
`txn_do_async`, all present on `$self`". ADR 0045 added a third use of the
context since: `$rs->with_context($ctx)`. That one was not present. The storage
carries no ownership token, so `with_context` refused it (`async context
ownership cannot be proven`), the coderef died and the transaction rolled back
— the portable ResultSet pattern of `DBIO::Manual::AsyncStorage` did not run
in the one mode every mock test uses. Nothing decided that; it fell between
the two ADRs.

### Decision

- **`with_context` takes the storage as the context of its own objects, in the
  `immediate` mode.** The proof ADR 0045 §4 asks for is a token because a real
  backend's context is a separate object that outlives pool generations. Here
  the context *is* the storage asked, so the proof is identity:
  `_assert_async_context_owner` (`lib/DBIO/Storage/DBI.pm`) accepts `$ctx` when
  it is the very storage and its mode is literally `immediate`. Everything else
  goes to the token comparison unchanged — another storage, a storage with no
  async mode, the storage of a real backend (whose context is the
  `TransactionContext`), a context of another backend.
- **A bound object goes the way a bound object goes on a real backend.** The
  dispatchers hand the context to the op's builder closure (ADR 0045 §2), and
  the storage's `*_async` run the statement in-process, inside the open
  transaction. Two things follow without further code:
  - a failed statement is noted in `_immediate_txn_failures` like the
    context's own (k236 addendum), so it rolls the transaction back, awaited
    or not;
  - what is not one statement is refused (ADR 0045 §6), although the
    synchronous fallback would run *inside* the transaction here. Letting it
    through was the alternative; it was not taken, because a coderef that
    works in this mode and throws on a real backend is the defect this ADR
    exists to remove. The refusal gives the reason that holds in this mode.
- **The surface a bound object asks for is completed, not wrapped.** Beyond
  the six `*_async`, a bound object asks its context two things, and the
  storage now answers both (`lib/DBIO/Storage/DBI.pm`, private):
  - `_query_async` — the raw-SQL seam `results_exist_async` uses. With a
    backend it is the backend's; in the `immediate` mode `_run_immediate` runs
    the rendered statement and resolves its rows.
  - `_context_active` — true while an `immediate` `txn_do_async` runs on the
    storage, which it already knows: `_immediate_txn_failures` is set for
    exactly that span. A bound object used outside of it is refused (`no
    longer active`) by the dispatchers' existing check, as one held past a
    real backend's transaction is.

No context wrapper, no new class and no public method: the wrapper this ADR
rejected stays rejected.

### What is still particular to the mode

The Decision calls an `in_txn` guard meaningless "where there is a single
in-process transaction and no pool". `_context_active` is not that guard put
back: it guards *bound objects*, which ADR 0045 §5 promises a refusal, and it
answers from what the storage knows anyway. It cannot tell one transaction
from the next, and that is left as it is:

- **Bound in one transaction, used inside a later one: accepted.** The context
  of every `immediate` transaction on a storage is that one storage, so the
  object is bound to the later one's context as well, and the statement runs
  in the later transaction — the only place it can run. A real backend, with
  one context object per transaction, refuses. Telling the two apart would
  need a per-transaction context object, which is the wrapper again.
- **The storage's own `*_async` are not guarded.** `$ctx->insert_async` called
  after the transaction runs outside it, as before (measured).
- **An unbound `*_async` inside the coderef** runs inside the transaction too,
  and its failure is still not the transaction's: dropped by the coderef, it
  does not roll back (measured: `BEGIN`, `COMMIT`). On a real backend such a
  statement is not in the transaction at all. Only binding makes a statement
  the transaction's, in every mode.
- **No `pipeline`.** It is a method of `DBIO::Storage::Async`; the mode has no
  backend, so there is no pipeline coderef and no pipeline context.

### Consequences

- The portable pattern `sub { my ($ctx) = @_; $rs->with_context($ctx)->… }`
  runs in every async mode. Nobody can depend on the refusal it replaces: it
  rolled the transaction back.
- No ADR 0024 contract-version bump: `DBIO::Storage::DBI` is not among the
  five versioned classes, and the two methods are private.
- `t/resultset/with_context_immediate.t` pins it against the fake storage and,
  coderef for coderef, against a real synchronous backend (38 of 78 assertions
  red before the change). The first particular above is held there as an
  assertion marked IST.

## Addendum 2026-10-09 — a cancelled `txn_do_async`, `pipeline` or `deploy_async` retires its connection (karr k274)

The Decision and the earlier addenda end a transaction in the finalizer: a
`->then` on the terminal chain that invalidates the context and hands the
connection back once. Future.pm runs no `->then` callback of a Future that is
cancelled, and cancelling the Future a caller was given -- or losing it in a
`wait_any` against a timeout -- is the only way a caller has to stop waiting.
So a cancel while the operation held its connection left everything open: no
`ROLLBACK`, no `PIPELINE_EXIT`, neither release nor retirement, the context
live, and a pool of one waiting for good. The same held for the Future the
coderef returned, cancelled by itself (dbio-postgresql-ev k70), and for the
release of a DDL run in `deploy_async`.

### Decision (maintainer, 2026-10-09)

- **A cancel retires the connection.** `ROLLBACK` is sent best-effort and not
  waited for, the context is invalidated, and the connection goes to the
  pool's `_retire_in_use_connection` -- never back into the pool. Each cancel
  costs one reconnect. Chosen over "wait for `ROLLBACK`, then release" because
  a cancelled Future never reports when the wire answered what it had in
  flight, so a connection released behind a slow statement may be lent while it
  is still busy; and over a Future of its own for the caller (as the pool's
  acquire has, k258) because that would hold the pool slot until the slow
  statement answered -- in exactly the case in which the caller gave up by
  timeout. A later move to "release when the wire is provably idle" would not
  be visible to a caller.
- **The cancel still reaches what is in flight.** Future.pm carries it down the
  chain; nothing is shielded.
- **Exactly once.** The transaction's record of its connection
  (`_txn_guard` on the context, `done` once handed back) is asked by the
  finalizer, by the cancel, and by the `ROLLBACK` paths; a pipeline and a DDL
  run keep a flag of their own. However many paths notice the cancel, the
  connection is retired and `ROLLBACK` sent once, and a cancel after the
  operation ended hands nothing back again.
- **No `ROLLBACK` where nothing is open or nothing can answer.** Not when
  `COMMIT` or `ROLLBACK` is out already (the context has ended), not in a
  pipeline or for DDL outside a transaction, and not onto a connection the
  pool has been told is dead (dbio-async k47, `_connection_is_dead`): a
  transaction that fails there fails with the error that ended it, not with
  `Rollback failed: not sent`, and the release retires the connection.
- **The coderef's own Future cancelled by itself** ends the transaction the
  same way and fails it (`Transaction cancelled: ...`) instead of leaving it
  pending.
- **A cancel while `COMMIT` is pending leaves the outcome unknown.** The
  transaction may have committed. The connection is retired either way; no
  `ROLLBACK` follows the `COMMIT`. It is documented in `txn_do_async`.

### Consequences

- A statement Future of the context cancelled *alone* (k236: the coderef goes
  on) is unchanged: `ROLLBACK` awaited, connection released.
- A pipeline run on a transaction that is cancelled marks the transaction's
  connection unusable (its `$retire`), as a failed exit does (k232).
- No ADR 0024 contract-version bump: the changed methods are private, and
  `_set_txn_guard` / `_txn_guard` on `TransactionContext` are optional seams a
  context class of a backend's own may omit (the cancel path then keeps only
  the record the finalizer holds).
- `t/test/47_async_cancel_outer_future.t` holds every entry point and cancel
  point against a real `Future` and a real `DBIO::Storage::PoolBase` of size 1
  (44 assertions red before the change).

## Addendum 2026-10-09 — a driver may refuse the Future the coderef returned: `_txn_inner_future` (karr k334)

Async-Verträge. A seam, so a driver can refuse a Future this ADR's adoption rule
takes at face value. The decision is the maintainer's (dbio-postgresql-ev k87,
option (a)).

### Context

- `txn_do_async` adopts the Future its coderef returns and chains `COMMIT` on
  it. A coderef that returns the Future of a call on the **storage**
  (`$storage->select_async(...)`) instead of one on the context hands it a
  Future that is not part of the transaction. On a pool of size 1 that call is
  queued for the one connection, the one the transaction holds: the
  transaction waits on a Future that waits on the transaction. Nothing blocks,
  so no deadlock check sees it; the top level dies with "nothing left", the
  transaction stays open and the pool is stuck.
- Only the driver knows its own queued waiter. dbio-postgresql-ev already has
  the operation that refuses it (`_refuse_queued`: take the waiter out of the
  pool queue, fail it); the core had no place to call it from.

### Decision

- **`_txn_inner_future($txn_ctx, $conn, $inner_future)`** on
  `DBIO::Storage::Async`, a driver seam. Asked once the coderef has returned
  and its Future is known, before `COMMIT` is chained on it; answers the Future
  the transaction adopts instead. Core default: `$inner_future` unchanged.
- **Refusal rides the existing failure path.** A seam that fails the inner
  Future (and returns it, or another failed Future) gets `ROLLBACK`, the
  transaction fails with exactly that failure, and the connection goes back to
  the pool. A seam that throws is treated as the coderef dying
  (`_txn_rollback_and_fail`; fail without `ROLLBACK` on an unusable
  connection). A return that is not a Future is ignored; `$inner_future` stays.
- **Not asked** when the coderef died or the connection is already unusable;
  those paths are unchanged.

### Consequences

- No behaviour change in core; a driver that does not fill the seam behaves as
  before.
- A driver that fills it must not settle the transaction itself: it refuses the
  Future and leaves `ROLLBACK`, the error and the release to the scaffold.
- No ADR 0024 contract-version bump: `DBIO::Storage::Async` is not one of the
  five versioned base classes.
- `t/test/44_async_txn_inner_future_seam.t` pins it on a pool of size 1: the
  default changes nothing; a refusing seam gives `ROLLBACK`, the refusal as the
  transaction's error, the connection back in the pool and no `COMMIT`; a
  throwing seam is a coderef die; the seam is not asked after a coderef die.

### Future architecture work (tracked cross-repo, not here)

- dbio-postgresql-ev k87: fill the seam with `_refuse_queued`.
