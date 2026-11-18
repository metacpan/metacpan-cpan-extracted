# Podman compatibility and other Engine-like implementations

> Read when: running a Docker API client against a non-Docker endpoint.

Podman's API service provides a Docker-compatible surface and a separate native Libpod surface. The current service documentation describes compatibility with Docker API v1.40 and notes that unsupported version prefixes are not rejected in the same way as Docker. Do not hardcode the original skill's “announces 1.41” as a permanent product fact.

On Linux, rootless socket activation commonly exposes `$XDG_RUNTIME_DIR/podman/podman.sock`; rootful service and remote Desktop/VM setups differ. Confirm the endpoint and identity rather than inferring it from the command name.

## Capability tests, not product-name branching alone

Test discovery/version behavior, create/start/wait/remove, health fields, event payloads, logs with and without TTY, exec completion, volume ownership, filters, auth headers, build targets, and archive behavior. Record differences as supported adaptations or explicit unsupported features.

The absence of a version error does not prove support for every field at that prefix. Require effective-state verification for security restrictions. Preserve original server errors as diagnostics but do not parse product-specific English strings for branching.

## Security and transport

Podman's service still grants powerful access as the user running it. Rootless means a different privilege boundary, not harmless remote code execution. Use a local protected socket or authenticated remote transport and do not expose a naked TCP API. Avoid permanently changing host security settings just to match a Docker example.

For other compatibility daemons, require the same matrix. A successful `/_ping` and one container create are insufficient to claim Docker compatibility. Route native Libpod functionality to its own API client instead of pretending it is part of Docker's contract.

## Primary sources

- [Podman system service and Docker compatibility layer](https://docs.podman.io/en/latest/markdown/podman-system-service.1.html)
- [Engine API overview and version matrix](https://docs.docker.com/reference/api/engine/)
- [Rootless Docker](https://docs.docker.com/engine/security/rootless/)
