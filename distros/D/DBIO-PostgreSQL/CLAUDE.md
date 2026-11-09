# CLAUDE.md — DBIO::PostgreSQL

This distribution tracks only what is its own: `.claude/skilletor.json`, its `dbio-postgresql*`
skills. The family skills, the shared agents (`dbio-release-manager`, `karr-coordinator`,
`dbio-adr-auditor`), the worker `dbio-worker-postgresql` (rendered from core's template with
the vars of `skilletor.json`) and the house rules are installed from the `dbio` core
repo by skilletor and are git-ignored, so a fresh clone has none of them until you run
`skilletor sync` (needs the `skilletor@getty` plugin and network access to the sources). Never
edit an installed copy — change the source in core. Everything named here refers to those. The
family-wide house rules (discipline, delegation, release) live in
`.claude/rules/.local.dbio-rules.md` — auto-loaded by Claude Code for the main agent and all
subagents.

## Delegation

Delegate behavior-relevant driver internals (Storage, SQLMaker, Introspect/Deploy/Diff,
types) to this repo's `dbio-worker-postgresql` instead of touching them yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-postgresql` (default), `dbio-release-manager`,
`karr-coordinator`.

## Core Concept: Three-Layer PostgreSQL Hierarchy

PostgreSQL has a real hierarchy that DBIO currently flattens:

```
PostgreSQL Cluster
  └── Database
       └── Schema (Namespace: public, auth, api, ...)
            ├── Table
            ├── View
            ├── Type (Enum, Composite, Range)
            ├── Function / Trigger
            ├── Sequence
            └── Index
       └── Extension (database-level, but schema-aware)
```

This module maps that hierarchy into DBIO with three component layers:

### Layer 1: Database (DBIO::Schema component)

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('PostgreSQL');

__PACKAGE__->pg_schemas(qw( public auth api ));
__PACKAGE__->pg_extensions(qw( pgcrypto uuid-ossp postgis ));
__PACKAGE__->pg_search_path(qw( public ));
__PACKAGE__->pg_settings({
    'default_text_search_config' => 'pg_catalog.german',
});
```

### Layer 2: PgSchema (new intermediate layer)

Models PostgreSQL schemas (namespaces) as first-class objects:

```perl
package MyApp::DB::PgSchema::Auth;
use base 'DBIO::PostgreSQL::PgSchema';

# Enums belong to a pg schema
__PACKAGE__->pg_enum('role_type'   => [qw( admin moderator user guest )]);
__PACKAGE__->pg_enum('status_type' => [qw( active inactive suspended )]);

# Composite types
__PACKAGE__->pg_type('address_type' => {
    street  => 'text',
    city    => 'text',
    zip     => 'varchar(10)',
    country => 'varchar(2)',
});

# Functions
__PACKAGE__->pg_function('update_modified_at' => q{
    CREATE OR REPLACE FUNCTION auth.update_modified_at()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.modified_at = NOW();
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
});
```

The schema class attaches the class to a namespace — after `pg_schemas(...)`,
which refuses once a binding is set, and with the PgSchema class loaded,
because the DDL generator calls it by name. The binding is the one source of
the namespace the class's definitions are installed into, and it never
restricts the deploy: only `pg_schemas` does, and it keeps the order it was
declared in. The class has no name of its own; an instance may be given one
with `PgSchema->new(pg_schema_name => 'auth')` (karr k103):

```perl
package MyApp::DB;
__PACKAGE__->pg_schemas(qw( public auth api ));    # the Layer 1 call
__PACKAGE__->pg_schema_class('auth' => 'MyApp::DB::PgSchema::Auth');
```

### Layer 3: Result (Result component)

```perl
package MyApp::DB::Result::User;
use base 'DBIO::Core';
__PACKAGE__->load_components('PostgreSQL::Result');

__PACKAGE__->pg_schema('auth');       # belongs to auth namespace
__PACKAGE__->table('users');          # → auth.users

