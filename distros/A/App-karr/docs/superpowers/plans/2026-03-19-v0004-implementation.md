# karr v0.004 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix Git ref sync to store task data as commit-wrapped blobs, add activity log, harden multi-agent coordination, and prepare for release.

**Architecture:** All git operations move to a safe `_git_cmd` helper (fork+exec, no shell interpolation). Refs wrap content in blob→tree→commit so `git push/fetch` works. Sync materializes refs to local files and serializes back. Lock integrates into Pick for atomic claiming.

**Tech Stack:** Perl 5, Moo, MooX::Cmd, MooX::Options, YAML::XS, Path::Tiny, JSON::MaybeXS, IPC::Open2, Time::Piece

**Spec:** `docs/superpowers/specs/2026-03-19-v0004-release-design.md`

---

## File Structure

### Modified Files

| File | Responsibility | Changes |
|------|---------------|---------|
| `lib/App/karr/Git.pm` | Git CLI wrapper | Full rewrite: `_git_cmd`, `_git_cmd_stdin`, commit-wrapped `write_ref`/`read_ref`, `save_task_ref`, `load_task_ref`, `list_task_refs`, fixed `is_repo`/`push`/`pull` |
| `lib/App/karr/Task.pm` | Task model | Refactor: `_parse_content`, `from_string`, refactored `from_file` |
| `lib/App/karr/Lock.pm` | Task locking | Refactor: accept `git` object instead of creating own |
| `lib/App/karr/Role/BoardAccess.pm` | Shared board ops | Add: `sync_before`, `sync_after`, `_materialize_from_refs`, `_serialize_to_refs`, `append_log` |
| `lib/App/karr/Cmd/Sync.pm` | Sync command | Rewrite: full sync with materialization |
| `lib/App/karr/Cmd/Pick.pm` | Pick command | Rewrite: Lock integration with immediate push |
| `lib/App/karr/Cmd/List.pm` | List command | Add: `--claimed-by` filter |
| `lib/App/karr/Cmd/Init.pm` | Init command | Remove `.gitignore` manipulation |
| `lib/App/karr/Cmd/Create.pm` | Create command | Remove `_sync_after`, use role's `sync_before`/`sync_after` |
| `lib/App/karr/Cmd/Move.pm` | Move command | Same |
| `lib/App/karr/Cmd/Edit.pm` | Edit command | Same |
| `lib/App/karr/Cmd/Delete.pm` | Delete command | Same |
| `lib/App/karr/Cmd/Archive.pm` | Archive command | Same |
| `lib/App/karr/Cmd/Handoff.pm` | Handoff command | Remove `_sync_after`, `_parse_timeout`, `_claim_expired`; use shared role |
| `lib/App/karr/Role/ClaimTimeout.pm` | Shared claim timeout logic | New: `_parse_timeout`, `_claim_expired` consumed by Pick + Handoff |
| `Dockerfile` | Docker image | Add git identity ENV vars |
| `Changes` | Changelog | Remove "experimental", add v0.004 entries |

### New Files

| File | Responsibility |
|------|---------------|
| `lib/App/karr/Cmd/Log.pm` | Activity log command |
| `t/13-git-refs.t` | Git ref roundtrip tests (commit-wrapped write/read) |
| `t/14-task-parse.t` | `from_string`/`from_file` parity tests |
| `t/15-sync.t` | Materialize/serialize roundtrip tests |
| `t/16-pick-lock.t` | Pick with Lock integration test |
| `t/17-log.t` | Log append + read tests |
| `t/18-list-filter.t` | `--claimed-by` filter test |
| `t/19-git-push-fetch.t` | Push/fetch between two repos test |
| `t/20-next-id-collision.t` | Config next_id collision prevention test |

---

## Chunk 1: Git.pm Foundation

All other changes depend on Git.pm having safe execution and commit-wrapped refs.

### Task 1: Rewrite Git.pm with safe execution

**Files:**
- Modify: `lib/App/karr/Git.pm`
- Test: `t/13-git-refs.t`

- [ ] **Step 1: Write failing test for `_git_cmd`**

```perl
# t/13-git-refs.t
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use App::karr::Git;

# Create a temporary git repo
my $dir = tempdir( CLEANUP => 1 );
system("git init '$dir' 2>/dev/null");
system("git -C '$dir' config user.email 'test\@test.com'");
system("git -C '$dir' config user.name 'Test'");

my $git = App::karr::Git->new( dir => $dir );

# Test is_repo
ok $git->is_repo, 'detects git repo';

# Test is_repo from subdirectory
my $subdir = "$dir/karr";
mkdir $subdir;
my $sub_git = App::karr::Git->new( dir => $subdir );
ok $sub_git->is_repo, 'detects git repo from subdirectory';

# Test non-repo
my $non_repo = tempdir( CLEANUP => 1 );
my $non_git = App::karr::Git->new( dir => $non_repo );
ok !$non_git->is_repo, 'non-repo returns false';

done_testing;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `prove -l t/13-git-refs.t`
Expected: FAIL (is_repo uses old `.git` child check, subdirectory fails)

- [ ] **Step 3: Implement `_git_cmd`, `_git_cmd_stdin`, and fixed `is_repo`**

Replace the entire `Git.pm` with safe execution:

```perl
# ABSTRACT: Git operations for karr sync (via CLI)

package App::karr::Git;

use strict;
use warnings;
use Path::Tiny qw( path );
use IPC::Open2;

sub new {
    my ( $class, %args ) = @_;
    return bless {
        dir => $args{dir} // '.',
    }, $class;
}

sub dir {
    my ($self) = @_;
    return path( $self->{dir} );
}

sub _git_cmd {
    my ($self, @cmd) = @_;
    my $dir = $self->dir->stringify;
    my $pid = open(my $fh, '-|');
    if (!defined $pid) {
        die "fork failed: $!";
    }
    if (!$pid) {
        open(STDERR, '>', '/dev/null');
        chdir $dir or die "chdir $dir: $!";
        exec('git', @cmd) or die "exec git: $!";
    }
    my $output = do { local $/; <$fh> };
    close $fh;
    my $ok = $? == 0;
    chomp $output if defined $output;
    return wantarray ? ($output, $ok) : $output;
}

sub _git_cmd_stdin {
    my ($self, $input, @cmd) = @_;
    my $dir = $self->dir->stringify;
    my $pid = open2(my $out_fh, my $in_fh, 'git', '-C', $dir, @cmd);
    print $in_fh $input;
    close $in_fh;
    my $output = do { local $/; <$out_fh> };
    waitpid($pid, 0);
    chomp $output if defined $output;
    return $output;
}

