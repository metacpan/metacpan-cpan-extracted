# Design: Git Instantiation via Role::BoardDiscovery

## Status

Proposed

## Datum

2026-05-15

## Context

`Git->new(dir => ...)` was previously called in many places (Init, Backup, Restore, Sync, Pick, Role::BoardAccess). After Candidate 1 and Candidate 2 refactors, `Role::BoardDiscovery` owns the `store`, and `store->git` is the canonical Git instance.

## Decision

`Role::BoardDiscovery` exposes `git` as a lazy attribute that delegates to `store->git`.

```perl
# in Role::BoardDiscovery
has git => (
    is => 'lazy',
);

sub _build_git {
    my ($self) = @_;
    return $self->store->git;
}
```

Commands access `$self->git` directly instead of `$self->store->git`. This is purely a convenience delegation — no new complexity is introduced, just a shorter path to the same object.

### Init command exception

`Init` creates the board before `BoardStore` exists, so it still instantiates `Git` directly:

```perl
my $git = App::karr::Git->new(dir => '.');
```

This is intentional — `Init` must create the Git refs before `BoardStore` can be used.

### Benefits

- **Locality**: Git object creation knowledge is localized to `Role::BoardDiscovery`. Commands don't know how `store->git` is constructed.
- **Consistency**: All commands use the same `store->git` path through the role.
- **Deletion test**: If this attribute were removed, every command that uses `$self->git` would need to call `$self->store->git` instead. The delegation earns its keep.

### Files Affected

- `lib/App/karr/Role/BoardDiscovery.pm` — add `git` attribute
- `lib/App/karr/Cmd/Init.pm` — already correct, no changes needed
- `lib/App/karr/Cmd/Pick.pm` — update `$self->claim` to use `$self->git` via role
- Update `AGENTS.md` and `CLAUDE.md`
- Add `Changes` entry under `{{$NEXT}}`