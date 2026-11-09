---
name: dbio-postgresql
description: Load when working on the DBIO::PostgreSQL driver — component API, JSONB querying, DDL and deploy, enums, indexes, introspection.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::PostgreSQL

Hierarchy: cluster → database → schema (namespace) → table/type/function/index/trigger/policy.

## Component Loading

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('PostgreSQL');
# connection() pins storage_type to +DBIO::PostgreSQL::Storage
```

`use DBIO Schema => -pg` (stub `DBIO::Shortcut::pg`) pins the same storage
class **without** loading the component: such a schema has no `pg_schemas`,
`pg_extensions`, `pg_deploy` … of its own. On a result class `use DBIO -pg`
loads `DBIO::PostgreSQL::Result`.

## Three Layers

| Layer | Class | Purpose |
|-------|-------|---------|
| Database | `DBIO::PostgreSQL` (Schema comp) | schemas, extensions, search_path, settings |
| Namespace | `DBIO::PostgreSQL::PgSchema` subclass | enums, composite types, functions |
| Table | `DBIO::PostgreSQL::Result` (Result comp) | pg_schema, indexes, triggers, RLS, CHECK, extra DDL |

### Database

```perl
__PACKAGE__->pg_schemas(qw( public auth api ));
__PACKAGE__->pg_extensions(qw( pgcrypto uuid-ossp vector ));   # pgvector's extension is named "vector"
__PACKAGE__->pg_search_path(qw( public ));
__PACKAGE__->pg_settings({ 'default_text_search_config' => 'pg_catalog.german' });
```

What each one does beyond being stored:

- `pg_schemas` — declaring any makes a deploy **restricted**: its diff
  introspects only these schemas, creates and updates declared extensions and
  drops none. With none declared the deploy owns the database and drops every
  extension not in `pg_extensions`.
- `pg_extensions` — `CREATE EXTENSION IF NOT EXISTS` ahead of everything;
  `Deploy` checks them against `pg_available_extensions` first and dies naming
  the missing one.
- `pg_search_path` — the `search_path` of every connection of the schema
  (sync and each `future_io` pool connection; karr k121): `SET search_path`
  ahead of `on_connect_do`, which can still replace it. Order: declared
  entries, schemas the declared extensions name (one without a schema adds
  nothing), the extensions' activation; `$user` is written `"$user"`. Nothing
  declared: nothing set. The connect key `schema` wins and the list is not
  read there. The install script writes nothing for it (it no longer ends
  with `SET search_path`); a table or view without a `pg_schema` is created
  in the first existing schema of the installing session's path.
- `pg_settings` — one `DO` block per entry that runs
  `ALTER DATABASE <current_database()> SET key = 'value'`. Install only: a
  default for new sessions, and not part of what the diff compares.

### PgSchema

```perl
package MyApp::DB::PgSchema::Auth;
use base 'DBIO::PostgreSQL::PgSchema';
__PACKAGE__->pg_enum('role_type' => [qw( admin moderator user guest )]);
__PACKAGE__->pg_type('address_type' => { street => 'text', city => 'text', zip => 'varchar(10)' });
__PACKAGE__->pg_function('update_modified_at' => q{ CREATE OR REPLACE FUNCTION auth.update_modified_at() ... });
```

Enum values keep their declaration order. The fields of a composite type are a
hash and are written in name order (`city`, `street`, `zip`). A function's SQL
is written as given.

The class does not name its namespace. The schema class binds it — after
`pg_schemas(...)`, which resets every binding, and with the PgSchema class
loaded (the DDL generator calls it by name):

```perl
package MyApp::DB;
__PACKAGE__->pg_schema_class('auth' => 'MyApp::DB::PgSchema::Auth');
```

### Result

```perl
package MyApp::DB::Result::User;
use base 'DBIO::Core';
__PACKAGE__->load_components('PostgreSQL::Result');
__PACKAGE__->pg_schema('auth');    # → auth.users
__PACKAGE__->table('users');

