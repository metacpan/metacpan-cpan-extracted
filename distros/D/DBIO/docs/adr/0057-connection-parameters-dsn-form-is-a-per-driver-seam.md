# ADR 0057 — The DSN form of connection parameters is a per-driver seam (`_connect_params_dsn`)

- Status: accepted
- Date: 2026-09-27
- Tags: accessbroker, storage, drivers, cross-driver, dsn, family-policy

## Context

`DBIO::AccessBroker::Static` answers connection parameters, not a DSN:
`{ dbname, host, port, user, password }` (ADR 0013). So does a connect-info hash
that has a `dbname` key and no `dsn`.
`DBIO::Storage::DBI::_normalize_connect_info` has to turn those parts into a DSN
before `DBI->connect`. Until karr k239 it built
`dbi:SQLite:dbname=<dbname>` whatever the driver and handed host and port to
`DBI->connect` as attributes. k239 made it build the DSN for the driver the
storage class is registered for (`register_driver`), in one fixed form:

    dbi:<DBD>:dbname=<dbname>;host=<host>;port=<port>

That form is right for DBD::Pg, DBD::mysql, DBD::MariaDB, DBD::SQLite,
DBD::Firebird and DBD::DuckDB, all of which take a `dbname` key (the MySQL
drivers as a synonym of `database`). It is wrong for the others the family
ships:

- DBD::Oracle takes a TNS alias or SID, `host=...;sid=...;port=...`, or an
  Easy Connect URL `//host[:port][/service_name]` — no `dbname` key;
- DBD::DB2 takes a cataloged alias, or an uncataloged connection string
  `DATABASE=...;HOSTNAME=...;PORT=...;PROTOCOL=TCPIP`;
- DBD::Sybase takes `server=...`, or `host=...;port=...` and `database=...`;
- the MSSQL driver registers the name `MSSQL`, which no DBD carries: the DSN
  names a driver that does not exist;
- DBD::ODBC connects through a data source name or a connection string naming
  the ODBC driver, and connection parameters carry neither.

Each of these got a DSN its DBD refuses. (Before k239 they got a SQLite DSN, so
nothing regressed — but nothing worked.) karr k242 raised two questions: should
the form be a per-driver seam, and should a schema without a driver component
be able to use Static through a `driver` (or `dsn`) argument. The maintainer
decided both on 2026-09-27.

## Decision

**The DSN form is the driver storage's seam `_connect_params_dsn`, and only the
form.** `DBIO::Storage::DBI` defines it with today's default; a driver whose DBD
takes another form overrides it in its storage class.

    sub _connect_params_dsn {
      my ($self, $driver, $params) = @_;   # 'Oracle', { dbname => ..., host => ..., port => ... }
      return $dsn;
    }

- **What it receives.** `$driver` is the DBD name the storage class is
  registered for. `$params` is a fresh hashref holding only the parts given —
  `dbname`, `host`, `port`, each present only when defined and not empty, none
  containing `;`.
- **What it returns.** The DSN string. An override may name another DBD than
  `$driver` when its engine is reached through one (MSSQL through DBD::Sybase).
  A DBD with no form these parts can fill throws, naming what it needs.
