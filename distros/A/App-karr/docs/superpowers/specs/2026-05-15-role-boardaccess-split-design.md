# Design: Role::BoardAccess Split

## Status

Proposed

## Datum

2026-05-15

## Context

`Role::BoardAccess` conflated four separate concerns:
1. Board discovery (walking up to find `.git`)
2. Task loading (`load_tasks`, `find_task`)
3. Cache management (clear board_dir, clear config)
4. Sync lifecycle (`sync_before`, `sync_after`)

This made commands hard to test in isolation and created a materialized temp dir pattern that leaked into all command logic.

## Decision

Split `Role::BoardAccess` into two roles:

### Role::BoardDiscovery

Minimal role providing only:
- `git_root` — path to the Git repository (lazy, walks up from `dir` or CWD)
- `store` — `BoardStore` instance (lazy, created from git_root)

No `board_dir`, no temp dir, no task loading. Commands access tasks via `$store->load_tasks()`, `$store->save_task($task)`, etc.

### Role::SyncLifecycle

Provides:
- `sync_before()` — runs `git pull` with 3 retries and clear error messages on failure
- `sync_after()` — runs `git push` with 3 retries and clear error messages on failure
- Returns a `SyncGuard` object from `sync_before()` that acts as insurance: if `die`/`croak` happens before `sync_after` is called, the Guard's `DESTROY` runs `sync_after`

Commands explicitly call `sync_after()` after successful work. Guard is backup insurance only.

### SyncGuard

```perl
package App::karr::SyncGuard;

has git           => (is => 'ro', required => 1);
has _errors       => (is => 'ro', default => sub { [] });
has _done         => (is => 'rw', default => 0);

sub errs { @{$_[0]->{_errors}} }

sub DESTROY {
    my ($self) = @_;
    return if $self->{_done};

    my ($ok, $err) = (1, '');
    for my $attempt (1 .. 3) {
        my $git = $self->git;
        my $msg = "Push attempt $attempt of 3...";
        # push happens here
        if ($ok) { $self->{_done} = 1; return; }
        push @{$self->{_errors}}, $err;
        print STDERR "$msg failed: $err\n";
        sleep 1 if $attempt < 3;
    }
    die "Push failed after 3 attempts. Local refs are intact.\n"
      . "Run 'karr sync' to retry.\n"
      . "Errors: " . join(', ', $self->errs) . "\n";
}
```

Commands use:
```perl
sub execute {
    my ($self, $args_ref, $chain_ref) = @_;
    my $guard = $self->sync_before;  # backup insurance

    # ... command logic ...
    # may die/croak, guard handles cleanup in DESTROY

    $self->sync_after;  # explicit call for clarity
    undef $guard;       # mark done, DESTROY no-ops
}
```

### No Materialized Temp Dir

Commands operate directly on refs via `$store->load_tasks()`, `$store->save_task($task)`, etc. No intermediate `.md` files.

`tasks/` directory is:
- In `.gitignore` (never committed)
- Generated on demand via `karr materialize` as a human-readable view
- Warning issued if `tasks/` exists and is not in `.gitignore`

### Benefits

- **Locality**: Sync lifecycle is in one role. New commands can't forget it.
- **Leverage**: Commands become unit-testable — mock `store` and `git`, no temp dir needed.
- **Depth**: `Role::BoardDiscovery` is small, `Role::SyncLifecycle` is single-purpose.
- **Deletion test**: If `Role::SyncLifecycle` were deleted, the 3-retry push logic would reappear in every command. If `Role::BoardDiscovery` were deleted, git_root/store discovery would reappear in every command.

## Files Affected

- Create `lib/App/karr/Role/BoardDiscovery.pm`
- Create `lib/App/karr/Role/SyncLifecycle.pm`
- Create `lib/App/karr/SyncGuard.pm`
- Modify `lib/App/karr/Role/BoardAccess.pm` — may be removed or kept as empty alias for backward compat
- Modify all 20+ command modules to compose `Role::BoardDiscovery` + `Role::SyncLifecycle`
- Modify `App::karr` (main app) to compose roles
- Update `.gitignore` to ensure `tasks/` is ignored
- Update `AGENTS.md` and `CLAUDE.md` to reflect new architecture

## Risks

- `sync_after` called twice if command calls it explicitly AND guard DESTROY runs — mitigated by `_done` flag
- Commands that currently read `.md` files directly need to be updated to use `$store->load_tasks()`