# App::karr

Git-native kanban for shared helper agents, human operators, and downstream
repos that want a board without checking a board directory into the work tree.

`karr` keeps canonical state in `refs/karr/*`, not in commits, branches, or a
persistent `karr/` folder. Tasks, config, logs, snapshots, and helper refs move
through normal Git transport, which makes the tool fit naturally into AI-heavy
and multi-machine workflows.

## Why it exists

Most task tools assume a central web service or a checked-in file tree.
`karr` takes a different route:

- board state lives in Git refs
- mutating commands pull, materialize, write back, and push
- tasks stay separate from branches and commits
- downstream projects can vendor the CLI through Docker and keep the exact same UX

That gives you a shared board with far fewer file-level collisions and without
having to bolt on another ticket system just to coordinate agents.

## Quick start

Inside an existing Git repository:

```bash
karr init --name "My Project"
karr create "Fix login bug" --priority high
karr list
karr board
```

Claim and progress work:

```bash
NAME=$(karr agentname)
karr pick --claim "$NAME" --status todo --move in-progress
karr handoff 1 --claim "$NAME" --note "Ready for review" --timestamp
```

Protect yourself before destructive operations:

```bash
karr backup > karr-backup.yml
karr restore --yes < karr-backup.yml
karr destroy --yes
```

## Installation

### Perl

```bash
cpanm App::karr
```

### Docker

The published images are:

- `raudssus/karr:latest`
- `raudssus/karr:user`

`latest` is the ergonomic default. It starts as root only long enough to inspect
`/work`, then drops to the owner of the mounted workspace before running
`karr`. That keeps host files from becoming root-owned.

`user` is the fixed-user image. It defaults to `1000:1000` and is the better
base when you want a deterministic downstream derivative.

Minimal smoke test:

```bash
docker run --rm -it -w /work -v "$(pwd):/work" raudssus/karr:latest --help
```

Recommended alias for real use:

```bash
alias karr='docker run --rm -it \
  -w /work \
  -e HOME=/home/karr \
  -v "$(pwd):/work" \
  -v "$HOME/.gitconfig:/home/karr/.gitconfig:ro" \
  -v "$HOME/.claude:/home/karr/.claude" \
  -v "$HOME/.codex:/home/karr/.codex" \
  -v "$HOME/.cursor:/home/karr/.cursor" \
  raudssus/karr:latest'
```

With that alias, all normal commands stay identical:

```bash
karr init --name "HandyIntelligence Prototype" --claude-skill
karr skill install --agent codex --global --force
karr create "Document release workflow"
```

If you want a custom fixed-user image in CI or a downstream repo:

```bash
docker build --target runtime-user \
  --build-arg KARR_UID=1010 \
  --build-arg KARR_GID=1010 \
  -t raudssus/karr:user1010 .
```

## How it works

The write path is intentionally simple:

```text
fetch refs -> materialize temp board -> change task/config -> serialize to refs -> push
```

Important refs:

- `refs/karr/config` holds sparse YAML config overrides
- `refs/karr/meta/next-id` holds the next numeric task id
- `refs/karr/tasks/<id>/data` holds task Markdown plus frontmatter
- `refs/karr/log/<agent>` holds append-style JSON log lines

This means the repository stays Git-only and the board remains ref-first even
when commands internally use temporary files for convenience.

## Command map

### Board lifecycle

| Command | Use it for |
|---------|------------|
| `karr init` | create the board in `refs/karr/*` |
| `karr config` | inspect and change merged board settings |
| `karr backup` | export the whole board as YAML |
| `karr restore --yes` | replace the board from a YAML snapshot |
| `karr destroy --yes` | remove the board completely |
| `karr sync` | explicitly pull/push board refs |

### Task lifecycle

| Command | Use it for |
|---------|------------|
| `karr create` | create a task |
| `karr list` | filter and search tasks |
| `karr show` | inspect one task in full |
| `karr edit` | update body, metadata, claim, or blocked state |
| `karr move` | change status explicitly or with `--next` / `--prev` |
| `karr archive` | soft-delete into `archived` |
| `karr delete` | permanently remove the task ref |

