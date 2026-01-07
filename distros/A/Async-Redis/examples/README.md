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

## Environment Variables

- `REDIS_HOST` - Redis server hostname (default: localhost)
- `REDIS_PORT` - Redis server port (default: 6379)
