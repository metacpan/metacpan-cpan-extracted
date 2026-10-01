---
name: karr-foundation-cli
description: Use when running karr-foundation — periodic agent execution across several karr boards, drain loops, ticket mode, named agents, the coordination agent and its assignment, the hub chain and question mailbox, auto-block logic.
---

# karr-foundation — Periodic Agent Executor for karr Boards

Single-shot daemon that monitors multiple karr boards and runs an agent command
when work is available. Designed for cron/systemd-timer invocation.

## Quick start

```bash
# Config at ~/.config/karr-foundation/config.yml
dirs:
  - /path/to/repo1
  - /path/to/repo2
scan:
  - /path/to/parent-dir   # finds dirs with .karr file

# Per-repo .karr file (in each repo root)
command: claude -p "Use karr-coordinator agent, pick next task"
on_idle: skip
drain: true
max_runtime: 1800
max_attempts: 2

# Run via cron every 5 minutes
*/5 * * * * karr-foundation
```

## Run modes

`mode` says what one pass over a repo is:

- **`drain`** (default) — run the agent again and again until the board stops
  moving. See [references/drain.md](references/drain.md).
- **`single`** — exactly one agent run; the agent still chooses its own work.
- **`ticket`** — exactly one agent run, about **one card foundation names**.

The `drain: true|false` alias, the full drain-loop classification table, and
ticket-mode's eligibility and scoring: [references/drain.md](references/drain.md).

## Rules you must not get wrong

- **`KARR_CLAIM` travels with every run.** foundation exports a fresh
  `agent-name --unique` claim for each run's agent process, so the agent's own
  `move`/`handoff` default to a claim already scoped to this run —
  [references/operations.md](references/operations.md) (Environment).
- **A disabled board is skipped whole.** `karr disable` writes fleet-wide state
  into `refs/karr/config`; it is checked before the agent command is resolved
  and before the drain decision, and `--force` does not override it —
  [references/operations.md](references/operations.md) (Board-level disable).
- **`--dry-run` is never scored.** It stops right after logging the would-be
  START, before an iteration can be judged progress, stall or idle — never a
  STALL, never a count toward auto-block —
  [references/drain.md](references/drain.md) (Drain loop semantics).
- **`backlog` is out of reach for automated picking.** Ticket mode excludes it
  exactly as `karr pick` does, and nothing here promotes a card out of it —
  [references/drain.md](references/drain.md) (Ticket mode).
- **One agent per repository, always.** Concurrency is opt-in and bounded by
  three levels, but it is always across repositories and never inside one
  working tree — [references/configuration.md](references/configuration.md)
  (Concurrency).
- **Agent definitions and the assignment are local only.** Never board state,
  never synced — a command or a routing table on one machine may not exist on
  the next — [references/configuration.md](references/configuration.md)
  (Named agents) and [references/coordination-agent.md](references/coordination-agent.md).

## Exit codes

The same contract as `karr` (ADR 0002), because `ask`, `answer` and `chain` are
typed by people and scripted by agents, not only run by cron:

- **0** — the tick finished: boards drained, an overview printed, a question
  asked or answered, the chain worked through. A chain step that **failed**
  does not change this — that is a statement about the plan, not about this
  binary.
- **1** — runtime failure: no repository discovered, a config that does not
  parse, a hub command with no hub, an answer to a question that already had
  one, or `chain` unable to fetch `refs/karr-foundation/*`.
- **2** — usage error: an unknown command, an unknown option, an invalid option
  value, a missing or surplus positional argument.

A run killed by `SIGTERM`, `SIGINT` or `SIGHUP` exits `128 + signal` after
taking its agents down with it.

## When you need more

| Need | Read |
|---|---|
| `config.yml`, the per-repo `.karr` file and its resolution order, named agents and availability, concurrency's three levels | [references/configuration.md](references/configuration.md) |
| The hub, `karr-foundation plan`/`chain`, step kinds, the question mailbox (`ask`/`answer`) | [references/hub.md](references/hub.md) |
| The coordination agent: when it is called, the four deviations, the assignment it writes | [references/coordination-agent.md](references/coordination-agent.md) |
| Run modes in full, ticket mode, the drain classification table, auto-block, exponential cooldown, `on_drained` | [references/drain.md](references/drain.md) |
| `--status` overview, `--config`/`--force`/`--dry-run`, board-level disable, state files, environment variables, cron, enabling a repo fleet | [references/operations.md](references/operations.md) |
