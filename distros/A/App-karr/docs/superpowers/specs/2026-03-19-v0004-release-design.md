# karr v0.004 Release & Product Strategy

Date: 2026-03-19

## Context

App::karr v0.003 has 16 commands, Docker packaging, and partial Git sync. The Git sync design (2026-03-15) specifies task data in `refs/karr/tasks/<id>` but only lock refs are currently implemented. This spec covers the fixes and features needed for a solid v0.004 release that delivers on the core promise: **distributed AI agent task coordination via Git refs**.

## Release Goals

1. Git sync stores and retrieves task data via refs (not just locks)
2. Multi-agent race conditions eliminated (Pick uses Lock)
3. `log` command for agent activity transparency
4. Agent integration is frictionless (Docker-first, skill install, hints)
5. Remove erroneous `karr/` from `.gitignore` generation

## Architecture: Task Data in Refs

### Critical: Refs Must Point to Commits, Not Blobs

Git's `git push` only transfers refs that point to commits (or tags). The current `write_ref` implementation creates a blob via `git hash-object` and points a ref at it. This works locally but **silently fails on push/fetch**. All ref writes must wrap content in a commit object.

All git operations MUST use the safe `_git_cmd` helper (see Section 1) to avoid shell injection. The multi-step ref write pipeline uses `_git_cmd` for each step and passes content via stdin using `_git_cmd_stdin`:

```perl
sub _git_cmd_stdin {
    my ($self, $input, @cmd) = @_;
    my $dir = $self->dir->stringify;
    my $pid = open2(my $out, my $in, 'git', '-C', $dir, @cmd);
    print $in $input;
    close $in;
    my $output = do { local $/; <$out> };
    waitpid($pid, 0);
    chomp $output if defined $output;
    return $output;
}

sub write_ref {
    my ($self, $ref, $content) = @_;

    # Create blob from content via stdin (safe, no shell interpolation)
    my $blob = $self->_git_cmd_stdin($content, 'hash-object', '-w', '--stdin');
    return unless $blob;

    # Create tree containing the blob
    my $tree_line = sprintf("100644 blob %s\tdata", $blob);
    my $tree = $self->_git_cmd_stdin($tree_line, 'mktree');
    return unless $tree;

    # Create commit (no parent — each ref is independent)
    my $commit = $self->_git_cmd('commit-tree', $tree, '-m', 'karr ref update');
    return unless $commit;

    # Update ref to point at commit
    $self->_git_cmd('update-ref', $ref, $commit);
    return 1;
}

sub read_ref {
    my ($self, $ref) = @_;
    # Read the blob named "data" from the commit's tree via ref:path syntax
    my ($content, $ok) = $self->_git_cmd('cat-file', '-p', "$ref:data");
    return $ok ? $content : '';
}
```

This stores content as a blob inside a tree inside a commit. `git push/fetch` can transfer commit-pointed refs. The `read_ref` uses git's `ref:path` syntax to reach the blob through the tree.

**Note on orphan commits:** Each `write_ref` creates a parentless commit. Unreachable objects accumulate over time but are cleaned by `git gc` (runs automatically). A future optimization could chain commits (parent = previous ref value) for delta compression.

### Current State (broken)

```
karr/tasks/001-fix-bug.md  →  local file only, gitignored
refs/karr/tasks/1/lock     →  lock owner (blob ref — cannot push!)
```

Tasks exist only as local files. `karr/` is erroneously added to `.gitignore` by `init`. Sync only attempts lock refs but those are blob-pointed so push silently fails. Nothing actually syncs.

### Target State

```
refs/karr/tasks/<id>/data  →  task content (commit-wrapped, syncs via push/fetch)
refs/karr/tasks/<id>/lock  →  lock owner (commit-wrapped, syncs via push/fetch)
refs/karr/config           →  board config (commit-wrapped, syncs)
refs/karr/log              →  activity log (commit-wrapped, syncs)
karr/tasks/001-fix-bug.md  →  local materialized working copy
karr/config.yml            →  local materialized config
```

**Source of truth:** The refs. Local files in `karr/` are a materialized working copy, regenerated from refs on every sync. The local files exist so commands can read/write them without going through git on every operation. `karr init` does NOT add `karr/` to `.gitignore` — the user decides whether to commit the working copies (for visibility in PRs/diffs) or gitignore them (since refs are authoritative). karr works correctly either way.