- **What stays core's**, in `DBIO::Storage::DBI::_dsn_from_connect_params`,
  once and the same for every driver: the three keys are removed from the
  connect attributes, so they never reach `DBI->connect` as attributes; empty
  parts are dropped; a `dbname` that starts with `dbi:` is taken as the whole
  DSN, and `host`/`port` beside it throw (they cannot be put into it, and as
  attributes they would be lost — a HostBound view's host among them); the
  driver is resolved from the registry and a storage registered for no single
  driver refuses; a value containing `;` refuses. Only then is the seam asked.
  (All of this for a hash that has a `dbname` key — see the addendum of
  2026-10-04; without that key and without a `dsn`, `host`/`port` are refused —
  see the addendum of 2026-10-06.)

**No `driver` argument on Static.** A schema that loads no driver component
stays refused for connection parameters: the generic storage learns its driver
from the DSN, and connection parameters name none. The seam is not a way around
that either — it is asked only on a storage registered for exactly one DBD.

**ODBC refuses, in core.** `DBIO::Storage::DBI::ODBC` (registered for `ODBC`)
overrides the seam to throw. There is no generic ODBC form: a DSN-less DBD::ODBC
connection string needs the ODBC driver's name (`Driver={...}`), whose keywords
that driver defines (`Server=host,port` for Microsoft's, `Server=...;Port=...`
for FreeTDS), and a data source name (`DSN=...`) is configured outside DBIO.
Reading `dbname` as a data source name would silently reinterpret the field and
drop `host`/`port`. The error names the ways out: the whole DSN — as `dsn`, or
as a `dbname` starting with `dbi:ODBC:` — or a broker answering in DBI form.

## Rationale

This is ADR 0020 again, for the connect path instead of the temp database: the
one legitimate per-driver variation is the DSN's *form*; everything around it is
engine-agnostic and carries invariants — above all that `dbname`/`host`/`port`
never reach `DBI->connect` as attributes, which is the bug k239 fixed. A seam
over the whole of `_dsn_from_connect_params` would hand every driver that
invariant to re-implement, and the first copy to forget it reintroduces the bug.
The narrow hook keeps the invariant in one place and makes the form a short
method a driver can safely replace.

The `driver` argument was declined because it would make the broker — a
CredentialSource that answers *which database and as whom* (ADR 0013) — name the
DBD, which is the schema's decision through its driver component, and it would
give the generic storage a second way to pick a driver next to the DSN.

## Consequences

- A driver whose DBD does not take `dbi:<DBD>:dbname=...;host=...;port=...`
  overrides `_connect_params_dsn` in its storage class and nothing else. The
  drivers that take the default form (PostgreSQL, MySQL/MariaDB, SQLite,
  Firebird, DuckDB) change nothing.
- The seam is on `DBIO::Storage::DBI`, not on one of the ADR 0024 contract base
  classes; the contract version does not move. A driver that has not overridden
  it keeps producing the DSN its DBD refuses — exactly today's behaviour — until
  its ticket lands.
- The seam is asked at `connect_info` and again for every new connection, since
  a broker is asked anew each time (a rotated or re-hosted answer gets a fresh
  DSN).
- A `dbname` given as a whole DSN no longer leaks `host`/`port` into the DBI
  attributes: absent ones (Static answers them as `undef`) are dropped, given
  ones throw.
- Pinned in core by `t/access_broker/15-connect-params-dsn-seam.t` (the seam's
  arguments and answer, the invariants around it, the ODBC refusal, the
  whole-DSN `dbname`) next to k239's `t/access_broker/07-dbi-connection-params-dsn.t`.

## Future architecture work (tracked cross-repo, not here)

One ticket per driver repo, filed by the coordinator. Each override receives
`($driver, { dbname?, host?, port? })` and returns the DSN.

- **dbio-oracle** (`DBIO::Oracle::Storage`, DBD::Oracle). Documented forms:
  `dbi:Oracle:<alias-or-SID>`, `dbi:Oracle:host=H;sid=S;port=P`, and Easy
  Connect `dbi:Oracle://host[:port][/service_name]` (port defaults to 1521).
  Proposed: with `host`, `dbi:Oracle://host[:port]/dbname` — `dbname` read as the
  service name; without `host`, `dbi:Oracle:dbname` (TNS alias or local
  SID/service); `port` without `host` throws. Whether `dbname` means service
  name or SID is that ticket's decision.
- **dbio-db2** (`DBIO::DB2::Storage`, DBD::DB2). Documented forms: cataloged
  `dbi:DB2:<alias>`; uncataloged
  `dbi:DB2:DATABASE=db;HOSTNAME=h;PORT=p;PROTOCOL=TCPIP` (user and password stay
  `DBI->connect` arguments, not `UID=`/`PWD=`). Proposed: with `host`, the
  uncataloged string (DB2 has no implied port — `port` required, else throw);
  without `host`, `dbi:DB2:dbname`.
- **dbio-sybase** (`DBIO::Sybase::Storage`, DBD::Sybase). Documented keys:
  `server=`, `host=` + `port=` (OpenClient 12.5.1+ or FreeTDS; bypasses the
  interfaces file), `database=`. Proposed:
  `dbi:Sybase:host=h;port=p;database=db` — the default with `database=` for
  `dbname=`.
- **dbio-mssql** (`DBIO::MSSQL::Storage`, registered `MSSQL`, no such DBD).
  The override must name a real DBD. The only form without an ODBC driver name
  is DBD::Sybase over FreeTDS: `dbi:Sybase:host=h;port=p;database=db`. Over
  DBD::ODBC it needs the ODBC driver name (`Driver={ODBC Driver 18 for SQL
  Server};Server=h,p;Database=db`, or `Driver=FreeTDS;Server=h;Port=p;Database=db`),
  which the parameters do not carry. Two things for that ticket: a storage
  pinned to `DBIO::MSSQL::Storage` is not driver-detected, so whether it becomes
  `DBIO::MSSQL::Storage::Sybase` on a `dbi:Sybase:` DSN is the driver's to make
  sure; and `DBIO::MSSQL::Storage::ODBC` (C3: `DBIO::Storage::DBI::ODBC` before
  `DBIO::MSSQL::Storage`) resolves to core's ODBC refusal unless it overrides
  the seam itself.

## Relationship to other ADRs

- ADR 0013 — the AccessBroker seam; Static is the source that answers
  connection parameters.
- ADR 0020 — the precedent: a narrow form-hook (`_temp_dsn`) instead of a
  whole-method override.
- ADR 0030 addenda (karr k240, k243) — the connect forms `[ $broker ]` and
  `[ $broker, \%options ]`; the parameters answered through either reach this
  seam.

## Addendum 2026-10-04 — the `dbname` key decides what counts as connection parameters (karr k267)

"`dbname`/`host`/`port` never reach `DBI->connect` as attributes" holds for a
hash that has a `dbname` **key** and no `dsn`. `_normalize_connect_info` enters
`_dsn_from_connect_params` — and so asks the seam — only then. The key decides,
not its value: Static answers `dbname` as `undef` when none was given, and the
DSN is built from the parts that have a value.

A hash with neither a `dsn` nor a `dbname` key — static connect info, or a
broker's answer of that shape — goes past all of it: the seam is not
asked, no DSN is built, and `host` and `port` stay in the hash and reach
`DBI->connect` as attributes. A connection then throws for want of a DSN, or,
with `$ENV{DBI_DSN}` set, goes to the DSN of the environment. Whether such a
hash is a set of connection parameters — built into a DSN or refused — or is
none by intent is the open question of karr k267, with karr k271 for a broker
answer that carries credentials and no DSN. Today's behaviour is pinned in
`t/access_broker/19-connect-params-without-dbname.t` and
`t/access_broker/17-dbi-broker-unusable-answer.t`. (Decided since: such a hash
is refused, and so is a broker answer without a DSN — see the addendum of
2026-10-06, which replaces this paragraph.)

## Addendum 2026-10-06 — connect info that names no database is refused; a broker's credentials never go to `$ENV{DBI_DSN}` (karr k267, k271)

Maintainer's decision, closing the question the addendum of 2026-10-04 left
open: a hash with `host`/`port` and no `dbname` key is neither built into a DSN
nor passed on. It is refused — and so is every broker answer without a DSN.

**`host`/`port` without a `dsn` and without a `dbname` key throw.**
`_normalize_connect_info` refuses a connect-info hash that has `host` or `port`
and neither key (and no `dbh_maker`), naming the keys given and what is
missing, never a value. Such a hash names a server and no database, so there is
no DSN to build the parts into; passed on as DBI attributes they bind nothing,
and the connection goes wherever `$ENV{DBI_DSN}` points — with the user and
password given for the host named. With this the invariant of the Rationale
holds for every hash without a `dsn`: `host` and `port` reach `DBI->connect`
inside a DSN or not at all. Beside a `dsn` they are DBI attributes as before.

**A broker answer without a DSN throws.**
`DBIO::Storage::DBI::AccessBroker::_normalized_access_broker_connect_info` is
the one place both `connect_info` and `_connect` read a broker's answer
through, so the refusal holds at configuration and at every later connection,
for a broker attached directly or through a HostBound view. Refused: a hash
with neither a `dsn` nor a `dbname` key (credentials alone, or with
`host`/`port`), and a hash or the DBI form whose DSN is undefined or empty. The
error names the broker class and the shape of the answer, never a value of it
(as for the shapes of karr k270), and `DBI->connect` is not called. An answer
giving a code reference (`dbh_maker`) needs no DSN.

**No fallback to the environment with a broker attached.** There are two: the
`_dbi_connect_info` reader puts `$ENV{DBI_DSN}` in the place of an undefined
DSN, and `DBI->connect` itself does so for an empty one. The refusal above
closes both for a connection, and the reader no longer falls back while a
broker is attached, so the storage does not take the environment's DSN for its
own either (driver determination reads it). The reason is ADR 0013's: a broker
answers *which database, and as whom* — its credentials are for the database it
names, and a DSN from the process environment is not that database.

**What stays.** The `dbname` key still decides, not its value:
`{ dbname => undef, host, port }` — Static without a `dbname` — is built into a
DSN from the parts that have a value. And static connect info without a broker
and without `host`/`port` keeps DBI's own behaviour: no DSN falls back to
`$ENV{DBI_DSN}`, as for a storage that never got connect info. The decision is
about a broker's credentials and about `host`/`port`, not about that fallback.

**Amended 2026-10-12 (k306):** static connect info carries its DSN as well, and
the storage reads no DSN from the environment in any state — see the addendum
of 2026-10-12.

**Consequence for drivers.** A broker, or a test double of one, that answers
`{ host, port, user, password }` without a `dbname` key now throws at
`connect_info`; it answers `dbname` (as `undef` when there is none, as Static
does) or a `dsn`. The seam `_connect_params_dsn` and its contract are
unchanged, and no ADR 0024 contract version moves.

Tests: `t/access_broker/19-connect-params-without-dbname.t`,
`t/access_broker/17-dbi-broker-unusable-answer.t`.

## Addendum 2026-10-06 — a broker's hash answer carrying a parameter the sync storage would not apply is refused (karr k298)

Maintainer's decision, from a live finding (dbio-postgresql-ev k60, PostgreSQL
with ssl off): a broker answered a hash with `sslmode => 'require'`. The `ev`
pool refused the server; the sync dbh of the same schema connected without SSL
and said nothing. Refuse, rather than connect without the parameter.

