# Async::Redis Stress Harness

A long-running CLI harness that drives Async::Redis hard enough — and
unpredictably enough — to surface latent bugs. Used both as a soak
test and as a CI smoke gate.

## What it does

Five concurrent workloads against Redis, on a single event loop:

| Workload  | What it exercises                                                       |
|-----------|-------------------------------------------------------------------------|
| KV        | Pool of N connections doing alternating SET/GET on bucketed keys        |
| Autopipe  | A single client batching SETs through `auto_pipeline => 1`              |
| Blocking  | M clients looping BLPOP, paced by an LPUSH driver                       |
| Pubsub    | Subscriber on K channels; publisher round-robins; per-channel seq check |
| Pattern   | psubscribe on `prefix:*`; publisher randomizes suffixes; drop check     |

Every `--kill-interval` seconds, a controller client (tagged
`stress-controller` and never killed) issues `CLIENT KILL ADDR`
against a random workload client. Integrity assertions split errors
by chaos-window membership: gaps during the recovery window after a
kill are expected; outside the window they're anomalies.

## Running

```bash
docker compose -f examples/docker-compose.yml up -d
REDIS_HOST=localhost ./examples/stress/stress --duration 60 --kill-interval 10
```

Output:

- **stderr**: a one-line-per-second human snapshot.
- **stdout**: one JSON record per second; one summary record on exit.

Slice the run with `jq`:

```bash
./examples/stress/stress --duration 60 --quiet | jq '.throughput.get'
```

## Exit codes

- `0` clean exit (`--duration` elapsed or SIGINT) with zero integrity violations.
- `1` integrity violation (sequence regression, drop outside chaos, queue conservation broken).
- `2` hang (a workload future did not unwind within `--command-deadline`).
- `3` configuration error.

## Interpreting output

Each JSONL record looks like:

```
{"kind": "metric", "t": 1761350400.123, "elapsed_s": 42.5,
 "throughput": {"get": 4231, "set": 3899},
 "latency_ms": {"get": {"p50": 0.4, "p95": 1.2, "p99": 4.8}},
 "errors_typed": {"Async::Redis::Error::Disconnected": 3},
 "reconnects": 2,
 "in_flight_depth_max": 17, "in_flight_depth_avg": 2.3,
 "integrity": {"kv_seq_regressions": 0, ...},
 "chaos": {"kills_issued": 1, "last_victim": "pool"}}
```

What to watch for:

- **Non-zero `integrity.*_regressions`**: a real bug. Investigate.
- **`errors_typed` containing `Unclassified`**: the structured-
  concurrency contract is leaking. Every error should be a typed
  `Async::Redis::Error` subclass.
- **Throughput collapsing to zero for >1 tick after a kill**: recovery
  should be near-instant.
- **`reconnects` not incrementing when chaos is on**: chaos isn't
  reaching the client, or the on_disconnect hook is broken.

## Verifying it works

```bash
REDIS_HOST=localhost ./examples/stress/stress --duration 5 --kill-interval 2
```

Expected: exit 0, ~5 metric records on stdout, summary record at end
with `kills >= 2` and zero integrity violations.

## Reset

```bash
REDIS_HOST=localhost ./examples/stress/reset-redis.sh
```

## Implementation

See `lib/Stress/`:

- `Metrics.pm` — counters + reservoir sampling.
- `Integrity.pm` — sequence trackers and chaos window.
- `Output.pm` — stderr line + JSONL emitter.
- `Chaos.pm` — CLIENT KILL controller.
- `Workload.pm` — five `async` coroutines.
- `Harness.pm` — orchestrator.

Spec: `docs/plans/2026-04-24-stress-example-design.md`.
Plan: `docs/plans/2026-04-24-stress-example-plan.md`.
