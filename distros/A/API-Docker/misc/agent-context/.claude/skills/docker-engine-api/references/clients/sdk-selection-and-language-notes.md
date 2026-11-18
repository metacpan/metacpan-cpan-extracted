# SDK choice, language boundaries, and implementation scope

> Read when: selecting Go/Python/Perl/C++ tooling or planning a minimal client.

Prefer a maintained SDK when it already handles transport, API negotiation, framing, and cancellation for your target. Read its actual version documentation; “Docker SDK” does not imply every SDK has the same context discovery, timeout, async, or platform behavior.

The official Go and Python guidance is the starting point. Pin dependencies, enable the documented negotiation mechanism, and test the supported daemon matrix. For Python, distinguish high-level object wrappers from the low-level API client, and close generators/connections promptly. Do not mix examples from incompatible library versions or assume `from_env()` fully resolves CLI contexts.

## Implementing a smaller client

Separate endpoint transport, version selection, typed request construction, finite JSON responses, streaming decoders, and orchestration policy. This allows Perl, C, C++, Rust, or another implementation to reuse the same test vectors without sharing a fragile hand-written HTTP parser. Use the language's mature HTTP/JSON libraries. Memory-constrained clients should stream and cap buffers rather than collect complete build logs in RAM.

Raw byte streams remain bytes until explicitly decoded. Languages with implicit string coercion must preserve JSON booleans, integer width, null/absent distinction, and URL-safe base64 padding. Nanosecond timestamps and large counters can exceed JavaScript's exact integer range; choose representations deliberately.

## What the included code is

`examples/python/engine_helpers.py` contains original, dependency-free framing, NDJSON, auth, and version helpers. `readonly_probe.py` demonstrates finite read-only HTTP over an explicit Unix socket. Neither is a full production Docker SDK; no SSH/npipe/TLS auto-discovery, interactive hijack, or general mutating API is claimed.

Use the helpers as tested building blocks or executable protocol fixtures. Production suitability additionally requires integration tests, endpoint-specific behavior, authentication management, telemetry/redaction, and the threat model in the security reference.

## Primary sources

- [Engine SDK guidance](https://docs.docker.com/reference/api/engine/sdk/)
- [Docker SDK for Python client](https://docker-py.readthedocs.io/en/stable/client.html)
- [Docker Python SDK multiplexed streams](https://docker-py.readthedocs.io/en/stable/user_guides/multiplex.html)
- [Engine SDK/API examples](https://docs.docker.com/reference/api/engine/sdk/examples/)
- [Docker contexts](https://docs.docker.com/engine/manage-resources/contexts/)
