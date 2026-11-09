# ADR 0009 — AccessBroker credential rotation via a per-spawn conninfo seam

- Status: accepted
- Date: 2026-09-06
- Tags: async, accessbroker, credentials, rotation, pool, drivers
- Amended: `_async_broker_conninfo` reads the broker's answer itself instead of
  handing it to the inherited normalisation, and a broker connect can select
  `ev` (see the Amendment of karr k54); the listen connection is core's and
  takes the broker's current answer every time it opens, so rotation needs no
  teardown of it (see the Amendment of karr k52); a broker's answer and static
  connect info are read by one reader, in the forms the owning sync storage
  reads (see the Amendment of karr k64); the decision itself stands

## Amendment (2026-10-08, karr k64, k66, k79) — one reader, for an answer and for static connect info

The decision stands. What the two earlier amendments say about *how* connect
info is read is replaced by one rule.

- **One reader.** `_pg_read_connect_info` reads connect info wherever it comes
  from: what `connect_info` is given, and what a broker answers, at attach and
  for every connection (`_async_broker_conninfo`). The k54 Amendment has the
  reading of an answer in `_async_broker_conninfo` and leaves static connect
  info to `connect_info`'s own DBI-form fold; the k52 Amendment calls that
  fold all that is PostgreSQL-specific in the override. Two readers disagreed:
  a form refused from a broker was taken as static connect info and failed at
  the first connection, or with a bare Perl error.
- **The measure is the owner.** A schema's dbh and its pool are opened from
  the same connect info (karr k58), so a form the sync storage reads as a
  connection is read as that connection: the DBI form, with DBI attributes in
  front of the DSN and DBI's `Username` / `Password`; the single hash with a
  `dsn` key, or with a `dbname` that is a whole DSN, which is that DBI form;
  the hash of connection parameters, without the keys that are the owner's.
  What the owner connects from and this transport cannot -- a code reference
  -- is refused, naming the form.
- **Two rules depend on the origin.** An answer that renders to the empty
  conninfo is refused (karr k61); static connect info that does is taken
  (open, karr k66). A hash outside an array is a broker's answer only.
- **A call that throws keeps nothing of the call before it** -- conninfo, pool
  size, options -- whichever way it throws.

The list of shapes in the k54 Amendment is therefore the list in
`connect_info`'s POD, for both origins.

## Amendment (2026-09-27, karr k52) — the listen connection is core's and rotates when it opens

The decision stands. Two statements below describe the LISTEN connection as
this driver kept it before karr k43, when `listen` / `unlisten` / `notify`
became core's (core ADR 0056; ADR 0003 carries the amendment). The k54
Amendment already records that the listen connection is opened through
`_async_broker_conninfo`; this one corrects what follows from that.

- *Decision*, "Second, it tears down the **dedicated LISTEN connection** on
  reconnect, which only exists in this driver (ADR 0003)". The dedicated
  listen connection is core's machinery, on every transport that declares
  `listen` -- the `future_io` transport has one too -- and this class fills
  its seams (`_listen_open`, `_listen_close`, ...). `connect_info` does not
  tear it down itself: when a pool or listen state exists it calls the
  inherited `disconnect`, and core's `disconnect` ends listening -- the
  connection is closed, the channel registry dropped, and what waits on it
  fails with "the storage was disconnected". What is PostgreSQL-specific in
  the override is the DBI-form fold alone.
- *Consequences*, "the dedicated LISTEN connection is not pooled, so it does
  not pick up rotated credentials by itself and must be dropped on reconnect
  or it outlives them". Half of it holds. It is not pooled, and an open
  listen connection keeps the credentials it was opened with for as long as
  it lives, like a live pooled connection (the first Consequence). But it
  does pick up rotated credentials by itself whenever it opens: `_listen_open`
  takes its conninfo from `_conninfo_provider`, so the broker is asked anew
  at the first open and at every reopen core makes -- after the server ends
  the session, which core notices, reports through `on_listen_error` and
  heals with backoff, and on `listen_reconnect`. A broker whose revocation
  ends the old sessions therefore gets a listen connection on its new
  credentials without anyone tearing it down, and a caller who wants one
  before that calls `listen_reconnect`. Rotation is not why a reconfigure
  ends listening; the connect info changing -- another broker, another DSN --
  is.

## Amendment (2026-09-27, karr k54) — the broker's answer is read, not split

The decision stands: this driver fills core's `_async_broker_conninfo` seam
with one freshly built libpq conninfo per new connection and adds nothing else
to the rotation mechanism. Two statements below no longer hold.

