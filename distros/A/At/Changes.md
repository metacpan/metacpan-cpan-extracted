# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1] - 2026-01-24

- Fix ::Builder prereqs

## [1.0] - 2026-01-23

### Added
- Dedicated Firehose client (`At::Protocol::Firehose`) for real-time event streaming.
- OAuth login support.
- Lexicon cache system.

## [0.18] - 2024-02-19

### Changed
- Update according to lexicon changes in `bluesky-social/atproto@8c94979`.
- Add timeline index pref to `bsky::actor::savedFeedsPref`.
- Update according to lexicon changes in `bluesky-social/atproto@15f3856`.
- Manage communication templates for moderation purposes.

## [0.17] - 2024-02-13

### Changed
- Refactor methods with more than one optional parameter to accept a hash (Work in progress).
- Update according to lexicon changes in `bluesky-social/atproto@9579bec`.
- `temp_fetchLabels(...)` has been deprecated; use `label_queryLabels(...)` or `label_subscribeLabels(...)` instead.
- Update according to lexicon changes in `bluesky-social/atproto@b400fae`.

### Fixed
- Sanity check on DID in `server_reserveSigningKey(...)` endpoint.

## [0.16] - 2024-02-11

### Changed
- Refactor methods with more than one optional parameter to accept a hash (Work in progress).
- Bluesky no longer requires an invite to create an account.
- Update according to lexicon changes in `bluesky-social/atproto@e4ec7af`.
- Add date range and comment filter to `queryModerationEvents` endpoint.

## [0.15] - 2024-01-27

### Fixed
- Minor bug sweep as I work on a functioning client.

## [0.14] - 2024-01-27

### Fixed
- Minor bug sweep as I work on a functioning client.

## [0.13] - 2024-01-26

### Fixed
- Less broken session management.

## [0.12] - 2024-01-26

### Changed
- Update according to lexicon changes in `bluesky-social/atproto@4171c04`.
- Add interest tags to preferences.
- Update according to lexicon changes in `bluesky-social/atproto@8994d36`.
- Signup queueing.

## [0.11] - 2024-01-25

### Added
- Early version of sugary API.

### Fixed
- Minor bug sweep as I work on a functioning client.

## [0.10] - 2024-01-25

### Fixed
- Minor bug sweep as I work on a functioning client.

## [0.09] - 2024-01-24

### Changed
- Update according to lexicon changes in `bluesky-social/atproto@dac5c9e`.
- Tagged suggestions.
- Update according to lexicon changes in `bluesky-social/atproto@fb979b1`.
- Social graph relationships endpoint.

## [0.08] - 2024-01-23

### Added
- Resume expired sessions with `$at->server_refreshSession( ... )`.

## [0.07] - 2024-01-20

### Added
- New system to resume an authenticated session.

### Changed
- Update according to lexicon changes in `bluesky-social/atproto@15f3856`.
- Communication templates for moderation.

### Fixed
- Login failures are fatal errors.

## [0.06] - 2024-01-19

### Changed
- Update according to lexicon changes in `bluesky-social/atproto@e43396a`.
- Phone verification support on account creation.

## [0.05] - 2024-01-09

### Added
- Update according to lexicon changes in `bluesky-social/atproto#1970`.
- New method: `admin_getAccountsInfo`.
- New field in class `At::Lexicon::com::atproto::admin::accountView`.

## [0.04] - 2024-01-06

### Fixed
- ...don't write tests that fail when an otherwise unimportant page on the internet changes.

## [0.03] - 2024-01-06

### Added
- Full support for core At protocol and Bluesky extensions.

## [0.02] - 2023-11-22

### Fixed
- Fix synopsis.
- Split `At::Bluesky` from `At.pm` because PAUSE ignores subclasses in perl's new class syntax.

## [0.01] - 2023-11-22

### Added
- Original version.

[Unreleased]: https://github.com/sanko/At.pm/compare/1.1...HEAD
[1.1]: https://github.com/sanko/At.pm/compare/1.0...1.1
[1.0]: https://github.com/sanko/At.pm/compare/0.18...1.0
[0.18]: https://github.com/sanko/At.pm/compare/0.17...0.18
[0.17]: https://github.com/sanko/At.pm/compare/0.16...0.17
[0.16]: https://github.com/sanko/At.pm/compare/0.15...0.16
[0.15]: https://github.com/sanko/At.pm/compare/0.14...0.15
[0.14]: https://github.com/sanko/At.pm/compare/0.13...0.14
[0.13]: https://github.com/sanko/At.pm/compare/0.12...0.13
[0.12]: https://github.com/sanko/At.pm/compare/0.11...0.12
[0.11]: https://github.com/sanko/At.pm/compare/0.10...0.11
[0.10]: https://github.com/sanko/At.pm/compare/0.09...0.10
[0.09]: https://github.com/sanko/At.pm/compare/0.08...0.09
[0.08]: https://github.com/sanko/At.pm/compare/0.07...0.08
[0.07]: https://github.com/sanko/At.pm/compare/0.06...0.07
[0.06]: https://github.com/sanko/At.pm/compare/0.05...0.06
[0.05]: https://github.com/sanko/At.pm/compare/0.04...0.05
[0.04]: https://github.com/sanko/At.pm/compare/0.03...0.04
[0.03]: https://github.com/sanko/At.pm/compare/0.02...0.03
[0.02]: https://github.com/sanko/At.pm/compare/0.01...0.02
[0.01]: https://github.com/sanko/At.pm/releases/tag/0.01
