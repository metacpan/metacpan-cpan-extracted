# Foundation is a multi-board coordinator, not an agent runner

`karr-foundation` is framed as a multi-board *coordinator* with two first-class
users — a human coordinating their own work and an AI agent driving tasks — not
as an agent-execution daemon. Consequences:

- **Agent execution is opt-in.** A repo runs an agent only via an explicit
  `command:` or the `claude: true` shorthand. With nothing configured,
  foundation does *not* warn-and-skip; its default action is the read-only
  **Overview** dashboard. A human can use foundation purely to see what is
  happening across boards, with no AI involved.
- **`claude: true` synthesizes the canonical invocation.** Rather than make
  users memorize the long `claude` command, `claude: true` makes foundation
  build it (`<claude_bin> -p "$PROMPT" --permission-mode bypassPermissions
  --max-turns N`, knobs overridable; `claude_bin` defaults to `claude`). An
  explicit `command:` still wins for full control.

## Considered Options

- **Agent-runner only** (status quo: no command → warn + skip) — rejected:
  excludes the human-coordinator use case and makes the bare invocation useless.
- **Raw `command:` string only** — kept as the power-user path, but `claude:
  true` is added because the canonical invocation is long and error-prone to
  retype per repo.

## Consequences

Foundation owns the canonical `claude` flag set, so it must track meaningful
changes to the `claude` CLI. The Overview is read-only and never mutates a
board or fires an agent, making the zero-config default safe to run anywhere.
