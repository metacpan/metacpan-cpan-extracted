# ADR 0001 — Transport is the MySQL wire protocol, over DBD::MariaDB / DBD::mysql

- Status: accepted
- Date: 2026-07-20

## Context

ClickHouse is a column-oriented OLAP database. It exposes several client
protocols: its native TCP protocol (port 9000), an HTTP interface (port 8123),
and — the one that matters here — the **MySQL wire protocol** (port 9004).

There is **no native `DBD::ClickHouse` on CPAN** (verified). Writing and
maintaining a native XS/FFI DBD against ClickHouse's native protocol is a large,
open-ended effort and is out of scope for a DBIO driver. DBIO drivers are thin
layers on top of an existing DBI driver; they do not implement the DBI transport
themselves.

ClickHouse's MySQL-wire endpoint lets any MySQL-protocol client connect. The
DBIO family already depends on two such DBI drivers for `dbio-mysql`:
`DBD::MariaDB` (bundles the MariaDB Connector/C) and `DBD::mysql`. Either can
talk to ClickHouse's port 9004.

## Decision

`DBIO::ClickHouse` rides the **MySQL wire protocol** via an existing MySQL-wire
DBI driver rather than a native `DBD::ClickHouse`:

1. `DBD::mysql` is the **recommended** transport (`recommends` in the
   cpanfile); `DBD::MariaDB` is **supported** (`recommends`) for servers whose
   config you control. This reverses the original choice (which mirrored
   `dbio-mysql`'s).
   *Revised by the Addendum (2026-08-05): the ranking is dropped, both DBDs
   are `recommends`, and which one is usable depends on whether you control
   the server config. Revised again by the Addendum (2026-08-17): the live
   measurements landed, `DBD::mysql` is the verified standard transport.*
2. The connection DSN is an ordinary MySQL-wire DSN pointed at port 9004, e.g.
   `dbi:MariaDB:database=default;host=127.0.0.1;port=9004`.
3. Identifier quoting is the backtick `` ` `` (MySQL-wire compatible), set on
   the storage via `sql_quote_char('`')`.

## Consequences

- **DSN-based driver detection cannot work.** Core's driver registry
  autodetects a storage class from the DSN's `dbi:<Driver>:` prefix. A
  ClickHouse DSN is `dbi:MariaDB:...` (or `dbi:mysql:...`), which is
  **indistinguishable from a real MySQL DSN** and resolves to the MySQL storage.
  There is therefore no autodetect route for ClickHouse. The storage **must** be
  pinned explicitly, either by `__PACKAGE__->load_components('ClickHouse')`
  (whose `connection()` sets `storage_type('+DBIO::ClickHouse::Storage')`) or by
  the `-ch` shortcut. This is documented prominently in the README, CLAUDE.md
  and the module POD.
- The `ClickHouse` driver name is still registered
  (`register_driver('ClickHouse' => ...)`) so the component / shortcut resolver
  and `apply_driver` work; it is simply never reached by *DSN* autodetection.
- Any MySQL feature the protocol advertises but ClickHouse does not actually
  implement (transactions, savepoints, `FOR UPDATE`, `RETURNING`,
  auto-increment) must be neutralised in the storage/SQLMaker rather than
  inherited blindly. See ADR 0002.
- The driver depends on ClickHouse's MySQL-wire endpoint being enabled
  (server config `mysql_port = 9004`).
- **`DBD::MariaDB` additionally requires a server-side setting to connect at
  all.** Found in the first live run (ClickHouse 25.3.14.14, 2026-07-26), not
  by reading docs. On connect, `DBD::MariaDB` unconditionally issues
  `SET character_set_server = 'utf8mb4'` — the statement is a hardcoded string
  in the compiled driver and there is no connect attribute that suppresses it.
  ClickHouse rejects a `SET` of any name it does not know unless that name
  begins with a registered custom-settings prefix, and ships with only `SQL_`:

      Code: 115. DB::Exception: Setting character_set_server is neither a
      builtin setting nor started with the prefix 'SQL_' registered for
      user-defined settings. (UNKNOWN_SETTING)

  The connection therefore fails outright against a stock server. The server
  must register the prefix, which turns those handshake settings into harmless
  user-defined ones:

      <clickhouse>
          <custom_settings_prefixes>SQL_,character_set_,collation_,sql_</custom_settings_prefixes>
      </clickhouse>

  It is read only at server **start** — `SYSTEM RELOAD CONFIG` does not pick it
  up. `maint/k8s/clickhouse.yaml` ships it as a ConfigMap. Note what this costs:
  the recommended DBD does not work against an unmodified ClickHouse, so this is
  a deployment prerequisite the driver cannot satisfy on its own, and it is not
  available on ClickHouse Cloud, which forbids custom prefixes. Whether
  `DBD::mysql` avoids the problem (it may send `SET NAMES` instead) is untested
  and tracked separately — if it does, the recommendation in this ADR should be
  reconsidered. *That question is answered as far as it can be answered without
  a server in the Addendum below.*
- No native-protocol-only features (native columnar block transport, etc.) are
  reachable over the MySQL wire. If those are ever wanted they would need a
  separate escape-hatch path; they are out of scope for this driver.

## Addendum (2026-08-05) — the ranking is dropped, not reversed

- Status: accepted
- Revises: Decision item 1
- Ticket: karr k15

### Why this was reopened

Decision item 1 ranked `DBD::MariaDB` first for one reason: `dbio-mysql` does.
That reason survived exactly until the first live run, which found the
first-ranked DBD cannot connect to a ClickHouse server whose config we do not
control — and on ClickHouse Cloud, cannot connect at all. Ranking a transport
above one that might work everywhere, on the strength of a sibling
distribution's habit, is not a decision worth keeping.

### What was measured, and how

The connect paths of both DBDs were read off the drivers themselves. **No
ClickHouse server was involved in this addendum** — every statement below is
about what the DBD sends, not about what ClickHouse answers. The one thing that
*is* a live measurement is the failure recorded in the Consequences above.

**`DBD::MariaDB` always sends the statement, on every connect.** In
`DBD-MariaDB-1.24/dbdimp.c` (the version installed here; the same calls are
visible in the compiled `MariaDB.so`, inside `mariadb_db_my_login`, after
`mysql_real_connect`):

    if (mysql_query(sock, "SET NAMES 'utf8mb4'") != 0 ||
        mysql_query(sock, "SET character_set_server = 'utf8mb4'") != 0)

It is guarded by no connect attribute — there is nothing to pass to suppress
it. Two details of that code matter here:

- The second statement is only reached when the first returned success, so the
  live failure on `character_set_server` also proves a **stock ClickHouse
  accepts `SET NAMES 'utf8mb4'`**. `SET NAMES` is not the problem; the
  server-scoped setting is.
- Its fallback branch is entered only for MySQL error `1115`
  (`ER_UNKNOWN_CHARACTER_SET`). ClickHouse answers `115` (`UNKNOWN_SETTING`),
  so the connect **fails outright** rather than degrading to `utf8`. Both
  branches go on to send `SET collation_connection` / `SET collation_server`,
  which is why the workaround prefix list needs `collation_` as well as
  `character_set_`.

**`DBD::mysql` sends no SQL at all on connect.** In `DBD-mysql-5.013` (current
CPAN) and `DBD-mysql-4.055`, `mysql_dr_connect()` issues nothing after
`mysql_real_connect`; the only `mysql_real_query` / `mysql_send_query` call
sites in the whole of `dbdimp.c` are in the statement-execution path. The
connection charset is applied **before** connect, via
`mysql_options(sock, MYSQL_SET_CHARSET_NAME, ...)` and only when
`mysql_enable_utf8mb4` / `mysql_enable_utf8` was passed, so it travels in the
handshake instead of as a `SET`. `AutoCommit` is silent too: the shadow flag is
initialised to TRUE at login and `dbd_db_STORE_attrib` returns early when the
value does not change, so the `AutoCommit => 1` DBIO connects with sends
nothing — and this driver never flips it to 0, because `_exec_txn_begin` is a
no-op (ADR 0003).

So the specific reason `DBD::MariaDB` fails is absent from `DBD::mysql` by
construction, not by luck.

### What that does and does not license

It does **not** license "`DBD::mysql` works against ClickHouse". Nobody has
connected with it. Reading a driver's source proves what it sends, never what
the server answers, and at least three things are still open: whether the
client library `DBD::mysql` is linked against negotiates an auth plugin
ClickHouse's MySQL-wire handler offers, whether the rest of the suite behaves
identically over it, and whether either DBD's server-side-prepare mode is
usable here. Those are named in karr k15 as the live measurements to take.

So the ranking is **dropped rather than reversed**:

1. Both DBDs are `recommends` in the cpanfile. Neither is "the default": which
   one is usable is a property of the server you are pointed at, not a quality
   judgement.
2. **If you control the server config** — `custom_settings_prefixes` as above —
   `DBD::MariaDB` is the transport the live suite has actually run against, and
   the one to use.
3. **If you do not** (ClickHouse Cloud, or any managed server), `DBD::MariaDB`
   is ruled out by measurement and `DBD::mysql` is the only remaining
   candidate — untried, but with nothing in its connect path that could trip
   the same wire.
4. One functional difference to plan for either way: `DBD::MariaDB` decodes
   character data to Perl Unicode strings unconditionally (it pins `utf8mb4`
   itself and has no `enable_utf8` knob), whereas `DBD::mysql` hands back bytes
   unless you connect with `mysql_enable_utf8mb4 => 1`. Swapping the transport
   is therefore not attribute-free for an application that stores non-ASCII
   text.

Nothing in the driver has to change to allow the choice: the storage is pinned
by `load_components('ClickHouse')` / the `-ch` shortcut and never by the DSN
(the first Consequence above), so `dbi:mysql:...` reaches
`DBIO::ClickHouse::Storage` exactly like `dbi:MariaDB:...`. That was verified
and is pinned by `t/07-transport-dbd.t`, because the equivalent claim was false
in a sibling driver and failed silently there.

## Addendum (2026-08-17) — DBD::mysql is the verified standard transport

- Status: accepted
- Revises: Decision item 1 (and the 2026-08-05 addendum's "neither is the default")
- Ticket: karr k15

### Why this was reopened

The 2026-08-05 addendum dropped the ranking because `DBD::mysql` had never been
connected. karr k15 was exactly those live measurements, and they are now taken
against a **stock** ClickHouse server — one with no
`custom_settings_prefixes` ConfigMap, no `config.d` mount. The outcome reverses
the drop: `DBD::mysql` connects to the stock server with no server-side
accommodation and the full live suite passes over it. "Which DBD is usable is a
property of the server" is still true; the property now has a measured answer —
**a stock server (and therefore ClickHouse Cloud) takes `DBD::mysql` and
refuses `DBD::MariaDB`'s connect-time `SET`.**

### What was measured, and how

All measurements are live, against `clickhouse/clickhouse-server:25.3`
(server version 25.3.14.14) run from a stock manifest. The DBD in the DSN was
the transport under test, the storage pinned per this ADR as always, via the
live harness (`DBIO::ClickHouse::Test->init_schema`, per-process database).

**`DBD::mysql` 4.055 connects to the stock server and the full suite passes
over it.** `33 files, 1035 tests, PASS` (`prove -lr t/` against the stock pod,
`dbi:mysql:` in the DSN, `mysql_enable_utf8mb4 => 1` supplied by the harness).
The auth handshake completed with `mysql_native_password` (confirmed in the
server log: `auth_plugin_name: mysql_native_password`), because this
installation of `DBD::mysql` is linked against **MariaDB Connector/C 3.4.9**
(`mysql_clientinfo` 3.4.9, `mysql_clientversion` 30409). The
caching_sha2_password risk the ticket named applies to a `DBD::mysql` built
against libmysqlclient 8.x; that build remains unmeasured — the one open caveat
below.

**Server-side prepares are unusable against ClickHouse, for both DBDs.** The
server accepts `COM_STMT_PREPARE` and even runs the query, but the client
cannot collect the result over the wire: `DBD::mysql` with
`mysql_server_prepare => 1` fails with "fetchrow_array failed: no statement
executing"; `DBD::MariaDB` with `mariadb_server_prepare => 1` fails with
"fetch() without execute()" (the latter measured against the prefixed server,
the only one `DBD::MariaDB` can reach). Client-side interpolation (the DBD
default) is the only usable path, which is what the driver has always done —
no driver change follows.

**`mysql_enable_utf8mb4 => 1` is required for `DBD::mysql`.** Without it the
server's character data comes back as bytes (a 3-byte UTF-8 sequence counted
as 10 bytes); with it, as decoded Unicode (8 characters). `DBD::MariaDB`
decodes unconditionally. The live harness now sets the attribute for
`dbi:mysql:` DSNs (`DBIO::ClickHouse::Test::_database`), so the suite asserts
against decoded Unicode on both transports.

### What that does and does not license

It licenses making `DBD::mysql` the standard recommendation:

1. `DBD::mysql` is the **recommended** transport (`recommends` in the
   cpanfile), the default in the live harness and in `maint/k8s/clickhouse.yaml`
   (now a stock manifest). It connects to a stock server — including ClickHouse
   Cloud — with no server-side accommodation. Verified.
2. `DBD::MariaDB` remains **supported** (`recommends`), for servers whose
   config you control and where `custom_settings_prefixes` is registered. The
   ConfigMap the manifest used to ship is gone; the requirement itself is still
   documented below. It decodes unconditionally and had the longer live history
   in this repo before this addendum.
3. Server-side prepare attributes (`mysql_server_prepare`,
   `mariadb_server_prepare`) are **off the table** — measured unusable, not
   merely unverified.
4. One caveat stays genuinely open: a `DBD::mysql` built against
   **libmysqlclient 8.x** has not been connected here. If such a build fails
   the auth handshake, the remedy is documented: create the ClickHouse user
   with `IDENTIFIED WITH double_sha1_password` (or `plaintext_password`) so the
   server offers `mysql_native_password`. Until then the MariaDB Connector/C
   build is the one verified.

The practical guidance is now: **prefer `DBD::mysql`** (stock/cloud-safe);
reach for `DBD::MariaDB` only when you control the server and register the
prefixes. The driver-side pin (`load_components('ClickHouse')` / `-ch`) is
untouched — both DBDs reach `DBIO::ClickHouse::Storage` via the DSN, pinned by
`t/07-transport-dbd.t` as before.

## Addendum (2026-10-07) — both DBDs are this driver's own access path

- Status: accepted
- Revises: nothing; adds a Consequence
- Ticket: karr k35

### Why this was reopened

Core's ADR 0059 (karr dbio k301) changed what happens to a storage class a
schema declares. The class stands, as this ADR always needed it to — but
during driver determination core now holds the DBD the DSN names against its
driver registry (`_check_access_path_dbd` in `DBIO::Storage::DBI`). When the
registry maps that DBD to a storage class the declared storage is not related
to by inheritance, the DSN is taken to lead through another driver's DBD and
is reported through `_driver_mismatch`: a warning by default, an exception
with `driver_strict(1)` on the schema.

Core registers `mysql` for `DBIO::MySQL::Storage` and `MariaDB` for
`DBIO::MySQL::Storage::MariaDB`, statically — it does not matter whether
dbio-mysql is loaded or installed. Those are the only two transports this
driver has (Decision above), and `DBIO::ClickHouse::Storage` inherits neither
class on purpose (ADR 0002). So every connection over the intended transport
was reported as a mismatch. Measured on 2026-10-07 in a live run over
`dbi:mysql:` against ClickHouse 25.3: sixteen warnings from nine test files,
suite green, because no file counted warnings. With `driver_strict(1)` the
same schema could not connect at all. It is reproducible without a server and
without a DBD, since core judges the name in the DSN.

ADR 0059 point 5 says there is deliberately no list of "my DBDs" for a driver
to keep: *the inheritance of the adapted class is the declaration*. That holds
for every driver whose DBD is its own, and for one that reaches a foreign DBD
through a class inheriting that DBD's storage. It cannot hold for a driver
whose transport is another driver's DBD **and** which refuses that driver's
class. This driver is that case by its two founding decisions.

### Decision

`DBIO::ClickHouse::Storage` overrides `_check_access_path_dbd` and accepts
exactly the two MySQL-wire DBDs, `mysql` and `MariaDB`, as its own access
path. Every other DBD goes to core's check unchanged through `next::method`.

It is the list ADR 0059 did not want drivers to keep, held in the one driver
for which inheritance cannot stand in for it, and held in one place (`%WIRE_DBD`
beside the override). It decides from the DBD name alone: no connection, no
probe query, no mismatch detection of its own. Whether the server behind a
`dbi:mysql:` DSN really is a ClickHouse is not asked — the DSN cannot tell,
which is the first Consequence of this ADR, and ADR 0059 (c) asks no server
anything for the sake of the check either.

### Why not the other four ways

- **The documented hook, `_adapt_to_access_path`.** It runs before the check
  and has one way to influence it: reblessing into a class that inherits the
  class the DBD is registered for. For this driver that is a class inheriting
  `DBIO::MySQL::Storage` — the `@ISA` change ADR 0002 exists to refuse, and the
  kind of change the house rules do not let a fix carry.
- **`register_driver('mysql' => 'DBIO::ClickHouse::Storage')`.** It would
  silence the check and take over the generic DSN detection for every schema
  that declares nothing: a real MySQL `dbi:mysql:` DSN would resolve to the
  ClickHouse storage. The first Consequence above says why there is no
  registry route for this driver; that has not changed.
- **`driver_warnings(0)` set by the component.** It silences the report for
  every DBD, the wrong ones included, takes a switch away from the schema's
  author, and leaves `driver_strict(1)` an error — `driver_strict` wins.
- **Doing nothing and documenting the switch.** A warning on every connection
  over the only transport there is teaches the caller to turn the check off,
  which is the same loss by another hand.

### What it costs

`_check_access_path_dbd` and `_access_path_dbd` are **private methods of
core**, named in ADR 0059 but not offered as a seam. The override would have
to follow a rename, and a core that changed how the check is reached could
bring the warning back. That is contained, not hidden: `t/07-transport-dbd.t`
runs driver determination offline for both DBDs, both declared ways (component
and `-ch`) and both switch settings and fails on the first warning, and
`t/07-transport-dbd-live.t` does the same over a real connection.

The other half is pinned just as hard, because an exception widened too far
would be silent: a `dbi:Pg:` DSN on a ClickHouse schema must still be reported,
naming `DBIO::ClickHouse::Storage` and `DBD::Pg`, and must still throw under
`driver_strict(1)`.

## Addendum (2026-10-14) — the override is replaced by core's documented API

- Status: accepted
- Revises: the Decision and "What it costs" of the 2026-10-07 addendum
- Ticket: karr k38

Core grew the seam the previous addendum asked for:
`DBIO::Storage::DBI->register_access_path_dbd(@dbds)`, which declares DBDs of
other drivers as a driver's own access path. `DBIO::ClickHouse::Storage` now
calls `__PACKAGE__->register_access_path_dbd(qw( mysql MariaDB ))` and the
private `_check_access_path_dbd` override and its `%WIRE_DBD` are gone.

The decision is unchanged: exactly `mysql` and `MariaDB` are this driver's own
transport, silently and also under `driver_strict(1)`; every other DBD (a
`dbi:Pg:` DSN) is still judged and reported by core. The declaration is made on
the storage class, inherited by its subclasses only, and changes neither
driver detection nor any `@ISA`, so ADR 0002 stands. What it no longer costs:
following a rename of a private core method. `t/07-transport-dbd.t` still
pins the behaviour and now also that the storage defines no check of its own.

## Future architecture work (tracked cross-repo, not here)

- **A documented seam in core for a driver whose transport is another
  driver's DBD.** ADR 0059 gives a driver no way to say "this DBD is mine
  although I do not inherit its storage"; this driver says it by overriding
  the check. Whether core grows a hook for it, and what it is called, is
  core's decision and a card on core's board (raised from karr k35).
  **Resolved 2026-10-14** (karr k38): core's `register_access_path_dbd` is that
  seam and this driver uses it; see the addendum above.
