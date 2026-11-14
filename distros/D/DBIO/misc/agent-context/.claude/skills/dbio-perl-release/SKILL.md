---
name: dbio-perl-release
description: Use when a dist.ini contains [@DBIO] and you prepare a release or change dist.ini — bundle options, versioning, dzil release flow.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DBIO uses `[@DBIO]` from `Dist::Zilla::PluginBundle::DBIO`.

## dist.ini

Drivers:
```ini
name = DBIO-DriverName

[@DBIO]
```
The bundle sets `author`, `license` (Perl_5) and `copyright_holder` (overridable with the
`copyright_holder` option; core also states `author` and `license` in its `dist.ini`).
`copyright_year` is not a bundle option; it stands in `dist.ini` when the dist states one
(core: 2005).

Heritage distributions (code derived from DBIx::Class — most extracted drivers):
```ini
name = DBIO-DriverName

[@DBIO]
heritage = 1
```
`heritage = 1` switches to `Pod::Weaver::PluginBundle::DBIO::Heritage`, which adds
a DBIx::Class copyright/attribution block to the generated POD;
`copyright_holder` defaults to `DBIO & DBIx::Class Authors`.

Core (`core = 1`):
```ini
name = DBIO
copyright_year = 2005

[@DBIO]
core     = 1
heritage = 1
```
Core extras: VersionFromMainModule, MakeMaker::Awesome, ExecDir, VersionLockstepTest.

## Repository metadata

All distributions (drivers and core) get `[DBIO::CodebergMeta]`. It derives the
`repository` / `bugtracker` / `homepage` resources from the git `origin` remote —
fully offline, no API token, no network. `origin` must point at `codeberg.org`
(the DBIO family lives at `codeberg.org/dbio/<repo>`); if it does not, the plugin
adds nothing rather than emitting metadata for the wrong forge. The bundle supplies the
resources, so `dist.ini` carries no `[MetaResources]` block.

## Agent skills (share_skill)

Each distribution ships the agent skills it OWNS (is the source of truth for)
into its sharedir. The bundle wires `[DBIO::GatherSkills]` + `[ShareDir]`:
GatherSkills copies `.claude/skills/<name>/` → `share/skills/<name>/` at build
time (sharedir, read at runtime through `DBIO::Skills`). The tracked `.claude/`
itself also lies in the tarball (see *The tarball*). Declare owned skills explicitly:

```ini
[@DBIO]
heritage = 1
share_skill = dbio-mssql
share_skill = dbio-mssql-database
```

- Each skill is shipped by exactly ONE dist (its home), never re-shipped from an
  installed copy. Drivers own `dbio-<driver>` + `dbio-<driver>-database`;
  derived dists (async/age/postgis/graphql) own only their own skill; the shared
  family skills belong to `DBIO` core (the karr skills come from the karr tool via
  skilletor, no DBIO dist ships them). `dbio-perl-release` is maintained in core and
  delivered to `dbio-dzil` through skilletor.
- Skills that only brief agents (`<dist>-core`) stay out of `share_skill`.
- Omitting `share_skill` makes GatherSkills derive owned skills from the dist
  name — declare them anyway, so the set is deterministic.
- Filtered bundles (`[@Filter]` in the EV dists) and the runtime access to the shipped
  skills (`DBIO::Skills`, `DBIO->skill`, `bin/dbio-skills`): `references/share-skill.md`.

## Version

- Every shipped `.pm` carries the same literal `our $VERSION` — the rule for
  writing it is in `dbio-perl-syntax`; the bundle mechanics that rewrite it:
- Drivers: `@Git::VersionManager` (first_version = 0.900000), with
  `RewriteVersion::Transitional` (`global = 1`, `finder = [:InstallModules]`) and
  `BumpVersionAfterRelease` (`finder = [:InstallModules]`) — the bundle rewrites
  and bumps every module in lockstep around release.
- Core: the dist version is read from `lib/DBIO.pm` via `[VersionFromMainModule]`
  (core does not use `@Git::VersionManager`). Nothing rewrites the sub-modules; they are
  raised by hand with it, and `xt/author/version-lockstep.t` names every module whose
  `$VERSION` is missing or differs.
- **Family alignment (soft rule):** keep the whole DBIO family on the *same*
  released version — bump laggards up to match, don't release a patchwork.
  Especially for a coordinated cross-repo train (a core change plus its
  driver/transport/extension shares): release every touched dist at one shared
  version so a given version of `X` always pairs with the same version across
  repos.

### Coordinated version step

For a family-wide step to one new version, in this order:

1. Core first: raise `$VERSION` in `lib/DBIO.pm` and in every module; the lockstep test
   is green.
2. In every dist's `cpanfile`, the family pins (`requires` and `recommends` alike) name
   that same number.
3. `Changes` of every dist is filled under `{{$NEXT}}`.
4. Dists follow in dependency order, core before the dists that require it.

