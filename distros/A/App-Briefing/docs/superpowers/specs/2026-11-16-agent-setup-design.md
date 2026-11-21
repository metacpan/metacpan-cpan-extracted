# Project agents and skilletor

## Goal and scope

Bring the briefing development checkout into line with the current Getty preset:
five project agents, managed shared rules and a short entry point.
The existing hook implementation and its public contracts remain unchanged by
this setup task. The user approved that scope on 2026-11-16.

## Chosen approach

Shared rules and Git/karr skills come through skilletor from their owning
repositories; `briefing-core` and the agents remain tracked project sources.
Another manually maintained copy of the house rules would drift again.
A comprehensive rewrite of both harnesses would exceed this setup task.
The development team follows the existing skilletor target `claude`;
the product's Codex support remains unchanged.

## Structure

- `.claude/skilletor.json`: portable sources, `getty-house`, Git and karr skills.
- `.claude/settings.json`: required plugins and marketplace; no new permissions.
- `.claude/skills/briefing-core/`: concise project conventions with disclosed references.
- `.claude/agents/briefing-{scout,worker,test-writer,reviewer,release-manager}.md`:
  distinct ownership, knowledge declared through `briefing.skills`.
- `.claude/rules/briefing-rules.md`: ownership and project-specific verification notes.
- `CLAUDE.md`: a short entry point with conditional pointers rather than a full manual.

## Constraints and evidence

Python 3.8+ for shared and Claude Code paths; standard library only.
No hook, product-skill, binary or manifest changes. No commit or push in this
initial setup scope. Keep the existing karr board. k5 concerns standalone
binaries without Python, not this setup; do not repurpose or close it.
Verify skilletor state, ack-team, briefing-doctor, a negative hook probe,
links/Git visibility and the existing unittest suite. Report native Windows
checks and real harness spawns as passed only when actually executed.
