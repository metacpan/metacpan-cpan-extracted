# `--all` mode and recovery

Detail for `dbio-consolidate-release`.

## --all mode

1. Discover DBIO dists: every dir under `../*/` (seen from this repo) with a `.git` and a
   `dist.ini` containing `@DBIO` (bundle or `[@Filter] -bundle = @DBIO`); skip `dbio-deprecated`
   (tombstone dist, versions of its own).
2. For each, compute `LAST` and the commit count since it. Print ONE plan table:
   `repo | last tag | #commits since | clean-tree? | will force-push?`.
3. Get a **single explicit confirmation** that lists every repo that will be
   force-pushed. Then process repos **sequentially**, each via the single-repo
   procedure (steps 1–6); the per-repo force-push is covered by the one up-front
   confirmation, so there is no per-repo prompt.
4. Skip (without aborting the whole run) any repo that fails a precondition or whose
   `dzil test` is red; collect and report those at the end. **Fail loud** — a repo whose
   tests were skipped or failed is reported as not done.

## Recovery

Consolidation regretted, not yet force-pushed:
```bash
git reset --hard consolidate-release-backup
```
Already force-pushed but want the old history back:
```bash
git push --force-with-lease origin consolidate-release-backup:"$BR"
```
(works as long as `consolidate-release-backup` still exists locally; it is again a push
that needs the maintainer's explicit go).