### Sync Flow (every write command)

```
1. git fetch origin refs/karr/*:refs/karr/*     # pull remote refs
2. Materialize: refs → local karr/tasks/ files  # overwrite local with remote state
3. [command applies its change to local files]   # normal file operations
4. Lock task if needed (write lock ref + push)   # push lock immediately
5. Serialize: local files → refs                 # write changed task refs
6. Append log entry to log ref                   # audit trail
7. git push origin refs/karr/*:refs/karr/*       # push all refs
8. Release lock (delete lock ref + push)         # cleanup
```

### Materialization Rules

When materializing refs to local files after fetch:

| Remote ref exists | Local file exists | Action |
|---|---|---|
| Yes | No | Write local file from ref (task created by another agent) |
| Yes | Yes | Overwrite local file with ref content (remote is authoritative) |
| No | Yes | Serialize to ref first (locally-created task not yet synced) |
| No | No | Nothing |

When serializing local files to refs before push:

- Read all `.md` files from `karr/tasks/`
- For each file, write its content to `refs/karr/tasks/<id>/data`
- Also serialize `karr/config.yml` to `refs/karr/config`

### Task ID Collision Prevention

`next_id` is stored in `config.yml` which is synced via `refs/karr/config`. On sync-before, the remote config is fetched and `next_id` is set to `max(local_next_id, remote_next_id)`. This prevents two agents from assigning the same ID.

### Conflict Resolution

The lock mechanism prevents two agents from modifying the same task simultaneously. Lock acquisition requires an immediate push so other agents see it. Different tasks can be modified concurrently — each task has its own ref, no conflicts possible.

For the rare case where lock push fails (network issue, another agent pushed first): the push will be rejected (non-fast-forward on the lock ref). The command should catch this and retry with the next available task.

## Changes Required

### 1. Fix: `is_repo` must find repo root + safe shell execution

**File:** `lib/App/karr/Git.pm`

Current `is_repo` checks `$self->dir->child('.git')` which fails when dir is `karr/`. Replace with `git rev-parse`. Also: all shell calls throughout `Git.pm` use single-quote interpolation which is vulnerable to shell injection if `$dir` contains quotes. Use `chdir` + backticks without path interpolation, or `IPC::Run3`/list-form `system()`.

```perl
sub _git_cmd {
    my ($self, @cmd) = @_;
    my $dir = $self->dir->stringify;
    my $pid = open(my $fh, '-|');
    if (!$pid) {
        chdir $dir or die "chdir $dir: $!";
        exec('git', @cmd) or die "exec git: $!";
    }
    my $output = do { local $/; <$fh> };
    close $fh;
    chomp $output if defined $output;
    return wantarray ? ($output, $? == 0) : $output;
}

sub is_repo {
    my ($self) = @_;
    my ($out, $ok) = $self->_git_cmd('rev-parse', '--show-toplevel');
    return $ok;
}
```

All other methods (`read_ref`, `write_ref`, `fetch`, `push`, `pull`) should use `_git_cmd` instead of backtick interpolation.

### 1b. Fix: `push` refspec

**File:** `lib/App/karr/Git.pm`

Current `push` uses `git push origin refs/karr/` which is not a valid refspec. Fix to match the `pull` pattern:

```perl
sub push {
    my ($self, $remote, $refspec) = @_;
    $remote //= 'origin';
    $refspec //= 'refs/karr/*:refs/karr/*';
    $self->_git_cmd('push', $remote, $refspec);
}
```

### 2. Fix: Remove `.gitignore` manipulation from Init

**File:** `lib/App/karr/Cmd/Init.pm`

Remove lines 54-65 that add `karr/` to `.gitignore`. The board data lives in refs, and local `karr/` files are materialized working copies. Whether to gitignore them is the user's choice — karr should not force it either way.

### 3. Feature: Task data serialization to/from refs

**File:** `lib/App/karr/Git.pm` (extend)

New methods:

