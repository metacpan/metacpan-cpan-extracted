# BeePack House Rules

Apply to every task in this distribution unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their conventions from the skills
force-loaded via `briefing.skills` — this file is for the orchestrating main agent.

## Engineering discipline

1. **Think before coding** — state assumptions; ask rather than guess. Push back when a
   simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first, surgically applied** — minimum code that solves the problem, nothing
   speculative. Touch only what you must; don't "improve" adjacent code or formatting.
3. **Goal-driven execution** — define success criteria, loop until verified.
4. **Surface conflicts, don't average them** — contradicting patterns: pick one (more
   recent / more tested), explain why, flag the other. Don't blend.
5. **Read before you write** — `lib/BeePack.pm` and `bin/bee` share one behaviour surface
   (the type dispatch, the open/save model); read both before changing either.
6. **Tests verify intent, not just behavior** — a test that only checks an accessor cannot
   fail when MsgPack packing breaks, which is the failure that reaches a file's consumer.
   Reproduce a bug before fixing it; leave the regression test behind.
7. **A red test is a claim before it is a failure** — before changing code to turn a test
   green, say what the test asserts and whether your fix keeps that claim or replaces it.
8. **Checkpoint and fail loud** — summarize done / verified / left after each significant
   step. "Done" is wrong if anything was skipped silently; "tests pass" is wrong if any
   were skipped — say so.
9. **Match the codebase's conventions, even if you disagree** — conformance > taste.

## Delegation

Depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): do NOT touch behavior-relevant
  code yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run tests,
  manage git, edit `Changes`/`README`. When in doubt, delegate. Why: only the `beepack-*`
  agents get their skills force-loaded via `briefing.skills`; you get no briefing and would
  touch the CDB/MsgPack model and the CLI with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug `lib/BeePack.pm` or `bin/bee` (incl. POD) | `beepack-worker` (default) |
  | Write or extend tests in `t/` | `beepack-test-writer` |
  | Pre-release audit | `beepack-release-checker` |

- **You cannot spawn subagents** (you ARE a `beepack-*` agent): the lock does not apply —
  implement, refactor, debug and test per these rules.

Behavior-relevant = `lib/BeePack.pm`, `bin/bee`, their POD, and the tests in `t/`. Prose in
`README`/`Changes` bullets is not.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — don't
invoke the skill first, just use it. Git-native kanban; state lives in `refs/karr/*` in this
repo (single distribution, one board, no cross-repo handoff).

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` · `karr edit ID -a "note"`
  · `--claim NAME` · `karr move ID in-progress` — full surface: skill `kanban-issues-karr-cli`

Record drift and follow-up work as tickets rather than growing the current change.
**Serialize board mutations when fanning out** — parallel implementation is fine, but
collect results and then loop `karr move`/`handoff`/`sync` sequentially.

## Release — never without permission

`dzil build` / `dzil test` / `prove -lr t/` are fine anytime. `dzil release` and any CPAN
upload are STRICTLY forbidden without explicit go-ahead — even if a plan or `Changes` lists
"release" as the next step. The version in the tree is the *next* release; `dzil release`
bumps and tags, so never hand-bump it outside a deliberate version-seeding change.

## Public issues (GitHub) — never act without instruction

`github.com/cindustries/p5-beepack` has a **public issue tracker**. Never act on an issue
or PR there on your own initiative — not even to read it. No listing, viewing, commenting,
editing, closing or creating unless explicitly told to handle a specific item. Every write
publishes under the maintainer's account.

## Hazards specific to this distribution

- **`prove -l t/` is not recursive** and silently skips subdirectory tests, exiting 0. Use
  `dzil test` or `prove -lr t/`. Reserve non-`-r` for a single named file.
- **The CDB backend is `CDB_File`, self-contained** — it carries its own cdb implementation,
  so there is no system `libcdb` dependency and CI needs no system-library step. `CDB_File`
  has no in-place update, so BeePack holds an in-memory buffer and `save` rebuilds the file.
- **The CLI and the library must not drift.** `bin/bee`'s command-line type dispatch mirrors
  `set_type` in `lib/BeePack.pm`; a new value type is a paired edit in both.
- **`nil_exists` and the in-memory-buffer / rebuild-on-save model are deliberate** (skill
  `beepack-core`). A grep makes `nil_exists` look like dead-simple code worth collapsing —
  it is load-bearing and tested.

## Perl conventions — reference, don't restate

Module loading, Moo patterns, dependency pinning, `$VERSION`, the `[@Author::GETTY]` release
workflow and BeePack's own internals live in skills `getty-perl-core`, `getty-perl-moo`,
`getty-perl-release-author-getty`, `perl-release-dist-ini` and `beepack-core` (force-loaded
per lane via `briefing.skills` — `.claude/agents/` defines which agent briefs which). Do not
duplicate that content here.
