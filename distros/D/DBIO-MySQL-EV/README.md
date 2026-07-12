# DBIO-MySQL-EV

Async MySQL/MariaDB storage for [DBIO](https://metacpan.org/pod/DBIO) using
[EV::MariaDB](https://metacpan.org/pod/EV::MariaDB).

Bypasses DBI entirely - speaks MariaDB's C client library directly for
maximum performance with pipeline mode support.

## Features

- **Non-blocking queries** - returns Futures, never blocks the event loop
- **Pipeline mode** - batch queries in a single network round-trip (up to 64 in-flight)
- **Connection pooling** - with transaction pinning
- **AccessBroker support** - `Schema->connect($broker)` with broker-refreshed conninfo for new pool connections
- **Sync fallback** - `->all`, `->first` etc. still work (blocking)
- **Returned-columns hashref** - `insert_async` resolves with the autoinc PK + insert data, ready for `_store_inserted_columns` (ADR 0031 §3)

## Synopsis

```perl
# EV async is opt-in per connection (ADR 0030). Loading the MySQL::EV
# component is an inert marker; the { async => 'ev' } attribute on
# connect() is what activates the EV backend. The 'ev' mode is
# registered by DBIO::MySQL::Storage (the sync driver).
package MyApp::Schema;
use base 'DBIO::Schema';
__PACKAGE__->load_components(qw(MySQL MySQL::EV));

my $schema = MyApp::Schema->connect(
    'dbi:MariaDB:database=myapp;host=localhost',
    'myapp', 'secret',
    { async => 'ev' },
);

# Async queries return Futures
$schema->resultset('Artist')->all_async->then(sub {
    my @artists = @_;
    say $_->name for @artists;
});

# insert_async resolves with the returned-columns HASHREF (autoinc PK
# overlaid onto the insert data) -- MySQL has no RETURNING clause, the
# EV storage reads SELECT LAST_INSERT_ID() on the pinned connection.
$schema->storage->insert_async('artist', { name => 'Tom' })->then(sub {
    my $returned = shift;
    say "inserted, new id = $returned->{id}";
});

# Pipeline
$schema->storage->pipeline(sub {
    Future->needs_all(
        map { $schema->resultset('Artist')->create_async({ name => $_ }) }
        @names
    );
});
```

## AccessBroker

```perl
use DBIO::AccessBroker::Static;

my $broker = DBIO::AccessBroker::Static->new(
    host     => 'localhost',
    database => 'myapp',
    user     => 'myapp',
    password => 'secret',
);

# AccessBroker works with { async => 'ev' } the same way as the sync
# driver: per-spawn credentials are re-fetched and normalised for the
# EV::MariaDB native conninfo shape.
my $brokered = MyApp::Schema->connect($broker, { async => 'ev' });
```

## Async

The storage class returns [Future](https://metacpan.org/pod/Future) objects
for all query operations, enabling fully non-blocking database access. Per
ADR 0031, the return shape of each `*_async` method is binding:

- `select_async` resolves with the raw row arrayrefs (cursor `->all` shape)
- `select_single_async` resolves with a single row arrayref
- `insert_async` resolves with the **returned-columns hashref** (autoinc PK
  + supplied insert data), so `create_async` / `Row::insert_async` can fold
  it back via `_store_inserted_columns`

The `Future` returned by every method auto-wraps a plain (non-Future) return
in a `then` callback into a resolved Future (ADR 0031 §4) -- this is the
native [Future.pm](https://metacpan.org/pod/Future) behaviour, so chained
callbacks can simply `return $value` without wrapping.

## Pipeline

Pipeline mode batches multiple queries into a single network round-trip.
Up to 64 queries can be in-flight simultaneously.

## Event Loop Compatibility

EV::MariaDB uses the EV event loop. This works with:

- **EV** directly
- **AnyEvent** (uses EV as backend when available)
- **IO::Async** via `IO::Async::Loop::EV`
- **Mojolicious** via `Mojo::Reactor::EV`

## Testing

```bash
# Load tests (skip without EV::MariaDB)
prove -l t/00-load.t t/01-storage-api.t

# Integration tests (need MySQL/MariaDB + EV::MariaDB)
DBIO_TEST_MYSQL_DSN='dbi:MariaDB:database=testdb;host=localhost' \
DBIO_TEST_MYSQL_USER=root \
DBIO_TEST_MYSQL_PASS=secret \
  prove -lr t/
```

## Requirements

- EV::MariaDB >= 0.03
- Future >= 0.49
- DBIO
- DBIO::MySQL

## Copyright

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.
