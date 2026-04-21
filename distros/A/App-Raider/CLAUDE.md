# CLAUDE.md

**MANDATORY: load `perl-core` skill before editing any Perl code.**

For `dist.ini` or release tasks: load `perl-release-author-getty`.
For `Langertha` internals or engine/raider patterns: load `perl-ai-langertha`.

## What this is

`App::Raider` is the CLI agent distribution — wraps `Langertha::Raider` with a
standard MCP toolbox (filesystem, bash, web) and ships the `raider` CLI binary.

## Key files

| Path | Role |
|------|------|
| `lib/App/Raider.pm` | Core class: engine selection, model, skill loading, mission building |
| `bin/raider` | CLI front-end: REPL, slash commands, banner, JSON mode |
| `lib/App/Raider/FileTools.pm` | MCP server: list_files / read_file / write_file / edit_file |
| `lib/App/Raider/WebTools.pm` | MCP server: web_search / web_fetch |
| `lib/App/Raider/Plugin/Trace.pm` | Live ANSI progress output, token stats |
| `lib/App/Raider/Plugin/Situation.pm` | Injects situational context into each turn |
| `lib/App/Raider/Skill.pm` | Generates RAIDER-SKILL.md / Claude Code SKILL.md |

## Configuration files (in the user's working directory)

- `.raider.yml` — engine options, model, skills list. Loaded by `_load_yml_options`.
  Supports flat, `default:` block, or per-engine-name block.
- `.raider.md` — persona / mission override appended to the default Langertha prompt.

## Engine / model defaults

`%DEFAULT_MODEL` in `App::Raider` maps engine name → cheap default model.
Engine is auto-detected from `*_API_KEY` env vars (anthropic first).

## REPL slash commands (`bin/raider`)

`/help`, `/clear`, `/metrics`, `/stats`, `/reload`, `/prompt`,
`/skill`, `/skill-claude`, `/model`, `/quit`

## Build system

`[@Author::GETTY]` via Dist::Zilla. Standard commands:

```bash
dzil build
dzil test
dzil release
prove -l t/
```
