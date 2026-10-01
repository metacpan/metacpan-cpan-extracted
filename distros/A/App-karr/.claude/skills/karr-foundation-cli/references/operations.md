# Operations: overview, disable, state files, environment, cron, fleet setup

## Board-level disable

A board can opt out of automated agent runs in **its own karr state**, not in the
local `.karr` file:

```bash
cd /path/to/repo
karr disable --reason "abandoned driver, backlog parked"
karr enable                                  # allow agent runs again
```

The flag is `foundation.enabled` in `refs/karr/config`, so it syncs with the
board — every foundation instance on every machine honours it. That is the
difference to `.karr`, which is local machine state and cannot express "this
board is parked" for the whole fleet.

**Precedence — absolute.** A disabled board is skipped **whole**: the flag is
checked before the agent command is resolved and before the drain decision, so
there is no drain, no auto-block and no agent run. It wins over every source in
the resolution order (references/configuration.md) — `--command`, the config's `default_command`, the
`.karr` `command`, a named `agent`, the assignment, `default_agent`, and
`claude: true` — and
`--force` does **not** override it. A `kind: shell` chain step aimed at a
disabled repo is left `pending` for the same reason. Disabled means disabled.

This closes the gap where a global `default_command` in `config.yml` turned
every discovered board into an agent board with no way for a repo to opt out.
Use it for a repository whose backlog is parked rather than abandoned, so an
automation host that drains every discovered board leaves this one alone.

The same state is readable and writable through `karr config`:

```bash
karr config get foundation.enabled           # -> 0 or 1
karr config set foundation.enabled false     # true/false, yes/no, on/off, 1/0
karr config set foundation.reason "why"
```

`karr disable` without `--reason` clears any previously stored reason. When
every discovered board is disabled (or has no agent), `karr-foundation` falls
back to the overview instead of draining.

## Overview

`karr-foundation --status` (and the default when no board has an agent) prints a
read-only dashboard of every board: status counts, in-progress/blocked tasks,
and disabled/lock/cooldown state. No agent is run — usable by a human to
coordinate work.

```
dbio-informix
  7 tasks  [disabled]
  backlog:5  review:2
  disabled:    abandoned driver, backlog parked
```

`disabled` leads the flag list and the `disabled:` line carries the reason
(`no reason given` when none was stored). The `agent` flag is suppressed for a
disabled board, because that agent will never run there; otherwise it names
which agent (`agent:minimax`, plus ` failing` when that one is unavailable). A
board the assignment routes to nothing runnable right now gets `agent-waiting`
and a `waiting:` line with the reason — it is an agent board whose agents are
down, not a board nobody configured, and the two are fixed by different things.
The boards are followed by an `Agents` block where the local config defines any
(`ok`, or `failing since … next attempt at …`, with `(coordinator)` beside the
one marked as such; `--verbose` adds each one's kind and description) and by the
hub's open questions where there are any.

## Options

```bash
karr-foundation --config PATH       # custom config file
karr-foundation --force             # run even if no board change / open tasks
karr-foundation --dry-run --verbose # preview without executing
karr-foundation --status            # read-only overview of every board, no runs
```

Agent output streams to the terminal when run interactively (TTY) or with
`--verbose`, and is always appended to `.karr.log`.

## State files (gitignored)

```
.karr.state   # board hash, per-task attempts, cooldown, last error, last
              # report, and the hook's fingerprint / rounds / last exit
.karr.lock    # flock'd lock: one agent per repo, however many ticks knock
.karr.log     # run log
```

Agent availability is not among them — it is not per board and does not live in
the repository at all (see references/configuration.md), and neither is the
assignment (see references/coordination-agent.md). Both sit beside `config.yml`.

## Environment

During agent execution foundation sets:

- `KARR_REPO` — the repo path
- `KARR_ROLE` — the identity nested `karr` calls write under: `agent` for an
  agent run (`refs/karr/log/agent/<email>`), `hook` for `on_drained`, `chain`
  for a `kind: shell` chain step, `coordinator` for the coordination agent; a
  human defaults to `user`
- `PROMPT` — the resolved agent instruction (`prompt` / `default_prompt` /
  built-in default), referenced as `$PROMPT` in the command template; in ticket
  mode it ends with the sentence naming the assigned task, for a hook it is
  empty, and for the coordination agent it is that agent's own instruction
  rather than the board's
- `KARR_TASK` — the id of the task a `mode: ticket` run was given, empty in
  every other mode
- `KARR_CLAIM` — the claim name nested `karr` calls default to: the checkout's
  `karr agent-name --unique` (checkout name plus a suffix), minted once per run

## Cron example

```bash
# Every 5 minutes, all repos
*/5 * * * * karr-foundation

# With verbose logging to syslog
*/5 * * * * karr-foundation --verbose 2>&1 | logger -t karr-foundation
```

## Enabling agent runs for a repo fleet

Each repo needs a `.karr` file with a command that invokes an agent on the
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

To initialize karr in a repo:
```bash
cd /path/to/repo
karr init --name my-project
karr create "Example task" --priority high --status todo   # backlog is never picked
```

Then add the `.karr` file and configure foundation to scan the parent dir.

To take a single repo out of a fleet that runs on a global `default_command`,
run `karr disable --reason "why"` in that repo — see "Board-level disable".
