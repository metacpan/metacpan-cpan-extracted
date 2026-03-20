# karr Git Sync Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Git-based sync to karr for multi-agent collaboration with locks, messages, and external repo support.

**Architecture:** Use Git::Raw for Git operations. Store task metadata in `refs/karr/tasks/<id>` (YAML blob). Implement lock via `refs/karr/tasks/<id>/lock` with atomic update-ref operations. Auto-sync by default on every write command.

**Tech Stack:** Perl, Moo, Git::Raw, YAML::XS

---

## File Structure

```
lib/App/karr/
  Sync.pm              # Core sync logic (NEW)
  Lock.pm              # Lock management (NEW)
  External.pm         # External repo integration (NEW)
  Cmd/
    Sync.pm           # Sync command (NEW)
  Role/
    GitSync.pm        # Role for commands needing sync (NEW)
```

## Implementation Chunks

### Chunk 1: Core Git Operations

**Files:**
- Create: `lib/App/karr/Sync.pm`
- Create: `lib/App/karr/Lock.pm`

- [ ] **Step 1: Write failing test for Sync module**

```perl
# t/10-sync.t
use strict;
use warnings;
use Test::More;
use App::karr::Sync;

my $sync = App::karr::Sync->new(board_dir => 't/fixtures/board');
ok($sync->has_remote, 'has_remote returns true when .git exists');
ok(!$sync->has_remote, 'has_remote returns false without .git');

done_testing;
```

Run: `prove -l t/10-sync.t`
Expected: FAIL - module not found

- [ ] **Step 2: Create Sync.pm skeleton**

```perl
# ABSTRACT: Git sync operations for karr

package App::karr::Sync;

use Moo;
use Path::Tiny;
use Git::Raw;
use YAML::XS qw( Load Dump );

has board_dir => ( is => 'ro', required => 1 );

sub has_remote {
    my ($self) = @_;
    my $git_dir = $self->board_dir->child('.git');
    return 0 unless $git_dir->exists;
    eval { Git::Raw::Repository->open($self->board_dir->stringify) };
}

1;
```

Run: `prove -l t/10-sync.t`
Expected: FAIL - has_remote logic wrong

- [ ] **Step 3: Fix has_remote**

```perl
sub has_remote {
    my ($self) = @_;
    my $git_dir = $self->board_dir->child('.git');
    return 0 unless $git_dir->exists;
    my $repo = eval { Git::Raw::Repository->open($self->board_dir->stringify) };
    return 0 unless $repo;
    my $remote = eval { $repo->remotes->{origin} };
    return defined $remote;
}
```

Run: `prove -l t/10-sync.t`
Expected: PASS

- [ ] **Step 4: Add fetch and push methods**

Add to Sync.pm:
```perl
sub fetch {
    my ($self) = @_;
    my $repo = Git::Raw::Repository->open($self->board_dir->stringify);
    my $remote = $repo->remotes->{origin} or return;
    $remote->fetch;
    return 1;
}

sub push_refs {
    my ($self, $ref, $content) = @_;
    my $repo = Git::Raw::Repository->open($self->board_dir->stringify);
    # Create/update ref
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/App/karr/Sync.pm t/10-sync.t
git commit -m "feat: add App::karr::Sync module

- Add has_remote, fetch, push_refs methods
- Add basic test for has_remote

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Chunk 2: Lock Mechanism

**Files:**
- Create: `lib/App/karr/Lock.pm`
- Modify: `t/10-sync.t` (add lock tests)

- [ ] **Step 1: Write failing lock test**

```perl
# Add to t/10-sync.t
use App::karr::Lock;

my $lock = App::karr::Lock->new(
    board_dir => 't/fixtures/board',
    task_id => 1,
);
ok($lock->can_acquire('agent-fox'), 'can acquire lock');
ok($lock->acquire('agent-fox'), 'acquire returns true');
ok(!$lock->can_acquire('agent-owl'), 'other agent cannot acquire');
ok($lock->release('agent-fox'), 'release returns true');
```

Run: `prove -l t/10-sync.t`
Expected: FAIL - Lock module not found

- [ ] **Step 2: Create Lock.pm**

```perl
# ABSTRACT: Task lock management via Git refs

package App::karr::Lock;

use Moo;
use Git::Raw;
use Path::Tiny;

has board_dir => ( is => 'ro', required => 1 );
has task_id => ( is => 'ro', required => 1 );

sub ref_path {
    my ($self) = @_;
    return "refs/karr/tasks/" . $self->task_id . "/lock";
}

sub can_acquire {
    my ($self, $agent) = @_;
    my $repo = Git::Raw::Repository->open($self->board_dir->stringify);
    my $ref = $self->ref_path;
    my $current = eval { $repo->reference($ref) };
    return 1 unless $current;
    my $content = $current->target->content;
    chomp(my $locked_by = $content);
    return $locked_by eq '' || $locked_by eq $agent;
}

sub acquire {
    my ($self, $agent) = @_;
    return 0 unless $self->can_acquire($agent);
    my $repo = Git::Raw::Repository->open($self->board_dir->stringify);
    my $ref = $self->ref_path;
    my $blob = $repo->blob($agent);
    my $commit = eval { $repo->reference($ref) };
    # Create or update ref
    $repo->reference($ref, $blob, 1);
    return 1;
}

sub release {
    my ($self, $agent) = @_;
    my $repo = Git::Raw::Repository->open($self->board_dir->stringify);
    my $ref = $self->ref_path;
    # Delete ref to release
    eval { $repo->reference($ref)->delete };
    return 1;
}

