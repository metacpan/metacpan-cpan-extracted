# Async Job Queue Example Implementation Plan

## Goal

Implement `examples/async-job-queue/` from
`examples/async-job-queue/SPEC.md`: a small CLI demo that visibly proves
Async::Redis can run a Redis-backed job queue concurrently in one Perl process.

The demo should show:

- a burst of jobs queued immediately
- two or more workers claiming and processing jobs concurrently
- a heartbeat that keeps printing while workers are blocked in `BLPOP` or
  sleeping during simulated work
- automatic shutdown after all jobs are processed

## Constraints

- Work only on the async-job-queue example and the examples index.
- Do not touch existing dirty stress files:
  - `examples/stress/lib/Stress/Chaos.pm`
  - `examples/stress/lib/Stress/Harness.pm`
- Use `perlbrew use perl-5.40.0@default` for all Perl checks.
- Keep the example dependency-light: no PAGI, no web server, no event-loop
  backend setup beyond `Future::IO`.
- Use explicit paths when staging later; do not use `git add -A`.

## Files

Create:

- `examples/async-job-queue/app.pl`
- `examples/async-job-queue/README.md`

Modify:

- `examples/README.md`

Existing spec:

- `examples/async-job-queue/SPEC.md`

## Step 1: Preflight And Scope Check

At the start, confirm the current branch and dirty tree:

```bash
git status --short --branch
```

Review:

- confirm unrelated stress changes are still present and will not be edited
- confirm the new spec exists and matches the desired behavior
- confirm Redis can be started with `examples/docker-compose.yml` if needed

No code changes in this step.

## Step 2: Add CLI Skeleton

Create `examples/async-job-queue/app.pl` with:

- shebang: `#!/usr/bin/env perl`
- `use strict; use warnings;`
- `FindBin` plus `use lib "$Bin/../../lib";`
- imports for `Future`, `Future::AsyncAwait`, `Future::IO`, `Getopt::Long`,
  and `Time::HiRes`
- option parsing for `--jobs`, `--workers`, `--delay`, `--help`
- validation for positive jobs, workers, and delay
- a `usage()` helper
- an empty `main()` async function wired to `->get`

Verification:

```bash
perlbrew use perl-5.40.0@default
perl -c examples/async-job-queue/app.pl
perl examples/async-job-queue/app.pl --help
perl examples/async-job-queue/app.pl --jobs 0
```

Expected:

- syntax check passes
- `--help` prints usage and exits `0`
- invalid `--jobs 0` exits non-zero with a clear message

Review after step:

- CLI defaults match the spec
- validation cannot silently accept bad values
- no Redis code yet
- no unrelated files changed

## Step 3: Add Redis Connections And Startup Cleanup

Add:

- constants for queue, processed counter, in-flight set, and stop sentinel
- `redis_args()` reading `REDIS_HOST` and `REDIS_PORT`
- `connect_redis($role)` helper
- `cleanup_demo_keys($redis)` that deletes only demo keys
- startup logging with relative timestamps

For this step, `main()` should connect a controller client, clean demo keys,
print a short success line, disconnect, and exit.

Verification:

```bash
perlbrew use perl-5.40.0@default
perl -c examples/async-job-queue/app.pl
REDIS_HOST=localhost perl examples/async-job-queue/app.pl --jobs 1 --workers 1 --delay 0.1
```

Expected:

- exits `0` when Redis is available
- fails clearly when Redis is unavailable
- only keys with the `async-job-queue:` prefix are touched

Review after step:

- connection errors are understandable
- cleanup is scoped and not `FLUSHDB`
- connections are disconnected on the happy path
- no blocking or async worker logic yet

## Step 4: Implement Producer Burst

Add:

- `enqueue_jobs($redis, $jobs)` helper
- immediate burst enqueue of `job-1` through `job-N`
- initial output line: `queued N jobs`
- queue depth check with `LLEN`

For this step, enqueue jobs and then clean them up before exit so repeated
manual runs do not leave queue entries behind.

Verification:

```bash
perlbrew use perl-5.40.0@default
perl -c examples/async-job-queue/app.pl
REDIS_HOST=localhost perl examples/async-job-queue/app.pl --jobs 3 --workers 1 --delay 0.1
```

Expected:

- output includes `queued 3 jobs`
- queue depth reaches `3` before cleanup
- process exits `0`

Review after step:

- job naming cannot collide with the stop sentinel
- repeat runs start cleanly
- no worker logic has been mixed into producer helpers

## Step 5: Implement One Worker Loop

Add:

- `worker($id, $opts)` async helper
- one dedicated Redis connection per worker
- `BLPOP $queue_key 0`
- sentinel handling
- in-flight set add/remove
- simulated work with `Future::IO->sleep($delay)`
- processed counter increment
- worker start/finish output

Initially wire one worker and have the controller push one sentinel after all
jobs are processed.

Verification:

```bash
perlbrew use perl-5.40.0@default
perl -c examples/async-job-queue/app.pl
REDIS_HOST=localhost perl examples/async-job-queue/app.pl --jobs 2 --workers 1 --delay 0.1
```

Expected:

- both jobs are started and finished by `worker-1`
- final processed count is `2`
- worker exits after consuming the sentinel

Review after step:

- `BLPOP` response shape is handled correctly
- worker disconnects even on normal sentinel exit
- in-flight set is cleaned after each job
- no busy polling

