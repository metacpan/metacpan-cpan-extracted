---
name: kanban-issues-karr-cli
description: Use when picking up, claiming, handing off or creating agent tickets with the karr CLI, or when reading a repo's karr board.
---

# karr — Kanban Assignment & Responsibility Registry

Git-native kanban board for multi-agent workflows. Canonical board state lives in
`refs/karr/*`, not in a checked-in `karr/` directory. Commands materialize a
temporary task/config view only while they run.

## Commands

### Initialize

```bash
karr init [--name NAME] [--statuses s1,s2,s3] [--claude-skill] [--new-board]
```

Creates the board refs inside the current Git repository. With
`--claude-skill`, installs this skill to `.claude/skills/karr/SKILL.md`.

Before it writes anything, init asks the remote whether this repository already
has a board there: `git clone` does not fetch `refs/karr/*`, so a fresh clone
looks exactly like a repository that never had one. A remote that advertises
`refs/karr/*` means the board exists and is one `karr sync` away, so init
refuses and says so rather than starting a second board beside it. Every other
answer -- no remote, an unreachable one, no answer inside the probe budget --
lets init through, because it has to work offline. Use `--new-board` only when
a clone is really meant to keep its own, independent board: the two will not
sync with each other, and the board-identity guard is what stops them.

### Create task

```bash
karr create "Title" [--status STATUS] [--priority PRIORITY] [--tags t1,t2] [--body TEXT]
karr create --title "Title" --assignee NAME --due 2026-03-15
karr create "Ship it" --depends-on 2,3       # ids of tasks this one depends on; each must exist on this board
karr create "Wait for the fix" --needs other-repo#7   # waits on a card in ANOTHER repository of the fleet
karr create "Fix the thing" --escalated-from home#5   # the card raised in that other repository
```

### List tasks

```bash
karr list                                    # all non-archived
karr list --status todo,in-progress          # filter by status
karr list --priority high,critical           # filter by priority
karr list --tag backend                      # filter by tag
karr list -s "search term"                   # search title/body/tags
karr list --sort priority --reverse          # sort and reverse
karr list --claimed-by agent-1               # filter by claim owner
karr list --compact                          # one-line output (agent-friendly)
karr list --json                             # JSON output
```

### Show task

```bash
karr show ID
karr show                  # most recently updated task
karr show --last 5         # the 5 most recent
karr show --me             # the task you most recently acted on (re-orient)
karr show --agent NAME     # the task most recently claimed by NAME
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
karr edit ID --add-depends-on 2,3            # append dependency ids (no duplicates; ids must exist, no self-reference)
karr edit ID --remove-depends-on 4           # absent ids are a no-op (cleanup after a deleted dependency)
karr edit ID --add-needs other-repo#7        # append a cross-board dependency (see below)
karr edit ID --remove-needs other-repo#7     # absent references are a no-op
karr edit ID --body "New description"
karr edit ID -a "Appended note"              # append to body
karr edit ID --claim agent-1                 # claim
karr edit ID --release                       # release claim
karr edit ID --block "Waiting on API"        # mark blocked
karr edit ID --unblock                       # clear blocked
```

An unknown or non-numeric id given to `--depends-on`/`--add-depends-on` rejects
the whole invocation before anything is written (usage error, exit 2); a
self-reference (`karr edit 5 --add-depends-on 5`) fails only that id, the rest
of the batch proceeds, and the command exits 1. Taking up a card whose
dependencies are unfinished warns on move/pick but is never blocked.

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

### Unlock a stuck task

```bash
karr unlock                                  # list the pick locks currently held
karr unlock ID                               # break one
karr unlock --all                            # break all of them
```

`karr pick` takes a lock ref and gives it back inside the same command, so normally there is nothing here to see. An agent that dies mid-pick leaves one behind. Locks expire on their own after `lock_timeout` (default `5m`, board config); this is how you look at what is stuck and clear it now instead of waiting.

### Handoff task for review

```bash
karr handoff ID --claim agent-1              # move to review, refresh claim
karr handoff ID --claim agent-1 --note "Done, needs QA" --timestamp
karr handoff ID --claim agent-1 --block "waiting for feedback" --release
```

