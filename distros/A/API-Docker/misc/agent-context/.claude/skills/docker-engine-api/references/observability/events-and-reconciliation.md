# Events and reconciliation loops

> Read when: building a dashboard, controller, or long-running watcher.

Use events as change notifications, not a durable database. Engine event history is bounded; the CLI documents only the last 256 retained events. A long disconnect can lose history even if the client supplies `since`.

## Controller pattern

Establish an event stream and buffer a bounded overlap while obtaining a current snapshot. Reconcile by full resource ID and daemon identity. Apply buffered events, then continue streaming. Periodically reconcile authoritative list/inspect state again. On disconnect, reconnect with a deliberate timestamp overlap and deduplicate; if the gap exceeds your confidence window, perform a full reconciliation.

There is no globally reliable monotonically increasing event ID you can treat as a Kafka offset. A composite deduplication key can include daemon, resource, action, timestamp, and selected attributes, but collisions/repeats still require idempotent state updates. Account for clock differences when using timestamps.

Keep filters narrow enough for workload and resource ownership, but do not filter out the lifecycle transitions needed to detect removals. Events from one Engine do not provide cluster-wide truth for unrelated daemons. Swarm event scope also differs from local container scope.

## Failure behavior

Separate stream health from workload health. A quiet connection may be normal, while a frozen proxy can look identical without a heartbeat/reconciliation policy. Do not restart workloads merely because the watcher lost connectivity. Bound reconnect backoff, buffers, and queue length; degrade to a fresh snapshot instead of accumulating unbounded stale events.

Store meaningful operational audit outside the daemon with redaction and retention. Test a burst larger than the retention window, a daemon restart, observer downtime, duplicate delivery, removal between list and inspect, and unknown event attributes. The UI should show stale/unknown state explicitly rather than displaying old green indicators indefinitely.

## Primary sources

- [Engine events behavior](https://docs.docker.com/reference/cli/docker/system/events/)
- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
- [Engine API version history](https://docs.docker.com/reference/api/engine/version-history/)
