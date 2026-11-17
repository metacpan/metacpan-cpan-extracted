# Alien::Libgit2

Provides the C library [libgit2](https://libgit2.org/) to CPAN modules that link against
it. Consumers are `Git::Libgit2` (low-level FFI::Platypus bindings) and `Git::Native`
(Moo wrapper on top of it), both via `Alien::Libgit2->dynamic_libs`; `->cflags` / `->libs`
exist for XS consumers.

Two install paths, decided at install time: a system libgit2 found by
`pkg-config libgit2` (>= 1.9.3), or a CMake build of the bundled source tarball. The
share build needs no network — suitable for air-gapped installs.

## Layout

| Path | Holds |
|---|---|
| `alienfile` | every decision: the `PkgConfig` probe and the CMake share build |
| `share/libgit2-1.9.3.tar.gz` | the bundled source, exactly one tarball |
| `lib/Alien/Libgit2.pm` | `use parent 'Alien::Base'` + `$VERSION` + POD, no logic |
| `t/01-alien.t` | `alien_ok` + `ffi_ok` on `git_libgit2_init` / `_shutdown` / `_version` |
| `.github/workflows/` | four jobs — system and share, on linux and macOS |

Packaging is `[@Author::GETTY]` with `alien_build = 1`. `dzil test` covers whichever path
the probe lands on here, so anything touching the build runs both explicitly:

```bash
env ALIEN_INSTALL_TYPE=share  dzil test
env ALIEN_INSTALL_TYPE=system dzil test
```

The share build needs cmake, a C compiler, pkg-config, OpenSSL headers and libssh2
headers.

## The 1.9.3 floor

A system libgit2 is preferred — faster, and it picks up distro security patches — but
only from 1.9.3 up: below that, libgit2's ssh transport hangs forever on a silent peer
(libgit2 PR #7165), so older distro libs fall through to the share build. Mechanism,
measurements, ABI pinning and the procedure for bundling a new libgit2: skill
`alien-libgit2-core`.

## Delegation

Delegate behavior-relevant work to the right agent instead of touching it yourself —
the principle is a shared house rule (skilletor bundle `getty-cpan-dist@getty`); lanes and
hazards are in `.claude/rules/alien-libgit2-rules.md`.

| Task | Agent |
|---|---|
| alienfile, `share/` tarball, CI workflows, `t/`, `lib/Alien/`, POD | `alien-libgit2-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `alien-libgit2-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Tickets live on the repo's `karr` board.

## Skills

`alien-libgit2-core` is project-owned; every other skill under `.claude/skills/` is
installed by skilletor from `.claude/skilletor.json` and changes in its source repo.

| Skill | Covers |
|---|---|
| `alien-libgit2-core` | this distribution: the two paths, the floor, bundling, the CI matrix |
| `perl-alien` | Alien::Build itself: `probe`/`share`, `PkgConfig`, `install_prop` vs `runtime_prop`, `Test::Alien` |
| `getty-perl-core` | house Perl conventions |
| `getty-perl-release-author-getty`, `perl-release-dist-ini` | the `[@Author::GETTY]` bundle and `dist.ini` |
| `kanban-issues-karr-coordination` | the karr board |

`perl-xs` is deliberately not linked: every consumer reaches libgit2 through FFI, so
this distribution has no Perl/C boundary. Link it if an XS consumer ever appears.
