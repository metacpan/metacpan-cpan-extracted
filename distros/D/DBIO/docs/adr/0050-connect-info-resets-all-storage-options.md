# ADR 0050 — connect_info() is a full reconfiguration: unnamed storage options reset to default

- Status: accepted
- Date: 2026-09-13
- Tags: storage, connect_info, divergence, public-api

## Context

`connect_info()` on `DBIO::Storage::DBI` (`lib/DBIO/Storage/DBI.pm`) sets up the
connection configuration: the DSN/credentials, the DBI attributes, the SQL-maker
options, and the *storage options* — the behavioural flags and connection-action
callbacks the storage reads for itself and never hands to `DBI->connect`:
`on_connect_do`, `on_disconnect_do`, `on_connect_call`, `on_disconnect_call`,
`disable_sth_caching`, `unsafe`, `auto_savepoint` (the list a driver can extend via
`_dbio_storage_option_names`), plus `cursor_class`.

Inherited verbatim from DBIx::Class, `connect_info()` treated these two families of
options **asymmetrically** on a repeated call:

- SQL-maker options were wiped and rebuilt every call (`_sql_maker(undef)` +
  `_sql_maker_opts({})`, then repopulate from the new info).
- Storage options were only ever *set when present*. A second `connect_info()` that
  omitted a previously-set option left the old value active. Call once with
  `on_connect_do => [...]`, call again with just a DSN, and the old `on_connect_do`
  still fired on the next connect.

This was never a designed "we preserve options" feature — it is a fossil. The story,
from the DBIx::Class history this repo carries:

- **2006, `b33697ef`** (evolving `1b45b01e`): storage options were extracted with the
  idiom `if (my $value = delete $attrs{$opt}) { $self->$opt($value) }` — a *picker* of
  named options out of the attribute hash, never a state reconciler. The `delete`
  strips the key from the hash bound for `DBI->connect`; it does not clear the accessor.
  A truthiness idiom cannot even express "reset to absent". No version in the history
  ever cleared an absent storage option.
- **2006/2008, `2cc3a7be` then `92fe2181`** ("Massive cleanup of connect_info"): the
  SQL-maker got the explicit `_sql_maker(undef); _sql_maker_opts({})` wipe, because it
  is a *derived, cached, compiled* object — a stale dialect or quote-char produces wrong
  SQL (real bugs: S::A::L `$dbh` caching, lost sql_maker settings on fork). The cleanup
  added that wipe directly next to the unchanged storage-option picker, cementing the
  asymmetry without ever deciding it.
- **2014, `b6a469f7` / `26aea721`**: a *reconnect*-path sqlmaker reset was added then
  backed out ("S::L tests rely on preserving the sqlmaker between reconnections"),
  leaving the standing `# FIXME - this needs reenabling with the proper "no reset on
  same DSN" check` in `_populate_dbh`. That FIXME is about the reconnect path, not this
  one, but it is the same unfinished "connect_info consolidation" the project flagged
  and never completed.

The stale storage option was documented *away*: old DBIO POD claimed `connect_info`
"clears everything", which the code never did (surfaced by the doc audit, karr k187;
docs aligned to the actual code in k186). k187 posed the choice: fix the doc to match the
fossil, or fix the code to match the always-intended contract. The maintainer chose the
contract.

## Decision

**A fresh `connect_info()` call is a full reconfiguration of the storage, not a merge.**
Every storage option not named in *this* call reverts to its default before the call's
options are applied:

- The flag/callback options (`_dbio_storage_option_names`, including any a driver added)
  reset to `undef` — their natural unset state.
- `cursor_class` resets to its **class default** (`DBIO::Storage::DBI::Cursor`), never
  `undef`, because it is a `component_class` accessor with a meaningful default and
  cursor creation depends on it.

This makes storage options symmetric with the SQL-maker options, which the 2008 cleanup
already wiped-and-rebuilt every call. The reset happens on every `connect_info()` entry,
including a bare-DSN call with no attribute hash (the exact k187 scenario), and covers
both the normal and the access-broker branch (it runs on the common path after the
branch, before the per-option apply loop).

This is a **deliberate divergence from DBIx::Class** and a **public-behaviour change**,
called out explicitly in the `connect_info` POD with a short version of the story above.

## Consequences