```perl
sub save_task_ref {
    my ($self, $task) = @_;
    my $ref = "refs/karr/tasks/" . $task->id . "/data";
    $self->write_ref($ref, $task->to_markdown);
}

sub load_task_ref {
    my ($self, $id) = @_;
    my $ref = "refs/karr/tasks/$id/data";
    my $content = $self->read_ref($ref);
    return undef unless $content;
    return App::karr::Task->from_string($content, $id);
}

sub list_task_refs {
    my ($self) = @_;
    my $output = $self->_git_cmd('for-each-ref', '--format=%(refname)', 'refs/karr/tasks/');
    return () unless $output;
    my %ids;
    for (split /\n/, $output) {
        $ids{$1} = 1 if m{refs/karr/tasks/(\d+)/};
    }
    return sort { $a <=> $b } keys %ids;
}
```

**File:** `lib/App/karr/Task.pm` (refactor)

Extract the YAML+body parsing from `from_file` into a shared `_parse_content` method. `from_file` calls it after `slurp_utf8`, `from_string` calls it directly. This avoids duplicate parsing logic:

```perl
sub _parse_content {
    my ($class, $content) = @_;
    my ($yaml, $body) = $content =~ m{^---\n(.+?)---\n(.*)$}s
        or die "Invalid task format\n";
    $body //= '';
    $body =~ s/^\n//;
    $body =~ s/\n$//;
    return (Load($yaml), $body);
}

sub from_string {
    my ($class, $content) = @_;
    my ($fm, $body) = $class->_parse_content($content);
    return $class->new(%$fm, body => $body);
}

sub from_file {
    my ($class, $file) = @_;
    $file = path($file);
    my ($fm, $body) = $class->_parse_content($file->slurp_utf8);
    return $class->new(%$fm, body => $body, file_path => $file);
}
```

### 4. Feature: Full sync with materialization

**File:** `lib/App/karr/Cmd/Sync.pm` (rewrite)

The sync command orchestrates the full cycle:

```perl
sub execute {
    my ($self, $args, $data) = @_;
    my $git = App::karr::Git->new(dir => '.');
    die "Not a git repository\n" unless $git->is_repo;

    # 1. Fetch remote refs
    $git->pull unless $self->push && !$self->pull;

    # 2. Materialize: refs → local files
    $self->_materialize($git) unless $self->push && !$self->pull;

    # 3. Serialize: local files → refs (for locally-created tasks)
    $self->_serialize($git) unless $self->pull && !$self->push;

    # 4. Push refs
    $git->push unless $self->pull && !$self->push;
}
```

**`_materialize($git)`:** List all task refs via `git for-each-ref refs/karr/tasks/`. For each task ID found, read `refs/karr/tasks/<id>/data` → write to `karr/tasks/<NNN>-<slug>.md`. Also materialize `refs/karr/config` → `karr/config.yml`.

**`_serialize($git)`:** Read all `karr/tasks/*.md` files. For each, call `$git->write_ref("refs/karr/tasks/$id/data", $content)`. Also serialize `karr/config.yml` → `refs/karr/config`.

**File:** `lib/App/karr/Role/BoardAccess.pm` (extend with sync helpers)

Add `sync_before` and `sync_after` methods that wrap the materialize/serialize pattern. These replace the duplicated `_sync_after` in all 7 write commands (Archive, Create, Delete, Edit, Handoff, Move, Pick):

