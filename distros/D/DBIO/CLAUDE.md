# CLAUDE.md — DBIO Core

Canonical instruction file for the DBIO core repo. This distribution ships its own agent
skills (`.claude/skills/`), agents (`.claude/agents/`), and house rules (`.claude/rules/`);
every `dbio-*` skill and `dbio-*` agent named here refers to those. The family-wide
discipline, delegation, and release rules live in `.claude/rules/dbio-rules.md` — loaded
automatically by Claude Code, for the main agent and all subagents.

## Delegation

Delegate behavior-relevant DBIO code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/dbio-rules.md`. Agents in this repo:

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `dbio-worker` (default) |
| Write/extend tests (mock storage) | `dbio-test-mock-writer` |
| Commits, `Changes`, card → done, pre-release audit | `dbio-release-manager` |
| Cross-repo routing, push tickets to other DBIO repos | `karr-coordinator` |
| Gap audit of the ADRs | `dbio-adr-auditor` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main agent
delegates rather than loading them. Skill sources live under `.claude/skills/`.

## Local workflow (maintainer's machine) — install the core

On the machine where the driver dists are developed side by side with core, run
`dzil install` in core after each finished ticket so the driver dists pull the current core.
This is a local development step, not part of the build or release.

## Driver, deploy and extensions — ADR 0064–0067

- A schema always has a declared driver; core detects none from the DSN (`DBIO->driver_for` /
  `schema_for` are the only DSN-to-driver functions) — ADR 0067, 0059.
- The driver storage alone owns `dbio_deploy_class`; `deploy` installs through it — ADR 0064, 0066 §4.
- Database extensions are the schema's declared list (`DBIO::Extension`, `::Extension::List`,
  `::Extension::Protocol`; commutativity test `DBIO::Test::ExtensionSet`) — ADR 0066.
- The connect key `schema` names the connection's namespace — ADR 0065.

Skill: `dbio-driver-development` (`references/extension-layers.md`).

## Core build specifics

`[@DBIO] core = 1` enables: VersionFromMainModule (version from `$VERSION` in `lib/DBIO.pm`),
MakeMaker::Awesome, ExecDir and DBIO::VersionLockstepTest (`xt/author/version-lockstep.t`:
every module carries the main module's `$VERSION`). Beyond that, core's `dist.ini` sets
`heritage = 1` and the `share_skill` lines, and adds a `[MetaNoIndex]` block for the
internal test helpers.

dist.ini:
```ini
copyright_year = 2005

[@DBIO]
core = 1
heritage = 1
```

`copyright_holder` is not set there — the bundle derives it (`DBIO & DBIx::Class Authors`
for a `heritage = 1` dist).

## Testing — mock only

Core tests run on `DBIO::Test::Storage` (fake storage) only, with no `dbi:SQLite` and no real DB.
`DBIO::Test->init_schema` without DSN arguments. Mock: `$storage->mock(qr/.../, \@rows)`.
Real DB testing belongs in the driver dists. Details: skill `dbio-core`.

`DBIO_TEST_FAST=1` skips the slow files, those marked `use DBIO::Test::Slow;` after
`use Test::More;`; `RELEASE_TESTING` or `AUTOMATED_TESTING` overrides it. Marking rule: POD of
`DBIO::Test::Slow`.

**Verify recursively.** `t/` has subdirectories (`t/sqlmaker/`, `t/search/`, `t/prefetch/`,
`t/count/`, `t/resultset/`, `t/test/`, …) holding the bulk of the suite. `prove -l t/` is
NOT recursive — it runs only the top-level `t/*.t` and silently skips every subdir test, so
it reports green while most of the suite never ran. Always verify with
`maint/capped-test prove -lr t/` or `maint/capped-test dzil test` (both recursive, and always
through the wrapper -- live-testing rule 9); use `prove -l` only on an explicit single file.

This is a *dev-side* trap only — the shipped dist is fine. Dist::Zilla's MakeMaker plugins
(`[MakeMaker::Awesome]` here, plain `[MakeMaker]` in the drivers) auto-glob every gathered
`t/**/*.t` into the `Makefile.PL` `TESTS` key, so install-time `make test` / `cpanm` is
recursive by construction and a fresh `dzil build` always picks up new subdir tests. No
per-subdir registration is needed; just verify your own manual runs with `-r`.

## Skill / briefing infrastructure

Skill sources live under `.claude/skills/` (shipped in the tarball like every tracked file) and are packaged
into the sharedir by `Dist::Zilla::Plugin::DBIO::GatherSkills`; reachable at runtime via
`DBIO->skill('name')` / `DBIO::Skills`. Skill content lives in the skills; this file references it.

Core owns the `dbio-*` skills (tracked here, shipped via `share_skill` in `dist.ini`) and
installs the rest through skilletor (`.claude/skilletor.json`: `getty-git-commit-style` and
`claude-headless` from `getty`, the two karr skills from `karr`). Those are git-ignored: a fresh clone or worktree
has them only after `skilletor sync`, and `skilletor sync` runs before `dzil build` (ADR 0058).

## Family distribution — core is the skilletor source

Every other DBIO repo installs from this repo through skilletor (source `dbio-core` in its
`.claude/skilletor.json`): the family skills, the house rules (`.claude/rules/dbio-rules.md`),
the shared agents `dbio-adr-auditor`, `dbio-release-manager` and `karr-coordinator`, and the
standard driver worker, rendered from `.claude/agents/dbio-driver-worker.md.njk`. Change them
here; a driver repo picks the change up on its next `skilletor sync` and never edits its
installed copy (`.claude/agents/.local.*`, `.claude/rules/.local.*`, a skill dir carrying a
`.gitignore`).

The worker template takes three vars from the driver's `skilletor.json`: `driver` (the agent
becomes `dbio-worker-<driver>`), `dist_label` and `worker_skills` (its `briefing.skills`).
A driver whose worker needs text of its own keeps a tracked
`.claude/agents/dbio-worker-<driver>.md` instead of installing the template. Rules that hold
for one repo only go into a tracked `.claude/rules/<name>.md` there, beside the installed
house rules.