**Why it was lost.** Of a hash, core builds `dbname`, `host` and `port` into
the DSN and nothing else (the Decision above). Every other key core does not
consume itself goes to `DBI->connect` as an attribute, and a DBD keeps a
lowercase attribute it does not know without a word. An async transport hands
the same key to its client. So the two connections of one schema differed in
exactly what the broker asked for.

**What is refused.** `_assert_access_broker_parameters_apply` in
`DBIO::Storage::DBI::AccessBroker`, called from
`_normalized_access_broker_connect_info` — the one place `connect_info` and
`_connect` read a broker's answer through, so it holds at configuration and at
every later connection, directly and through a HostBound view. (No longer at
configuration, only where the storage connects — see the addendum of
2026-10-06 (III).) A key of a hash answer passes when it is

- consumed by the storage: `dsn`, `user`, `password`, `dbname`, `host`, `port`,
  the storage options, the SQL maker options, `cursor_class`, `async`,
  `pool_size`, `ignore_version`;
- the name of a DBI attribute: starting with an uppercase letter, with
  `private_`, `dbi_` or `dbd_`, or with a prefix of the DBD the answer's DSN
  names;
- set to `undef` or the empty string, which names no parameter.

Every other key throws, naming the broker class and the keys, never a value,
and `DBI->connect` is not called. That includes the prefix of another DBD and a
lowercase name on a DBD whose prefix is not known: neither can be told from a
client parameter, and the decision is to refuse in doubt.

