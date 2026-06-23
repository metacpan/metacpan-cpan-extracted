# Driver CLAUDE.md — Template

Uniform template for the `CLAUDE.md` of each `DBIO-<Driver>` distribution. Reference for the
rollout that unifies all driver repos. Keep it slim: discipline and routing live in the
shared `.claude/rules/` plus the per-repo agents; only spell out genuine repo specifics here.

`<Driver>` = the CamelCase driver name (`SQLite`, `PostgreSQL`, `MySQL`, …).

The family-wide house rules (discipline, delegation, release) live in
`.claude/rules/dbio-rules.md` — hardlinked into every repo and auto-loaded by Claude Code for
the main agent and all subagents. The driver CLAUDE.md does NOT restate them.

---

```markdown
# CLAUDE.md — DBIO::<Driver>

This distribution ships its own `dbio-*` skills/agents and the shared `.claude/rules/`;
everything named here refers to those.

## Delegation
Delegate behavior-relevant driver internals (Storage, SQLMaker, Introspect/Deploy/Diff,
types) to this repo's `dbio-worker-<driver>` instead of touching them yourself. Principle and lane:
`.claude/rules/dbio-rules.md`. Repo agents: `dbio-worker-<driver>` (default), `dbio-release-checker`,
`karr-coordinator`. The worker carries its skills via `briefing.skills` — no skill-loading
instruction belongs here.

## Namespace
- `DBIO::<Driver>` — schema component
- `DBIO::<Driver>::Storage` — storage
(+ variants)

## Driver specifics
Native deploy triad (Introspect/Diff/Deploy), SQLMaker quirks, test setup (mock + live DSN
env), key-modules table. Only what genuinely belongs to this repo.
```
