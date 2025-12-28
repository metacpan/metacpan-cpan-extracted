# DBD::Patroni

A Perl DBI driver for PostgreSQL with Patroni cluster support. Automatically routes queries to the appropriate node:
- **SELECT** queries go to replicas (read scaling)
- **INSERT/UPDATE/DELETE** queries go to the leader

## Features

- Automatic leader discovery via Patroni REST API
- Read/write query routing
- Configurable load balancing (round-robin, random, leader-only)
- Automatic failover with retry on connection errors
- Pure Perl implementation (wraps DBD::Pg)

## Installation

```bash
cpanm DBD::Patroni
```

Or from source:

```bash
perl Makefile.PL
make
make test
make install
```

## Usage

```perl
use DBI;

# Connect using standard DBI syntax with patroni_url in DSN
my $dbh = DBI->connect(
    "dbi:Patroni:dbname=mydb;patroni_url=http://patroni1:8008/cluster,http://patroni2:8008/cluster",
    $user, $password
);

# Or with attributes hash
my $dbh = DBI->connect(
    "dbi:Patroni:dbname=mydb",
    $user, $password,
    {
        patroni_url => "http://patroni1:8008/cluster,http://patroni2:8008/cluster",
        patroni_lb  => "round_robin",  # round_robin | random | leader_only
    }
);

# SELECT queries go to replica
my $sth = $dbh->prepare("SELECT * FROM users WHERE id = ?");
$sth->execute(1);
my $row = $sth->fetchrow_hashref;

# INSERT/UPDATE/DELETE queries go to leader
$dbh->do("INSERT INTO users (name) VALUES (?)", undef, "John");

# Transactions always use the leader
$dbh->begin_work;
$dbh->do("UPDATE accounts SET balance = balance - 100 WHERE id = ?", undef, 1);
$dbh->do("UPDATE accounts SET balance = balance + 100 WHERE id = ?", undef, 2);
$dbh->commit;

$dbh->disconnect;
```

## Connection Attributes

All Patroni attributes can be specified either in the DSN string or in the attributes hash. Attributes hash takes precedence.

| Attribute | Description | Default |
|-----------|-------------|---------|
| `patroni_url` | Comma-separated Patroni REST API endpoints | **required** |
| `patroni_lb` | Load balancing mode: `round_robin`, `random`, `leader_only` | `round_robin` |
| `patroni_timeout` | HTTP timeout for Patroni API calls (seconds) | `3` |

Example with all attributes in DSN:
```perl
my $dbh = DBI->connect(
    "dbi:Patroni:dbname=mydb;patroni_url=http://host:8008/cluster;patroni_lb=random;patroni_timeout=5",
    $user, $password
);
```

## Query Routing

Queries are automatically routed based on their type:

- **Read queries** (SELECT, WITH...SELECT): Routed to a replica
- **Write queries** (INSERT, UPDATE, DELETE, CREATE, DROP, etc.): Routed to the leader
- **Transactions**: Always use the leader

## Failover Handling

When a connection error occurs:

1. DBD::Patroni queries the Patroni API to discover the current leader
2. Reconnects to the new leader/replica
3. Retries the failed operation

If the retry also fails, the error is propagated to the caller.

## Running Tests

### Unit Tests

```bash
prove -v -Ilib t/01-basic.t
```

### Integration Tests (requires Docker)

```bash
cd docker
docker compose up -d
export PATRONI_URLS="http://localhost:8008/cluster"
export PGUSER=testuser PGPASSWORD=testpass PGDATABASE=testdb
prove -v -Ilib t/02-integration.t
docker compose down -v
```

### Failover Tests

```bash
cd docker
docker compose up -d
export TEST_FAILOVER=1
export PATRONI_URLS="http://localhost:8008/cluster"
export PGUSER=testuser PGPASSWORD=testpass PGDATABASE=testdb
prove -v -Ilib t/03-failover.t
docker compose down -v
```

## Requirements

- Perl 5.10.1+
- DBI 1.614+
- DBD::Pg 3.0+
- LWP::UserAgent
- JSON

## License

Same as Perl itself (Artistic License / GPL).

## Author

Xavier Guimard
