# Hijacked connections, attach, exec, and terminal behavior

> Read when: implementing interactive commands or bidirectional streaming.

Exec has an instance-creation step and a start step. Obtain the final exit code from exec inspection after completion; start success does not mean the command exited successfully. Detached start also needs later observation. Container attach is a different lifecycle: it connects to an existing container process rather than creating an exec instance.

Some interactive endpoints upgrade/hijack HTTP into a bidirectional connection. Handle the selected endpoint's documented 101/200 behavior using a compatible transport. A normal HTTP response-body reader is not automatically a correct bidirectional attach implementation, especially across proxies and HTTP/2-only infrastructure.

## Direction matters

Docker's multiplex header describes daemon output. Do not prepend those headers to stdin indiscriminately; the attach input direction uses the endpoint's raw stream contract. Preserve half-close semantics where supported so EOF on stdin does not prematurely discard remaining stdout/stderr. Keep terminal resize, detach keys, and cancellation separate from application input bytes.

TTY mode combines stdout/stderr and carries terminal control sequences. Use it only when terminal semantics are needed. For machine-readable output and separate error handling, prefer non-TTY mode. An interactive session must restore the user's terminal mode even on failure.

## Transport acceptance tests

Run a command that writes distinct stdout and stderr, a command that waits for stdin EOF, a command that emits final output during shutdown, and a command whose result is nonzero. Repeat through the actual SSH/TLS/proxy path. Verify no output is lost when stdin closes.

Connection loss does not guarantee the exec process stops. Reconcile using the exec/container identity and application-level job state. Do not automatically restart an interrupted mutating command. The included Python client deliberately does **not** implement hijacking; use a tested SDK transport for that surface rather than extending its finite-response helper casually.

## Primary sources

- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
- [Pinned Moby stdcopy framing implementation](https://raw.githubusercontent.com/moby/moby/v28.5.2/pkg/stdcopy/stdcopy.go)
- [Docker Python SDK multiplexed streams](https://docker-py.readthedocs.io/en/stable/user_guides/multiplex.html)
- [Engine SDK/API examples](https://docs.docker.com/reference/api/engine/sdk/examples/)