sub is_repo {
    my ($self) = @_;
    my ($out, $ok) = $self->_git_cmd('rev-parse', '--show-toplevel');
    return $ok;
}

sub git_user_email {
    my ($self) = @_;
    my ($email, $ok) = $self->_git_cmd('config', '--get', 'user.email');
    return $ok ? $email : '';
}

sub git_user_name {
    my ($self) = @_;
    my ($name, $ok) = $self->_git_cmd('config', '--get', 'user.name');
    return $ok ? $name : '';
}

sub git_user_identity {
    my ($self) = @_;
    my $name = $self->git_user_name;
    my $email = $self->git_user_email;
    return "$name <$email>" if $name && $email;
    return $email || $name || '';
}

sub write_ref {
    my ( $self, $ref, $content ) = @_;

    # Create blob from content via stdin
    my $blob = $self->_git_cmd_stdin($content, 'hash-object', '-w', '--stdin');
    return unless $blob;

    # Create tree containing the blob as "data"
    my $tree_line = sprintf("100644 blob %s\tdata", $blob);
    my $tree = $self->_git_cmd_stdin($tree_line, 'mktree');
    return unless $tree;

    # Create commit wrapping the tree
    my $commit = $self->_git_cmd('commit-tree', $tree, '-m', 'karr ref update');
    return unless $commit;

    # Point ref at commit
    $self->_git_cmd('update-ref', $ref, $commit);
    return 1;
}

sub read_ref {
    my ( $self, $ref ) = @_;
    my ($content, $ok) = $self->_git_cmd('cat-file', '-p', "$ref:data");
    return $ok ? $content : '';
}

sub delete_ref {
    my ( $self, $ref ) = @_;
    $self->_git_cmd('update-ref', '-d', $ref);
    return 1;
}

sub fetch {
    my ( $self, $remote ) = @_;
    $remote //= 'origin';
    my (undef, $ok) = $self->_git_cmd('fetch', $remote);
    return $ok;
}

sub push {
    my ( $self, $remote, $refspec ) = @_;
    $remote //= 'origin';
    $refspec //= 'refs/karr/*:refs/karr/*';
    my (undef, $ok) = $self->_git_cmd('push', $remote, $refspec);
    return $ok;
}

sub pull {
    my ( $self, $remote ) = @_;
    $remote //= 'origin';
    my (undef, $ok) = $self->_git_cmd('fetch', $remote, 'refs/karr/*:refs/karr/*');
    return $ok;
}

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
    require App::karr::Task;
    return App::karr::Task->from_string($content);
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

1;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `prove -l t/13-git-refs.t`
Expected: PASS

- [ ] **Step 5: Extend test for commit-wrapped write_ref/read_ref roundtrip**

Append to `t/13-git-refs.t`:

```perl
# Test write_ref / read_ref roundtrip with commit-wrapped refs
my $test_content = "---\nid: 1\ntitle: Test task\n---\n\nBody here.\n";
ok $git->write_ref('refs/karr/test/data', $test_content), 'write_ref succeeds';

my $read_back = $git->read_ref('refs/karr/test/data');
is $read_back, $test_content, 'read_ref returns original content';

# Verify the ref points to a commit (not a blob)
my $obj_type = $git->_git_cmd('cat-file', '-t', 'refs/karr/test/data');
is $obj_type, 'commit', 'ref points to a commit object';

# Test read of nonexistent ref
my $missing = $git->read_ref('refs/karr/nonexistent');
is $missing, '', 'missing ref returns empty string';

# Test delete_ref
$git->delete_ref('refs/karr/test/data');
my $after_delete = $git->read_ref('refs/karr/test/data');
is $after_delete, '', 'deleted ref returns empty string';
```

- [ ] **Step 6: Run test to verify it passes**

Run: `prove -l t/13-git-refs.t`
Expected: PASS

- [ ] **Step 7: Run all existing tests to verify no regressions**

Run: `prove -l t/`
Expected: All pass (Git.pm interface is backward-compatible for existing callers)

- [ ] **Step 8: Commit**

```bash
git add lib/App/karr/Git.pm t/13-git-refs.t
git commit -m "feat: rewrite Git.pm with safe execution and commit-wrapped refs"
```

---

### Task 2: Refactor Task.pm parsing

**Files:**
- Modify: `lib/App/karr/Task.pm`
- Test: `t/14-task-parse.t`

- [ ] **Step 1: Write failing test for `from_string`**

```perl
# t/14-task-parse.t
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use App::karr::Task;

my $content = <<'MD';
---
id: 42
title: Test from_string
status: todo
priority: high
class: standard
created: 2026-03-19T10:00:00Z
updated: 2026-03-19T10:00:00Z
---

This is the body.
MD

# Test from_string
my $task = App::karr::Task->from_string($content);
is $task->id, 42, 'from_string: id';
is $task->title, 'Test from_string', 'from_string: title';
is $task->status, 'todo', 'from_string: status';
is $task->body, 'This is the body.', 'from_string: body';
ok !$task->has_file_path, 'from_string: no file_path';

# Test from_file gives same result
my $dir = tempdir( CLEANUP => 1 );
my $file = path($dir)->child('042-test-from-string.md');
$file->spew_utf8($content);

my $file_task = App::karr::Task->from_file($file);
is $file_task->id, $task->id, 'from_file matches from_string: id';
is $file_task->title, $task->title, 'from_file matches from_string: title';
is $file_task->body, $task->body, 'from_file matches from_string: body';
ok $file_task->has_file_path, 'from_file: has file_path';

done_testing;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `prove -l t/14-task-parse.t`
Expected: FAIL (`from_string` method does not exist yet)

- [ ] **Step 3: Implement `_parse_content` and `from_string`, refactor `from_file`**

In `lib/App/karr/Task.pm`, replace the existing `from_file` with:

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

- [ ] **Step 4: Run test to verify it passes**

Run: `prove -l t/14-task-parse.t`
Expected: PASS

- [ ] **Step 5: Run all existing tests for regressions**

Run: `prove -l t/`
Expected: All pass (from_file behavior unchanged)

- [ ] **Step 6: Commit**

```bash
git add lib/App/karr/Task.pm t/14-task-parse.t
git commit -m "refactor: extract _parse_content, add from_string to Task"
```

---

### Task 3: Complete Git.pm task ref tests

**Files:**
- Modify: `t/13-git-refs.t`

Now that Task.pm has `from_string`, complete the task ref roundtrip tests.

- [ ] **Step 1: Add save/load/list task ref tests**

Append to `t/13-git-refs.t`:

```perl
use App::karr::Task;

