# Verify real harness integration

Subprocess tests prove “payload → output,” not “the harness calls the hook and
passes the context.” An integration test must be constructed so it cannot
accidentally pass without briefing.

## Positive test and control

1. Write a test phrase exclusively into the body of a test skill.
   Neither prompt nor agent description names or reveals the phrase.
2. Ask the declaring agent to produce it from context it already has, without
   reading files or loading the skill.
3. Start the same agent without `briefing.skills` or without
   `# briefing: skills = [...]` as the control. Expected: `UNKNOWN`.
4. Check tool calls and the actual hook exchange. An agent that reads the file
   itself does not prove injection. “Is phrase X in the context?” in the prompt
   reveals the answer and is not a test.
5. For Claude Code, also prove the unmodified `Agent` prompt and test an agent
   with an unknown skill: the `PreToolUse` guard must deny it, while the
   successful spawn receives its briefing only through `additionalContext` at
   `SubagentStart`.

A tempting skill description can cause the control to read the file:
name and description are visible without an injected body.

## Codex: two separate trust decisions

- Plugin hooks run only after hook trust has been granted. Before then, they are
  skipped silently. `codex exec` cannot grant that trust interactively;
  `--dangerously-bypass-hook-trust` is available for an explicitly approved
  integration test.
- The project must be trusted separately; otherwise Codex loads no project roles
  and spawns `default`. Trust in `$HOME` does not cover a separate Git repository
  beneath it. The hook exception does not change this.
- Per run, use `-c 'projects={"<abs path>"={trust_level="trusted"}}'`.
  The dotted form `projects."<path>".trust_level=...` was silently ignored in
  the verified Codex version. The logged `agent_type` distinguishes a wrong
  default agent from failed briefing.
- Always use the real `CODEX_HOME`; pass other test settings through `-c`.
  **Never copy `auth.json` into a second home:** parallel homes with the same
  refresh token can invalidate the login.

## Observability and installed version

`codex exec` discards hook `systemMessage` even with `--json`; the TUI shows it
as a warning. Missing visible output is therefore not evidence of a missing hook.
When instrumentation is necessary, after approval save the actually installed
cache copy and log its stdin/stdout; then restore it.
A marker in the repository alone proves nothing about the installed plugin.
Do not log auth files, environment secrets, or unnecessary project content.

Claude Code can test the checkout with
`claude -p --permission-mode auto --plugin-dir <checkout>`.
Disable a parallel installed briefing copy for this run with
`--settings '{"enabledPlugins":{"briefing@getty":false}}'`,
so the test does not run twice or against the wrong version.
Record the hook path actually loaded and the plugin/harness version;
do not assume a fixed ordering such as “checkout older, installation newer.”
A successful guard or Doctor does not prove `SubagentStart` support in older
harnesses; see the legacy-harness caveat in the [hook contract](hook-contract.md).
New agent files require a new session; Doctor/hook simulations remain possible
without restarting. Do not present such a check as a real spawn.

## Historical evidence, not a current verification claim

The upstream CLAUDE.md recorded the following runs; they were not rerun during
this documentation migration:

- Codex 0.153.4: a differing file name under `agents/team/`, spawning from a
  repository subdirectory, and a `config_file` role produced the phrase;
  the control produced `UNKNOWN`.
- briefing 0.4.0 (before Claude Code migrated to `SubagentStart`): Codex named
  the injected `<skill>` element; a logged SessionStart reported the broken
  declaration. Claude Code found an agent by `name` in a subdirectory, produced
  the phrase without a tool call, and the control produced `UNKNOWN`;
  audit and pre-flight appeared as system messages at that time.
- Claude Code 2.1.318, migration to `SubagentStart` (briefing k5):
  `claude -p --permission-mode auto --plugin-dir <checkout>` with the installed
  copy disabled. A raw probe hook established `agent_type` = agent `name` and
  adoption of `additionalContext` with `additionalContextLimit: 0`.
  With briefing, the declaring agent produced the phrase; its only tool call
  was returning to the requester, with no skill or file loading.
  The identical control without a declaration answered `UNKNOWN`.
  An unknown skill was denied with `PreToolUse:Agent hook error: briefing: agent
  'broken' references unknown skill(s): no-such-skill`.
  The `Agent` prompt arrived unchanged.
  **Limits:** The old prompt rewrite was also not denied in the headless-auto-mode
  run; the AutoModeRefusal originally reported from interactive sessions was
  therefore not reproduced. `claude -p` showed no `SubagentStart`
  `systemMessage` in the stream; audit display in the TUI remained unproven.
- The original Codex comparison logged `SubagentStart` in both runs; only the
  declaring agent knew the phrase.
- A shared `hooks.json` was tested with Claude Code: the additional
  SubagentStart block was accepted, while deliberately broken JSON instead
  produced `Failed to load hooks`.

These findings justify the test strategy. Current platform/harness results
must be rerun; explicitly omit unavailable runs.
