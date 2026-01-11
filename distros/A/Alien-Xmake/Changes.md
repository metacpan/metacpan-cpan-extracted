# Changelog

All notable changes to Alien::Xmake will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.08] - 2026-01-11

### Changed

- Don't bother with making sure we can install a lib on CPAN smokers. I can't diagnose a system I have no access to.

## [0.07] - 2026-01-09

### Changed

- Switch xmake to plain text mode on CPAN smokers

## [0.06] - 2026-01-07

### Added

- Support system installs on Windows
- Expose xrepo
- Demos in `eg/`
  - `eg/xmake_demo.pl` creates and builds a simple shared library in C
  - `eg/xrepo_demo.pl` queries for zlib's info, installs it locally, and spews the flags required to build against it

### Changed

- Bump to Xmake 3.0.6

## [0.05] - 2024-03-18

### Fixed

- Resort to git when we fail to download snapshot with HTTP::Tiny (kinda pointless but the code was already there)

## [0.04] - 2024-03-17

### Changed

- Install v2.8.8 on platforms that build from source
- Pull tarball instead of git clone on platforms that build from source

## [0.03] - 2024-03-17

### Changed

- Install v2.8.8 on Windows

## [0.02] - 2024-03-17

### Changed

- Minor documentation changes
- Move to Test2::V0

## [0.01] - 2023-10-02

### Changed

- It exists.

[Unreleased]: https://github.com/sanko/Alien-Xmake/compare/0.08...HEAD
[0.08]: https://github.com/sanko/Alien-Xmake/compare/0.07...0.08
[0.07]: https://github.com/sanko/Alien-Xmake/compare/0.06...0.07
[0.06]: https://github.com/sanko/Alien-Xmake/compare/0.05...0.06
[0.05]: https://github.com/sanko/Alien-Xmake/compare/0.04...0.05
[0.04]: https://github.com/sanko/Alien-Xmake/compare/0.03...0.04
[0.03]: https://github.com/sanko/Alien-Xmake/compare/0.02...0.03
[0.02]: https://github.com/sanko/Alien-Xmake/compare/0.01...0.02
[0.01]: https://github.com/sanko/Alien-Xmake/releases/tag/0.01