# Test save_task_ref / load_task_ref roundtrip
my $task = App::karr::Task->new(
    id       => 1,
    title    => 'Test save ref',
    status   => 'todo',
    priority => 'high',
    class    => 'standard',
    body     => 'Some body text',
);

$git->save_task_ref($task);

my $loaded = $git->load_task_ref(1);
ok $loaded, 'load_task_ref returns task';
is $loaded->id, 1, 'loaded task id';
is $loaded->title, 'Test save ref', 'loaded task title';
is $loaded->body, 'Some body text', 'loaded task body';

# Test list_task_refs
my $task2 = App::karr::Task->new(
    id => 2, title => 'Second task', status => 'backlog',
    priority => 'medium', class => 'standard',
);
$git->save_task_ref($task2);

my @ids = $git->list_task_refs;
is_deeply \@ids, [1, 2], 'list_task_refs returns sorted IDs';

# Test load nonexistent
my $missing_task = $git->load_task_ref(999);
ok !$missing_task, 'load_task_ref returns undef for missing';
```

- [ ] **Step 2: Run test**

Run: `prove -l t/13-git-refs.t`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add t/13-git-refs.t
git commit -m "test: add task ref roundtrip tests"
```

---

## Chunk 2: Sync Infrastructure

### Task 4: Add sync helpers to Role::BoardAccess

**Files:**
- Modify: `lib/App/karr/Role/BoardAccess.pm`
- Test: `t/15-sync.t`

- [ ] **Step 1: Write failing test for materialize/serialize roundtrip**

```perl
# t/15-sync.t
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::XS qw( DumpFile );
use App::karr::Git;
use App::karr::Task;

# Create a git repo with a karr board
my $repo = tempdir( CLEANUP => 1 );
system("git init '$repo' 2>/dev/null");
system("git -C '$repo' config user.email 'test\@test.com'");
system("git -C '$repo' config user.name 'Test'");

my $board = path($repo)->child('karr');
$board->mkpath;
$board->child('tasks')->mkpath;

# Create a default config
my $config = {
    version => 1,
    board => { name => 'Test Board' },
    tasks_dir => 'tasks',
    statuses => ['backlog', 'todo', 'in-progress', 'review', 'done', 'archived'],
    priorities => ['low', 'medium', 'high', 'critical'],
    next_id => 3,
    defaults => { status => 'backlog', priority => 'medium', class => 'standard' },
};
DumpFile($board->child('config.yml')->stringify, $config);

# Create two task files locally
my $t1 = App::karr::Task->new(
    id => 1, title => 'Local task one', status => 'todo',
    priority => 'high', class => 'standard', body => 'Body one',
);
$t1->save($board->child('tasks'));

my $t2 = App::karr::Task->new(
    id => 2, title => 'Local task two', status => 'backlog',
    priority => 'medium', class => 'standard',
);
$t2->save($board->child('tasks'));

# Serialize local files to refs
my $git = App::karr::Git->new( dir => $repo );
for my $file ($board->child('tasks')->children(qr/\.md$/)) {
    my $task = App::karr::Task->from_file($file);
    $git->save_task_ref($task);
}
$git->write_ref('refs/karr/config', $board->child('config.yml')->slurp_utf8);

# Verify refs exist
my @ids = $git->list_task_refs;
is_deeply \@ids, [1, 2], 'serialize: both tasks in refs';

# Delete local files to simulate fresh materialization
for my $f ($board->child('tasks')->children(qr/\.md$/)) {
    $f->remove;
}
my @remaining = $board->child('tasks')->children(qr/\.md$/);
is scalar @remaining, 0, 'local files cleared';

# Materialize from refs
for my $id (@ids) {
    my $task = $git->load_task_ref($id);
    $task->save($board->child('tasks'));
}

# Verify files recreated
my @files = sort $board->child('tasks')->children(qr/\.md$/);
is scalar @files, 2, 'materialize: two files recreated';

# Verify content matches
my $reloaded = App::karr::Task->from_file($files[0]);
is $reloaded->id, 1, 'materialized task 1: id';
is $reloaded->title, 'Local task one', 'materialized task 1: title';
is $reloaded->body, 'Body one', 'materialized task 1: body';

done_testing;
```

- [ ] **Step 2: Run test to verify it passes (uses already-implemented Git methods)**

Run: `prove -l t/15-sync.t`
Expected: PASS (this tests the pattern, not the role methods yet)

- [ ] **Step 3: Implement sync helpers in BoardAccess role**

Add to `lib/App/karr/Role/BoardAccess.pm`:

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
    if ($tasks_dir->exists) {
        for my $file ($tasks_dir->children(qr/\.md$/)) {
            require App::karr::Task;
            my $task = App::karr::Task->from_file($file);
            my $ref_content = $git->read_ref("refs/karr/tasks/" . $task->id . "/data");
            unless ($ref_content) {
                $git->save_task_ref($task);
                push @ids, $task->id unless grep { $_ == $task->id } @ids;
            }
        }

        # Clear all .md files to avoid stale entries
        for my $old_file ($tasks_dir->children(qr/\.md$/)) {
            $old_file->remove;
        }
    }

    # Materialize from refs
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
    my $config_file = $self->board_dir->child('config.yml');
    if ($config_file->exists) {
        $git->write_ref('refs/karr/config', $config_file->slurp_utf8);
    }
}

sub append_log {
    my ($self, $git, %entry) = @_;
    require JSON::MaybeXS;
    # POSIX::strftime avoids the Time::Piece import issue (require vs use)
    require POSIX;
    $entry{ts} //= POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime());
    my $identity = $git->git_user_email || 'unknown';
    $identity =~ s/[^a-zA-Z0-9._-]/_/g;
    my $ref = "refs/karr/log/$identity";
    my $existing = $git->read_ref($ref);
    my $line = JSON::MaybeXS::encode_json(\%entry);
    my $new = $existing ? "$existing\n$line" : $line;
    $git->write_ref($ref, $new);
}
```

- [ ] **Step 4: Run all tests**

Run: `prove -l t/`
Expected: All pass

- [ ] **Step 5: Commit**

```bash
git add lib/App/karr/Role/BoardAccess.pm t/15-sync.t
git commit -m "feat: add sync helpers (materialize/serialize/log) to BoardAccess"
```

---

### Task 5: Rewrite Sync.pm

**Files:**
- Modify: `lib/App/karr/Cmd/Sync.pm`

- [ ] **Step 1: Rewrite Sync.pm to use BoardAccess sync helpers**

```perl
# ABSTRACT: Sync karr board with remote

package App::karr::Cmd::Sync;

use Moo;
use MooX::Cmd;
use feature 'say';
use MooX::Options (
    usage_string => 'USAGE: karr sync [--push] [--pull]',
);
use App::karr::Role::BoardAccess;

