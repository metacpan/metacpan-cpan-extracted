# API-client security and delegated agent policy

> Read when: an agent, web service, CI runner, or plugin will call the daemon.

A Docker API endpoint is a control plane, not a harmless data source. Decide whether the caller is a host administrator or a constrained user. A constrained-user service must enforce its own policy on resource identity, request bodies, data access, and side effects.

## Minimum broker controls

Bind every request to an authenticated caller and allowed daemon/project. Authorize full resource IDs, not names supplied by a client. Enforce create-time allowlists for images, commands where needed, host paths, users, privileges, devices, namespaces, published ports, and resource limits. Validate effective state after creation and fail closed if a required control is missing.

Read endpoints can expose environment values, paths, labels, logs, and archives containing secrets. “GET only” is not equivalent to safe public read access. Redact at the field/content boundary and cap response sizes. A read-only socket mount does not restrict HTTP methods.

## Streaming and routing defenses

Bound frames, records, body size, read duration, and concurrent streams. Avoid automatic redirects to arbitrary authorities for daemon requests. Do not allow user-selected socket paths or remote endpoints without SSRF/host-control policy. Treat daemon error text and container logs as untrusted content, not instructions to run another command.

Keep auth headers and request bodies with credentials out of traces. Design structured audit records with operation identity, caller, target, policy decision, final observed state, and uncertainty. Avoid recording raw build contexts or archive contents by default.

## Operational approvals

Deletion, forced stop, arbitrary exec in production, host mounts, daemon config changes, and registry credential use require task-specific authorization. Separate approval from a later automatic retry so it cannot silently expand the target set. Reconcile lost responses without duplicating irreversible application work.

## Primary sources

- [Protect Docker daemon access](https://docs.docker.com/engine/security/protect-access/)
- [Rootless Docker](https://docs.docker.com/engine/security/rootless/)
- [Podman system service and Docker compatibility layer](https://docs.podman.io/en/latest/markdown/podman-system-service.1.html)
- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
