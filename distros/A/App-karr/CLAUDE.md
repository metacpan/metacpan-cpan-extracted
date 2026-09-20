# CLAUDE.md

This file provides project guidance for Claude Code and similar coding agents.

## Project Overview

`App::karr` — **Kanban Assignment & Responsibility Registry**

A Perl reimplementation of [kanban-md](https://github.com/antopolskiy/kanban-md), a file-based kanban board designed for multi-agent workflows. The reference implementation is in Go and is not part of this workspace.

This is a Dist::Zilla distribution using `[@Author::GETTY]`.

## House rules, agents & coordination

Engineering discipline, the delegation lane, board coordination, and the release policy live in
`.claude/rules/karr-rules.md` — auto-loaded by Claude Code at launch. Don't restate them here.

**Delegate behavior-relevant code instead of editing it yourself** (the rule and rationale are in
the rules file). Agents in this repo (skills force-loaded via `briefing.skills`):

| Task | Agent |
|---|---|
| Task/config semantics, lifecycle, claims, dependencies (`needs`/`CrossBoard`), activity log, ordinary board commands, filtering, rendering | `karr-board-worker` |
| Git transport, refs-backed storage, CAS, locks, sync, encoding, materialize/import/backup/restore | `karr-ref-worker` |
| karr-foundation: discovery, drain loops, per-repo lock/state, cooldown, auto-blocking, `disable`/`enable` | `karr-foundation-worker` |
| Behavior-relevant code spanning those domains, or none of them cleanly | `karr-worker` (generalist fallback) |
| Write/extend tests under `t/` | `karr-test-writer` |
| Pre-release audit (Changes, cpanfile, dist.ini, version) | `karr-release-checker` |
| POD (`=attr`/`=method`, `# ABSTRACT`) | `karr-pod-writer` |

Take the narrowest domain worker that fits; each names the other two in its boundaries section
and hands a misrouted task back rather than solving it from the wrong context.

**Dogfood:** karr tracks its own work on its own board (`refs/karr/*`). Use `karr list --compact`
/ `karr board` for open work and file bugs found here as tickets. Full surface: skill
`kanban-issues-karr-cli`.

## Reference: kanban-md

The Go implementation is the feature reference for the board commands. It is not
checked out here — clone it to `../kanban-md/` when you need to compare
behaviour, then read `README.md` (command reference and design principles),
`cmd/` (CLI commands), `internal/task/` (file parsing, validation, consistency),
`internal/board/` (filtering, sorting, picking) and `internal/config/` (schema,
migration, defaults).

**Goal**: Feature parity with kanban-md for the board itself, but idiomatic Perl
with Moo, MooX::Cmd, MooX::Options. What karr has beyond it — refs-first
storage, cross-board dependencies, `karr-foundation` — has no kanban-md
counterpart and no parity obligation.

## Architecture

- `bin/karr` — CLI entry point
- `lib/App/karr.pm` — Main app, MooX::Cmd root
- `lib/App/karr/Cmd/*.pm` — Subcommands (MooX::Cmd default namespace)
- `lib/App/karr/Role/Output.pm` — Role for the --json output option and the JSON printers
- `lib/App/karr/Role/CompactOutput.pm` — Role for --compact, composed only by the nine commands that render one
- `lib/App/karr/Encoding.pm` — The character/octet boundary: argv, std handles, ref blobs, YAML, JSON
- `lib/App/karr/Role/BoardDiscovery.pm` — Role providing git/store/config discovery
- `lib/App/karr/Role/SyncLifecycle.pm` — Role providing sync_before/sync_after with retry
- `lib/App/karr/Role/BoardAccess.pm` — Composes BoardDiscovery + SyncLifecycle + task access
- `lib/App/karr/Task.pm` — Task object: parse/write Markdown+YAML frontmatter
- `lib/App/karr/Config.pm` — Board config management (defaults + helpers)
- `lib/App/karr/SyncGuard.pm` — Push insurance on die/croak
- `lib/App/karr/Git.pm` — Low-level Git operations; local ops native via Git::Native (libgit2), with a git-CLI fallback for remote transport (ssh-config/ProxyCommand)
- `lib/App/karr/BoardStore.pm` — Ref-backed board storage (load_tasks, save_task, effective_config)
- `lib/App/karr/Lock.pm` — Advisory task locking via refs
- `lib/App/karr/ActivityLog.pm` — Activity log writer; role-qualified identities under `refs/karr/log/*`
- `lib/App/karr/CrossBoard.pm` — Cross-board dependencies: a link from a card here to a card on another board (`BOARD#ID`)
- `lib/App/karr/Error.pm` — Turns internal errors into one clean user-facing line

### karr-foundation (the second entry point)

`bin/karr-foundation` drives agent runs across several boards; `App::karr::Foundation`
is the single-shot daemon, and the subsystem beside it splits as follows:

- `Foundation/Overview.pm` — read-only multi-board status dashboard
- `Foundation/Picker.pm` — ticket selection: the one card a ticket-mode run is about
- `Foundation/Runner.pm` — command execution: fork/pipe/select tee plus run classification
- `Foundation/Agents.pm` — agent definitions, invocation contract, per-agent availability
- `Foundation/State.pm` — per-repo state: lock file, JSON state, cooldown backoff
- `Foundation/Limits.pm` — concurrency limits: machine ceiling, per-agent estimates, chain header
- `Foundation/ChainStore.pm` — chain and run-log storage under `refs/karr-foundation/*`
- `Foundation/Executor.pm` — chain executor: picks a ready step, runs it, writes its state back
- `Foundation/Questions.pm` — question mailbox under `refs/karr-foundation/questions/*`

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
| `dashboard` | implemented | — (configuration-free multi-board overview under a directory) |
| `pick` | implemented | `pick` |
| `unlock` | implemented | — (show and break pick locks) |
| `archive` | implemented | `archive` |
| `handoff` | implemented | `handoff` |
| `needs` | implemented | — (report/resolve cross-board dependencies) |
| `metrics` | implemented | `metrics` |
| `log` | implemented | `log` |
| `config` | implemented | `config` |
| `context` | implemented | `context` |
| `agent-name` | implemented | `agent-name` |
| `skill` | implemented | `skill` |
| `materialize` | implemented | — (refs→files bridge) |
| `import` | implemented | — (files→refs bridge) |
| `repair` | implemented | — (migrates a 0.402-or-earlier board off double-encoded UTF-8) |
| `sync` | implemented | — (explicit refs pull/push) |
| `backup` | implemented | — (board snapshot to YAML) |
| `restore` | implemented | — (snapshot→refs, destructive) |
| `destroy` | implemented | — (remove `refs/karr/*` incl. remote) |
| `set-refs` / `get-refs` | implemented | — (helper refs outside the board) |
| `disable` / `enable` | implemented | — (board-level opt-out from karr-foundation runs) |

## Key design decisions

- **MooX::Cmd** for subcommand dispatch (not App::Cmd — lighter, Moo-native)
- **MooX::Options** for CLI option parsing
- **YAML::XS** for frontmatter (fast, correct YAML parsing)
- **Path::Tiny** for all file operations
- **No namespace::clean** in command classes (incompatible with MooX::Options)
- Task file format 100% compatible with kanban-md (interop goal)
- **Characters inside, octets only at the edges.** Everything between the CLI
  entry point and the Git ref blob is a Perl character string. `App::karr::Encoding`
  owns every crossing — `@ARGV`, STDOUT/STDERR, ref read/write, YAML, JSON — and
  nothing else may `Encode::encode`/`decode`, call `YAML::XS::Dump`/`Load`, or
  `encode_json`/`decode_json` directly. `Path::Tiny`'s `slurp_utf8`/`spew_utf8`
  are already character-level: putting an encode in front of one is a double
  encode. Boards written before this rule are detected via
  `refs/karr/meta/encoding` and repaired on read; `karr repair` migrates them.

## Building and testing

```bash
prove -l t/                    # Run all tests
prove -l t/01-task.t           # Run specific test
dzil test                      # Full Dist::Zilla test
dzil build                     # Build distribution
```

## What still needs building

Open work lives on the karr board (`refs/karr/*`) — `karr list --compact` or
`karr board`. This file deliberately keeps no second copy of it: the summary that
used to stand here dated from the initial commit, was never reconciled with the
board, and by the time anyone noticed, none of its five items existed as a
ticket while it claimed the board held the live status.

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
- `skills/` — seven skills. Five are shared across repositories via manage-skills
  hardlinks (`kanban-issues-karr-cli`, `getty-perl-core`, `getty-perl-moo`,
  `getty-perl-release-author-getty`, `perl-release-dist-ini`); two are local to
  this repository (`karr-foundation-cli`, `perl-file-sharedir`). `ls -li
  .claude/skills/*/SKILL.md` tells them apart by link count. Don't rename them,
  and edit a shared one via `cat > .claude/skills/<skill>/SKILL.md` (its
  `references/*.md` are linked the same way) — **not** the
  `Edit`/`Write` tools or `sed -i`, which mint a new inode and break the shared
  hardlink; see skill `manage-skills`. `kanban-issues-karr-cli` is hardlinked
  file-for-file to `share/kanban-issues-karr-cli/` (what `karr skill install`
  ships: `SKILL.md` plus `references/*.md`), so editing one edits the other —
  as long as the edit keeps the inode. A new file under either directory has to
  be linked into the other by hand: `ln <canonical> <other>` (t/62).

Two more documents carry decisions rather than instructions:
- `CONTEXT.md` — the domain vocabulary (Claim vs. Assignee vs. Lock, Activity
  log, …), including the words to avoid. Read it before naming anything new.
- `docs/adr/` — architecture decision records: refs-first storage, the exit-code
  contract, role-qualified log identity, foundation as a coordinator, board-level
  disable. Read the relevant one before changing the shape it describes.

Keep this file focused on the repository; behavioral rules belong in `rules/`, not here.
