# ADR 0066 — Database extensions are a declared list the driver runs; each extension knows its peers

- Status: accepted
- Date: 2026-10-16
- Tags: extensions, deploy, introspection, diff, drivers, composition, cross-driver, contract, relates-0006, relates-0024, relates-0032, relates-0060, relates-0064, relates-0065

## Context

A database extension adds to a database what the application's schema does
not declare: types, functions, operators, and, for some extensions, objects in
the application's own namespaces that the engine does not record as the
extension's. PostgreSQL has `CREATE EXTENSION` (PostGIS, Apache AGE,
pgvector); `create_graph` of AGE makes a schema per graph with a table per
label. DuckDB has `INSTALL` and `LOAD`, SQLite `load_extension`, MySQL and
MariaDB plugins and components, Oracle its options; SQLite's FTS5 and R*Tree
modules and Oracle Text keep shadow tables in the user's schema.

Deploy, introspection and diff (ADR 0006, ADR 0064) need three answers for
every extension a database holds:

- **which objects belong to the application model** and which to the
  extension;
- **what the extension adds to an object of the model** (PostGIS: geometry
  type and SRID of a column);
- **how a change of such an object is written or refused** (PostGIS: a new
  SRID is `USING ST_Transform(...)`, a new geometry type is refused).

Several extensions are active in one database at a time, and each answer has
to hold beside the others. The storage layers of ADR 0032 are the runtime
surface of an extension (`cypher`, `create_graph`, the async mirror); this
ADR covers the model: declaration, installed state, model, diff, and the
per-connection activation.

## Decision

### 1. The list

#### 1.1 An entry

One entry per database extension, keyed by the engine's own name
(`pg_extension.extname`, the DuckDB extension name, the SQLite module name):

| field | meaning |
|---|---|
| `name` | the engine's name, `postgis`, `age`, `vector` |
| `class` | the DBIO extension class (§2), resolved by the driver (§1.2) |
| `options` | the declaration's options: install schema, version condition, library path (SQLite) |

#### 1.2 Where it comes from: the schema's declaration

The list starts where the application starts: at its schema, which starts
from its driver (ADR 0059). The schema states which database extensions its
database has, in the driver's spelling; for PostgreSQL that is
`pg_extensions` as it is:

```perl
package MyApp::DB;
use DBIO Schema => -pg;
__PACKAGE__->pg_extensions('age', postgis => { schema => 'gis' }, 'citext');
```

The declaration is the driver's, so it exists only on a schema that chose
that driver.

That declaration is the list. Nothing else adds to it: an extension is not
pulled in by loading a component, and a schema that does not declare `age`
has no AGE rules, whatever is loaded in the process.

The driver resolves each declared name to its class:

- **a name the driver knows** — the driver keeps a fixed table of the
  family's extensions (`age` → `DBIO::PostgreSQL::Age::Extension`,
  `postgis` → `DBIO::PostgreSQL::PostGIS::Extension`). The class is loaded
  when the list is resolved; a distribution that is not installed refuses,
  naming the distribution;
- **a class the declaration names** — `vector => { class => '...' }` for an
  extension outside the family (§6); it wins over the table;
- **any other name** gets the driver's plain extension class, which has no
  rules: the extension is installed and kept, nothing else (`citext`).

The class is loaded and its interface version checked (§5.3) when the driver
resolves the list, before the first deploy or query that needs it. The table
maps names to existing classes; nothing is derived from a name.

An extension with a runtime surface (AGE: `cypher`, `create_graph`) names its
storage layer in its class (`storage_layer`, §2.1); the driver registers that
layer (ADR 0032 §2) for every declared extension that names one. The
declaration is thereby the one place an application writes, for the model and
for the runtime surface.

#### 1.3 Declared, installed, active

Three sets, kept apart:

- **declared** — the list of §1.2, per schema class. It is the
  application's statement of which extensions its database has. It never
  determines the driver (ADR 0032 §7): an extension class names the driver
  it belongs to as an assertion, checked once the DSN has decided the
  driver, i.e. at the first use after driver resolution, never at
  `connect`.
