---
name: docker-engine-api
description: "Use when implementing, testing, or debugging a Docker Engine HTTP API client: socket/remote transport, API negotiation, container lifecycle, attach/exec/log framing, progress streams, image auth, events/stats, resource policy, archives, retries, or Podman compatibility. Load task-specific references rather than the entire API corpus."
---

# Docker Engine HTTP API

Use this skill when software speaks directly to the Engine API instead of delegating the operation to Docker CLI/Compose. Documentation review: **2026-10-09**. This is a protocol and client-engineering guide, not an exhaustive endpoint dump or a replacement for the selected API schema.

## Acquire the contract first

Read the [compatibility policy](references/compatibility-policy.md) and [version negotiation](references/transport/version-negotiation.md). Record target implementation, endpoint/transport, server API range, the client's implemented API range, and required features. Select a supported intersection; never adopt the daemon maximum merely because it is advertised.

Pinned Moby **28.5.2 / API 1.51** sources support reproducible wire-format examples. They are not a latest-version claim. For additional endpoints or fields, fetch the exact target release's official schema and gate the implementation explicitly.

## Load by task

| Task or symptom | Required reference | Related reference |
|---|---|---|
| Wrong daemon, socket, TLS, or remote discovery | [Transport and discovery](references/transport/discovery-and-connections.md) | [Security](references/clients/security-and-untrusted-input.md) |
| Query encoding, filters, paths, or JSON body types | [Request shapes](references/http/request-shapes-and-encoding.md) | [Status and retries](references/http/status-errors-and-retries.md) |
| Create/start/stop/delete automation | [Lifecycle and ownership](references/containers/lifecycle-and-ownership.md) | [Create/resource policy](references/containers/create-and-resource-policy.md) |
| Garbage bytes in logs or truncated output | [Multiplexed output](references/streams/multiplexed-output.md) | [Hijack/attach/exec](references/streams/hijack-attach-and-exec.md) |
| Interactive execution or lost exit status | [Hijack/attach/exec](references/streams/hijack-attach-and-exec.md) | [Lifecycle](references/containers/lifecycle-and-ownership.md) |
| Pull/push/build reports false success | [Progress/completion](references/streams/json-progress-and-completion.md) | [Registry auth](references/images/pull-push-and-registry-auth.md) |
| Reimplementing a Docker build | [Build context/BuildKit boundary](references/images/build-context-and-buildkit-boundary.md) | [SDK selection](references/clients/sdk-selection-and-language-notes.md) |
| Dashboard, watcher, or resource accounting | [Events/reconciliation](references/observability/events-and-reconciliation.md) | [Stats](references/observability/stats-and-accounting.md) |
| Network, volume, or cleanup API | [Resources and prune](references/resources/networks-volumes-and-prune.md) | [Ownership](references/containers/lifecycle-and-ownership.md) |
| File copy into/out of containers | [Archives](references/resources/archives-and-copy.md) | [Input security](references/clients/security-and-untrusted-input.md) |
| Compose or Swarm through HTTP | [Control-plane boundaries](references/resources/swarm-and-compose-boundaries.md) | [SDK selection](references/clients/sdk-selection-and-language-notes.md) |
| Podman or another compatible engine | [Compatibility testing](references/clients/podman-and-other-engines.md) | [Conformance](references/testing-and-conformance.md) |

## Client invariants

Treat the Docker socket as a privileged control plane. Keep endpoint selection explicit; do not silently fall back to another daemon. Do not expose raw Engine access to untrusted callers. A policy must inspect mutation payloads, mounts, privileges, resource limits, images, and ownership—not merely HTTP verbs.

Separate HTTP transport errors, endpoint statuses, streamed operation errors, and application exit status. Handle empty successful bodies without JSON decoding. Drain and validate finite operation streams before reporting completion. Reconcile after an ambiguous mutation instead of retrying it blindly.

For non-TTY streams, parse binary headers across arbitrary network boundaries; for TTY streams, preserve raw combined output. Put bounds on frames, JSON records, queues, and timeouts. Keep long-lived stream connections separate from ordinary requests.

Validate endpoint-specific filters and version-gated request fields. Malformed filters are not a safe deletion guard. Inspect actual created resource settings where policy enforcement matters. Never log credentials, registry auth headers, full container environments, or signed storage URLs.

## Implement and prove

Read [testing and conformance](references/testing-and-conformance.md) before claiming support. The [Python helper package](examples/python/README.md) supplies numeric version-range negotiation, padded registry auth encoding, bounded multiplex/NDJSON parsers, unit tests, and an explicitly read-only Unix-socket probe. It is not a complete SDK, Windows transport, TLS/SSH client, or hijack implementation.

For client code, state the supported contract, request/response model, streaming behavior, retry/cancellation semantics, security restrictions, and tests. Separate unit/static validation from integration tests against actual engine versions.

Use sibling `docker` for Dockerfile/Compose operation and `docker-registry` for the separate Distribution/OCI API. The [full index](references/INDEX.md) and [sources](references/SOURCES.md) provide deeper navigation.
