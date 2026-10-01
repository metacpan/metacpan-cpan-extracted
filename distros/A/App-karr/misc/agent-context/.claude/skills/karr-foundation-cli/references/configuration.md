# Configuration: config.yml, .karr, named agents, and concurrency

## Config file

Default: `~/.config/karr-foundation/config.yml`

```yaml
dirs:
  - /path/to/repo1
  - /path/to/repo2

scan:
  - /path/to/parent-dir   # finds direct children with .karr file

concurrent: 4             # boards that may have an agent at once (default: 1)
hub: /path/to/hub-repo    # the repo carrying refs/karr-foundation/* (the chain)
routing: >-               # prose for the coordination agent; karr never parses it
  minimax is cheap and does the routine work. Never hand it a release.
```

## Per-repo .karr file

Place in repo root. All keys optional. Agent execution is opt-in: a board runs
an agent only if one of seven sources names a command, and the first one that
does wins:

```
--command  >  config default_command  >  .karr command  >  .karr agent
           >  the assignment  >  config default_agent  >  claude: true
```

A literal command string is the most specific thing that can be said, a named
agent (see "Named agents") sits below it, and `claude: true` is the oldest and
least specific. The assignment (see references/coordination-agent.md) is the routing
table written for this machine: it is asked only for a board that names no
agent of its own, and it beats `default_agent` because it is per repository
where that is per fleet. A board naming an agent the config does not define is
an error that skips **that board**, not one that silently stops running. With
no agent on any board, `karr-foundation` prints a read-only overview instead of
running anything (see references/operations.md).

```yaml
claude: true              # synthesize the canonical claude command (opt-in)
claude_bin: claude        # binary for claude: true (default: claude)
claude_max_turns: 30      # --max-turns for claude: true (default: 30)
claude_permission_mode: bypassPermissions   # (default: bypassPermissions)
prompt: >-                # agent instruction, exposed to the command as $PROMPT
  Use the karr-coordinator skill: pick the next actionable task and move it.
# command: claude -p "$PROMPT"   # explicit command; wins over claude: true
# agent: minimax          # a named agent from the config's 'agents:' section
on_idle: skip             # 'skip' (default) | 'always-run'
mode: drain               # drain (default) | single | ticket
drain: true               # older spelling of mode: true=drain, false=single
max_runtime: 1800         # seconds: per-run TERM, then KILL 2s later (0 = off)
max_attempts: 2           # stalls on one task before auto-block (default: 2)
max_iterations: 50        # hard cap on drain iterations / drain budget (default: 50)
cooldown_base: 1          # cooldown minutes at level 0 (default: 1)
cooldown_max: 64          # cooldown ceiling in minutes (default: 64)
error_patterns:           # extra case-insensitive substrings → common-error
  - my custom api error
on_drained: ./release-gate.sh   # run when the board has no work left
on_drained_max_runtime: 1800    # seconds for that command (0 = no limit)
on_drained_max_rounds: 3        # see references/drain.md (0 = no cap)
```

`claude`, `claude_bin`, the other `claude_*` knobs, `mode` and the three
`on_drained*` keys may also be set in `config.yml` under the same name;
`command`, `prompt` and `agent` have config-wide spellings of their own
(`default_command`, `default_prompt`, `default_agent`). The per-repo `.karr`
value wins in every case — including `on_drained: ""`, which is how one board
opts out of a fleet-wide hook.

## Named agents

A board has one command; a fleet has several agent commands with different
strengths and different failure modes. `config.yml` names them, a `.karr` picks
one with `agent:`:

```yaml
agents:
  minimax:
    command: claude_with_minimax
    kind: claude-code       # the invocation contract; default: shell
    probe_every: 15m        # retry interval once it stops working
    permission_mode: bypassPermissions    # kind: claude-code only
    max_turns: 30                         #   "     "        "
    allowed_tools: [ Bash, Edit ]         #   "     "        "
    concurrent: 2           # runs of THIS agent at once — see "Concurrency"
    description: >-
      Prose. What this agent is good at, where it is weak, what it costs.
  planner:
    command: claude
    kind: claude-code
    role: coordinator       # the fleet's judgement layer — see below

default_agent: minimax    # for boards whose .karr names none
probe_every: 10m          # fleet-wide default for agents that name none
```

