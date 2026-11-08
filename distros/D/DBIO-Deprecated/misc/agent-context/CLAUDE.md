# CLAUDE.md — DBIO::Deprecated

This distribution ships its own `dbio-deprecated` skill + `dbio-worker-deprecated`
agent and the shared `.claude/rules/`. The family-wide house rules (discipline,
delegation, release) live in `.claude/rules/.local.dbio-rules.md` — auto-loaded by
Claude Code for the main agent and all subagents.

## Delegation

Delegate behaviour-relevant code (the tombstone modules under `lib/`, their
tests, POD, and `Changes`/skill updates) to this repo's `dbio-worker-deprecated`
instead of touching it yourself. Lane and principle: `.claude/rules/.local.dbio-rules.md`.
Repo agents: `dbio-worker-deprecated` (default) and `dbio-release-manager`.
Deliberately no ADR auditor and no karr coordinator: this dist records no
architecture — every module is a self-contained stub whose entire behaviour is
to die on load — and its board is a receiving end, not a routing point. The
release checker stays because releasing is the one operation here that can do
damage: a wrong $VERSION hands the PAUSE index entry back to the superseded
distribution.

## Core concept: PAUSE-takeover tombstones

`DBIO::Deprecated` has no runtime behaviour of its own. It exists purely so a
DBIO module that is renamed or retired does not leave its old CPAN name
permanently resolving to stale, superseded code — PAUSE has no delete.

