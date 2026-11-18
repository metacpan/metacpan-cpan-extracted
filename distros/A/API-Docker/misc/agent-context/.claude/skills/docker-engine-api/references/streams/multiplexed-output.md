# Docker multiplexed output and defensive decoding

> Read when: logs contain binary headers or implementing non-TTY attach/exec/log streams.

When the endpoint uses Docker's non-TTY multiplexed output, each frame has an eight-byte header: one stream byte, three reserved bytes, then an unsigned big-endian 32-bit payload length. This is application framing **inside** HTTP; HTTP chunks and socket reads do not align with frames.

```text
01 00 00 00 00 00 00 04  4f 55 54 0a    stdout: OUT\n
02 00 00 00 00 00 00 04  45 52 52 0a    stderr: ERR\n
```

The usual output types are stdout=1 and stderr=2. Pinned Moby `stdcopy` also recognizes stdin=0 and system-error=3. Type 3 must not be silently displayed as ordinary application output. Treat unknown frame kinds as a protocol/compatibility event.

With TTY enabled, output is a raw PTY byte stream: no Docker multiplex headers and no recoverable stdout/stderr separation. Do not decide framing by sniffing the first bytes of arbitrary application output. Use known TTY configuration and endpoint behavior. PTY newline behavior can vary; do not require all line endings to be CRLF.

## Defensive decoder requirements

Read exactly eight header bytes across partial reads. Validate header/type according to your compatibility policy. Bound payload allocation and total buffering. Read the announced payload fully; distinguish clean EOF at a frame boundary from truncation within a frame. Deliver bytes to separate sinks; do incremental text decoding above the framing layer because a multibyte character can span frames.

The included helper intentionally rejects truncated frames and oversized payloads. Those are **client safety choices**, not a promise that every upstream decoder rejects them identically. Its default size cap is configurable and must be sized for the workload.

Test single-byte reads, multiple frames per read, zero-length frames, split UTF-8, system errors, invalid headers, truncated payloads, and TTY bypass. A clean interactive TTY test alone cannot validate a non-TTY log client.

## Primary sources

- [Pinned Moby stdcopy framing implementation](https://raw.githubusercontent.com/moby/moby/v28.5.2/pkg/stdcopy/stdcopy.go)
- [Docker Python SDK multiplexed streams](https://docker-py.readthedocs.io/en/stable/user_guides/multiplex.html)
- [Pinned Moby 28.5.2 API 1.51 schema (compatibility evidence, not latest)](https://raw.githubusercontent.com/moby/moby/v28.5.2/docs/api/v1.51.yaml)
