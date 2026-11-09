# ADR 0059 — A declared driver storage stands and adapts itself to the access path (`_adapt_to_access_path`, `_driver_mismatch`)

- Status: accepted
- Date: 2026-10-06
- Tags: storage, drivers, driver-detection, connect-path, cross-driver, family-policy, builds-on-0032, relates-0035, relates-0057

## Context

A storage finds its driver in `DBIO::Storage::DBI::_determine_driver`, lazily,
at the first use that needs it. That method sends exactly one kind of storage
through the DSN detection — the registry lookup by DBD name
(`register_driver`), the rebless, the `_rebless` hook: the **generic**
`DBIO::Storage::DBI`, bare or as the base of a `DBIO::Storage::Composed`
class. Every other class skips the block and goes straight to `_init`.

A schema that says which driver it uses is never the generic class. There are
two places that say it, and both pin the same thing:

- the **driver component**: `DBIO::<Name>::connection` sets
  `storage_type('+DBIO::<Name>::Storage')` before every connect;
- the **driver shortcut**: `use DBIO 'Schema', -syb` resolves to
  `DBIO->apply_driver($caller, 'Sybase')` in `lib/DBIO.pm`, which sets
  `storage_type("+DBIO::${name}::Storage")`.

So a schema that declares its driver gets the driver's **base** storage class
and keeps it for good. For a driver with one access path that is the right
class. For a driver with several it is a class that fits none of them:

- **dbio-sybase k64.** `DBIO::Sybase::Storage` is a dispatcher. Its `_rebless`
  asks the server what it is and moves on to `DBIO::Sybase::Storage::ASE`
  (and from there to `...::ASE::NoBindVars`); its `_init` mixes the FreeTDS
  fixups in once the storage has left the base class. For a schema that
  loaded the `Sybase` component or used `-syb`, `_rebless` never runs: the
  storage stays the dispatcher, which has no ASE behaviour and gets no
  FreeTDS fixups.
- **dbio-mssql k37.** `DBIO::MSSQL::Storage` is the transport-neutral base of
  ADR 0035; the classes that work are `DBIO::MSSQL::Storage::ODBC` and
  `DBIO::MSSQL::Storage::Sybase`. It is registered for the name `MSSQL`, which
  no DBD carries, so a schema that loaded the `MSSQL` component reaches
  neither.

The same `_rebless` that would have helped is also where the old detection
changes the **product**: `DBIO::Sybase::Storage::_rebless` turns a storage
into `DBIO::MSSQL::Storage::Sybase` when the server answers as Microsoft SQL
Server, and `DBIO::Storage::DBI::ODBC::_rebless` hands the storage to whatever
engine the connector registry names. That is right for a storage that was
told nothing but a DSN. It is wrong for a schema that said `-syb`.

karr k301 put the question to the maintainer: what does the declared class
mean, and who gets a declared storage to the class its connection needs.

## Decision

Maintainer's decision of 2026-10-06. DBIO is driver-driven: **a schema always
declares its driver** — by the driver's component or by its shortcut. A schema
that declares none is not the way to use DBIO.

- **(a) The declared storage class stands.** It never becomes the class of
  another driver or product.
- **(b) The driver adapts itself to the access path** — the DBD and client
  library the DSN leads through. Core calls an adaptation hook during driver
  determination **for declared (non-generic) classes too**. The hook may
  specialise only within its own driver: afterwards the storage must still be
  an instance of the declared class, **or core throws**. The base hook does
  nothing; for a driver without a hook of its own nothing changes.
- **(c) Little hand-holding.** No new probe queries to the server, no earlier
  connect forced by core. A warning comes only where a problem is noticed
  anyway: (1) the DBD of the DSN does not belong to the declared driver (a
  schema declaring MSSQL connected with `dbi:Pg:`), or (2) the driver notices,
  from what it knows anyway, that the server is something else. One central
  core method reports both; drivers call it, and core uses it for (1). MySQL
  and MariaDB are a compatible family: no warning.
- **(d) Two switches on the schema.** `driver_strict => 1` makes these
  warnings errors, as if the combination did not work at all;
  `driver_warnings => 0` turns them off. Default: warn.
- **(e) The old DSN detection for the generic storage is not touched** — the
  registry, `_rebless`, `_determine_connector_driver`,
  `DBIO::Storage::DBI::ODBC`. Its behaviour stays as it is, bit for bit. What
  becomes of it is a card of its own.

