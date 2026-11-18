# Endpoint discovery and connection management

> Read when: opening a Unix socket, SSH transport, named pipe, or TLS endpoint.

Make endpoint selection explicit and observable. Linux rootful Docker commonly uses `/var/run/docker.sock`; rootless Docker uses a user-specific endpoint; Desktop and native Windows have different contexts/transports. A hardcoded Unix socket is a valid scoped choice, not a portable auto-discovery algorithm.

For library clients, use documented environment/context integration. Do not assume every SDK honors `DOCKER_HOST`, `DOCKER_CONTEXT`, or CLI context metadata in the same way. `DOCKER_HOST` is a common convention, not an obligation binding every library. Prefer explicit constructor settings when reliable target selection matters.

## Connection classes

Keep ordinary finite HTTP requests separate from long-lived events/stats/log streams and hijacked interactive sessions. A stuck stream must not consume every connection needed for stop/inspect requests. Use explicit dial/TLS/header deadlines, operation cancellation, bounded response bodies, and a pool sized for each class.

A Unix socket carries HTTP without a network TCP endpoint. The URL host used by a Unix-socket HTTP client can be a routing placeholder; the filesystem socket selects the daemon. SSH transports need a compatible SDK dialer or a controlled tunnel, not a blind substitution of an `ssh://` URL into every HTTP library.

## Identity and trust

Authenticate remote access with SSH or mutual TLS. Verify server identity and protect client keys. A local TCP endpoint is not automatically safe from other local users or browser-origin attacks. Do not enable unauthenticated TCP as a convenience fallback.

On failed connection, report selected endpoint, transport phase, timeout, and sanitized error. Do not print certificate private keys, full Docker config, or credential headers. A retry to another daemon is not transparent failover unless that daemon intentionally represents the same managed state.

## Primary sources

- [Protect Docker daemon access](https://docs.docker.com/engine/security/protect-access/)
- [Docker contexts](https://docs.docker.com/engine/manage-resources/contexts/)
- [Rootless Docker](https://docs.docker.com/engine/security/rootless/)
- [Docker SDK for Python client](https://docker-py.readthedocs.io/en/stable/client.html)
- [Podman system service and Docker compatibility layer](https://docs.podman.io/en/latest/markdown/podman-system-service.1.html)
