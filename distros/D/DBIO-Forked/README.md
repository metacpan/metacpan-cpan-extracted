# DBIO-Forked

Dependency-free, fork-based async layer for
[DBIO](https://metacpan.org/pod/DBIO) drivers.

`DBIO::Forked::Storage` is a generic async-storage backend that makes **any**
sync DBIO driver async — without an async-capable database client and without
an event loop. It subclasses core
[DBIO::Storage::Async](https://metacpan.org/pod/DBIO::Storage::Async) and runs
each query in a `fork()`ed child that speaks the ordinary sync driver,
streaming the result rows back to the parent over a pipe. The parent returns a
`DBIO::Forked::Future` immediately.

It is a sibling of [DBIO::Async](https://metacpan.org/pod/DBIO::Async) on the
same layer — both satisfy the core `DBIO::Storage::Async` contract — but they
take opposite routes:

- **DBIO::Async** — `Future::IO` over a driver's own async binding (the
  non-blocking interface DBD::Pg / DBD::mysql expose themselves).
- **DBIO::Forked** — `fork()` + pipe + the plain sync driver in the child.
  Works for every driver, including the ones that will never get a native
  async client (Oracle, SQLite, DB2, Sybase, ...).

## Activation

Loading `DBIO::Forked` registers a generic `forked` async mode on core
(ADR 0030); a user opts a connection into it at `connect` time:

```perl
use DBIO::Forked;
my $schema = MyApp::Schema->connect($dsn, $user, $pass, { async => 'forked' });
```

A connection opened with `{ async => 'forked' }` answers the `*_async` methods
(and the ResultSet/Row `*_async` helpers) through `DBIO::Forked::Storage`; one
opened without it stays fully synchronous (its `*_async` croak — no
auto-selection). The core resolver builds `DBIO::Forked::Storage->new($schema)`
and feeds it the DBI-form connect info; each async query forks a child that
reconnects the sync driver fresh before running the query.

## Dependency posture

Only core Perl — `fork`, `pipe`, `Storable` (serialization), `IO::Select`
(waiting) — plus DBIO core. **No** `Future`, `Future::IO`, event loop or
async DB client. That is the whole point: turning a sync driver async pulls in
none of the async ecosystem.

## Execution model

Model A — one short-lived `fork()` per query. The child inherits the entire
parent memory (including the real driver's sync storage), throws away the
inherited DBI handle (the fork trap that `DBIO::Storage::DBI` already guards
against), reconnects fresh from the DBI-form connect info, runs the driver's
**ordinary** sync CRUD (no SQL is re-implemented in `DBIO::Forked`), serializes
the result rows back over the pipe with `Storable`, and exits. The parent
returns a `DBIO::Forked::Future` bound to the pipe read fd: `is_ready` peeks
non-blocking, `get` blocks for the result and reaps the child.

## Status

Scaffold + architecture skeleton. The fork-per-query mechanics and the
Future's fd / `IO::Select` plumbing are not yet implemented.

## License

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
