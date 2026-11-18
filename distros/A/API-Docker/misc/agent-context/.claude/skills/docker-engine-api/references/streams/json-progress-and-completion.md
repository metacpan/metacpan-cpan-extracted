# Progress streams, in-band errors, and completion evidence

> Read when: consuming image pulls/pushes or build progress.

Handle both ordinary non-2xx failures and successful headers followed by an operation error in the body stream. Messages can contain status/progress, textual build output, auxiliary results, `error`, or `errorDetail`. Preserve structured error context without depending on human wording.

For documented newline-delimited JSON endpoints, buffer across network chunks, parse complete objects, enforce a per-record limit, and process a final record even if it lacks a trailing newline. Do not assume every HTTP chunk is one JSON message. A bounded reader protects the client from an unexpectedly huge status record or proxy error.

```text
HTTP status -> validate endpoint status class
body chunks -> bounded record parser -> progress/error handler
stream end -> transport complete? operation error seen? result evidence present?
```

Honor the actual `Content-Type` and selected endpoint contract. A different format, such as RFC 7464 JSON sequences, must not be treated as NDJSON merely because both contain JSON. Unknown media types require a deliberate compatibility path, not blind line parsing.

## Completion policy

Do not declare success after the first progress record. At a minimum, finish the documented stream and reject in-band errors. For important operations, verify the expected artifact/container state afterward. Transport closure may be ambiguous; whether cancellation stops pull/push/build work is endpoint/version dependent.

Keep progress reporting backpressured and bounded. A slow user interface should not cause unbounded memory growth. Handle caller cancellation by closing resources and reporting whether final server state is known. Store enough operation identity to reconcile after a disconnect.

The included parser covers fragmented reads, CRLF, blank lines, trailing records, malformed JSON, size limits, and in-band errors. It is deliberately scoped to NDJSON. Do not reuse it for raw TTY streams, binary frames, or arbitrary concatenated JSON without adding the correct parser.

## Primary sources

- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
- [Engine API version history](https://docs.docker.com/reference/api/engine/version-history/)
- [Engine SDK/API examples](https://docs.docker.com/reference/api/engine/sdk/examples/)