Moves the task to the board's review column, refreshes the claim, and optionally appends a timestamped note, blocks, or releases the claim. On a board that configures a `review` status that is the target; a board without one hands off to its last non-terminal column instead of failing.

### Cross-board dependencies

`--depends-on` is board-local. When work here cannot proceed until something is
fixed in *another repository*, that link is a cross-board dependency:

```bash
# in the other repository -- raise the card and record where it came from
karr create "Fix the API" --escalated-from home#5

# here -- record what you are waiting for, block, release the claim, leave
karr edit 5 --add-needs other-repo#7 --block "needs other-repo#7: API change first" --release

# any time -- what is this board waiting on, and is it done yet?
karr needs
karr needs --board other-repo=/srv/other-repo     # where that board is on THIS machine
karr needs --resolve                              # drop settled links, unblock what is free
```

A reference is `BOARD#ID`: the other board's **name** and a task id. Never a
path -- the card is shared state and two clones of the same fleet have
different directories. karr turns the name into a directory from
`--board NAME=PATH` or from the fleet config
(`~/.config/karr-foundation/config.yml`, `--fleet-config` to point elsewhere),
matching the repository's directory basename.

`--resolve` settles a link whose far card has reached one of the **far** board's
own terminal statuses, and lifts the `blocked` flag when a card's last link
settles, printing the reason it lifted. A far card that does not exist settles
nothing. A board this machine cannot place is reported, not fatal.

Like `depends_on`, a cross-board link blocks nothing by itself: `pick` hands the
card over and says what it waits on. The `blocked` flag is what keeps the card
out of `pick` and out of karr-foundation's selection -- the link is the fact,
`blocked` is the decision.

### Config

```bash
karr config                                  # show all config values
karr config get KEY                          # get a single value
karr config set KEY VALUE                    # set a writable value
karr config show --defaults                  # karr's defaults, no board read
karr config --json                           # JSON output
```

Writable keys: `board.name`, `board.description`, `defaults.status`, `defaults.priority`, `defaults.class`, `claim_timeout`, `lock_timeout`, `foundation.enabled`, `foundation.reason`.

`show` and `get` read this board and refuse with exit 1 when there is none —
they never fall back to the built-in defaults, which is how a fresh clone used
to answer `board.name: Kanban Board` for a board that has a name. Ask for those
defaults explicitly with `--defaults`: it reads no board (and needs no
repository), so `diff <(karr config show) <(karr config show --defaults)` is
exactly what this board overrides.

### Disable / enable automated agent runs

```bash
karr disable                                 # no automated agent runs here
karr disable --reason "abandoned driver, backlog parked"
karr enable                                  # allow them again
karr disable --json                          # {"foundation":{"enabled":0,"reason":"…"}}
```

Board-level opt-out from `karr-foundation`. Unlike the per-machine `.karr` file
the flag is board state (`foundation.enabled` in `refs/karr/config`), so it syncs
with the board and every foundation instance on every machine honours it. A
disabled board is skipped whole: no drain, no auto-block, no agent run — the
flag wins over `karr-foundation --command`, the config's `default_command`, the
`.karr` `command` and `claude: true`, and `--force` does not override it. Nothing
else changes: the board stays fully usable by hand (`karr list`, `karr pick`,
`karr move`, …). Use it for a repository whose backlog is parked rather than
abandoned.

`karr disable` without `--reason` clears any previously stored reason. The same
state is readable and writable through `karr config`:

```bash
karr config get foundation.enabled           # -> 0 or 1
karr config set foundation.enabled false     # true/false, yes/no, on/off, 1/0
karr config set foundation.reason "why"
```

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

For Docker-wrapped usage, prefer the `raudssus/karr:latest` alias that mounts
the current project at `/work` and uses `/home/karr` as `HOME`, so the image
can drop privileges to the owner of the mounted workspace without breaking
access to Git config or agent skill directories.

### Sync

```bash
karr sync
karr sync --pull
karr sync --push
```

Use this when you want explicit control over board ref exchange with the remote
instead of relying only on the implicit pull/push behavior of mutating
commands.

