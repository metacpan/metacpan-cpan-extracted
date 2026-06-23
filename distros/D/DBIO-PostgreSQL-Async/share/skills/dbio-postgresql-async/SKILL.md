---
name: dbio-postgresql-async
description: "DBIO::PostgreSQL::Async driver — EV::Pg async storage, Future API, Pool, LISTEN/NOTIFY, Pipeline, COPY"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::PostgreSQL::Async

Async PostgreSQL storage for DBIO using EV::Pg. Bypasses DBI entirely — speaks libpq's async protocol directly for maximum performance.

## Namespace

| Class | Purpose |
|-------|---------|
| `DBIO::PostgreSQL::Async` | Schema integration entry point |
| `DBIO::PostgreSQL::Async::Storage` | Async storage implementation (extends `DBIO::Storage::Async`) |
| `DBIO::PostgreSQL::Async::Pool` | EV::Pg connection pool |

## Key Architecture

- Uses **EV::Pg** (libpq XS wrapper), NOT DBI/DBD::Pg
- Connection info is **libpq conninfo format**, not DBI DSN
- Returns **Future.pm** objects from all async methods
- Sync methods (select, insert, etc.) work by blocking via `->get`
- **Pipeline mode** for batching queries in single round-trip
- **LISTEN/NOTIFY** via dedicated connection

## Component Loading

```perl
package MyApp::DB;
use base 'DBIO::Schema';
__PACKAGE__->load_components('PostgreSQL::Async');
# → sets storage_type to +DBIO::PostgreSQL::Async::Storage
```

## Connection

```perl
# libpq conninfo format (not DBI DSN)
$schema->connect({
  dsn  => 'host=localhost port=5432 dbname=myapp',
  user => 'dbio',
  pass => 'secret',
});

# Or with async pool options
$schema->connection({
  dsn  => 'host=localhost dbname=myapp',
  async => {
    pool_size => 10,
    pipeline  => 1,
  },
});

# With AccessBroker — see dbio-core skill for full AccessBroker docs
use DBIO::AccessBroker::Static;
my $broker = DBIO::AccessBroker::Static->new(
  dsn  => 'host=localhost dbname=myapp',
  user => 'dbio',
  pass => 'secret',
);
my $brokered = MyApp::Schema->connect($broker);
```

## Async API

```perl
# Non-blocking query → Future
my $future = $storage->select_async('SELECT * FROM users WHERE id = ?', [1]);
my @rows   = $future->get;  # blocks until ready

# Single row
my $future = $storage->select_single_async('SELECT * FROM users WHERE id = ?', [1]);
my $row    = $future->get;

# Pipeline mode (multiple queries, single round-trip)
my $pipe = $storage->pipeline;
$pipe->query('INSERT INTO logs (msg) VALUES (?)', [$msg]);
$pipe->query('SELECT count(*) FROM logs');
my @results = $pipe->get;  # both complete in one network round-trip
```

## LISTEN/NOTIFY

```perl
# Subscribe to channel
$storage->listen('events', sub {
  my ($payload) = @_;
  say "Received: $payload";
});

# Send notification
$storage->notify('events', 'something happened');

# Deferred: LISTEN/UNLISTEN until on_connect fires
# (see commit 39e31dc fix)
```

## Key Modules

| Module | Purpose |
|-------|---------|
| `DBIO::PostgreSQL::Async` | Schema component (entry point) |
| `DBIO::PostgreSQL::Async::Storage` | Async storage: Future API, pipeline, LISTEN/NOTIFY |
| `DBIO::PostgreSQL::Async::Pool` | EV::Pg connection pool management |

## Dependencies

- `EV::Pg` >= 0.02, < 0.03 (0.02.x is the verified line on libpq 15)
- `Future` >= 0.49
- `DBIO` core

## Testing

```bash
# Unit tests (no DB needed)
prove -l t/00-load.t t/01-storage-api.t t/02-access-broker.t

# Integration tests (requires DB)
export DBIO_TEST_PG_DSN='dbi:Pg:dbname=dbio_async;host=localhost'
export DBIO_TEST_PG_USER=dbio
export DBIO_TEST_PG_PASS=secret
prove -l t/10-integration.t t/11-access-broker-live.t
```

### Kubernetes setup

```bash
kubectl --kubeconfig ~/.kube/rexdemo.yaml apply -f maint/k8s/pg-pod.yaml
kubectl --kubeconfig ~/.kube/rexdemo.yaml wait --for=condition=Ready pod/dbio-async-pg --timeout=60s
kubectl --kubeconfig ~/.kube/rexdemo.yaml port-forward svc/dbio-async-pg-svc 5432:5432 &

DBIO_TEST_PG_DSN='dbi:Pg:dbname=dbio_async;host=127.0.0.1;port=5432' \
DBIO_TEST_PG_USER=dbio \
DBIO_TEST_PG_PASS=dbio \
  prove -l t/10-integration.t t/11-access-broker-live.t

kubectl --kubeconfig ~/.kube/rexdemo.yaml delete -f maint/k8s/pg-pod.yaml
```

## Important Implementation Notes

- **Deferred LISTEN/UNLISTEN**: Committed fix 39e31dc defers LISTEN/UNLISTEN until `on_connect` fires — critical for connection recovery
- **Pipeline mode**: Enable with `$storage->pipeline` for batched queries
- **Sync compatibility**: Sync methods (`select`, `insert`, etc.) work by blocking via `->get` on the underlying Future
- **NOT DBI**: This driver does NOT use DBI or DBD::Pg — it speaks libpq directly via EV::Pg