with 'App::karr::Role::BoardAccess';

option push => ( is => 'ro', default => 0, doc => 'Push refs to remote' );
option pull => ( is => 'ro', default => 0, doc => 'Pull refs from remote' );

sub execute {
    my ( $self, $args, $data ) = @_;

    require App::karr::Git;
    my $git = App::karr::Git->new( dir => $self->board_dir->parent->stringify );

    unless ( $git->is_repo ) {
        say "Not a git repository. Skipping sync.";
        return;
    }

    my $email = $git->git_user_email;
    my $name = $git->git_user_name;
    unless ($email) {
        say q(No git user.email configured. Run: git config --global user.email 'you@example.com');
        return;
    }

    say "User: $name <$email>";

    my $push_only = $self->push && !$self->pull;
    my $pull_only = $self->pull && !$self->push;

    # Pull + materialize
    unless ($push_only) {
        say "Pulling refs/karr/ from remote...";
        $git->pull;
        say "Materializing board from refs...";
        $self->_materialize_from_refs($git);
    }

    # Serialize + push
    unless ($pull_only) {
        say "Serializing board to refs...";
        $self->_serialize_to_refs($git);
        say "Pushing refs/karr/ to remote...";
        $git->push;
    }

    say "Done.";
}

1;
```

- [ ] **Step 2: Run all tests**

Run: `prove -l t/`
Expected: All pass

- [ ] **Step 3: Commit**

```bash
git add lib/App/karr/Cmd/Sync.pm
git commit -m "feat: rewrite Sync.pm with full materialization"
```

---

### Task 6: Remove `_sync_after` from 7 commands, use role methods

**Files:**
- Modify: `lib/App/karr/Cmd/Create.pm`
- Modify: `lib/App/karr/Cmd/Move.pm`
- Modify: `lib/App/karr/Cmd/Edit.pm`
- Modify: `lib/App/karr/Cmd/Delete.pm`
- Modify: `lib/App/karr/Cmd/Archive.pm`
- Modify: `lib/App/karr/Cmd/Handoff.pm`
- Modify: `lib/App/karr/Cmd/Pick.pm` (Pick gets full rewrite in Task 8, just remove _sync_after for now)

For each of the 7 commands, the change is identical:

1. Delete the `_sync_after` sub
2. Replace `$self->_sync_after if -d '.git';` at start of `execute` with `$self->sync_before;`
3. Add `$self->sync_after;` before return at end of `execute`

**Note on logging:** Commands that modify tasks should call `$self->append_log(...)` between their operation and `sync_after`. For example, in Create.pm after `$task->save`:

```perl
$task->save($self->tasks_dir);
# Log the action
my $git = App::karr::Git->new(dir => $self->board_dir->parent->stringify);
$self->append_log($git, agent => 'user', action => 'create', task_id => $task->id, detail => $task->status) if $git->is_repo;
$self->sync_after;
```

The same pattern applies to Move, Edit, Delete, Archive, Handoff. The `agent` field should use `$self->claim` if available, or `$git->git_user_email`, or `'user'` as fallback.

- [ ] **Step 1: Update Create.pm**

Remove `_sync_after` sub (lines 70-77). Replace line 83 `$self->_sync_after if -d '.git';` with `$self->sync_before;`. Add `$self->sync_after;` after the printf at line 110.

- [ ] **Step 2: Update Move.pm**

Remove `_sync_after` sub (lines 33-40). Replace line 46 with `$self->sync_before;`. Add `$self->sync_after;` before the json output block.

- [ ] **Step 3: Update Edit.pm**

Remove `_sync_after` sub (lines 93-100). Replace line 106 with `$self->sync_before;`. Add `$self->sync_after;` before the json output block.

- [ ] **Step 4: Update Delete.pm**

Remove `_sync_after` sub (lines 22-29). Replace line 35 with `$self->sync_before;`. Add `$self->sync_after;` before the json output block.

- [ ] **Step 5: Update Archive.pm**

Remove `_sync_after` sub (lines 16-23). Replace line 29 with `$self->sync_before;`. Add `$self->sync_after;` before the json output block.

- [ ] **Step 6a: Create ClaimTimeout role**

Create `lib/App/karr/Role/ClaimTimeout.pm` to share `_parse_timeout` and `_claim_expired` between Pick and Handoff:

```perl
# ABSTRACT: Shared claim timeout logic

package App::karr::Role::ClaimTimeout;

use Moo::Role;
use Time::Piece;

sub _parse_timeout {
    my ($self, $timeout_str) = @_;
    return 3600 unless $timeout_str;
    if ($timeout_str =~ /^(\d+)h$/) { return $1 * 3600; }
    if ($timeout_str =~ /^(\d+)m$/) { return $1 * 60; }
    return 3600;
}

