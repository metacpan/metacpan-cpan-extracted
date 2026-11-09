---
name: dbio-core
description: Load before editing DBIO ORM code — architecture, the component system, drivers, result classes, and the testing rules.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DBIO = DBIx::Class fork. Namespace `DBIO::`, SQL::Abstract (not ::Classic). Integrated: TimeStamp, Helpers. SQL::Translator optional (legacy deploy only).

## Architecture

```
DBIO::Schema → ResultSource → ResultSet → Row
Storage → DBIO::Storage::DBI
SQLMaker
```

## Components

`load_components('Foo')` resolves under `DBIO::`. `+` = absolute path.

```perl
__PACKAGE__->load_components('PostgreSQL');  # DBIO::PostgreSQL
__PACKAGE__->load_components('+My::Custom'); # absolute
```

Driver components override `connection()` to set `storage_type`; a driver
shortcut (`use DBIO 'Schema', -pg`) sets the same class. That pin **declares
the driver**, and a schema always declares one (ADR 0059): the declared storage
class stands, adapts itself to the DSN's access path within its own driver
(`_adapt_to_access_path`) and never becomes another driver's class. A DSN or
server that does not fit warns; on the schema, `driver_strict(1)` makes it an
error and `driver_warnings(0)` silences it.

No schema without a driver (ADR 0067). `DBIO::Schema::connection` refuses a
schema whose storage class resolves to the generic `DBIO::Storage::DBI` — made
with `use DBIO 'Schema'` (no shortcut), `use base 'DBIO::Schema'` or as a clone
alike; it is the one check, nothing checks at compile time. `storage_type` set on
the class or on a clone before connecting is a declaration. Where the driver is not known in
advance (loading a schema from a database) finding it is a function:

```perl
my $driver = DBIO->driver_for($dsn, $user, $pass, \%attrs);  # 'PostgreSQL'
my $schema = DBIO->schema_for($dsn, $user, $pass, \%attrs);  # connected, no sources
```

`driver_for` answers the exact driver `register_driver` maps the DSN's DBD to (a
coderef's: its handle's DBD), asks the server nothing, and throws for a DBD that
names no driver (ODBC, ADO, a proxy) — declare the driver there. It knows the
drivers in the registry's default mapping and those whose storage is loaded.
`schema_for` returns a connected schema of `DBIO::SchemaFor::<Driver>` (one class
per driver, shared) with that driver applied and no sources.

## Drivers

Examples; the full family and who owns what is in [[dbio-coordination]].

| Dist | Component | Storage |
|------|-----------|---------|
| DBIO-PostgreSQL | `DBIO::PostgreSQL` | `DBIO::PostgreSQL::Storage` |
| DBIO-MySQL | `DBIO::MySQL` | `DBIO::MySQL::Storage` |
| DBIO-SQLite | `DBIO::SQLite` | `DBIO::SQLite::Storage` |
| DBIO (core) | `DBIO::Replicated` | `DBIO::Replicated::Storage` (over the declared driver) |

`DBIO::Replicated` is a storage over a declared driver, not a driver: load it after
the driver (`use DBIO 'Schema', -pg` plus `load_components('Replicated')`, or
`load_components(qw(PostgreSQL Replicated))`). `backend_storage_class` defaults to
the declared driver's storage, and one given in the connect info is itself a
declaration; a replicated schema with neither is refused.

## Result Class

```perl
package MyApp::DB::Result::User;
use base 'DBIO::Core';
__PACKAGE__->table('users');
__PACKAGE__->add_columns(
  id   => { data_type => 'integer', is_auto_increment => 1 },
  name => { data_type => 'varchar', size => 255 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(posts => 'MyApp::DB::Result::Post', 'user_id');
```

Relationships: `belongs_to`, `has_many`, `has_one`, `might_have`, `many_to_many`.

`EncodedColumn` (ADR 0063, 0073; `encode_class` Bcrypt by default, Argon2 or Digest selectable) encodes every defined value set through the accessor, `new`, `create` or `update`; import a finished hash with `set_column` or `\[ '?', $hash ]`.

