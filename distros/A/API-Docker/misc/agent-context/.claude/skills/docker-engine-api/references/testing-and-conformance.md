# Client conformance and failure-injection plan

> Read when: claiming a supported client release or modifying a decoder.

## Offline checks included here

Run `python -m unittest discover -s tests -v` inside `examples/python`. Fixtures exercise partial reads, frame boundaries, invalid/truncated frames, size caps, TTY bypass, NDJSON fragments/trailing records, in-band errors, auth padding, and API range intersection. These are original client-policy tests, not upstream certification.

## Required integration matrix

| Axis | Cases |
|---|---|
| Version | Oldest supported, newest supported, newer-than-client, disjoint range |
| Transport | Every supported Unix/TLS/SSH/npipe path; actual reverse proxy if any |
| Engine | Docker rootful/rootless; Podman only when advertised |
| Platform | Linux/Windows and architectures actually supported |
| Streams | TTY/non-TTY, slow consumer, partial write/read, abrupt disconnect |
| Lifecycle | Fast exit, nonzero exit, timeout, lost create response, auto-remove race |
| Security | Rejected unsafe mounts/privileges; effective-state verification |
| Storage | Archive traversal, permissions, volume retention, scoped cleanup |

Use a dedicated disposable daemon/project, never a shared production target. Give fixtures unique labels and clean up only their IDs. Test no-op/status behavior and compare with the selected schema. Introduce an in-band pull/build failure after successful headers and assert that the client reports failure.

## Evidence report

Record versions, daemon identity, feature scope, tested transports, test results, known limitations, and unresolved discrepancies. Distinguish syntax/unit validation from a live daemon test. The delivery's validation report states which checks were actually executed; no live Engine, registry, or Kubernetes certification is implied.

Before extending support, add a failing regression fixture that represents the new behavior. Do not broaden advertised compatibility merely because an API prefix is accepted or a server returns extra fields without error.

## Primary sources

- [Engine API overview and version matrix](https://docs.docker.com/reference/api/engine/)
- [Engine API version history](https://docs.docker.com/reference/api/engine/version-history/)
- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
- [Podman system service and Docker compatibility layer](https://docs.podman.io/en/latest/markdown/podman-system-service.1.html)
- [Engine SDK guidance](https://docs.docker.com/reference/api/engine/sdk/)
