# Design: Unified Config Access via BoardStore

## Status

Proposed

## Datum

2026-05-15

## Context

`BoardStore::load_config` merges code defaults with file overrides to produce an effective config. However, individual commands instantiate `App::karr::Config->new(file => $path)` directly and bypass the merge entirely. This means commands may not see code defaults (like `claim_timeout => '1h'` or default statuses) when fields are absent from the materialized `config.yml`.

## Decision

Expose `effective_config()` on `BoardStore` as the single access point for config. Commands never instantiate `Config` directly with a file path.

### BoardStore changes

Add `effective_config()` method:

```perl
sub effective_config {
    my ($self) = @_;
    return $self->{_effective_config} //= do {
        my $defaults = App::karr::Config->default_config;
        my $overrides = $self->load_config_overrides;
        _merge_hashes($defaults, $overrides);
    };
}

# invalidate cache when config is saved
sub save_config {
    my ($self, $effective) = @_;
    ...
    delete $self->{_effective_config};  # clear cache
    ...
}
```

### Config class changes

`App::karr::Config` retains:
- `default_config()` — class method returning code defaults
- `effective_config($overrides)` — class method for merging (used by tests)
- `statuses()`, `status_config()`, `priorities()` — helper methods on data hash

Remove:
- The `file`-based constructor (`has file`, `_build_data`) is no longer used by commands. `Config` becomes a pure data class for defaults and helpers, not a file wrapper.

### Role::BoardDiscovery provides config

Add `config` accessor to `Role::BoardDiscovery`:

```perl
has config => (
    is => 'lazy',
);

sub _build_config {
    my ($self) = @_;
    return $self->store->effective_config;
}
```

Commands access config via `$self->config()`.

### Benefits

- **Locality**: Config knowledge concentrated in `BoardStore` and `Role::BoardDiscovery`. Commands don't know about defaults.
- **Leverage**: One place to change how defaults are merged. Tests for commands that use config don't need a full `config.yml` fixture.
- **Deletion test**: If this module were deleted, the defaults-vs-override merge logic would reappear in every command that uses config.
- **No duplication**: Commands no longer create `Config->new(file => ...)` bypassing the merge.

### Files Affected

- `lib/App/karr/BoardStore.pm` — add `effective_config()`, cache invalidation on `save_config`
- `lib/App/karr/Role/BoardDiscovery.pm` — add `config` accessor
- `lib/App/karr/Config.pm` — retain `default_config`, `effective_config` class method, helpers; deprecate file-based instantiation
- Update all commands that use `App::karr::Config->new(file => ...)` to use `$self->config()` instead
- Add `Changes` entry under `{{$NEXT}}`
- Update `AGENTS.md` and `CLAUDE.md`