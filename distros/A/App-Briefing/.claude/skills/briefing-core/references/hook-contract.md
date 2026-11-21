# Hook contract for this checkout

Applies to `hooks/briefing-preload`, not unchecked to installed plugin versions.
`main()` routes `SubagentStart` to the shared briefing, `SessionStart` to
pre-flight, and otherwise only `tool_name == "Agent"` to the Claude Code guard.
When invoked as `briefing-doctor` or with `doctor` as its first argument, the same
resolution runs as a CLI. `bin/briefing-doctor` is its executable wrapper.

## Claude Code: PreToolUse guard

```json
{
  "hook_event_name": "PreToolUse", "cwd": "/abs/path", "tool_name": "Agent",
  "permission_mode": "auto",
  "tool_input": { "subagent_type": "my-agent", "prompt": "...", "model": "sonnet" }
}
```

Missing declared skill: `hookSpecificOutput` with
`hookEventName: "PreToolUse"`, `permissionDecision: "deny"`, and
`permissionDecisionReason`. Otherwise exit 0 with empty stdout — even on success.
The guard never changes the call and never emits `updatedInput`.
Auto mode reviews the call before hooks and can deny subsequent changes:
`a hook changed this call's input after auto mode reviewed it`.
Therefore, do not reintroduce the prompt rewrite used through briefing 0.5.x.

## SubagentStart: both harnesses

Claude Code, observed payload in 2.1.318 (without `permission_mode`):

```json
{
  "hook_event_name": "SubagentStart", "cwd": "/abs/path",
  "session_id": "...", "transcript_path": "/home/u/.claude/projects/.../x.jsonl",
  "prompt_id": "...", "agent_id": "...", "agent_type": "my-agent"
}
```

Codex:

```json
{
  "hook_event_name": "SubagentStart", "cwd": "/abs/path",
  "agent_type": "my_agent", "agent_id": "...", "turn_id": "..."
}
```

`spawn_harness` first distinguishes through `transcript_path` (`/.claude/` versus
`/.codex/` or `$CODEX_HOME`), then through Codex's `turn_id`. With no unambiguous
signal, a found Claude Code agent wins; otherwise Codex is used. `agent_type` is
the declared agent name, not necessarily the file name. No matching agent or no
declaration means exit 0 and empty stdout; built-ins without an agent file are
also no-ops.

Success: `hookSpecificOutput.hookEventName: "SubagentStart"` and
`additionalContext` with the complete briefing.
Missing skill: instead, an instruction not to perform the task and to return to
the requester with the error; additionally, `systemMessage`.
Even skills that were already resolvable remain out when an error occurs. This
also applies if, under Claude Code, a skill disappears between the guard and
`SubagentStart`.

Neither harness can stop the spawn at `SubagentStart`. Codex ignores
`continue: false` despite its compatibility parser; a partial briefing is not a
substitute. `additionalContextLimit: 0` in `hooks/hooks.json` and `hooks/codex-hooks.json` prevents Codex
from writing long output to disk and providing only a preview to the model
context (the default is about 2500 tokens).

**Legacy-harness caveat:** Claude Code must support context from `SubagentStart`;
2.1.318 was tested, not the earliest possible version. Older versions without
this support start the agent silently unbriefed: a successful guard injects
nothing and is not a fallback.

## Shared output

On success, `SubagentStart` writes an audit line for the human to `systemMessage`:
`briefing: my-agent ← skill-a, skill-b (N kB)`; warnings follow on further lines.
More than 64 KiB of skill text warns but does not deny.
Each skill is embedded without frontmatter as follows:

```xml
<skill name="skill-a" dir="/abs/path/to/skill-a">
…SKILL.md content…
</skill>
```

`dir` is absolute; only the main text is preloaded. Further files remain
progressively accessible. A skill does not recursively load further
`briefing.skills`.

## SessionStart: both harnesses

```json
{
  "hook_event_name": "SessionStart", "cwd": "/abs/path", "session_id": "...",
  "source": "startup", "transcript_path": "/home/u/.codex/sessions/..."
}
```

Only a top-level `systemMessage` for declarations that do not work, otherwise no
output. Never `hookSpecificOutput`, which would create model context here.
`transcript_path` distinguishes `/.codex/` or `$CODEX_HOME` from `/.claude/`;
without an unambiguous signal, both are checked.
`startup`, `resume`, and a missing `source` are checked; other sources such as
compaction remain silent. Overlong but working briefings are not reported again
here. Doctor, by contrast, shows errors and budget warnings.

## Hook files

Both files run the starter `bin/briefing hook EVENT`
(`pre-tool-use`, `subagent-start`, `session-start`, and `marketplace-notice` as the first
`SessionStart` entry); `additionalContextLimit: 0` on
`SubagentStart` stays in both. `hooks/hooks.json` serves Claude Code: exec form
(`command` plus `args`), `PreToolUse` guard included. Codex ignores `args` and runs the
command text through its shell, so `hooks/codex-hooks.json` (named by
`.codex-plugin/plugin.json`) carries the arguments inside the command and has no
`PreToolUse` entry (the guard is Claude Code only). Codex also resolves
`${CLAUDE_PLUGIN_ROOT}`. On Windows the exec-form entry starts `bin/briefing.exe`
(winlaunch), which runs the Python hook. Without a verified cached binary the starter runs
`hooks/briefing-preload`, so the contract above holds either way; `session-start` is the
only event that may download the binary. Background and native tests:
`winlaunch/README.md`.

`hook marketplace-notice` is a separate SessionStart notice with its own state file,
`~/.claude/.briefing-marketplace-notice`; the read-only and side-effect-free guarantee of
the preload hook is not a claim about it. The binary and the Perl CLI run
`process_notice` (as `briefing notice` does); without a verified cached binary both
starters run the Python notice `hooks/briefing-marketplace-notice`, and without a Python
nothing: no Perl fallback, never the starter's "no fallback" warning. It prints one
top-level `systemMessage` only when `CLAUDE_PLUGIN_ROOT` lies in a marketplace cache
(`.../cache/<marketplace>/...`, after lexical normalization) other than `getty` and the
state file is absent; then it writes that file, and a failed write still prints. Every
other case is silent with exit 0, errors included in the CLI's notice handler, the Python
notice and the POSIX starter; a die before that handler runs still exits 2 (`k21`), and a
bootstrap failure before it recognises the hook exits 1 (`k26`). It reads no payload and
never provisions.
