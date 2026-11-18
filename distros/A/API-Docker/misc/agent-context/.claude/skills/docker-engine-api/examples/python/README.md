# Dependency-free protocol fixtures (Python 3.10+)

These are original, scoped examples—not a complete Docker SDK. The helper module contains API range negotiation, padded auth encoding, bounded frame decoding, and bounded NDJSON/progress parsing. The read-only probe uses an **explicit Unix socket** and performs `/version` plus a negotiated container-list request. It never creates, starts, stops, execs, or deletes containers.

## Offline tests

From this directory:

```sh
python -m unittest discover -s tests -v
```

The tests use in-memory byte streams and require no Docker daemon or third-party package. Strict truncation/reserved-byte handling and configured size caps are this example's safety policy, not claims that every Moby release applies identical checks.

## Explicit local probe

```sh
python readonly_probe.py --socket /var/run/docker.sock
```

Select the actual socket first; do not run as root merely to bypass an unknown permission problem. For rootless Docker, pass the verified user socket path. The example's default supported range is 1.40–1.51 for its small read-only surface. It intersects that range with the daemon's advertised range and fails if they do not overlap. A missing server minimum requires an explicit `--legacy-server-min` policy.

Container names, image names, IDs, and endpoints may be sensitive. Review output before sharing. Registry-auth helper output is credential material; never log it.

## Deliberate exclusions

No automatic Docker-context parsing, SSH transport, Windows named pipes, TLS transport, hijacked/interactive connections, retrying mutations, streaming content-type negotiation, registry credential helper integration, or full API coverage. Use a maintained SDK for those features. The probe's finite response reader must not be reused for long-running events or interactive output.

## Integration evidence

Unit tests prove parser/helper behavior against fixtures only. Add tests against every advertised daemon version, platform, transport, and compatible implementation before production use. Test lost responses and effective policy enforcement, not only successful happy-path requests.
