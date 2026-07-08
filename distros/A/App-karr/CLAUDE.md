# CLAUDE.md

This file provides project guidance for Claude Code and similar coding agents.

## Project Overview

`App::karr` — **Kanban Assignment & Responsibility Registry**

A Perl reimplementation of [kanban-md](https://github.com/antopolskiy/kanban-md), a file-based kanban board designed for multi-agent workflows. The reference implementation is in Go and lives at `../kanban-md/` relative to this workspace.

This is a Dist::Zilla distribution using `[@Author::GETTY]`.

## House rules, agents & coordination

Engineering discipline, the delegation lane, board coordination, and the release policy live in
`.claude/rules/karr-rules.md` — auto-loaded by Claude Code at launch. Don't restate them here.

**Delegate behavior-relevant code instead of editing it yourself** (the rule and rationale are in
the rules file). Agents in this repo (skills force-loaded via `briefing.skills`):

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `karr-worker` (default) |
| Write/extend tests under `t/` | `karr-test-writer` |
| Pre-release audit (Changes, cpanfile, dist.ini, version) | `karr-release-checker` |
| POD (`=attr`/`=method`, `# ABSTRACT`) | `karr-pod-writer` |

**Dogfood:** karr tracks its own work on its own board (`refs/karr/*`). Use `karr list --compact`
/ `karr board` for open work and file bugs found here as tickets. Full surface: skill
`kanban-issues-karr-cli`.

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
- `lib/App/karr/Role/BoardDiscovery.pm` — Role providing git/store/config discovery
- `lib/App/karr/Role/SyncLifecycle.pm` — Role providing sync_before/sync_after with retry
- `lib/App/karr/Role/BoardAccess.pm` — Composes BoardDiscovery + SyncLifecycle + task access
- `lib/App/karr/Task.pm` — Task object: parse/write Markdown+YAML frontmatter
- `lib/App/karr/Config.pm` — Board config management (defaults + helpers)
- `lib/App/karr/SyncGuard.pm` — Push insurance on die/croak
- `lib/App/karr/Git.pm` — Low-level Git operations, all-native via Git::Native (libgit2, no fork/exec)
- `lib/App/karr/BoardStore.pm` — Ref-backed board storage (load_tasks, save_task, effective_config)
- `lib/App/karr/Lock.pm` — Advisory task locking via refs

### Board state (refs-first)

Canonical state lives in `refs/karr/*`. The `tasks/` directory (with its
`config.yml`) is a materialized view, not the source of truth, and is always in
F<.gitignore> — never committed. `karr materialize` writes that file view from
the refs (`BoardStore->materialize_to`) and `karr import --yes` reads it back in
(`serialize_from`) — a bridge for kanban-md interop and grepping files, not a
storage backend.

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
| `log` | implemented | `log` |
| `config` | implemented | `config` |
| `context` | implemented | `context` |
| `agent-name` | implemented | `agent-name` |
| `skill` | implemented | `skill` |
| `materialize` | implemented | — (refs→files bridge) |
| `import` | implemented | — (files→refs bridge) |

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

Live status is on the karr board (`refs/karr/*`); this is the at-a-glance summary.

1. **metrics command** — throughput, lead/cycle time, flow efficiency
2. **dependency checking** — block tasks with unsatisfied deps from being picked
3. **Self-healing IDs** — detect and repair duplicate IDs, filename/ID mismatches
4. **WIP limit enforcement** — reject moves that would exceed WIP limits
5. **TUI** — interactive terminal board (stretch goal, possibly with Tickit)

## Documentation and release notes

- Keep runtime dependencies in `cpanfile`, not `dist.ini`
- For user-visible changes, add an unreleased entry under `{{$NEXT}}` in `Changes`
- POD follows `[@Author::GETTY]` conventions (inline `=attr`, `=method`, no manual NAME/VERSION/AUTHOR sections)
- `# ABSTRACT:` comment required on every .pm file
- Release policy (`dzil release` only with explicit go-ahead) is in `.claude/rules/karr-rules.md`

## Repository metadata

Agent/skill/rule material lives under `.claude/`:
- `rules/karr-rules.md` — house rules, auto-loaded (discipline, delegation, coordination, release)
- `agents/karr-*.md` — the project agent fleet (briefing-aware; skills force-loaded at spawn)
- `skills/` — `kanban-issues-karr-cli` + shared Getty Perl skills (hardlinked via manage-skills; don't rename)

Keep this file focused on the repository; behavioral rules belong in `rules/`, not here.
