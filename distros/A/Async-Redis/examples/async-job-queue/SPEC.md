# Async Job Queue Example Specification

## Goal

Create a small CLI example that makes Async::Redis concurrency visible without
requiring a web framework or extra UI.

The example should prove three things:

- Redis list commands can model a simple job queue.
- multiple async workers can process jobs concurrently in one Perl process.
- a heartbeat task keeps running while workers wait in `BLPOP` and while other
  tasks are sleeping or doing Redis I/O.

## Location

- executable: `examples/async-job-queue/app.pl`
- documentation: `examples/async-job-queue/README.md`
- examples index update: `examples/README.md`

## User Story

As a new Async::Redis user, I can run one command and see jobs being queued,
claimed by workers, processed concurrently, and reported by a heartbeat while
the process remains responsive.

## Runtime Behavior

The app should:

- connect to Redis using `REDIS_HOST` and `REDIS_PORT`, defaulting to
  `localhost` and `6379`
- clean only its own demo keys at startup
- enqueue a burst of jobs immediately so the queue depth is visible
- start a fixed number of worker coroutines
- start one heartbeat coroutine
- exit automatically after all jobs are processed
- clean up its worker unblock sentinels before exit

Default values:

- jobs: `10`
- workers: `2`
- simulated work delay: `1.5` seconds
- heartbeat interval: `0.25` seconds
- queue key: `async-job-queue:jobs`
- processed counter key: `async-job-queue:processed`
- in-flight set key: `async-job-queue:in-flight`

## Async Design

Use separate Redis connections for roles that can block independently:

- one producer/controller connection
- one stats connection
- one Redis connection per worker

Workers must use `BLPOP` so the example demonstrates a real Redis blocking
operation. Each worker connection may sit inside `BLPOP` without preventing the
producer, heartbeat, or other workers from making progress.

Workers should simulate job processing with `Future::IO->sleep($delay)` rather
than CPU work. The point is event-loop concurrency, not parallel CPU execution.

The app should coordinate all tasks with futures, for example:

- producer future enqueues all jobs
- worker futures loop until they receive a stop sentinel
- heartbeat future loops until the processed count reaches the target
- main future waits for producer, workers, and heartbeat to finish

## Queue Semantics

Startup:

- delete `async-job-queue:jobs`
- delete `async-job-queue:processed`
- delete `async-job-queue:in-flight`
- push jobs `job-1` through `job-N`

Worker loop:

- `BLPOP async-job-queue:jobs 0`
- if the value is a stop sentinel, exit
- add the job to `async-job-queue:in-flight`
- print that the worker started the job
- `await Future::IO->sleep($delay)`
- remove the job from `async-job-queue:in-flight`
- increment `async-job-queue:processed`
- print that the worker finished the job

Shutdown:

- after all real jobs are processed, push one stop sentinel per worker
- workers consume sentinels and exit
- final summary prints elapsed time, processed count, and expected sequential
  time

The stop sentinel should be a value that cannot collide with generated job
names, for example `__async_job_queue_stop__`.

## Output Requirements

Output must be human-readable and timestamped relative to process start.

It should make queueing and async behavior obvious. Example shape:

```text
[ 0.00s] queued 10 jobs
[ 0.01s] worker-1 started job-1
[ 0.01s] worker-2 started job-2
[ 0.25s] heartbeat queue=8 in_flight=2 processed=0
[ 1.51s] worker-1 finished job-1
[ 1.51s] worker-1 started job-3
[ 1.51s] worker-2 finished job-2
[ 1.51s] worker-2 started job-4
[ 1.75s] heartbeat queue=6 in_flight=2 processed=2
[ 7.55s] done processed=10 workers=2 elapsed=7.55s sequential_about=15.00s
```

The README should explain that the heartbeat lines are the key proof: the
process continues running other async work while workers are blocked in Redis
or waiting on simulated work.

## CLI

Keep the first version simple, but allow the demo to be tweaked:

```text
examples/async-job-queue/app.pl [options]

Options:
  --jobs N       number of jobs to enqueue, default 10
  --workers N    number of workers, default 2
  --delay SEC    simulated seconds per job, default 1.5
  --help         show usage
```

Validation:

- `--jobs` must be a positive integer
- `--workers` must be a positive integer
- `--delay` must be a positive number

## Dependencies

Use only modules already required by the distribution or Perl core where
possible:

- `Async::Redis`
- `Future`
- `Future::AsyncAwait`
- `Future::IO`
- `Getopt::Long`
- `Time::HiRes`
- `FindBin`

Do not require PAGI, AnyEvent, IO::Async-specific setup, or a web server.

## Documentation Requirements

`examples/async-job-queue/README.md` should include:

- what the example demonstrates
- how to start Redis with the existing `examples/docker-compose.yml`
- how to run the app from the project root
- sample output
- why separate worker connections are used
- what to look for in the output

`examples/README.md` should add an `async-job-queue` section with a short
description and one run command.

## Test And Verification Plan

Manual smoke test:

```bash
perlbrew use perl-5.40.0@default
docker compose -f examples/docker-compose.yml up -d
REDIS_HOST=localhost perl examples/async-job-queue/app.pl --jobs 6 --workers 2 --delay 0.2
```

Expected:

- exits with status `0`
- prints an initial queued line
- prints heartbeat lines while jobs are still running
- prints worker start and finish lines from both workers
- final summary reports `processed=6`
- elapsed time is closer to `(jobs / workers) * delay` than `jobs * delay`

Automated lightweight check, if added later:

- run the app with `--jobs 4 --workers 2 --delay 0.05`
- assert exit status `0`
- assert output contains `queued 4 jobs`
- assert output contains `heartbeat`
- assert output contains both `worker-1` and `worker-2`
- assert output contains `done processed=4`

## Non-Goals

- no durable retry/dead-letter queue
- no job payload schema
- no worker crash recovery
- no Redis Streams
- no connection pool abstraction
- no benchmark claims beyond a simple sequential-time comparison

This is an educational example, not a production queue implementation.
