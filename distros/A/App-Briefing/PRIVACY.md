# Privacy policy

`briefing` is a Claude Code plugin that runs entirely on your local
machine. It collects nothing, transmits nothing, and stores nothing
beyond what you already have on disk.

## What the plugin does

The plugin ships a single `PreToolUse` hook that runs whenever Claude
Code is about to spawn a subagent via the `Agent` tool. On each
invocation the hook:

1. Reads the target subagent's markdown file from your project's
   `.claude/agents/` directory or your user-level `~/.claude/agents/`
   directory.
2. Reads each declared skill's `SKILL.md` file from your project,
   user, or installed plugin cache directories.
3. Writes a modified prompt back to Claude Code via the hook's
   `stdout`. The modified prompt is consumed by Claude Code itself
   and is sent only to the destinations Claude Code already sends
   prompts to (i.e., Anthropic's API, under the same terms you've
   already accepted by using Claude Code).

That's the entire data flow.

## What the plugin does not do

- No network requests. The hook is a stdlib-only Python script with
  no `urllib`, `socket`, or any other I/O beyond reading local files
  and writing to `stdout`/`stderr`.
- No telemetry, analytics, crash reporting, or usage tracking of any
  kind.
- No writes to disk. The hook is read-only against the filesystem.
- No persistence. The hook holds no state between invocations.
- No third-party services, dependencies, or SDKs.

## Data sent to Anthropic

The plugin itself does not send anything to Anthropic. However, by
inlining skill bodies into a subagent's prompt, the plugin causes
the contents of those skill files to be included in the prompt that
Claude Code subsequently sends to Anthropic's API. Treat your
`SKILL.md` files the same way you treat any other prompt content:
do not put secrets in them.

## Source

The hook is ~140 lines of Python and lives at `hooks/briefing-preload`
in this repository. Audit it directly — it is short on purpose.

## Contact

Issues and questions: https://github.com/Getty/briefing/issues
