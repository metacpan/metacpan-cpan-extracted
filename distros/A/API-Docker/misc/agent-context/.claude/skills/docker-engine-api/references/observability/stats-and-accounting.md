# Stats, rate calculation, and platform differences

> Read when: implementing resource graphs or diagnosing API/CLI discrepancies.

Stats include cumulative counters, snapshots, and platform-dependent fields. Identify each metric's unit and lifecycle before graphing it. A counter increase over an elapsed interval gives a rate; a single raw counter does not.

For Linux CPU, a commonly used calculation compares the container CPU-usage delta with the host system CPU delta and multiplies by the relevant online CPU count and 100. Handle zero/negative deltas, missing previous samples, CPU hotplug, and restart/reset. State whether 100% represents one core or the entire host; otherwise multicore values appear misleading.

Memory `usage` and the CLI's displayed “used memory” can differ because Docker's CLI subtracts cache-related values on Linux. cgroup v1/v2 expose different cache field names. Windows has different accounting again. Do not label every memory counter RSS or working set; name the actual metric.

## Collector design

Use bounded streaming connections or periodic one-shot requests according to fleet size. Deduplicate collection for consumers watching the same container. Separate polling concurrency from mutation capacity. Treat disappearing containers as expected lifecycle events, not endless error alerts.

Record timestamp, daemon/container identity, sample interval, OS/cgroup context, raw counters needed for later interpretation, and computed values. Reset derivative state when identity or counter epoch changes. Percentages need a denominator: container limit, host capacity, or per-core convention.

## Validation

Compare a controlled CPU workload and a memory/cache workload against the native CLI on the same host, then explain expected display differences. Test a container with limits, an unconstrained one, a stopped/removed one, and a rootless or Windows target if supported. Monitoring code must not silently replace missing values with zero and imply healthy idle behavior.

## Primary sources

- [Stats display versus API counters](https://docs.docker.com/reference/cli/docker/container/stats/)
- [Container resource constraints](https://docs.docker.com/engine/containers/resource_constraints/)
- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
