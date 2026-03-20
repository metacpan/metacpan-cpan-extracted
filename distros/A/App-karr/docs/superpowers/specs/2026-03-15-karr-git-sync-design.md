# karr Git Sync Design

Date: 2026-03-15

## Overview

Add Git-based sync to karr for multi-agent collaboration. Agents can work on the same board, see each other's changes, and coordinate via locks and messages.

## Goals

- Share karr board state across multiple agents/repos
- Real-time-ish feedback when others block or claim tasks
- Support for external repos (GitHub Issues, other karr boards)
- Lock mechanism to prevent conflicts

## Architecture

### Git Ref Structure

```
refs/karr/tasks/<id>         # Task metadata (YAML blob)
refs/karr/tasks/<id>/lock   # Lock file (contains username)
refs/karr/external/<name>    # External repo references
```

**Task Metadata (YAML):**
```yaml
---
id: 1
title: "Fix login bug"
status: in-progress
claimed_by: agent-fox
priority: high
blocked_by: "waiting on API"
external:
  - type: github
    repo: owner/repo
    issue: 42
messages:
  - author: agent-fox
    text: "Ich arbeite dran"
    timestamp: 2026-03-15T10:00:00Z
  - author: agent-owl
    text: "Kann ich übernehmen?"
    timestamp: 2026-03-15T11:00:00Z
---
```

### Lock Mechanism

1. Read `refs/karr/tasks/<id>/lock`
2. If empty or contains my name → proceed
3. If contains other name → show error/wait
4. After changes → clear lock

### Sync Flow

**Auto-sync (default on every write):**
1. Acquire lock
2. Fetch remote refs/karr/
3. Merge if needed (or show conflicts)
4. Apply local changes
5. Push refs/karr/
6. Release lock

### External Repos

`refs/karr/external/<name>` contains:
```yaml
---
type: github
url: https://github.com/owner/repo
token: $GITHUB_TOKEN  # or use gh CLI
---
```

karr can fetch and display external issues alongside local tasks.

## Commands

| Command | Description |
|---------|-------------|
| `karr sync` | Full sync (push + pull) |
| `karr sync --push` | Push only |
| `karr sync --pull` | Pull only |
| `karr sync --watch` | Background daemon, polls regularly |
| `karr sync --wait` | Block until remote changes |
| `--no-sync` | Skip sync for a command |

**Defaults:**
- Every write command (create, move, edit) does auto-sync by default
- Use `--no-sync` to work locally without syncing

## Data Flow

```
Local Change → Update Task File → Update refs/karr/tasks/<id> → Push → Release Lock
```

## Implementation Notes

- Use Git::Raw or IPC::Git for Git operations
- Lock timeout: configurable (default 5 min), auto-expire
- Poll interval: configurable (default 30s), in .karr.yml
- Conflict resolution: show diff, let user decide

## Files to Modify/Create

- `lib/App/karr/Sync.pm` — Core sync logic
- `lib/App/karr/Cmd/Sync.pm` — Sync command
- `lib/App/karr/Lock.pm` — Lock management
- `lib/App/karr/External.pm` — External repo integration
