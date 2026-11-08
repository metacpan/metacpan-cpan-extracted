---
name: dbio-deprecated
description: Use when a DBIO module was renamed or retired and needs a CPAN tombstone, or when auditing the family for orphaned module names.
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
concern here since the maintainer owns every dist in the family). Shipping an
`Old::Module::Name` package in a `DBIO-Deprecated` release whose version is
higher than the last release that shipped that name takes over the PAUSE
index entry for it: `cpanm Old::Module::Name` now installs THIS tombstone
instead of the stale code. The version that decides this is **the
`DBIO-Deprecated` release's own version**, not a literal written into the
stub file -- see `DBIO::Deprecated`'s "HOW THE TAKEOVER WORKS" for the
full mechanism.

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
Method: unite the `package X;` names of **all** release tags of a dist and
diff that union against its current HEAD. Comparing a single tag misses
names that vanished between two older releases (that is how
`DBIO::Schema::Versioned` was missed, karr k6).

```bash
cd <dist-repo>
names() { git grep -h -E '^package[[:space:]]+[A-Za-z_][A-Za-z0-9_:]*' "$1" -- lib \
          | sed -E 's/^package[[:space:]]+([A-Za-z0-9_:]+).*/\1/'; }
comm -23 <(for t in $(git tag -l 'v0.9*'); do names "$t"; done | sort -u) \
         <(names HEAD | sort -u)
# adjust the tag glob to the dist's release tags (git tag -l)
```

Output = names shipped at some release but absent from HEAD. The `^package`
anchor already drops indented lines. Run against `dbio` core
(2026-10-07) it prints 21 names: `DBIO::ResultSourceHandle`,
`DBIO::Schema::Versioned`, `DBIO::StartupCheck`, `DBIO::Version`,
`DBIO::Version::Table`, plus sixteen `DBIO::Test::Schema::Moo*` /
`Moose*` names (see the non-findings below).

**Subtract before concluding:**

- namespaces excluded from the index via `[MetaNoIndex]` in the dist's
  `dist.ini` -- PAUSE never indexed them, so there is nothing to take over;
- `package` lines that are not real packages: indented lines, and lines
  inside POD (e.g. a SYNOPSIS).

**Known non-findings (as of 2026-10-07), do not recompute:**

- `DBIO::Test::Schema::Moo`, `::MooCake`, `::Moose`, `::MooseSugar` with
  their `Result::*` / `ResultSet::*` classes (16 names, last in dbio
  v0.900001) were excluded via `[MetaNoIndex]` (namespace
  `DBIO::Test::Schema`) in every release.
- `package DBIO::EV::Pg::Pool` in dbio `lib/DBIO/Storage/Pool.pm` and
  `package DBIO::PostgreSQL::Async::Pool` in `lib/DBIO/Storage/PoolBase.pm`
  (v0.900000 through v0.900002) are indented inside POD SYNOPSIS, not real
  packages.

Every other orphaned name has its tombstone.

**Reverse direction -- a fixed step of every audit:** no tombstone name may
exist as a real package in the HEAD of any dist of the family. A name that
comes back live (core re-introduced `DBIO::Test::Future` after it had been
tombstoned here, karr k7) must lose its tombstone: two dists would fight over
the index entry and installing this one would overwrite the real module with
a dying stub. `t/03-no-live-collision.t` checks this against the sibling
checkouts; it skips when there are none.

A name present at a release tag but absent from HEAD (and absent from every
later release tag too) is orphaned -- it needs a tombstone here, UNLESS a
later release of that same distribution re-introduced it (then PAUSE already
points at the current, correct code and no tombstone is needed). Grep
`git log --all -p -- '*OldName*'` and the commit that removed/renamed it to
confirm the actual replacement (or confirm there is none) before writing the
tombstone -- do not guess the successor from the file path alone.

## Two tombstone shapes

### 1. Renamed -- die pointing at the successor

The stub's `$VERSION` literal and the version rules for writing one are
implementer detail (repo-local skill `dbio-deprecated-core`, present only in
the DBIO-Deprecated repository).

- **The module does nothing else.** No POD-only doc stub, no re-export, no
  `use base` of the replacement -- just `die` on load. A tombstone that
  merely warns and keeps working invites callers to never migrate; dying
  forces the fix.

Model: `lib/DBIO/MySQL/Async.pm`, `lib/DBIO/MySQL/Async/Pool.pm`,
`lib/DBIO/MySQL/Async/Storage.pm`, `lib/Dist/Zilla/Plugin/DBIO/SetCopyrightHolder.pm`
(the last one documents a same-distribution rename explicitly in its POD --
copy that framing whenever the "new distribution" is really the same one the
caller already depends on).

### 2. Removed -- die with no successor, no false rename claim

For a module deleted outright with nothing replacing it. The `die` message must say plainly the module was
removed and why, and must **not** claim a rename or name a "replacement"
that does not exist -- misdirecting a caller to a nonexistent module is
worse than a blunt "removed" message. Model: `lib/DBIO/StartupCheck.pm`.

## Adding a tombstone

The step-by-step procedure (stub layout, tests, tables, `Changes`, version
check) and the dist's hard boundary live in the skill `dbio-deprecated-core`.
That skill exists only in the DBIO-Deprecated repository; it is not shipped
with this one.
