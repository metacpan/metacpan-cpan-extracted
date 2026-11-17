---
name: alien-libgit2-core
description: Use when working on the Alien::Libgit2 distribution — its alienfile, the 1.9.3 version floor, the bundled libgit2 tarball, the four-job CI matrix, or what the FFI consumers (Git::Libgit2, Git::Native) depend on.
metadata:
  type: project
---

# Alien::Libgit2 — core

Force-loaded into every `alien-libgit2-*` agent before its first turn; do not
restate it in an agent body. Generic Alien::Build mechanics (probe/share, the
`PkgConfig` plugin, `Test::Alien`, `install_prop` vs `runtime_prop`) live in
skill `perl-alien` — this file holds only what is true about *this* distribution.

## What the distribution is

One job: make a libgit2 >= 1.9.3 available to Perl, over two paths.

- **system** — `plugin 'PkgConfig' => (pkg_name => 'libgit2', minimum_version => '1.9.3')`.
- **share** — CMake build of `share/libgit2-1.9.3.tar.gz`, no network
  (`Fetch::Local` + a `file://` `start_url` built with `Path::Tiny->cwd`).

`lib/Alien/Libgit2.pm` is deliberately logic-free: `use parent 'Alien::Base'`,
`$VERSION`, POD. Everything that decides anything is in `alienfile`. Consumers
get `dynamic_libs` (FFI) or `cflags`/`libs` (XS) from `Alien::Base` — do not add
methods here to "help" them.

The share build's CMake flags are load-bearing: `USE_SSH=ON`,
`USE_HTTPS=OpenSSL`, `REGEX_BACKEND=builtin` (builtin so a system PCRE cannot
change matching behaviour at runtime), plus `BUILD_TESTS/CLAR/EXAMPLES=OFF`.
Anything that builds libgit2 elsewhere — the CI system job included — uses the
same flag set, or the two paths stop being comparable.

## The 1.9.3 floor is a bug gate, not an API requirement

libgit2 PR #7165 (in 1.9.3) stopped the ssh transport looping forever on
`LIBSSH2_ERROR_TIMEOUT`. Below it, a peer that accepts the connection and then
goes silent parks the caller indefinitely: libssh2 does its own reads and no
libgit2 option — `GIT_OPT_SET_SERVER_TIMEOUT` included — reaches that loop.
Measured: against 1.9.0 a fetch was still blocked after 25 s; against 1.9.3 the
same fetch returns at the configured timeout.

**No Debian release meets the floor** (bookworm 1.5.1, trixie 1.9.0). So on
Debian the probe fails *by design* and the share build runs. That is the
intended outcome — a probe failure there is never a reason to lower
`minimum_version`.

The version number is written in `alienfile`, the POD in `lib/Alien/Libgit2.pm`,
`README.md`, `CLAUDE.md`, `.github/workflows/linux.yml` and this skill — they move
together.

## Consumers and ABI

`Git::Libgit2` (FFI::Platypus, binds `git_*` symbols by name at runtime) and
`Git::Native` (Moo wrapper on top of it). Because they bind at runtime, the
libgit2 version is a compatibility surface: libgit2 breaks ABI between minor
versions. One bundled libgit2 per Alien::Libgit2 release; changing it is its own
release, and the consumers get told.

Cross-repo work goes to that repo's karr board (`~/dev/p5-git-libgit2`,
`~/dev/p5-git-native`) — never a direct edit there from here.

## Upgrading the bundled libgit2

1. `git rm` the old tarball, add the new one under `share/` — one 7 MB tarball
   in the tree, never two.
2. `alienfile`: the `start_url` filename. Raise `minimum_version` only when the
   new release fixes something a consumer needs — the floor tracks bugs, not
   "latest".
3. `.github/workflows/linux.yml`: the system job untars and builds that same
   tarball into `/usr/local` and asserts `pkg-config --modversion libgit2`
   against a hardcoded version. Both strings are in the workflow.
4. `Changes`: under `{{$NEXT}}`, which libgit2 and why.
5. Run both install paths locally (below) before calling it done.

## Verification — both paths, every time

```bash
dzil test                                  # whatever the probe decides here
env ALIEN_INSTALL_TYPE=share  dzil test    # forced bundled build
env ALIEN_INSTALL_TYPE=system dzil test    # forced probe; fails loudly with no system lib
```

An unforced `dzil test` on a machine that has libgit2 proves nothing about the
share build; on Debian it never enters the probe at all. Share-build
prerequisites: cmake, a C compiler, pkg-config, OpenSSL headers, libssh2 headers. Build logs and the gathered `alien.json` land in
`_alien/` — read that file first when a consumer sees flags it did not expect.

`t/01-alien.t` is `alien_ok` + `ffi_ok` on `git_libgit2_init` /
`_shutdown` / `_version`; FFI, not XS, because every consumer is FFI.

## CI matrix — four jobs, install type always pinned

`linux.yml` and `macos.yml` each run one system job and one share job, and every
one passes `install-type:` to the shared `dzil-test` composite action. That pin
is the point: without it a failed probe silently falls through to a share build
and the job reports green for the path it never tested. On linux the system job
installs the bundled 1.9.3 into `/usr/local` itself (apt cannot reach the floor);
on macOS Homebrew's libgit2 is the real system-path coverage, guarded by a
`pkg-config --atleast-version=1.9.3` check up front.

This is not hypothetical: a job without the pin once passed as "system" on apt's
below-floor libgit2-dev. That is why every job pins `install-type:` and every
job you add must too.

## Repo mechanics

- **`.claude/` is git-ignored except for a whitelist.** The root `.gitignore` ignores
  `.claude/*` and re-admits `settings.json`, `agents/`, `skills/`, `rules/` — a *new*
  directory under `.claude/` therefore stays invisible to git until it is whitelisted
  there. Verify with `git status --short` after creating one; the same applies to
  `.claude/worktrees/`, which is ignored explicitly.
- **Two kinds of skill live under `.claude/skills/`.** The ones `skilletor` installs
  (`skilletor status` lists them under *project scope*) carry a `.gitignore` holding `*`
  in their own directory — they are build artifacts, the next `skilletor sync` overwrites
  them, and editing one is forbidden. A repo-owned skill (tracked by git, no entry in
  `.claude/skilletor.json`) belongs to this repository: `alien-libgit2-core` is the only
  one here, and it is the file to extend when the rules grow too long.
