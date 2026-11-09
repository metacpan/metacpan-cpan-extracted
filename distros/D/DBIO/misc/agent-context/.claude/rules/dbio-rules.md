# DBIO House Rules

## Engineering discipline (every task, every DBIO distribution; caution over speed)

1. **Think before coding** — State assumptions. When uncertain, ask. Present the readings
   of an ambiguous request. Push back when a simpler approach exists. When confused, name
   what is unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative, no
   abstraction for single-use code.
3. **Surgical changes** — Touch only what you must; match existing style.
4. **Goal-driven execution** — Define success criteria, loop until verified.
5. **Surface conflicts** — Contradicting patterns: pick one (more recent / more tested),
   say why, flag the other for cleanup.
6. **Read before you write** — Read exports, immediate callers and shared utilities first.
7. **Tests verify intent** — A test encodes WHY behavior matters and fails when the
   business logic changes.
8. **Checkpoint after every significant step** — done / verified / left.
9. **Match the codebase's conventions** — Conformance over taste; surface a harmful
   convention, don't fork silently.
10. **Fail loud** — "Done" and "tests pass" hold only when nothing was skipped silently.
11. **A red test is a claim before it is a failure** — Before changing code to turn it
    green, say what the test asserts and whether the fix keeps that claim or replaces it.
    A wrong claim is fixed as a claim, and said so.

Composition seams: changing `@ISA` / `use base` of a component, storage layer or storage
class is an architecture change with a ticket and an ADR; an extension never determines
the driver. Skill `dbio-perl-class-patterns`, § *Composition seams*.

## Delegation

- **You can spawn subagents** (orchestrating main agent): behavior-relevant DBIO code goes
  to this repo's worker agent (`dbio-worker`, or `dbio-worker-<db>` in driver repos).
  Your lane: coordinate, inspect, plan, review diffs, run tests, edit non-behavioral docs.
  When in doubt, delegate: only the `dbio-*` agents get their skills loaded via
  `briefing.skills`.
- **You cannot spawn subagents** (you ARE a worker): implement, refactor, debug and test
  per these rules.

Behavior-relevant = runtime behavior, public API, SQL generation, transactions, adapters,
migrations, type mapping, error handling, tests, performance.
**Other DBIO repos:** start a Claude inside the target repo (`cd` there, `claude -p …`),
which comes up on that repo's CLAUDE.md, rules, agents and skills. Its scope: implement,
test, commit locally — no `git push`, no release. Pass `--model` explicitly (default: this
session's model), run repos serially. A worker that needs downstream work files a ticket.
Skills `claude-headless`, `dbio-coordination` § *Direct cross-repo execution*.

**Commits:** only `dbio-release-manager` commits. A worker leaves a commit-ready tree and
hands its card to `review`; the main agent then dispatches the release manager.

## Skills, rules, agents — installed by skilletor

Core is the one source of the family skills, these rules and the shared agents; every other
repo installs them through skilletor (ADR 0058). Edit the source in core, then
`skilletor sync`; installed copies (`.claude/agents/.local.*`, `.claude/rules/.local.*`, a
skill dir with a `.gitignore`) are overwritten by the sync. A fresh clone or worktree has
them only after `skilletor sync`.

## Coordination — karr board

`karr` is always in scope. Load skill `kanban-issues-karr-coordination` before creating,
editing, moving or handing off a card, and before citing one in prose or a commit; plain
reads (`karr list` / `board` / `show`) need no load. Cards are written `kNN` in prose,
commits and code comments (the CLI takes bare numbers). `Changes`, POD, README and
messages describe the behaviour itself and carry no card number; the card lives in the
commit. Detail: skill `dbio-perl-release`, § *Changes*. Routing and handoff across repos:
skill `dbio-coordination`.

## Public issues (Codeberg)

Codeberg issues are the public tracker, written under the maintainer's name. Touch one
(even to read) only when the user names it; confirm every write first.
Skill `dbio-codeberg-user-issues`.

## Release

`dzil build` / `dzil test` are fine anytime. `dzil release` and any CPAN upload happen only
with the maintainer's explicit go-ahead, also when a plan lists "release" as the next step.

## Live testing

Every suite runs through `maint/capped-test` (core; `../dbio/maint/capped-test` from a
driver), a live one after `maint/live-preflight`; one run per database, no `prove -j`.
Rules and maintainer infrastructure: skill `dbio-driver-development`,
`references/live-testing.md`.