**The DBD's prefix is a seam, `_dbd_attribute_prefixes($driver)`** on
`DBIO::Storage::DBI`. `$driver` is read off the DSN the connection will be
opened with — built or answered — so it is the DBD that gets the attributes,
whatever the storage class is registered for. The default asks
`DBI->driver_prefix`, DBI's static registry, which needs no DBD loaded. It does
not know DBD::Firebird or DBD::DuckDB; their driver storages override the
seam. On the generic storage only the default is asked.

**The ways out, both always open.** A client parameter goes inside the DSN — a
`dsn` key in the hash, or the DBI form. A DBI attribute the storage cannot
recognise goes into the attribute hash of the DBI form
`[ $dsn, $user, $password, \%attrs ]`, which is DBI's by its place and is not
looked into. A broker that serves an async transport and its owner in different
shapes answers by the storage that asks (`connect_info_for_storage`). (A `dsn`
key in the hash is no longer named as a way out — see the addendum of
2026-10-06 (III).)

**What stays.** Static connect info without a broker, the attribute hash of a
DBI-form answer, the options beside a broker (`[ $broker, \%options ]`) and a
`dbh_maker` answer are not covered by the decision and behave as before; so do
`host`/`port` beside a `dsn` key. An async mode does not defer the refusal: the
owning storage normalises the answer for its own connection in `connect_info`.
(Replaced for the options beside a broker and for the async mode — see the
addendum of 2026-10-06 (III).)

