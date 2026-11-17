# Alien::libssh

Provides the libssh C library for CPAN modules that link against it.

## What It Does

Alien::libssh follows the Alien::Build pattern:

1. First checks if a system libssh is available via `pkg-config libssh`
2. If not, builds libssh from source (bundled tarball — no network required)

## Used By

- `Net::LibSSH` (XS binding, `~/dev/p5-net-libssh`) — links against libssh at
  build time via `Alien::libssh->cflags` and `->libs`

## Bundled Source

The distribution ships `libssh-0.12.2.tar.xz` in `share/`. No network access
required during `cpanm` install — suitable for air-gapped environments.

## Build Config

Uses `[@Author::GETTY]` Dist::Zilla bundle with `alien_build = 1`.

Share-build requirements:
- `cmake` (libssh uses CMake)
- C compiler
- `pkg-config` (for system lib detection)
- OpenSSL and zlib headers (libssh links both; the static share build needs
  the consumer to link them too)

## alienfile

The `alienfile` at the root defines the probe/build/install steps. The
`PkgConfig` plugin probes and gathers on both paths; the share path is an
out-of-source static CMake build (`Build::CMake`) with an `after 'gather'`
hook that appends `-lcrypto -lz` to the link line. Every non-obvious line
carries a comment saying why — read them before changing it.

## Verification

```bash
dzil test                                  # whatever the probe decides
env ALIEN_INSTALL_TYPE=share  dzil test    # forced bundled build
env ALIEN_INSTALL_TYPE=system dzil test    # forced probe
```

`prove -l t` builds nothing and is not a test. Anything touching the alienfile
runs both forced paths.

## Delegation

Delegate behavior-relevant work to the right agent instead of touching it yourself —
the principle is a shared house rule (skilletor bundle `getty-cpan-dist@getty`); lanes and
hazards are in `.claude/rules/alien-libssh-rules.md`.

| Task | Agent |
|---|---|
| alienfile, `share/` tarball, `t/`, `lib/Alien/`, POD | `alien-libssh-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `alien-libssh-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Tickets live on the repo's `karr` board.

## Skills

`alien-libssh-core` is project-owned; every other skill under `.claude/skills/` is
installed by skilletor from `.claude/skilletor.json` and changes in its source repo.

| Skill | Covers |
|---|---|
| `alien-libssh-core` | this distribution: the two paths, the static build, the `-lcrypto -lz` line, the consumer |
| `perl-alien` | Alien::Build itself: `probe`/`share`, `PkgConfig`, `install_prop` vs `runtime_prop`, `Test::Alien` |
| `perl-xs` | the Perl/C boundary — `t/01-alien.t` compiles XS, and `Net::LibSSH` is XS |
| `getty-perl-core` | house Perl conventions |
| `getty-perl-release-author-getty`, `perl-release-dist-ini` | the `[@Author::GETTY]` bundle and `dist.ini` |
| `kanban-issues-karr-coordination` | the karr board |