`kind` says what karr may append to `command`. `shell` (the default) is a
complete template karr appends **nothing** to — it cannot know what the thing
at the other end understands. `claude-code` gets `-p "$PROMPT"`,
`--output-format stream-json --verbose --include-partial-messages`, and
`--permission-mode` / `--max-turns` / `--allowed-tools` from the definition;
stream-json rather than plain `json` because karr needs the run's own result
object *and* the live output, and plain `json` prints nothing until the run
ends. The ticket of a `mode: ticket` run is never appended — it travels as
`$PROMPT`'s closing sentence and as `$KARR_TASK`.

`description` is never read by karr. It is carried for the agent that routes
work across the fleet: the thing choosing is a language model and reads prose,
so there are no classes and no enums. `--status --verbose` prints it.

`role` marks the one agent that is the fleet's judgement layer (see
references/coordination-agent.md). `coordinator` is the only value; anything else is a config
error, and two marked definitions are refused rather than guessed between —
"which of these is the judgement layer" has no safe default. `--status` prints
`(coordinator)` beside it.

**Availability.** karr keeps the least it can per agent: `ok`, or `failing`
since a moment with the next attempt due at another. No cost, no tokens, no
quotas — a rate limit and a spent budget look identical from the outside. A
drain ending in `common-error` marks its agent failing; any other outcome says
it works. While an agent is failing, **every** board on it is skipped, and
`--force` does not override that either — the wait is bounded by `probe_every`
and ends by itself. When the next attempt comes round the agent is simply run
again on the work that was waiting: the probe **is** the run, and every
recovery is recorded so a rhythm can be read out later.

Agent definitions are **local and only local** — never board state, never
synced: a command that exists on one machine does not exist on the next, and an
account limit belongs to a person, not to a project. The availability record
lives beside the config that defines them (`agents.state` next to
`config.yml`, so `--config` relocates it), flock'd because every board on the
machine shares it.

## Concurrency

Default: **one board at a time**, which is what this has always been.
Concurrency is opt-in like agent execution itself. Three levels bound what runs
and the **tightest one wins**:

1. `concurrent:` in `config.yml` — the machine ceiling. Protects this box's CPU
   and memory; it is not a quota. Default `1`.
2. `concurrent:` on a named agent definition (the `agents:` section) — the
   operator's estimate of where that agent's session limit sits. It is allowed
   to be wrong: being wrong makes the agent start failing, which parks every
   board on it for one probe interval and lets the fallback take over.
3. `limits:` in the chain header, for the fleet's current plan:

   ```yaml
   limits:
     concurrent: 4
     per_agent:
       minimax: 2
   ```

   The `per_agent` names are agent definition names. One this machine does not
   define is dropped with a `--verbose` note, not refused: agent definitions
   are local and only local.

**One agent per repository, always.** The unit of concurrency is one board, run
by one forked child that owns that board's `.karr.lock` for the length of its
drain. Two agents in one working tree would collide over the index and the
checkout, so concurrency is across repositories and never inside one; anything
else would need a git worktree per agent and is out of scope.

A signal to `karr-foundation` takes every running agent with it: the parent
TERMs its children and each child kills its own agent's process group and
releases its own lock, exactly as a serial run does.

`--dry-run` stays serial whatever the ceiling says.

`hub:` names the one repository of a fleet that carries
`refs/karr-foundation/*`. That namespace is pulled once at the start of a run,
before the chain header is read, so a tick applies the fleet's current limits
and not whatever this machine last happened to fetch. Nothing is pushed back —
this run reads the header and writes no step state.