**Consequence for drivers.** dbio-firebird and dbio-duckdb override
`_dbd_attribute_prefixes` (one ticket each); until then a private
attribute of their DBD in a hash answer throws and belongs in the DBI form. The
seam is on `DBIO::Storage::DBI`, not on an ADR 0024 contract class; no contract
version moves.

Tests: `t/access_broker/31-dbi-broker-unapplied-parameters.t`.

## Addendum 2026-10-06 (III) — the sync storage refuses where it connects, and a parameter beside the broker like one in the answer (karr k298, k307)

Maintainer's decision, the same day, from two findings against the addendum
above. It keeps what that addendum decided — the sync storage never opens a
connection without a client parameter it was given — and replaces when it
says so and what it covers.

**The moment was wrong (k298).** The refusal sat in
`_normalized_access_broker_connect_info` and so fired in `connect_info`. An
async transport whose client takes parameters by name documents one hash for
every storage as the way to give one, and hands every key of it to its client
(dbio-postgresql-ev). With the refusal at configuration,
`Schema->connect($broker, { async => 'ev' })` died before either half opened
anything — also for a caller that only ever uses the pool. The sync storage was
refusing an answer nobody had asked it to connect with.

**The other door was open (k307).**
`Schema->connect($broker, { async => 'ev', sslmode => 'require' })`:
`_access_broker_call_info` normalised the hash beside the broker without the
yardstick above, `_merge_access_broker_call_info` joined what was left into the
DBI attributes of every answer, and the DBD did not read it. The owner's dbh
was opened without the parameter and nothing said so — the loss the addendum
above closed for the answer, by the hash next to it.

**Decision: the sync DBI storage throws when it is really to connect — with an
answer, or with options beside the broker — and cannot apply a client
parameter.**

1. **Never a connection without it.** A parameter in a hash answer and a
   parameter beside the broker both stop the connection; `DBI->connect` is not
   called.
2. **Not while only another storage uses the answer.** `connect_info` no longer
   throws for either. It configures the storage as before — the DSN of the
   answer goes into `_dbi_connect_info`, which driver determination and the
   resolution of the async backend read. The throw sits in `_connect`, so it
   comes with every connection of the storage's own: the first use of its dbh,
   a reconnect, a rotated answer, directly and through a HostBound view.
