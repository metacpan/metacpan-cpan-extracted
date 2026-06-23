# ADR 0015 — Agent/skill infrastructure: hardlinked invariants, repo-specific workers, model pinning

- Status: accepted
- Date: 2026-06-20
- Tags: infra, tooling, agents, skills, hardlink, model

## Context

This ADR is the first to record a **development-infrastructure** decision rather than a
DBIO runtime one (0001–0014 are all runtime architecture). The DBIO family is 17 sibling
repos (core + 16 drivers) that share Claude Code dev infrastructure under `.claude/`:
agents, skills, and the house rules. Two facts about that infrastructure were inconsistent
and one was actively broken:

- **Agents have two natures, treated as one.** Some agents are *repo-invariant* — the same
  job everywhere (`dbio-adr-auditor`, `dbio-release-checker`, `karr-coordinator`). Others are
  *repo-specific* — finetuned per database, carrying driver skills (`dbio-worker`). They were
  all just per-repo copies, so the invariant ones drifted: `dbio-adr-auditor` existed only in
  core despite declaring itself "Identical across every DBIO repo"; `karr-coordinator` had
  fragmented into several inode groups; `dbio-release-checker` was 17 loose copies.
- **The shared rules already proved the right mechanism.** `.claude/rules/dbio-rules.md` is
  hardlinked into all 17 repos (one inode, 17 links) — change the home, every repo sees it.
  The invariant agents were simply never enrolled in that scheme.
- **Agents inherited the session model and died at boot (karr #43).** An agent with no
  `model:` frontmatter inherits the parent session model. On `opus-4-8[1m]` (the 1M-context
  tier) the briefing-heavy `dbio-worker` failed to start — 0 tokens, "Usage credits required
  for 1M context". A per-call `model:` override did not help; the start-time tier is what gates.

## Decision

1. **Two agent classes, two mechanisms.**
   - *Invariant* agents (`dbio-adr-auditor`, `dbio-release-checker`, `karr-coordinator`) are
     **one physical file**, home in core, **hardlinked** into all 17 repos — exactly like
     `dbio-rules.md`. They are edited only at the home and re-linked outward.
   - *Repo-specific* agents (`dbio-worker`) stay one independent file per repo. Where a repo's
     worker diverges from the standard skill set (driver skills), it is **renamed
     `dbio-worker-<db>`** (`dbio-worker-sqlite`, `dbio-worker-postgresql`, …). Core keeps the
     bare `dbio-worker` as the reference. `dbio-dzil` — skill-identical to the standard but a
     distinct repo — becomes `dbio-worker-dzil`: a different file never keeps the shared name.
2. **`model:` is mandatory on every agent — never inherit the session model.** `opus` for
   code/judgment-heavy agents (`dbio-worker*`, `dbio-adr-auditor`); `sonnet` for mechanical
   agents (`dbio-test-mock-writer`, `dbio-release-checker`, `karr-coordinator`). The alias
   resolves to a non-1M tier, which boots under the gate (verified: core `dbio-worker` boots
   with `model: opus`).
3. **`dbio-test-mock-writer` stays core-only** (core tests use only mock storage; drivers test
   against real DBs). Its brief also fixes the division of labor: the dispatching main agent
   owns test *intent* and coverage judgment, the mock-writer owns the *mechanics*.

## Rationale

Hardlinking the invariants is the family's own proven method (`dbio-rules.md`): one source of
truth, zero drift, no sync tooling to maintain. Naming repo-specific workers with a `-<db>`
suffix removes the real hazard the user named: identical names over divergent content collide
the moment agents are referenced cross-repo or synced. Pinning `model:` explicitly is the
direct fix for karr #43 — the boot-time credit gate is driven by the *inherited* tier, and
only frontmatter `model:` (not a per-call override) changes it.

## Consequences

- **Hardlinks are fragile by mechanism, not by accident.** Atomic-rename editors (the Edit
  tool) and `git checkout`/`pull`/`merge` replace the inode and silently break the link — the
  home keeps the new content, the other 16 keep the old. So **after any edit to a shared file,
  it must be re-linked** (`ln -f` from core into every repo). Plain `git add`/`commit` do not
  break links. A relink/verify helper was deliberately *not* built yet (tracked, see below);
  until it exists the discipline is manual and drift can recur (that is how `karr-coordinator`
  fragmented).
- Adding an invariant agent: create it in core, hardlink it into all repos. Adding a driver
  repo: give it a `dbio-worker-<db>` and hardlink the three invariants in. `docs/driver-claude-md-template.md`
  documents the `dbio-worker-<driver>` naming.
- Every new agent must carry `model:`, or it risks the 1M-context boot gate again.

## Future architecture work (tracked cross-repo, not here)

A relink/verify tool (re-establish the hardlink groups for the invariant agents +
`dbio-rules.md` from core, assert one inode per group; run after edits and after clone/pull)
remains unbuilt — owned by the agent-infrastructure thread under karr #43.
