---
name: dbio-mysql-async
description: "DBIO::MySQL::Async driver — EV::MariaDB async storage, Future API, Pool, Pipeline, AccessBroker"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::MySQL::Async

Async MySQL/MariaDB storage for DBIO using EV::MariaDB. Bypasses DBI entirely — speaks MariaDB's C client library directly for maximum performance.

## Namespace

| Class | Purpose |
|-------|---------|
| `DBIO::MySQL::Async` | Schema integration entry point |
| `DBIO::MySQL::Async::Storage` | Async storage implementation (extends `DBIO::Storage::Async`) |
| `DBIO::MySQL::Async::Pool` | EV::MariaDB connection pool |
| `DBIO::MySQL::Async::TransactionContext` | Transaction context with pinning |

## Key Architecture

- Uses **EV::MariaDB** (MariaDB C client XS wrapper), NOT DBI/DBD::mysql
- Connection info is **EV::MariaDB conninfo hash**, not DBI DSN
- Returns **Future.pm** objects from all async methods
- Sync methods (`select`, `insert`, etc.) work by blocking via `->get`
- **Pipeline mode** for batching queries in single round-trip (up to 64 in-flight)
- **Connection pooling** with transaction pinning

## Component Loading

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('MySQL::Async');
# → sets storage_type to DBIO::MySQL::Async::Storage
```

## Connection

```perl
# EV::MariaDB conninfo hash
$schema->connect({
  host     => 'localhost',
  port     => 3306,
  database => 'myapp',
  user     => 'myapp',
  password => 'secret',
  pool_size => 10,
});

# With AccessBroker — see dbio-core skill for full AccessBroker docs
use DBIO::AccessBroker::Static;
my $broker = DBIO::AccessBroker::Static->new(
  host     => 'localhost',
  database => 'myapp',
  user     => 'myapp',
  password => 'secret',
);
my $brokered = MyApp::Schema->connect($broker);
```

## Async API

```perl
# Non-blocking query → Future
my $future = $storage->select_async('SELECT * FROM users WHERE id = ?', [1]);
my @rows   = $future->get;  # blocks until ready

# Pipeline mode (multiple queries, single round-trip)
my $pipe = $storage->pipeline;
$pipe->query('INSERT INTO logs (msg) VALUES (?)', [$msg]);
$pipe->query('SELECT count(*) FROM logs');
my @results = $pipe->get;  # both complete in one network round-trip

# Async resultset iteration
$schema->resultset('Artist')->all_async->then(sub {
    my @artists = @_;
    say $_->name for @artists;
});
```

## Event Loop Compatibility

EV::MariaDB uses the EV event loop. Works with:

- **EV** directly
- **AnyEvent** (uses EV as backend when available)
- **IO::Async** via `IO::Async::Loop::EV`
- **Mojolicious** via `Mojo::Reactor::EV`

## Key Modules

| Module | Purpose |
|-------|---------|
| `DBIO::MySQL::Async` | Schema component (entry point) |
| `DBIO::MySQL::Async::Storage` | Async storage: Future API, pipeline, pool |
| `DBIO::MySQL::Async::Pool` | EV::MariaDB connection pool with pinning |
| `DBIO::MySQL::Async::TransactionContext` | Transaction context management |

## Dependencies

- `EV::MariaDB` >= 0.03
- `Future` >= 0.49
- `DBIO` core
- `DBIO::MySQL`

## Testing

```bash
# Unit tests (no DB needed)
prove -l t/00-load.t t/01-storage-api.t t/02-access-broker.t

# Integration tests (requires DB + EV::MariaDB)
DBIO_TEST_MYSQL_DSN='database=testdb;host=localhost' \
DBIO_TEST_MYSQL_USER=root \
DBIO_TEST_MYSQL_PASS=secret \
  prove -l t/10-integration.t t/11-access-broker-live.t
```

## Important Implementation Notes

- **NOT DBI**: This driver does NOT use DBI or DBD::mysql — it speaks MariaDB C client directly via EV::MariaDB
- **Pipeline mode**: Enable with `$storage->pipeline` for batched queries (up to 64 in-flight)
- **Sync compatibility**: Sync methods (`select`, `insert`, etc.) work by blocking via `->get` on the underlying Future
- **Pool transaction pinning**: When inside a transaction, the same connection is reused (pinned to the transaction context)