- Reconfiguring a storage by calling `connect_info()` a second time no longer leaks a
  previously-set `on_connect_do` (or any other storage option). The value set on the
  first call is gone unless the second call restates it.
- Code that *relied* on the fossil — setting `on_connect_do` once via `connect_info` and
  then re-calling `connect_info` with only a DSN, expecting the callback to survive —
  must now pass the callback on every `connect_info` call, or set it via its accessor
  after the reconfiguration. This is the intended, documented break.
- The reconnect path (`_populate_dbh` → `_connect`) is unaffected: it does not route
  through `connect_info`, so a plain reconnect still preserves the configured options.
  The standing `_populate_dbh` sqlmaker FIXME is a separate matter and is left as-is.
- `DBIO::Storage::Async::connect_info` already replaces its stored `_conninfo`/`_opts`
  wholesale on every call, so it never had this fossil; the sync path now matches that
  full-replace spirit. (On every call that completes — for a call that throws, see the
  addenda of 2026-10-04 and 2026-10-08.)
- `DBIO::Replicated::Storage::connect_info` keeps its own, deliberate merge semantics for
  `pool_args`/`balancer_args` and is explicitly out of scope for this ADR, which governs
  `DBIO::Storage::DBI::connect_info` only.
- A regression test pins the new contract: a second `connect_info()` without an option
  clears it, a driver-extended storage option is cleared too, and `cursor_class` reverts
  to its class default rather than `undef`.

## Addendum 2026-10-04 — an async `connect_info` that throws with a broker (karr k265)

"Replaces wholesale on every call" holds for a `DBIO::Storage::Async::connect_info`
call that completes. Given a broker, the call attaches it and then reads its answer,
and reading it can throw — the broker itself, an answer of nothing or of no usable
shape, two pool sizes that disagree. Since karr k265 the stored `_conninfo` is dropped
**before** the answer is read, so the conninfo of the `connect_info` before — password
included — is gone also when the call throws, and a connection opened after the broker
is detached is not opened from it (`t/access_broker/21-async-broker-attach-failure.t`).

`_pool_size` and `_opts` are replaced only once the answer is in: after a throwing
call they still hold the values of the call before, beside the newly attached broker,
until a `connect_info` that completes replaces them.

> Superseded on this point by the addendum of 2026-10-08: nothing of the call before
> outlives a call that throws.

## Addendum 2026-10-08 — a `connect_info` that throws leaves nothing of the one before, and a broker comes and goes in one place (karr k273, k283, k293)

The addendum of 2026-10-04 recorded what a throwing async `connect_info` left behind.
That was one face of a wider state of things. What a `connect_info` leaves on an async
storage is spread over several slots — the broker and its mode, the per-spawn provider,
the stored conninfo, the pool size, the options, the connect options given beside a
broker — plus, for a backend embedded in a sync storage, that storage's own broker. They
did not change together, and every road that changed one left others standing.

### What was found, each case executed

- **A `connect_info` that threw** once the new broker was attached left the pool size,
  the options and the beside-options of the call before next to it (k283). One that threw
  *before* it reached a broker — the driver's `_normalize_conninfo`, options a transport
  does not take, static connect info of no usable shape — left the call before in place
  as a whole, and the next pool connection was opened from it.
- **`set_access_broker` called directly** set the broker slot only: no provider, and the
  static conninfo still stored, from which a transport went on building its pool.
- **`clear_access_broker`** left the provider, which then handed a transport that did not
  refuse by itself no conninfo at all (k273 point 2), and left the pool size, options and
  beside-options of the broker's connect info.
- **`clear_access_broker` on the sync storage** did not reach its embedded backend, which
  went on asking the broker for pool and listen connections; a backend built only
  afterwards attached the detached broker again (k293). A sync `connect_info` that threw
  left the backend of the connect info before in place, asking the broker it replaced.
- **On a driver storage class that does not declare the c3 method resolution order** —
  `DBIO::PostgreSQL::Storage` and `DBIO::MySQL::Storage` — the sync detach of karr k266
  never ran. `DBIO::Storage::DBI::AccessBroker` stands behind `DBIO::Storage` there (the
  first base, `QueryRewrite`, inherits it), so the bare
  `DBIO::Storage::clear_access_broker` was found first, and the DBI connect info of the
  broker's last answer, password included, stayed stored. `clear_access_broker` was the
  one mixin method shadowed that way.