ResultSet chaining: `$schema->resultset('User')->search({active=>1})->search({role=>'admin'})->order_by('name')`

### find and the *_or_* helpers (ADR 0070)

`find(\%cond)` runs the whole condition as one AND and needs every column of one unique constraint as a concrete equality (defined scalar or `{ '=' => $v }`, top level, after scope and relationship values); else it throws and `search(...)->single` is the way. `key => '...'` names the constraint that has to be covered. `find_or_new`, `find_or_create`, `update_or_new`, `update_or_create` (and `_async`) look up by the one covered constraint only, the rest is data; several covered need `key`. User input goes in as `find({ id => $id })`.

### Mass assignment (ADR 0071)

What a hash assigns to the columns is checked: a value of the caller's (a column, or a relationship value resolved to foreign key columns) may not contradict an equality of the resultset's condition (`create on a scoped resultset: 'artist' is fixed to 7 by the condition, got 999`; same value and `undef` for `IS NULL` allowed); `is_guarded => 1` on a column (`add_columns`) makes `new_result`, `create`, `update(\%h)`, `update_or_create`, `populate` (void too) and multi-create throw, on a relationship it excludes multi-create; `set_column`, the accessor and `update` without a hash stay free. Scope values and parent keys inherited by `create_related` are no assignment. Multi-create and `add_to_*` fetch a related row with `find` only through a `belongs_to` (`is_depends_on`) whose hash covers a unique constraint, every other hash creates; uniqueness is no permission, `is_guarded` on the relationship or its foreign key is.

### Return types (ADR 0042)

No method changes its return type by context. `search`, `search_related`, `search_literal`, `search_like`, `slice`, the has_many/many_to_many accessors and `ResultSetColumn::func` throw in list context (`assert_no_list_context`): write `my @rows = $rs->search(...)->all`. The chain helpers `where`, `having`, `offset`, `join`, `select` (and `order_by`) always return a ResultSet.

### Column nullability and indexes

- A column without `is_nullable` is NOT NULL (ADR 0043); say `is_nullable => 1` for a nullable one.
- Indexes are declared once on the ResultSource (ADR 0061): `add_index_declaration`, read with `index_declarations` / `index_declarations_for($driver, \@allowed_keys)`. `DBIO::Cake::idx` writes only there; a driver's DDL emitter and diff read it. Attributes a driver cannot implement are refused, never simplified.
- `add_relationship` does no resolution at definition time (ADR 0054).

## Testing Rules

- Core tests MUST use `DBIO::Test::Storage` (fake). Never `dbi:SQLite` or real DB in core
- `DBIO::Test::Storage` is a declared fake driver: the mock path of `init_schema` declares it (with `storage_type`, a fake over that driver storage). `DBIO::Test::Schema` keeps no driver in its class — each use declares one; `init_schema(dsn => …)` requires `storage_type` (ADR 0067 §4)
- Driver integration: `DBIO_TEST_PG_DSN`, `DBIO_TEST_MYSQL_DSN`, etc.
- `t/` = tests; `xt/` = author tests
- Shared test schemas → `DBIO::Test::Schema::*` in `dbio/lib/` (see Shared Schemas below for the OO-variant siblings). Do NOT redefine result classes inline in driver tests
- Do NOT nest a new standalone demo schema under `DBIO::Test::Schema::*` — that namespace is walked by a no-arg `load_classes` sweep (t/102load_classes.t); a class there with its own optional deps (Moose/Moo/...) dies the sweep fatally on boxes lacking them, instead of skipping gracefully. Put it as a sibling instead (`DBIO::Test::FooSchema`), as done for the Moo/Moose/MooCake/MooseSugar schemas below
- Optional dep skip:
  ```perl
  BEGIN { eval { require Moo; 1 } or plan skip_all => 'Moo not installed' }
  ```
  List in cpanfile as `suggests`, never `requires`
