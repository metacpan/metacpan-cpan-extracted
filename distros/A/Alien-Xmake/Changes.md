# Changelog

All notable changes to Alien::Xmake will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.1] - 2026-09-08

### Fixed

- xmake's core C engine prioritizes the `XMAKE_PROGRAM_DIR` env var over its own bundled Lua scripts creating situations where our local sharedir install attempts to run old, incompatible .lua from the system install.

## [v1.0.0] - 2026-09-07

No changes from previous release.

## [v0.9.5] - 2026-09-07

Looking for a reason not to make this v1.0.0...

### Changed

- Split `Alien::Xrepo` out into its own distribution and repo
- `Alien::Xmake::exe` returns the bare executable path without embedded quotes; the quote-on-demand sites now do their own quoting, and every list-form `system @cmd` / `Capture::Tiny` spawn avoids quote characters that made `CreateProcess` fail for paths with spaces on Windows.

## [v0.9.4] - 2026-09-04

### Added

- `Alien::Xmake::target_info( $name )` wraps the per-target detail of `xmake show -t <target>` as a hashref by default or the raw text with `plain => 1`.

### Changed
- Removed the deprecated `json => 1` option from `Alien::Xmake::show`; the upstream bare `--json` flag is deprecated in favour of `--format=json`, so callers use `format => 'json'`.

### Fixed
- v0.9.x has had a broken install step that just plain ignored the share directory.

## [v0.9.3] - 2026-09-03

### Fixed

- Fixed file permissions when copying directories

## [v0.9.2] - 2026-09-02

Aliens based on `xrepo` install only what end users need (libs, binaries, etc.) and not all the tools installed along the way (compilers, cmake, python, etc.).

### Added

- Just a bunch of examples in the docs.

### Changed

- `::Base::Builder::_resolve_alien` now re-exports installed packages with (`xrepo export -k shared --shallow`) to avoid extra toolchain clutter in the sharedir install. This might not be the *best* place to do it but it's the current place.
- `::Base` avoids reinstalling everything when running unit tests

## [v0.9.1] - 2026-09-02

More polish as I inch towards v1.0.0.

### Added