`karr sync` also carries `refs/karr-foundation/*` — karr-foundation's shared
chain, run logs, question mailbox and design documents — in the same run,
after the board and never on its own. One command on purpose: a separate one
would be a second thing to remember, and a coordination namespace nobody
synced fails quietly. Mutating commands still sync the board only, so this
costs nothing outside an explicitly typed `karr sync`, and a repository
holding nothing under `refs/karr-foundation/` pushes nothing there. Deletions
in that namespace (log retention, a cleared chain) travel like board deletions
do, so a pruned run log does not come back on the next pull.

**A fresh clone fetches the board by itself.** `git clone` does not carry
`refs/karr/*`, so a new checkout holds no board while the whole board sits on
its remote. The read commands (`board`, `list`, `show`, `log`, `context`, and
`config show`/`config get`) do not pull as a rule — only mutating commands do —
but where there is nothing under `refs/karr/` at all and the remote has a
board, they fetch it once and answer, with one line on STDERR (never STDOUT)
saying where it came from. Where there is no remote, or the remote has no
board, they still refuse with exit 1 rather than rendering an empty board:
that is the only place `karr init` is the answer. In a clone whose board is on
the remote, `karr init` refuses as well and points at `karr sync`, so it can no
longer start a second, empty board beside the real one; `karr init --new-board`
is the documented way through when an independent board there really is what
you want.
`KARR_NO_AUTO_FETCH=1` switches the fetch off where karr must not touch the
network.

### File view (kanban-md interop)

```bash
karr materialize                             # refs -> tasks/ + config.yml on disk
karr materialize --force                     # overwrite git-tracked cards there
karr import --yes                            # tasks/ on disk -> refs
```

The board lives in `refs/karr/*`. `materialize` writes a file view of it for
grepping or for kanban-md to read; `import` reads such a directory back in.
The `tasks/` directory is always gitignored and is never the source of truth —
losing it costs nothing, editing it costs nothing until you `import`.
`materialize` refuses to write over paths the project itself tracks in git,
which is what `--force` overrides.

### Repair an old board

```bash
karr repair                                  # report what would change
karr repair --yes                            # migrate
```

Boards written by karr 0.402 or earlier stored UTF-8 double-encoded. Such a
board is detected on read and repaired on the fly, so nothing is broken in the
meantime; this migrates the stored refs once so the workaround stops being
needed. A board created by a later version needs nothing here and says so.

The same command also raises a `started` stamp that precedes its own card's
`created` up to that `created` — karr wrote `started` as a bare date until
ticket #68, which reads as midnight and so lands before a card created later
the same day. A clamped card then asserts zero queue time and no longer
records that its stamp was ever day-granular, so the dry run tells you how
many cards that is before you apply it. It reports, but does not touch,
`completed` stamps with the same day-granular problem.

### Backup and restore

```bash
karr backup > karr-backup.yml
karr restore --yes < karr-backup.yml
```

`restore` is destructive and replaces the entire `refs/karr/*` namespace.

### Destroy

```bash
karr destroy --yes
```

Deletes the entire `refs/karr/*` namespace from the repository and prunes the
remote board state too when a remote is configured. Prefer taking a
`karr backup` first.

### Helper refs

```bash
karr set-refs superpowers/spec/1234.md draft ready
karr set-refs superpowers/spec/1234.md < design.md    # multi-line payload
karr get-refs superpowers/spec/1234.md
```

Stores and retrieves helper payloads in Git refs outside protected namespaces
such as `refs/karr/*`, branches, and tags. Use this for shared planning blobs,
agent scratch data, or similar workflow artifacts that should sync through Git
without becoming task cards.

The arguments after the ref are joined with a single space, so they are a
one-line payload. A document goes in on stdin instead — with no content
argument at all, `karr set-refs REF < file` stores the file verbatim and
`karr get-refs REF > file` gives it back unchanged.

### Activity log

```bash
karr log                                     # last 20 entries
karr log --agent swift-fox                   # filter by agent
karr log --task 5                            # filter by task
karr log --last 50 --json                    # more entries, JSON
```

### Flow metrics

```bash
karr metrics                                 # throughput, lead/cycle time, efficiency, aging
karr metrics --since 2026-01-01              # only count tasks completed after this date
karr metrics --compact                       # one line plus one per aging item
karr metrics --json                          # JSON output
```

