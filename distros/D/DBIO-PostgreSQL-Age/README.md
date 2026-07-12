# DBIO::PostgreSQL::Age

Apache AGE graph database extension support for DBIO::PostgreSQL.

## Supports

- Apache AGE openCypher graph queries ([DBIO::PostgreSQL::Age::Storage](https://metacpan.org/pod/DBIO::PostgreSQL::Age::Storage))
- graph creation and deletion lifecycle
- cypher() SQL function execution via [DBIO::PostgreSQL::Age::Storage/cypher](https://metacpan.org/pod/DBIO::PostgreSQL::Age::Storage)
- integration with [DBIO::PostgreSQL](https://metacpan.org/pod/DBIO::PostgreSQL) base driver

## Usage

    package MyApp::Schema;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('PostgreSQL::Age');

    my $schema = MyApp::Schema->connect(
      $dsn, $user, $pass,
      { on_connect_call => 'load_age' },
    );

    $schema->storage->create_graph('social');

    my $rows = $schema->storage->cypher(
      'social',
      'MATCH (a:Person)-[:KNOWS]->(b:Person) RETURN a.name, b.name',
      [qw( person friend )],
    );

DBIO core autodetects `dbi:Pg:` DSNs with the PostgreSQL driver, and
[DBIO::PostgreSQL::Age](https://metacpan.org/pod/DBIO::PostgreSQL::Age) is loaded via `load_components`.

## Apache AGE Features

**Graph Operations**
- `create_graph($name)` - create a named graph
- `drop_graph($name, $cascade)` - drop a graph (cascade drops vertices and edges too)
- `cypher($graph, $query, \@columns, \%params, \%opts)` - execute openCypher query
- `decode_agtype($value)` - decode a single agtype text value into native Perl data
- `connect_call_load_age` - connection callback: `LOAD 'age'` + `SET search_path = ag_catalog, ...`

By default `cypher()` returns each result cell as the raw agtype text
that PostgreSQL hands back over the wire — strings are quoted (`"alice"`),
maps and vertices are JSON, and so on. Pass `{ auto_decode => 1 }` as the
fifth argument to apply [`decode_agtype`](https://metacpan.org/pod/DBIO::PostgreSQL::Age::Storage#decode_agtype)
to every cell of every row, so you get back plain Perl strings, numbers,
hashrefs, arrayrefs, vertex hashrefs (`{ id, label, properties }`), and
edge hashrefs (`{ id, label, start_id, end_id, properties }`).

**openCypher Support**
- `MATCH`, `OPTIONAL MATCH` - graph pattern matching
- `WHERE` - filtering on node/relationship properties
- `RETURN`, `RETURN DISTINCT` - result projection
- `ORDER BY`, `SKIP`, `LIMIT` - pagination
- `WITH` - query chaining and aggregation (`count()`, `collect()`, ...)
- `CREATE`, `MERGE`, `SET`, `REMOVE` - graph mutation
- `DELETE`, `DETACH DELETE` - graph deletion
- Variable-length paths: `()-[:KNOWS*1..3]->()`
- Node labels and relationship types
- Parameterized queries via `$name` placeholders

**Labels & Types**
- Node labels: `(:Person)`, `(:Person {name: 'Alice'})`
- Relationship types: `[:KNOWS]`, `[:KNOWS {since: 2020}]`
- Multiple labels: `(:Person:Employee)`
- Multiple relationships: `(a)-[:KNOWS]->(b)-[:WORKS_WITH]->(c)`

## Testing

Three layers, each more involved than the last:

### 1. Offline unit tests (no database needed)

```bash
prove -l t/20-cypher.t t/21-agtype.t t/30-registry.t t/00-load.t
```

Covers `cypher()` SQL generation, `decode_agtype` for every agtype shape
(vertex / edge / path / scalar / null / bool / map / list), and the
regression that loading AGE storage must not hijack the plain `'Pg'`
driver registry.

### 2. Local live tests (docker compose)

Spins up PostgreSQL 18 with the AGE extension preinstalled (image
`apache/age:latest`, which is `postgres:18` + AGE 1.7):

```bash
docker compose up -d
# wait for "database system is ready to accept connections"
DBIO_TEST_PG_DSN="dbi:Pg:dbname=dbio_age_test;host=127.0.0.1;port=54329" \
DBIO_TEST_PG_USER=postgres \
DBIO_TEST_PG_PASS=dbio_age_test \
  prove -lr t/
docker compose down -v
```

`compose` exposes on `54329` to stay side-by-side with anything else
already on `5432`. The init script `docker/init-age-db.sh` creates the
`dbio_age_test` database and enables the AGE extension there.

### 3. End-to-end against a Kubernetes cluster

```bash
LOCAL_PORT=55432 k8s/test.sh
# or pin a specific context:
CONTEXT=my-cluster k8s/test.sh
```

`k8s/test.sh` deploys the AGE PostgreSQL pod (`k8s/postgres.yaml`),
waits for it to be ready, creates the test DB and enables AGE inside
the cluster, port-forwards `127.0.0.1:${LOCAL_PORT}` to the pod, runs
the Perl test suite against that forward, and tears everything down on
exit. The script refuses to run against any kubectl context whose
name contains `prod`, `production`, or `staging`. Pass `KEEP=1` to
leave the deployment/service in the cluster for post-mortem.

### Test layout

| File                     | What it does                                                                 |
|--------------------------|------------------------------------------------------------------------------|
| `t/00-load.t`            | Module load smoke test.                                                      |
| `t/10-age-live.t`        | Live test against a real AGE cluster. Covers graph lifecycle, `MERGE`, `SET`, `REMOVE`, `DELETE`, `OPTIONAL MATCH`, `WHERE`, `ORDER BY`, `WITH`, `count()`, variable-length paths `[*1..2]`, edge properties, `auto_decode`. |
| `t/11-age-deploy.t`      | "Deploy" pattern: idempotent fixture loading via `MERGE`, callable twice.     |
| `t/20-cypher.t`          | Offline unit tests for `cypher()` SQL generation + graph-name validation.    |
| `t/21-agtype.t`          | Offline unit tests for `decode_agtype` across all agtype shapes.              |
| `t/30-registry.t`        | Regression: AGE storage must not register itself as the plain `'Pg'` driver.  |

The live tests (`t/10-age-live.t`, `t/11-age-deploy.t`) skip cleanly
when `DBIO_TEST_PG_*` env vars are unset or the cluster has no AGE
extension.

## Requirements

- Perl 5.36+
- [DBD::Pg](https://metacpan.org/pod/DBD::Pg)
- Apache AGE PostgreSQL extension
- DBIO core
- [DBIO::PostgreSQL](https://metacpan.org/pod/DBIO::PostgreSQL) base driver

## See Also

[DBIO::PostgreSQL](https://metacpan.org/pod/DBIO::PostgreSQL), [DBIO::PostgreSQL::Age::Storage](https://metacpan.org/pod/DBIO::PostgreSQL::Age::Storage), [Apache AGE](https://age.apache.org/)

## Repository

[https://codeberg.org/dbio/dbio-postgresql-age](https://codeberg.org/dbio/dbio-postgresql-age)