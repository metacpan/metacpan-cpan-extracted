# Direct cross-repo execution — the call, the prompt, running a block

Detail for `dbio-coordination` § *Direct cross-repo execution*.

## The call

Spawn Claude headless inside the target repo:

```bash
( cd ../dbio-mysql-ev \
  && claude -p "$PROMPT" \
       --model <exact-id> \
       --permission-mode bypassPermissions \
       --max-turns 40 ) 2>&1 \
    | tee <scratchpad>/xrepo-dbio-mysql-ev.log
```

Three flags matter:

- `--model <exact-id>` — the exact ID from the system prompt, not a family alias. A
  child claude does not inherit the parent session's model; without `--model` it reads
  the user default from the user's Claude settings. `--model` defaults to the model
  this session runs on; deviate only on the maintainer's explicit instruction (house rules).
- `--permission-mode bypassPermissions` — print mode cannot ask for permission, so
  unapproved tool calls deny. Run only inside the target-repo working tree.
- `--max-turns 40` — bounds a runaway; tune per task.

The limits therefore come from the prompt and from the scope below, not from the
permission layer. Log to the scratchpad, not into the repo (`.karr.log` belongs to
karr-foundation).

## The prompt

Name all four or the run drifts:

1. **The ticket** — its ID *on the target repo's board*. `karr show <id>` is the run's first move.
2. **Why it exists** — the head ticket, its repo, and what was decided there. The target
   agent cannot see the coordinating conversation; anything it needs must be in the prompt.
3. **The scope** — implement, test, commit locally; no `git push`, no release.
4. **Who does it** — the repo's own worker (`dbio-worker-<db>`), so the local briefing applies.

## Running a block

1. **Core first.** Finish the head ticket, verify with `maint/capped-test prove -lr t/`
   (recursive), then `dzil install` so the drivers pull the current core.
2. **One repo at a time, serially.** Two target-repo Claudes at once can exhaust the
   machine's memory, the same reason as for live testing.
3. **Live suites follow the live-testing rules**: one run per database at a time (every repo
   has its own database on the shared PostgreSQL, so runs of different repos may overlap),
   the harness serial, every run through `maint/capped-test`.
4. **On failure, keep going.** A failed repo does not stop the others: mark it with
   `karr edit <id> --block "<reason>"` and move on. Dependents of the failed repo are
   skipped; siblings are not.
5. **Report at the end** — per repo: what landed (commit ids), what is blocked and why,
   what still needs a push. A block is done only when no part of it is blocked.