__PACKAGE__->add_columns(
    id => {
        data_type     => 'uuid',
        default_value => \'gen_random_uuid()',
    },
    role => {
        data_type    => 'enum',
        pg_enum_type => 'auth.role_type',   # a type string, written as given:
                                            # name the schema, the search_path
                                            # above does not hold auth
    },
    tags => {
        data_type => 'text[]',
    },
    metadata => {
        data_type     => 'jsonb',
        default_value => '{}',
    },
    address => {
        data_type    => 'composite',
        pg_type_name => 'auth.address_type',
    },
    embedding => {
        data_type => 'vector(1536)',    # pgvector
    },
);

# PostgreSQL-specific indexes
__PACKAGE__->pg_index('idx_users_tags' => {
    using   => 'gin',
    columns => ['tags'],
});

__PACKAGE__->pg_index('idx_users_active' => {
    columns => ['role'],
    where   => "role != 'suspended'",   # partial index
});

__PACKAGE__->pg_index('idx_users_name_lower' => {
    expression => 'lower(name)',        # expression index
});

__PACKAGE__->pg_index('idx_users_embedding' => {
    using     => 'ivfflat',            # pgvector
    columns   => ['embedding'],
    opclasses => { embedding => 'vector_l2_ops' },  # ivfflat's default for vector; hnsw has none
    with      => { lists => 100 },
});

# Triggers
__PACKAGE__->pg_trigger('users_modified_at' => {
    when    => 'BEFORE',
    event   => 'UPDATE',
    execute => 'auth.update_modified_at()',
});

# Row Level Security
__PACKAGE__->pg_rls({
    enable   => 1,
    force    => 1,
    policies => {
        users_own_data => {
            for   => 'ALL',
            using => 'id = current_setting($$app.current_user_id$$)::uuid',
        },
    },
});
```

## Architecture

### Module Structure

```
lib/DBIO/
├── PostgreSQL.pm                        # Schema component (Database layer)
├── PostgreSQL/
│   ├── Storage.pm                       # PostgreSQL storage (replaces Storage::DBI::Pg)
│   ├── Storage/
│   │   └── Async.pm                     # future_io transport (async over DBD::Pg)
│   ├── SQLMaker.pm                      # PostgreSQL-specific SQL generation
│   ├── Adapter.pm                       # Portable base types → native PostgreSQL types
│   ├── Util.pm                          # Shared rules: identifiers, literals, type
│   │                                    #   modifiers, DSN values, placeholders, channels,
│   │                                    #   the search path of a connection
│   ├── Extension.pm                     # Plain extension class + family table (ADR 0066)
│   ├── PgSchema.pm                      # Base class for PG schema namespaces
│   ├── Result.pm                        # Result component
│   ├── ResultSet.pm                     # ResultSet with pgvector nearest_neighbors
│   ├── JSONB.pm, JSONB/Op.pm            # JSONB path expression helpers for queries
│   ├── Vector.pm, Vector/Op.pm          # pgvector distance-query helpers
│   ├── InflateColumn/
│   │   ├── Vector.pm                    # pgvector values
│   │   └── TSVector.pm                  # tsvector values
│   │
│   ├── Introspect.pm                    # pg_catalog → internal model
│   ├── Introspect/
│   │   ├── Schemas.pm
│   │   ├── Tables.pm                    # Every relation kind; a view with its definition
│   │   ├── Columns.pm
│   │   ├── Types.pm                     # Enums, Composites, Ranges
│   │   ├── Indexes.pm
│   │   ├── Triggers.pm
│   │   ├── Functions.pm
│   │   ├── Extensions.pm
│   │   ├── Policies.pm                  # Row Level Security
│   │   ├── Sequences.pm
│   │   ├── ForeignKeys.pm
│   │   ├── CheckConstraints.pm
│   │   ├── OutsideReaders.pm            # Views outside the filter that read a modelled column
│   │   ├── OutsideDependents.pm         # Objects outside the filter that stand on a table, type or schema to drop
│   │   ├── Normalize.pm                 # Pure normalization of introspected metadata
│   │   └── Parse.pm                     # Pure parsers for raw metadata strings
│   │
│   ├── Diff.pm                          # Compare two introspected models
│   ├── Diff/
│   │   ├── Schema.pm
│   │   ├── Table.pm
│   │   ├── Column.pm
│   │   ├── View.pm
│   │   ├── Type.pm
│   │   ├── Index.pm
│   │   ├── ForeignKey.pm
│   │   ├── Function.pm
│   │   ├── Trigger.pm
│   │   ├── Policy.pm
│   │   ├── Extension.pm
│   │   ├── Sequence.pm                  # CREATE SEQUENCE
│   │   ├── SequenceOwner.pm             # ALTER SEQUENCE ... OWNED BY
│   │   ├── CaseOnly.pm                  # Rule: a name in two spellings is refused
│   │   ├── Dependents.pm                # Rule: a drop with dependents outside the model is refused
│   │   └── NoStatement.pm               # Rule: no operation without a statement
│   │
│   ├── DDL.pm                           # DBIO classes → install DDL
│   ├── Deploy.pm                        # Orchestration: install, diff, upgrade
│   └── Test/                            # Result classes for the test suites
│       └── Conformance.pm               # answers the core's shared DDL case table (ADR 0060)
└── Shortcut/pg.pm                       # `use DBIO -pg`
```

### Deploy Flow (Test Deploy + Compare)

The key innovation: instead of trying to generate diffs from abstract representations,
we deploy to a temporary database and let PostgreSQL compare with itself.

```perl
my $deploy = DBIO::PostgreSQL::Deploy->new(
    schema => MyApp::DB->connect($dsn),
);

