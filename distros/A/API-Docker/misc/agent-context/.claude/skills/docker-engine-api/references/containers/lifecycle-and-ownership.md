# Container lifecycle, ownership, and cleanup

> Read when: implementing run/create/start/wait/remove workflows.

A CLI `run` workflow is several API operations, not a single `/run` endpoint. Resolve/pull the intended image if required, create a container with an explicit configuration, attach or prepare log collection if needed, start, observe completion, inspect exit/result state, collect artifacts, then clean up only owned disposable resources.

Assign a unique operation label and retain the full returned container ID. Treat a preexisting name as a conflict to investigate, not permission to adopt or remove it. Ownership checks should include the expected labels and configuration, not just a prefix in the name.

## Lost-response handling

A network error during create/start can leave a real container behind. Reconcile using operation identity before retrying. A response received by the server but not the client is an **unknown outcome**, not an automatic failure with no side effects.

To capture short-lived process output, establish an appropriate attach/log strategy before start. Avoid `AutoRemove` when the client must inspect exit state, collect archives, or reconcile after disconnection. Automatic deletion can erase precisely the evidence needed for reliable orchestration.

## State and exit

Wait returns the workload's exit result according to the endpoint's selected condition; the HTTP status alone is not the workload exit code. Inspect the container for OOM/error/health evidence. A stopped container, an unhealthy running container, and a removed container are different states.

On timeout, decide explicitly whether the workload should keep running, receive a graceful stop, or be forcibly terminated. Canceling a client request does not universally cancel the container's work. Apply cleanup in a finally/defer path only after confirming identity and respecting the user's retention policy.

For stateful or production containers, prefer an explicit operator-controlled lifecycle. Do not reuse the disposable-job cleanup pattern for long-lived services with volumes. Compose ownership labels belong to Compose; an API client should not impersonate them casually.

## Primary sources

- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
- [Engine SDK/API examples](https://docs.docker.com/reference/api/engine/sdk/examples/)
- [Container wait](https://docs.docker.com/reference/cli/docker/container/wait/)
- [Engine events behavior](https://docs.docker.com/reference/cli/docker/system/events/)
