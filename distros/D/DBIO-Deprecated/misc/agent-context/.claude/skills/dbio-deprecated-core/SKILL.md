---
name: dbio-deprecated-core
description: Use when implementing in the DBIO-Deprecated repo itself — adding or changing a tombstone stub, its tests, tables or Changes entry.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

Repo-local skill for implementers of this distribution (not shipped to other
repos). Audit method, takeover mechanism and the two shapes are in the skill
`dbio-deprecated`; this skill does not repeat them.

## Vocabulary

- **Tombstone** -- a stub package under an OLD module name in `lib/`. Its only
  job is to `die` on load.
- **Renamed shape** -- a successor exists; the message names the replacement
  module and distribution and says "renamed".
- **Removed shape** -- no successor; the message says "removed" and claims no
  rename and names no replacement. Model: `lib/DBIO/StartupCheck.pm`.
- **Origin release** -- the last release of the origin dist that shipped the
  old name, recorded in the stub's comment.
- **Takeover** -- this dist's release at a version above the origin release
  takes the PAUSE index entry for the name.
- **Main module** -- `lib/DBIO/Deprecated.pm`: no tombstone, carries the
  "HOW THE TAKEOVER WORKS" POD and the "CURRENT TOMBSTONES" table.

## Architecture

The dist has no runtime behaviour. Every file under `lib/` except
`DBIO/Deprecated.pm` is a tombstone, and the tests derive the tombstone set
from `lib/`. The path matches the OLD module name, also for non-`DBIO::`
namespaces (`Dist::Zilla::Plugin::DBIO::SetCopyrightHolder`).

Stub layout, in this order:

1. `package Old::Name;` then `# ABSTRACT: RENAMED -- ...` or `REMOVED -- ...`
2. `use strict; use warnings;`
3. The comment block opening with
   `# Last release that shipped this name: <Dist> <X.Y>.` (see Testing), then
   the takeover note pointing at `DBIO::Deprecated`, "HOW THE TAKEOVER WORKS".
   Copy it from an existing stub and change only the origin line.
4. `our $VERSION = '...';`
5. The `die`, then `1;`, then `__END__` and POD: `=head1 NAME` (DEPRECATED /
   REMOVED), `=head1 DESCRIPTION` (what happened; the module dies
   unconditionally), `=head1 SEE ALSO` (the replacement if any, plus
   `DBIO::Deprecated`).

## Hard boundaries

- No `use DBIO`, no `use base`, no dependency on core or any DBIO dist; the stub
  is self-contained and loads fast.
- The stub dies unconditionally on load. It does not warn, re-export or
  forward to the replacement.
- A removed-shape message never claims a rename and never names a replacement;
  a renamed-shape message names the true successor, taken from git history
  and not guessed from the file path.
- No DB-specific code in the dist.

## Versions

- The `$VERSION` literal in a stub documents; it decides nothing. The build
  rewrites it to the dist version (and inserts it where missing), and PAUSE
  reads the dist version from META `provides`. Write the line like the
  existing stubs; never compute or tune the number by hand.
- The decisive number is this dist's own next release version. It must be
  strictly higher than the origin release in the stub comment. If it is not,
  the dist version is raised, not the stub literal.
- `lib/DBIO/Deprecated.pm` carries the dist version and is tool-managed:
  never hand-bump it.
- Establish the origin release from the origin repo's `vX.Y.Z` tag (`git
  ls-tree` it to confirm the name was in it) or `cpanm --info`; fall back to
  the containing file's `$VERSION` when the package declares none.

## Adding a tombstone

1. Audit and confirm the successor (or its absence) per `dbio-deprecated`;
   establish the origin release and check the version rule above.
2. Create the stub at `lib/<Old/Namespace>.pm` in the matching shape, modelled
   on an existing stub.
3. Extend `%tombstone` in `t/01-tombstones.t` (`type` renamed or removed, plus
   the `match` pattern). One hash, no new test file per tombstone.
4. Update every list of current tombstones: the "CURRENT TOMBSTONES" table in
   `lib/DBIO/Deprecated.pm` (grouped by origin dist, and a `SEE ALSO` `L<...>`
   if the replacement is new), the table in `CLAUDE.md`, and `README.md`.
5. Add a `Changes` entry under `{{$NEXT}}`: old module, new module or "removed,
   no replacement", origin dist, the origin release this dist's version
   clears, and the card as `(karr kNN)`.
6. Run the tests and `dzil build`. `dzil release` waits for the maintainer.

## Known limits

- A tombstone file already installed stays on disk until a newer release of
  the real module overwrites it; withdrawing a tombstone does not remove it
  from machines that installed it.
- A name that returns live in another dist loses its tombstone (withdrawn
  case: `DBIO::Test::Future`, core re-issued it). Remove the file, its table
  rows, its README line and its test entry; `t/03` detects the collision.
- PAUSE keeps the index entry of a withdrawn tombstone until the live dist
  ships the name at a higher version.
- Existing tombstones cannot be overtaken by their origin dists, whose
  releases are frozen; only a NEW tombstone can fail silently on version.
- Two checks have gaps by design: `t/02` compares versions only, and `t/03`
  needs sibling git checkouts to say anything.

## Testing

Offline; no database, no `DBIO_TEST_*` variables. From the repo root, with
`PERL5LIB` pointing at the sibling `lib/` dirs when they are checked out:

```bash
../dbio/maint/capped-test prove -lr t/
```

- `t/00-load.t` -- the main module `DBIO::Deprecated` loads.
- `t/01-tombstones.t` -- every tombstone dies on load (3 checks each). Renamed:
  names the replacement and says "renamed". Removed: says "removed" and does
  not claim a rename.
- `t/02-version-guard.t` -- every `lib/` module except the main one carries
  exactly one parseable `# Last release that shipped this name: <Dist> <X.Y>.`
  line, and `$DBIO::Deprecated::VERSION` is strictly higher than the maximum.
  A missing line fails; so does a missing `lib/` or an empty tombstone set
  (`BAIL_OUT`).
- `t/03-no-live-collision.t` -- no tombstone name exists as a column-0
  `package X;` outside POD in `lib/` of a sibling checkout. It skips, labelled,
  outside a git checkout or without siblings; siblings that carry
  `lib/DBIO/Deprecated.pm` (other worktrees, clones) are left out.

## ADRs and installation

This dist keeps no ADRs: every module is a stub whose whole behaviour is to
die, so there is no architecture to record (`CLAUDE.md` says so). The family
ADRs apply as written; skills, rules and shared agents are installed by
skilletor (ADR 0058); installed copies are changed in their source (core),
not here.
`dbio-deprecated` is the one skill this dist ships to others (`share_skill`
in `dist.ini`); this skill is deliberately not listed there.
