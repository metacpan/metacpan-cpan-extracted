# Async::Redis

Async Redis client for Perl using Future::IO

## Features

- **Truly async** - Non-blocking I/O using Future::IO
- **Event loop agnostic** - Works with IO::Async, AnyEvent, UV, or any Future::IO implementation
- **Pipelining** - Batch commands for improved throughput
- **Connection pooling** - Built-in connection pool with health checks
- **PubSub** - Subscribe to channels and patterns with automatic reconnect
- **Transactions** - MULTI/EXEC with WATCH support
- **TLS/SSL** - Secure connections with certificate verification
- **Fork-safe** - Works with pre-fork servers like Starman
- **Observability** - OpenTelemetry tracing and metrics integration

## Installation

```bash
cpanm Async::Redis

# Or with dependencies
cpanm Future::IO Future::AsyncAwait Protocol::Redis IO::Async

# Optional for better performance:
cpanm Protocol::Redis::XS
```

## Quick Start

```perl
use Async::Redis;
use Future::AsyncAwait;

# Use any Future::IO-compatible event loop
# IO::Async example:
use IO::Async::Loop;
my $loop = IO::Async::Loop->new;

# Or UV:        use Future::IO; Future::IO->load_impl('UV');
# Or Glib:      use Future::IO; Future::IO->load_impl('Glib');

my $redis = Async::Redis->new(
    host => 'localhost',
    port => 6379,
);

async sub main {
    await $redis->connect;

    # Basic commands
    await $redis->set('foo', 'bar');
    my $value = await $redis->get('foo');
    print "Value: $value\n";

    # Pipelining
    my $pipe = $redis->pipeline;
    $pipe->set('k1', 'v1');
    $pipe->set('k2', 'v2');
    $pipe->get('k1');
    my $results = await $pipe->execute;

    $redis->disconnect;
}

$loop->await(main());
```

## Usage Examples

### Connection Options

```perl
my $redis = Async::Redis->new(
    # Basic connection
    host => 'localhost',
    port => 6379,

    # Or use URI
    uri => 'redis://user:pass@host:6379/1',

    # Authentication
    password => 'secret',
    username => 'myuser',  # Redis 6+ ACL
    database => 1,

    # Timeouts
    connect_timeout => 10,
    request_timeout => 5,

    # Auto-reconnect
    reconnect       => 1,
    reconnect_delay => 0.1,
    reconnect_delay_max => 60,

    # TLS
    tls => {
        ca_file   => '/path/to/ca.crt',
        cert_file => '/path/to/client.crt',
        key_file  => '/path/to/client.key',
    },

    # Key prefix (applied to all commands)
    prefix => 'myapp:',
);
```

### Pipelining

```perl
my $pipe = $redis->pipeline;
$pipe->set('key1', 'value1');
$pipe->set('key2', 'value2');
$pipe->incr('counter');
$pipe->get('key1');

my $results = await $pipe->execute;
# $results = ['OK', 'OK', 1, 'value1']
```

### PubSub

```perl
# Subscriber
my $sub = await $redis->subscribe('news', 'alerts');
while (my $msg = await $sub->next_message) {
    print "Channel: $msg->{channel}, Message: $msg->{message}\n";
}

# Publisher (on different connection)
await $redis->publish('news', 'Breaking news!');
```

### Transactions

```perl
my $results = await $redis->multi(async sub {
    my ($tx) = @_;
    $tx->set('key', 'value');
    $tx->incr('counter');
});
# $results = ['OK', 1]

# With WATCH for optimistic locking
my $results = await $redis->watch_multi(['counter'], async sub {
    my ($tx, $values) = @_;
    my $current = $values->{counter} // 0;
    $tx->set('counter', $current + 1);
});
# Returns undef if counter was modified by another client
```

### Connection Pooling

```perl
use Async::Redis::Pool;

my $pool = Async::Redis::Pool->new(
    host => 'localhost',
    min  => 2,
    max  => 10,
);

# Use the with() pattern for automatic acquire/release
my $result = await $pool->with(sub {
    my ($conn) = @_;
    return $conn->get('key');
});
```

### Lua Scripts

```perl
my $script = $redis->script('return redis.call("get", KEYS[1])');
my $result = await $script->run(['mykey']);

# Script is cached via EVALSHA
```

### SCAN Iterators

```perl
my $iter = $redis->scan_iter(match => 'user:*', count => 100);
while (my $keys = await $iter->next) {
    for my $key (@$keys) {
        print "Found key: $key\n";
    }
}
```

## Running Tests

```bash
# Start Redis
docker compose up -d

# Run all tests
REDIS_HOST=localhost prove -l t/

# Run specific test suites
REDIS_HOST=localhost prove -l t/20-commands/
REDIS_HOST=localhost prove -l t/99-integration/

# Run benchmarks
perl scripts/benchmark.pl

# Stop Redis
docker compose down
```

## Performance

Benchmarks on localhost with default settings:

| Operation | ops/sec |
|-----------|---------|
| Sequential SET | ~2,000 |
| Sequential GET | ~2,200 |
| Pipelined SET (batch 100) | ~60,000 |
| Pipelined GET (batch 100) | ~60,000 |
| Mixed pipeline | ~64,000 |

Pipelining provides ~30x throughput improvement over sequential commands.

## Architecture

```
┌─────────────────────────────────────┐
│         Async::Redis           │
│  - Connection management            │
│  - Command methods                  │
│  - Pipelining / Auto-pipeline       │
│  - PubSub / Transactions            │
│  - Connection pooling               │
└─────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│       Protocol::Redis(::XS)         │
│  - RESP2 parsing/encoding           │
│  - Streaming/incremental            │
└─────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│            Future::IO               │
│  - Event loop abstraction           │
│  - read/write/connect               │
└─────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│  IO::Async / AnyEvent / UV / etc.   │
└─────────────────────────────────────┘
```

## Dependencies

**Required:**
- Future::IO (0.17+)
- Future::AsyncAwait
- Protocol::Redis

**Recommended:**
- Protocol::Redis::XS (faster parsing)
- IO::Async (or your preferred event loop)

**Optional:**
- IO::Socket::SSL (for TLS)
- OpenTelemetry::SDK (for observability)

## See Also

- [Future::IO](https://metacpan.org/pod/Future::IO) - The underlying async I/O abstraction
- [Future::AsyncAwait](https://metacpan.org/pod/Future::AsyncAwait) - Async/await syntax
- [Redis](https://metacpan.org/pod/Redis) - Synchronous Redis client
- [Net::Async::Redis](https://metacpan.org/pod/Net::Async::Redis) - Another async Redis client

## Author

John Googoo

## License

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