- *Decision*, "built by routing the broker's current credentials through the
  inherited normalisation". Core's `_normalize_async_connect_info` splits a
  `[ $conninfo, \%opts ]` pair and takes the first element as the conninfo.
  That fits a broker answering a libpq hash (Static), not one answering the DBI
  form `[ 'dbi:Pg:...', $user, $password, \%attrs ]` (Vault): libpq was handed
  the bare DSN string, which it refuses, and the user and password were never
  read -- every pool connection and the listen connection failed, HostBound
  over Vault alike (found in dbio-postgresql k80). `_async_broker_conninfo` now
  asks the broker itself and reads the answer: a DBI-form arrayref goes through
  `dbi_to_conninfo` like DBI-form connect info, a libpq hash or a libpq string
  (alone or with an options hash) passes, and any other answer croaks naming
  its shape, never its values. `connect_info` reads the answer the same way
  when the broker is attached, so a `pool_size` among a Vault broker's
  attributes sizes the pool. The listen connection is opened through the same
  seam, at every reconnect.
- *Consequences*, "A broker connect cannot also request async". A DBI-form
  broker carries the mode among its own attributes -- `dbi_attrs => { async =>
  'ev' }` on a Vault broker reaches this transport through
  `MyApp::Schema->connect($vault)` -- and a core that takes the connect options
  beside the broker (core k240) takes `connect($broker, { async => 'ev' })` for
  any broker. The broker in `t/02-access-broker.t` carries no mode, so its
  schema stays sync, as that file asserts.

## Context

Core ADR 0013 establishes the AccessBroker / CredentialSource seam; core ADR 0014
notes that the async tier consumes it. The async-specific problem is that a sync
DBI storage holds one `$dbh` and simply re-fetches credentials when it
reconnects, whereas this transport holds a **pool** of EV::Pg connections created
lazily and on demand. For rotation to work, *each new pooled connection* must be
built from freshly-fetched credentials rather than from a snapshot captured when
the schema first connected — which would pin the pool to a password that later
expires.

The sibling driver recorded that reasoning first, in `dbio-mysql-ev` ADR 0006.
**This ADR deliberately does not restate it.** It records only what is
PostgreSQL-specific here, plus one correction that a reader of the sibling ADR
needs.

## The correction: most of that ADR is now core's, not the driver's

`dbio-mysql-ev` ADR 0006 describes building the provider closure and detecting the
broker shape as *driver* decisions. That was true when it was written and is no
longer. Measured against the installed core, the following all resolve to
`DBIO::Storage::Async`, not to any driver:

`_is_access_broker_connect_info`, `_setup_access_broker`, `_clear_access_broker`,
`_current_async_connect_info`, `_normalize_async_connect_info` and
`_conninfo_provider`.

Core's own `ACCESSBROKER CONSUMPTION` POD says as much — it names this "the async
consumption wiring that was previously re-implemented by every async driver".
Read the sibling ADR for the *why*; read this one for *what is still decided
here*.

## Decision

This driver fills the core seam and adds nothing else to the rotation mechanism.
What is genuinely local:

- **`_async_broker_conninfo`** — the storage-native shape. Core asks the
  transport for one fresh conninfo per new pool connection; this driver answers a
  libpq conninfo **hash**, built by routing the broker's current credentials
  through the inherited normalisation. It is the only rotation method this class
  defines.
- **`connect_info`** is overridden for two PostgreSQL-specific reasons, neither of
  which the sibling driver has. First, it folds a DBI-form connect info
  (`['dbi:Pg:…', $user, $pass, \%attrs]`) into the libpq `[\%conninfo, \%opts]`
  shape through `DBIO::PostgreSQL::EV::ConnectInfo::dbi_to_conninfo` **before**
  the broker/normalise logic runs — the embedded path, where the sync storage
  feeds its own DBI-form info. EV::MariaDB consumes the normalised hash directly
  and needs no such step. Second, it tears down the **dedicated LISTEN
  connection** on reconnect, which only exists in this driver (ADR 0003).
- **`pool`** hands the pool the provider coderef when a broker is attached and a
  static conninfo string otherwise.

## Consequences

- Broker-backed pools rotate credentials transparently: each new pooled connection
  is built from freshly-fetched credentials, with no pool teardown. Existing live
  connections are unaffected until they are recycled.
- **A broker connect cannot also request async.** Broker detection keys on the
  connect info being a single blessed element, so `->connect($broker)` has no
  slot for `{ async => 'ev' }`. A broker-backed schema therefore gets the ordinary
  sync DBI storage, and the async transport is reached only on the embedded path.
  `t/02-access-broker.t` pins exactly this, and it is why that file asserts
  `isa_ok $schema->storage, 'DBIO::Storage::DBI'` in a test about async.
- The LISTEN teardown in `connect_info` is a rotation concern as much as a
  connection one: the dedicated LISTEN connection is not pooled, so it does not
  pick up rotated credentials by itself and must be dropped on reconnect or it
  outlives them.
- Because the mechanism is now core's, a change to rotation semantics is a core
  ticket, not one here. What this driver must keep is answering
  `_async_broker_conninfo` with a *freshly built* value per call — returning a
  cached hash would silently defeat rotation while every test still passed.

## Future architecture work (tracked cross-repo, not here)

Whether the sibling `dbio-mysql-ev` ADR 0006 should itself be amended to mark
its superseded half is that repo's call, not this one's. This run could only
read that repo, so the finding is reported to the coordinator for routing onto
its board rather than filed from here; no ticket number is cited because none
exists yet.
