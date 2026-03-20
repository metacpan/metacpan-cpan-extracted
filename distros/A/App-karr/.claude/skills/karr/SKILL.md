---
name: karr
description: "karr CLI — Kanban Assignment & Responsibility Registry. Command reference, decision trees, and workflows for managing kanban tasks via the karr CLI tool."
user-invocable: true
---

# karr — Kanban Assignment & Responsibility Registry

File-based kanban board for multi-agent workflows. Tasks are Markdown files with YAML frontmatter in `karr/tasks/`. Board config in `karr/config.yml`.

## Commands

### Initialize

```bash
karr init [--name NAME] [--statuses s1,s2,s3] [--claude-skill]
```

Creates `karr/` directory with `config.yml` and `tasks/`. Adds `karr/` to `.gitignore`. With `--claude-skill`, installs this skill to `.claude/skills/karr/SKILL.md`.

### Create task

```bash
karr create "Title" [--status STATUS] [--priority PRIORITY] [--tags t1,t2] [--body TEXT]
karr create --title "Title" --assignee NAME --due 2026-03-15
```

### List tasks

```bash
karr list                                    # all non-archived
karr list --status todo,in-progress          # filter by status
karr list --priority high,critical           # filter by priority
karr list --tag backend                      # filter by tag
karr list -s "search term"                   # search title/body/tags
karr list --sort priority --reverse          # sort and reverse
karr list --compact                          # one-line output (agent-friendly)
karr list --json                             # JSON output
```

### Show task

```bash
karr show ID
```

### Move task

```bash
karr move ID STATUS                          # move to specific status
karr move ID --next                          # advance one status
karr move ID --prev                          # go back one status
karr move ID in-progress --claim agent-1     # move and claim
```

### Edit task

```bash
karr edit ID --title "New title"
karr edit ID --priority high --add-tag urgent
karr edit ID --body "New description"
karr edit ID -a "Appended note"              # append to body
karr edit ID --claim agent-1                 # claim
karr edit ID --release                       # release claim
karr edit ID --block "Waiting on API"        # mark blocked
karr edit ID --unblock                       # clear blocked
```

### Delete task

```bash
karr delete ID --yes                         # skip confirmation
```

### Archive task

```bash
karr archive ID                              # soft-delete (move to archived)
```

Idempotent — archiving an already-archived task is a no-op.

### Board summary

```bash
karr board
```

Shows tasks grouped by status with WIP utilization.

### Pick next task (multi-agent)

```bash
karr pick --claim agent-1                    # pick highest priority available
karr pick --claim agent-1 --status todo --move in-progress
karr pick --claim agent-1 --tags backend
```

Atomically finds and claims the next available task. Respects claim timeouts, blocked state, and class-of-service priority ordering (expedite > fixed-date > standard > intangible).

### Handoff task for review

```bash
karr handoff ID --claim agent-1              # move to review, refresh claim
karr handoff ID --claim agent-1 --note "Done, needs QA" --timestamp
karr handoff ID --claim agent-1 --block "waiting for feedback" --release
```

Moves task to `review`, refreshes claim, optionally appends a timestamped note, blocks, or releases the claim.

### Config

```bash
karr config                                  # show all config values
karr config get KEY                          # get a single value
karr config set KEY VALUE                    # set a writable value
karr config --json                           # JSON output
```

Writable keys: `board.name`, `board.description`, `defaults.status`, `defaults.priority`, `defaults.class`, `claim_timeout`.

### Context (board summary for embedding)

```bash
karr context                                 # print markdown summary
karr context --write-to AGENTS.md            # create/update file with sentinels
karr context --sections blocked,overdue      # filter sections
karr context --days 14                       # lookback for recently-completed
karr context --json                          # JSON output
```

Generates a markdown summary with sections: In Progress, Blocked, Overdue, Recently Completed. Uses `<!-- BEGIN kanban-md context -->` / `<!-- END kanban-md context -->` sentinels for in-place updates.

### Skill management

```bash
karr skill install                           # install skill for detected agents
karr skill install --agent claude-code       # install for specific agent
karr skill install --global                  # install globally (~/)
karr skill install --force                   # force reinstall
karr skill check                             # check if installed skills are current
karr skill update                            # update outdated skills
karr skill show                              # print skill content to stdout
```

Supported agents: `claude-code`, `codex`, `cursor`.

### Agent name

```bash
karr agentname                               # generate random two-word name
karr pick --claim $(karr agentname) --move in-progress
```

## Task file format

```markdown
---
id: 1
title: Set up CI pipeline
status: backlog
priority: high
class: standard
created: 2026-03-12T10:00:00Z
updated: 2026-03-12T10:00:00Z
tags:
  - devops
---

Optional body with more detail.
```

## Config (karr/config.yml)

```yaml
version: 1
board:
  name: My Project
tasks_dir: tasks
statuses:
  - backlog
  - todo
  - name: in-progress
    require_claim: true
  - name: review
    require_claim: true
  - done
  - archived
priorities: [low, medium, high, critical]
wip_limits:
  in-progress: 3
  review: 2
claim_timeout: 1h
defaults:
  status: backlog
  priority: medium
  class: standard
next_id: 1
```

## Decision tree: which command?

1. **Need a board?** → `karr init`
2. **New work item?** → `karr create "Title" --priority high`
3. **What's on the board?** → `karr board` or `karr list`
4. **Starting work?** → `karr pick --claim NAME --move in-progress`
5. **Done with task, hand to review?** → `karr handoff ID --claim NAME --note "reason"`
6. **Done with task, close it?** → `karr edit ID --release && karr move ID done`
7. **Blocked?** → `karr edit ID --block "reason"`
8. **Need details?** → `karr show ID`
9. **Soft-delete?** → `karr archive ID`
10. **Board snapshot for agent context?** → `karr context --write-to AGENTS.md`
11. **Check/change config?** → `karr config` / `karr config set KEY VALUE`
12. **Install agent skills?** → `karr skill install`

## Multi-agent workflow

```bash
# 1. Generate agent name and pick task
NAME=$(karr agentname)
karr pick --claim $NAME --status todo --move in-progress

# 2. Work on task...

# 3. Hand off for review
karr handoff ID --claim $NAME --note "Implementation complete" --timestamp

# 4. Or: release and mark done directly
karr edit ID --release
karr move ID done
```

Claims expire after the configured timeout (default: 1h). Statuses with `require_claim: true` enforce that moves include `--claim`.
