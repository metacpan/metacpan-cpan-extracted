# Design: SyncGuard — Minimal Lock Handling

## Status

Approved

## Datum

2026-05-15

## Decision

**No structural changes to Lock.pm.** Lock release remains explicitly in command code (`Pick`, `Handoff`).

**Reasoning:** Lock is advisory. If a lock stays held due to a failed `sync_after`, it's not data loss — the lock times out or an admin resolves it. Adding lock tracking to `SyncGuard` adds complexity without proportional benefit.

**SyncGuard** (from Candidate 1) is a simple push guarantor with retry logic. It does not track locks.

### SyncGuard behavior

```perl
package App::karr::SyncGuard;

has git   => (is => 'ro', required => 1);
has _done => (is => 'rw', default => 0);
has _errors => (is => 'ro', default => sub { [] });

sub errs { @{$_[0]->{_errors}} }

# Called by command after successful work
sub done {
    my ($self) = @_;
    $self->{_done} = 1;
}

# DESTROY: only runs if done was never set (i.e., die/croak before sync_after)
sub DESTROY {
    my ($self) = @_;
    return if $self->{_done};
    # 3 retries with stderr output, then die with clear error
}
```

### Commands that use locks (Pick, Handoff)

Lock release is explicit in the command after `sync_after` succeeds:

```perl
$self->sync_after;
$lock->release($task->id, $email);  # explicit, after push
```

If `sync_after` dies (after 3 retries), the command exits — lock remains held until timeout. Acceptable for advisory locking.

### Files Affected

- `lib/App/karr/SyncGuard.pm` — new file
- No changes to `lib/App/karr/Lock.pm`
- No changes to `lib/App/karr/Cmd/Pick.pm` or `lib/App/karr/Cmd/Handoff.pm` (already correct)
- Add `Changes` entry under `{{$NEXT}}`
- Update `AGENTS.md` and `CLAUDE.md`