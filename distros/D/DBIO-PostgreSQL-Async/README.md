# DBIO-PostgreSQL-Async

Async PostgreSQL storage for [DBIO](https://metacpan.org/pod/DBIO) using
[EV::Pg](https://metacpan.org/pod/EV::Pg).

Bypasses DBI entirely - speaks libpq's async protocol directly for
maximum performance (124k queries/sec in pipeline mode).

## Features

- **Non-blocking queries** - returns Futures, never blocks the event loop
- **Pipeline mode** - batch queries in a single network round-trip
- **LISTEN/NOTIFY** - real-time event streaming from PostgreSQL
- **COPY** - bulk data loading at wire speed
- **Connection pooling** - with transaction pinning
- **AccessBroker support** - `Schema->connect($broker)` with broker-refreshed conninfo for new pool connections
- **Sync fallback** - `->all`, `->first` etc. still work (blocking)

## Synopsis

```perl
my $schema = MyApp::Schema->connect(
    'DBIO::PostgreSQL::Async',
    {
        host      => 'localhost',
        dbname    => 'myapp',
        pool_size => 10,
    },
);

use DBIO::AccessBroker::Static;

my $broker = DBIO::AccessBroker::Static->new(
    dsn      => 'dbi:Pg:dbname=myapp;host=localhost',
    username => 'myapp',
    password => 'secret',
);

my $brokered = MyApp::Schema->connect($broker);

# Async
$schema->resultset('Artist')->all_async->then(sub {
    my @artists = @_;
    say $_->name for @artists;
});

# Pipeline
$schema->storage->pipeline(sub {
    Future->needs_all(
        map { $schema->resultset('Artist')->create_async({ name => $_ }) }
        @names
    );
});

# LISTEN/NOTIFY
$schema->storage->listen('events', sub {
    my ($channel, $payload) = @_;
    say "Got: $payload";
});
```

## Async

The storage class returns [Future](https://metacpan.org/pod/Future) objects for all query operations,
enabling fully non-blocking database access.

## Pipeline

Pipeline mode batches multiple queries into a single network round-trip.

## LISTEN/NOTIFY

PostgreSQL's publish/subscribe system for real-time notifications.
Use `->listen($channel, $callback)` to subscribe and `->notify($channel, $payload)` to emit.

## Event Loop Compatibility

EV::Pg uses the EV event loop. This works with:

- **EV** directly
- **AnyEvent** (uses EV as backend when available)
- **IO::Async** via `IO::Async::Loop::EV`
- **Mojolicious** via `Mojo::Reactor::EV`

## Testing

```bash
# Load tests (skip without EV::Pg)
prove -l t/00-load.t t/01-storage-api.t

# Integration tests (need PostgreSQL + EV::Pg)
DBIO_TEST_PG_DSN='dbname=testdb' prove -l t/10-integration.t
```

## Requirements

- libpq >= 14 (PostgreSQL client library)
- EV::Pg >= 0.02, < 0.03
- Future >= 0.49
- DBIO

## Copyright

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.