- **installed** — the database's answer, read by the driver over the
  connection a deploy works on: installed or not, version, schema, scope
  (database, connection, server). PostgreSQL reads `pg_extension`; SQLite has
  no catalog of loaded extensions, so there the extension's own `inspect`
  (§2.1) answers.
- **active** — the declared entries, each with its installed state attached.
  The rules of §2 run for exactly these, sorted by `name`. An extension that
  is installed but not declared is not in the list; the driver's base filter
  (PostgreSQL: the `pg_depend` member filter of `DBIO::PostgreSQL::Introspect`)
  still keeps its member objects out of the model.

A declared extension that is not installed has no objects to claim: its rules
see a model without them and answer nothing (the AGE probe of
`ag_catalog.ag_graph` does exactly this). The driver creates it where its
scope allows (§3).

### 2. The extension interface

#### 2.1 Methods

A DBIO extension is a class deriving from `DBIO::Extension` (core). Every
method has a default that does nothing, so an extension writes only what it
needs. All methods are class methods; anything an extension knows about the
database comes through `$ctx`.

```perl
package DBIO::PostgreSQL::PostGIS::Extension;
use base 'DBIO::Extension';

sub extension_interface { 1 }             # the core interface version implemented
sub name   { 'postgis' }                  # the engine's name
sub driver { 'DBIO::PostgreSQL' }         # assertion, checked after driver resolution

sub inspect    { my ($class, $ctx)          = @_; ... }  # phase 0: read the database
sub claims     { my ($class, $model, $ctx)  = @_; ... }  # phase 1: not the application's
sub annotate   { my ($class, $model, $ctx)  = @_; ... }  # phase 2: what I add to objects
sub verdict    { my ($class, $change, $ctx) = @_; ... }  # phase 3: one change, written or refused
sub activation { my ($class, $ctx)          = @_; ... }  # per connection, as data
sub storage_layer { undef }               # the runtime layer, if any (AGE: its Storage)
```

- **`inspect($ctx)`** is the only method with database access
  (`$ctx->dbh`). It returns the extension's state, a plain structure (AGE: the
  graphs and their schemas). Core stores it in the context, and in the model
  under the extension's name, read-only: a deploy never creates or drops it.
- **`claims($model, $ctx)`** returns the addresses of objects that are the
  extension's and not the application's (AGE: `[schema => $graph_schema]` for
  each graph). It reads, it does not change the model.
- **`annotate($model, $ctx)`** returns `[address, attribute, value]` triples
  for objects that stay in the model (PostGIS: `base_type`, `geometry_type`,
  `srid` on a column whose type lives in the PostGIS schema).
- **`verdict($change, $ctx)`** is asked by the driver for a change it is about
  to write: a column type change, today. It returns `undef` (not mine),
  `{ using => $expr }`, or `{ refuse => $message }`.
- **`activation($ctx)`** returns data, not statements:
  `{ load => 'age', search_path => ['ag_catalog'] }`. The driver turns the
  activation of all active extensions into the statements of a new
  connection (§3).
- **`storage_layer`** names the storage layer of ADR 0032 that carries the
  extension's runtime surface, or `undef`. The driver registers it for a
  declared extension; the layer stays what ADR 0032 makes it.

An address is the driver's: `[schema => $name]`, `[table => $key]`,
`[column => $table_key, $column]`, `[type => $key]` and so on, with the
driver's cascade (a claimed schema takes its tables, a table its columns,
indexes, triggers, keys). Core treats addresses as opaque values it sorts,
de-duplicates and compares.

#### 2.2 The context and the peers

`$ctx` carries, for one deploy and one connection:

- `peers` — the other active entries, name → `{ class, installed, version,
  schema, state }`, with each peer's `inspect` state;
- `self` — the extension's own entry and state;
- `driver` — the driver's helpers an extension may use (`quote_ident`,
  `qualified_key`, the address constructors);
- `connection_schema` (ADR 0065) and whether the deploy is restricted.

The peers are how an extension regulates its interaction with another one,
inside its own code: it reads which peers are active and yields or adapts.
There is no priority, no `before`/`after` between extensions, no registration
of hooks into another class.

#### 2.3 Phases and merge rules

The phases run in a fixed sequence; within a phase **every extension reads the
same input** and returns data, and core merges:

