# ADR 0003 — Transactions: no-op with a warning, but rollback throws

- Status: accepted
- Date: 2026-07-25

## Context

ClickHouse has no transactions. `BEGIN` / `COMMIT` over the MySQL wire endpoint
(ADR 0001) do not give real atomicity, and there are no savepoints — the
savepoint hooks (`_exec_svp_begin` / `_exec_svp_release` / `_exec_svp_rollback`)
already throw. What was left open is DBIO's *transaction* API:
`txn_do`, `txn_begin`, `txn_commit`, `txn_rollback`.

This is not a corner of the API that a driver can ignore. Core itself reaches
for transactions on ordinary operations: `ResultSet::populate`, `delete_all`,
`update_all`, multi-create in `Row::insert`, and cascading delete all open a
`DBIO::Storage::TxnScopeGuard`, i.e. `txn_begin` + `txn_commit`, with
`txn_rollback` on the unwind. Whatever this driver decides, it decides for the
whole ORM surface, not just for user-written `txn_do` blocks.

Three options were on the table:

- **(a) Always throw.** Honest, but it takes `populate`, multi-create,
  `delete_all` and cascade delete with it: the ORM would be unusable for
  anything but single-row work, and every user would have to route around core
  internals they do not control.
- **(b) No-op passthrough.** The API keeps working and stays silent. It is a
  lying API of exactly the kind ADR 0002 exists to prevent — the caller is told
  a transaction succeeded when there never was one.
- **(c) No-op with a one-time warning.** The API keeps working, but the driver
  says out loud, once, that nothing is atomic.

Within (c) the four entry points are not equivalent. `txn_begin`, `txn_commit`
and `txn_do` only ever *promise* atomicity; a silent no-op costs the caller a
guarantee they never really had. `txn_rollback` is different in kind: it
*claims work was undone*. Accepting it silently leaves the caller believing the
changes are gone while every statement is still in the table — the one place
where a no-op does not merely fail to help but actively manufactures a wrong
belief about the data.

## Decision

**(c), with `txn_rollback` as the exception.**

1. **`txn_begin` / `txn_commit` are no-ops** at the `_exec_txn_begin` /
   `_exec_txn_commit` hooks: nothing is sent to the server, but core's public
   methods and its `transaction_depth` bookkeeping run untouched, so nesting,
   `txn_scope_guard` and "commit without begin" keep behaving the way they do
   on every other driver.
2. **`txn_do` runs its coderef with no `BEGIN`/`COMMIT` bracket**, via a
   `DBIO::Storage::BlockRunner` with `wrap_txn => 0`. Arguments, calling
   context and core's `_in_do_block` handling are preserved. The block is
   **never retried** (`retry_handler => sub { 0 }`): core's retry-on-stale-
   connection is only safe because the transaction guarantees the failed
   attempt left nothing behind — without one, a retry would re-apply whatever
   the first attempt already wrote.
3. **A failing `txn_do` re-throws the original exception unchanged** and carps
   loudly, **every time** (not once), that nothing was rolled back. Because
   nothing is wrapped, there is no rollback that could fail and mask the real
   error — the failure-report path in `BlockRunner` that produces
   `"Transaction aborted: ... Rollback failed: ..."` is never entered.
4. **`txn_rollback` always throws** via `throw_exception`, after unwinding
   `transaction_depth` by one so the storage is never left believing it is
   inside a transaction.
5. **Warn-once granularity is per interpreter**, using core's own `carp_once`
   from `DBIO::Carp` (the house primitive for exactly this) rather than
   hand-rolled per-object state. The limitation is a property of ClickHouse
   itself — not of a connection, a callsite or a moment — so repeating it per
   storage object would be noise about a fact that cannot change. Warning
   texts differ between the `txn_begin`/`txn_commit` pair and `txn_do`, so each
   condition gets its own single warning.

## Consequences

- Ordinary ORM code keeps working. `populate`, multi-create, `delete_all`,
  `update_all` and cascade delete run their guarded blocks unchanged, minus the
  atomicity ClickHouse never had.
- On the guard's error path, `TxnScopeGuard::DESTROY` catches our refusal and
  folds it into the in-flight error, so a `DBIO::Exception` (what core raises)
  arrives as `"Transaction aborted: <original> Rollback failed: ClickHouse has
  no transactions ..."`. That is the intended outcome: the partial write really
  did survive, and the caller is told so. A plain string exception comes back
  untouched, because perl's own die propagation overwrites the guard's `$@`
  rewrite; a guard leaving scope with no error in flight carps twice and does
  not die. In all three shapes the original error is preserved and
  `transaction_depth` returns to 0. **Superseded — see the addendum below.**
- A user calling `$schema->txn_rollback` (or `$guard->rollback`) gets a hard
  error. That is deliberate and is the single behavioural difference from every
  other DBIO driver: on ClickHouse there is no way to make that call true, and
  the only safe answer is to refuse instead of pretending.
- `deferred_rollback` / `NESTED_ROLLBACK_EXCEPTION` never come into play here.
  They exist to defer a *real* rollback to an outer transaction scope; with no
  rollback to defer, arming them would only poison the storage. `txn_rollback`
  therefore does not delegate to core's implementation.
- Applications that need atomicity must get it from ClickHouse's own tools
  (idempotent bulk inserts, `ReplacingMergeTree` de-duplication, staging tables
  swapped in with `EXCHANGE TABLES`), not from this API.
- Not covered here, and left for follow-up tickets: making `txn_scope_guard`
  itself refuse up front (**settled — see the addendum below**), and the
  async-mutation `UPDATE` / `DELETE` path, whose eventual consistency is a
  separate promise this driver cannot keep.