This is **not only a cross-distribution problem**. PAUSE indexes per
**module name**, not per distribution: it resolves a module name to
whichever shipped release — of any distribution, including a later release
of the *same* one — carries the highest `$VERSION` for that name. A rename
across a distribution boundary (`dbio-mysql-ev`'s `DBIO::MySQL::Async` →
`DBIO::MySQL::EV`) and a rename or deletion *within* one distribution's own
release history (`dbio-dzil`'s inline `SetCopyrightHolder` → `SetMeta`, or
core's `DBIO::StartupCheck` deleted outright) orphan the old name the same
way: either way the name stops appearing in anything newer, and PAUSE keeps
pointing at the last release that had it.

Each renamed/removed module gets a stub package here under the OLD name,
shipped at a distribution version above the last release that carried that
name, taking the index entry over. The stub `die`s immediately on load —
naming the replacement module and distribution when there is one, or saying
plainly the module was removed when there isn't — full mechanism and the
audit method (diff `package` names at a dist's release tags against its
current HEAD) are in the `dbio-deprecated` skill, the step-by-step "add a new
tombstone" procedure in the repo-local `dbio-deprecated-core` skill; neither
is duplicated here.

## Version policy — the dist version takes the index over, not the literal

**This dist is no longer an exception to anything, and the tombstone `$VERSION`
literals are not hand-maintained.** Measured 2026-09-06 (karr k2):

- Every `.pm` in every DBIO dist carries a literal `$VERSION` today: core
  245/245, dbio-mysql 26/26, here 17/17. The old "only a dist's main module
  carries one" norm was real but has expired — at core tag `v0.900002` exactly
  1 of 244 modules had one; core commit `5168c54b` stamped the rest.
- `[@DBIO]` runs `@Git::VersionManager` for non-core dists (this is one) with
  `RewriteVersion::Transitional` `global = 1`, `finder = [:InstallModules]`.
  The build therefore **rewrites** every module's `$VERSION` to the dist
  version, and **inserts** the line where a module has none: a literal
  `0.111111` in `lib/DBIO/Version.pm` builds as `0.900004`, and deleting the
  line outright still builds as `0.900004`.
- What PAUSE reads is the `provides` block of `META.json`, written by
  `MetaProvides::Package` with `inherit_version = 1` — that is the
  **distribution version**, regardless of the literal in the file.

Both paths lead to the same number, which is why the conclusion is robust: if
PAUSE reads `provides`, it gets the dist version; if it scans the shipped files
instead, those carry the dist version too, because the build stamped them.

So the takeover hangs on this distribution's own release version alone. The
literals stay (family convention, and `BumpVersionAfterRelease` keeps them in
step), but removing one breaks nothing — do not claim it does, and never
hand-compute one when adding a tombstone.

### Operating rule — the risk is a new tombstone, not an old one

Every origin release is frozen: none of the 16 tombstoned names still exists in
its origin dist's HEAD, and the old `DBIO-MySQL-Async` / `DBIO-PostgreSQL-Async`
dists no longer exist at all. A later origin release does not carry the name, so
it can never overtake a tombstone that is already in place -- unless the name
comes back live (`DBIO::Test::Future`, k7): then the tombstone goes, and
`t/03-no-live-collision.t` is what notices.

The real hazard is a **new** tombstone added while this dist lags the family. It
ships at whatever version `dbio-deprecated` happens to be on, which may be
*lower* than the origin release that last shipped the name — and then the
takeover fails silently. Hence: this dist rides the coordinated family release
version, and adding a tombstone includes checking that this dist's next release
version is strictly higher than the origin release recorded in the stub comment.
`t/02-version-guard.t` performs exactly that comparison automatically (k3), so
the check is a test failure before the release rather than a manual step.

`lib/DBIO/Deprecated.pm` carries the version everything above derives from
(`RewriteVersion::Transitional` reads it, `Git::NextVersion` is the fallback).
It is tool-managed like every other main module in the family; never hand-bump it.

## Current tombstones

| Old module | Redirects to | Origin |
|---|---|---|
| `DBIO::MySQL::Async` | `DBIO::MySQL::EV` | dbio-mysql-ev (cross-dist) |
| `DBIO::MySQL::Async::Pool` | `DBIO::MySQL::EV::Pool` | dbio-mysql-ev (cross-dist) |
| `DBIO::MySQL::Async::QueryExecutor` | `DBIO::MySQL::EV::QueryExecutor` | dbio-mysql-ev (cross-dist) |
| `DBIO::MySQL::Async::Storage` | `DBIO::MySQL::EV::Storage` | dbio-mysql-ev (cross-dist) |
| `DBIO::MySQL::Async::TransactionContext` | `DBIO::MySQL::EV::TransactionContext` | dbio-mysql-ev (cross-dist) |
| `DBIO::PostgreSQL::Async` | `DBIO::PostgreSQL::EV` | dbio-postgresql-ev (cross-dist) |
| `DBIO::PostgreSQL::Async::ConnectInfo` | `DBIO::PostgreSQL::EV::ConnectInfo` | dbio-postgresql-ev (cross-dist) |
| `DBIO::PostgreSQL::Async::Pool` | `DBIO::PostgreSQL::EV::Pool` | dbio-postgresql-ev (cross-dist) |
| `DBIO::PostgreSQL::Async::Storage` | `DBIO::PostgreSQL::EV::Storage` | dbio-postgresql-ev (cross-dist) |
| `DBIO::PostgreSQL::Async::TransactionContext` | `DBIO::PostgreSQL::EV::TransactionContext` | dbio-postgresql-ev (cross-dist) |
| `DBIO::StartupCheck` | *(removed, no replacement)* | dbio core (in-dist) |
| `DBIO::Schema::Versioned` | *(removed, no replacement)* | dbio core (in-dist) |
| `DBIO::Version` | *(removed, no replacement)* | dbio core (in-dist) |
| `DBIO::Version::Table` | *(removed, no replacement)* | dbio core (in-dist) |
| `DBIO::ResultSourceHandle` | *(removed, no replacement)* | dbio core (in-dist) |
| `Dist::Zilla::Plugin::DBIO::SetCopyrightHolder` | `Dist::Zilla::Plugin::DBIO::SetMeta` | dbio-dzil (in-dist) |

## Adding a new tombstone

Do not improvise this — follow the procedure in the `dbio-deprecated-core` skill
(`.claude/skills/dbio-deprecated-core/SKILL.md`): find the old module's last
released version, create the stub (rename-with-successor or
removed-with-no-successor shape), add it to `t/01-tombstones.t`, update this
dist's main-module POD table and this file's table above, add a `Changes`
entry. Candidates come from any dist in the family, not just driver renames —
the `dbio-deprecated` skill documents the audit method (diff release-tag package names against
current HEAD) for finding them.

## Boundary / dependencies

No DB-specific code, no dependency on DBIO core — every tombstone is
self-contained (no `use base 'DBIO::Base'`, no `use DBIO`). Keep it that way;
a tombstone's only job is to load fast and die with a clear message.

## Testing

```bash
../dbio/maint/capped-test prove -lr t/
```

`t/00-load.t` loads the real main module (`DBIO::Deprecated`) and must load
cleanly. `t/01-tombstones.t` asserts all 16 tombstones die on load, three
checks each: the renamed shape must name its replacement and say "renamed",
the removed shape (`DBIO::StartupCheck`, `DBIO::Version`,
`DBIO::Version::Table`, `DBIO::ResultSourceHandle`, `DBIO::Schema::Versioned`) must say "removed" and
must not falsely claim a rename. `t/02-version-guard.t` is the release guard
for the one failure mode that fails silently (k3): it reads the
`# Last release that shipped this name: ... X.Y` line out of every tombstone,
takes the maximum, and requires `$DBIO::Deprecated::VERSION` to be strictly
higher -- so a new tombstone added while this dist lags the family is caught
before the release, not after. It fails just as hard when a tombstone carries
no such line at all; otherwise the guard could be sidestepped by omitting it.
`t/03-no-live-collision.t` (k7) claims that no tombstone name exists as a real
`package X;` (column 0, outside POD) in `lib/` of any sibling checkout under
`../*/lib`: a name that comes back live in another dist must lose its tombstone,
or installing this dist overwrites the real module with a dying stub. Tombstone
names are derived from `lib/`, not hand-listed. It skips (clearly labelled) when
the cwd is no git checkout -- `dzil test`, a built tarball dir -- or no sibling
git checkouts of other dists exist, so the dist builds standalone. A sibling
that is itself a copy of this dist (it carries `lib/DBIO/Deprecated.pm`: another
git worktree, a second clone) is left out -- it holds every tombstone by design.
The test was verified red against `../dbio/lib/DBIO/Test/Future.pm` before that
tombstone was withdrawn.
No DB, no mock storage involved.