__PACKAGE__->add_columns(
  id       => { data_type => 'uuid', default_value => \'gen_random_uuid()' },
  role     => { data_type => 'enum', pg_enum_type => 'auth.role_type' },
  tags     => { data_type => 'text[]' },
  metadata => { data_type => 'jsonb', default_value => '{}' },
);

__PACKAGE__->pg_index('idx_users_tags'   => { using => 'gin', columns => ['tags'] });
__PACKAGE__->pg_index('idx_users_active' => { columns => ['role'], where => "role != 'suspended'" });
```

- A type string (`data_type`, `pg_enum_type`, `pg_type_name`) is written as
  given. `pg_enum_type => 'role_type'` is the column type `role_type`, which
  the server looks up along the session's `search_path` — name the schema
  (`auth.role_type`) for a type outside it.
- `pg_index`: `columns`, `using`, `opclasses`, `where`, `expression` (in place
  of `columns`), `include`, `with`, `unique`. pgvector: `hnsw` has no default
  operator class and must name one; `ivfflat` defaults to `vector_l2_ops`.
- `pg_trigger`: `when`, `event`, `execute`, `for_each` (default `ROW`).
- `pg_rls`: `enable`, `force`, `policies => { name => { for, roles, using, with_check, restrictive } }`
  (`restrictive => 1` writes `AS RESTRICTIVE`; default permissive).
- `pg_check_constraint(name => $expr)`, `pg_extra_ddl(@sql)`,
  `pg_fk_constraints_from_rels(0|1)` (FOREIGN KEY from `belongs_to`; on by
  default, `0` switches a class off; `is_foreign_key_constraint => 0` in a
  relationship's attributes writes no key for it. A `belongs_to` to a class that
  is not loaded or a table outside the deploy refuses the install unless it
  says that, karr k120).
- A pgvector column promotes `resultset_class` to `DBIO::PostgreSQL::ResultSet`
  (`nearest_neighbors`) and inflates/deflates; a `tsvector` column inflates too.

**Names and SQL.** Every name a declaration gives (schema, table, column,
index, trigger, policy, constraint, type, extension, role, a `pg_search_path`
entry, each dotted part of a `pg_settings` key) is written as an identifier by
the server's rule, `DBIO::PostgreSQL::Util::quote_ident`: bare when plain lower
case and no key word, quoted otherwise — `MixedCase` stays `MixedCase`. A
`pg_search_path` entry or `pg_settings` key already in double quotes is refused
with the unquoted form. What a declaration documents as SQL (`where`,
`expression`, `using`, `with_check`, `execute`, a `\'...'` default, type
strings, `pg_extra_ddl`, function and view SQL, an index's `using`, `with` and
`opclasses`) is written as given. Values go through `quote_literal`. Nothing
else writes a name into DDL.

## One class, several namespaces (connect key `schema`)

```perl
my $a = MyApp::DB->connect($dsn, $user, $pass, { schema => 'tenant_a' });
my $b = MyApp::DB->connect($dsn, $user, $pass, { schema => 'tenant_b' });
$a->pg_deploy->install;              # creates tenant_a, installs into it
$a->resultset('User')->all;          # tenant_a.users
```

The namespace is the connection's (core ADR 0065, here ADR 0008); nothing of
it is class data, so one class is connected for many namespaces at once.

- Every connection — sync and each async pool connection — gets
  `SET search_path TO <namespace>, <extension schemas>` ahead of
  `on_connect_call`/`on_connect_do` (`Storage::_set_connection_schema`). The
  rule is `Util::connection_search_path`: namespace, then the schema of each
  declared extension in order, `public` for one that names none and when none
  is declared. `pg_search_path` is not read.
- The install script of such a connection carries itself: every extension
  `WITH SCHEMA` (declared or `public`), `CREATE SCHEMA IF NOT EXISTS
  <namespace>`, `SET search_path` (once, at the head; the script does not
  end with it), the objects unqualified. PostgreSQL puts an unqualified object into the first
  schema of the path that *exists* — the script never relies on the session.
- `Deploy->_schema_filter` is `[ <namespace> ]` for that schema object,
  ahead of `pg_schemas`: the diff sees the namespace alone, drops no
  extension, and a `CREATE EXTENSION` it writes names its schema and, where that
  schema is not `public`, is behind a `CREATE SCHEMA IF NOT EXISTS` of it
  (the diff cannot see that schema; karr k131).
- Refused in the install (`refusing to write the install DDL: ...`): an
  extension whose schema (declared or `public`) is the namespace, a
  `pg_schema_class` binding, a result class with a `pg_schema`, a table name
  with a schema. `pg_schemas` entries alone refuse nothing.
- The class writes its SQL without a schema. A multi-namespace class stays
  with `pg_schemas`/`pg_schema_class` and connects without the key.

## JSONB Querying

Operators auto-applied via `DBIO::PostgreSQL::SQLMaker` `expand_op` handlers.

### Containment `@>` / `<@`

Hashref/arrayref → JSON-encoded, sent as a bind with a `::jsonb` cast:

```perl
$rs->search({ 'me.data' => { '@>' => { status => 'active' } } });
# WHERE "me"."data" @> ?::jsonb        bind: {"status":"active"}