# --- Fresh install ---
$deploy->install;

# --- Upgrade via test-deploy ---
my $diff = $deploy->diff;
#   1. CREATE DATABASE temp_xxxx
#   2. Deploy desired schema from DBIO classes there
#   3. Introspect both DBs via pg_catalog
#   4. Compare the two models
#   5. DROP DATABASE temp_xxxx

say $diff->as_sql;
say $diff->summary;

$deploy->apply($diff);

# --- Or one-step ---
$deploy->upgrade;
```

### Introspection Strategy

All introspection goes through `pg_catalog`; `information_schema` is not read:

- `pg_catalog.pg_namespace` → schemas
- `pg_catalog.pg_class` + `pg_attribute` → tables, columns
- `pg_catalog.pg_inherits` → the partitioned table a partition belongs to and
  the parents of a table that inherits; `pg_attribute.attislocal` tells a
  column a table defines itself from one it only inherits
- `pg_catalog.pg_type` + `pg_enum` → types, enum values
- `pg_catalog.pg_index` + `pg_am` → indexes (incl. type: btree/gin/gist/brin/ivfflat)
- `pg_catalog.pg_trigger` → triggers
- `pg_catalog.pg_proc` → functions
- `pg_catalog.pg_extension` → extensions
- `pg_catalog.pg_policy` → RLS policies
- `pg_catalog.pg_depend` → what belongs to what: an extension's members
  (deptype `e`) and the internal parts of another object (deptype `i`, e.g. a
  range type's constructor functions) are left out of the model; extension →
  extension (deptype `n`) orders `CREATE`/`DROP EXTENSION`; the rows of a
  view's rewrite rule (`pg_rewrite`) give the relations a view reads and, by
  `refobjsubid`, the columns; a sequence's owning column (deptype `a`;
  identity `i`); the columns a policy, a trigger (WHEN, UPDATE OF) or a
  generated column reads (`depends_on_columns`), and the views outside the
  `pg_schemas` that read a modelled column (section `outside_readers`)
- `pg_catalog.pg_constraint` → FOREIGN KEY and CHECK constraints (PRIMARY KEY,
  UNIQUE and EXCLUDE come in only as their backing indexes)
- `pg_get_indexdef()`, `pg_get_constraintdef()`, `pg_get_triggerdef()`,
  `pg_get_functiondef()`, `pg_get_viewdef()` → exact DDL. A view definition is
  read under an empty `search_path`, so it is the same text in every session;
  the other texts are read under the session's `search_path` and name an
  object without its schema where that path finds it (karr k120, point 7)

### Diff Output

```perl
$diff->as_sql;
# ALTER TYPE auth.role_type ADD VALUE 'superadmin';
# ALTER TABLE auth.users ADD COLUMN avatar text;
# CREATE INDEX idx_users_avatar ON auth.users USING btree (avatar);
# DROP INDEX auth.idx_users_old;