### Decision

- **`connect_info` forgets first.** `DBIO::Storage::Async::connect_info` drops everything
  the call before left — broker, provider, conninfo, pool size, options, beside-options,
  the connect info as given — before it reads anything of the new one. A call that
  throws early leaves the storage where one never given connect info is. One that throws
  with the new broker attached leaves that broker attached in full, including what stood
  beside it in this call, which is stored before the answer is read.
- **`set_access_broker` is where an async storage gets a broker**, and
  `_setup_access_broker` is the same call. Attaching forgets what the connect info before
  left and installs the provider. A transport that overrides `connect_info` inherits the
  forgetting through `_setup_access_broker` and `_clear_access_broker`, provided it calls
  them before it reads.
- **`clear_access_broker` is where it loses it**, under either name. What came with the
  broker goes with it. The provider stays and refuses: `<class> has no AccessBroker
  attached to ask for connect info`, as a failed Future from `acquire`, on the storage
  and in a pool built with it. Core says so itself now; the transports of the family each
  said it in `_async_broker_conninfo`, in these words. `_clear_access_broker` is the
  detach plus the forgetting of everything else, the provider included.
- **The sync storage's detach takes the embedded backend along** — detached as above,
  its open connections left open, as the sync storage keeps its handle; a backend not
  built yet is refused, not built from the detached broker. This follows from k266: the
  sync storage drops the broker's last answer *so that no connection is opened with it*,
  and a backend that goes on asking the same broker opens exactly those. The sync
  `connect_info` lets go of the backend of the call before on the way in.
- **`DBIO::Storage::DBI` names `clear_access_broker` itself** and calls the mixin's, so
  the detach is found first in either resolution order. No `@ISA` is changed.

### Rationale

- **The state is one thing.** A broker beside a static conninfo, or beside the pool size
  of another connect info, describes no connection anybody asked for. Setting and
  clearing it in one place each is what keeps a road from changing half.
- **Forget before reading, not after.** Reading is where everything can throw. What is
  forgotten afterwards is forgotten only on the roads that get there.
- **A detached storage says so.** "No AccessBroker attached" tells the application what
  happened; the transports had already agreed on that, and on its wording.

### Consequences

- An application that detached the broker on a PostgreSQL or MySQL sync storage and went
  on using it was, until now, reconnected with the broker's last answer. It now gets
  `You did not provide any connection_info`, as on every other DBI storage since k266.
- After a detach on the sync storage, `*_async` calls fail until connect info is given
  again; before, they kept working through the detached broker.
- `_access_broker_call_attributes`, `_pool_size` and `_opts` are unset, not empty, on a
  storage that was detached or never configured; the accessor still answers `{}`.
- No ADR 0024 contract-version bump: none of the five versioned classes changes shape.
- Pinned by `t/access_broker/33-async-broker-one-state.t` (90 of 268 assertions red
  before the change) and by `t/access_broker/21-async-broker-attach-failure.t`, whose
  assertion of the old behaviour — a pool connection opened from no conninfo at all
  after a bare `clear_access_broker` — is replaced by the refusal.

Not covered — measured, and left for a decision:

  - **Whether a bare `clear_access_broker` should drop the provider too**, so that the
    two names leave the same state. It was tried: the storage is then where one never
    given connect info is, and a pool built afterwards refuses with `conninfo or
    conninfo_provider required` instead of naming the missing broker. Every pooled
    transport of the family pins the other behaviour for the public name — 10 assertions
    in dbio-async, 48 in dbio-postgresql, 122 in dbio-mysql, 3 in dbio-mysql-ev go red,
    and dbio-postgresql-ev's file aborts — so it was not done.
  - **A pool that is already built when a broker is attached directly.** It keeps what it
    was built with — the static conninfo — until a `disconnect`. `connect_info` shuts the
    pool down first; `set_access_broker` does not.
  - **`set_access_broker` on the sync storage** after its `connect_info`. The sync storage
    asks the new broker from then on; its backend, built or not yet, the one in the
    connect info.
  - **Shutting the backend's pool down at the sync storage's detach.** It is detached,
    not shut down.
  - **`DBIO::Forked::Storage`** keeps the connect info and builds a sync storage from it
    in each child; a detach on the owning storage does not reach that (read, not run).