### How it is built

**1. The hook has a name of its own: `_adapt_to_access_path`. `_rebless` is
not reused.** `_rebless` belongs to the old generic detection of (e), and
there it may change the product (the two cases above). The new contract
forbids exactly that. Two contracts under one name is something a driver
could not tell apart: the same method would have to move a storage to another
product when the storage came in generic, and refuse to when it came in
declared. With a name of its own, installing this core changes no driver's
adaptation — each driver steps in by defining the hook, in its own time — and
the old detection can be decided later without touching the new path. The
generic path does not call the new hook.

**2. The call.** `_determine_driver` calls
`$self->_adapt_to_access_path($dbd)` in its non-generic branch, before
`_driver_determined(1)` and `_init`, so `_init` runs on the specialised class
— where it runs after `_rebless` on the generic path. The hook is imperative,
as `_rebless` is: it reblesses `$self`, may call itself again on the new class,
may set options.

`$dbd` is the DBD name core knows **without connecting**
(`_access_path_dbd`): the live handle's `{Driver}{Name}` when the storage is
already connected, else the name in the DSN of `_dbi_connect_info` (the regex
of `_extract_driver_from_connect_info`), else `$ENV{DBI_DRIVER}`. It is
`undef` when the connect info is a code reference that has not run, and when
there is no DSN. Core does **not** connect to find out — unlike the generic
path, which runs a connection coderef because it has no other way to learn
anything. A declared class already knows its driver; what it may still need to
know is the driver's own business and the driver's own cost: a hook that needs
the handle calls `$self->_get_dbh`. That is safe inside determination
(`_in_determine_driver` keeps `_populate_dbh` from re-entering it and holds
the connection actions back until `_init` has run), and
`t/storage/declared_driver_access_path.t` pins it: one connection, one hook
call, `_init` once on the specialised class, connection actions once.

`_extract_driver_from_connect_info` is not shared with the new path, although
the regex is the same: it connects for a coderef, and it belongs to (e).

**3. The contract is checked by core, after the hook.** The declared class is
the class the instance had before the hook — for a `DBIO::Storage::Composed`
class its base. If the instance is no longer `isa` that class, core blesses it
back into the class it came in and throws, naming the declared class and the
attempted one. The two switches do not apply: this is a defect of the driver,
not a mismatch between a schema and a server. The storage is put back first
because the foreign class need not be a storage at all, and the exception is
thrown through the storage.

Storage layers survive. A hook reblesses into a plain class of its driver, so
a layered storage loses its layers on the way; when the instance came in
composed and is not composed afterwards, core composes the same layers over
the new class with `DBIO::Storage::Composed->recompose` — what the generic
rebless and `_determine_connector_driver` do.

Any exception out of the hook or the checks leaves the storage in the class
it came in and undetermined, so the next use tries again. A storage is never
left half adapted.

**4. One method reports a mismatch:
`DBIO::Storage::DBI::_driver_mismatch($message)`.** It reads the switches off
the schema (`$self->schema`; a storage without one gets the default):
`driver_strict` true throws; else `driver_warnings` false does nothing; else
it warns. `driver_strict` wins over `driver_warnings(0)`. The message is
prefixed with the declared storage class and, in a warning, followed by the
two switches. It carries a DBD name and class names and nothing of the
connect info. The declared class is kept on the storage
(`_declared_storage_class`) when determination enters the declared branch, so
a driver that notices the server only later — in `_init`, at a connect —
reports under the same name, also after it has specialised.

**5. The DBD of another driver, checked by core after the hook**
(`_check_access_path_dbd`), only when the DBD is known — a handle the hook
opened may supply it; core does not connect. A DBD is foreign exactly when
the driver registry (`register_driver`) maps it to a class R **and** the
adapted storage is neither `isa` R nor is R a subclass of the declared class.
R is loaded for the second question; a class that cannot be loaded is no
relative. A DBD the registry does not know (Proxy, Gofer, a mock) is not a
noticed problem and is not judged.

There is deliberately **no list of "my DBDs"** for a driver to keep. The
inheritance of the adapted class is the declaration, and the cases fall out
without a special one:

| Schema declares | DSN | R | Result |
|---|---|---|---|
| MySQL | `dbi:MariaDB:` | `DBIO::MySQL::Storage::MariaDB`, a subclass of the declared class | silent |
| MSSQL, hook specialised to `DBIO::MSSQL::Storage::ODBC` | `dbi:ODBC:` | `DBIO::Storage::DBI::ODBC`, an ancestor of the adapted class | silent |
| MSSQL, hook specialised to `DBIO::MSSQL::Storage::Sybase` | `dbi:Sybase:` | `DBIO::Sybase::Storage`, an ancestor of the adapted class | silent |
| MSSQL | `dbi:Pg:` | `DBIO::PostgreSQL::Storage`, unrelated | `_driver_mismatch` |
| any | `dbi:Proxy:` | none | silent |

The same rule reports a driver that has an access path and has not adapted to
it: a schema declaring MSSQL on `dbi:ODBC:` whose storage stayed
`DBIO::MSSQL::Storage` is told that DBD::ODBC is registered for
`DBIO::Storage::DBI::ODBC`. That finding is true — the base class does not
work on that handle — and it goes away when the driver ships its hook.

**6. The switches are schema accessors, and only that.** `driver_strict`
(default 0) and `driver_warnings` (default 1) are inherited class data on
`DBIO::Schema`, like `storage_type` and `stacktrace`: settable on the class
and on a connected schema. They are not connect attributes and not import
switches. They are read when there is something to report, so a switch set
after `connect` and before the first use counts.

**7. The two pins stay.** `DBIO->apply_driver` and the driver components go on
pinning the driver's base class. That pin *is* the declaration of (a).

**8. Who is not part of this.** `DBIO::Test::Storage` and
`DBIO::Replicated::Storage` override `_determine_driver` and never reach the
declared branch. The backends of a replicated storage are storages of their
own and go through it like any other; with the default
`backend_storage_class` they are generic.

## Rationale

The decision moves a choice to where the knowledge is. Which class fits
DBD::Sybase over FreeTDS, or SQL Server over ODBC, is knowledge of the driver
distribution; core cannot have it without naming drivers. Which *driver* a
schema uses is knowledge of the schema's author, and the DSN is a poor second
source for it — `dbi:ODBC:` and `dbi:Sybase:` each lead to more than one
engine, which is why the old detection has to ask the server. Declared, the
question never comes up, and nothing has to be asked.

The `isa` rule is the smallest check that keeps (a) honest without core
knowing what a "product" is. It is not complete: a class of another
distribution that inherits the declared class passes it
(`DBIO::MSSQL::Storage::Sybase` is a `DBIO::Sybase::Storage`). A driver that
moves there has broken (a) by its own hand; the rule for drivers below says
so in words, where core cannot say it in code.

(c) is the reason there is no detection in the declared branch at all. Every
check that could tell a schema it is talking to the wrong server costs a
round trip, at a moment the caller did not choose. The registry lookup costs
nothing and is right whenever it speaks; what a driver learns on the way
(a version string it reads anyway, an error it gets anyway) costs nothing
either.

## Consequences

**For callers.**

- A schema that declares a driver without a hook behaves as before: same
  class, no connection opened by determination, `_init` as before.
- New: on the first use that needs the driver, a declared storage whose DSN
  leads through a DBD registered for an unrelated class warns once per storage
  (`Driver mismatch for declared storage class ...`). This includes a class
  set through `storage_type` by hand that is no driver's — a private subclass
  of `DBIO::Storage::DBI` connected with `dbi:Pg:` is told that DBD::Pg is
  registered for `DBIO::PostgreSQL::Storage` — and a driver with access paths
  it has not adapted to yet (MSSQL on either DBD, Firebird over ODBC — see
  below). `driver_warnings(0)` silences it.
- `driver_strict` and `driver_warnings` are new public accessors on
  `DBIO::Schema`.
- Determination stays lazy and stays once per storage: a later `connect_info`
  with another DSN does not run the hook again, as it does not run detection
  again today.

**For drivers.**

- A driver with one access path does nothing.
- A driver with several defines `_adapt_to_access_path` on its **base**
  storage class — the one its component and shortcut pin — and reblesses, by
  `$dbd`, into its own class for that access path. Every such class inherits
  the base class; one that also inherits the class the DBD is registered for
  (`DBIO::Storage::DBI::ODBC`, `DBIO::Sybase::Storage`) is silent in the
  check of point 5.
- A server that is something else is reported with `_driver_mismatch` and the
  storage stays in the driver. A driver never moves a declared storage into a
  class of another product — not even one that happens to inherit its own.
