# Build requests, tar contexts, and the BuildKit boundary

> Read when: implementing /build or deciding whether raw Engine HTTP is sufficient.

The Engine build endpoint accepts a tar-format context body with build options in the endpoint's documented query/header fields. Parameters such as labels/buildargs may be JSON serialized inside query values. Build context construction is a client responsibility; do not assume sending a directory path causes the daemon to read the developer's files.

Before packaging, apply the intended context/ignore policy, reject escape paths and unexpected symlinks as appropriate, and avoid credentials. Keep tar metadata deterministic where reproducibility matters. Limit context size and stream large uploads instead of buffering an entire repository in memory.

`X-Registry-Config` differs from `X-Registry-Auth`: it supplies a registry-address-to-auth configuration map for builds that need multiple registry credentials. Follow the endpoint/version contract. Redact it in every log/trace.

## Not all Buildx features are simple /build options

Modern BuildKit can use separate sessions, secret/SSH providers, advanced exporters, remote workers, cache backends, and multi-platform orchestration. Do not fabricate query parameters for a feature merely because Buildx offers a flag. Decide whether to use the Engine endpoint's supported subset, BuildKit's own client/session interfaces, or the documented CLI/SDK toolchain.

A correct build client needs progress parsing, in-band error detection, cancellation policy, output identity, and post-build verification. A successful tar upload or 200 response is not the build result. Avoid scraping human build log lines for an image ID when a structured result or inspectable artifact is available.

## Security

Builds execute code. Never supply credentials or privileged entitlements to an untrusted Dockerfile without an isolated threat model. A secret mount is designed to avoid automatic layer persistence, not to prevent the build process from deliberately exporting it. Separate build workers and release-signing credentials where possible.

## Primary sources

- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
- [BuildKit build secrets](https://docs.docker.com/build/building/secrets/)
- [Buildx multi-platform workflow](https://docs.docker.com/build/building/multi-platform/)
- [Engine SDK guidance](https://docs.docker.com/reference/api/engine/sdk/)
