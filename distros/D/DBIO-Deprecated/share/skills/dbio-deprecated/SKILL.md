---
name: dbio-deprecated
description: "DBIO::Deprecated -- permanent home for CPAN redirect (tombstone) stub modules covering DBIO modules renamed or retired anywhere in the family, cross-distribution or within one distribution's own release history. Covers the PAUSE-takeover mechanism, the audit method for finding orphaned module names, and the procedure for adding a new tombstone."
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::Deprecated

Permanent home for "tombstone" redirect stub modules: when a DBIO module gets
renamed or retired, the old module name stays indexed on PAUSE against the
last release that shipped it, forever -- PAUSE has no delete. Anyone still
running `cpanm Old::Module::Name` (or a cpanfile pinning it) would keep
installing the stale, dead code with no hint a replacement exists.

This dist ships a tombstone for each such name: a stub package under the OLD
module name whose only job is to `die` immediately on load -- naming the
replacement module and distribution when there is one, or saying plainly the
module was removed when there isn't.

## The CPAN-takeover mechanism

PAUSE indexes each module name to whichever shipped release -- of **any**
distribution -- carries the **highest `$VERSION`** for that module name
(subject to the primary maintainer/owner controlling the namespace -- not a
concern here since Getty owns every dist in the family). Releasing
`DBIO-Deprecated` with an `Old::Module::Name` package versioned higher than
the last release that shipped that name takes over the PAUSE index entry for
it: `cpanm Old::Module::Name` now installs THIS tombstone instead of the
stale code.

**This is not only a cross-distribution problem.** PAUSE indexes per
**module name**, not per distribution. Two shapes both orphan a name and
both need a tombstone here:

- **Cross-distribution rename** -- the module moves to a different CPAN
  dist (`dbio-mysql-ev`'s `DBIO::MySQL::Async` → `DBIO::MySQL::EV`, a
  different distribution name). The old dist keeps shipping the old name at
  its last release forever; the new dist never ships the old name at all.
- **Same-distribution rename or removal** -- a later release of the *same*
  distribution renames or deletes an internal package without moving it
  anywhere (`dbio-dzil`'s inline `Dist::Zilla::Plugin::DBIO::SetCopyrightHolder`
  → `Dist::Zilla::Plugin::DBIO::SetMeta`, still inside
  `Dist-Zilla-PluginBundle-DBIO`; `dbio` core's `DBIO::StartupCheck` deleted
  outright with no replacement). PAUSE does not know or care that "the dist
  is still actively released" -- it only sees that no shipped release
  contains that module name above the version of the last one that did, so
  the name is orphaned exactly the same way a cross-dist rename orphans one.

## Auditing the family for orphaned module names

Not just driver renames -- any dist in the family can produce a candidate.
Method: diff the set of `package X;` names present at a dist's release
tag(s) against the set present at its current HEAD.

```bash
cd <dist-repo>
git tag -l                                    # find release tags (vX.Y.Z)
git ls-tree -r --name-only vX.Y.Z -- lib      # packages shipped at that release
# compare against:
git ls-tree -r --name-only HEAD -- lib        # packages shipped now
```

A name present at a release tag but absent from HEAD (and absent from every
later release tag too) is orphaned -- it needs a tombstone here, UNLESS a
later release of that same distribution re-introduced it (then PAUSE already
points at the current, correct code and no tombstone is needed). Grep
`git log --all -p -- '*OldName*'` and the commit that removed/renamed it to
confirm the actual replacement (or confirm there is none) before writing the
tombstone -- do not guess the successor from the file path alone.

## Two tombstone shapes

### 1. Renamed -- die pointing at the successor

Consequences that shape the module:

- **Explicit, hand-set `$VERSION`.** Every other DBIO sub-module in the
  family carries no `$VERSION` at all -- only a dist's main module does, and
  that one is bumped by `[@DBIO]`'s `RewriteVersion::Transitional` /
  `Git::NextVersion` machinery (finder `[:MainModule]` only). A tombstone is
  a deliberate, hand-maintained exception: `dzil`'s version bumper never
  touches it, so it needs its own `our $VERSION = '...';` literal, set once
  and left alone. Each tombstone module carries a comment explaining this so
  a future maintainer does not "clean it up" to match the no-`$VERSION`
  sub-module norm -- doing so would silently hand the PAUSE index entry back
  to the superseded release on the next `dbio-deprecated` release.
