# Changelog

All notable changes to Alien::Xrepo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.8] - 2026-10-15

### Fixed

- Normalize a scalar `links` value from `xrepo fetch --json` back into an array ref.

## [v1.0.7] - 2026-10-15

### Fixed

- Limit each package to one registry refresh and one automatic retry per build tree. The counter is stored in checkpoint data so this limit is applied even if the build is resumed after a mid-stage failure.
- Checkpoints now record each stage as completed *before* persisting, so a resumed build does not repeat tasks that completed in a previous attempt.

## [v1.0.6] - 2026-10-14

Alpha runtime dependency diagnostic for FFI libraries. If, say libsdl3_ttf requires freetype, Alien::Xrepo will let you know.

It's... a work in progress.

### Added

- Runtime dependency diagnostic for FFI libraries:
  - `Alien::Xrepo` gains `runtime_deps`, `fetch_closure`, `scan_runtime_deps`, `loader_env_var`, and `dep_search_dirs`.
  - `Alien::Xrepo::PackageInfo` gains the `deps` and `runtime_deps` fields plus `with_runtime_deps`.

### Changed

- `Alien::Xrepo::Build` records each package's runtime dependencies so they ride into the snapshot and back out through `Runtime::package_info` without a second scan. Also warns when a dependency is `unresolved`.
- Require `Alien::Xmake` v1.0.5

## [v1.0.5] - 2026-10-14

### Added

- `Alien::Xrepo::Build::assert_installed`, an opt-in all-or-nothing check a packaging caller runs after `run()`: it drops the just-written snapshot and dies listing every package that failed, so a dist with a broken package fails its build instead of being reported green. `run()` itself stays non-fatal so one failed package never hides the siblings that did install.
- `Alien::Xrepo::Runtime` snapshot introspection: `has_snapshot`, `snapshot_path`, and `snapshot_errors`, so a consumer's tests can tell a cold checkout (no snapshot) from a snapshot that was written but is incomplete (a failed build).

### Changed

- `Alien::Xrepo::MB` and `Alien::Xrepo::MM` now call `assert_installed` after the build, turning a partial or failed install into a build failure.

## [v1.0.4] - 2026-10-07

### Fixed

- ExtUtils::Install installs files as readonly (mode 0444) so Xmake's templates (used by `xmake create`, etc.) would copy readonly files into a project and then try to modify them which obviously does not work. I just copy them to the global xmake directory on first use and fix permissions.
- In situations like prebuilt libs bundled in a single archive, `libpath` used to resolve to whichever lib the filesystem happened to sort first. The runtime library now uses the package's `links`; falling back to the first lib when none match.

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

[Unreleased]: https://github.com/sanko/Alien-Xrepo/compare/v1.0.8...HEAD
[v1.0.8]: https://github.com/sanko/Alien-Xrepo/compare/v1.0.7...v1.0.8
[v1.0.7]: https://github.com/sanko/Alien-Xrepo/compare/v1.0.6...v1.0.7
[v1.0.6]: https://github.com/sanko/Alien-Xrepo/compare/v1.0.5...v1.0.6
[v1.0.5]: https://github.com/sanko/Alien-Xrepo/compare/v1.0.4...v1.0.5
[v1.0.4]: https://github.com/sanko/Alien-Xrepo/compare/v1.0.3...v1.0.4
[v1.0.3]: https://github.com/sanko/Alien-Xrepo/compare/v1.0.2...v1.0.3
[v1.0.2]: https://github.com/sanko/Alien-Xrepo/compare/v1.0.1...v1.0.2
[v1.0.1]: https://github.com/sanko/Alien-Xrepo/compare/v1.0.0...v1.0.1
[v1.0.0]: https://github.com/sanko/Alien-Xrepo/releases/tag/v1.0.0