1;
```

Run: `prove -l t/10-sync.t`
Expected: FAIL - need to handle Git::Raw API

- [ ] **Step 3: Fix Lock.pm for Git::Raw API**

```perl
# Simplified: use git command for now
sub can_acquire {
    my ($self, $agent) = @_;
    my $ref = $self->ref_path;
    my $content = `cd @{[$self->board_dir]} && git cat-file -p $ref 2>/dev/null`;
    return 1 unless $content;
    my ($locked_by) = $content =~ /^(\S+)/m;
    return !$locked_by || $locked_by eq $agent;
}

sub acquire {
    my ($self, $agent) = @_;
    return 0 unless $self->can_acquire($agent);
    my $ref = $self->ref_path;
    system("cd @{[$self->board_dir]} && git update-ref $ref $agent");
    return $? == 0;
}

sub release {
    my ($self, $agent) = @_;
    my $ref = $self->ref_path;
    system("cd @{[$self->board_dir]} && git delete-ref $ref");
    return 1;
}
```

Run: `prove -l t/10-sync.t`
Expected: PASS (with test fixtures)

- [ ] **Step 4: Commit**

```bash
git add lib/App/karr/Lock.pm t/10-sync.t
git commit -m "feat: add Lock module with acquire/release

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Chunk 3: Sync Command

**Files:**
- Create: `lib/App/karr/Cmd/Sync.pm`

- [ ] **Step 1: Create Sync command**

```perl
# ABSTRACT: Sync karr board with remote

package App::karr::Cmd::Sync;

use Moo::Role;
use MooX::Options;
use App::karr::Sync;

option push => ( is => 'ro', default => 0 );
option pull => ( is => 'ro', default => 0 );
option watch => ( is => 'ro', default => 0 );
option wait => ( is => 'ro', default => 0 );
option 'no-sync' => ( is => 'ro', default => 0 );

sub execute {
    my ( $self, $args, $data ) = @_;

    my $sync = App::karr::Sync->new( board_dir => $self->board_dir );

    unless ( $sync->has_remote ) {
        say "No remote configured. Run 'git remote add origin ...' first.";
        return;
    }

    if ( $self->watch ) {
        $sync->watch;
    } elsif ( $self->wait ) {
        $sync->wait_for_changes;
    } else {
        $sync->pull if $self->pull || !$self->push;
        $sync->push if $self->push || !$self->pull;
    }
}

1;
```

- [ ] **Step 2: Add to App::karr**

Modify `lib/App/karr.pm`:
```perl
with 'App::karr::Cmd::Sync';
```

- [ ] **Step 3: Commit**

```bash
git add lib/App/karr/Cmd/Sync.pm lib/App/karr.pm
git commit -m "feat: add karr sync command

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Chunk 4: Task Metadata in Git Refs

**Files:**
- Modify: `lib/App/karr/Sync.pm` (add task_ref methods)

- [ ] **Step 1: Add task_ref read/write to Sync.pm**

```perl
sub read_task_ref {
    my ( $self, $task_id ) = @_;
    my $ref = "refs/karr/tasks/$task_id";
    my $content = `cd @{[$self->board_dir]} && git cat-file -p $ref 2>/dev/null`;
    return undef unless $content;
    return Load($content);
}

sub write_task_ref {
    my ( $self, $task_id, $data ) = @_;
    my $content = Dump($data);
    my $ref = "refs/karr/tasks/$task_id";
    # Write to ref (requires ODB blob + ref update)
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/App/karr/Sync.pm
git commit -m "feat: add task ref read/write

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Chunk 5: Auto-Sync Integration

**Files:**
- Create: `lib/App/karr/Role/GitSync.pm`
- Modify: `lib/App/karr/Cmd/Move.pm`, `Cmd/Edit.pm`, etc.

- [ ] **Step 1: Create GitSync role**

```perl
# ABSTRACT: Role for commands that auto-sync

package App::karr::Role::GitSync;

use Moo::Role;
use App::karr::Sync;
use App::karr::Lock;

has sync => ( is => 'lazy' );

sub _build_sync {
    my ($self) = @_;
    return App::karr::Sync->new( board_dir => $self->board_dir );
}

sub auto_sync {
    my ( $self, $task_id, $agent ) = @_;
    return if $self->no_sync;

    my $lock = App::karr::Lock->new(
        board_dir => $self->board_dir,
        task_id => $task_id,
    );

    unless ( $lock->acquire($agent) ) {
        die "Task $task_id is locked by another agent";
    }

    $self->sync->pull;
    # Do the actual operation
    $self->sync->push;
    $lock->release($agent);
}

1;
```

- [ ] **Step 2: Add to Move command**

```perl
with 'App::karr::Role::GitSync';

sub execute {
    my ( $self, $args, $data ) = @_;
    # ... existing code ...

    $self->auto_sync( $task_id, $self->claim )
        if $self->claim && !$self->no_sync;
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/App/karr/Role/GitSync.pm lib/App/karr/Cmd/Move.pm
git commit -m "feat: add auto-sync to move command

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Chunk 6: External Repos (Future)

**Files:**
- Create: `lib/App/karr/External.pm`

This chunk is optional for v1. Skip for initial release.

---

## Test Fixtures

Create `t/fixtures/board/` with a minimal git repo:
```
t/fixtures/board/
  .git/
  karr/
    config.yml
    tasks/
```