$rs->search({ 'me.tags' => { '@>' => ['admin', 'user'] } });
$rs->search({ 'me.data' => { '<@' => { role => 'guest' } } });

# Pre-encoded JSON string — bound as it is
$rs->search({ 'me.data' => { '@>' => '{"status":"active"}' } });

# Scalar ref — literal SQL, no binding
$rs->search({ 'me.data' => { '@>' => \'other_col' } });
# WHERE "me"."data" @> other_col
```

### Key existence `?` / `?|` / `?&`

Written as the operators, each `?` as `\?` (a bare `?` is a DBI placeholder),
so a GIN index over the column answers them — the functions
`jsonb_exists*()` behind them it does not (karr k121):

```perl
$rs->search({ 'me.data' => { '?'  => 'email' } });
# WHERE "me"."data" \? ?
$rs->search({ 'me.data' => { '?|' => [qw(email phone)] } });
# WHERE "me"."data" \?| ARRAY[?, ?]
$rs->search({ 'me.data' => { '?&' => [qw(name email)] } });
# WHERE "me"."data" \?& ARRAY[?, ?]
```

### JSONPath `@?` / `@@` (PG 12+)

```perl
$rs->search({ 'me.data' => { '@?' => '$.status == "active"' } });
# WHERE "me"."data" @\? ?::jsonpath
$rs->search({ 'me.data' => { '@@' => '$.score > 10' } });
# WHERE "me"."data" @@ ?::jsonpath
```

The `?` of the operator `@?` is written `\?`, a question mark that is no
placeholder; `as_query` shows `@\?`. DBD::Pg (3.7.1 or later, pinned) sends
`@?` for it, the async transports drop the backslash when they number
(`Util::number_placeholders`). Literal SQL writes the operator the same way: a
bare `@? ?` is two placeholders on every way.

### Path extraction DSL

```perl
use DBIO::PostgreSQL::JSONB qw(jsonb);

# Single key → ->>, nested path → #>>
jsonb('me.data', 'status')->eq('active');         # (me.data->>'status') = ?
jsonb('me.config', 'theme', 'color')->eq('dark'); # (me.config#>>'{theme,color}') = ?

# Comparisons: eq, ne, gt, ge, lt, le, like, ilike, is_null, is_not_null
jsonb('me.stats', 'score')->gt(100);
jsonb('me.data', 'name')->ilike('%smith%');

# ORDER BY
$rs->search({}, { order_by => jsonb('me.score', 'total')->as_order });
$rs->search({}, { order_by => { -desc => jsonb('me.score', 'total')->as_order } });

