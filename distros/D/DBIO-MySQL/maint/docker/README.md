# dbio-mysql — live MySQL server and genuine-DBD::mysql test image

Two jobs, one resource-capped MySQL 8.0 server:

- the database for the **whole live suite run from the host** (over
  `DBD::MariaDB`), see *Whole live suite from the host* below;
- live-verifying the **DBD::mysql (`mysql_*`) async path** of
  `DBIO::MySQL::Storage::Async` against that server, on a host where
  `DBD::mysql` **cannot be built** natively.

## Whole live suite from the host

```bash
cd maint/docker && docker compose up -d --wait mysql
cd ../..
DBIO_TEST_MYSQL_DSN='dbi:MariaDB:database=dbio_test;host=127.0.0.1;port=3306' \
DBIO_TEST_MYSQL_USER=dbio DBIO_TEST_MYSQL_PASS=dbio \
  ../dbio/maint/capped-test prove -lr t/      # serial, never -j
(cd maint/docker && docker compose down -v)    # ALWAYS
```

The server is prepared so this needs no manual step (karr k104):

- `--log-bin-trust-function-creators=1` — MySQL 8 runs with the binary log on,
  and then a user without `SUPER` may not create triggers or stored routines
  (`t/78` creates a trigger, `t/79` a procedure). The flag lifts only that
  requirement and keeps the binlog on, as servers in the wild run it.
- `initdb/dbio-grants.sql` grants `dbio` everything on the databases named
  `dbio\_k%` (the scratch databases the live tests create, `dbio_k<NN>_<pid>`)
  and `\_dbio\_tmp\_%` (the diff's temp databases, `DBIO::MySQL::Deploy`).
  Database-level, by name pattern; no global privilege. Init scripts run only
  on an empty data dir — another reason for `down -v` after every run.

The port is published on `127.0.0.1:3306` only; a MySQL already listening on
the host's 3306 conflicts with it. The same suite inside the container, over
genuine `DBD::mysql`: `docker compose run --rm test t/`.

## Why this image exists

`DBIO::MySQL` speaks to MySQL through two DBI drivers, and ships one async
transport per driver (ADR 0030/0031):

| DSN            | DBD driver     | async storage class                       | binding    |
|----------------|----------------|-------------------------------------------|------------|
| `dbi:MariaDB:` | DBD::MariaDB   | `DBIO::MySQL::Storage::MariaDB::Async`     | `mariadb_*`|
| `dbi:mysql:`   | DBD::mysql     | `DBIO::MySQL::Storage::Async` (base)       | `mysql_*`  |

The `mariadb_*` path is already live-verified (`t/55` against a `dbi:MariaDB:`
DSN — `DBD::MariaDB` bundles its own MariaDB Connector/C and builds anywhere).

The **`mysql_*` path could not be** — `DBD::mysql` (5.013+) needs the *genuine
Oracle* `libmysqlclient` development headers (`MYSQL_OPT_*` / `SSL_MODE_*`
constants). Debian 12/13 (this host's default, and the `perl:5.40` base image)
ship **MariaDB-flavoured** `default-libmysqlclient-dev` / `libmariadb-dev`,
which lack those constants, so `DBD::mysql` fails to compile on the host.

This mirrors the class of problem `dbio-postgresql-ev/maint/docker/Dockerfile.test`
solves for `libpq` (Debian's library was the wrong flavour/version for the XS
module). Here the fix is simpler than the PostgreSQL multi-stage lift:

> **Ubuntu still packages the genuine Oracle MySQL 8 client.** Ubuntu maintains
> the `mysql-8.0` source package from Oracle, so its `libmysqlclient-dev` is the
> real thing, with the `MYSQL_OPT_*` / `SSL_MODE_*` constants. Debian switched
> its `libmysqlclient-dev` provider to MariaDB; Ubuntu did not.

So `Dockerfile.test` is simply an **`ubuntu:24.04`** base with
`libmysqlclient-dev` + `DBD::mysql` — no MySQL APT repo, no GPG dance. (The
MySQL APT repo route was rejected: Oracle's `mysql-2023` signing key
**expired 2025-10-22**, and Debian trixie's strict `sqv` verifier refuses the
unsigned `InRelease` outright.)

## What it verifies

`t/55-future-io-live.t` run with a `dbi:mysql:` DSN resolves the **base**
`DBIO::MySQL::Storage::Async` adapter (not the MariaDB subclass) and drives its
`mysql_*` primitives end to end over `Future::IO` + `IO::Async`:

- non-blocking `select_async` / `insert_async` / `select_single_async`
  (`mysql_fd` socket watcher, `mysql_async_ready` / `mysql_async_result`);
- `mysql_insertid` folded onto the auto-increment PK in the returned-columns
  hashref;
- `txn_do_async` COMMIT and ROLLBACK on a pinned connection;
- the high-level `create_async` / `all_async` ResultSet/Row API.

## Layout

- `Dockerfile.test` — Ubuntu 24.04 + genuine `libmysqlclient-dev` + `DBD::mysql`.
  Source (dbio core, DBIO::Async, this dist) is **mounted**, not baked, so
  editing tests never triggers a rebuild. A build-time sanity gate fails loudly
  if the headers are ever the wrong flavour or `DBD::mysql` won't load.
- `docker-compose.yml` — brings up ONE resource-capped `mysql:8.0` server, waits
  for it, then runs the test container against a `dbi:mysql:` DSN.
- `initdb/dbio-grants.sql` — run by the server on an empty data dir: grants
  `dbio` the scratch and temp databases the live suite creates itself.
- `entrypoint.sh` — installs any cpanfile-dep delta, waits for the DB via a real
  `DBD::mysql` connect, runs the tests with the mounted dev copies on `@INC`.

## Usage

```bash
# From the repo root (dbio-mysql/):
cd maint/docker
docker compose up --build --abort-on-container-exit --exit-code-from test
docker compose down -v          # ALWAYS clean up — frees the capped DB

# Run a different test file (e.g. the whole offline suite too):
#   override the `test` service command:
docker compose run --rm test t/54-future-io-async.t t/55-future-io-live.t
```

The image is also usable standalone against any reachable MySQL:

```bash
docker build -f maint/docker/Dockerfile.test -t dbio-mysql-genuine ../..
docker run --rm \
  -e DBIO_TEST_MYSQL_DSN='dbi:mysql:database=dbio_test;host=…;port=3306' \
  -e DBIO_TEST_MYSQL_USER=dbio -e DBIO_TEST_MYSQL_PASS=dbio \
  -v "$PWD/../../../dbio:/src/dbio:ro" \
  -v "$PWD/../../../dbio-async:/src/dbio-async:ro" \
  -v "$PWD/../..:/src/dbio-mysql:ro" \
  dbio-mysql-genuine
```

## Resource discipline (small SHARED box)

See `.claude/rules/dbio-rules.md` → "Live testing". This host has been
OOM-rebooted by uncontrolled test runs. Both compose services carry
`mem_limit` + `cpus`; there is exactly **one** database. Run this stack **alone**
(never in parallel with another live DB suite), keep the harness serial (no
`prove -j`), and `docker compose down -v` when finished. `mysql:8.0` +
`mysql_native_password` matches `dbio-mysql-ev/maint/k8s/mysql-pod.yaml` and the
pod `xbin/dbio-mysql-k8s` spins up; this compose file is the self-contained,
`DBD::mysql`-flavoured alternative for the host where `DBD::mysql` will not
build.
