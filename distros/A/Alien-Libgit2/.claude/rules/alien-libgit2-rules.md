# Alien::Libgit2 House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They
load as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish
nothing until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Finds or builds libgit2, the linkable Git library. Read first: `alienfile` is the whole
distribution; read it *and* the CI workflows before changing either — they encode the same
CMake flags twice on purpose.

## Agent team

| Task | Agent |
|---|---|
| alienfile, share/ tarball, CI workflows, t/, lib/Alien/, POD | `alien-libgit2-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `alien-libgit2-release-manager` |
| Read-only research, audit, gap analysis | `alien-libgit2-worker` ("read-only, change nothing") |

Behavior-relevant = anything changing what gets installed or how it is found: `alienfile`,
`share/`, `.github/workflows/`, `cpanfile`, `dist.ini`, `t/`, and the POD stating the
version floor. Prose and `Changes` notes are not.

Work owned by `Git::Libgit2` or `Git::Native` becomes a ticket on that repo's board.

## Release

A libgit2 version change is always its own release, and `Git::Libgit2` / `Git::Native` get
told. Pre-release audit goes through `alien-libgit2-release-manager`.

## Hazards — mechanism and background: skill `alien-libgit2-core`

- **Pin the install type in CI.** Without `ALIEN_INSTALL_TYPE` a failed probe falls through
  to a share build and the job passes as "system". Every job pins `install-type:` — pin it
  for any job you add.
- **Both install paths, always.** A local `dzil test` proves one path at most — "tests
  pass" is wrong if only one install path ran. Anything touching the build runs
  `env ALIEN_INSTALL_TYPE=share dzil test` **and** `env ALIEN_INSTALL_TYPE=system dzil test`.
- **Never lower `minimum_version`.** No Debian release meets the 1.9.3 floor (bookworm
  1.5.1, trixie 1.9.0) — a failing probe there is the designed outcome, not a bug to fix
  by moving the floor.
- **`.claude/` is git-ignored except for a whitelist.** A new directory under it stays
  invisible to git until whitelisted — verify with `git status --short`.
- **Installed skills and rules are build artifacts.** The ones `skilletor` installs are
  overwritten by the next `skilletor sync` — never edit them. Only repo-owned files
  (tracked by git, no `skilletor` entry) may be edited.

## Perl and Alien specifics — reference, don't restate

House Perl style: `getty-perl-core`; Alien::Build mechanics: `perl-alien`; this
distribution's own facts: `alien-libgit2-core`.