- Multi-package support in `Alien::Xrepo::Base` (borrowing from `Alien::Build`:
  - New `alt( [$pkg] )` accessor, modeled on `Alien::Base->alt`: without an argument (or with the primary name) it returns `$self`; with a non-primary name it returns a delegate whose `cflags`, `libs`, `libpath`, `bin_dir`, `kind`, `dynamic_libs`, `dist_dir`, `install_type`, `version`, and related accessors are pinned to that package. The delegate is the new `Alien::Xrepo::Base::Alt` class.
  - New `Alien::Base`-style accessors: `cflags_static`, `libs_static`, `dynamic_libs`, `dist_dir`, `install_type`, and `split_flags`.
  - `package_names` returns the bound package names, and `install` returns the list of package infos in list context.
  - This will allow me to merge Alien::SDL3_mixer, Alien::SDL3_image, Alien::SDL3_ttf into Alien::SDL3
- Security and Contributing policy files

## [v0.9.0] - 2026-09-01

The docs have been greatly expanded since January but the stars of this release are Alien::Xrepo and Alien::Xrepo::Base, an Alien::Base stand-in for installing tools and libraries from [xrepo](https://packages.xmake.io/), [vcpkg](https://vcpkg.io/en/packages), [conan](https://conan.io/center), [brew](https://brew.sh/) (homebrew/linuxbrew), [conda](https://anaconda.org/), [dub](https://dub.pm/) (Dlang libs), [pacman](https://wiki.archlinux.org/title/Pacman#Installing_packages) (if you use arch, btw) [clib](https://github.com/clibs/clib/), [apt](https://www.debian.org/distrib/packages) on Debian/Ubuntu, [Cargo](https://crates.io/) for Rust crates, [Portage](https://packages.gentoo.org/) on Gentoo, [Nimble](https://nimpackages.com/) for nimlang, [NuGet](https://www.nuget.org/) for .NET, [Zypper](https://documentation.suse.com/smart/systems-management/html/concept-zypper/index.html) on openSUSE, and even your own custom repositories with smart prerequisite management in just a few lines of Perl.

### Changed

- We install the latest tagged release of xmake rather than hardcoding a version. If the system install is older, we leave it alone and create a local install in our <share/> dir.

### Fixed

- `Alien::Xrepo` shouldn't choke when xrepo sends chatter to `STDOUT` like the compiler probe before the actual JSON we're looking for

### Added

- Alien::Xrepo::Base.
- New examples:
  - `eg/webui.pl` wraps [webUI](https://webui.me/) for fast, local, browser based GUIs
  - `eg/nuklear/` builds the header-only [Nuklear](https://github.com/immediate-mode-ui/nuklear) GUI library via xmake into a shared library (GDI backend on Windows, Xlib on Unix) and uses Affix to wrap that lib
  - `eg/repo_features.pl` is a feature tour covering third-party package manager support (`vcpkg::`, `conan::`, `brew::`, `pacman::`, `dub::`, ...) and creation of dependency graphs (`info( ..., depgraph => 1, format => 'dot' )` for   Graphviz
  - `eg/xrepo_inline_c.pl` an Inline::C walkthrough for downloading and linking `libpng` and `zlib`
  - `eg/xrepo_binary.pl` demonstrates using xrepo to install and run binaries; in this case `ninja`
  - Two example CPAN-style dists under `eg/examples/` demonstrating how to build a thin `Alien::` module on `Alien::Xrepo::Base`:
    - `Alien-Zstandard`: a runnable example with three demo scripts (Affix, Affix with compression, and FFI::Platypus) and unit tests; installed via xrepo as the `zstd` package
    - `Alien-Lsquic`: the plumbing for a heavy `lsquic` install with unit tests
- Automatic confirmation for xmake/xrepo prompts: both `Alien::Xmake` and `Alien::Xrepo` accept new constructor options `yes` and `confirm` with per-call `yes`/`confirm` overrides.
- Full coverage of xrepo actions in Alien::Xrepo
  - `fetch` returns parsed package info (or raw `--cflags`/`--ldflags`) without reinstalling
  - `info` supports `--depgraph` and `--format=json`
  - `scan` lists installed packages (optional lua-pattern filter)
  - `download` fetches package source archives
  - `import_pkg` / `export` handle offline package distribution
  - `list_repo` lists configured remote repositories
  - `env` sets up a package environment and runs a program (or `--show` it)
  - `search` supports `--addon`
  - `uninstall` supports `--all` and `--force`
  - `_build_args` now understands jobs, force/shallow/build, VS/NDK/SDK/MingW toolchain switches, and `--toolchain_host`
- Full coverage of xmake actions and plugins in Alien::Xmake
  - New constructor option `verbose` to echo commands as they run
  - Actions: `build`, `clean`, `create`, `configure`, `global`, `install`, `uninstall`, `package`, `pack`, `require`, `run`, `test`, `update`, `service`, `addon`
  - Plugins: `check`, `doxygen`, `format`, `lua`, `macro`, `project`, `repo`, `show`, `watch`
  - Generic escape hatch `task( $name, %options )` for tasks without a dedicated method
  - `show` strips ANSI codes, splits listings, and decodes `--format=json` into a data structure
  - The xmake `f`-style config switches are mapped to options like `plat`, `arch`, `mode`, `kind`, `vs`, `ndk`, `mingw`, `sdk`, `toolchain`, ... (plus a `set` hash for any `--key=value`)
  - `global` gets only the config keys xmake actually accepts there (`vs`, `ndk`, `qt`, ...)
  - Version-build accessor renamed `build()` to `buildid()` so `build` is the build action; the xmake `config` action is exposed as `configure()` to keep config( $key )` as the install-time data accessor
- New `installdir`/`cachedir` options to force a project-local package store (via `XMAKE_PKG_INSTALLDIR` / `XMAKE_PKG_CACHEDIR`) for reproducible, isolated builds
- `::PackageInfo` gains...
  - an `installdir` accessor (from fetch `artifacts.installdir`, else derived from the first libfile/include dir) and `bin_dir` falls back to `<installdir>/bin`, so tool packages (ninja, python, ...) can be installed and run as binaries
  - a `kind` accessor (`library` vs `binary`), surfaced by `print`/`dump`/`_data_printer`
- `Alien::Xrepo->new( root => $dir )` becomes the default `installdir` for every store-touching method, so one install call can run against a project-local store; used by `Alien::Xrepo::Base`
- Alien::Xrepo POD now describes binary/tool installs and not just shared libs for FFI
- New `theme` constructor option (default `plain`) so xmake/xrepo output carries no ANSI color codes; passed as `$ENV{XMAKE_THEME}` on every store-touching method, overridable per-call with `theme => ...`

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

[Unreleased]: https://github.com/sanko/Alien-Xmake/compare/v1.0.1...HEAD
[v1.0.1]: https://github.com/sanko/Alien-Xmake/compare/v1.0.0...v1.0.1
[v1.0.0]: https://github.com/sanko/Alien-Xmake/compare/v0.9.5...v1.0.0
[v0.9.5]: https://github.com/sanko/Alien-Xmake/compare/v0.9.4...v0.9.5
[v0.9.4]: https://github.com/sanko/Alien-Xmake/compare/v0.9.3...v0.9.4
[v0.9.3]: https://github.com/sanko/Alien-Xmake/compare/v0.9.2...v0.9.3
[v0.9.2]: https://github.com/sanko/Alien-Xmake/compare/v0.9.1...v0.9.2
[v0.9.1]: https://github.com/sanko/Alien-Xmake/compare/v0.9.0...v0.9.1
[v0.9.0]: https://github.com/sanko/Alien-Xmake/compare/0.08...v0.9.0
[0.08]: https://github.com/sanko/Alien-Xmake/compare/0.07...0.08
[0.07]: https://github.com/sanko/Alien-Xmake/compare/0.06...0.07
[0.06]: https://github.com/sanko/Alien-Xmake/compare/0.05...0.06
[0.05]: https://github.com/sanko/Alien-Xmake/compare/0.04...0.05
[0.04]: https://github.com/sanko/Alien-Xmake/compare/0.03...0.04
[0.03]: https://github.com/sanko/Alien-Xmake/compare/0.02...0.03
[0.02]: https://github.com/sanko/Alien-Xmake/compare/0.01...0.02
[0.01]: https://github.com/sanko/Alien-Xmake/releases/tag/0.01