## Addendum (2026-07-26) — `txn_scope_guard` returns a no-op guard

- Status: accepted
- Supersedes: the second Consequences bullet above

### What the follow-up found

The open item was whether `txn_scope_guard` should refuse up front instead of
letting `DESTROY` throw. Before deciding, the guard sites in the installed core
were enumerated and each one driven against a recording ClickHouse storage.
Reachable on this driver:

| Site | Path |
|---|---|
| `ResultSet::update_all`, `ResultSet::delete_all` | one guard, then a mutation per row |
| `Row::insert` (`Row.pm:224` / `:253`) | multi-create — `$rs->create` with related rows |
| `Relationship::CascadeActions::delete` / `::update` | any source with a cascading relationship |
| `ResultSet::populate` in non-void context (>1 row) | per-row `create` under one guard |
| `ResultSet::populate` **with related data**, even in void context | falls back to per-row `create`, which re-enters the guarded non-void path |
| `ResultSet::_rs_update_delete` (`ResultSet.pm:1610`) | complex `$rs->update`/`->delete` needing an ORed PK set — reachable because this storage leaves `_use_multicolumn_in` at 0 |
| `Row::update` (`Row.pm:552`) | a column hook declaring `txn_wrap` |
| `DBIO::Ordered` | if the component is loaded |

Not reachable: `Storage::DBI::_insert_bulk` (this driver overrides it —
`t/13-insert.t` pins that a void `populate` of plain columns raises no
transaction warning), and `ResultSet::upsert`, which throws in
`_upsert_unsupported` before it ever takes its guard because this storage does
not declare `_use_supports_upsert`.

So the scope shrank, but not to nothing, and it is wider than "`delete_all` and
friends": **`populate` is still guarded whenever the data carries related rows**,
which the original write-up had assumed was gone.

Measured behaviour of the status quo on those paths:

- Happy path: guard commits, `transaction_depth` back to 0, nothing else
  happens. Correct already.
- Failure with a `DBIO::Exception` (what core raises): `DESTROY` **mutates the
  exception object in place**, prefixing `"Transaction aborted: "` and appending
  `"Rollback failed: <our refusal>"` — **once per guard on the stack**. A
  `delete_all` inside a caller's own guard nests three deep and produced three
  prefixes and three copies of the refusal paragraph in front of the real cause.
- Failure with a plain string: perl's die propagation overwrites the guard's
  `$@` rewrite, so the original comes back byte-identical.
- Guard leaving scope with no error: carps twice and does not die.

### Decision

**`txn_scope_guard` returns `DBIO::ClickHouse::Storage::TxnScopeGuard`** — core's
guard with `DESTROY` replaced. It unwinds `transaction_depth` by one, `carp`s
that nothing was rolled back, and returns. `new`, `commit` and `rollback` are
inherited unchanged, so `$guard->rollback` still throws.

Rejected alternatives:

- **Refuse up front.** This is option (a) of the original decision wearing a
  different hat, and the enumeration above shows the caller set it breaks is
  essentially the one that got (a) rejected in the first place: `delete_all`,
  `update_all`, multi-create, cascade delete, related-data `populate`. Users
  cannot route around core internals they do not control.
- **Keep the status quo.** Defensible on the happy path, which is already
  correct — but the failure path actively damages the error. The decoration is
  not information here: *every* rollback on this storage fails, always, for the
  same reason, and that reason is already stated by the one-time `txn_begin`
  warning, by `$guard->rollback`, and in the documentation. Paying for a
  restatement of a constant with a mangled exception on every failed bulk
  operation is a bad trade.

### Why this is the same rule, not a new one

The original decision split the API on a single question: does the call
*promise* atomicity, or does it *claim work was undone*? A guard object answers
both, in different places, and each place keeps the answer the split gives it:

| Guard operation | Equivalent | Behaviour |
|---|---|---|
| `txn_scope_guard` (construction) | `txn_begin` | no-op, one-time warning |
| `$guard->commit` | `txn_commit` | no-op |
| `$guard->rollback` | `txn_rollback` | **throws** |
| `DESTROY` without commit | *nobody's statement* | carp, never throws |

`DESTROY` is the only genuinely new case, and it is not a caller's claim at all —
it is core's unwinding machinery firing in a scope the user may not have written.
It promises atomicity; it asserts nothing about what is already on disk. Under
the rule of this ADR, that makes it a no-op.

The result is that a scope guard now behaves exactly like `txn_do`, which is the
same construct with a different spelling: no bracket, run the body, and on
failure carp loudly — **every time, not once, because each unwind is its own
partial write** — while the original exception propagates untouched.

### Consequences

- Guarded operations are no longer atomic in any respect, and no longer pretend
  to unwind. A failure part-way through `delete_all` leaves the already-deleted
  rows deleted. This is not new — it was already true, the guard simply added a
  message on top — and it is true of every mutation on this engine.
- Errors out of `delete_all`, `update_all`, multi-create, cascade delete and
  related-data `populate` are now the errors the engine raised, with no
  `"Transaction aborted:"` prefixes and no rollback paragraph.
- An abnormal unwind is louder in the one way that matters and quieter in every
  other: one `carp` per guard that left scope uncommitted, saying that nothing
  was rolled back.
- `transaction_depth` still returns to 0 on every path, so the storage is never
  left believing it is inside a transaction.
- A caller who wants the old behaviour — a hard error when a guard unwinds —
  writes `$guard->rollback` explicitly, which still throws.