A dist still carrying the previous number after the step was missed by the sweep.
The release itself runs only on the maintainer's go-ahead (see *Release*).

## PodWeaver

POD conventions of `[@DBIO]` (`=attr`/`=method`, `# ABSTRACT`, generated
sections): skill `dbio-perl-pod`.

The bundle also gathers `xt/author/pod-checker.t` (`[DBIO::PodCheckerTest]`):
`Pod::Checker` over the built, woven POD under `lib/` and `bin/`. Any error —
above all an unresolved internal `L<>` link — fails `dzil test` and
`dzil release`; warnings do not, and a plain install skips the test. Fix the
POD, never the gate.

## Dependencies

In `cpanfile`, not dist.ini. Bundle uses `[Prereqs::FromCPANfile]`.
Versioning rules for DBIO-family deps: see [[dbio-perl-syntax]].

## Changes — the change, not the card

Rule in every DBIO distribution: an entry in `Changes` says
what changed for the user of the dist, in words; it carries no karr card number, neither
`(kNN)` nor a board-qualified `(core kNN)`. The card belongs in the commit message, in
the house form `kNN`. Codeberg issues are public and keep their notation, `(Codeberg #13)`.

The changelog section of the commit-style skill applies in full: one topic one entry,
the destination not the journey. Released blocks (everything below a version line) are
not touched.

## Release

```bash
skilletor sync && ../dbio/maint/capped-test dzil test   # core: maint/capped-test dzil test
```

`dzil release`, any CPAN upload, `git tag` and `git push` only on the maintainer's
explicit go-ahead (house rules, *Release*); a plan that lists "release" as the next step
is not that go-ahead.

The release flow (`dzil release`), in order:

- Checks: `Git::Check` (only `dist.ini`, `Changes`, `cpanfile` may be dirty),
  `Git::CheckFor::CorrectBranch` (`main`), `TestRelease`, `Test::ChangesHasContent`,
  `InstallRelease` (`cpanm .`), then `ConfirmRelease` and `UploadToCPAN`.
- Core: `NextRelease` stamps `{{$NEXT}}`, then `Git::Commit` (same dirty allowance),
  `Git::Tag` and `Git::Push`.
- Drivers: `@Git::VersionManager` stamps, commits, tags and bumps; `Git::Push` pushes to
  `origin`.
- The tag format is `v%V` (`v` plus the version).

`skilletor sync` comes first. GatherSkills reads the skill dirs from disk, and a
dist may declare a `share_skill` it installs through skilletor rather than tracks
(`dbio-dzil` ships `dbio-perl-release`, whose source is core) — git-ignored, so a
fresh clone does not have it. A `share_skill` whose dir is missing is fatal; the
per-skill `.gitignore` skilletor writes is not gathered (ADR 0058 in core).

**Skilletor sources stay on `main`.** Every `.claude/skilletor.json` in the family
keeps `ref: "main"` for each source (`getty`, `karr`, `dbio-core`, `dbio-postgresql`,
`dbio-mysql`); `skilletor.lock.json` stays git-ignored. The family develops against
`main` together: a rule, agent or skill changed in core reaches every dist on its
next `skilletor sync`, and whoever synced last has the current state. A release does
not pin sources to tags and needs no tag on a source repository: the tarball carries
the tracked `.claude/` as it is, and `GatherAgentContext` records the full agent
context a release was built with, skilletor-installed skills included, under
`misc/agent-context/`.

## The tarball

- It holds everything tracked in git, dotfiles and agent setup included (`.claude/`,
  `CLAUDE.md`); left out are the files the build writes itself (`META.yml`, `META.json`,
  `MANIFEST`, `README`, `README.md`) and `.karr`.
- `GatherAgentContext` snapshots `.claude/` and `CLAUDE.md` (and `.codex/`, `AGENTS.md`
  where present) into `misc/agent-context/` (provenance, not installed).
- `DBIO::LicenseFile` checks the committed `LICENSE`: the text from `dist.ini`, or with
  `heritage` the DBIx::Class text. A missing or stale file stops the build.
- `DBIO::CoverageGate` is a test runner behind the build plugin: once the whole suite
  of the build directory is through, it scores `cover_db/` against `coverage_threshold`
  (default 80, `0` = off), for `dzil test` and `dzil release`, also under a parallel
  harness. Under `RELEASE=1` it fails without `cover_db/` and below the threshold.
  `dzil release` sets only `RELEASE_TESTING`, so a release runs with
  `RELEASE=1 HARNESS_PERL_SWITCHES=-MDevel::Cover dzil release`. The tarball carries no
  coverage test.
- `MetaResources` sets the family `x_IRC` channel.
- Core's `MetaNoIndex` keeps the test facades (`DBIO::Test::Conformance` & co.) indexed, they are public.

## Reference tests (dbio-dzil)

The tests in `dbio-dzil` are the executable reference for the bundle — read them when
unsure what `[@DBIO]` does. The list with what each pins: `references/bundle-tests.md`.
