# Async::Redis Examples

This directory contains example applications demonstrating Async::Redis.

## Prerequisites

All examples require a Redis server. Use the included docker-compose configuration:

```bash
# Start Redis
docker compose -f examples/docker-compose.yml up -d

# Verify Redis is running
docker compose -f examples/docker-compose.yml ps

# Stop Redis
docker compose -f examples/docker-compose.yml down

# Stop Redis and remove data volume
docker compose -f examples/docker-compose.yml down -v
```

## Examples

### async-job-queue

A small CLI demo that queues a burst of Redis list jobs, processes them with
multiple async workers, and prints heartbeat lines while workers wait in
`BLPOP` or simulate slow work.

```bash
REDIS_HOST=localhost perl examples/async-job-queue/app.pl
```

See [async-job-queue/README.md](async-job-queue/README.md) for details.

### bulk-insert

A CLI demo that inserts many TTL'd Redis keys in concurrent batches while a
separate heartbeat connection keeps printing progress and Redis ping latency.

```bash
REDIS_HOST=localhost perl examples/bulk-insert/app.pl --count 10000 --heartbeat 0.05
```

See [bulk-insert/README.md](bulk-insert/README.md) for details.

### slow-redis

Demonstrates non-blocking I/O by intentionally delaying each request by 1 second.
The key insight: with non-blocking I/O, 5 concurrent requests still complete in
~1 second (not 5 seconds) because they all sleep concurrently.

```bash
# Start the server
REDIS_HOST=localhost pagi-server --app examples/slow-redis/app.pl --port 5001

# Test 5 concurrent requests (should complete in ~1 second, not 5!)
time (for i in 1 2 3 4 5; do curl -s http://localhost:5001/ & done; wait)
```

See [slow-redis/README.md](slow-redis/README.md) for details.

### pagi-chat

A multi-worker chat application demonstrating Redis PubSub for real-time
cross-worker message broadcasting. Port of PAGI's websocket-chat-v2 example.

```bash
# Start the chat server
REDIS_HOST=localhost pagi-server \
    --app examples/pagi-chat/app.pl \
    --port 5000 \
    --workers 4

# Open http://localhost:5000
```

See [pagi-chat/README.md](pagi-chat/README.md) for details.

### stress

A CLI harness that runs all major Async::Redis features under load
with periodic CLIENT KILL chaos and integrity verification. Used both
as a soak test and a CI smoke gate.

```bash
REDIS_HOST=localhost ./examples/stress/stress --duration 60 --kill-interval 10
```

See [stress/README.md](stress/README.md) for output format and exit codes.

## Environment Variables

- `REDIS_HOST` - Redis server hostname (default: localhost)
- `REDIS_PORT` - Redis server port (default: 6379)