- Core test helpers beyond the mock storage: `DBIO::Test::Conformance` (shared case table for DDL, Diff and Bind, ADR 0060 — a driver subclass declares `conformance_answered_through`; async transports run the Bind list), `DBIO::Test::AsyncHarness` (live harness of an async transport), `DBIO::Test::Future` (deterministic Future), `DBIO::Test::StorageLayer` (structural check for extension dists).
- Every suite runs through `maint/capped-test` (live-testing rule 9, skill `dbio-driver-development`).
- **Mock storage cursor invariant (karr core k55)**: the fake cursor's
  captured SQL must equal the SQL a real cursor would have executed.
  Any new test infra on the fake storage must route through
  `$storage->_select_args` to apply join pruning and complex-prefetch
  rewriting. The diff between fake-captured and as_query is a bug.

## Shared Schemas

| Schema | Layer | DDL |
|--------|-------|-----|
| `DBIO::Test::MooSchema` | Moo | `add_columns` |
| `DBIO::Test::MooseSchema` | Moose | `add_columns` |
| `DBIO::Test::MooCakeSchema` | Moo + Cake | Cake DDL |
| `DBIO::Test::MooseSugarSchema` | Moose + Cake | Cake DDL |

Each: Artist + CD, has_many/belongs_to, one custom + one default ResultSet.

## AccessBroker

A broker answers a connection's details — which database, and as whom. Pass it to `connect` in place of a DSN; the storage asks it again for every new connection.

```perl
use DBIO::AccessBroker::Static;

my $broker = DBIO::AccessBroker::Static->new(
  host     => 'localhost',
  dbname   => 'myapp',
  username => 'myapp',
  password => 'secret',
);

my $schema = MyApp::Schema->connect($broker);   # MyApp::Schema loads its driver component

# the connect options go beside the broker
my $schema = MyApp::Schema->connect($broker, {
  async         => 'future_io',
  on_connect_do => [ 'SET search_path TO app' ],
});
```

### Interface

A broker is a **CredentialSource**: one backend identity, one set of credentials. It does NOT route and does NOT own a host list — routing + topology belong to `DBIO::Replicated`. See `CONTEXT.md`.

| Method | Returns | Purpose |
|--------|---------|---------|
| `connect_info_for` | HASHREF or ARRAYREF | The answer: connection parameters `{dbname, host, port, user, password}`, or DBI form `[$dsn, $user, $password, \%attrs]` |
| `connect_info_for_storage($storage)` | same | Storage-aware version; default delegates to `connect_info_for` |
| `needs_refresh` | Bool | True if credentials need rotation |
| `refresh` | - | Perform credential rotation |
| `has_rotating_credentials` | Bool | True if credentials rotate |
| `is_transaction_safe` | Bool | False if rotating (default) |
| `for_host($host)` | broker view | One credential, pinned to one host (HostBound) |

A subclass implements `connect_info_for` (the base throws) or overrides `connect_info_for_storage`; the rest have defaults. The trailing `$mode` ('read'/'write') arg is **vestigial** — accepted for back-compat, ignored. Routing decides read vs write, not the broker.

### Implemented Brokers

| Broker | Answers | Use Case |
|--------|---------|----------|
| `DBIO::AccessBroker::Static` | connection parameters | Fixed details, transaction-safe |
| `DBIO::AccessBroker::Vault` | DBI form, `dbi_attrs` as `\%attrs` | TTL-based credential rotation |
| `DBIO::AccessBroker::HostBound` | its broker's shape, host/port bound in (DBI form: through the driver's `_bind_host_into_dsn`, which refuses forms it cannot translate) | One credential pinned to one host (via `for_host`) |

### Storage Integration

Broker form is `[ $broker ]` or `[ $broker, \%options ]` (`_is_access_broker_connect_info`). `connect_info` attaches the broker (`set_access_broker`), asks it (`current_connect_info_for_storage`) and normalises the answer like any other connect info; `_connect` asks again for every connection, so rotated credentials reach the next one.

