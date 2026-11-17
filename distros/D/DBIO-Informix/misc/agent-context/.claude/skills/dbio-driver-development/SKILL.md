---
name: dbio-driver-development
description: Use when building or extending a DBIO database driver — storage class, deploy/introspect/diff, capabilities, async transport.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO Driver Development

A DBIO driver is a separate CPAN distribution binding DBIO to one engine. This file is the
door; depth is in `references/` — load the file the task needs.

| Task | Read |
|---|---|
| Deploy, introspect, diff, index DDL, conformance, SQLSTATE errors | `references/deploy-introspect-diff.md` |
| Capability tiers, connect/DSN seams, explain, set operations, upsert, Cake types | `references/storage-seams.md` |
| Composing storage roles, DateTime parser | `references/storage-class.md` |
| Async adapter (`future_io`), ev backend, AccessBroker, LISTEN/NOTIFY | `references/async-transport.md` |
| Extension (AGE, PostGIS, tenant add-on): declared list, extension class, storage layer | `references/extension-layers.md` |
| Live suites, `capped-test`, `live-preflight`, resource caps, the maintainer's cluster (`dbio-db`) | `references/live-testing.md` |
| Skipping a test on a missing capability or platform | `references/platform-skips.md` |

```
User → DBIO::Schema → declared driver (component / -shortcut pins storage_type)
                    → Storage class → SQLMaker → capabilities
```

| Family | Base | Returns |
|---|---|---|
| DBI-based (Pg, SQLite, MySQL, …) | `DBIO::Storage::DBI` | blocking |
| Async transport (`DBIO::PostgreSQL::EV`, `DBIO::Async`) | `DBIO::Storage::Async` | Future |

## The declared driver (ADR 0059)

**A schema always declares its driver**; the DSN names the DBD and decides nothing else.
The declaration pins the driver's *base* storage class as `storage_type`, in two places:
the driver component's `connection()` and the shortcut (`use DBIO Schema => -pg`, class
`DBIO::Shortcut::pg`, `sub apply { DBIO->apply_driver($_[1], 'PostgreSQL') }`; for a
Result class `apply_driver` also loads `<Name>::Result` when it exists).

```perl
package DBIO::PostgreSQL::Storage;
use base 'DBIO::Storage::DBI';
__PACKAGE__->register_driver('Pg' => __PACKAGE__);
```

- No schema without a driver (ADR 0067): `DBIO::Schema::connection` refuses a schema whose
  storage class resolves to the generic `DBIO::Storage::DBI`; the generic storage has no
  driver and is never guessed into one. `DBIO->driver_for(@connect_info)` is the only way
  from a DSN to a driver (details: dbio-core).
- Driver resolution is lazy (first `dbh` access, not `connect`).
- **Several access paths** (own DBD, ODBC, another client): define
  `_adapt_to_access_path($dbd)` on the base class. Afterwards the storage must still be
  `isa` the declared class, or core puts it back and throws. A server that is something
  else: `$self->_driver_mismatch('…')` and stay in your driver; never bless into another
  product's class. Each access-path class inherits the class its DBD is registered for.
  A DBD that names no driver (ODBC, ADO, a proxy) is the declared driver's own
  `_adapt_to_access_path` to handle; `DBIO->driver_for` throws on it.
- `$dbd` is the live handle's DBD, else the DSN's; `undef` for a connection coderef that
  has not run. `$ENV{DBI_DRIVER}` never stands in; a DSN with an empty driver part
  (`dbi::…`) and a connect-info without DSN, broker or coderef throw (ADR 0057).
  A schema that only generates SQL connects with `connect('dbi:Pg:')`.
- A DBD that is a foreign driver's transport: `register_access_path_dbd(@dbd)`.
- The driver is declared (ADR 0067): core detects nothing from the DSN and no registry
  moves a storage into another product (`register_connector_driver` throws); a driver
  adapts in `_adapt_to_access_path`.
- `driver_strict` / `driver_warnings` are schema accessors, never connect attributes.

## Driver structure

1. **Component** `DBIO::X` — base `DBIO::Base` (never `DBIO::Schema`); pins `storage_type`
   in `connection()`. Users: `use DBIO Schema => -x` or `load_components('X')`.
2. **Storage** `DBIO::X::Storage` (required) — class data (`sql_quote_char`,
   `datetime_parser_type`, `sql_maker_class`), capability declarations, `last_insert_id`,
   optional `_exec_svp_*`, `with_deferred_fk_checks`, `bind_attribute_by_data_type`,
   `connect_call_*`, `dbio_deploy_class` (the driver's alone, never a layer's; ADR 0064, 0066),
   `_ddl_sql_dialect`.
3. **SQLMaker** `DBIO::X::SQLMaker` (optional) — dialect, operators via `expand_op`
   (`$opts{expand_op}{op} ||= sub { my ($self, $op, $val, $col) = @_; … }`; the key is
   the operator in `{ op => val }`, not the field).