| phase | input of every extension | merge | conflict |
|---|---|---|---|
| 0 `inspect` | the connection | per extension, under its name | none possible |
| 1 `claims` | the driver's base model | union of addresses | none: claiming is idempotent |
| 2 `annotate` | the model after phase 1 | union of triples | the same address and attribute with two different values refuses, naming both extensions |
| 3 `verdict` | the change, the models after phase 2 | at most one answer per change | two different answers refuse; any `refuse` refuses the diff, all refusals listed |
| `activation` | the context | the driver composes | the driver refuses what it cannot compose (two libraries for one name) |

Phases 1 and 2 run on both sides of a diff, the live model and the target
model, with the same extension set.

#### 2.4 Order and commutativity

The list is ordered by `name`. The order decides only the sequence of
messages and of statements that do not depend on each other (several `LOAD`).
No result depends on it: each phase hands every extension the same input, and
the merges of §2.3 are unions with a refusal on conflict, so the result does
not depend on who ran first. Order independence is a property of the
protocol, not something each extension author has to arrange.

What the protocol cannot ensure on its own is that an extension stays inside
it: an extension that changes its input, keeps state between calls, or
answers differently depending on what ran before breaks the property. Core
therefore ships a **commutativity test**, `DBIO::Test::ExtensionSet`:

- given a driver, a set of extension classes and a source and target model
  (offline fixture) or a database (live), it runs the phases in **every
  permutation** of the set (all permutations up to five extensions; above,
  every rotation and its reverse), overriding the name order only inside the
  test;
- it asserts the same post-phase models on both sides, the same diff
  statements, the same activation, and per extension the same output in
  every position;
- it hands each extension a copy of its input and fails when the input came
  back changed.

A driver runs it over the extensions of its family; an extension
distribution runs it over itself and every extension it names as a peer.

### 3. Core and driver, building block by building block

| building block | where | why |
|---|---|---|
| the list's entry, its merge of declaration options, the refusal of two classes for one name | core | engine-independent |
| the spelling of the declaration (`pg_extensions`) and the table of the family's extension classes | driver | the names are the engine's; the declaration already is the driver's |
| registering an extension's storage layer | driver, through core's `register_storage_layer` | the layer machinery is ADR 0032's |
| `DBIO::Extension` with defaults, `extension_interface`, the refusal of §5.3 | core | one contract for every driver; the pattern of ADR 0024 |
| ordering, `$ctx` with the peer list, the phases, the merges and their refusals | core | they operate on opaque addresses and are the same for every engine |
| running the protocol inside deploy | core, in `DBIO::Deploy::Base` around `_introspect_current`, `_build_target_model` and `diff` | every driver deploy gets it without code of its own |
| `DBIO::Test::ExtensionSet` and the conformance cases (area "extensions" of the ADR 0060 table) | core states, driver answers | ADR 0060 |
| reading the installed state, and its scope | driver | `pg_extension`, `duckdb_extensions()`, `information_schema.PLUGINS`, `v$option`; nothing for SQLite |
| addresses, cascade, applying claims and annotations to the model | driver | the model is the driver's (ADR 0006, ADR 0007) |
| the base member filter | driver | catalog-specific (`pg_depend`) |
| creating, updating, dropping the extension, and whether a deploy may at all | driver | dialect (`CREATE EXTENSION ... WITH SCHEMA`, `INSTALL`/`LOAD`); a server-level plugin or an Oracle option is the DBA's, so there the deploy only checks |
| activation per connection | the extension supplies data, the driver executes | a session setting such as `search_path` has one owner: the driver composes it, the namespace of ADR 0065 first, then the extensions' entries in name order |
| the extension classes (AGE, PostGIS, pgvector) | the extension distribution | knowledge of one engine extension |

Where core holds nothing, it is because the matter is the engine's: what an
object is, how an extension is installed, and where its state is recorded.

### 4. Relation to the `dbio_deploy_class` chain and the introspector subclasses

The list **replaces** both, it does not build on them. Model knowledge of an
extension lives in its extension class and reaches the deploy through the
list; the driver's Deploy class runs the protocol.

