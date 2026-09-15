# Changelog

All notable changes to Alien::Xrepo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.1] - 2026-09-11

### Added

- `Alien::Xrepo::MB` and `Alien::Xrepo::MM`, generic Module::Build and ExtUtils::MakeMaker integrations for Alien distributions
- Build engine `share_dir` option: per-package installs land under `<share>/<pkg>` via `installdir`, and the snapshot records share-relative paths so an installed dist resolves packages after relocation to the site sharedir.
- Example distributions demonstrating the new recipe shapes:
  - `Exotic::SDL3` installs multiple shared libraries for FFI consumers with one Alien
  - `Exotic::Ninja` demos a binary tool alien
  - `Exotic::Zstandard` and `Exotic::Lsquic` demonstrate `Alien::Xrepo::MB`
  - `Exotic::Raylib6` example distribution on the using `Alien::Xrepo::MM`
  - `Exotic::SQLite3`
  - `Exotic::Zlib` demos static library building for `cc_lib_flags` consumers like Inline::C or XS
  - `Exotic::Vcpkg::zlib` installs a lib from a 3rd party repo
- Package `version` pinning

## [v1.0.0] - 2026-09-07

Splitting this out of the `Alien::Xmake` dist and repo

### Changed

- It exists? Check the Alien::Xmake changelog, I guess

[Unreleased]: https://github.com/sanko/Alien-Xrepo/compare/v1.0.1...HEAD
[v1.0.1]: https://github.com/sanko/Alien-Xrepo/compare/v1.0.0...v1.0.1
[v1.0.0]: https://github.com/sanko/Alien-Xrepo/releases/tag/v1.0.0
