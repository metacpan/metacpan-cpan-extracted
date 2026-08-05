# Board-level disable lives in board state and is absolute

A board can opt out of automated agent runs through `foundation.enabled` in
`refs/karr/config`, written by `karr disable [--reason "why"]` and cleared by
`karr enable`. Two properties are deliberate:

- **It is board state, not machine state.** The flag sits in the karr refs and
  syncs with the board, so every `karr-foundation` instance on every machine
  honours it. The per-repo `.karr` file cannot express this: it is local
  machine state and would have to be recreated on each host that discovers the
  repo.
- **It is absolute.** Foundation checks the flag before it resolves the agent
  command and before it decides whether to drain, so a disabled board is
  skipped whole — no drain, no auto-block, no agent run. It therefore wins over
  `karr-foundation --command`, the config's `default_command`, the `.karr`
  `command` and `claude: true`. `--force` does **not** override it.

The gap this closes: with a global `default_command` in
`~/.config/karr-foundation/config.yml`, *every* discovered board became an agent
board and a repository had no way to opt out. The motivating case is a parked
backlog — an abandoned project kept for reference, with backlog and review tasks
that look actionable but must never be drained or auto-blocked.

## Considered Options

- **A key in the per-repo `.karr` file** — rejected: `.karr` is local machine
  state (it sits next to `.karr.state` / `.karr.lock` / `.karr.log`, all
  gitignored). "This board is parked" is a fact about the board, and every host
  that discovers the repo must learn it without manual setup.
- **`--force` overrides the flag** — rejected: it re-creates the problem one
  level up. An automation host that runs with `--force` (a common cron shape,
  to run regardless of board change) would drain every disabled board anyway.
  Disabled means disabled; a human who wants a run does `karr enable`.
- **`karr config set foundation.enabled false` as the only front door** —
  rejected as the *primary* surface, kept as an equivalent one. Disabling is a
  two-field operation (flag plus reason) and a bare `"false"` from the command
  line is true in Perl. `karr disable --reason` sets both atomically;
  `App::karr::Config::parse_bool` coerces the `config set` path so both write
  the same 1/0. There is one truth in `refs/karr/config`.

## Consequences

Foundation re-checks the flag after `_sync_pull`, not only before it: a board
disabled on another machine would otherwise be drained exactly once by each
host that decided to run before pulling. The cost is one extra ref read per
repo per tick.

Because `foundation.enabled` defaults to `1` in `App::karr::Config`'s
`default_config`, re-enabling drops the whole `foundation` key from the sparse
overrides again — an enabled board is indistinguishable from one that never
touched the flag.

Disabled boards are excluded from foundation's "does any board have an agent?"
check, so a configuration consisting only of disabled boards falls back to the
read-only Overview rather than attempting a drain.