$diff->summary;
#   ~type: auth.role_type +1 value(s) (superadmin)
#   +column: auth.users.avatar (text)
#   +index: idx_users_avatar (on auth.users)
#   -index: idx_users_old (on auth.users)

$diff->operations;
# Returns structured list of DBIO::PostgreSQL::Diff::* objects
```

## PostgreSQL Features Covered

The list is the target scope of the design, grouped by what `lib/` does today.
"Install" is the DDL `DDL.pm` generates from DBIO classes, "diff" is what
`Diff/*.pm` emits for an upgrade. `[P1]`–`[P3]` is the priority the design gave
each feature.

### Implemented: install and diff
- Schemas (namespaces): CREATE SCHEMA, DROP SCHEMA (RESTRICT; dependents outside the model are named and refused) — created before
  the extensions installed into them and dropped after them; the diff refuses
  to drop a schema that holds an extension it keeps. A connection opened with
  `{ schema => 'tenant_a' }` installs the class into that namespace (created
  when missing, looked up in `pg_namespace` first, so a role without CREATE on
  the database can use a namespace made for it; the same for the schema of a
  declared extension) and restricts its deploy to it; `pg_search_path` is not read
  there (ADR 0008); a diff over such a connection writes the
  `pg_namespace` lookup that creates a missing schema ahead of a `CREATE EXTENSION ... WITH SCHEMA` whose schema is
  not `public`, since the deploy sees the namespace alone (karr k131). Types
  and functions of such a connection are declared without a schema (enum
  column list, `pg_extra_ddl`) and land in the namespace;
  `pg_enum`/`pg_type`/`pg_function` need the refused `pg_schema_class`
  binding; the install script writes no `SET search_path` at its end, so
  the caller's session is left as it was. A declared `pg_search_path` is the
  `search_path` of every connection of the schema (sync and each `future_io`
  pool connection), set ahead of `on_connect_do`: the declared entries, then
  the schemas the declared extensions name, then the extensions' activation;
  nothing is set when none is declared (karr k121) `[P1]`
- Tables: CREATE/DROP TABLE, also UNLOGGED and the switch between the two
  (SET LOGGED/UNLOGGED, written in foreign-key order: to UNLOGGED the
  referencing table first, to LOGGED the referenced one first; two tables
  that reference each other and change together are refused); columns ADD/DROP/ALTER (type, NOT NULL, default,
  identity), column types as exact PostgreSQL strings; a change to an enum or
  composite type is written `USING col::text::type` with the default dropped
  and set again; a type change of a column a declared view reads drops those
  views (and the ones on them) ahead of the change and creates them again
  behind it, in one transaction, while a materialized view that reads it
  (directly or through such a view) and a view only the database has are
  refused by name; a type change under a policy, a trigger (WHEN, UPDATE OF),
  a generated column or a view outside the `pg_schemas` is refused by name
  with the statement that clears it; the diff refuses a composite-to-composite
  change of other attributes `[P1]`
- Enums: CREATE TYPE in declaration order, ALTER TYPE ADD VALUE — a value between
  or ahead of existing ones is written `BEFORE|AFTER` its neighbour (at the end, no position);
  values are never removed, a lost or reordered one is refused `[P1]`
- Indexes: any access method via `using` (btree, gin, gist, brin, hash, hnsw,
  ivfflat) — partial, expression, INCLUDE, operator classes, storage
  parameters; a changed index is dropped and recreated (ADR 0003) `[P1]`
- Identity columns: GENERATED ALWAYS/BY DEFAULT AS IDENTITY, incl. switching
  the kind; `serial`/`bigserial` as declared types. A column default that
  calls a sequence gets its `CREATE SEQUENCE` (all parameters) ahead of the
  table or column and `ALTER SEQUENCE ... OWNED BY` behind it; a sequence only
  the database has is not dropped, one both have is compared only by its
  owner; identity made `serial` is refused, `DROP IDENTITY` is the way out `[P1]`
- Extensions: the declaration is the list of ADR 0066 (`pg_extensions`, option
  `class` for an extension outside the family; fixed table age, postgis,
  postgis_topology in `DBIO::PostgreSQL::Extension`); the core protocol runs in
  `Deploy` (claims, annotations, verdicts), activation (`LOAD`, `search_path`)
  per connection, the diff summary names a dropped undeclared extension.
  CREATE/DROP EXTENSION, ALTER EXTENSION UPDATE, in the order the
  extensions depend on one another; a deploy restricted by `pg_schemas` drops
  none (ADR 0002 addendum). `pg_extensions('pgcrypto', vector => { schema =>
  'extensions' })` names a schema: install is `CREATE EXTENSION ... WITH
  SCHEMA` (the schema created ahead of it; it must be declared in `pg_schemas`
  unless `public`, which makes the deploy restricted), the diff moves a relocatable extension by `ALTER EXTENSION ...
  SET SCHEMA` and refuses a non-relocatable one (postgis, age) when the
  operations are built; a function body that names the old schema breaks after
  a move. The list form names no schema and is never moved. The schema a
  `CREATE EXTENSION` takes: the declared one; else, where the path has a
  server (Deploy, diff, temporary database), the one the control file fixes
  (age: ag_catalog, postgis_topology: topology, pg_cron: pg_catalog), written
  without the clause because the server creates that schema itself; else
  `public`. A declared schema that differs from the fixed one is refused
  before any statement. `DDL->install_ddl` asks no server: there an extension
  with a fixed schema must declare it. On a connection that names its
  namespace (connect key `schema`) one whose schema is the namespace is
  refused `[P1]`
- Composite Types: CREATE TYPE ... AS (...), DROP TYPE — attribute changes of
  an existing type, a range's subtype, collation, operator class, canonical
  and subtype_diff, an attribute's collation and a change of the kind of a
  type are refused (`refusing to diff`); a type renamed or moved to another
  schema is created, the columns follow by `ALTER COLUMN ... USING`, the old
  type is dropped `[P2]`
- Functions: CREATE OR REPLACE FUNCTION as declared (for triggers etc.), DROP
  FUNCTION, DROP PROCEDURE for a procedure; a routine that changes kind
  (function ↔ procedure) is dropped and created again where the two signatures
  pair (they differ at most in the mode IN), and refused where they do not
  (INOUT or OUT argument, another argument name) but the input argument types
  are the same, with the DROP to run by hand; an aggregate or window
  function is introspected without a definition, and one the diff would have to
  create or change is refused, one only the database has is dropped (DROP AGGREGATE for an aggregate) `[P2]`
- Triggers: BEFORE/AFTER/INSTEAD OF, per-row (default) or per-statement
  (`for_each`); a changed trigger is dropped and recreated `[P2]`
- Row Level Security: policies created/dropped by name with their roles,
  ENABLE/DISABLE, also for a table the diff creates. The diff writes a
  policy's kind (`AS RESTRICTIVE`) as the target has it; a policy of `pg_rls`
  declares it with `restrictive => 1`, else it is permissive. FORCE is set on
  install only, and the diff does not detect a changed policy under an
  unchanged name `[P2]`
- Views: CREATE VIEW (not OR REPLACE) for non-virtual `DBIO::ResultSource::View`
  sources, behind the tables and each behind the views its `deploy_depends_on`
  names (a circle is refused); the diff creates and drops a view as a view, in
  the order of the views it reads, and drops and recreates one whose definition
  changed together with the views on it `[P2]`

Two rules hold for every kind above (`DBIO::PostgreSQL::Diff/WHAT IS REFUSED`).
An object to create and one to drop whose names differ only in upper and lower
case are not taken for two: where the drop would lose something — schema,
table, column, type, an index a constraint may stand on — the diff is refused
and names the `RENAME` that settles it. And an operation the diff has no
statement for is refused when it is built; none is written as a comment or a
placeholder.

### Implemented: install only, no diff
- Database settings: `pg_settings` is stored on the database the install runs
  in (ALTER DATABASE ... SET, built around `current_database()`); a changed
  value is not carried by an upgrade
- Constraints: PRIMARY KEY and UNIQUE inline in CREATE TABLE, CHECK via
  `pg_check_constraint`, FOREIGN KEY via `pg_fk_constraints_from_rels` (on by
  default, `0` per class switches it off, `is_foreign_key_constraint => 0` on a
  relationship leaves that one out; ON DELETE/ON UPDATE as declared, one
  constraint per foreign key) or raw
  `pg_extra_ddl`. No index is written over the columns of a UNIQUE constraint.
  CHECK is introspected but has no diff class. The diff creates PRIMARY KEY and
  UNIQUE as constraints (`ADD CONSTRAINT`; a database that has only the index
  gets `ADD CONSTRAINT ... USING INDEX`, ADR 0003 addendum) and compares and
  creates FOREIGN KEYs (`Diff/ForeignKey.pm`, ADR 0009): a foreign key the
  target model does not declare is dropped and named in the summary (not one
  into a table in neither model, e.g. a schema outside `pg_schemas`: it is
  kept, neither compared nor dropped, and the summary says `kept (target
  outside the deploy)`), a target
  without a foreign-key section drops none, the deploy option
  `foreign_keys_not_valid` writes `NOT VALID`, and the `VALIDATE CONSTRAINT`
  behind it runs in a transaction of its own; model keys `deferrable` and
  `initially_deferred` on FOREIGN KEY and UNIQUE are read, compared (a change
  is drop + create, a rename alone keeps them) and written; a UNIQUE
  constraint declares them with `pg_unique_options` `[P1]`

### Introspection only
- Materialized views: introspected; the diff creates and drops one (and its
  indexes) and refuses a changed definition; no DBIO class can declare one `[P2]`
- Range Types: read from `pg_range`, and the diff renders CREATE/DROP TYPE for
  them, but no DBIO class can declare one `[P3]`
- Partitioned Tables: recognized as a table kind; no strategy, keys or bounds;
  the diff drops one and refuses to create one, and changes a column at the
  partitioned table, not at its partitions; an index or trigger of a
  partitioned table, which the server carries down to every partition, is not
  in the model there, so a trigger is written at the partitioned table only
  and an index `ON ONLY` it, with a `CREATE INDEX` and `ATTACH PARTITION` at
  each partition so that it is valid (one a partition has of its own stays
  and is diffed). The same holds for a table that
  inherits (INHERITS): its inherited columns are changed at the parent, and
  the diff refuses to create one or to change what a table belongs to `[P3]`
- Foreign Tables (FDW): recognized as a table kind; the diff drops one and
  refuses to create one; FDW management is parked on karr k36 `[P3]`
- Generated Columns (STORED, VIRTUAL on 18): the diff writes `GENERATED ALWAYS
  AS (expr) STORED|VIRTUAL` in CREATE TABLE and ADD COLUMN and refuses a change
  to an existing one; no way to declare one `[P3]`

### Not implemented
- ALTER SCHEMA (rename, owner) `[P1]`
- EXCLUDE constraints — nothing to declare one with short of raw
  `pg_extra_ddl` `[P1]`
- Tablespaces `[P3]`
- Domain Types `[P3]`
- Statistics objects (CREATE STATISTICS) `[P3]`

## Use Cases This Enables

### Multi-Tenant via PG Schemas
```perl
# One schema class, one PostgreSQL schema per tenant: the connection names
# the namespace, the class names none (karr k128, ADR 0008)
foreach my $tenant (@tenants) {
    my $schema = MyApp::DB->connect($dsn, $user, $pass,
        { schema => $tenant->schema_name });
    $schema->pg_deploy->install;   # creates the namespace, installs into it
}
# every connection of such a schema -- sync and each async pool connection --
# has search_path = <namespace>, then the schemas of the declared extensions
# (the control-file schema or public for one that names none, public when none is declared); its deploy is
# restricted to the namespace
```

### API Schema Separation
```perl
__PACKAGE__->pg_schemas(qw( internal api ));
# internal.users → full table
# api.users_view → restricted view for API layer
```

### Extension-Heavy Stacks
```perl
__PACKAGE__->pg_extensions(qw(
    pgcrypto        # gen_random_uuid()
    postgis          # geography, geometry
    pg_trgm          # trigram similarity search
    vector           # pgvector: AI embeddings
    timescaledb      # time-series
));
```

## Dependencies

- DBIO (from ../dbio/) — its class system (`use base`, components,
  Class::Accessor::Grouped). This distribution needs neither Moo nor Moose;
  core supports both as optional integrations
- DBI + DBD::Pg
- DateTime::Format::Pg
- PostgreSQL 14+ (for full feature coverage)

## Testing Strategy

- **Unit tests** (no DB): annotation parsing, DDL generation, diff logic
- **Integration tests** (need PostgreSQL): introspection, deploy, roundtrip
- `t/120-conformance-ddl(-live).t` runs the core's shared DDL case table, one
  schema per case; `t/122-conformance-ddl-text.t` checks the same cases offline
- `t/140-mask-error-values.t` (offline table of server texts) and
  `t/141-error-values-live.t` (a marker bound per form, also where the server
  reads it as a name; sync and future_io, which holds no value at the handle
  after the statement) hold that an error text names types, columns and constraints, never values
  (`DBIO::PostgreSQL::Util::mask_error_details`, ADR 0010)
- A live test works in the database `DBIO_TEST_PG_DSN` names; one that
  installs, diffs or upgrades a whole schema gets a temporary database of its
  own (`t/lib/PrivatePgDatabase.pm`: CREATE/DROP DATABASE)
- A live test takes its own DBI connections from `t/lib/LiveServer.pm`, never
  from a raw `DBI->connect`: a connect that fails is reported with its secrets
  masked, and with the DSN set and no server there the file fails with a plan
  (`t/109-live-files-use-live-server.t` guards it)

### Offline and live runs

Every suite runs through `capped-test` (house rule 9), recursive, never `prove -j`:

```bash
../dbio/maint/capped-test prove -lr t/          # offline: no DBIO_TEST_PG_DSN, touches no database
```

A live run takes its database from the `DBIO_TEST_PG_*` variables. This repo works in a
database of its own, `dbio_pg` — never in the shared default `dbio_test`, never in another
repo's database:

```bash
export DBIO_TEST_PG_DSN='dbi:Pg:dbname=dbio_pg;host=localhost'
export DBIO_TEST_PG_USER='dbio'
export DBIO_TEST_PG_PASS='secret'
../dbio/maint/live-preflight && ../dbio/maint/capped-test prove -lr t/
```

`DBIO_TEST_PG_EXT_DSN` (same form) names the database of the extension tests. The
PostgreSQL instance must have **pgvector** installed — some tests (loader, Cake schema
generation) require the `vector` extension; the extension tests also use `age` and
`postgis`. One run per database at a time. How a live database is provided, the caps and
the preflight are in "Live testing" of `.claude/rules/.local.dbio-rules.md`.

### The maintainer's cluster, and the pod scripts

The maintainer's own live databases (`dbio-db up|env postgresql`, namespace `dev-dbio`) are
described in the last section of `.claude/rules/.local.dbio-rules.md`, *Maintainer-only live
infrastructure*; there `dbio-db env postgresql` names `dbio_test`, which this repo
replaces by `dbio_pg` in `DBIO_TEST_PG_DSN` and `DBIO_TEST_PG_EXT_DSN`.

`maint/k8s/pg-pod.yaml` is the manifest `dbio-db` starts the standing PostgreSQL pod
from; keep it. The script `xbin/dbio-pg-k8s` that once built the same pod is gone (karr
k121): `dbio-db` provides the database.

## Important Design Decisions

### Why not SQL::Translator?
- SQL::Translator is database-agnostic → loses PostgreSQL-specific features
- Its diff algorithm produces suboptimal/incorrect migrations for PostgreSQL
- Enum support is broken, partial indexes not supported, JSONB treated as text
- We don't need abstraction — we're PostgreSQL-specific by design

### Why test-deploy instead of class-to-DDL diff?
- PostgreSQL comparing with itself is always correct
- No need to maintain a DDL generator that might drift from reality
- Catches edge cases automatically (column ordering, implicit defaults, etc.)
- The temp DB deploy is fast (schema-only, no data)

### Why a separate PgSchema layer?
- PostgreSQL schemas are fundamental to its architecture
- Enums, types, functions all belong to a schema — not to a table
- Multi-tenant patterns depend on schema isolation
- Without it, everything gets dumped into "public" and we lose structure

### Column type handling
- Don't try to map PostgreSQL types to abstract types and back
- Store the exact PostgreSQL type as declared
- Introspect the exact PostgreSQL type from pg_catalog
- Compare types as PostgreSQL strings — no lossy translation layer

