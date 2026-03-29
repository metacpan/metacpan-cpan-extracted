# Alien::libssh

Provides the libssh C library for CPAN modules that link against it.

## What It Does

Alien::libssh follows the Alien::Build pattern:

1. First checks if a system libssh is available via `pkg-config libssh`
2. If not, builds libssh from source (bundled tarball — no network required)

## Used By

- `Net::LibSSH` (XS binding) — links against libssh at build time

## Bundled Source

The distribution ships `libssh-0.10.6.tar.xz` in `share/`. No network access
required during `cpanm` install — suitable for air-gapped environments.

## Build Config

Uses `[@Author::GETTY]` Dist::Zilla bundle with `alien_build = 1`.

Build requirements:
- `cmake` (libssh uses CMake)
- C compiler
- `pkg-config` (for system lib detection)

## alienfile

The `alienfile` at the root defines the probe/build/install steps. Uses
`Alien::Build::Plugin::Build::CMake`.

## Key Details

- System install is preferred (faster, uses distro security patches)
- Share install builds a static lib in the local Alien dir
- `Alien::libssh->cflags` and `->libs` used by `Net::LibSSH`'s `Makefile.PL`