3. **One yardstick.** What passes beside the broker is what passes in a hash
   answer: consumed by core, the name of a DBI attribute, a prefix from
   `_dbd_attribute_prefixes`, or set to `undef` or the empty string. The DBD is
   the one the DSN of the current answer names, whatever form the answer has —
   that is the DBD the attributes beside the broker go to.
4. **The error says which of the two.** For the answer it reads as before
   (`AccessBroker <class> answered connect info with parameter(s) a DBI storage
   does not apply (...)`); for the hash beside the broker, `A DBI storage does
   not apply parameter(s) given beside AccessBroker <class> (...)`. Both name
   the broker class and the keys, never a value. A parameter in the answer is
   named first; the one beside the broker once the answer carries none.

**How.** `_normalized_access_broker_connect_info($mode, connecting => 1)` runs
`_assert_access_broker_parameters_apply` on a hash answer; `connect_info` calls
it without the flag. `_connect` then runs
`_assert_access_broker_options_apply($info, $beside)` before the hash beside
the broker is merged into the answer. Both read the yardstick from
`_access_broker_unapplied_parameters`.

**The ways out.** The DBI form `[ $dsn, $user, $password, \%attrs ]` with the
parameter inside the DSN, whose attribute hash is still not looked into; and a
broker answering by the storage that asks (`connect_info_for_storage`) — the
DBI storage an answer without the parameter, or with it inside the DSN. A
parameter beside the broker belongs in the broker's answer, in one of these
two ways, not beside it. A `dsn` key in the hash is **not** among them any
more: the sync storage takes it as before, but an `ev` transport does not read
it (dbio-postgresql-ev k79), so it gives the parameter to one half of a schema
only. Neither message nor POD points to it.

**Why at the connection, not at configuration.** A storage can answer only for
the connection it opens itself. The broker is asked per storage
(`connect_info_for_storage($storage)`), and an async backend asks on its own
behalf; at `connect_info` the owner cannot know whether it will ever connect
with what it was configured with. Refusing there made the owner veto an answer
that was correct for the only storage using it. The price is that the error
comes later — at the first sync use, not at `Schema->connect` — and that is
accepted: the same answer is wrong for a schema only once its sync half
connects.

**What stays at `connect_info`.** Everything else it checks: an answer that is
no hash and no array (k270), an answer without a DSN (k271), a setting given
both in the answer and beside the broker with different values, and the
connection itself named beside the broker. Still not covered: static connect
info without a broker, the attribute hash of a DBI-form answer, and a
`dbh_maker` answer — beside which nothing is judged either, since the storage
applies nothing that stands beside the broker to a connection the code opens.

**Consequences.**

- `Schema->connect` with such an answer, or such options, now succeeds; the
  first sync use throws. Code that relied on the refusal at configuration gets
  it at the first dbh.
- A lowercase key beside a broker that is no connect option and no DBI
  attribute by its name used to reach `DBI->connect` and now stops the sync
  connection. That includes a private attribute of a DBD whose prefix DBI's
  registry does not know (DBD::Firebird, DBD::DuckDB) until its driver storage
  overrides `_dbd_attribute_prefixes` — the tickets of the addendum above; until
  then it belongs in the attribute hash of a DBI-form answer.
- A transport, layer or driver that reaches for the owner's dbh on its own
  meets the refusal there.
- No ADR 0024 contract version moves.

Tests: `t/access_broker/31-dbi-broker-unapplied-parameters.t`,
`t/access_broker/32-dbi-broker-unapplied-options-beside.t`.

## Addendum 2026-10-09 — a DSN already written has its own seam (karr k276)

`_connect_params_dsn` builds a DSN from parts. Putting a host into a DSN that
is already written -- a `HostBound` view over a DBI-form answer -- is the
separate seam `_bind_host_into_dsn`, which declines forms it cannot translate
and so makes the view refuse; see ADR 0013, addendum 2026-10-09.

## Addendum 2026-10-12 — static connect info carries its DSN; the storage reads none from the environment (karr k306)

