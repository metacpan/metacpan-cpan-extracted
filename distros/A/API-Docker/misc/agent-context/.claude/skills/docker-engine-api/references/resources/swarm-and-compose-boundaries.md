# Swarm objects, Compose orchestration, and concurrency control

> Read when: a client encounters services/tasks/secrets or wants to reproduce Compose.

Engine container operations and Swarm service operations describe different abstractions. A Swarm service is a desired specification whose tasks are scheduled by the orchestrator. Updating a service is not equivalent to changing one container. Nodes, tasks, service secrets/configs, and manager-only operations require the appropriate Swarm state and authorization.

For versioned Swarm updates, read the current object/version and use the documented optimistic-concurrency field. On conflict, reread and reconcile desired changes against current state. Do not blindly retry a stale full object and overwrite someone else's update. Preserve immutable fields and default behavior according to the selected schema.

## Secrets/configs

Swarm-managed secrets are not local Compose file-backed secrets. Do not use the existence of Engine secret endpoints to claim a standalone Compose deployment has the same encryption/distribution semantics. Local Compose maps its project model to several Engine operations; the daemon does not expose a generic `/compose/up` endpoint.

Official Compose documentation now describes a Go SDK in Compose v5. For embedding full Compose behavior, evaluate that documented surface and its supported version rather than implementing a partial YAML-to-container translator and calling it compatible.

## Scope statement

A small client can intentionally support standalone container lifecycle and leave Swarm/Compose out of scope. Make that an explicit capability error. If service management is required, test manager versus worker behavior, concurrent updates, rollback, secret rotation, and partially failed rollouts against the chosen release.

Do not assume deleting a task container permanently removes the desired service. The orchestrator may recreate it. Operate through the owner of desired state, or explain that a lower-level diagnostic operation is intentionally temporary.

## Primary sources

- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
- [Compose SDK and CLI history](https://docs.docker.com/compose/intro/history/)
- [Engine API overview and version matrix](https://docs.docker.com/reference/api/engine/)
