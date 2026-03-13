# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.05] - 2026-03-12

### Added
- Added `oauth` command for a streamlined, interactive authentication flow with an automatic local listener.
- Implemented `chat` and `dm` commands for managing conversations and sending direct messages via PDS proxying.
- Sessions now persist and can be resumed with full metadata including DPoP keys and scopes.

### Changed
- Improved `show-session` command with detailed diagnostic output.

## [0.04] - 2024-02-13

### Changed
- Update to fit current API of At.pm

## [0.03] - 2024-01-27

### Added
- Commands for app passwords, likes, reposts, invite codes, threads, etc.

## [0.02] - 2024-01-26

### Fixed
- Less broken session management

## [0.01] - 2024-01-26

### Added
- original version

[Unreleased]: https://github.com/sanko/App-bsky/compare/0.05...HEAD
[0.05]: https://github.com/sanko/App-bsky/compare/0.04...0.05
[0.04]: https://github.com/sanko/App-bsky/compare/0.03...0.04
[0.03]: https://github.com/sanko/App-bsky/compare/0.02...0.03
[0.02]: https://github.com/sanko/App-bsky/compare/0.01...0.02
[0.01]: https://github.com/sanko/App-bsky/releases/tag/0.01