- `_rebless` stays what it is, for the generic detection only. A driver that
  wants one body for both writes it once and calls it from both hooks; what
  must differ is the product switch, which only `_rebless` may make.
- The hook, `_driver_mismatch` and the switches are on `DBIO::Storage::DBI`
  and `DBIO::Schema`, not on one of the five ADR 0024 contract classes
  (`DBIO::Introspect::Base`, `DBIO::Diff::Base`, `DBIO::Deploy::Base`,
  `DBIO::SQLMaker`, `DBIO::Storage::DBI::Capabilities`). No capability is
  added and no method of those classes changes shape. **The contract version
  does not move**, as for the seam of ADR 0057; `t/test/12_contract_version.t`
  is untouched. A driver that ignores all of it is unchanged.

Pinned in core by `t/storage/declared_driver_access_path.t`.

## Future architecture work (tracked cross-repo, not here)

- **The generic DSN detection (e).** Whether a schema without a declared
  driver keeps being detected, warns, or is refused — and with it the fate of
  `_rebless`, `_determine_connector_driver`, the connector registry and the
  detection half of `DBIO::Storage::DBI::ODBC` — is undecided. A card of its
  own on core's board; nothing here depends on the answer.
- **dbio-sybase k64.** `_adapt_to_access_path` on `DBIO::Sybase::Storage`:
  what its `_rebless` does today for ASE, without the branch into
  `DBIO::MSSQL::Storage::Sybase`; a server that answers as something else goes
  to `_driver_mismatch`.
- **dbio-mssql k37.** `_adapt_to_access_path` on `DBIO::MSSQL::Storage`: by
  DBD into `DBIO::MSSQL::Storage::ODBC` or `DBIO::MSSQL::Storage::Sybase`.
  Until then a schema declaring MSSQL warns at its first use, on either DBD.
- **dbio-firebird.** `DBIO::Firebird::Storage::ODBC` does not inherit
  `DBIO::Firebird::Storage`, the class the component pins, so the `isa` rule
  does not let a hook go there. What the Firebird component declares is that
  repo's decision (and an `@ISA` question, so one with an ADR of its own).

## Relationship to other ADRs

- ADR 0032 (§7 and the addendum of 2026-08-07) — an **extension** never
  determines the driver; it registers a layer. This ADR is the other half: the
  **driver** component or shortcut does determine it, and that declaration
  stands. A layered storage goes through the hook and keeps its layers. The
  addendum's sentence that "the DSN decides the driver" describes a schema
  that loaded an extension and no driver component, which is the generic path
  of (e); with a driver declared, the DSN decides the access path only.
  Resolution stays lazy in both: connect, or use, before asserting a class.
- ADR 0035 — one transport-neutral base and a thin class per DBD is the shape
  the hook specialises along. The connector registry of that ADR is part of
  (e) and unchanged.