## Step 6: Run Multiple Workers Concurrently

Change `main()` to start `$workers` worker futures concurrently and wait for
them all to finish.

Shutdown should push one sentinel per worker after all real jobs are processed.

Verification:

```bash
perlbrew use perl-5.40.0@default
perl -c examples/async-job-queue/app.pl
REDIS_HOST=localhost perl examples/async-job-queue/app.pl --jobs 4 --workers 2 --delay 0.2
```

Expected:

- output shows both `worker-1` and `worker-2`
- the first two jobs start near the same timestamp
- elapsed time is closer to `0.4s` than `0.8s`
- final processed count is `4`

Review after step:

- each worker uses its own Redis connection
- all worker futures are awaited
- sentinels cannot be counted as processed jobs
- no worker can be left blocked after completion

## Step 7: Add Heartbeat Task

Add:

- separate stats Redis connection
- `heartbeat($opts)` async helper
- heartbeat loop every `0.25s`
- output with `queue=`, `in_flight=`, and `processed=`
- stop condition when processed count reaches target

Verification:

```bash
perlbrew use perl-5.40.0@default
perl -c examples/async-job-queue/app.pl
REDIS_HOST=localhost perl examples/async-job-queue/app.pl --jobs 6 --workers 2 --delay 0.2
```

Expected:

- heartbeat lines appear while jobs are still running
- heartbeat continues while workers are sleeping
- queue depth starts above zero and drains
- in-flight count reflects active workers

Review after step:

- heartbeat uses its own Redis connection
- heartbeat exits naturally after target processed count
- heartbeat interval is not implemented with blocking sleep
- output remains readable

## Step 8: Final Summary And Cleanup

Add final summary:

- processed count
- worker count
- elapsed seconds
- approximate sequential time: `jobs * delay`

Add final cleanup:

- remove stop sentinels if any remain
- delete in-flight set
- leave or clean the processed counter based on what reads better for the demo;
  prefer cleanup at startup over cleanup at exit so the final state can be
  inspected briefly if desired

Verification:

```bash
perlbrew use perl-5.40.0@default
perl -c examples/async-job-queue/app.pl
REDIS_HOST=localhost perl examples/async-job-queue/app.pl --jobs 10 --workers 2 --delay 0.1
```

Expected:

- final line includes `done processed=10 workers=2`
- elapsed time is meaningfully lower than sequential estimate
- process exits `0`

Review after step:

- cleanup cannot delete non-demo keys
- final numbers are internally consistent
- failures preserve useful error messages
- no dead code from earlier skeleton steps remains

## Step 9: Add README

Create `examples/async-job-queue/README.md` with:

- what the example demonstrates
- how to start Redis using `examples/docker-compose.yml`
- how to run from the project root
- sample output
- explanation of separate worker connections for `BLPOP`
- what to look for to prove async behavior
- note that this is educational, not a production queue

Verification:

```bash
perlbrew use perl-5.40.0@default
perl -c examples/async-job-queue/app.pl
```

Manual review:

- commands are copy-pasteable from repo root
- sample output matches current app output shape
- README does not overclaim production readiness

## Step 10: Update Examples Index

Modify `examples/README.md` to add an `async-job-queue` section.

Include:

- one-paragraph description
- one run command
- link to `async-job-queue/README.md`

Verification:

```bash
perlbrew use perl-5.40.0@default
perl -c examples/async-job-queue/app.pl
```

Manual review:

- ordering in examples index is sensible
- no existing examples text was accidentally changed

## Step 11: End-To-End Smoke Test

Run the canonical smoke test:

```bash
perlbrew use perl-5.40.0@default
REDIS_HOST=localhost perl examples/async-job-queue/app.pl --jobs 6 --workers 2 --delay 0.2
```

Expected:

- exits `0`
- prints `queued 6 jobs`
- prints at least one `heartbeat` line before completion
- prints `worker-1` and `worker-2`
- prints `done processed=6`

If Redis access is blocked by the sandbox, rerun with escalation rather than
changing the app.

Review after step:

- no warnings
- no hanging worker process
- output demonstrates the intended async behavior without explanation

## Step 12: Related Test Suite Check

Run focused tests for areas touched by the example:

```bash
perlbrew use perl-5.40.0@default
prove -lr t/70-blocking t/01-unit
```

Expected:

- all tests pass, or Redis-backed tests skip only if Redis is unavailable

Review after step:

- example did not require library changes
- any failure is investigated before proceeding

## Step 13: Final Review

Before considering the work complete:

```bash
git status --short --branch
git diff -- examples/async-job-queue examples/README.md
```

Review:

- only intended files changed
- unrelated stress modifications are untouched
- CLI behavior matches `SPEC.md`
- README and examples index match the implemented command names
- code has no dead helpers, unused imports, or misleading comments
- no security issue from accepting arbitrary Redis key prefixes because keys
  are hardcoded to the demo namespace

## Optional Follow-Up

If a future automated example test is desired, add a lightweight test that runs:

```bash
REDIS_HOST=localhost perl examples/async-job-queue/app.pl --jobs 4 --workers 2 --delay 0.05
```

and asserts output contains:

- `queued 4 jobs`
- `heartbeat`
- `worker-1`
- `worker-2`
- `done processed=4`

Do not add this unless the project wants Redis-backed example tests in the
normal test suite.
