---
name: claude-headless
description: "Use when running Claude Code headless — claude -p, JSON output, claude calling claude, or a nested run that hangs, denies a tool or picks the wrong model."
---

# Headless Claude Code

`claude -p "<prompt>"` runs one non-interactive turn-loop and exits. Calling it
from inside a running Claude Code session works — no environment cleanup
needed. Facts below verified against claude 2.1.261; when a flag misbehaves,
`claude --help` is the authority for the installed version.

## Matching the parent's model

A child does **not** inherit the parent session's model — it reads the saved
user default (`~/.claude/settings.json`, key `model`; this is where `/model`
saves). To guarantee the same model, pass it explicitly and verify:

1. The system prompt's environment block states the exact model ID — e.g.
   `MiniMax-M3-512k`, or `claude-opus-5-5` when on Claude. No environment
   variable carries it.
2. Pass `--model <exact-id>` using that **exact string**, verbatim. Do not
   substitute an Anthropic-family alias (`fable`, `opus`, `sonnet`, `haiku`)
   when the parent is on a different provider; those aliases resolve inside
   the Anthropic namespace only, and would silently swap the model.
3. Verify from the output: with `--output-format json`, the `modelUsage`
   object is keyed by the model ID that actually ran — assert it is the one
   you asked for.

```bash
claude -p "Reply with exactly one word: PONG" \
  --model MiniMax-M3-512k --output-format json \
  | jq -er '.result, (.modelUsage | keys[0])'
```

**Default to the model you're already on.** `fable` / `claude-fable-5-1`
is the most expensive slot in the Anthropic lineup and currently no better
than `opus` (5.5) on most work — a one-shot `-p` call on `fable` writes a
fresh cache before it even answers. Try `opus` at higher effort first;
escalate to `fable` only when that falls short. Otherwise let the parent's
tier stand.

The system prompt's "alternative models" list (typically the recent Claude
family plus Haiku) is the switch menu — your current model is often *not*
on that list when it belongs to another provider. Pick the cheapest tier
appropriate for the task; per-token pricing varies by provider, so use that
provider's rate card, not Claude's.

## JSON output

`--output-format json` (requires `-p`) returns one object; the fields that
matter: `result` (the final text), `is_error`, `session_id` (feed to
`--resume`), `total_cost_usd`, `num_turns`, `stop_reason`, `modelUsage`,
`usage` (token detail), `permission_denials`. `--output-format stream-json`
emits events as they happen and additionally requires `--verbose`;
`--json-schema <schema>` forces structured output.

## Permissions — decide before launch

A one-shot print run cannot ask. An unapproved tool call is denied (see
`permission_denials`), so the run limps or stops instead of prompting. Choose
one:

- `--allowedTools "Bash(git *),Read,Edit"` — pre-approve exactly what the task
  needs (permission-rule syntax; the deny syntax is `--disallowedTools`).
- `--permission-mode <mode>` — `auto`, `dontAsk`, `acceptEdits`, `plan`,
  `bypassPermissions`.
- `--dangerously-skip-permissions` (= `bypassPermissions`) — only inside an
  isolated environment (container, throwaway VM), never on a working checkout
  you care about.

## Staying in the conversation

The single turn is a choice, not a limit. `--input-format stream-json` keeps
stdin open, so one process takes several turns and remembers the earlier ones:

```python
p = subprocess.Popen(
    ["claude","-p","--input-format","stream-json","--output-format","stream-json",
     "--verbose","--replay-user-messages","--model","claude-haiku-4-5-20251001"],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1)

def say(text):                       # one message in
    p.stdin.write(json.dumps({"type":"user","message":{"role":"user",
        "content":[{"type":"text","text":text}]}}) + "\n")
    p.stdin.flush()                  # read stdout until type == "result"
```

`--replay-user-messages` echoes each message back so the driver knows it
landed; closing stdin ends the run. `--include-partial-messages` streams
chunks as they arrive, `--forward-subagent-text` surfaces what its subagents
say. Both need `--output-format stream-json`.

This is also the one way a print run can *ask*: point
`--permission-prompt-tool` at an MCP tool of your own and every tool decision
comes to the driver as a question instead of being silently denied.

Because the channel is a pipe, it survives ssh — and that is how you drive an
agent on a host whose Claude is somebody else's login:

```bash
ssh -T host 'export PATH=$HOME/.local/bin:$PATH; cd /srv/project; exec claude -p \
  --input-format stream-json --output-format stream-json --verbose'
```

Write the same JSON lines into ssh's stdin. Use `-T` (no tty) and `exec` so the
remote claude owns the connection's stdio and its signals. Verified across
hosts: turn two still knew what turn one had been told. Nothing is shared but
the ssh session — no account, no Remote Control.

## The child is a peer

A `-p` child is a full session, not an isolated command. It appears in
`claude agents --json` — as `kind: interactive`, named after its directory
(`p5-alien-libgit2-13`) — and it can call `ListAgents` and `SendMessage` to
reach the session that started it and every other session on the machine.
So a headless run does not have to report only through its exit JSON; it can
talk back while it works, and you can talk to it. See `claude-cross-session`.

## What the child inherits

Settings resolve against the **child's cwd**, not the parent's session:
managed → user (`~/.claude/settings.json`) → project (`.claude/settings.json`)
→ local (`.claude/settings.local.json`), plus the cwd's `CLAUDE.md`, skills,
agents, and hooks. Consequences:

- Run the child in the directory whose context it should have; `cd` is the
  main inheritance lever.
- `--setting-sources user,project,local` narrows which scopes load;
  `--settings <file-or-json>` injects overrides; `--bare` skips hooks,
  plugins, MCP, and CLAUDE.md discovery entirely — pass what it needs
  explicitly (`--append-system-prompt`, `--mcp-config`, `--agents`).
- Session-scoped state of the parent (its model, its conversation) never
  transfers; context the child needs goes into the prompt, the system-prompt
  flags, or files it can read.

## Guard rails and follow-ups

- `--max-turns <n>` and `--max-budget-usd <amount>` bound a runaway child.
- `session_id` from the JSON + `claude -p --resume <session-id> "<next>"`
  continues that conversation; `--continue` takes the most recent one.
  `--session-id <uuid>` picks the id up front. `--no-session-persistence`
  for fire-and-forget runs.
- Background Bash commands the child starts are killed ~5 s after its final
  result — a headless run must finish its work in the foreground.
- Inside any Claude Code Bash call, `CLAUDECODE=1` and
  `CLAUDE_CODE_SESSION_ID` are set — a script can detect it is being run *by*
  Claude and avoid spawning recursively by accident.

## Related

- `claude-cross-session` — when you do not want a result but a counterpart:
  starting a session elsewhere with `claude --bg` and talking to it while it
  runs.
- `getty-agent-team` — subagents *within* a session (briefing-preloaded);
  reach for headless spawning only when a separate process is genuinely
  needed: clean context, different cwd, CI, or another program driving Claude.
