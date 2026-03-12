# Changelog

All notable changes to Algorithm::Kademlia will be documented in this file.

## [v1.1.0] - 2026-03-11

### Changed
- No functional changes from v1.0.1

## [v1.0.1] - 2026-01-28

### Added
- `Algorithm::Kademlia::Storage::Entry` to hold stored data including seeds and leechers.
- `Algorithm::Kademlia::RoutingTable->import_peers()` method for bulk-loading peers into buckets.

### Changed
- `Algorithm::Kademlia::RoutingTable->local_id_bin` now has reader and writer accessors.
- Requires perl v5.42.x

## [v1.0.0] - 2026-01-25

### Added
- Pulled out of Net::BitTorrent::DHT for use in other DHTs.

[Unreleased]: https://github.com/sanko/Algorithm-Kademlia.pm/compare/v1.1.0...HEAD
[v1.1.0]: https://github.com/sanko/Algorithm-Kademlia.pm/compare/v1.0.1...v1.1.0
[v1.0.1]: https://github.com/sanko/Algorithm-Kademlia.pm/compare/v1.0.0...v1.0.1
[v1.0.0]: https://github.com/sanko/Algorithm-Kademlia.pm/releases/tag/v1.0.0
