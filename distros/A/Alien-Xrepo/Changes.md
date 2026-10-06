# Changelog

All notable changes to Alien::Xrepo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.3] - 2026-10-06

### Added

- `system` recipe option. With `system => 1` a package is allowed to resolve from the system (Homebrew, apt, vcpkg, ...), which makes `add_extsources()` in a package recipe usable again. Without it an install is a private build into its own store, as before.

### Fixed

- `system` installs no longer automatically collapse into a source build.
- A package reported with an install tree but no `libfiles` is no longer mistaken for a header-only package.

## [v1.0.2] - 2026-10-04

- Make some of the flaky tests Author's tests. Their failure means very little, honestly, and could fail for a lot of reasons.

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

[Unreleased]: https://github.com/sanko/Alien-Xrepo/compare/v1.0.3...HEAD
[v1.0.3]: https://github.com/sanko/Alien-Xrepo/compare/v1.0.2...v1.0.3
[v1.0.2]: https://github.com/sanko/Alien-Xrepo/compare/v1.0.1...v1.0.2
[v1.0.1]: https://github.com/sanko/Alien-Xrepo/compare/v1.0.0...v1.0.1
[v1.0.0]: https://github.com/sanko/Alien-Xrepo/releases/tag/v1.0.0
