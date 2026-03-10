# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.0.3] - 2026-03-10

### Fixed
- Fix resource metadata

## [v0.0.2] - 2026-03-10

### Added
- Added `Archive::CAR::CID->from_raw($bytes)` for easier decoding from binary sources.

### Changed
- Improved CID decoding to handle optional leading zero bytes common in firehose events.

## [v0.0.1] - 2026-03-09

### Changed
- It exists!

[Unreleased]: https://github.com/sanko/Archive-CAR.pm/compare/v0.0.3...HEAD
[v0.0.3]: https://github.com/sanko/Archive-CAR.pm/compare/v0.0.2...v0.0.3
[v0.0.2]: https://github.com/sanko/Archive-CAR.pm/compare/v0.0.1...v0.0.2
[v0.0.1]: https://github.com/sanko/Archive-CAR.pm/releases/tag/v0.0.1
