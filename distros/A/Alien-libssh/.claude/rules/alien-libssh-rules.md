# Alien::libssh House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They
load as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish
nothing until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Finds or builds libssh, the SSH library. Read first: `alienfile` is the whole
distribution; its comments record why each line exists — read them before changing a line
they explain.

## Agent team

| Task | Agent |
|---|---|
| alienfile, share/ tarball, t/, lib/Alien/, POD | `alien-libssh-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `alien-libssh-release-manager` |
| Read-only research, audit, gap analysis | `alien-libssh-worker` ("read-only, change nothing") |

Behavior-relevant = anything changing what gets installed or how it is found: `alienfile`,
`share/`, `cpanfile`, `dist.ini`, `t/`. Prose and `Changes` notes are not.

Work owned by `Net::LibSSH` becomes a ticket on that repo's board (`~/dev/p5-net-libssh`).

## Release

A libssh version change is always its own release, and `Net::LibSSH` gets told.
Pre-release audit goes through `alien-libssh-release-manager`.

## Hazards — mechanism and background: skill `alien-libssh-core`

- **Both install paths, always.** This host has no system libssh, so an unforced
  `dzil test` only ever runs the share build — "tests pass" is wrong if only one install
  path ran. Anything touching the build runs `env ALIEN_INSTALL_TYPE=share dzil test`
  **and** `env ALIEN_INSTALL_TYPE=system dzil test`. `prove -l t` builds nothing — not a
  test.
- **A share build that links is not a share build that runs.** The generated `libssh.pc`
  omits `-lcrypto -lz`; the `after 'gather'` hook adds them. `t/01-alien.t`'s `xs_ok` on
  the share path is the check — it fails at *load*, not at compile.
- **`.claude/` is git-ignored except for a whitelist.** A new directory under it stays
  invisible to git until whitelisted — verify with `git status --short`.
- **Installed skills and rules are build artifacts.** The ones `skilletor` installs are
  overwritten by the next `skilletor sync` — never edit them. Only repo-owned files
  (tracked by git, no `skilletor` entry) may be edited.

## Perl and Alien specifics — reference, don't restate

House Perl style: `getty-perl-core`; Alien::Build mechanics: `perl-alien`; the XS consumer
side: `perl-xs`; this distribution's own facts: `alien-libssh-core`.
