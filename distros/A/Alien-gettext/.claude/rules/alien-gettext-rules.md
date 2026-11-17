# Alien::gettext House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They
load as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish
nothing until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Finds or builds the GNU gettext command-line tools. Read first: the root `alienfile` and
`dist.ini` — `[@Author::GETTY]` with `alien_build = 1` generates the `Makefile.PL` from the
`alienfile` at `dzil build`.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug the alien config, `lib/Alien/`, `t/`, POD, tool set | `alien-gettext-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `alien-gettext-release-manager` |
| Read-only research, audit, gap analysis | `alien-gettext-worker` ("read-only, change nothing") |

Behavior-relevant = the `alienfile`, the `alien_*` config in `dist.ini`, the install-time
probe and share build, the tool set, `lib/Alien/gettext.pm`, and `t/`. Pure prose docs and
changelog notes are not.

## Hazards

- **The build is the root `alienfile` (Alien::Build).** There is no checked-in
  `Makefile.PL`/`Build.PL` to edit — it is generated at `dzil build`.
- **The share build downloads from `ftp.gnu.org` at install time** — no bundled tarball,
  so it needs the network and tracks the newest GNU release (no version floor). A single
  unforced `dzil test` proves only the path this box lands on; run the forced
  `ALIEN_INSTALL_TYPE=share` / `=system` pair before calling a build change verified —
  "tests pass" is wrong if a path was never exercised.

## Perl / Alien specifics — reference, don't restate

House Perl conventions, the `[@Author::GETTY]`/`dist.ini` bundle, Alien probe/share
mechanics and this distribution's tool set live in the briefed skills (`getty-perl-core`,
`getty-perl-release-author-getty`, `perl-release-dist-ini`, `perl-alien`,
`alien-gettext-core`).
