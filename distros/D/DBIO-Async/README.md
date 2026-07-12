# DBIO-Async

Shared, loop-agnostic async layer for [DBIO](https://metacpan.org/pod/DBIO)
drivers.

`DBIO::Async::Storage` is a concrete, DB-agnostic async-storage skeleton that
subclasses core
[DBIO::Storage::Async](https://metacpan.org/pod/DBIO::Storage::Async). It hosts
the generic machinery every async driver needs — the CRUD runner, transaction
pinning, pipeline bracketing, sync `->get` fallbacks, AccessBroker wiring —
plus an isolated [Future::IO](https://metacpan.org/pod/Future::IO) watcher
seam. A DB-specific driver subclasses it and supplies only the DB-specific
hooks (submit query, collect result, transform SQL, connect-info shape, socket
fd). The Future / Future::IO requirements live here, not in each driver, so a
sync-only driver pulls no async dependencies.

## Activation — the `future_io` mode

Async is an explicit per-connection *mode* (core ADR 0030/0031). Loading
`DBIO::Async` registers the `future_io` mode against the core storage; a schema
connected with `{ async => 'future_io' }` then builds the `DBIO::Async::Storage`
backend for its `*_async` methods. There is no auto-fallback — the mode is
explicit or the connection stays synchronous.

```perl
use DBIO::Async;   # registers the 'future_io' mode

my $schema = MyApp::Schema->connect(
    $dsn, $user, $pass, { async => 'future_io' },
);

$schema->resultset('Artist')->all_async->then(sub { ... });
```

## Synopsis

```perl
package DBIO::PostgreSQL::Storage::Async;   # convention: ref($storage).'::Async'
use base 'DBIO::Async::Storage';

# Supply only the DB-specific seam hooks:
sub _submit_query   { ... }   # submit an async query, return a Future
sub _collect_result { ... }   # read the ready result off the socket
sub _conn_fileno    { ... }   # the fd to watch with Future::IO
sub _transform_sql  { ... }   # e.g. '?' -> '$N' (or identity)
# ... plus connect-info shape, post-insert SQL, pool create/shutdown, ...
```

## Description

This distribution carries the Future-ecosystem requirements and the shared
Future::IO transport base over the core Model-B orchestration. It ships **no**
DB-specific code — that stays in each driver's convention-resolved adapter
(`DBIO::PostgreSQL::Storage::Async`, a future `DBIO::MySQL::Storage::Async`, …),
loaded by `{ async => 'future_io' }` (karr #65). The watcher seam is loop-agnostic:
`Future::IO`'s default implementation is `IO::Poll` (core, no event loop), and
it auto-routes through IO::Async / AnyEvent / Mojo / UV / Glib when the
matching `Future::IO::Impl::*` module is installed. The user picks the loop; no
event loop is a hard requirement (core ADR 0014).

## License

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