Maintainer's decision: the DSN decides the driver. Static connect info — every
form without a broker and without a code reference — names its DSN, and
`$ENV{DBI_DSN}` is no substitute for it.

**Static connect info without a DSN throws at `connect_info`.**
`_assert_static_connect_info_has_dsn` in `DBIO::Storage::DBI` judges the
normalised form, so it holds for every shape: no arguments at all, the DBI form
with an undefined or an empty DSN, a hash whose `dsn` is undefined or empty
(with `host`, `port`, `user` beside it or not), and a hash with neither a `dsn`
nor a `dbname` key. The error names the shape, never a value. It is the static
twin of the refusal a broker's answer gets, with the same shapes.

**No fallback to the environment.** The `_dbi_connect_info` reader returns what
`connect_info` stored and nothing in its place. A storage that never got
connect info, one whose `connect_info` threw and one whose broker was detached
are in the same state: `_connect` throws `You did not provide any
connection_info`, with `$ENV{DBI_DSN}` set or not. The DBD whose attribute
prefix passes among static attributes is the one the DSN given names.

**What stays.** A hash with a `dbname` key has a DSN — the one
`_connect_params_dsn` builds for the declared driver — and the `dbname` key
still decides, not its value. A code reference and a `dbh_maker` open the
connection themselves and need no DSN. A broker's answer keeps its own refusal
and message. `sslmode` in static connect info passes as a DBI attribute.

**Consequence for callers and drivers.** A schema made only to generate SQL
names its DSN like any other (`->connect('dbi:Pg:')`); nothing is opened before
the first use that needs a connection. A mock storage is connected with a code
reference, as `DBIO::Test->init_schema` does. The seam `_connect_params_dsn` is
unchanged, and no ADR 0024 contract version moves.

Tests: `t/access_broker/37-static-without-dsn-refused.t`,
`t/access_broker/19-connect-params-without-dbname.t`,
`t/access_broker/16-dbi-broker-detached.t`.

## Addendum 2026-10-13 (karr k340)

**The driver part of a DSN is never empty.** The DSN decides the driver, so a
DSN whose driver part is empty (`dbi::dbname=x`) is refused with a message that
names the shape, never the DSN, and `$ENV{DBI_DRIVER}` stands in for nothing.
The refusal is made before `DBI->connect` (which would itself read
`DBI_DRIVER`), in static connect info and in a broker's answer alike, and
again wherever core reads the driver off the DSN without connecting.

**An empty `dbname` is no database.** The DSN built from the parts refuses a
`dbname` that is defined and empty, in a static hash and in a broker's answer —
both go through `_dsn_from_connect_params`. A `dbname` that is not given
(`undef`) still lets the DSN be built from host and port; empty `host` and
`port` values are still dropped.

Test: `t/access_broker/38-empty-driver-part-and-empty-dbname-refused.t`.

## Addendum 2026-10-25 — the DSN of every connect passes a seam of its own (karr k361)

**`_finish_connect_dsn($dsn)` has the last word on the DSN.** With a broker, the
DSN of a connection is formed from the broker's answer for each connect, so
what a driver appends to a stored DSN (Sybase `;maxConnect=N`, `;bulkLogin=1`)
cannot ride on the stored connect info. `DBIO::Storage::DBI::_connect` therefore
asks `_finish_connect_dsn` for the DSN string once the connect info is formed —
from the broker's answer or from the stored connect info, at the same place for
both — and connects with the result.

- The default returns the DSN unchanged.
- It is asked only for a DSN string, never for a connection coderef.
- It works on a copy of the connect info; the stored one is not touched, so the
  seam is called at every connect and **must be idempotent**.
- A driver overrides it to append its additions; it needs no hook in
  `connect_info` and no state of its own.

The seams `_connect_params_dsn` (the form built from parameters) and the DSN
already written (k276) are unchanged; no ADR 0024 contract version moves.

Test: `t/access_broker/39-finish-connect-dsn-seam.t`.
