# ADR 0048 — DBIO-private connect attributes are stripped centrally before reaching `DBI->connect`

- Status: accepted
- Date: 2026-09-09
- Tags: connect-info, storage, async, driver-contract, cross-driver, family-policy

> Accepted with the implementation committed in karr k66 (2026-07-07).
> Sibling of k68 / ADR 0049, which closes the connect-action half of the same
> sync/async divergence.

## Context

A user connects to a DBIO storage with attributes that mean two different
things in two layers:

- DBI layer: `RaiseError`, `PrintError`, `AutoCommit`, `ChopBlanks`, … —
  these go to `DBI->connect`.
- DBIO layer: `async`, `quote_char`, `name_sep`, `quote_names`,
  `cursor_class`, `@storage_options`, `ignore_version`, the `on_connect_do` /
  `on_connect_call` lists — these do **not** go to `DBI->connect`. They are
  read by DBIO itself.

If a DBIO-private attribute leaks through to `DBI->connect`, the DBD is the
one that decides what happens. The drivers that ship today split:

- `DBD::Pg` **silently tolerates** the stray `async` attr, so PostgreSQL
  future_io adapters work *by luck*.
- `DBD::MariaDB` **hard-rejects** it: `DBI connect(...) failed: Unknown
  attribute async`. That is why `dbio-mysql`'s async adapter had to strip
  the attrs itself.

The two paths in core were inconsistent. The sync path was correct:
`DBIO::Storage::DBI::_normalize_connect_info` separates every DBIO-private
attr out of the attrs that reach `DBI->connect`:

- `async` → `$info{async_mode}` (sync `connect_info` reads it from there)
- `quote_char` / `name_sep` / `quote_names` → `$info{sql_maker_options}`
- `@storage_options`, `cursor_class` → `$info{storage_options}`
- `ignore_version` → deleted from `%dbi_attrs` (consumed by the
  DeploymentHandler version-storage component,
  `DBIO::DeploymentHandler::VersionStorage::Standard::Component`, not by the
  DBD)

The async path did not. `DBIO::Storage::DBI::_async_storage` handed the async
backend's pool the same hash without going through the same strip, so every
strict DBD would either silently accept (Pg) or loudly refuse (MariaDB), and
which one happened depended on the DBD, not on the contract.

## Decision

There is **one** authoritative list of DBIO-private connect attributes,
maintained in core, consulted by both the sync normalizer and the async
strip. The list lives on `DBIO::Storage`, the common base of the DBI and the
async storage (`_dbio_storage_option_names`, `_dbio_sql_maker_option_names`),
so the async base reaches it without depending on `DBIO::Storage::DBI`. Both
paths use it.

Concretely:

- The names are enumerated in one place. The sync `_normalize_connect_info`
  reads them to know what to strip into `$info{async_mode}` /
  `$info{sql_maker_options}` / `$info{storage_options}` / to delete from
  `%dbi_attrs`. The async strip — `_strip_private_connect_attrs`, run by the
  backend's `connect_info` on what `_async_storage` hands it — reads the same
  list to know what to strip before the hash reaches the backend's pool.

- New DBIO-private connect attributes are added once, to that list, and
  reach both paths on the next reload. A driver that adds a new DBIO-private
  attr without registering it gets a clear failure (the attr leaks to
  `DBI->connect` and the DBD complains) rather than a silent inconsistency.

- The extension seam is `k116`: an extension that wants its own DBIO-private
  connect attr registers it through `k116`'s accessor and the list picks
  it up. The list is not extensible by every driver individually — that
  would re-create the divergence this ADR closes.

## Rationale

The bug was that the strip was a property of *one path*. A correct-by-luck
DBD (Pg) hid it; a strict DBD (MariaDB) showed it. Both observations were
real, neither was actionable on its own, and the eventual fix is what
distinguishes "a list of names that two paths must share" from "two paths
that each list their own names."

Centralising the list in core is the only place it can live:

- Putting it on `DBIO::Storage`, the common base of `DBIO::Storage::DBI` and
  `DBIO::Storage::Async`, lets both paths read it from their own instance:
  the sync path's `_normalize_connect_info` stays the source of truth for
  the split and the async path is a consumer, without the async base
  depending on `DBIO::Storage::DBI`.
- Putting it in `DBIO::Storage::Async` would invert the relationship: the
  async path would own the list and the sync path would consume it. That
  is wrong — the sync path is the original, the async path is the addition,
  and the addition has to match the original, not the other way round.
- Putting it in a driver would mean the list drifts per driver. Drivers
  do not own DBIO-private names; core does.

The extension seam (`k116`) is the only safe way to grow the list: an
extension declares its name, accessor, and storage-option hook in one place,
and the central strip picks it up. Without that seam, every new DBIO-private
attr is a hand-edit in two paths and a maintenance burden that grows
linearly.

## Consequences

- A new DBIO-private connect attribute is registered once, in core, and
  the sync normalizer and the async strip both pick it up. No per-driver
  hand-stripping (which is what the MySQL async adapter was doing before
  k66) survives.

- `dbio-mysql`'s pre-k66 attr-strip is dead code and goes. The async adapter
  for MySQL works because the central strip now does what the driver used
  to do, not because the driver still does it.

- A driver that does need its own DBIO-private connect attribute goes
  through `k116`'s extension seam — accessor + storage-option hook in one
  place. The driver no longer carries its own strip.

- The sync `_normalize_connect_info` becomes the source of truth for what
  reaches `DBI->connect`. A driver introspecting its own `connect_info`
  sees the same shape every other driver sees, because the strip is one
  function, not one function per path.

- A new DBIO-private attr added without registering through the seam
  surfaces as a `DBI connect(...) failed: Unknown attribute <name>` from
  the DBD — a clear, immediate failure rather than the silent inconsistency
  this ADR closes.

## Future architecture work (tracked cross-repo, not here)

The extension seam `k116` is owned by core. Drivers that want to grow the
list file karr tickets to core; no driver maintains its own list. The
asymmetry that made the MySQL async adapter carry a private strip is
explicitly closed by this ADR — see the k66 ticket for the per-driver
follow-up.

## Addendum 2026-09-27 — the connect options beside an AccessBroker go through the same split (karr k243)

A broker-backed connection can carry connect options beside the broker,
`[ $broker, \%options ]` (ADR 0030 addendum 2026-09-27 II). They are split by
the same code as every other attribute hash, on both sides:

- **Sync:** the owner normalises the hash with `_normalize_connect_info`
  (`DBIO::Storage::DBI::AccessBroker::_access_broker_call_info`), so the private
  keys go to `async_mode` / `storage_options` / `sql_maker_options` exactly as
  with a DSN, and only real DBD attributes are merged into what the broker
  answered.
- **Async:** when a transport is handed the hash (it declares
  `broker_connect_options`), `_strip_private_connect_attrs` strips it like the
  attribute slots of a DSN form before `_normalize_conninfo` runs; what is left
  is `pool_size` and DBD attributes.

The name list is still the one on `DBIO::Storage`; the broker form adds a slot
to strip, not a list.
