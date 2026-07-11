# DBIx-QuickDB developer/agent notes

## Running tests

ALWAYS set `AUTHOR_TESTING=1` when running tests in this repo, use `-j16`
concurrency, and wrap in a timeout so a hung server cannot stall a run
(the full suite finishes in ~5 minutes at `-j16`):

    timeout 600 env AUTHOR_TESTING=1 prove -Ilib -r t -j16

Without `AUTHOR_TESTING` the suite only exercises the system-installed
database servers. With it, the test helpers also scan `~/dbs/*/bin` for
developer installs of MariaDB/MySQL/Percona/PostgreSQL and run every
applicable test once per install, each in a forked subprocess with that
install's bin dir prepended to `$PATH`. The scan is live: drop a new install
under `~/dbs/<name>/bin` and it is picked up automatically; delete one and it
disappears. Nothing is hardcoded.

Nothing in `lib/` knows about `~/dbs` — it is a developer-only convention that
must never leak into shipped code.

Concurrency math: each test file runs up to `QDB_INSTALL_JOBS` (default 4)
install subprocesses at once, and `prove -j16` runs 16 files at once, so the
worst-case fan-out is ~64 install children (each with its own db server and
watcher). That is measured-fine on the primary dev box (~2.5 min suite); on a
smaller machine lower one or both knobs (e.g. `QDB_INSTALL_JOBS=2` and/or
`-j8`) — System V IPC (PostgreSQL semaphores) and RAM are the limits that
bite first.

## Editing the per-install test machinery

The parent process of a per-install test file must NEVER load `DBIx::QuickDB`,
its drivers, or `Test2::Tools::QuickDB`. The drivers capture `$PATH` at load
time (BEGIN blocks in the PostgreSQL driver) and in private lexical caches
(`%PROVIDER_CACHE` in the MySQL driver) that a forked child inherits, which
silently defeats the per-install `$PATH`. All DBIx::QuickDB code loads inside
the forked children only. Read the comments in `t/lib/QDB/Installs.pm` before
touching the test wrappers.