# Combine containment + path (OR)
$rs->search([
  jsonb('me.data', 'status')->eq('published'),
  { 'me.data' => { '@>' => { featured => \1 } } },
]);
```

The column given to `jsonb()` is written into the SQL as it is, unquoted. The
extracted value is text; cast in SQL for a numeric comparison.

## DDL & Deploy

```perl
my $sql = $schema->pg_install_ddl;     # the install script, ONE STRING
print $sql;                            # same as DBIO::PostgreSQL::DDL->install_ddl($schema)

my $deploy = $schema->pg_deploy;       # DBIO::PostgreSQL::Deploy
$deploy->install;                      # fresh install
$deploy->install_schema('tenant_42');  # CREATE SCHEMA IF NOT EXISTS, the bare namespace

# Diff: temp DB deploy + pg_catalog compare
my $diff = $deploy->diff;              # DBIO::PostgreSQL::Diff; dies here on a refusal
say $diff->as_sql;                     # the statements
say $diff->summary;                    # one line per operation
$deploy->apply($diff) if $diff->has_changes;

$deploy->upgrade;                      # diff + apply
```

The driver storage's `dbio_deploy_class` is the one place that names the deploy
class; a storage layer that defines it is refused (core karr k347). An extension
adds its rules through its `DBIO::Extension` class, not a deploy class (ADR
0066). `$schema->deploy`
and `$storage->deploy($schema)` install through it, with or without the
component, and execute no DDL file; `pg_deploy` returns an object of it. The
storage has no `deploy` or `deployment_statements` of its own (core ADR 0064):
`deployment_statements` is core's reader of a DDL file in `$dir` for every
schema -- it throws when there is none and asks no server. Install DDL comes
from `pg_install_ddl`.

### The install script

Order: extensions → `CREATE SCHEMA` (not `public`) → enums, composite types
and functions of the PgSchema classes, then an enum type per column with
`extra => { list => [...] }` and no `pg_enum_type` (`{table}_{column}_enum`)
→ tables, each with its indexes, triggers, RLS, CHECK constraints and
`pg_extra_ddl` → opt-in FOREIGN KEYs, after every table → views → one `DO`
block per `pg_settings` entry. No `SET search_path` at the end.

- One string, pieces separated by blank lines, each ending in its own
  semicolon (on a line of its own behind a closing `--` comment). It runs the
  same cut into statements by `Deploy` and as one piece by `psql -f`.
- A foreign key that cannot be written leaves a note,
  `-- skipped FK for rel NAME: REASON`, as a piece of its own. A deploy passes
  over it; it is seen in the script only.
- Views: non-virtual `DBIO::ResultSource::View` sources with a
  `view_definition`, by source name, each behind the views its
  `deploy_depends_on` names. A circle there is refused, and so is a view
  that two sources declare (same relation name):
  `refusing to write the install DDL: ...`.
- The schema is only read; a second call returns the same script. A schema
  without the component gets the component's defaults.

### What the diff does

Operations come in two halves: everything created or changed, in the order
schemas, extensions, types, sequences, functions, tables, columns, what a
sequence belongs to, views, indexes, triggers, policies — then every removal
in the reverse order. A column default that calls a sequence (what `serial`
is in the catalog) gets its `CREATE SEQUENCE` ahead of the table or column
(`Diff::Sequence`, every parameter of the target) and `ALTER SEQUENCE ...
OWNED BY` behind it (`Diff::SequenceOwner`). The sequence of an identity
column is part of the column and is not touched; a sequence only the database
has is never dropped, and one both have is compared only by its owner (no
`ALTER SEQUENCE` for type, increment, bounds). A changed index,
trigger or view is a drop (`replaced` true) followed by its create. A function,
a trigger, an index and a view are written as the text the catalog gives for
them, and compared by it.

**Refused** — building the operations dies with `refusing to diff: ...`, names
the object and the way out, and no statement is generated for anything:

- dropping a schema an extension the diff keeps is installed in;
- a relation of another kind in the target (table ↔ view ↔ materialized view);
  creating a foreign table, a partitioned table, a partition or a table that
  inherits; partition/inheritance on one side only; a partitioned table or
  materialized view UNLOGGED on one side only;
- a materialized view with another definition, or one the target keeps on a
  view that has another definition;
- a change to how an existing column is generated; a column that changes its
  type while a materialized view reads it (also through a view) or a view only
  the database has (a declared ordinary view is dropped and created again
  around the change); a column change at a partition or inheriting
  table instead of at the table it comes from;
- a column that changes from one composite type to another with other
  attributes (an enum or a composite target is otherwise converted with
  `USING col::text::type`, its default dropped ahead and set again behind);
- a type both sides have that changes other than by enum values added (each written `ADD VALUE ... BEFORE|AFTER`
at its place in the target's order, none at the end): an
  enum that lost or reordered a value, an enum or composite type the target
  declares empty (no values, no attributes) where the database has some, a
  composite type with other
  attributes (name, type, size or the collation of an attribute), a range
  with another subtype, collation, operator class, `canonical` or
  `subtype_diff` function, a type of another kind. A type moved to another
  schema or renamed is a create, `ALTER COLUMN ... TYPE ... USING`, and
  `DROP TYPE` (not refused);
- a drop of a table, a type or a schema that objects outside the model depend
  on (`DBIO::PostgreSQL::Diff::Dependents`, read into the `outside_dependents`
  model section): the views, materialized views, foreign keys, partitions and
  inheriting tables of a schema outside `pg_schemas` on a table; its columns,
  functions and domains on a type; the domains, operators, collations and the
  like in a schema. The message names each object, no values. No drop is
  written with `CASCADE`: the diff drops what the model holds first, and
  what neither knows stops at the server, whose transaction rolls back;
- an aggregate or window function to create or change, or one under the
  signature of a function or procedure (a function that becomes a procedure,
  or back, is dropped and created again when the signatures pair, differing
  at most in the mode IN; when they do not (INOUT or OUT argument, another
  argument name) under the same input argument types it is refused, naming the
  DROP to run by hand; the server refuses that DROP while
  a trigger or a column default uses the function, and the transaction around
  the statements leaves the database as it was; one only the database has is
  dropped, DROP AGGREGATE for an aggregate);
- a function, trigger, index or view to create without a definition in the
  target model (`DBIO::PostgreSQL::Diff::NoStatement`);
- a sequence of its own to create under the name the database holds as an
  identity column's sequence (identity made `serial`); the message carries
  `ALTER TABLE ... ALTER COLUMN ... DROP IDENTITY` as the way out;
- an index behind a PRIMARY KEY, UNIQUE or EXCLUDE constraint whose
  constraint cannot go with it (foreign keys of other tables point at it and
  stay, or the constraint is dropped and added again; a key the target drops
  or redirects is gone first and is no reason), or
  a constraint to create that the diff cannot write: EXCLUDE, a key with a
  sort order or operator class, a primary key under another name than the
  database's and with another definition (the same definition is renamed:
  `ALTER TABLE ... RENAME CONSTRAINT`, as is any UNIQUE; a nonunique index
  holding the target's name is dropped first and the unique one under another
  name renamed and taken), an index the run drops that a foreign key stands
  on, or that a foreign key the target creates would be bound to, an index of the database that
  `ADD CONSTRAINT ... USING INDEX` does not take (partial, expression, not
  btree, not valid, partitioned table). The message carries the `ALTER TABLE`
  that settles it. A key of the target is created as `ALTER TABLE ... ADD
  CONSTRAINT ... PRIMARY KEY|UNIQUE (cols)`, never as the bare index
  (`pg_get_indexdef` is the same text for both); a database that has it only
  as an index gets `ADD CONSTRAINT ... USING INDEX` (k139), after `ALTER INDEX
  ... RENAME TO` when the index has another name than the constraint. A constraint with
  another definition under its name is dropped and added again; one the
  target lacks is dropped by `ALTER TABLE ... DROP CONSTRAINT`, a unique index
  without a constraint by `DROP INDEX`;
- an object to create whose name differs only in case from one to drop —
  schema, table, column, type, an index behind a constraint
  (`DBIO::PostgreSQL::Diff::CaseOnly`; the message carries the `RENAME`).

An operation built by hand whose `as_sql` has no statement dies
(`NoStatement->throw`); nothing is ever written as a comment or placeholder.

Foreign keys (`Diff::ForeignKey`, ADR 0009) are compared, created and dropped:
a key the schema does not declare is dropped and the summary says so — except
a key into a table in neither model (a schema outside `pg_schemas`), which is
kept, neither compared nor dropped, and named `=fk: ... -- kept (target
outside the deploy)` in the summary (no operation, no change). A table only one
model has is inside the deploy.

Not diffed: CHECK constraints, `pg_settings`, FORCE RLS, a
changed policy under an unchanged name, attribute changes of a composite type,
removed enum values.

## Introspection

All via `pg_catalog`:

```perl
my $introspect = DBIO::PostgreSQL::Introspect->new(
  dbh           => $schema->storage->dbh,
  schema_filter => [qw( public auth )],   # optional; undef = all non-system schemas
);
my $model = $introspect->model;   # one hashref, built lazily
# keys: schemas, extensions, types (enums/composites/ranges), tables, columns,
#       indexes (access method + full pg_get_indexdef), triggers, functions,
#       policies (RLS), sequences, foreign_keys, check_constraints
# tables/columns/indexes are keyed by "schema.table":
#   $model->{tables}{'auth.users'}, $model->{columns}{'auth.users'}
```

There are no per-section accessor methods and no section objects — the model
hashref is the interface `DBIO::PostgreSQL::Diff` consumes.

- Views and materialized views are entries of `tables`, told apart by `kind`
  (`r` `v` `m` `f` `p`); there is no `views` section.
- A key is where the model files an object, not its name: take the names from
  the entry's `schema_name` / `table_name` (`Introspect->key_names`), never by
  splitting the key.
- What an installed extension owns is left out (only the extension is in the
  model), and so are functions PostgreSQL made as part of another object.
- An index entry's `columns` has one entry per index *key* position, `undef`
  where the position is an expression: `[undef]` for an expression index, in
  that one form whatever `pg_expand_array` is. INCLUDE columns are in
  `include_columns` only. The entry also says what stands behind it, from the
  catalog: `constraint_name` / `constraint_type` (`p`, `u`, `x`; `undef` for
  an index without a constraint), `referenced_by` (foreign keys pointing at
  that constraint), `opclasses` (non-default class, with its schema where the
  `search_path` does not find it) and `sort_options` (`DESC`, `NULLS FIRST`,
  ... per key column; no key of `pg_index` declares one).
- Reading the model leaves the session as it was: view definitions are read
  under an empty `search_path` set in a transaction or savepoint that is
  rolled back.

## Async & storage-layer extensions

Async is opt-in per connection: `connect($dsn, $user, $pass, { async => $mode })`.

- `ev` → the native `DBIO::PostgreSQL::EV` backend (dist `dbio-postgresql-ev`):
  LISTEN/NOTIFY, plus COPY and pipeline, which only this mode has. Registered
  once as a transport BASE on the driver storage
  (`register_async_mode(ev => ...)`).
- `future_io` → the loop-agnostic `DBIO::PostgreSQL::Storage::Async` transport
  (over DBD::Pg's `pg_async` binding), resolved by convention off the driver
  storage. Pooled CRUD + `txn_do_async` and LISTEN/NOTIFY (`listen`/`unlisten`/
  `notify`, `listen_alive`/`listen_reconnect`); advertises `on_connect_replay`,
  `listen`, `notify`, `broker_connect_options`. COPY and pipeline are NOT on
  this transport (they are `ev` only).

PostgreSQL extensions (AGE, PostGIS, …) are **declared**, not loaded: `__PACKAGE__->pg_extensions('age',
vector => { schema => 'extensions' })` names them (ADR 0066), and the driver resolves each name to a
`DBIO::PostgreSQL::Extension` class (`class` option for one outside the family table).
Loading an extension's component adds nothing to that list. The extension's
storage layer — still a **layer**, never a `storage_type` subclass (core karr k70),
registered with `$schema->register_storage_layer('DBIO::PostgreSQL::Ext::Storage')` —
carries only its connection-time activation (`LOAD`, `search_path`); core composes it
(C3) over the PG driver storage for sync, and its async mirror `…::Storage::Async`
over the resolved transport for async. The layer defines no `dbio_deploy_class`: the
driver stays the sole owner of deploy, and the extension's rules enter through
`DBIO::PostgreSQL::Deploy`. The driver component keeps choosing the driver BASE
(`storage_type('+DBIO::PostgreSQL::Storage')` in `connection()`), and the
`ev`/`future_io` registrations do not grow per extension.

The shared `DBIO::PostgreSQL::SQLMaker` always emits `?` (the sync DBI driver
needs it); the `future_io` transport rewrites `?`→`$N` **once**, in
`_transform_sql`, invoked internally by the inherited `_query_async` — callers
never shape. See skill `dbio-driver-development` for the composition + seam model.

Three rules that live in one place each, in `DBIO::PostgreSQL::Util` (it
depends on Carp and Exporter only, so `dbio-postgresql-ev` loads it too):

- `number_placeholders($sql)` — what `_transform_sql` calls, and the public,
  stable interface `dbio-postgresql-ev` shares. A `?` is numbered
  only where PostgreSQL reads SQL: not in `'...'`, `"..."`, `E'...'`,
  `$tag$...$tag$`, `--` or nested `/* */`. Everywhere else it is a
  placeholder, behind an operator character too (`<@?`, `@? ?` → `@$1 $2`),
  as DBD::Pg reads it at the dbh. `\?` is a literal question mark and loses
  its backslash (`@\? ?` → `@? $1`); `$N` already there passes through, `$N`
  beside a `?` placeholder is refused, and so are `undef` and a reference.
- `quote_dsn_value($value)` — how a `dbname`/`host`/`port` given by value
  (connect-info hash, `AccessBroker::Static`) is written into a `dbi:Pg:` DSN
  so libpq reads back exactly that value. The sync storage
  (`_connect_params_dsn`) and `future_io` (`_async_broker_conninfo`) both write
  through it, so both connections of a schema open the same database.
- `dsn_names_target($dsn)` — whether a whole `dbi:Pg:` DSN names a `dbname`,
  `host`, `port`, `hostaddr` or `service`. The sync storage
  (`_refuse_dsn_without_target`, at `_connect` and for a broker's answer) and
  `future_io` (`_pg_connect`) refuse a connection with a DSN that names none
  (`dbi:Pg:`), as they refuse connection parameters that name none; libpq
  would take the target from `PGHOST`/`PGDATABASE`. `connect('dbi:Pg:')` of a
  schema that only writes SQL is not a connection and is not refused.
- `quote_channel($name)` — LISTEN/NOTIFY channel names, refused beyond 63
  bytes instead of truncated.

A `future_io` error of the database's is a plain string — the text and a
newline, no file and line of this library: DBI's message for a refused
statement (`DBD::Pg::db pg_result failed: ERROR: ...`), DBI's connect message
with the password masked. Every handle carries a `HandleError` that raises it
(`_pg_raise`); the SQLSTATE is on the handle, not in the text. A refusal of
the transport's own (broker answer, conninfo, channel name, closed listen
connection, a statement `number_placeholders` refuses) is a `DBIO::Exception`
naming the caller's file and line (`_pg_refuse`): `Future` and `IO::Async`
frames are skipped, so the place is the caller's on a direct call, through the
pool and from a loop callback.

## Testing

Every suite runs through core's `maint/capped-test`, offline and live, and
never with `prove -j`:

```bash
../dbio/maint/capped-test prove -lr t/                 # offline: no DBIO_TEST_PG_* set
```

Live (needs **pgvector**): one run per database at a time, preflight first.

```bash
eval "$(<cihq-ocp>/umgebungen/dbio/dbio-db env postgresql)"   # maintainer's cluster: DBIO_TEST_PG_DSN/_USER/_PASS
# this repo works in its own database dbio_pg, not the dbio_test that env names
export DBIO_TEST_PG_DSN="${DBIO_TEST_PG_DSN/dbname=dbio_test/dbname=dbio_pg}" DBIO_TEST_PG_EXT_DSN="${DBIO_TEST_PG_EXT_DSN/dbname=dbio_test/dbname=dbio_pg}"
../dbio/maint/live-preflight && ../dbio/maint/capped-test prove -lr t/
```

Offline (fake storage):

```perl
my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::PostgreSQL::Storage',
);
```

Writing a live test:

- A DBI connection of the test's own comes from `t/lib/LiveServer.pm` only —
  `LiveServer->control_dbh(...)`, `->dbh_or_die(...)` — never a raw
  `DBI->connect`: a failed connect is reported without the password and ends
  the file as one failed test with a plan.
- Every file that reads `DBIO_TEST_PG_*` calls `LiveServer->require_server`
  behind its own skips. A server that is not there **fails** the file; it does
  not skip.
- `t/109-live-files-use-live-server.t` guards both, over every `t/*.t` and
  `t/lib/*.pm`.
- A file that diffs or introspects the WHOLE database works in a database of
  its own: `PrivatePgDatabase->create($tag)` (`t/lib/PrivatePgDatabase.pm`).
- `is_deeply` has no prototype: write `is_deeply scalar eval { ... }, $want,
  $name or diag $@` — a bare `eval` that dies is an empty list there and takes
  the test's name with it.

## Key Modules

| Module | Purpose |
|--------|---------|
| `DBIO::PostgreSQL` | Schema component (DB layer) |
| `DBIO::PostgreSQL::Storage` | DBI storage: RETURNING, upsert, savepoints, BYTEA, advisory locks, deferred FK checks |
| `DBIO::PostgreSQL::Storage::Async` | `future_io` async transport (DBD::Pg `pg_async`); `?`→`$N` seam |
| `DBIO::PostgreSQL::SQLMaker` | JSONB operators (`expand_op`), `ON CONFLICT`, `SKIP LOCKED`/`NOWAIT` |
| `DBIO::PostgreSQL::JSONB` | `jsonb()` path-expression DSL |
| `DBIO::PostgreSQL::Vector` / `::ResultSet` | `vector()` distance DSL, `nearest_neighbors` |
| `DBIO::PostgreSQL::Result` | Result comp: pg_schema, indexes, triggers, RLS, CHECK, extra DDL |
| `DBIO::PostgreSQL::PgSchema` | Base for PG namespace classes |
| `DBIO::PostgreSQL::DDL` | Generates the install script |
| `DBIO::PostgreSQL::Deploy` | Orchestrates install/diff/upgrade |
| `DBIO::PostgreSQL::Diff` | Compares introspected models; `Diff::*` one class per kind of object |
| `DBIO::PostgreSQL::Diff::CaseOnly` / `::NoStatement` | The two refusals shared by the `Diff::*` classes |
| `DBIO::PostgreSQL::Introspect` | Reads live DB via pg_catalog; generation contract — the source `DBIO::Generate` builds DBIO classes from |
| `DBIO::PostgreSQL::Util` | `quote_ident`/`quote_qualified`/`quote_literal`/`quote_role`, `quote_channel`, type modifiers, `number_placeholders`, `quote_dsn_value` |
