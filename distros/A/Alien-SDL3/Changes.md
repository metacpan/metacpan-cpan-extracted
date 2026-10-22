# Changelog

All notable changes to Alien::SDL3 will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v3.4.22] - 2026-10-21

### Added

- Document prerequisites based on what I needed to do for the CI.

## [v3.4.21] - 2026-10-19

- Bump minimum required `Alien::Xrepo` to v1.0.10 and allow installation of `libsdl3_image`, `libsdl3_ttf`, and `libsdl3_mixer` to fail without failing the overall installation of `Alien::SDL3`.

## [v3.4.20] - 2026-10-17

### Changed

- Bump minimum required `Alien::Xrepo` to v1.0.9.

### Fixed

 - Fix `t/02_affix.t` on systems using pre-installed libs from (vcpkg, apt, brew, etc.) which all report lowercase link names (sdl3, sdl3_image, ...) while building from source creates what I'd call 'normal' names (SDL3, SDL3_image, ...).
 - 64-bit x86 Solaris no longer builds 32-bit libraries thanks to the next item...
 - The bundled `libsdl3` recipe now survives the falsely detected cross-compile on Solaris. Xmake misreads the host arch as i386 and asks cmake to set up cross-compilation.

## [v3.4.19] - 2026-10-15

Well, I guess I'm going to have to tinker with versioning soon...

### Fixed

- On Windows, a Strawberry Perl host (gcc, no `cl` on PATH) could not install anything: xmake's `windows` platform never offers a gcc toolchain, so `perl Build` aborted with `toolchain not found!` and the prebuilt SDL3 DLLs were never fetched. The recipe now pins the xmake toolchain to the compiler Perl was built with, so the prebuilt DLL flavour, the import library used by the package self-test, and the library FFI opens all agree.
- `Affix` test died on an undefined value when the primary package was missing but others resolved: `package_info()` with no argument returns the primary package only, so its one-element list was always truthy. It now collects each named package and drops the undefs.

### Changed

- `t/00_compile.t` and `t/01_delegation.t` now fail only when a snapshot exists but the core `libsdl3` package does not resolve, instead of silently passing; a genuinely cold checkout (no snapshot) still skips. A companion library that failed (`libsdl3_image`, `libsdl3_ttf`, `libsdl3_mixer`) is reported and its checks skipped rather than failing the suite, since a dist with a working core is still useful. Both also surface whatever the build recorded for a failed package.

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

[Unreleased]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/v3.4.22...HEAD
[v3.4.22]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/v3.4.21...v3.4.22
[v3.4.21]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/v3.4.20...v3.4.21
[v3.4.20]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/v3.4.19...v3.4.20
[v3.4.19]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/v3.4.18...v3.4.19
[v3.4.18]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/v3.4.2...v3.4.18
[v3.4.2]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/v2.28.0...v3.4.2
[v2.28.0]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/0.05...v2.28.0
[0.05]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/0.04...0.05
[0.04]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/0.03...0.04
[0.03]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/0.02...0.03
[0.02]: https://github.com/Perl-SDL3/Alien-SDL3.pm/compare/0.01...0.02
[0.01]: https://github.com/Perl-SDL3/Alien-SDL3.pm/releases/tag/0.01
