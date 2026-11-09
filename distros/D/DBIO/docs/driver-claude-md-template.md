# Driver CLAUDE.md — Template

Uniform template for the `CLAUDE.md` of each `DBIO-<Driver>` distribution. Reference for the
rollout that unifies all driver repos. Keep it slim: discipline and routing live in the
shared `.claude/rules/` plus the per-repo agents; only spell out genuine repo specifics here.

`<Driver>` = the CamelCase driver name (`SQLite`, `PostgreSQL`, `MySQL`, …).

The family-wide house rules (discipline, delegation, release) come from core through
skilletor and land in the driver as `.claude/rules/.local.dbio-rules.md` — auto-loaded by
Claude Code for the main agent and all subagents. The driver CLAUDE.md does NOT restate them.

The same goes for the family skills and the shared agents (`dbio-adr-auditor`,
`dbio-release-manager`, `karr-coordinator`), installed as `.claude/agents/.local.<name>.md`,
and for the standard worker, rendered from core's `dbio-driver-worker` template with the
vars `driver`, `dist_label` and `worker_skills` of the driver's `.claude/skilletor.json`. A
driver tracks only what is its own: `skilletor.json`, its `dbio-<driver>*` skills, a worker
of its own if the template does not fit, rules that hold for this repo only. Everything
installed is git-ignored — a fresh clone has it after `skilletor sync` — and is changed in
core, never in the installed copy.

---

```markdown
# CLAUDE.md — DBIO::<Driver>

This distribution ships its own `dbio-*` skills/agents and the shared `.claude/rules/`;
everything named here refers to those. The family-wide house rules (discipline, delegation,
release) live in `.claude/rules/.local.dbio-rules.md` — auto-loaded by Claude Code for the
main agent and all subagents.

## Delegation
Delegate behavior-relevant driver internals (Storage, SQLMaker, Introspect/Deploy/Diff,
types) to this repo's `dbio-worker-<driver>` instead of touching them yourself. Principle and lane:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-<driver>` (default), `dbio-release-manager`,
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
