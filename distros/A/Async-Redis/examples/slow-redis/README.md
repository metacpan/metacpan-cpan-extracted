# Slow Redis Example

Demonstrates non-blocking I/O by intentionally delaying each request by 1 second.

## The Point

With **blocking I/O**, a single-threaded server handling 5 requests that each take 1 second would need 5 seconds total (sequential processing).

With **non-blocking I/O**, those same 5 concurrent requests complete in ~1 second because they all sleep concurrently while the event loop handles them.

## Running

```bash
# Start Redis
docker run -d -p 6379:6379 redis

# Start the server
REDIS_HOST=localhost pagi-server --app examples/slow-redis/app.pl --port 5001
```

## Testing

### Single request (~1 second)
```bash
curl http://localhost:5001/
```

### 5 concurrent requests (should be ~1 second, not 5!)
```bash
time (for i in 1 2 3 4 5; do curl -s http://localhost:5001/ & done; wait)
```

### 10 concurrent requests
```bash
time (for i in $(seq 1 10); do curl -s http://localhost:5001/ & done; wait)
```

### Compare with fast endpoint (no delay)
```bash
curl http://localhost:5001/fast
```

## Expected Output

```
Slow Redis Response
===================
Worker PID:     12345
Redis Time:     1704307200.123456
Request took:   1.002s (including 1s sleep)

This request intentionally waits 1 second to demonstrate non-blocking I/O.
Run multiple concurrent requests - they should all complete in ~1 second total!
```

## How It Works

1. Request arrives
2. `Future::IO->sleep(1)` yields control to the event loop
3. Event loop can accept and process other requests during the sleep
4. After 1 second, all sleeping requests wake up
5. Each request gets Redis TIME and responds

The key is that `Future::IO->sleep()` is **non-blocking** - it doesn't block the thread, it just schedules a callback for later while the event loop continues processing other work.
