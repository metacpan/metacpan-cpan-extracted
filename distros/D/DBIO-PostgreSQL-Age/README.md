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
- `drop_graph($name)` - drop a graph (cascade)
- `cypher($graph, $query, \@params)` - execute openCypher query

**openCypher Support**
- `MATCH`, `OPTIONAL MATCH` - graph pattern matching
- `WHERE` - filtering on node/relationship properties
- `RETURN`, `RETURN DISTINCT` - result projection
- `ORDER BY`, `SKIP`, `LIMIT` - pagination
- `WITH` - query chaining
- `CREATE`, `SET` - graph mutation
- `DELETE`, `DETACH DELETE` - graph deletion
- Node labels and relationship types

**Labels & Types**
- Node labels: `(:Person)`, `(:Person {name: 'Alice'})`
- Relationship types: `[:KNOWS]`, `[:KNOWS {since: 2020}]`
- Multiple labels: `(:Person:Employee)`
- Multiple relationships: `(a)-[:KNOWS]->(b)-[:WORKS_WITH]->(c)`

## Testing

Requires a running PostgreSQL instance with Apache AGE extension:

```bash
export DBIO_TEST_PG_DSN="dbi:Pg:database=myapp"
export DBIO_TEST_PG_USER=postgres
export DBIO_TEST_PG_PASS=secret
prove -l t/
```

The live test (C<t/10-age-live.t>) creates an actual graph and runs
openCypher queries. Skips if no AGE extension is available.

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