- ADR 0057 — its MSSQL note ("a storage pinned to `DBIO::MSSQL::Storage` is
  not driver-detected, so whether it becomes `DBIO::MSSQL::Storage::Sybase` on
  a `dbi:Sybase:` DSN is the driver's to make sure") is answered here: by the
  hook. `_connect_params_dsn` is asked on the declared class at
  `connect_info`, before determination; a driver whose access-path classes
  build different DSNs keeps that in mind.
- ADR 0024 — no contract version moves (see Consequences).

## Addendum 2026-10-10 — the check meets registered classes only; switches follow the parent storage (karr k301)

Decided by the maintainer on 2026-10-09 after the first review of the
implementation. Five points, the first four built in core, the fifth accepted.

1. **The DBD check judges registered driver classes only.** It runs when the
   declared class, or an ancestor of it, is registered for a DBD
   (`_registered_dbd_drivers` is not empty). A private subclass of
   `DBIO::Storage::DBI` set as `storage_type` by hand and connected with
   `dbi:Pg:` is no longer told that DBD::Pg belongs to another driver, and
   throws nothing under `driver_strict`: it has no registered origin to be
   compared with. A subclass of a registered driver class stays under the
   check. This **supersedes** the sentence in Consequences that a class "set
   through `storage_type` by hand that is no driver's" is warned; that
   paragraph is left as written. A driver calling `_driver_mismatch` itself
   (the server check) is untouched.
2. **A storage without a schema inherits the switches.** Writer and bulk
   storages are built with `(ref $self)->new`, without a schema, and set
   `_parent_storage` to the storage they came from (dbio-sybase). Core declares
   `_parent_storage` as a plain accessor on `DBIO::Storage::DBI` (the same hash
   key, so a driver declaring it again is compatible) and `_driver_mismatch`
   reads `driver_strict` / `driver_warnings` from the storage's own schema,
   else from the schema of the nearest parent storage along `_parent_storage`
   (bounded depth, cycle-safe). With no schema at all: not strict, warns.
3. **The switches are, and stay, accessors of the schema.** Not connect
   attributes: `driver_strict` / `driver_warnings` in the attribute hash are
   unknown attributes since karr k327 and are refused loudly. The refusal now
   adds a sentence naming the accessor (`$schema->driver_strict(1)`), in the
   static form and beside an AccessBroker; the value is never in the message.
4. **The `isa` rule is incomplete, and what it leaves open is the driver's
   duty.** `DBIO::MSSQL::Storage::Sybase` inherits `DBIO::Sybase::Storage` and
   so passes the rule for a storage declared as `DBIO::Sybase::Storage`,
   although it is another product's class. The rule cannot tell an
   access-path class from the class of another product that inherits the
   declared one. No driver hook moves a declared storage into the class of
   another product, even one that inherits the declared class; that is the
   driver's obligation, not something core checks.
5. **Until dbio-mssql k37 stands, a declared MSSQL schema warns** -- accepted,
   nothing in core fights it. (dbio-mssql k37 and dbio-sybase k64 have since
   reached the drivers' `main`; where the hook takes effect the warning has no
   object. Not combatted in core, stated here for the record.)

Pinned by `t/storage/declared_driver_access_path.t`.

## Addendum 2026-10-10 — a driver declares the foreign DBDs it takes as its access path (karr k321)

Decided by the maintainer on 2026-10-09, option (a).

The addendum above narrowed the DBD check to registered driver classes and
named the inheritance of the adapted class as the whole declaration. That
leaves one honest case unanswered: a driver whose **transport is the DBD of a
foreign driver** and which deliberately does not inherit that driver's storage
(dbio-clickhouse over `DBD::mysql` / `DBD::MariaDB`). Its DSN is judged a
mismatch, since the registry gives the DBD to the MySQL storage and the
ClickHouse storage is neither its ancestor nor its subclass. Inheriting
`DBIO::MySQL::Storage` to silence the check is the wrong cure: it drags a
product's SQL dialect and capabilities into a storage that is not that
product.

**Mechanism.** `DBIO::Storage::DBI->register_access_path_dbd(@dbd_names)`,
called at load time on the driver's storage class:

    __PACKAGE__->register_access_path_dbd('mysql', 'MariaDB');

- The registry is kept **per declaring class**, not globally. A lookup walks
  the MRO of the storage being checked -- the adapted class, which contains
  the declared one -- so a subclass of the declaring class takes the same
  DBDs, while a sibling class or the parent does not.
- `_check_access_path_dbd` asks it **before** the registry question and
  returns silently for a declared DBD, under `driver_strict` too. Everything
  else is unchanged: an undeclared foreign DBD still warns, or is refused
  under `driver_strict`; no change to `@ISA`, to the generic detection path or
  to `_adapt_to_access_path`.
- Inheritance stays the normal way to say "this DBD is mine". The declaration
  is for DBDs whose driver storage is not inherited.

**Why not the two private method names as the contract.** Until now such a
driver overrode `_check_access_path_dbd`, with `_registered_dbd_drivers` and
`%_driver_registry` beside it. That makes the shape of core's check -- the
order of its questions, its argument list, the name of the lookup -- an API
that core cannot change without breaking a driver, and it asks every such
driver to re-implement the judgement instead of stating a fact. A declaration
states the fact (these DBDs are mine) and leaves the judgement to core, which
may refine it, as k301 just did, without a driver noticing.

**Consequence for dbio-clickhouse.** Its private override of
`_check_access_path_dbd` is replaced by one call,
`__PACKAGE__->register_access_path_dbd('mysql', 'MariaDB')` on its storage
class (a ticket on that board; the dispatcher files it). No contract version
moves: `_check_access_path_dbd` and the new methods are not part of the five
versioned base classes' public shape.

Pinned by `t/storage/declared_driver_access_path_dbds.t`.
