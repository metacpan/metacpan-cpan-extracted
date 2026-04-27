# Async Job Queue Example

This example demonstrates Async::Redis running a small Redis-backed job queue in
one Perl process.

It intentionally keeps the app simple:

- one controller connection queues jobs and coordinates shutdown
- one Redis connection per worker waits in `BLPOP`
- one stats connection prints heartbeat lines
- workers simulate slow work with `Future::IO->sleep`

The point is to make async behavior visible. While workers are blocked in
`BLPOP` or waiting on simulated work, the heartbeat keeps printing and other
workers continue making progress.

## Running

Start Redis from the project root:

```bash
docker compose -f examples/docker-compose.yml up -d
```

Run the demo:

```bash
REDIS_HOST=localhost perl examples/async-job-queue/app.pl
```

Run a shorter smoke test:

```bash
REDIS_HOST=localhost perl examples/async-job-queue/app.pl --jobs 6 --workers 2 --delay 0.2
```

## Options

```text
examples/async-job-queue/app.pl [options]

Options:
  --jobs N       number of jobs to enqueue, default 10
  --workers N    number of workers, default 2
  --delay SEC    simulated seconds per job, default 1.5
  --help         show usage
```

Environment:

- `REDIS_HOST` - Redis hostname, default `localhost`
- `REDIS_PORT` - Redis port, default `6379`

## Example Output

```text
[ 0.00s] queued 6 jobs
[ 0.01s] worker-1 started job-1
[ 0.01s] worker-2 started job-2
[ 0.25s] heartbeat queue=4 in_flight=2 processed=0
[ 1.51s] worker-1 finished job-1 processed=1
[ 1.51s] worker-2 finished job-2 processed=2
[ 1.51s] worker-1 started job-3
[ 1.51s] worker-2 started job-4
[ 1.75s] heartbeat queue=2 in_flight=2 processed=2
[ 4.55s] done processed=6 workers=2 elapsed=4.55s sequential_about=9.00s
```

The important lines are the heartbeat lines. They show the process is still
doing useful work while workers are blocked on Redis or sleeping between job
start and finish.

## Why Each Worker Has Its Own Redis Connection

`BLPOP` is a Redis blocking command. A connection sitting inside `BLPOP` cannot
also be used for unrelated commands until Redis replies.

This example gives each worker its own connection so one worker can wait for
jobs without blocking:

- the controller from enqueueing or sending stop sentinels
- the stats task from reading queue depth and processed counts
- other workers from claiming and processing jobs

This is a demo queue, not a production queue implementation. It does not handle
durable retries, worker crash recovery, dead-letter queues, or job schemas.