### Flow and coordination

| Command | Use it for |
|---------|------------|
| `karr board` | grouped board view |
| `karr pick` | atomic next-task selection with claim |
| `karr handoff` | move into review and append a note |
| `karr context` | generate agent-facing board summary |
| `karr log` | inspect per-agent or per-task activity |
| `karr agentname` | generate short claim names |

### Skills and helper refs

| Command | Use it for |
|---------|------------|
| `karr skill install` | install bundled skills for Claude Code, Codex, or Cursor |
| `karr skill check` | detect outdated installed skills |
| `karr skill update` | refresh installed skills |
| `karr set-refs` | store shared non-task payloads in allowed refs |
| `karr get-refs` | fetch helper payloads back out |

## Multi-agent workflow

```bash
NAME=$(karr agentname)

# pick the best available task
karr pick --claim "$NAME" --status todo --move in-progress

# inspect board state
karr board
karr list --claimed-by "$NAME"

# hand off to review
karr handoff 1 --claim "$NAME" --note "Implementation complete" --timestamp

# inspect activity trail
karr log --agent "$NAME"
```

`pick` respects blocked state, claim timeout, and class-of-service ordering:

- `expedite`
- `fixed-date`
- `standard`
- `intangible`

## Helper refs

Not all shared workflow state belongs in tasks. `karr` also supports arbitrary
non-protected refs outside `refs/karr/*`.

```bash
karr set-refs superpowers/spec/1234.md draft ready
karr get-refs superpowers/spec/1234.md
```

Use this for:

- planning blobs
- generated specs
- agent scratch state
- workflow metadata you want synced through Git but not modeled as cards

Protected namespaces such as branches, tags, remotes, stash, and `refs/karr/*`
are blocked.

## Skills

The distribution ships a bundled `karr` skill that can be installed locally in
a repo or globally in the current home directory.

```bash
karr skill install
karr skill install --agent claude-code
karr skill install --agent codex --global --force
karr skill check --global
karr skill update
```

Supported targets:

- `claude-code`
- `codex`
- `cursor`

Project-local Claude installation during board setup:

```bash
karr init --name "My Project" --claude-skill
```

## Board snapshots and destructive operations

Backups are full YAML snapshots of `refs/karr/*`:

```bash
karr backup > karr-backup.yml
```

Restore is intentionally destructive:

```bash
karr restore --yes < karr-backup.yml
```

It deletes current `refs/karr/*` refs first and then replays the snapshot.

Full board removal is explicit too:

```bash
karr destroy --yes
```

If a remote exists, `restore` and `destroy` also prune the remote board state
to match.

## Stored task shape

Tasks live in `refs/karr/tasks/*/data`, but the payload itself is ordinary
Markdown with YAML frontmatter:

```markdown
---
id: 1
title: Fix login bug
status: in-progress
priority: high
class: standard
claimed_by: agent-fox
created: 2026-03-12T10:00:00Z
updated: 2026-03-12T10:00:00Z
---

Task description here.
```

That makes the format easy to inspect, script, and reuse from Perl code.

## Programmatic usage

`karr` is primarily a CLI, but the lower-level modules are usable from Perl:

```perl
use App::karr::Git;
use App::karr::BoardStore;

my $git = App::karr::Git->new(dir => '.');
my $store = App::karr::BoardStore->new(git => $git);

my $config = $store->load_config;
my @tasks  = $store->load_tasks;
```

Or create a task directly:

```perl
use App::karr::Task;

my $task = App::karr::Task->new(
  id       => $store->allocate_next_id,
  title    => 'Write release notes',
  status   => 'backlog',
  priority => 'high',
);

$store->save_task($task);
$git->push;
```

## Why Docker matters here

Perl installation is the normal local path, but Docker is equally valid when a
downstream repo wants to vendor `karr` instead of adding a direct Perl tool
dependency. That keeps the command surface identical across:

- local Perl installs
- Codex/Claude/Cursor-heavy repos
- CI or ops environments that prefer containerized tooling

## License

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.
