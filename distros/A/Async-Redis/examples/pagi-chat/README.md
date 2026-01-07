# Multi-Worker Chat with PAGI + Async::Redis

This is a port of PAGI's `websocket-chat-v2` example, adapted to use **Redis** for state management and **PubSub** for cross-worker broadcasting.

## The Problem

The original PAGI chat example uses in-memory state:

```perl
# Original - only works with 1 worker
my %sessions;  # In-memory hash
my %rooms;     # In-memory hash

sub broadcast_to_room {
    for my $user (get_room_users($room)) {
        $user->{send_cb}->($message);  # Direct callback
    }
}
```

This breaks with multiple workers because each worker has its own memory space.

## The Solution

This example replaces in-memory state with Redis:

```perl
# Redis-backed - works with N workers
async sub broadcast_to_room {
    # Publish to Redis channel - all workers receive it
    await $redis->publish('chat:broadcast', $message);
}

# Each worker subscribes and delivers to its local clients
while (my $msg = await $pubsub->next_message) {
    for my $client (@local_clients) {
        $client->send($msg);
    }
}
```

## Architecture

```
                    ┌─────────────────┐
                    │      Redis      │
                    │  - Sessions     │
                    │  - Rooms        │
                    │  - Messages     │
                    │  - PubSub       │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
   ┌──────────┐        ┌──────────┐        ┌──────────┐
   │ Worker 1 │        │ Worker 2 │        │ Worker 3 │
   │          │        │          │        │          │
   │ Clients  │        │ Clients  │        │ Clients  │
   │ A, B     │        │ C, D     │        │ E, F     │
   └──────────┘        └──────────┘        └──────────┘
```

When Client A sends a message:
1. Worker 1 receives it via WebSocket
2. Worker 1 stores in Redis and publishes to PubSub
3. All workers receive the PubSub message
4. Each worker broadcasts to its local clients (B, C, D, E, F)

## Running

### 1. Start Redis

Using docker-compose (recommended):

```bash
# Start Redis (from project root)
docker compose -f examples/docker-compose.yml up -d

# Check status
docker compose -f examples/docker-compose.yml ps

# View logs
docker compose -f examples/docker-compose.yml logs -f

# Stop Redis
docker compose -f examples/docker-compose.yml down

# Stop and remove data
docker compose -f examples/docker-compose.yml down -v
```

Or using docker directly:

```bash
docker run -d -p 6379:6379 --name redis-example redis:7-alpine
```

### 2. Run the Chat Server

```bash
# Run with multiple workers
REDIS_HOST=localhost pagi-server \
    --app examples/pagi-chat/app.pl \
    --port 5000 \
    --workers 4
```

### 3. Test Multi-Worker Chat

Open http://localhost:5000 in multiple browser tabs. Messages sent from one tab
will be received by all other tabs, even though they may be connected to different
worker processes.

## What This Demonstrates

- **Async::Redis** working with PAGI
- **Fork-safe connections** - each worker creates its own Redis connections
- **PubSub** for real-time cross-worker message delivery
- **Redis data structures** for shared state (hashes, sets, lists)
- **Non-blocking I/O** throughout with async/await

## Files

```
examples/pagi-chat/
├── app.pl                 # Main PAGI application
├── lib/
│   └── ChatApp/
│       ├── State.pm       # Redis-backed state management
│       ├── WebSocket.pm   # WebSocket chat handler
│       └── HTTP.pm        # Static files and API
└── public/
    ├── index.html
    ├── css/style.css
    └── js/app.js
```

## Comparison with Original

| Feature | Original (In-Memory) | This Version (Redis) |
|---------|---------------------|----------------------|
| Workers | 1 only | N workers |
| State | Process memory | Redis |
| Broadcast | Direct callbacks | Redis PubSub |
| Persistence | None (lost on restart) | Redis (survives restart) |
| Scalability | Single process | Horizontal |

## Requirements

- PAGI (0.001+)
- Async::Redis
- Redis server
- JSON::MaybeXS
