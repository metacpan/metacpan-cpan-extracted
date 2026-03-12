# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6] - 2026-03-12

### Changed
- Switch to `Codec::CBOR`
- Implemented a 30s heartbeat in `At::UserAgent::Mojo` to keep firehose connections alive.
- Disabled `inactivity_timeout` in `At::UserAgent::Mojo` for WebSocket connections to prevent premature disconnects during long running firehose runs.

## [1.5] - 2026-03-10

### Changed
- Firehose requires Archive::CAR

### Fixed
- While processing lexicons, validation errors fall back to the raw string instead of throwing a fatal exception.

## [1.4] - 2026-03-09

### Added
- Added high-level helpers for...
  - Rrepository management: `create_record`, `delete_record`, `put_record`, and `apply_writes`
  - Direct PDS binary uploads: `upload_blob`
  - Identity resolution: `resolve_did_to_handle`

## [1.3] - 2026-03-08
... [rest of file] ...

[Unreleased]: https://github.com/sanko/At.pm/compare/1.6...HEAD
[1.6]: https://github.com/sanko/At.pm/compare/1.5...1.6
[1.5]: https://github.com/sanko/At.pm/compare/1.4...1.5
[1.4]: https://github.com/sanko/At.pm/compare/1.3...1.4
[1.3]: https://github.com/sanko/At.pm/releases/tag/1.3
