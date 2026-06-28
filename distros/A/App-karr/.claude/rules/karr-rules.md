# App::karr House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over speed
on non-trivial work; use judgment on trivial tasks. Loaded automatically by Claude Code at
launch (same priority as `.claude/CLAUDE.md`). Subagents get their discipline from the skills
force-loaded via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess. Present
   alternatives when ambiguous. Push back when a simpler approach exists. Stop when confused;
   name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative. No
   abstractions for single-use code.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code, comments, or
   formatting. Match existing style.
4. **Read before you write** — Before new code, read exports, immediate callers, shared
   utilities (`Role/*`, `BoardStore`, `Git`, `Task`, `Config`). "Looks orthogonal" is dangerous.
5. **Tests verify intent, not just behavior** — A test that can't fail when the logic changes is
   wrong. Reproduce a bug before fixing it; leave a regression test behind.
6. **Match the codebase's conventions, even if you disagree** — Conformance > taste. Surface a
   harmful convention; don't fork silently.
7. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is wrong if any
   were skipped. Surface uncertainty, don't hide it.

## Delegation

Depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant karr
  code yourself — delegate to `karr-worker`. Your lane: coordinate, inspect, plan, review diffs,
  run tests, manage git, edit non-behavioral docs. Why: only the `karr-*` agents get their skills
  force-loaded via `briefing.skills`; you get no briefing and would touch internals with too
  little context. Specialist lanes:

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `karr-worker` (default) |
  | Write/extend tests under `t/` | `karr-test-writer` |
  | Pre-release audit (Changes, cpanfile, dist.ini, version) | `karr-release-checker` |
  | POD (`=attr`/`=method`, ABSTRACT) | `karr-pod-writer` |

- **You cannot spawn subagents** (you ARE a `karr-*` agent): The delegation lock does not apply —
  implement, refactor, debug, and test per these rules.

Behavior-relevant = CLI command logic (`Cmd/*`), refs-backed storage (`BoardStore`, `Git`,
`Lock`, `SyncGuard`), `Task`/`Config` parsing and writing, sync lifecycle, tests.

## Coordination — karr board (dogfood, always in scope)

This repo manages its own work on its own board — `refs/karr/*` already exists here. karr is the
tool *and* the workflow, so use it; don't invoke a skill first, just run it:

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` — new ticket
- `karr edit ID -a "note"` · `--claim NAME` · `--block "why"` — update
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review

Bugs found while dogfooding become tickets on this board. Full command surface (pick / context /
set-refs / multi-agent): skill `kanban-issues-karr-cli`.

## Release — never without permission

`dzil build` / `dzil test` / `prove -l t/` are fine anytime. `dzil release` and any CPAN upload
are STRICTLY forbidden without the maintainer's explicit go-ahead — even if a plan or roadmap
lists "release" as the next step. For anything heading toward release: stop and ask. After a
release the `$VERSION` bump in `lib/App/karr.pm` is a separate, deliberate commit.

## Perl specifics — reference, don't restate

Module loading, Moo/Moose patterns, cpanfile pinning for Getty-authored deps, and house style
live in skill `perl-core` (force-loaded for `karr-*` agents). Do not duplicate that content here.
