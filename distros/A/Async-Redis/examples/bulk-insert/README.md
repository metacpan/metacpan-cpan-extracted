# Bulk Insert Example

This example inserts a large number of Redis keys while a heartbeat keeps
printing progress.

It demonstrates that a Perl process using Async::Redis can keep doing other
event-loop work while many Redis writes are in flight.

## What It Does

- creates one writer Redis connection with `auto_pipeline => 1`
- creates one stats Redis connection for heartbeat `PING`s
- writes keys in concurrent batches
- prints `issued`, `confirmed`, `batches`, `ping_ms`, and insert rate
- gives every key a TTL so demo runs do not leave permanent data behind

The heartbeat is the proof point. If the app were obviously blocking the Perl
process, heartbeat lines would stop until the inserts finished.

## Running

Start Redis from the project root:

```bash
docker compose -f examples/docker-compose.yml up -d
```

Run the default demo:

```bash
REDIS_HOST=localhost perl examples/bulk-insert/app.pl
```

Run a shorter smoke test:

```bash
REDIS_HOST=localhost perl examples/bulk-insert/app.pl \
    --count 10000 \
    --batch 250 \
    --ttl 30 \
    --heartbeat 0.05
```

## Options

```text
examples/bulk-insert/app.pl [options]

Options:
  --count N           keys to insert, default 50000
  --batch N           concurrent SETs per batch, default 500
  --ttl SEC           expiry for inserted keys, default 120
  --payload-bytes N   value size per key, default 128
  --heartbeat SEC     heartbeat interval, default 0.25
  --help              show usage
```

Environment:

- `REDIS_HOST` - Redis hostname, default `localhost`
- `REDIS_PORT` - Redis port, default `6379`

## Example Output

```text
[ 0.00s] starting count=10000 batch=250 payload=128B ttl=30s prefix=bulk-insert:69148:1777210772014:
[ 0.06s] heartbeat issued=1000 confirmed=750 batches=3 ping_ms=6.7 rate=12438/s
[ 0.17s] heartbeat issued=2500 confirmed=2250 batches=9 ping_ms=4.0 rate=13341/s
[ 0.35s] heartbeat issued=5250 confirmed=5000 batches=20 ping_ms=9.1 rate=14391/s
[ 0.64s] heartbeat issued=9750 confirmed=9500 batches=38 ping_ms=10.0 rate=14804/s
[ 0.70s] done inserted=10000 batches=40 elapsed=0.70s rate=14359/s keys_expire_in=30s
```

## Notes

This is an educational example, not a benchmark. Throughput depends on Redis,
your machine, payload size, and batch size.

The inserted keys use a unique prefix for each run and expire automatically.
The prefix is printed so you can inspect a run before the TTL expires.