sub _claim_expired {
    my ($self, $task, $timeout_secs) = @_;
    return 0 unless $task->has_claimed_at;
    my $claimed = eval { Time::Piece->strptime($task->claimed_at =~ s/Z$//r, '%Y-%m-%dT%H:%M:%S') };
    return 0 unless $claimed;
    return (gmtime() - $claimed) > $timeout_secs;
}

1;
```

- [ ] **Step 6b: Update Handoff.pm**

Remove `_sync_after` sub. Remove `_parse_timeout` and `_claim_expired`. Add `with 'App::karr::Role::ClaimTimeout';` to the `with` line (alongside BoardAccess and Output). Replace sync call with `$self->sync_before;`. Add `$self->sync_after;` after save.

- [ ] **Step 7: Update Pick.pm (minimal — full rewrite in Task 8)**

Remove `_sync_after` sub. Remove `_parse_timeout` and `_claim_expired`. Add `with 'App::karr::Role::ClaimTimeout';`. Replace sync call with `$self->sync_before;`. Add `$self->sync_after;` after the json output block.

- [ ] **Step 8: Run all tests**

Run: `prove -l t/`
Expected: All pass

- [ ] **Step 9: Commit**

```bash
git add lib/App/karr/Cmd/Create.pm lib/App/karr/Cmd/Move.pm lib/App/karr/Cmd/Edit.pm \
  lib/App/karr/Cmd/Delete.pm lib/App/karr/Cmd/Archive.pm lib/App/karr/Cmd/Handoff.pm \
  lib/App/karr/Cmd/Pick.pm
git commit -m "refactor: replace _sync_after with role sync_before/sync_after"
```

---

## Chunk 3: Lock + Pick

### Task 7: Refactor Lock.pm to accept Git object

**Files:**
- Modify: `lib/App/karr/Lock.pm`

- [ ] **Step 1: Refactor Lock.pm constructor**

```perl
# ABSTRACT: Lock management via Git refs

package App::karr::Lock;

use strict;
use warnings;

sub new {
    my ( $class, %args ) = @_;
    my $git = $args{git};
    unless ($git) {
        require App::karr::Git;
        $git = App::karr::Git->new( dir => $args{dir} // '.' );
    }
    return bless {
        git     => $git,
        task_id => $args{task_id},
    }, $class;
}

sub task_id { shift->{task_id} }
sub git     { shift->{git} }

sub ref_name {
    my ( $self, $task_id ) = @_;
    $task_id //= $self->task_id;
    return "refs/karr/tasks/$task_id/lock";
}

sub get {
    my ( $self, $task_id ) = @_;
    my $ref = $self->ref_name($task_id);
    my $content = $self->git->read_ref($ref);
    return $content;
}

sub acquire {
    my ( $self, $task_id, $email ) = @_;
    $task_id //= $self->task_id;
    my $ref = $self->ref_name($task_id);

    my $current = $self->get($task_id);
    if ( $current && $current ne $email ) {
        return ( 0, "locked by $current" );
    }

    $self->git->write_ref( $ref, $email );
    return ( 1, "acquired" );
}

sub release {
    my ( $self, $task_id, $email ) = @_;
    $task_id //= $self->task_id;
    my $ref = $self->ref_name($task_id);

    my $current = $self->get($task_id);
    if ( $current && $current ne $email ) {
        return ( 0, "locked by $current" );
    }

    $self->git->delete_ref($ref);
    return ( 1, "released" );
}

1;
```

- [ ] **Step 2: Run existing lock/git tests**

Run: `prove -l t/11-git-impl.t t/13-git-refs.t`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add lib/App/karr/Lock.pm
git commit -m "refactor: Lock accepts pre-built Git object"
```

---

### Task 8: Rewrite Pick.pm with Lock integration

**Files:**
- Modify: `lib/App/karr/Cmd/Pick.pm`
- Test: `t/16-pick-lock.t`

- [ ] **Step 1: Write test for Pick claiming different tasks sequentially**

```perl
# t/16-pick-lock.t
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::XS qw( DumpFile );
use App::karr::Task;
use App::karr::Git;
use App::karr::Lock;

# Set up a git repo with a karr board
my $repo = tempdir( CLEANUP => 1 );
system("git init '$repo' 2>/dev/null");
system("git -C '$repo' config user.email 'test\@test.com'");
system("git -C '$repo' config user.name 'Test'");

my $board = path($repo)->child('karr');
$board->mkpath;
$board->child('tasks')->mkpath;

my $config = {
    version => 1,
    board => { name => 'Test' },
    tasks_dir => 'tasks',
    statuses => ['backlog', 'todo', 'in-progress', 'done', 'archived'],
    priorities => ['low', 'medium', 'high', 'critical'],
    next_id => 3,
    claim_timeout => '1h',
    defaults => { status => 'backlog', priority => 'medium', class => 'standard' },
};
DumpFile($board->child('config.yml')->stringify, $config);

# Create two tasks
for my $i (1, 2) {
    App::karr::Task->new(
        id => $i, title => "Task $i", status => 'todo',
        priority => 'high', class => 'standard',
    )->save($board->child('tasks'));
}

my $git = App::karr::Git->new( dir => $repo );
my $lock = App::karr::Lock->new( git => $git );

# Agent A acquires lock on task 1
my ($ok1, $msg1) = $lock->acquire(1, 'agent-a@test.com');
ok $ok1, 'agent A acquires lock on task 1';

# Agent B tries to acquire same lock — fails
my ($ok2, $msg2) = $lock->acquire(1, 'agent-b@test.com');
ok !$ok2, 'agent B cannot lock task 1';
like $msg2, qr/locked by/, 'correct rejection message';

# Agent B acquires lock on task 2
my ($ok3, $msg3) = $lock->acquire(2, 'agent-b@test.com');
ok $ok3, 'agent B acquires lock on task 2';

# Agent A releases lock on task 1
my ($ok4, $msg4) = $lock->release(1, 'agent-a@test.com');
ok $ok4, 'agent A releases lock on task 1';

# Now anyone can lock task 1
my ($ok5, $msg5) = $lock->acquire(1, 'agent-b@test.com');
ok $ok5, 'agent B can now lock task 1 after release';

# Clean up
$lock->release(1, 'agent-b@test.com');
$lock->release(2, 'agent-b@test.com');

done_testing;
```

- [ ] **Step 2: Run test**

Run: `prove -l t/16-pick-lock.t`
Expected: PASS

- [ ] **Step 3: Rewrite Pick.pm with Lock integration**

Replace Pick.pm's execute method to use Lock before claiming. The lock acquire/release wraps the claim operation. In non-repo contexts (no git), skip locking.

Key changes to `execute`:
- After filtering/sorting tasks, loop with lock acquisition
- Use `$self->sync_before` at start instead of `_sync_after`
- After save, call `$self->sync_after`
- Lock acquire before claim, release after sync_after

```perl
sub execute {
    my ($self, $args_ref, $chain_ref) = @_;

    $self->sync_before;

    my $config = App::karr::Config->new(
        file => $self->board_dir->child('config.yml'),
    );

    my @tasks = $self->load_tasks;

    # [existing filter logic stays the same: status, claimed, blocked, tags, sort]

    unless (@tasks) {
        print "No available tasks to pick.\n";
        return;
    }

    # Try to lock + claim
    require App::karr::Git;
    my $git = App::karr::Git->new(dir => $self->board_dir->parent->stringify);
    my $use_lock = $git->is_repo;
    my $lock;
    if ($use_lock) {
        require App::karr::Lock;
        $lock = App::karr::Lock->new(git => $git);
    }
    my $email = $use_lock ? ($git->git_user_email || $self->claim) : $self->claim;

    my $picked;
    for my $task (@tasks) {
        if ($use_lock) {
            my ($ok, $msg) = $lock->acquire($task->id, $email);
            next unless $ok;
        }

        $task->claimed_by($self->claim);
        $task->claimed_at(gmtime->datetime . 'Z');

        if ($self->move) {
            $task->status($self->move);
            if ($self->move eq 'in-progress' && !$task->has_started) {
                $task->started(gmtime->strftime('%Y-%m-%d'));
            }
        }

        $task->save;
        $picked = $task;
        last;
    }

    unless ($picked) {
        print "No available tasks to pick (all locked).\n";
        return;
    }

    # Serialize + push BEFORE releasing lock (spec ordering: sync then release)
    $self->sync_after;

    # Append log entry
    if ($use_lock) {
        $self->append_log($git,
            agent   => $self->claim,
            action  => 'pick',
            task_id => $picked->id,
            detail  => $picked->status,
        );
    }

    # Release lock AFTER sync is complete
    if ($use_lock) {
        $lock->release($picked->id, $email);
        $git->push('origin', $lock->ref_name($picked->id) . ':' . $lock->ref_name($picked->id));
    }

    if ($self->json) {
        my $data = $picked->to_frontmatter;
        $data->{body} = $picked->body if $picked->body;
        $self->print_json($data);
        return;
    }

    printf "Picked task %d: %s (claimed by %s)\n", $picked->id, $picked->title, $self->claim;
    printf "Status: %s | Priority: %s | Class: %s\n", $picked->status, $picked->priority, $picked->class;
    if ($picked->body) {
        print "\n" . $picked->body . "\n";
    }
}
```

- [ ] **Step 4: Run all tests**

Run: `prove -l t/`
Expected: All pass

- [ ] **Step 5: Commit**

```bash
git add lib/App/karr/Cmd/Pick.pm t/16-pick-lock.t
git commit -m "feat: Pick uses Lock for atomic task claiming"
```

---

## Chunk 4: Log + List Filter

### Task 9: Add `--claimed-by` filter to List

**Files:**
- Modify: `lib/App/karr/Cmd/List.pm`
- Test: `t/18-list-filter.t`

- [ ] **Step 1: Write failing test**

```perl
# t/18-list-filter.t
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::XS qw( DumpFile );
use App::karr::Task;

my $dir = tempdir( CLEANUP => 1 );
my $board = path($dir)->child('karr');
$board->mkpath;
$board->child('tasks')->mkpath;

DumpFile($board->child('config.yml')->stringify, {
    version => 1, tasks_dir => 'tasks',
    statuses => ['backlog', 'todo', 'in-progress', 'done', 'archived'],
    priorities => ['low', 'medium', 'high', 'critical'],
    next_id => 4,
    defaults => { status => 'backlog', priority => 'medium', class => 'standard' },
});

App::karr::Task->new(
    id => 1, title => 'Claimed by A', status => 'in-progress',
    priority => 'high', class => 'standard',
    claimed_by => 'agent-a',
)->save($board->child('tasks'));

App::karr::Task->new(
    id => 2, title => 'Claimed by B', status => 'in-progress',
    priority => 'medium', class => 'standard',
    claimed_by => 'agent-b',
)->save($board->child('tasks'));

App::karr::Task->new(
    id => 3, title => 'Unclaimed', status => 'todo',
    priority => 'low', class => 'standard',
)->save($board->child('tasks'));

# Test filtering logic directly
my @all_tasks = map { App::karr::Task->from_file($_) }
    sort $board->child('tasks')->children(qr/\.md$/);

# Filter by claimed_by
my @claimed_a = grep { $_->has_claimed_by && $_->claimed_by eq 'agent-a' } @all_tasks;
is scalar @claimed_a, 1, 'one task claimed by agent-a';
is $claimed_a[0]->id, 1, 'correct task for agent-a';

done_testing;
```

- [ ] **Step 2: Run test (passes — tests filter logic, not CLI option yet)**

Run: `prove -l t/18-list-filter.t`
Expected: PASS

- [ ] **Step 3: Add `--claimed-by` option to List.pm**

Add after the `search` option:

```perl
option claimed_by => (
    is => 'ro',
    format => 's',
    doc => 'Filter by claim owner',
);
```

Add to `_filter` method, after the `search` block:

```perl
if ($self->claimed_by) {
    @filtered = grep { $_->has_claimed_by && $_->claimed_by eq $self->claimed_by } @filtered;
}
```

- [ ] **Step 4: Run all tests**

Run: `prove -l t/`
Expected: All pass

- [ ] **Step 5: Commit**

```bash
git add lib/App/karr/Cmd/List.pm t/18-list-filter.t
git commit -m "feat: add --claimed-by filter to list command"
```

---

### Task 10: Implement Log command

**Files:**
- Create: `lib/App/karr/Cmd/Log.pm`
- Test: `t/17-log.t`

- [ ] **Step 1: Write failing test for log append and read**

```perl
# t/17-log.t
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use JSON::MaybeXS qw( decode_json );
use App::karr::Git;

my $repo = tempdir( CLEANUP => 1 );
system("git init '$repo' 2>/dev/null");
system("git -C '$repo' config user.email 'agent-a\@test.com'");
system("git -C '$repo' config user.name 'Agent A'");

my $git = App::karr::Git->new( dir => $repo );

# Append two log entries under agent-a's ref
my $ref_a = 'refs/karr/log/agent-a_test.com';
my $line1 = '{"ts":"2026-03-19T10:00:00Z","agent":"agent-a","action":"pick","task_id":1}';
$git->write_ref($ref_a, $line1);

my $line2 = '{"ts":"2026-03-19T10:05:00Z","agent":"agent-a","action":"handoff","task_id":1}';
$git->write_ref($ref_a, "$line1\n$line2");

# Append one entry under agent-b's ref
my $ref_b = 'refs/karr/log/agent-b_test.com';
my $line3 = '{"ts":"2026-03-19T10:02:00Z","agent":"agent-b","action":"pick","task_id":2}';
$git->write_ref($ref_b, $line3);

# Read all log refs
my $output_a = $git->read_ref($ref_a);
my $output_b = $git->read_ref($ref_b);

ok $output_a, 'agent-a log ref exists';
ok $output_b, 'agent-b log ref exists';

# Parse and merge
my @entries;
for my $log_content ($output_a, $output_b) {
    for my $line (split /\n/, $log_content) {
        push @entries, decode_json($line);
    }
}

@entries = sort { $a->{ts} cmp $b->{ts} } @entries;
is scalar @entries, 3, 'three total log entries';
is $entries[0]{action}, 'pick', 'first entry (by time): pick by agent-a';
is $entries[1]{action}, 'pick', 'second entry: pick by agent-b';
is $entries[2]{action}, 'handoff', 'third entry: handoff by agent-a';

done_testing;
```

- [ ] **Step 2: Run test**

Run: `prove -l t/17-log.t`
Expected: PASS

- [ ] **Step 3: Create Log.pm command**

```perl
# ABSTRACT: Show activity log

package App::karr::Cmd::Log;

use Moo;
use MooX::Cmd;
use MooX::Options (
    usage_string => 'USAGE: karr log [--agent NAME] [--task ID] [--last N] [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use JSON::MaybeXS qw( decode_json );

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';

option agent => (
    is => 'ro',
    format => 's',
    doc => 'Filter by agent name',
);

option task => (
    is => 'ro',
    format => 'i',
    doc => 'Filter by task ID',
);

option last => (
    is => 'ro',
    format => 'i',
    default => sub { 20 },
    doc => 'Number of entries to show (default: 20)',
);

sub execute {
    my ($self, $args_ref, $chain_ref) = @_;

    require App::karr::Git;
    my $git = App::karr::Git->new(dir => $self->board_dir->parent->stringify);

    unless ($git->is_repo) {
        print "Not a git repository. No log available.\n";
        return;
    }

    # Read all log refs
    my $refs_output = $git->_git_cmd('for-each-ref', '--format=%(refname)', 'refs/karr/log/');
    my @entries;

    if ($refs_output) {
        for my $ref (split /\n/, $refs_output) {
            my $content = $git->read_ref($ref);
            next unless $content;
            for my $line (split /\n/, $content) {
                my $entry = eval { decode_json($line) };
                push @entries, $entry if $entry;
            }
        }
    }

    # Sort by timestamp
    @entries = sort { $a->{ts} cmp $b->{ts} } @entries;

    # Apply filters
    if ($self->agent) {
        @entries = grep { ($_->{agent} // '') eq $self->agent } @entries;
    }
    if ($self->task) {
        @entries = grep { ($_->{task_id} // 0) == $self->task } @entries;
    }

    # Limit
    if ($self->last && @entries > $self->last) {
        @entries = @entries[-$self->last .. -1];
    }

    if ($self->json) {
        $self->print_json(\@entries);
        return;
    }

    unless (@entries) {
        print "No log entries.\n";
        return;
    }

    for my $e (@entries) {
        printf "%s  %-15s %-10s task#%s %s\n",
            $e->{ts} // '?',
            $e->{agent} // '?',
            $e->{action} // '?',
            $e->{task_id} // '?',
            $e->{detail} // '';
    }
}

1;
```

- [ ] **Step 4: Add `use_ok` for Log in `t/00-load.t`**

Add `use_ok('App::karr::Cmd::Log');` to the load test.

- [ ] **Step 5: Run all tests**

Run: `prove -l t/`
Expected: All pass

- [ ] **Step 6: Commit**

```bash
git add lib/App/karr/Cmd/Log.pm t/17-log.t t/00-load.t
git commit -m "feat: add log command for activity trail"
```

---

## Chunk 5: Release Preparation

### Task 11: Fix Init.pm — remove .gitignore manipulation

**Files:**
- Modify: `lib/App/karr/Cmd/Init.pm`

- [ ] **Step 1: Remove lines 54-65 from Init.pm**

Delete the entire `.gitignore` section:

```perl
  # Offer to add to .gitignore
  my $gitignore = path('.gitignore');
  if ($gitignore->exists) {
    my $content = $gitignore->slurp_utf8;
    unless ($content =~ m{^karr/?$}m) {
      $gitignore->append_utf8("karr/\n");
      print "Added karr/ to .gitignore\n";
    }
  } else {
    $gitignore->spew_utf8("karr/\n");
    print "Created .gitignore with karr/\n";
  }
```

- [ ] **Step 2: Run all tests**

Run: `prove -l t/`
Expected: All pass

- [ ] **Step 3: Commit**

```bash
git add lib/App/karr/Cmd/Init.pm
git commit -m "fix: remove .gitignore manipulation from init"
```

---

### Task 12: Docker git identity + Changes cleanup

**Files:**
- Modify: `Dockerfile`
- Modify: `Changes`

- [ ] **Step 1: Add git identity ENV vars to Dockerfile**

Add before `ENTRYPOINT`:

```dockerfile
ENV GIT_AUTHOR_NAME="karr"
ENV GIT_AUTHOR_EMAIL="karr@localhost"
ENV GIT_COMMITTER_NAME="karr"
ENV GIT_COMMITTER_EMAIL="karr@localhost"
```

- [ ] **Step 2: Update Changes file**

Replace `(experimental)` with stable language. Update the unreleased section to reflect v0.004 changes:

```
{{$NEXT}}

    - BREAKING: Git sync now stores task data in commit-wrapped refs
    - Add full board sync via refs/karr/* (fetch/materialize/serialize/push)
    - Add karr log command for activity trail
    - Add --claimed-by filter to list command
    - Add from_string to Task for ref-based loading
    - Rewrite Git.pm with safe execution (_git_cmd, no shell injection)
    - Fix write_ref to create commit-wrapped refs (enables git push/fetch)
    - Fix is_repo to work from subdirectories
    - Fix push refspec to refs/karr/*:refs/karr/*
    - Pick command uses Lock for atomic task claiming
    - Remove .gitignore manipulation from init
    - Extract sync_before/sync_after into BoardAccess role
    - Refactor Lock.pm to accept pre-built Git object
    - Docker: add default git identity ENV vars
```

- [ ] **Step 3: Run all tests one final time**

Run: `prove -l t/`
Expected: All pass

- [ ] **Step 4: Commit**

```bash
git add Dockerfile Changes
git commit -m "chore: Docker git identity, update Changes for v0.004"
```

---

### Task 13: Push/fetch test between repos

**Files:**
- Create: `t/19-git-push-fetch.t`

- [ ] **Step 1: Write push/fetch integration test**

```perl
# t/19-git-push-fetch.t
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use App::karr::Git;
use App::karr::Task;

# Create a bare "remote" repo
my $bare = tempdir( CLEANUP => 1 );
system("git init --bare '$bare' 2>/dev/null");

# Create "agent A" working copy
my $repo_a = tempdir( CLEANUP => 1 );
system("git init '$repo_a' 2>/dev/null");
system("git -C '$repo_a' config user.email 'a\@test.com'");
system("git -C '$repo_a' config user.name 'Agent A'");
system("git -C '$repo_a' remote add origin '$bare'");
# Need at least one commit for push to work
system("git -C '$repo_a' commit --allow-empty -m 'init' 2>/dev/null");
system("git -C '$repo_a' push origin main 2>/dev/null");

# Create "agent B" working copy
my $repo_b = tempdir( CLEANUP => 1 );
system("git clone '$bare' '$repo_b' 2>/dev/null");
system("git -C '$repo_b' config user.email 'b\@test.com'");
system("git -C '$repo_b' config user.name 'Agent B'");

my $git_a = App::karr::Git->new( dir => $repo_a );
my $git_b = App::karr::Git->new( dir => $repo_b );

# Agent A writes a task ref and pushes
my $task = App::karr::Task->new(
    id => 1, title => 'Push test', status => 'todo',
    priority => 'high', class => 'standard', body => 'Test body',
);
$git_a->save_task_ref($task);
ok $git_a->push, 'agent A pushes refs';

# Agent B fetches and reads
ok $git_b->pull, 'agent B pulls refs';
my $fetched = $git_b->load_task_ref(1);
ok $fetched, 'agent B can load task from refs';
is $fetched->title, 'Push test', 'fetched task has correct title';
is $fetched->body, 'Test body', 'fetched task has correct body';

# Agent B writes a different task and pushes
my $task2 = App::karr::Task->new(
    id => 2, title => 'From agent B', status => 'backlog',
    priority => 'medium', class => 'standard',
);
$git_b->save_task_ref($task2);
ok $git_b->push, 'agent B pushes refs';

# Agent A pulls and sees both tasks
ok $git_a->pull, 'agent A pulls refs';
my @ids = $git_a->list_task_refs;
is_deeply \@ids, [1, 2], 'agent A sees both tasks after pull';

done_testing;
```

- [ ] **Step 2: Run test**

Run: `prove -l t/19-git-push-fetch.t`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add t/19-git-push-fetch.t
git commit -m "test: push/fetch integration test between two repos"
```

---

### Task 14: next_id collision prevention

**Files:**
- Modify: `lib/App/karr/Role/BoardAccess.pm`
- Create: `t/20-next-id-collision.t`

- [ ] **Step 1: Write failing test for next_id collision**

```perl
# t/20-next-id-collision.t
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::XS qw( DumpFile LoadFile );
use App::karr::Git;

my $repo = tempdir( CLEANUP => 1 );
system("git init '$repo' 2>/dev/null");
system("git -C '$repo' config user.email 'test\@test.com'");
system("git -C '$repo' config user.name 'Test'");

my $board = path($repo)->child('karr');
$board->mkpath;
$board->child('tasks')->mkpath;

# Local config has next_id: 5
my $local_config = {
    version => 1, board => { name => 'Test' }, tasks_dir => 'tasks',
    statuses => ['backlog', 'todo', 'done'],
    priorities => ['low', 'medium', 'high'],
    next_id => 5,
    defaults => { status => 'backlog', priority => 'medium', class => 'standard' },
};
DumpFile($board->child('config.yml')->stringify, $local_config);

# Remote config has next_id: 10 (another agent created more tasks)
my $git = App::karr::Git->new( dir => $repo );
my $remote_config = { %$local_config, next_id => 10 };
use YAML::XS qw( Dump );
$git->write_ref('refs/karr/config', Dump($remote_config));

# Materialize config from refs — should take max(local, remote)
my $config_content = $git->read_ref('refs/karr/config');
ok $config_content, 'config ref exists';
my $fetched_config = YAML::XS::Load($config_content);
is $fetched_config->{next_id}, 10, 'remote next_id is 10';

# The materialization should set local next_id to max(5, 10) = 10
my $local = LoadFile($board->child('config.yml')->stringify);
is $local->{next_id}, 5, 'local next_id is still 5 before materialize';

# Simulate materialization with next_id merge
my $merged_next_id = $local->{next_id} > $fetched_config->{next_id}
    ? $local->{next_id}
    : $fetched_config->{next_id};
is $merged_next_id, 10, 'merged next_id takes max';

done_testing;
```

- [ ] **Step 2: Run test**

Run: `prove -l t/20-next-id-collision.t`
Expected: PASS

- [ ] **Step 3: Add next_id merge to `_materialize_from_refs`**

In `lib/App/karr/Role/BoardAccess.pm`, update the config materialization section of `_materialize_from_refs`:

```perl
    # Materialize config with next_id merge
    my $config_content = $git->read_ref('refs/karr/config');
    if ($config_content) {
        my $local_config_file = $self->board_dir->child('config.yml');
        if ($local_config_file->exists) {
            require YAML::XS;
            my $remote_config = YAML::XS::Load($config_content);
            my $local_config = YAML::XS::LoadFile($local_config_file->stringify);
            # Merge next_id: take the max to prevent collisions
            my $local_nid = $local_config->{next_id} // 1;
            my $remote_nid = $remote_config->{next_id} // 1;
            $remote_config->{next_id} = $local_nid > $remote_nid ? $local_nid : $remote_nid;
            YAML::XS::DumpFile($local_config_file->stringify, $remote_config);
        } else {
            $local_config_file->spew_utf8($config_content);
        }
    }
```

- [ ] **Step 4: Run all tests**

Run: `prove -l t/`
Expected: All pass

- [ ] **Step 5: Commit**

```bash
git add lib/App/karr/Role/BoardAccess.pm t/20-next-id-collision.t
git commit -m "feat: next_id collision prevention in config sync"
```

---

### Task 15: Update skill and README (Phase 2 prep)

**Files:**
- Modify: `share/claude-skill.md`
- Modify: `README.md`

- [ ] **Step 1: Add `log` command and `--claimed-by` to skill**

Add to the Commands section in `share/claude-skill.md`:

```markdown
### Activity log

\`\`\`bash
karr log                                     # last 20 entries
karr log --agent swift-fox                   # filter by agent
karr log --task 5                            # filter by task
karr log --last 50 --json                    # more entries, JSON
\`\`\`
```

Add `--claimed-by` to the list command section:

```markdown
karr list --claimed-by agent-1               # filter by claim owner
```

- [ ] **Step 2: Update README.md**

Add `log` to the commands table. Add a note about Git sync being the core coordination mechanism.

- [ ] **Step 3: Commit**

```bash
git add share/claude-skill.md README.md
git commit -m "docs: add log command and --claimed-by to skill and README"
```

---

### Task 16: Final verification

- [ ] **Step 1: Run full test suite**

Run: `prove -lv t/`
Expected: All tests pass

- [ ] **Step 2: Run `dzil test` if available**

Run: `dzil test`
Expected: All tests pass including author tests

- [ ] **Step 3: Verify Docker build**

Run: `dzil build && docker build --build-arg KARR_TGZ=App-karr-*.tar.gz -t raudssus/karr:test .`
Expected: Builds successfully

- [ ] **Step 4: Smoke test Docker**

```bash
mkdir /tmp/karr-smoke && cd /tmp/karr-smoke
git init && git config user.email 'test@test.com' && git config user.name 'Test'
docker run --rm -v $(pwd):/work raudssus/karr:test init --name "smoke-test"
docker run --rm -v $(pwd):/work raudssus/karr:test create "Test task" --priority high
docker run --rm -v $(pwd):/work raudssus/karr:test list --json
docker run --rm -v $(pwd):/work raudssus/karr:test pick --claim smoke-agent --move in-progress
docker run --rm -v $(pwd):/work raudssus/karr:test board
```