4. **Result component** `DBIO::X::Result` (optional) — column/table features.
5. **Deploy / DDL / Introspect / Diff** — see reference. Every SQL driver has them.
6. **Test::Conformance** `DBIO::X::Test::Conformance` — see reference.

Storage roles are plain packages composed with `use base` + `use mro 'c3'`, never by
Exporter import (details: `references/storage-class.md`).

## Capabilities in one paragraph

Declare static facts with `__PACKAGE__->_use_X(0|1)` in the storage class, probed facts
with `sub _determine_supports_X`; never force on the instance. An undeclared capability
reads 0 and its core method throws — declare every one the engine has (`transactional_ddl`,
`supports_exists_query`, `supports_upsert`, …). Three tiers, ADR 0041; full text in
`references/storage-seams.md`.

## Messages never quote credentials

Any text carrying connect info goes through `DBIO::Util::mask_connect_secrets`; own stack
traces through `masked_longmess` / `masked_confess` / `masked_cluck` (ADR 0025 addendum).

## Messages never quote values

A message names the key, column or option, never the value. Engine error text runs through
`$storage->_mask_error_values($text, \@values, $statement)`; a driver whose engine writes
values in a form of its own overrides it, calls `next::method` and masks that form.

## Distribution layout

```
lib/DBIO/X.pm                 component          lib/DBIO/Shortcut/<key>.pm   -shortcut
lib/DBIO/X/Storage.pm         storage (required) lib/DBIO/X/{SQLMaker,Result,Util,Adapter}.pm
lib/DBIO/X/{Deploy,DDL}.pm, Introspect*/, Diff*/ lib/DBIO/X/Test/Conformance.pm
t/ (offline), docs/adr/, dist.ini ([@DBIO], heritage = 1, share_skill lines),
cpanfile, .claude/skilletor.json + driver skills (dbio-<driver>[-database]), CLAUDE.md
```

CLAUDE.md of a driver starts from `docs/driver-claude-md-template.md` in core.

Naming: dist `DBIO-X`; `DBIO::X`, `DBIO::X::Storage`, `DBIO::X::SQLMaker`; async adapter
`DBIO::X::Storage::Async` (future_io), `DBIO::X::EV` (ev-bound).

## Testing

- Offline: `DBIO::Test->init_schema(no_deploy => 1, storage_type => 'DBIO::X::Storage')`
  and `is_same_sql_bind`; assert SQL through the mock storage. The mock path declares
  `DBIO::Test::Storage`, the fake driver; `storage_type` there makes it a fake over your
  storage (ADR 0067 §4). With `dsn`/`connect_info`, `storage_type` is mandatory —
  `DBIO::Test::Schema` declares no driver. The driver's own test helper
  (`DBIO::X::Test`) declares its driver by default.
- Live: DSN env vars from `dbio-db env <db>` (`references/live-testing.md`).
- A test skips on the capability it needs, found by trying it, with the reason in the skip
  (`references/platform-skips.md`).
- **Every suite runs through `../dbio/maint/capped-test`** (live-testing rule 9); before a live
  suite `maint/live-preflight`.
- Driver tests run against the *installed* core: `dzil install` in core after a finished
  core ticket.
- Extensions assert structure with `DBIO::Test::StorageLayer`, their declared set with
  `DBIO::Test::ExtensionSet` (ADR 0066); async transports build their live harness on
  `DBIO::Test::AsyncHarness` and run `DBIO::Test::AsyncParity` over it (their test class
  inherits it and declares deviations and capabilities); the shared case table is
  `DBIO::Test::Conformance`.

## Conventions a reviewer checks

Each has an ADR; read it before deviating.

- **Contract version on base classes** (ADR 0024): a change that shifts the public shape of
  `Introspect::Base`, `Diff::Base`, `Deploy::Base`, `SQLMaker` or
  `Storage::DBI::Capabilities` bumps `$CONTRACT_VERSION` and updates the tripwire
  `t/test/12_contract_version.t`.
- **Trace redaction** (ADR 0025): the `redact_bind_value` hook on `DBIO::Storage::DBI` is the
  one seam for bind values in trace output; install it once on the storage class, trace
  callbacks carry no redaction logic.
- **DDL transactional safety** (ADR 0026): DDL runs in `$storage->txn_do` only after probing
  `$storage->_use_transactional_ddl`. A driver that declares nothing is non-transactional,
  which is right for MySQL, Oracle, DB2, Sybase, Informix and for SQLite, whose rebuild path
  needs `AutoCommit=on`.
- **IF EXISTS** (ADR 0026): the IF-EXISTS question is answered by
  `should_emit_if_exists($storage)` alone; it is the only emit site in Diff.
- **Mock storage cursor** (ADR 0046): the SQL the fake cursor captures equals the SQL a real
  cursor would have run, so new test infrastructure on the fake storage goes through
  `$storage->_select_args`.
- **Exceptions**: throw `DBIO::Exception->throw(...)` or a typed subclass.
- **Capability declarations**: `mk_group_accessors(use_dbms_capability => …)`, the shape of
  `DBIO::Storage::DBI::Capabilities`; one capability system.