- `dbio_deploy_class` names the driver's Deploy class and has one owner, the
  driver storage. A storage layer does not define it; the set of chainable
  hooks of `DBIO::Storage::Composed` (ADR 0032, addendum 2026-10-15) is empty.
- The Deploy and Introspect subclasses of the extension distributions
  (`DBIO::PostgreSQL::Age::Deploy`, `::Age::Introspect`,
  `DBIO::PostgreSQL::PostGIS::Deploy`, `::PostGIS::Introspect`) become
  stubs; their rules move into `DBIO::PostgreSQL::Age::Extension` and
  `DBIO::PostgreSQL::PostGIS::Extension`. No introspector class is
  synthesised.
- The process-wide diff registries of the driver
  (`DBIO::PostgreSQL::Diff::Column->register_using_hook`,
  `DBIO::PostgreSQL::Diff->register_diff_class`) are driver-internal. An
  extension's diff rules reach the diff through `verdict`, and so apply only
  to a schema whose list holds that extension.

Why replace: an introspector or Deploy class per extension makes the
cooperation of two extensions a property of class composition, which
depends on the composition order and on every class calling the next one.
The list keeps each extension's rules in one class with one input, and the
cooperation is the protocol's.

### 5. Lifecycle: an extension comes, goes, changes its interface

#### 5.1 An extension is added

The next deploy has it in the target model (the temporary database creates
it), the live database does not: the diff creates it. Its claims and
annotations apply to both sides from that deploy on.

#### 5.2 An extension is removed from the list

It is no longer declared. For the deploy it is an installed, undeclared
extension: a restricted deploy keeps it, an unrestricted one drops it, as the
driver does for every undeclared extension. What it made at runtime (AGE
graphs) is dropped with it; `pg_schemas` restricts the deploy, and the diff
summary names the extension (Decisions, 4).

#### 5.3 The interface changes

- `DBIO::Extension` carries the interface version core implements, and the
  set it supports. An extension states the version it implements
  (`extension_interface`).
- A version outside core's set **refuses when the driver resolves the list** with a
  `DBIO::Exception` naming the extension, its version, core's set and which
  side to upgrade. No warning mode.
- A new optional method with a do-nothing default does not change the
  version. A changed signature, a changed meaning of a return value, or a
  new required method does.
- An extension whose `driver` is not the resolved driver refuses at the first
  use after driver resolution, naming both.
- An extension may state the engine versions it understands (AGE 1.5 to
  1.8); an installed version outside refuses the deploy, never the connect.

### 6. A third extension: pgvector, or an application's own

A third extension needs no change in core, in the driver or in another
extension: a class, and the declaration naming it.

```perl
package MyApp::DB::Extension::Vector;
use base 'DBIO::Extension';

sub extension_interface { 1 }
sub name   { 'vector' }
sub driver { 'DBIO::PostgreSQL' }

# vector(n): the dimension is part of the type; a change of it is refused.
sub verdict {
  my ($class, $change, $ctx) = @_;
  return undef unless $change->{kind} eq 'column_type'
    && ($change->{old_info}{data_type} // '') =~ /\bvector\(/;
  return { refuse => "column $change->{column_name}: the dimension of a vector is not converted" };
}

package MyApp::DB;
use DBIO Schema => -pg;
__PACKAGE__->pg_extensions(vector => { class => 'MyApp::DB::Extension::Vector' });
```

Once a family distribution ships a class for an extension, the driver's
table names it and the declaration needs no `class`.

The rules for every extension, family or not:

1. One class per engine extension; `name` is the engine's name.
2. It states `extension_interface` and `driver`, and derives from
   `DBIO::Extension`.
3. Only `inspect` touches the database. The other methods are functions of
   their arguments: no changes to the input, no state between calls, no
   globals.
4. It never determines the driver (ADR 0032 §7), changes no `@ISA` of a
   storage, Deploy or Introspect class, and registers nothing into a driver
   registry.
5. It answers only for what is its own. Where another extension's presence
   changes its answer, it reads `$ctx->{peers}`; it does not ask core for an
   order.
6. It passes `DBIO::Test::ExtensionSet` over itself and the extensions it
   names as peers.

