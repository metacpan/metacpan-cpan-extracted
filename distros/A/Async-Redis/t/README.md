# Async::Redis Test Suite

## Prerequisites

- Perl 5.18+
- Redis server (via Docker or local install)

## Starting Redis

```bash
cd t/
docker compose up -d redis
```

For full test coverage (auth, replica, cluster):

```bash
docker compose up -d
```

## Running Tests

```bash
# All tests (recursive)
prove -lr t/

# Single test
prove -l t/01-basic.t

# Test directory
prove -lr t/20-commands/

# Verbose output
prove -lv t/01-basic.t
```

Tests automatically skip if Redis is not available.

## Test Organization

| Directory | Purpose |
|-----------|---------|
| `01-unit/` | Unit tests (no Redis required) |
| `10-connection/` | Connection handling, auth, TLS |
| `20-commands/` | Redis command coverage |
| `30-pipeline/` | Pipeline and auto-pipeline |
| `40-transactions/` | MULTI/EXEC transactions |
| `50-pubsub/` | Pub/Sub messaging |
| `60-scripting/` | Lua scripting |
| `70-blocking/` | BLPOP, BRPOP, etc. |
| `80-scan/` | SCAN iterators |
| `90-pool/` | Connection pooling |
| `91-reliability/` | Reconnection, failover |
| `92-concurrency/` | Parallel operations |
| `93-binary/` | Binary data handling |
| `94-observability/` | Metrics, logging |
| `99-integration/` | End-to-end scenarios |
| `lib/` | Test helper modules |

## Docker Services

| Service | Port | Purpose |
|---------|------|---------|
| `redis` | 6379 | Basic Redis |
| `redis-auth` | 6381 | Password auth (testpassword) |
| `redis-replica` | 6382 | Read replica |
| `redis-cluster-1` | 7001 | Cluster node |
| `redis-cluster-2` | 7002 | Cluster node |
| `redis-cluster-3` | 7003 | Cluster node |

## Stopping Redis

```bash
docker compose down
```