```perl
sub sync_before {
    my ($self) = @_;
    require App::karr::Git;
    my $git = App::karr::Git->new(dir => $self->board_dir->parent->stringify);
    return unless $git->is_repo;
    $git->pull;
    $self->_materialize_from_refs($git);
}

sub sync_after {
    my ($self) = @_;
    require App::karr::Git;
    my $git = App::karr::Git->new(dir => $self->board_dir->parent->stringify);
    return unless $git->is_repo;
    $self->_serialize_to_refs($git);
    $git->push;
}

sub _materialize_from_refs {
    my ($self, $git) = @_;
    my @ids = $git->list_task_refs;
    my $tasks_dir = $self->tasks_dir;
    $tasks_dir->mkpath;

    # First: serialize any locally-created tasks (no ref yet) to refs
    # so they survive the cleanup step
    if ($tasks_dir->exists) {
        for my $file ($tasks_dir->children(qr/\.md$/)) {
            my $task = App::karr::Task->from_file($file);
            my $ref_content = $git->read_ref("refs/karr/tasks/" . $task->id . "/data");
            unless ($ref_content) {
                # Local-only task — serialize to ref before clearing
                $git->save_task_ref($task);
                push @ids, $task->id unless grep { $_ == $task->id } @ids;
            }
        }

        # Clear all existing .md files to avoid stale entries
        # (e.g., task title changed remotely → old slug file remains)
        for my $old_file ($tasks_dir->children(qr/\.md$/)) {
            $old_file->remove;
        }
    }

    # Re-materialize from refs (now includes locally-created tasks)
    for my $id (@ids) {
        my $task = $git->load_task_ref($id);
        next unless $task;
        $task->save($tasks_dir);
    }
    # Materialize config
    my $config_content = $git->read_ref('refs/karr/config');
    if ($config_content) {
        $self->board_dir->child('config.yml')->spew_utf8($config_content);
    }
}

sub _serialize_to_refs {
    my ($self, $git) = @_;
    for my $task ($self->load_tasks) {
        $git->save_task_ref($task);
    }
    # Serialize config
    my $config_file = $self->board_dir->child('config.yml');
    if ($config_file->exists) {
        $git->write_ref('refs/karr/config', $config_file->slurp_utf8);
    }
}
```

### 5. Fix: Pick must use Lock with immediate push

**File:** `lib/App/karr/Cmd/Pick.pm`

Before claiming a task, acquire lock AND push the lock ref immediately so other agents see it. On failure (local or push), skip to next task. After save + serialize, release lock.

```perl
my $git = App::karr::Git->new(dir => $self->board_dir->parent->stringify);
# Note: Lock.pm constructor needs refactoring to accept a pre-built $git object
# instead of creating its own. Change: new(dir => ...) → new(git => $git)
my $lock = App::karr::Lock->new(git => $git);
my $email = $git->git_user_email || $self->claim;

for my $task (@tasks) {
    my ($ok, $msg) = $lock->acquire($task->id, $email);
    next unless $ok;

    # Push lock immediately so other agents see it
    my $lock_ref = $lock->ref_name($task->id);
    unless ($git->push('origin', "$lock_ref:$lock_ref")) {
        # Another agent got there first (non-fast-forward)
        $lock->release($task->id, $email);
        next;
    }

    # Claim and save
    $task->claimed_by($self->claim);
    $task->claimed_at(gmtime->datetime . 'Z');
    $task->save;

    # Serialize to ref + push
    $git->save_task_ref($task);
    $git->push;

    # Release lock
    $lock->release($task->id, $email);
    $git->push('origin', "$lock_ref:$lock_ref");

    # Output result...
    last;
}
```

### 6. Fix: Extract sync into Role::BoardAccess

Covered in Section 4 above. Remove the duplicated `_sync_after` method from all 7 commands: `Archive`, `Create`, `Delete`, `Edit`, `Handoff`, `Move`, `Pick`. Replace with calls to `$self->sync_before` and `$self->sync_after` from the role.

### 7. Feature: `--claimed-by` filter on `list`

**File:** `lib/App/karr/Cmd/List.pm`

```perl
option claimed_by => (
    is => 'ro',
    format => 's',
    doc => 'Filter by claim owner',
);
# In execute: @tasks = grep { $_->has_claimed_by && $_->claimed_by eq $self->claimed_by } @tasks;
```

### 8. Feature: `log` command

**New file:** `lib/App/karr/Cmd/Log.pm`

Activity log stored as newline-delimited JSON. To avoid race conditions on a single shared ref, each agent appends to its own log ref:

```
refs/karr/log/<agent-identity>   →  that agent's log entries (NDJSON)
```

Format per line:
```json
{"ts":"2026-03-19T10:00:00Z","agent":"swift-fox","action":"pick","task_id":5,"detail":"in-progress"}
```

**Append is safe:** Each agent only writes its own ref, so no concurrent-write conflicts. Reading aggregates all `refs/karr/log/*` refs, sorts by timestamp.

**Growth management:** For v0.004, the log grows without bound. This is acceptable for the expected scale (hundreds to low thousands of entries per board). Log rotation/archival is a v0.005 concern if needed.