The documentation lives in two places: `DBIO::Extension` ("WRITING AN
EXTENSION": interface, phases, rules above, the test) and each driver's POD
(its addresses, its cascade, what a deploy may do with an extension, and the
form of its declaration).

## Example: AGE and PostGIS

```perl
package MyApp::DB;
use DBIO Schema => -pg;
__PACKAGE__->pg_extensions('age', postgis => { schema => 'gis' });
```

The schema says what its database has; that is all the application writes.
The driver resolves the list, by name: `age` →
`DBIO::PostgreSQL::Age::Extension`, `postgis` →
`DBIO::PostgreSQL::PostGIS::Extension`, and registers the AGE storage layer
the AGE class names. The order of the declaration does not enter it.

| | `age` | `postgis` |
|---|---|---|
| `inspect` | `name`, `namespace` of `ag_catalog.ag_graph`, when `to_regclass` finds it | nothing; the installed state (schema `gis`) is in its entry |
| `claims` | `[schema => $s]` for each graph schema; the driver's cascade takes the label tables, their columns, indexes, triggers, sequences | none: its own types and functions are `pg_depend` members |
| `annotate` | none | `base_type`, `geometry_type`, `srid` on each column whose type lives in its schema |
| `verdict` | none | column type change: another SRID → `{ using => 'ST_Transform(...)' }`; another geometry type, or geometry ↔ geography → `{ refuse => ... }` |
| `activation` | `{ load => 'age', search_path => ['ag_catalog'] }` | none |
| `storage_layer` | `DBIO::PostgreSQL::Age::Storage` | none |
| state in the model | the graphs, read-only | none |

The interactions the maintainer named, and where each one lives:

- *For PostGIS, the graph schemas of AGE are not its model.* No code in
  PostGIS: phase 2 sees the model after the claims of phase 1, so a geometry
  column a user put into a label table is gone before PostGIS annotates.
- *For AGE, geometry columns belong to PostGIS.* AGE has no column rules
  today. When it gets one (a `verdict` on a label table's columns, say), it
  answers `undef` for a column whose type belongs to an active `postgis`
  peer, read from `$ctx->{peers}{postgis}{schema}`.

The two rule sets are disjoint today: AGE takes whole objects out, PostGIS
adds attributes to objects that stay. Applied one after the other, in either
order, they give the same model. The protocol keeps that property when a
third extension or a new rule arrives, and the commutativity test checks it:
for this pair, the orders (`age`, `postgis`) and (`postgis`, `age`), offline
on a fixture with a graph schema holding a geometry column, and live in
`dbio-postgresql-age` against a database with both extensions.

## Cross-check against other drivers

| engine | where an extension lives | installed state | objects outside the engine's own record (claims) | what a deploy may do | the interface |
|---|---|---|---|---|---|
| PostgreSQL | database | `pg_extension` | AGE graph schemas | create, update, drop | fits as above |
| DuckDB | `INSTALL` per host, `LOAD` per database instance | `duckdb_extensions()` (installed, loaded, version) | rarely; extension functions sit in the system catalog | `INSTALL`/`LOAD` as activation, no drop | fits; scope "connection", `annotate` for e.g. `GEOMETRY` of `spatial` |
| SQLite | `load_extension` per connection, nothing in the file | none: the extension's `inspect` answers (a probe of its function or metadata table) | shadow tables of FTS5 and R*Tree, SpatiaLite's metadata tables | activation only (library path from the declaration's options) | fits; the reason `inspect` is the extension's and the catalog read the driver's |
| MySQL / MariaDB | server (plugins, MySQL components) | `information_schema.PLUGINS`, `mysql.component` | rarely | check only: refuse when missing, never install or drop | fits as check-only |
| Oracle | database options installed by the DBA | `v$option`, `dba_registry` | Oracle Text `DR$` tables and Spatial index tables in the user's schema | check only | fits; `claims` carries the most weight here |
| ClickHouse | engines and table functions built into the server | `system.table_engines`, `system.table_functions` | none | nothing | not needed: the driver has no declaration of extensions and refuses one, like ADR 0065 §3 |

The interface needs nothing engine-specific beyond what §3 gives the driver:
the scope and what a deploy may do are the driver's answers, the installed
state is the driver's catalog read or the extension's `inspect`.

## Rationale

- **One place per extension.** Everything a deploy has to know about AGE is in
  one class with one input; there is no second class whose composition
  decides whether it is used.
- **Order independence by construction.** The same input for every extension
  of a phase, merges that are unions, a conflict refused: the result cannot
  depend on order, and the test checks that each extension keeps to the
  protocol.
- **Scoped to the schema that declares it.** An extension's rules apply to a
  schema whose list holds it, not to every schema in the process.
- **The driver gives only the dialect.** Addresses, cascade, catalog read,
  DDL and activation are engine knowledge; the protocol, the contract and the
  tests are not, and live once in core.
- **Loud on mismatch.** Interface version, driver, engine version and
  conflicting answers each refuse with a message naming both sides.

## Consequences

- Core gains `DBIO::Extension`, the protocol (in `DBIO::Deploy::Base` or a
  module it uses), `DBIO::Test::ExtensionSet`, and conformance cases. The contract versions of
  `DBIO::Deploy::Base`, `DBIO::Introspect::Base` and `DBIO::Diff::Base`
  (ADR 0024) change.
- `DBIO::Storage::Composed` has no chainable hooks; `dbio_deploy_class` is the
  driver's.
- The driver shortcut gives the schema the driver's declarations: a schema
  made with `use DBIO Schema => -pg` has `pg_extensions`, as one that loads
  the `PostgreSQL` component does.
- dbio-postgresql: `pg_extensions` resolved into the list (the table of
  family classes, the `class` option), installed-state reader, addresses and
  cascade, plain extension class, registration of the named storage layers,
  activation composition in the connect path next to
  `_set_connection_schema`, the protocol wired into its Deploy; the global
  registries stay internal.
- dbio-postgresql-age and dbio-postgresql-postgis: one extension class each;
  Deploy and Introspect subclasses become stubs; the storage layers keep the
  runtime surface and are registered by the driver. The schema components
  `DBIO::PostgreSQL::Age` and `DBIO::PostgreSQL::PostGIS` stay as the
  distributions' overview documentation; an application does not load them
  to get the extension.
- dbio-sqlite and dbio-duckdb follow with their reader and addresses once the
  PostgreSQL pair runs; MySQL, Oracle as check-only when a consumer asks.
- Downstream work is filed per repo after acceptance; the core part (k346) changes no driver.

## Decisions

Maintainer's decisions of 2026-10-16 (karr k346):

1. **Name to class.** The driver keeps a fixed table of the family's extension
   classes; a declaration outside the family names its `class` (Â§1.2).
2. **PostGIS's result-side parts.** The PostGIS extension class names the
   geometry inflation component as well, and the driver applies it for a
   declared `postgis`.
3. **Activation is in the list.** `LOAD 'age'` and `ag_catalog` on the
   `search_path` are the activation data of Â§2.1. The driver composes the
   `search_path`: the namespace of the connection (ADR 0065) first, then the
   extensions' entries in name order.
4. **An extension taken off the list.** The declaration is the statement. An
   unrestricted deploy drops an installed, undeclared extension together with
   the objects it made at runtime; `pg_schemas` restricts the deploy; the diff
   summary names the extension.
5. **Interface versions.** Until the family's first release core accepts
   exactly the current interface version; from then on the current and the
   previous one, for one release.
6. **Interface version 1** is `inspect`, `claims`, `annotate`, `verdict`,
   `activation` (and `storage_layer`). `install_steps` and `diff_steps` come
   as interface version 2 with their first consumer.
7. **`postgis_topology`** is its own entry with its own class, one engine
   extension per entry. Whether its topologies are runtime schemas is
   measured in the driver's work.

## Addendum 2026-10-16 (k347)

`components` is an optional class method of `DBIO::Extension`, beside the
methods of §2.1 and outside interface version 1. It returns the list of
result-component class names the extension brings (PostGIS: the geometry
inflation component of Decision 2); the driver applies them for a declared
extension. Its default is the empty list. Like every optional method with a
do-nothing default it does not change the interface version (§5.3), and the
method list of §2.1 stays interface 1.
