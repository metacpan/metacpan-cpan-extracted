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
checkouts. What the live tests need from it is the `ev` async-mode
registration: the **sync** driver `DBIO::PostgreSQL::Storage` calls
`register_async_mode( ev => 'DBIO::PostgreSQL::EV::Storage' )`, and core
resolves the mode by walking the storage MRO. Against a release that predates
that registration, `connect(..., { async => 'ev' })` has nothing to resolve and
the first async call croaks with `async mode 'ev' is not available -- no driver
or add-on registers it`. That is loud by design (core ADR 0030 §3: explicit or
it croaks — there is no fallback backend and nothing degrades silently), but
the suite still cannot run until the newer driver is on `@INC`.

Mount the dev `dbio-postgresql` lib tree at `/extra-lib` (or anywhere,
the entrypoint script honors `$EXTRA_LIB_DIR`):

```bash
docker run --rm --network host \
  -v $HOME/perl5/lib/perl5:/extra-lib:ro \
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

`cpanfile` pins `EV::Pg >= 0.02, < 0.08` (karr k16). Hosts on libpq 15
(Debian 12 default) should run this image; libpq 16+ hosts can install
straight from cpanfile.

## EV::Pg 0.02 on libpq 15 (karr k77)

`Dockerfile.libpq15` builds the other end of the range: EV::Pg 0.02 against
the libpq 15.19 of Debian 12, nothing baked in but the client (mount the tree
and the family `lib/` directories at run time, see below). Measured:

- EV::Pg 0.02 already references `PQconnectionUsedGSSAPI`. It loads lazily
  (`perl -MEV::Pg`) and fails under `PERL_DL_NONLAZY=1` with `undefined
  symbol: PQconnectionUsedGSSAPI` -- exactly as 0.07 does. So on libpq 15
  `make test` / `dzil test` break with either end of the range; the claim
  "0.02.x is the verified line on libpq 15" held only for a lazy load.
- Offline suite (`prove -lr t/`, 106 files) against 0.02 / libpq 15: green,
  7208 tests, live files skipped. The mock tests use a stand-in EV::Pg, so
  they say little about 0.02 itself; t/34 needs EV >= 4.37 (the image's
  Debian EV 4.33 fails its parent-after-fork checks 11-15, EV 4.37 passes).
- Live suite against 0.02 / libpq 15: not run (the cluster access token had
  expired), so the real 0.02 code paths are still unmeasured.

```bash
DOCKER_BUILDKIT=0 docker build -f maint/docker/Dockerfile.libpq15 -t dbio-pgev-libpq15 maint/docker
docker run --rm --memory 1g --memory-swap 1g --cpus 2 \
  -v "$PWD/..":/fam:ro -v "$PWD":/src:ro -w /src \
  -e PERL5LIB=/fam/dbio/lib:/fam/dbio-async/lib:/fam/dbio-postgresql/lib \
  --env-file <(env | grep ^DBIO_TEST_) \
  dbio-pgev-libpq15 -l -r t/
```

The image has no DBIO or Future deps beyond Debian's; install the cpanfiles of
core, dbio-async, dbio-postgresql and this dist with `cpanm --installdeps`
on top (and `cpanm EV`) before running.

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