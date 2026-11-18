# docker-engine-api: reference index

Read [the skill entrypoint](../SKILL.md) first. Follow only the links needed for the task. These are on-demand reference files, not instructions to load the whole directory.

## Clients

| Reference | Read when |
|---|---|
| [Podman compatibility and other Engine-like implementations](clients/podman-and-other-engines.md) | running a Docker API client against a non-Docker endpoint. |
| [SDK choice, language boundaries, and implementation scope](clients/sdk-selection-and-language-notes.md) | selecting Go/Python/Perl/C++ tooling or planning a minimal client. |
| [API-client security and delegated agent policy](clients/security-and-untrusted-input.md) | an agent, web service, CI runner, or plugin will call the daemon. |

## Start Here

| Reference | Read when |
|---|---|
| [Compatibility policy and contract acquisition](compatibility-policy.md) | starting a client or adding an API-dependent feature. |
| [Client conformance and failure-injection plan](testing-and-conformance.md) | claiming a supported client release or modifying a decoder. |

## Containers

| Reference | Read when |
|---|---|
| [Create configuration and effective-policy verification](containers/create-and-resource-policy.md) | setting mounts, ports, capabilities, limits, or user identity through HTTP. |
| [Container lifecycle, ownership, and cleanup](containers/lifecycle-and-ownership.md) | implementing run/create/start/wait/remove workflows. |

## Http

| Reference | Read when |
|---|---|
| [Request shapes, filters, identifiers, and URL encoding](http/request-shapes-and-encoding.md) | building API requests without an official SDK. |
| [Status codes, stream errors, retries, and ambiguous outcomes](http/status-errors-and-retries.md) | mapping HTTP responses to operation results. |

## Images

| Reference | Read when |
|---|---|
| [Build requests, tar contexts, and the BuildKit boundary](images/build-context-and-buildkit-boundary.md) | implementing /build or deciding whether raw Engine HTTP is sufficient. |
| [Image operations and registry authentication headers](images/pull-push-and-registry-auth.md) | pulling or pushing images through the Engine API. |

## Observability

| Reference | Read when |
|---|---|
| [Events and reconciliation loops](observability/events-and-reconciliation.md) | building a dashboard, controller, or long-running watcher. |
| [Stats, rate calculation, and platform differences](observability/stats-and-accounting.md) | implementing resource graphs or diagnosing API/CLI discrepancies. |

## Resources

| Reference | Read when |
|---|---|
| [Archives, copy, export, and extraction safety](resources/archives-and-copy.md) | copying files into/out of containers or packaging build contexts. |
| [Networks, volumes, and destructive endpoint policy](resources/networks-volumes-and-prune.md) | automating resource creation or cleanup. |
| [Swarm objects, Compose orchestration, and concurrency control](resources/swarm-and-compose-boundaries.md) | a client encounters services/tasks/secrets or wants to reproduce Compose. |

## Streams

| Reference | Read when |
|---|---|
| [Hijacked connections, attach, exec, and terminal behavior](streams/hijack-attach-and-exec.md) | implementing interactive commands or bidirectional streaming. |
| [Progress streams, in-band errors, and completion evidence](streams/json-progress-and-completion.md) | consuming image pulls/pushes or build progress. |
| [Docker multiplexed output and defensive decoding](streams/multiplexed-output.md) | logs contain binary headers or implementing non-TTY attach/exec/log streams. |

## Transport

| Reference | Read when |
|---|---|
| [Endpoint discovery and connection management](transport/discovery-and-connections.md) | opening a Unix socket, SSH transport, named pipe, or TLS endpoint. |
| [Correct version negotiation and feature gating](transport/version-negotiation.md) | choosing request prefixes or handling new/old daemon combinations. |

## Maintenance

Read the [source register](SOURCES.md) for upstream verification.