- **The version must beat the last release that shipped the old name**,
  found via `cpanm --info Old::Dist::Name` or that dist's release git tag
  (Getty's convention: a `vX.Y.Z` tag at the released commit; `git ls-tree`
  the tag to confirm the name was actually there, and check the containing
  file's own `$VERSION` if the package itself declares none). Round up
  generously -- a full patch/minor bump, not `+0.000001`, so a stray
  uncommitted dev-version bump in the old repo can never collide. If the
  package's own `$VERSION` is unclear (e.g. an inline package in a bundle
  file that inherits nothing), beat the *containing file's* declared
  `$VERSION` instead, to be safely conservative.
- **The module does nothing else.** No POD-only doc stub, no re-export, no
  `use base` of the replacement -- just `die` on load. A tombstone that
  merely warns and keeps working invites callers to never migrate; dying
  forces the fix.

Model: `lib/DBIO/MySQL/Async.pm`, `lib/DBIO/MySQL/Async/Pool.pm`,
`lib/DBIO/Test/Future.pm`, `lib/Dist/Zilla/Plugin/DBIO/SetCopyrightHolder.pm`
(the last one documents a same-distribution rename explicitly in its POD --
copy that framing whenever the "new distribution" is really the same one the
caller already depends on).

### 2. Removed -- die with no successor, no false rename claim

For a module deleted outright with nothing replacing it. Same `$VERSION`
mechanics as above, but the `die` message must say plainly the module was
removed and why, and must **not** claim a rename or name a "replacement"
that does not exist -- misdirecting a caller to a nonexistent module is
worse than a blunt "removed" message. Model: `lib/DBIO/StartupCheck.pm`.

## Adding a new tombstone (procedure)

1. **Find the old module's last released `$VERSION`** and confirm the
   successor (or its absence) via the audit method above.
2. **Create the stub** at `lib/<Old/Namespace>.pm` (path matches the OLD
   module name, not the new one -- note the namespace does not have to
   match the dist name, e.g. `Dist::Zilla::Plugin::DBIO::*` tombstones ship
   from this `DBIO-Deprecated` dist same as `DBIO::*` ones). Pick the
   renamed or removed shape above and model it on the matching existing
   tombstone. Structure: `package Old::Module::Name;` + `# ABSTRACT: ...`,
   `use strict; use warnings;`, the explicit `$VERSION` with its "do not
   clean this up" comment, the `die`, then POD after `__END__` (`=head1
   NAME` marking DEPRECATED/REMOVED, `=head1 DESCRIPTION` explaining what
   happened and that the module dies unconditionally, `=head1 SEE ALSO`
   linking the replacement if any plus `DBIO::Deprecated`).
3. **Add a test** in `t/01-tombstones.t` (extend the existing `%tombstone`
   hash -- do not write a new file per tombstone): mark its `type` as
   `renamed` or `removed`, `eval "require $mod; 1"` must be false, and `$@`
   must match the expected pattern for that shape.
4. **Update `lib/DBIO/Deprecated.pm`'s POD** -- add a row to the "CURRENT
   TOMBSTONES" table (grouped by originating dist), and if the replacement
   module is new, a `L<...>` entry under `SEE ALSO`.
5. **Update `CLAUDE.md`'s "Current tombstones" table** to match.
6. **Add a `Changes` entry** under `{{$NEXT}}` describing the new tombstone:
   old module, new module (or "removed, no replacement"), origin dist, and
   the version it was set to beat.
7. **Verify**: `prove -lr t/` green, `dzil build` clean. Do not `dzil
   release` without the maintainer's explicit go-ahead (family-wide rule,
   `.claude/rules/dbio-rules.md`).

## Boundary

This dist ships no DB-specific code and has no runtime dependency on DBIO
core -- each tombstone is fully self-contained (no `use base 'DBIO::Base'`,
no `use DBIO`). Keep it that way: a tombstone's only job is to load fast and
die with a clear message, nothing more.
