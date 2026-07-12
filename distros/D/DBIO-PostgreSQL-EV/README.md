# DBIO-PostgreSQL-EV

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
# EV async is opt-in: connect with { async => 'ev' } (ADR 0030).
# The sync DBIO::PostgreSQL::Storage registers the 'ev' mode and
# resolves it to DBIO::PostgreSQL::EV::Storage -- no class-data hack,
# no runtime mode-switch, no silent degrade.
use MyApp::Schema;

my $schema = MyApp::Schema->connect(
    'dbi:Pg:dbname=myapp;host=localhost',
    'myapp', 'secret',
    { async => 'ev' },
);

# Sync still works exactly as before on a separate connection:
my $sync = MyApp::Schema->connect('dbi:Pg:dbname=myapp', 'myapp', 'secret');

# ResultSet/Row async routes through the storage backend (ADR 0031):
$schema->resultset('Artist')->all_async->then(sub {
    my @artists = @_;
    say $_->name for @artists;
});

# Storage-level async runs real non-blocking over EV::Pg:
$schema->storage->select_async('artist', ['id', 'name'], undef)->then(sub {
    my @rows = @_;
    ...
});

# insert_async resolves a returned-columns HASHREF (ADR 0031 §3):
$schema->storage->insert_async('artist', { name => 'x' })->then(sub {
    my $row = shift;   # { name => 'x', id => 42, ... }
    ...
});

# Pipeline mode, LISTEN/NOTIFY and COPY are async-only -- not routed
# through the sync storage. Reach them on the embedded async backend:
$schema->storage->async->listen('changelog', sub {
    my ($chan, $payload) = @_;
    ...
});
$schema->storage->async->pipeline(sub {
    Future->needs_all(
        map { $schema->storage->insert_async('artist', { name => $_ }) }
        @names
    );
});
```

## Async

The storage class returns [Future](https://metacpan.org/pod/Future) objects for all query operations,
enabling fully non-blocking database access. The mode is selected at
`connect` time via `{ async => 'ev' }` and fixed for the instance's lifetime.
A `*_async` call on a sync instance croaks explicitly rather than silently
degrading (ADR 0030).

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
DBIO_TEST_PG_DSN='dbi:Pg:dbname=dbio_async;host=127.0.0.1;port=5432' \
DBIO_TEST_PG_USER=dbio DBIO_TEST_PG_PASS=dbio \
  prove -l t/10-integration.t t/11-access-broker-live.t
```

## Requirements

- libpq >= 16 (PostgreSQL client library); libpq 15 hosts should use the
  [`maint/docker/Dockerfile.test`](maint/docker/Dockerfile.test) image
- EV::Pg >= 0.02, < 0.08
- Future >= 0.49
- DBIO >= 0.900000 with the `ev` mode registered by DBIO::PostgreSQL

## Copyright

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.