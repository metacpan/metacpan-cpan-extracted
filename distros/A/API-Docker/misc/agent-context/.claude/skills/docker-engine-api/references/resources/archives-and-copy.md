# Archives, copy, export, and extraction safety

> Read when: copying files into/out of containers or packaging build contexts.

Archive endpoints transfer tar streams, not JSON arrays of files. Match the endpoint's path/query/header contract and avoid reading large archives entirely into memory. Metadata headers and HTTP status describe the transfer, not the safety of extraction.

## Safe archive handling

Treat archive paths as untrusted input. Before extraction, validate normalized paths stay inside the chosen destination. Reject absolute paths, `..` escapes, unsafe symlink/hardlink targets, and special device files unless explicitly required and approved. Bound expanded bytes and file count as well as compressed/network size. Protect against overwrite of existing sensitive files.

Use the archive library's current safe-extraction facilities where available and still define application policy; library defaults differ by version. A lexical path check alone is insufficient if symlinks in the destination can redirect later writes. Prefer a new isolated destination and reject links when they are unnecessary.

## Data consistency

Copying files from a running database container does not automatically produce a consistent backup. Mounted data and image/container layers have distinct lifecycles. Container export is not equivalent to image save and is not a backup of all attached volumes. Use application-aware backup procedures.

## Permissions and direction

Copy source/destination semantics, directory existence, ownership, and symlink behavior can differ from a familiar local `cp`. Test the exact API direction and path shape. Do not grant arbitrary host destination paths through an agent-facing “download artifact” interface.

For uploads, ensure the destination is owned by the intended container and that overwriting config or executables is authorized. For downloads, redact or exclude secrets before exposing artifacts. Test traversal, deep nesting, oversized payloads, link escapes, permission failure, interrupted transfer, and destination collisions.

## Primary sources

- [Container copy and archive semantics](https://docs.docker.com/reference/cli/docker/container/cp/)
- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
