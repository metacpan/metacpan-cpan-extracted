# CLAUDE.md

This file provides project guidance for Claude Code and similar coding agents.

## Project Overview

`App::karr` — **Kanban Assignment & Responsibility Registry**

A Perl reimplementation of [kanban-md](https://github.com/antopolskiy/kanban-md), a file-based kanban board designed for multi-agent workflows. The reference implementation is in Go and lives at `../kanban-md/` relative to this workspace.

This is a Dist::Zilla distribution using `[@Author::GETTY]`.

## Reference: kanban-md

The Go implementation at `../kanban-md/` is the feature reference. Key docs:
- `../kanban-md/README.md` — Full command reference and design principles
- `../kanban-md/cmd/` — CLI command implementations
- `../kanban-md/internal/task/` — Task file parsing, validation, consistency
- `../kanban-md/internal/board/` — Board operations, filtering, sorting, picking
- `../kanban-md/internal/config/` — Config schema, migration, defaults

**Goal**: Feature parity with kanban-md, but idiomatic Perl with Moo, MooX::Cmd, MooX::Options.

## Architecture

- `bin/karr` — CLI entry point
- `lib/App/karr.pm` — Main app, MooX::Cmd root
- `lib/App/karr/Cmd/*.pm` — Subcommands (MooX::Cmd default namespace)
- `lib/App/karr/Role/Output.pm` — Role for --json and --compact output options
- `lib/App/karr/Task.pm` — Task object: parse/write Markdown+YAML frontmatter
- `lib/App/karr/Config.pm` — Board config management
- `lib/App/karr/Role/BoardAccess.pm` — Role for board directory discovery

### Board layout on disk

```
karr/
  config.yml
  tasks/
    001-set-up-ci-pipeline.md
    002-fix-login-bug.md
```

Task files use YAML frontmatter + Markdown body, identical format to kanban-md.

## Commands (current / planned)

| Command | Status | kanban-md equivalent |
|---------|--------|---------------------|
| `init` | implemented | `init` |
| `create` | implemented | `create` / `add` |
| `list` | implemented | `list` / `ls` |
| `show` | implemented | `show` |
| `move` | implemented | `move` |
| `edit` | implemented | `edit` |
| `delete` | implemented | `delete` / `rm` |
| `board` | implemented | `board` / `summary` |
| `pick` | implemented | `pick` |
| `archive` | implemented | `archive` |
| `handoff` | implemented | `handoff` |
| `metrics` | TODO | `metrics` |
| `log` | TODO | `log` |
| `config` | implemented | `config` |
| `context` | implemented | `context` |
| `agent-name` | implemented | `agent-name` |
| `skill` | implemented | `skill` |

## Key design decisions

- **MooX::Cmd** for subcommand dispatch (not App::Cmd — lighter, Moo-native)
- **MooX::Options** for CLI option parsing
- **YAML::XS** for frontmatter (fast, correct YAML parsing)
- **Path::Tiny** for all file operations
- **No namespace::clean** in command classes (incompatible with MooX::Options)
- Task file format 100% compatible with kanban-md (interop goal)

## Building and testing

```bash
prove -l t/                    # Run all tests
prove -l t/01-task.t           # Run specific test
dzil test                      # Full Dist::Zilla test
dzil build                     # Build distribution
```

## What still needs building (v1 roadmap)

1. **metrics command** — throughput, lead/cycle time, flow efficiency
2. **log command** — activity log of board mutations
3. **dependency checking** — block tasks with unsatisfied deps from being picked
4. **Self-healing IDs** — detect and repair duplicate IDs, filename/ID mismatches
5. **WIP limit enforcement** — reject moves that would exceed WIP limits
6. **TUI** — interactive terminal board (stretch goal, possibly with Tickit)

## Documentation and release notes

- Keep runtime dependencies in `cpanfile`, not `dist.ini`
- For user-visible changes, add an unreleased entry under `{{$NEXT}}` in `Changes`
- POD follows `[@Author::GETTY]` conventions (inline `=attr`, `=method`, no manual NAME/VERSION/AUTHOR sections)
- `# ABSTRACT:` comment required on every .pm file

## Repository metadata

- Agent and skill material lives under `.claude/`
- Keep this file focused on the repository
