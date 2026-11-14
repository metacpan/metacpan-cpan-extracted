---
name: dbio-consolidate-release
description: Use when asked to consolidate unreleased commits, clean up the Changes entry, or get a DBIO dist's history clean before release. Rewrites history and force-pushes.
user-invocable: true
---

# dbio-consolidate-release — clean, consolidated pre-release state

**Use on demand, as the exception — not every release.** Some dists accumulate a
back-and-forth history since the last release: a `Changes` bullet gets written, then
reworded, then superseded; intermediate commits that only add noise. This procedure
cleans that up into two deliverables:

1. **A clean `Changes` `{{$NEXT}}` entry** that contains *all* the real changes in
   their **final form** — the intermediate steps collapsed away, nothing lost.
2. **One clean commit** since the last release tag, whose message records everything
   nicely — a readable changelog of the release, not a pile of intermediate steps.

The dist is then tidy and ready for `dzil release` (which you run separately, with the
maintainer's go-ahead). If a dist's history is already clean, you don't need this — it
is a cleanliness workaround, not the normal flow.

**Lane:** git + `Changes` prose + `dzil build/test`. No driver internals are touched, so
no `dbio-worker`; the commit itself is `dbio-release-manager`'s (house rule: only the
release manager commits) — the orchestrating agent plans, confirms and dispatches it.
The commit belongs to `dbio-release-manager`; the orchestrating agent runs
`git push --force-with-lease` after the maintainer's explicit go (step 5).

**This rewrites published history.** Most commits since the last release are already
on `origin/main`, so the single-commit result needs a `git push --force-with-lease`.
That step is irreversible on the remote and is **always confirmed with the user at
runtime** (step 5). A local backup branch is made first, so it is always recoverable
on your machine.

## Arguments

- *(none)* — operate on the current repo.
- `--all` — operate on every DBIO dist next to this repo (the directory that holds the DBIO checkouts side by side, `..`) that has commits
  since its last tag (see `references/all-and-recovery.md`).
- `--dry-run` — preview only: show the commits in scope and the proposed `Changes`
  entry, then STOP. No edit, no commit, no push. Combine with `--all` to preview the
  whole family.

## Preconditions — STOP if any fails (report, don't work around)

1. Inside a git repo whose `dist.ini` has `[@DBIO]` (or `[@Filter]` with
   `-bundle = @DBIO`). Otherwise this is not a DBIO dist — stop.
2. `git status --porcelain` is **empty** (clean tree). A dirty tree means uncommitted
   work would be folded into the consolidated commit — stop and let the user commit or
   stash first. (What skilletor installed — skills, house rules, shared agents — is
   git-ignored and does not show up here. Any other untracked file is never `git add`ed
   here, so it cannot enter the commit — but still surface it and get an explicit OK
   before proceeding.)
3. A release tag exists: `LAST=$(git describe --tags --abbrev=0)`. No tag → never
   released; there is nothing to consolidate *against* — stop.
4. `git rev-list --count "$LAST"..HEAD` > 0. Zero → already clean, nothing to do.
5. The branch has an upstream (`git rev-parse --abbrev-ref '@{u}'`) — needed for the
   force-push target. Note the branch (`BR=$(git rev-parse --abbrev-ref HEAD)`).

## Procedure (single repo)

### 1. Gather the delta
```bash
LAST=$(git describe --tags --abbrev=0)
BR=$(git rev-parse --abbrev-ref HEAD)
N=$(git rev-list --count "$LAST"..HEAD)
git log --reverse --format='%h %s%n%w(0,6,6)%b' "$LAST"..HEAD   # subjects + bodies (ticket refs)
git rev-list --count "$LAST"..@{u} 2>/dev/null                  # how many are already pushed
```

### 2. Rewrite the Changes entry — everything, in final form
Read the current `Changes`. The unreleased block is everything **between the
`{{$NEXT}}` line and the first following version header** (a line starting with a
digit, e.g. `0.900000  2026-06-23`). It is often already partly hand-written — do
not throw that prose away.

Produce ONE consolidated entry covering the **whole** `"$LAST"..HEAD` delta:
- **Keep the `{{$NEXT}}` marker line intact** — `[NextRelease]` replaces it with the
  version + date at release time. Only edit the content *under* it.
- Merge existing prose with any commit it does not yet mention. Dedupe. Never drop a
  real detail; never leave a real change unmentioned.
