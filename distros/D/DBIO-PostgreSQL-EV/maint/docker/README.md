# Docker test environment

A reproducible client image for running the dbio-postgresql-ev test suite
against any reachable PostgreSQL instance.

## Why

EV::Pg >= 0.07 links against libpq symbols introduced in PostgreSQL 16
(`PQconnectionUsedGSSAPI`, `PGRES_TUPLES_CHUNK`). On hosts that ship libpq 15
(Debian 12 default), `EV::Pg.so` loads fine via lazy binding but blows up the
moment `make test` sets `PERL_DL_NONLAZY=1` and the dynamic linker tries to
resolve every undefined symbol up-front. The failure surfaces as
`No plan found in TAP output` from `make test` / `dzil test` even though
`prove -lr t/` runs green.

This image fixes that locally without touching your system libpq:

```
debian:bookworm-slim
        │ libpq 17 (lifted out of postgres:17-bookworm)
        │ Perl 5.36, cpanm, build-essential
        ▼
EV::Pg 0.07 built and linked against that libpq 17
```

The result is a self-contained image in which `prove`, `make test`, and
`dzil test` all see the same libpq and `PERL_DL_NONLAZY=1` no longer trips
on a missing symbol.

## Build

```bash
docker build -f maint/docker/Dockerfile.test -t dbio-async-test .
```

The build prints a one-line confirmation at the end (`OK: EV::Pg.so links
against libpq 17, all required symbols resolved`) which is the gate that
proves the libpq pull worked. If that line is missing, the image is broken.

## Run

### Against an existing PostgreSQL

```bash
docker run --rm \
  -e DBIO_TEST_PG_DSN='dbi:Pg:dbname=dbio_async;host=host.docker.internal;port=5432' \
  -e DBIO_TEST_PG_USER=dbio \
  -e DBIO_TEST_PG_PASS=dbio \
  dbio-async-test
```

`host.docker.internal` reaches the host's localhost from inside Docker
Desktop and recent Docker Engine versions on Linux. On older setups, use
the host's LAN IP or run Postgres in a sibling container with a shared
network.

### Single test file

```bash
docker run --rm -e DBIO_TEST_PG_DSN=... dbio-async-test -lv t/21-deploy-async-live.t
```

The container's ENTRYPOINT is `prove`, so any `prove` flag works.

### Without a database (offline lint only)

Drop the `-e DBIO_TEST_PG_DSN=...` flag. Live tests under `t/*-live.t`
self-skip on missing DSN; offline tests still run.

### Against an in-development DBIO::PostgreSQL

The CPAN release of `DBIO::PostgreSQL` lags behind the in-development
checkouts and lacks the `async_backend` hook that wires the sync storage
to this distribution's async backend. Live tests (`t/*-live.t`) will
silently fall back to `DBIO::Test::Future` and `select_async`/`insert_async`
will block the event loop forever.

Mount the dev `dbio-postgresql` lib tree at `/extra-lib` (or anywhere,
the entrypoint script honors `$EXTRA_LIB_DIR`):

```bash
docker run --rm --network host \
  -v /storage/raid/home/getty/perl5/lib/perl5:/extra-lib:ro \
  -e DBIO_TEST_PG_DSN='dbi:Pg:dbname=dbio_async;host=127.0.0.1;port=5432' \
  -e DBIO_TEST_PG_USER=dbio \
  -e DBIO_TEST_PG_PASS=dbio \
  dbio-async-test -lr t/21-deploy-async-live.t
```

The entrypoint prepends `/extra-lib` to `PERL5LIB` so the mounted copy
wins over the CPAN release baked into the image. This is the same
pattern DBIO's own test harness uses locally; the image just isolates
the libpq-17 / EV::Pg-0.07 toolchain so a developer's system Perl
doesn't have to.

## cpanfile

`cpanfile` pins `EV::Pg >= 0.02, < 0.08` (karr #16). The 0.02.x line is
verified on libpq 15; 0.07.x added the libpq-16+ symbols
(`PQconnectionUsedGSSAPI`, `PGRES_TUPLES_CHUNK`) the image's libpq 17 has.
Hosts on libpq 15 (Debian 12 default) should run this image; libpq 16+ hosts
can install straight from cpanfile.

## Scope

This image is the CLIENT only. PostgreSQL itself can live wherever the
caller wants:

- `docker run postgres:17 ...` (sibling container, same network)
- `maint/k8s/pg-pod.yaml` (existing Kubernetes reference)
- A system install on the host
- A managed service

The image deliberately does NOT bundle a Postgres server — keep the two
concerns (client build, server choice) separated so each can evolve
independently.