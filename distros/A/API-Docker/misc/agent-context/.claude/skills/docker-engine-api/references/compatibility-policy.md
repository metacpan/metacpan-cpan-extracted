# Compatibility policy and contract acquisition

> Read when: starting a client or adding an API-dependent feature.

Declare supported client API range, Engine families/versions, operating systems, transports, and optional feature gates. Do not publish “Docker compatible” based on a successful ping. API version, implementation, operating mode, and feature availability are distinct variables.

The upstream version matrix is the current starting point. This package uses **Moby 28.5.2 / API 1.51** source snapshots to make framing/auth/filter observations reproducible. That is an implementation reference, not a claim that 1.51 is the latest API or that every target supports it. Retrieve the schema for the selected negotiated version before generating request models.

## Contract evidence order

Use the target release's API schema and official change history first. Use pinned implementation source when the schema omits a wire detail. Use an integration test against the supported engine for observable behavior. Record discrepancies rather than silently generalizing a source-code detail into a permanent protocol requirement.

The schema is open to additional fields, so tolerate unknown response fields while validating the fields necessary for your operation. Unknown or unsupported request fields may be ignored; a successful status is not proof that a requested security restriction took effect. Inspect effective configuration after create/update operations.

## Capability record

Store daemon identity, detected implementation, negotiated version, OS/architecture, rootless status where exposed, and outcomes of safe feature probes. Cache these per endpoint/connection generation, not globally across all daemons. Re-evaluate after server changes.

Raw Engine API is not the complete protocol surface of every Docker ecosystem tool. Buildx/BuildKit sessions and Compose orchestration can require their own interfaces. If reproducing a CLI operation would require inventing undocumented endpoints, prefer the documented SDK/CLI integration or narrow the client scope explicitly.

## Primary sources

- [Engine API overview and version matrix](https://docs.docker.com/reference/api/engine/)
- [Engine API version history](https://docs.docker.com/reference/api/engine/version-history/)
- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
- [Engine SDK guidance](https://docs.docker.com/reference/api/engine/sdk/)
- [Compose SDK and CLI history](https://docs.docker.com/compose/intro/history/)