- **An answer without a DSN** (connection parameters): the storage builds the DSN for the one DBD its class is registered for (`register_driver`), leaving out parts not given. The form is the driver storage's seam `_connect_params_dsn($driver, \%params)` (ADR 0057) — default `dbi:<DBD>:dbname=…;host=…;port=…`; core's ODBC storage refuses (no driver/data-source name to build from). The schema always declares its driver (ADR 0059, 0067), so the DBD is that driver's. A `dbname` that starts with `dbi:` is taken as the DSN; `host`/`port` beside it throw (they cannot go into it).
- **Options beside the broker** take what the attribute hash of every other connect form takes: DBI attributes, the DBIO connection attributes (`on_connect_do`, `quote_names`, …), `async`, `pool_size`. The connection itself — `dsn`, `user`, `password`, `dbh_maker`, `dbname`, `host`, `port` — is the broker's answer and throws beside it. This is how a broker answering connection parameters gets an async mode or any option at all.
- **A setting in both places** — beside the broker and in a DBI-form answer (Vault's `dbi_attrs`) — must have the same value (same plain value, both undef, or the very same reference), or the connect throws naming the setting, never its values (`_merge_access_broker_settings`). Checked in `connect_info` and again in every `_connect`.
- **Static connect info names its DSN** (ADR 0057 addenda, karr k306/k340): a hash needs `dsn` or `dbname`, connect info without DSN, broker or coderef throws, `$ENV{DBI_DSN}` / `$ENV{DBI_DRIVER}` never stand in. A DSN with an empty driver part (`dbi::…`) throws; a schema that only generates SQL connects with `connect('dbi:Pg:')`.
- **Connect key `schema`** (ADR 0065) names the namespace of a connection; a driver with namespaces implements `_set_connection_schema`, one without refuses the key.
- **With an async mode**, `pool_size` stays out of the owner's `DBI->connect`. The embedded backend gets `[ $broker ]` while the options hold only what the owner applies (mode, storage and SQL maker options; pooled connections replay `on_connect_*` from the owner). DBD attributes or `pool_size` beside the broker reach the backend as `[ $broker, \%options ]` only if its transport declares `broker_connect_options` in `transport_capabilities`; any other transport throws at first async use. `DBIO::Storage::Async::connect_info` takes that form: `pool_size` sizes the pool, the DBD attributes wait in `_access_broker_call_attributes` for the transport to merge into each connection.

`DBIO::Replicated` passes a broker (or a `for_host` view) through the master/replicant connect paths by identity — never merged into an options hash — and each backend, a storage of the declared driver, consumes it. The guard predicate is `DBIO::Util::is_access_broker($x)`.

## OOP

- Core: `Class::Accessor::Grouped` + `Class::C3::Componentised` → [[dbio-perl-class-patterns]]
- Pure-Perl style baseline → [[dbio-perl-syntax]]
- Drivers: Class::Accessor::Grouped like core, no Moo/Moose (ADR 0022)
- `DBIO::Moo`/`DBIO::Moose` = optional result-class bridges (`suggests`), FOREIGNBUILDARGS + lazy rules → [[dbio-moo-moose]] (installed in core only)

## Driver contract versioning (ADR 0024)

The five base classes out-of-tree drivers subclass carry
`$CONTRACT_VERSION` and a `contract_version()` accessor:

- `DBIO::Introspect::Base`
- `DBIO::Diff::Base`
- `DBIO::Deploy::Base`
- `DBIO::SQLMaker`
- `DBIO::Storage::DBI::Capabilities`

The contract version advances only when the public shape changes in a
way drivers can observe (new method, new capability, signature change).
Current contract: 1.3 for `DBIO::SQLMaker` (`operator_words`, ADR 0068),
`DBIO::Storage::DBI::Capabilities` (the `_adjust_bind_values` seam, k373),
`DBIO::Diff::Base` and `DBIO::Deploy::Base` (deploy hooks `_check_before_apply`
and `_execute_diff`, `allow_destructive`, `dry_run`, Diff conformance table 4,
ADR 0080); `DBIO::Introspect::Base` is at 1.2. Tripwire:
`t/test/12_contract_version.t`.

## DDL transactional safety + IF EXISTS (ADR 0026)

Two capabilities on `DBIO::Storage::DBI::Capabilities`, both default 0
(conservative):

- `transactional_ddl` — `__PACKAGE__->_use_transactional_ddl(1)` to opt
  in. Only true for engines where DDL is honoured inside a transaction
  (Pg yes, MySQL (any version) / Oracle / DB2 / Sybase / Informix no, SQLite
  explicitly NO — rebuild path needs `AutoCommit=on`).
- `supports_if_exists` — `__PACKAGE__->_use_supports_if_exists(1)` to
  opt in. Engines that parse `DROP TABLE IF EXISTS` etc.

Deploy/Base and DeploymentHandler probe the capability before wrapping
DDL in `$storage->txn_do`. A driver that does not opt in is treated
as non-transactional. For diff renderers: `Diff::Op::should_emit_if_exists($storage)`
is the single emit site — never reintroduce driver-name string matches.
The helper probes `_use_supports_if_exists` — the accessor the capability
registration actually mints. A capability named `X` mints `_use_X` and
`_supports_X`; probing a name nobody registers is silently inert.

## Atomic upsert (ADR 0036) and the EXISTS/set-operation seam (ADR 0037, 0039)

Two further capabilities, both default 0, both refusing rather than
degrading — an engine whose driver has not declared them throws instead of
falling back to a racier or differently-shaped query:

- `supports_upsert` — `__PACKAGE__->_use_supports_upsert(1)`. Gates
  `$rs->upsert`, the single-statement server-side upsert. Rendering the
  `on_conflict` clause belongs to the driver SQLMaker; the base generator
  throws rather than silently dropping it.
- `supports_exists_query` — `__PACKAGE__->_use_supports_exists_query(1)`.
  Gates `results_exist` and its two siblings. Paired with the storage hook
  `_exists_value_sql($inner_sql)`, which returns a complete statement
  yielding 1 or 0. Core's base rendering is the standard-conforming
  `SELECT CASE WHEN EXISTS <inner> THEN 1 ELSE 0 END`; only engines that
  also refuse a `FROM`-less `SELECT` override it with their dummy table
  (Oracle `DUAL`, DB2 `SYSIBM.SYSDUMMY1`, Firebird `RDB$DATABASE`).

All six set operations run through one hook without a flag (ADR 0039):
`_set_operation_keyword($op)`, asked with the canonical op name — `union`,
`union_all`, `intersect`, `intersect_all`, `except`, `except_all` — and
answering that operation's ANSI keyword by default (`'MINUS'` for `except` on
Oracle). It has two jobs, deliberately in one place: **spell** the operation
for this engine, or **refuse** it. An engine that has no `EXCEPT ALL` (Oracle
before 21c, SQLite, SQL Server) throws here, from its own driver, naming
engine and version. There is nothing for a caller to branch on, and a
refusal that names a version can only be written where that version is known
-- so refusal lives next to the rendering it refuses.
Override only the ops you have an opinion about and delegate the rest to
`$self->next::method($op)`; an unknown op is a *core* programming error and
the base throws, listing the six.

## Trace redaction (ADR 0025)

`redact_bind_value` is a class-level hook on `DBIO::Storage::DBI` that
the trace formatter consults for every bind value, before the value
lands in the trace stream. Display-only — the bind value going to
`$dbh->execute(@bind)` is untouched. Identity default (no change unless
installed).

A message never quotes credentials (ADR 0025 addendum): every site that puts
connect info into an exception, warning or debug line goes through
`DBIO::Util::mask_connect_secrets`, the one place that knows how. Core masks the
error a pool transport raises in `PoolBase::_spawn_connection`; never roll a
pattern of your own.