- **Describe the net effect, not the journey.** A change that was added then reworded
  then superseded appears **once, in its final form** — this is the whole point (the
  intermediate steps disappear). Fold superseded/intermediate commits into the final-state
  bullet.
- **The entry names the change, not the card** (skill `dbio-perl-release`, § *Changes*):
  the final-form bullet says what the user of the dist gets, in words, and carries no
  karr number. Codeberg issues are public and keep their notation (`(Codeberg #13)`).
- House style — grouped categories, `-`-bullets, prose wrapped ~72 cols, describing
  **what changed and why**:

```
{{$NEXT}}
    * Storage
        - <what & why, wrapped>
    * Documentation
        - <...>
    * Tests
        - <...>
```
Match the categories the repo already uses (core: `Breaking Changes` / `New Features` /
`Fixes`; drivers: topic names such as `Storage`, `SQL`, `Deploy`, `Introspect`, `Diff`,
`Documentation`, `Tests`, `Fixes`). Use only those that apply. Drop pure-noise commits (`wip`, `typo`, `fixup`, `$VERSION` bump)
and internal `.claude/` skill-sync commits — fold real intent into the relevant
bullet, don't list them verbatim.

Write it back with `Edit` on `Changes`. **If `--dry-run`: print the proposed entry instead of writing, then STOP.**

### 3. Verify BEFORE touching history
```bash
skilletor sync && dzil build && ../dbio/maint/capped-test dzil test   # in core: maint/capped-test dzil test
```
`skilletor sync` first: the build ships the skill dirs named by `share_skill` from disk,
and a declared one that is missing is fatal (see [[dbio-perl-release]]).
Run on the working tree with the new `Changes` (consolidating history does not change
file contents, only history — so this tests the exact tree that will ship).
**Tests fail → STOP.** Report the failure; do not rewrite history on a red suite.
Live DB tests self-skip without `DBIO_TEST_PG_*` — that's fine.

### 4. Consolidate into one commit
```bash
git branch -f consolidate-release-backup HEAD    # recoverable snapshot (local only)
git add Changes                                  # ONLY Changes — nothing else
git reset --soft "$LAST"                          # HEAD -> tag; index keeps full tree + Changes
git commit -F <message>                           # single commit = entire delta since $LAST
dzil clean                                        # drop build artifacts, keep tree clean
```
The commit message must read like a **clean changelog of the release** — everything
nicely in it, grouped, with every ticket ref. The message reads as the changelog of the
release: it presents the real, final-form work, in the words of the work and not of the
mechanics of consolidating. Pick the
conventional type of the dominant change (`feat` if any feature, else `fix`, else
`docs`/`chore`):
```
feat: <headline of the release's work> since <LAST>

Everything since <LAST>, in final form:

  * <Category> — <what, refs>
  * <Category> — <what, refs>
  ...

Refs: karr k.., karr <other-board> k.., Codeberg #..
```

### 5. Confirm, then force-push (irreversible, outward-facing)
Show the result and get an **explicit go** before pushing — every invocation, even if
a plan said "push". Verify nothing but `Changes` differs from the pre-consolidation
tree (proves no code was lost):
```bash
git diff consolidate-release-backup HEAD --stat          # expect: only Changes
git diff consolidate-release-backup HEAD -- . ':(exclude)Changes'   # expect: empty
git range-diff "$LAST" "@{u}" HEAD                        # old published history vs the one commit
echo "backup: consolidate-release-backup ($(git rev-parse --short consolidate-release-backup))"
```
On the maintainer's explicit go the orchestrating agent runs:
```bash
git push --force-with-lease origin "$BR"
```
`--force-with-lease` (not `--force`) refuses if the remote moved unexpectedly. After a
clean push, tell the user `consolidate-release-backup` can be deleted once satisfied.

### 6. STOP before release
`dzil release` and any CPAN upload are a separate, maintainer-gated step (house
rule: release needs explicit go-ahead). Report: consolidated N
commits → 1, Changes rewritten in final form, tests green, force-pushed to
`origin/$BR`. Remind about family-version alignment (see [[dbio-perl-release]]) if this
dist is part of a coordinated cross-repo train.

## --all mode and recovery

The `--all` run over every dist (plan table, one up-front confirmation, sequential
processing) and the recovery steps for a regretted consolidation or force-push:
`references/all-and-recovery.md`.