Every figure comes from the `created`/`started`/`completed` stamps on the
cards, not from the activity log. Cards whose stamps cannot carry a
measurement — an unreadable date, a `started` that precedes the card's own
`created`, or a `completed` that precedes that `started` — are left out of the
averages that need them and counted in `unusable_timestamps` (cards, not
stamps), so a low sample count is visible rather than silent.

Lead time is the deliberate exception: a `completed` that precedes its own
`created` is still averaged in, negative and all, because every value it could
be clamped to would be an invention. Such samples are counted separately in
`negative_lead_samples` and named in the closing note, so the average is
qualified instead of cleaned — they are *in* the figure, not missing from it,
which is why they are not in `unusable_timestamps`. They come from boards
written before karr 0.403, which stamped `started`/`completed` as a bare
`YYYY-MM-DD` that reads as midnight; on such a board an average printed to the
hour is finer than the data underneath it.

### Agent name

```bash
NAME=$(karr agent-name)                       # mint once, reuse everywhere
karr pick --claim "$NAME" --move in-progress
karr handoff ID --claim "$NAME" --note "Implementation complete"
```

Every `karr agent-name` call mints a **new** name and remembers it nowhere, so
`--claim "$(karr agent-name)"` written a second time claims under one name and
hands off under another â while the first claim is live the handoff is refused,
and once it has expired it silently re-stamps the card with a name nobody holds.
Capture the name once into a shell variable and pass that same variable to every
later `--claim`, `--claimed-by` and `log --agent`. If it was never captured, read
it back off the board (`karr show ID` â `Claimed:`, or `karr pick`'s own
`(claimed by NAME)`) rather than minting a fresh one.

## Stored task format

```markdown
id: 1
title: Set up CI pipeline
status: backlog
priority: high
class: standard
created: 2026-03-12T10:00:00Z
updated: 2026-03-12T10:00:00Z
tags:
  - devops
  - needs:other-repo#7

Optional body with more detail.
```

Cross-board dependencies ride in `tags` (`needs:BOARD#ID`,
`escalated-from:BOARD#ID`) rather than in a frontmatter field of their own:
kanban-md marshals a card from its own struct and would drop an unmodelled key
the first time it writes, while `tags` is modelled on both sides.

Tasks are stored under `refs/karr/tasks/*/data`. During command execution `karr`
materializes the same Markdown shape into a temporary task directory, so this
format still matters when reading or generating tasks programmatically.

## Config refs

```yaml
version: 1
board:
  name: My Project
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
foundation:
  enabled: false
  reason: abandoned driver, backlog parked
```

That YAML lives in `refs/karr/config` as sparse overrides. The next numeric id
is kept separately in `refs/karr/meta/next-id`.

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
13. **Need a full board snapshot?** → `karr backup` / `karr restore --yes`
14. **Need shared non-task workflow data?** → `karr set-refs` / `karr get-refs`
15. **Board should never be drained by an automation host?** → `karr disable --reason "why"`
16. **Need to remove the board completely?** → `karr destroy --yes`

## Multi-agent workflow

```bash
# 1. Generate agent name and pick task
NAME=$(karr agent-name)
karr pick --claim $NAME --status todo --move in-progress

# 2. Work on task...

# 3. Hand off for review
karr handoff ID --claim $NAME --note "Implementation complete" --timestamp

# 4. Or: release and mark done directly
karr edit ID --release
karr move ID done
```

Claims expire after the configured timeout (default: 1h). Statuses with `require_claim: true` enforce that moves include `--claim`.

Perl remains the primary local installation path, but a Docker alias around
`raudssus/karr:latest` or `raudssus/karr:user` works with the same commands when
another repository vendors `karr` instead of installing it locally.

## Helper-ref workflow

```bash
# 1. Publish a shared planning blob
karr set-refs superpowers/spec/1234.md initial draft ready for review

# 2. Or pipe a whole document in - arguments are joined with a space and
#    would flatten it into one line
karr set-refs superpowers/spec/1234.md < design.md

# 3. Read it back elsewhere
karr get-refs superpowers/spec/1234.md
```

Use helper refs for coordination data that should travel with Git but should
not affect the board state itself.
