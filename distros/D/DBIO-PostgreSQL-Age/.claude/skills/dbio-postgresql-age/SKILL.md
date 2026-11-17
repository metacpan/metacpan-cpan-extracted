---
name: dbio-postgresql-age
description: Load when working on the DBIO::PostgreSQL::Age driver — Apache AGE graph data, vertices and edges, Cypher via cypher(), agtype results.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::PostgreSQL::Age — Apache AGE Graph

## Setup

The schema declares its driver (`-pg`); the Age component is a storage layer and declares none, so a schema with only the component is refused at connect (core ADR 0067). AGE is a database extension of the declared list (core ADR 0066): declare it with `pg_extensions('age')` — loading the component does not. The driver then runs `Age::Extension` in deploy (graph schemas are kept in the model and never dropped); deploy installs the declared extension. Load component, connect with `load_age` callback so each session runs `LOAD 'age'` and adds `ag_catalog` to `search_path`.

```perl
package MyApp::Schema;
use DBIO 'Schema', -pg;

__PACKAGE__->pg_extensions('age');
__PACKAGE__->load_components('PostgreSQL::Age');

my $schema = MyApp::Schema->connect($dsn, $user, $pass, {
  AutoCommit      => 1,
  RaiseError      => 1,
  PrintError      => 0,
  on_connect_call => 'load_age',
});

my $storage = $schema->storage;
```

## Graph Lifecycle

```perl
$storage->create_graph('social');
$storage->drop_graph('social', 1);   # 1 = cascade
```

Graph names must be plain PG identifiers (validated by `cypher()`):

```
valid:   social, app_graph_1
invalid: app-graph, public.social, "graph name"
```

## Running Cypher

```perl
my $rows = $storage->cypher($graph, $query, \@result_columns, \%params);
```

Every result column is declared `agtype`. Column names must be plain identifiers (`[A-Za-z_][A-Za-z0-9_]*`), otherwise `cypher()` throws `Invalid AGE column name`. Returns arrayref of hashrefs.

```perl
my $rows = $storage->cypher(
  'social',
  q{ MATCH (p:Person) RETURN p.name, p.age },
  [qw(name age)],
);

for my $row (@$rows) {
  say "$row->{name} is $row->{age}";
}
```

## Vertices

AGE requires every `cypher()` to RETURN at least one column, so CREATE returns a stub.

```perl
$storage->cypher(
  'social',
  q{
    CREATE (:Person {name: $name, age: $age})
    RETURN 1
  },
  ['ok'],
  { name => 'Alice', age => 30 },
);
```

Always parameterise user input — never interpolate.

## Edges

Match endpoints first, then create. Can combine create + create in one query.

```perl
$storage->cypher(
  'social',
  q{
    MATCH (a:Person {name: $from}), (b:Person {name: $to})
    CREATE (a)-[:KNOWS {since: $since}]->(b)
    RETURN 1
  },
  ['ok'],
  { from => 'Alice', to => 'Bob', since => 2020 },
);
```

## Querying

```perl
my $rows = $storage->cypher(
  'social',
  q{
    MATCH (a:Person)-[r:KNOWS]->(b:Person)
    RETURN a.name, b.name, r.since
  },
  [qw(person friend since)],
);
```

## agtype Results

`cypher()` returns `agtype` as strings via DBI. Let it decode them: pass `{ auto_decode => 1 }` as the 5th argument.

```perl
my $rows = $storage->cypher(
  'social',
  q{ MATCH (p:Person {name: $name}) RETURN p, p.age },
  [qw(person age)],
  { name => 'Alice' },
  { auto_decode => 1 },
);
# $rows->[0]{person} = { id => ..., label => 'Person', properties => { ... } }
# $rows->[0]{age}    = 30
```

Or decode a single cell: `$storage->decode_agtype($cell)`. Vertices come back as `{ id, label, properties }`, edges additionally with `start_id` and `end_id`.

Fallback without auto_decode: scalar strings come back quoted.

```perl
sub ag_string {
  my ($value) = @_;
  return undef unless defined $value;
  $value =~ s/\A"//;
  $value =~ s/"\z//;
  return $value;
}
```

JSON-like agtype values → use `JSON::MaybeXS`:

```perl
use JSON::MaybeXS qw(decode_json);

my $rows = $storage->cypher(
  'social',
  q{ MATCH (p:Person {name: $name}) RETURN p {.name, .age} },
  ['person'],
  { name => 'Alice' },
);

my $person = decode_json($rows->[0]{person});
```

Full vertices/edges/paths may include graph annotations in text form. Prefer projected maps:

```perl
$storage->cypher('social', q{
  MATCH (a:Person)-[r:KNOWS]->(b:Person)
  RETURN { from: a.name, to: b.name, since: r.since }
}, ['relationship']);
```

## Checklist

- `use DBIO 'Schema', -pg` (or `load_components('PostgreSQL')`) — the schema names the driver
- `pg_extensions('age')` and `load_components('PostgreSQL::Age')` on schema
- `on_connect_call => 'load_age'` in connect attrs
- `$storage->create_graph($name)` before use
- Always provide `\@columns` matching RETURN exprs, each a plain identifier
- Always parameterise; never interpolate
- Return properties or projected maps for clean agtype parsing
- `$storage->drop_graph($name, 1)` for test cleanup

## Async

`cypher_async`, `create_graph_async` and `drop_graph_async` (on `$schema->storage`, which routes to the async backend, or on `->async`) return Futures and take the same arguments, including `{ auto_decode => 1 }`. They run on a **pooled** connection only: inside `txn_do_async` or `pipeline` they execute outside that transaction. For transactional graph work use `$schema->txn_do(sub { $schema->storage->cypher(...) })`.

## Tests

Offline tests (`t/`) use mock storage and touch no database:

```bash
../dbio/maint/capped-test prove -lr t/
```

The live files (`t/*-live.t`, `t/11-age-deploy.t`) skip unless `DBIO_TEST_PG_DSN`, `DBIO_TEST_PG_USER` and `DBIO_TEST_PG_PASS` are set; they need PostgreSQL with the Apache AGE extension. On the maintainer's cluster `eval "$(dbio-db env postgresql)"` sets them; point the DSN at the repo's own database `dbio_age`. Run `maint/live-preflight` (in core) before, and the suite through `capped-test`. Paths, caps and sharing: core skill `dbio-driver-development`, `references/live-testing.md`.
