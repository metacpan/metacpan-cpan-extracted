---
name: kanban-issues-karr-foundation-cli
description: Use when managing karr-foundation — periodic agent execution across multiple karr boards, drain loops, and auto-block logic.
---

# karr-foundation — Periodic Agent Executor for karr Boards

Single-shot daemon that monitors multiple karr boards and runs an agent command
when work is available. Designed for cron/systemd-timer invocation.

## Quick start

```bash
# Config at ~/.config/karr-foundation/config.yml
dirs:
  - /storage/raid/home/getty/dev/perl/dbio-dev/dbio
  - /storage/raid/home/getty/dev/perl/dbio-dev/dbio-postgresql
scan:
  - /storage/raid/home/getty/dev/perl/dbio-dev   # finds dirs with .karr file

# Per-repo .karr file (in each repo root)
command: claude -p "Use karr-coordinator agent, pick next task"
on_idle: skip
drain: true
max_runtime: 1800
max_attempts: 2

# Run via cron every 5 minutes
*/5 * * * * karr-foundation
```

## Config file

Default: `~/.config/karr-foundation/config.yml`

```yaml
dirs:
  - /path/to/repo1
  - /path/to/repo2

scan:
  - /path/to/parent-dir   # finds direct children with .karr file
```

## Per-repo .karr file

Place in repo root. All keys optional. Agent execution is opt-in: a board runs
an agent only if it has `command` **or** `claude: true`. With no agent on any
board, `karr-foundation` prints a read-only overview instead of running
anything (see "Overview").

```yaml
claude: true              # synthesize the canonical claude command (opt-in)
claude_bin: claude        # binary for claude: true (default: claude)
claude_max_turns: 30      # --max-turns for claude: true (default: 30)
claude_permission_mode: bypassPermissions   # (default: bypassPermissions)
prompt: >-                # agent instruction, exposed to the command as $PROMPT
  Use the karr-coordinator skill: pick the next actionable task and move it.
# command: claude -p "$PROMPT"   # explicit command; wins over claude: true
on_idle: skip             # 'skip' (default) | 'always-run'
drain: true               # loop until drained (default) | false for single run
max_runtime: 1800         # seconds: per-command SIGKILL (0 = no timeout)
max_attempts: 2           # stalls on one task before auto-block (default: 2)
max_iterations: 50        # hard cap on drain iterations / drain budget (default: 50)
cooldown_base: 1          # cooldown minutes at level 0 (default: 1)
cooldown_max: 64          # cooldown ceiling in minutes (default: 64)
error_patterns:           # extra case-insensitive substrings → common-error
  - my custom api error
```

`claude`, `claude_bin`, the `claude_*` knobs, `command` and `prompt` may also be
set globally in `config.yml` (`default_command` / `default_prompt`); the per-repo
`.karr` value wins.

## Overview

`karr-foundation --status` (and the default when no board has an agent) prints a
read-only dashboard of every board: status counts, in-progress/blocked tasks,
and lock/cooldown state. No agent is run — usable by a human to coordinate work.

## Options

```bash
karr-foundation --config PATH       # custom config file
karr-foundation --force             # run even if no board change / open tasks
karr-foundation --dry-run --verbose # preview without executing
karr-foundation --status            # read-only overview of every board, no runs
```

Agent output streams to the terminal when run interactively (TTY) or with
`--verbose`, and is always appended to `.karr.log`.

## Drain loop semantics

Each iteration runs `command` once, then classifies result:

| Outcome | Meaning | Action |
|---------|---------|--------|
| **progress** | board changed | keep draining |
| **stall** | task claimed but didn't move | bump attempt counter; auto-block after `max_attempts` |
| **common-error** | bad exit, timeout, or error pattern | exponential backoff, no task penalty |
| **idle** | agent did nothing, grabbed nothing | stop |

### Auto-block

When a task is stuck after `max_attempts`, foundation marks it blocked with:
```
blocked: auto-block: no progress after N attempts (foundation)
```
Agent can override with `karr edit --block "reason"`.

### Exponential cooldown

On common-error: repo waits `cooldown_base × 2^level` minutes (capped at `cooldown_max`).
Level resets on next clean (non-error) run.

## State files (gitignored)

```
.karr.state    # board hash, per-task attempts, cooldown, last error
.karr.lock    # PID lock (prevents concurrent runs)
.karr.log     # run log
```

## Environment

During agent execution foundation sets:

- `KARR_REPO` — the repo path
- `KARR_ROLE=agent` — so nested `karr` calls log under the `agent` identity
  (`refs/karr/log/agent/<email>`); a human defaults to `user`
- `PROMPT` — the resolved agent instruction (`prompt` / `default_prompt` /
  built-in default), referenced as `$PROMPT` in the command template

## Cron example

```bash
# Every 5 minutes, all repos
*/5 * * * * karr-foundation

# With verbose logging to syslog
*/5 * * * * karr-foundation --verbose 2>&1 | logger -t karr-foundation
```

## For dbio-dev repos

Each dbio-* repo needs a `.karr` file with a command that invokes claude on the
next available task. Example:

```yaml
command: claude -p "Use karr CLI to pick next task, implement it fully, hand off or close"
on_idle: skip
drain: true
max_runtime: 900
max_attempts: 2
cooldown_base: 2
cooldown_max: 32
```

To initialize karr in a dbio repo:
```bash
cd /path/to/dbio-postgresql
karr init --name dbio-postgresql
karr create "Example task" --priority high
```

Then add the `.karr` file and configure foundation to scan the parent dir.