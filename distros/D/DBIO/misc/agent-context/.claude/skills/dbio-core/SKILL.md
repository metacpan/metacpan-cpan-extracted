---
name: dbio-core
description: Use when working in the DBIO core — components, result classes, AccessBroker, capabilities, or writing mock-storage tests.
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
- Shared test schemas are `DBIO::Test::Schema::*` in `dbio/lib/` (the OO-variant siblings are under Shared Schemas below); driver tests use them and define no result classes inline
- A standalone demo schema lives beside that namespace as a sibling (`DBIO::Test::FooSchema`, like the Moo/Moose/MooCake/MooseSugar schemas below): a no-arg `load_classes` walks `DBIO::Test::Schema::*` (`t/102load_classes.t`), and a class there with optional deps of its own would die the sweep on a box lacking them
- Optional dep skip:
  ```perl
  BEGIN { eval { require Moo; 1 } or plan skip_all => 'Moo not installed' }
  ```
  List in cpanfile as `suggests`, never `requires`
- Skips: a test skips on the capability it needs, found by trying it, and the skip names that capability. Rules and examples: skill `dbio-driver-development`, `references/platform-skips.md`
- Core test helpers beyond the mock storage: `DBIO::Test::Conformance` (shared case table for DDL, Diff and Bind, ADR 0060 — a driver subclass declares `conformance_answered_through`; async transports run the Bind list), `DBIO::Test::AsyncHarness` (live harness of an async transport), `DBIO::Test::AsyncParity` (the same ResultSet operations sync and async, compared; a transport's test class inherits it and declares deviations and capabilities, POD section *WRITING A TRANSPORT'S CLASS*), `DBIO::Test::Future` (deterministic Future), `DBIO::Test::StorageLayer` (structural check for extension dists), `DBIO::Test::Util::{LeakTracer,OverrideRequire,UmaskGuard}` (leak tracing, `require` override, umask restore).
- Every suite runs through `maint/capped-test` (live-testing rule 9, skill `dbio-driver-development`).
- **Mock storage cursor invariant (ADR 0046)**: the fake cursor's
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

A broker answers a connection's details — which database, and as whom; pass it to `connect` in place of a DSN and the storage asks it again for every new connection. It is a credential source (one identity, one set of credentials): routing and topology belong to `DBIO::Replicated`. Built-ins: `DBIO::AccessBroker::{Static,Vault,HostBound}`. Interface, connect forms, options beside the broker and the async rules: `references/access-broker.md`.

## OOP

- Core: `Class::Accessor::Grouped` + `Class::C3::Componentised` → [[dbio-perl-class-patterns]]
- Pure-Perl style baseline → [[dbio-perl-syntax]]
- Drivers: Class::Accessor::Grouped like core, no Moo/Moose (ADR 0022)
- `DBIO::Moo`/`DBIO::Moose` = optional result-class bridges (`suggests`), FOREIGNBUILDARGS + lazy rules → [[dbio-moo-moose]] (installed in core only)


## Capabilities and driver contracts

The five driver base classes (`Introspect::Base`, `Diff::Base`, `Deploy::Base`, `SQLMaker`, `Storage::DBI::Capabilities`) carry `$CONTRACT_VERSION`; a public-shape change bumps it and updates the tripwire `t/test/12_contract_version.t` (ADR 0024). A driver declares engine facts as capabilities with `_use_X`; deploy probes `transactional_ddl` before wrapping DDL in `txn_do` (ADR 0026), and the IF-EXISTS question is answered by `Diff::Op::should_emit_if_exists($storage)` alone. Upsert, EXISTS and set operations refuse when undeclared (ADR 0036, 0037, 0039). Contracts in full: `references/capabilities.md`; tiers and seam table: skill `dbio-driver-development`.

## Trace redaction (ADR 0025)

`redact_bind_value` is a class-level hook on `DBIO::Storage::DBI` that
the trace formatter consults for every bind value, before the value
lands in the trace stream. Display-only — the bind value going to
`$dbh->execute(@bind)` is untouched. Identity default (no change unless
installed).

A message never quotes credentials (ADR 0025 addendum): every site that puts
connect info into an exception, warning or debug line goes through
`DBIO::Util::mask_connect_secrets`, the one place that knows how. Core masks the
error a pool transport raises in `PoolBase::_spawn_connection`.

A message names the key, column or option, never the value. Error text that carries
engine output runs through `$storage->_mask_error_values($text, \@values, $statement)`;
a driver whose engine writes values in a form of its own overrides it and calls
`next::method`.