```perl
# In Role::BoardAccess (called by every write command):
sub append_log {
    my ($self, $git, %entry) = @_;
    $entry{ts} //= gmtime->datetime . 'Z';
    my $identity = $git->git_user_email || 'unknown';
    $identity =~ s/[^a-zA-Z0-9._-]/_/g;  # safe ref name
    my $ref = "refs/karr/log/$identity";
    my $existing = $git->read_ref($ref);
    my $line = encode_json(\%entry);
    my $new = $existing ? "$existing\n$line" : $line;
    $git->write_ref($ref, $new);
}
```

**Command:** `karr log [--agent NAME] [--task ID] [--last N] [--json]`

Reads all `refs/karr/log/*` refs, merges entries, sorts by `ts`, applies filters. Default: last 20 entries.

### 9. Docker: Git identity fallback

**File:** `Dockerfile`

```dockerfile
ENV GIT_AUTHOR_NAME="karr"
ENV GIT_AUTHOR_EMAIL="karr@localhost"
ENV GIT_COMMITTER_NAME="karr"
ENV GIT_COMMITTER_EMAIL="karr@localhost"
```

Overridable via `-e` flags on `docker run`.

### 10. Fix: Changes file — remove "experimental"

Replace "experimental" with stable language. Git sync via refs/karr/* is a core feature.

## AI Agent Integration Scenarios

### Scenario 1: Claude Code Session — Solo Agent

One agent, one repo. The simplest case.

```bash
# Setup (once)
docker run --rm -v $(pwd):/work raudssus/karr init --name "my-project"
docker run --rm -v $(pwd):/work raudssus/karr skill install

# Agent session starts, skill is loaded automatically
# Agent checks what's available:
karr pick --claim $(karr agentname) --status todo --move in-progress --json

# Agent works on the task...

# Agent hands off:
karr handoff 5 --claim swift-fox --note "Implemented auth module, tests pass" -t

# Agent marks done:
karr move 5 done --claim swift-fox
```

**Integration hint:** Add a Claude Code hook that runs `karr context --write-to AGENTS.md` on session start, so the agent always sees the current board state.

### Scenario 2: Multiple Claude Code Instances — Parallel Agents

Three agents on the same repo, each in a separate terminal/worktree.

```bash
# Agent A picks first available task:
karr pick --claim agent-a --move in-progress --json
# → picks task 3 (highest priority unclaimed)

# Agent B picks next available (task 3 is now claimed):
karr pick --claim agent-b --move in-progress --json
# → picks task 7 (next highest, task 3 locked by agent-a)

# Agent C picks:
karr pick --claim agent-c --move in-progress --json
# → picks task 12

# Agent A finishes, hands off:
karr handoff 3 --claim agent-a --note "done" -t
# Sync pushes → agents B and C see updated board on next sync

# Agent B checks what's blocked:
karr list --status review --json
```

**Integration hint:** Use `karr pick --claim $NAME --tags backend` to let agents specialize by domain. Tag tasks with `backend`, `frontend`, `docs` etc.

### Scenario 3: Cross-Repo Agent Coordination

Human manages GitHub Issues. Bridge agent transfers selected issues to karr. Worker agents pick and execute.

```
GitHub Issues                    karr board                    Agent work
┌──────────────┐   bridge    ┌──────────────────┐  pick    ┌──────────────┐
│ Issue #42    │ ──agent──→  │ Task 1 (backlog) │ ──────→  │ Agent works  │
│ Issue #43    │ ──agent──→  │ Task 2 (backlog) │          │ on task 1    │
│ Issue #44    │             │ Task 3 (todo)    │          │              │
└──────────────┘             └──────────────────┘          └──────────────┘
```

```bash
# Bridge agent (runs periodically or via hook):
ISSUES=$(gh issue list --repo owner/repo --label agent-ready --json number,title)
# For each issue:
karr create "$TITLE" --priority high --body "See: owner/repo#42" --tags github

# Worker agent:
karr pick --claim worker-1 --move in-progress --json
# Agent reads task body, sees "See: owner/repo#42"
# Agent works on the issue, creates PR
# Agent hands off:
karr handoff 1 --claim worker-1 --note "PR #99 created" -t
```

**Integration hint:** The bridge is NOT part of karr — it's a simple script or Claude Code hook. karr stays source-agnostic. The task body carries the link back to the original issue.

### Scenario 4: Continuous Agent Loop with Docker

A persistent agent container that polls for work, executes, and reports.

```bash
#!/bin/bash
# agent-loop.sh — runs inside Docker or as a cron job
NAME="docker-agent-$(hostname)"

while true; do
    # Sync first
    karr sync --pull

    # Try to pick a task
    TASK=$(karr pick --claim "$NAME" --status todo --move in-progress --json 2>/dev/null)

    if [ -z "$TASK" ]; then
        sleep 30
        continue
    fi

    TASK_ID=$(echo "$TASK" | jq -r '.id')
    TASK_TITLE=$(echo "$TASK" | jq -r '.title')

    echo "Working on task $TASK_ID: $TASK_TITLE"

    # Execute task (agent-specific logic here)
    # ...

    # Hand off
    karr handoff "$TASK_ID" --claim "$NAME" --note "Completed by $NAME" -t
    karr sync --push

    sleep 5
done
```

**Integration hint:** Use `--json` everywhere for machine parsing. A future `karr sync --watch` could replace the sleep loop with event-driven polling (v0.005+).

## Agent Integration Quick Reference

### Docker one-liner setup

```bash
# Add to .bashrc / .zshrc:
alias karr='docker run --rm -v $(pwd):/work -v $HOME/.gitconfig:/root/.gitconfig:ro raudssus/karr'

# Init a board:
karr init --name "my-project"

# Install skills for all detected agents:
karr skill install
```

### Claude Code hooks (settings.json)

```json
{
  "hooks": {
    "session_start": [
      "karr context --write-to AGENTS.md"
    ],
    "pre_tool_use:Edit": [
      "karr list --claimed-by $AGENT_NAME --status in-progress --compact"
    ]
  }
}
```

### Embed board state in AGENTS.md or CLAUDE.md

```bash
karr context --write-to CLAUDE.md
# Inserts/updates between <!-- BEGIN kanban-md context --> sentinels
# Agent sees current board state at session start automatically
```

### Agent identity strategies

| Strategy | Persistence | Use case |
|----------|------------|----------|
| `karr agentname` | Ephemeral (new each call) | One-shot tasks |
| `git config user.email` | Stable per machine | Persistent agents |
| `$HOSTNAME-$PID` | Stable per process | Docker containers |
| Fixed name in hook/config | Stable always | Dedicated agent role |

**Recommendation for persistent agents:** Use git identity or a fixed name, not `karr agentname`.

### Key flags for agent consumption

| Flag | Purpose |
|------|---------|
| `--json` | Machine-readable output on ALL commands |
| `--compact` | One-line output (good for log context) |
| `--claimed-by NAME` | Filter to "my" tasks |
| `--status S1,S2` | Filter by status |
| `--tags t1,t2` | Specialize agents by domain |

### Docker + Git sync

```bash
# Mount git config for identity:
docker run --rm -v $(pwd):/work \
  -v $HOME/.gitconfig:/root/.gitconfig:ro \
  -v $HOME/.ssh:/root/.ssh:ro \
  raudssus/karr sync
```

## Test Coverage Requirements

The ref-based sync is the highest-risk change. Required tests:

1. **`write_ref`/`read_ref` roundtrip** — verify commit-wrapped refs can be written and read back
2. **`push`/`fetch` with commit-wrapped refs** — verify refs actually transfer between repos (test with `git clone --bare` + two working copies)
3. **Materialize/serialize roundtrip** — create task via file, serialize to ref, delete file, materialize from ref, verify content matches
4. **Pick with Lock** — two sequential picks should claim different tasks
5. **Log append + read** — append entries from two "agents", verify merged output is sorted
6. **`from_string`/`from_file` parity** — same content parsed both ways produces identical Task objects
7. **`is_repo` from subdirectory** — verify detection works from `karr/` inside a git repo
8. **Config sync** — `next_id` collision prevention across two agents

Existing tests (`t/01-task.t` through `t/07-context.t`) must continue to pass unchanged.

## Out of Scope (v0.005+)

- `metrics` command (throughput, cycle time)
- `sync --watch` (background daemon polling)
- Dependency checking (block tasks with unsatisfied deps)
- Self-healing IDs
- WIP limit enforcement on move
- TUI (Tickit)
- External repo refs (`refs/karr/external/`)
- Messages in task metadata
