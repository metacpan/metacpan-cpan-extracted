# Changelog

All notable changes to Alien::SDL3 will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v3.4.18] - 2026-10-07

### Changed

- Updated to SDL3 3.4.18
- Install satellite libs SDL_image (v3.4.8), SDL_ttf (v3.2.2), and SDL_mixer (v3.2.4)
- Use `Alien::Xrepo` to locate, build, or install a prebuilt libs unless a system install meets our version requirements

## [v3.4.2] - 2026-02-22

### Changed

- Updated to SDL3 3.4.2

## [v2.28.0] - 2025-12-12

### Changed

  - Updated to SDL3 3.2.28

## [0.05] - 2025-10-17

### Changed

  - Updated to SDL3 3.2.24

## [0.04] - 2023-06-07

### Fixed

  - Diagnostic release to investigate smoker environment issues ([CPAN Report](http://www.cpantesters.org/cpan/report/4550e21c-053a-11ee-98b0-b3c3213a625c))

## [0.03] - 2023-06-06

### Fixed

  - Prevented cleaning of paths from tarballs that were never extracted
  - Explicitly return false when download or extraction of library source fails
  - Investigated `Archive::Extract` path issues on Win32 ([CPAN Report](http://www.cpantesters.org/cpan/report/a8235ba9-762a-1014-8029-f651364cc2ba))

## [0.02] - 2023-06-06

### Changed

  - Complied with `Module::Build`'s clean action
  - Returns list of libs (note: currently disorganized)
  - Now attempts to die immediately when SDL3 fails to build

## [0.01] - 2023-06-05

### Added

  - Original version
  - Installs from the tip of main
  - Note: Does not pull prebuilt binaries for Windows

[Unreleased]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/v3.4.18...HEAD
[v3.4.18]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/v3.4.2...v3.4.18
[v3.4.2]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/v2.28.0...v3.4.2
[v2.28.0]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/0.05...v2.28.0
[0.05]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/0.04...0.05
[0.04]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/0.03...0.04
[0.03]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/0.02...0.03
[0.02]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/0.01...0.02
[0.01]: https://github.com/Perl-SDL3/Alien-SDL3.pm/releases/tag/0.01
