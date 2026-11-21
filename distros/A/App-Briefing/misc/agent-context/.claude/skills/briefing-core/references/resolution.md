# Agents, declarations, and skill resolution

Authoritative implementation: `hooks/briefing-preload`; protect behavior with
`tests/test_briefing.py`, `tests/test_briefing_codex.py`, and
`tests/test_briefing_doctor.py`.
Each harness gets its own search locations, not a shared global list.

## Claude Code

Agents: `.claude/agents/` in `cwd`, then in the user's home, recursively for `.md`.
Identity is the frontmatter `name`; the file name is a fallback and fast search path,
not a replacement for a differing `name`. Declare under `briefing.skills`,
as a YAML block or flow list. A top-level `skills:` belongs to the harness.

Bare skills: `<cwd>/.claude/skills` → `~/.claude/skills` → installed plugins.
`plugin:skill` resolves directly through plugin resolution.

- Installation index: `~/.claude/plugins/installed_plugins.json`, not cache globs.
  Old versions and commit hashes remain in the cache; sorting cannot find the live version.
- `installPath` is the plugin root. Project/local entries apply only within their
  `projectPath` and take precedence over user installations.
- `enabledPlugins` is merged per key from user, project, and
  `.claude/settings.local.json`; the later layer wins.
  Only `true` enables a marketplace plugin; absent and `false` disable it.
- `--settings` and managed settings are inaccessible to the hook. A state set
  only there is not resolvable configuration for this hook.
- Skills: `skills/<name>/` and manifest `skills` paths. Each additional path
  denotes one skill or a directory containing skills directly.
  Deeper, undeclared structures are not implicit skills.
- The namespace is the manifest name, not necessarily the directory name.
  This checkout does not yet read additional `skills` from marketplace entries.

## Codex declaration

```toml
name = "my_agent"
description = "..."
# briefing: skills = ["skill-a", "plugin:skill-b"]
developer_instructions = """
This agent's task.
"""
```

The comment line is outside multiline strings. `parse_skills_comment` tracks
their state so example text does not become a declaration.
Codex 0.153 rejects agents with unknown TOML fields (`deny_unknown_fields`),
including `[briefing]`; that is not a free-form metadata namespace. A sidecar
`.toml` under `agents/` would itself be an agent definition.

The legacy table remains readable for older harnesses, with a migration warning.
The comment takes precedence; an existing legacy declaration remains diagnosed.
`parse_skills_toml` imports `tomllib` locally (Python 3.11+), otherwise it uses
the narrow regex fallback for this table and key.

`[[skills.config]]` means visibility to the agent, not preloading.
That independent decision remains unchanged.

## Find Codex agents

Configuration layers: every `.codex/` from `cwd` to the nearest `.git` project
root, then `$CODEX_HOME` (default `~/.codex`), then `/etc/codex`.
Without a found project root, only `cwd` is used as the project layer.

Within each layer, `[agents.<name>] config_file` in `config.toml` takes
precedence; relative paths are relative to the configuration file. Additionally,
all `*.toml` below `agents/` are searched recursively for their `name`.
`<name>.toml` is only a fast search path and is skipped when its `name` differs.
The nearest layer wins. Upstream reference:
`codex-rs/agent-roles/src/{loader,discovery}.rs`.

## Find Codex skills

For each project directory from `cwd` to the nearest `.git`, nearest first:
`.codex/skills` → `.agents/skills`. Then:

1. `$CODEX_HOME/skills`
2. `~/.agents/skills`
3. `$CODEX_HOME/skills/.system`
4. `/etc/codex/skills`

`plugin:skill` is also valid in Codex; verified with `briefing:briefing` in
`codex debug prompt-input`. The typical plugin path is
`$CODEX_HOME/plugins/cache/<marketplace>/<plugin>/<version>/skills/<skill>/`.
This checkout's Codex resolver uses cache globs; do not document index-based
Claude Code resolution as already implemented without verification.
