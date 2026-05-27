# Alien::Libgit2

Provides the libgit2 C library for CPAN modules that link against it via
FFI or XS.

## What It Does

Alien::Libgit2 follows the Alien::Build pattern:

1. First checks if a system libgit2 (>= 1.5) is available via `pkg-config libgit2`
2. If not, builds libgit2 from source (bundled tarball — no network required)

## Used By

- `Git::Libgit2` — low-level FFI::Platypus bindings against libgit2
- `Git::Native` — high-level Moo wrapper on top of `Git::Libgit2`

Other consumers should call `Alien::Libgit2->dynamic_libs` (for FFI) or
`->cflags`/`->libs` (for XS).

## Bundled Source

Ships `libgit2-1.9.3.tar.gz` in `share/`. No network access required
during `cpanm` install — suitable for air-gapped environments.

## Build Config

Uses `[@Author::GETTY]` Dist::Zilla bundle with `alien_build = 1`.

Build requirements (for the share-install path only):
- `cmake` (libgit2 uses CMake)
- C compiler
- `pkg-config` (for system lib detection)
- OpenSSL headers (HTTPS backend)
- libssh2 headers (SSH transport)

## alienfile

The `alienfile` at the root defines the probe/build/install steps. Uses
`Alien::Build::Plugin::Build::CMake`. Build flags pin REGEX_BACKEND=builtin
so we don't pick up an inconsistent regex lib at runtime.

## Key Details

- System install preferred — faster, picks up distro security patches
- Share install builds libgit2 in the local Alien dir, no system pollution
- Pinned to a single bundled libgit2 version per Alien::Libgit2 release
  (ABI bumps between minor versions of libgit2)
