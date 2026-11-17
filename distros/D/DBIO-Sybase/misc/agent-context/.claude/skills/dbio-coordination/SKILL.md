---
name: dbio-coordination
description: Use when work in one DBIO repo touches another — which repo owns what, and how to hand a ticket to another repo's board.
user-invocable: false
allowed-tools: Read, Bash, Glob
model: sonnet
---

# DBIO Cross-Repo Coordination

The DBIO family is **many independent CPAN distributions**, each its own Git repo. There is no central workspace. Coordination happens two ways: `karr` tickets pushed to repo remotes and picked up by the receiving repo's agent, or — for a block of dependent work that needs one head — by starting a Claude inside the target repo directly (see *Direct cross-repo execution*).

## Repo ownership

| Concern | Owning repo |
|---------|-------------|
| Schema, ResultSet, Row, Cursor, SQLMaker core | `dbio` |
| Test infrastructure (`DBIO::Test::Storage`, mocks) | `dbio` |
| Storage::DBI base class, Storage::Async base | `dbio` |
| Driver registration, capability system docs | `dbio` |
| Driver-specific Storage (Pg/MySQL/SQLite/…) | `dbio-<driver>` |
| Driver-specific SQLMaker (JSONB ops, CONNECT BY) | `dbio-<driver>` |
| DB-version capability detection per driver | `dbio-<driver>` |
| Cake driver flags (`cake_defaults`) | `dbio-<driver>` |
| Shared Future::IO async base (`DBIO::Async::Storage`, the `future_io` mode) | `dbio-async` |
| `future_io` adapter `DBIO::<Driver>::Storage::Async` | `dbio-<driver>` |
| Native `ev` transport `DBIO::<Driver>::EV` (Pg, MySQL) | `dbio-<driver>-ev` |
| `forked` mode (`DBIO::Forked`) | `dbio-forked` |
| Dist::Zilla bundle `[@DBIO]` | `dbio-dzil` |
| Family skills (this one included), house rules, shared agents | `dbio` (skilletor source `dbio-core`; every other repo installs them) |
| Shared DDL case table `DBIO::Test::Conformance`, `AsyncHarness`, `StorageLayer`, `Kubernetes`, `maint/capped-test`, `maint/live-preflight` | `dbio` |
| Driver's conformance subclass `DBIO::<Driver>::Test::Conformance` (ADR 0060) | `dbio-<driver>` |
| Extensions over a driver (AGE, PostGIS, GraphQL) | `dbio-postgresql-age`, `dbio-postgresql-postgis`, `dbio-graphql` |
| Tombstones of retired module names | `dbio-deprecated` |

## Decision rule when a ticket arrives

```
ticket is about SQL gen abstraction / Storage API / Schema / Test::Storage
  → keep in dbio
ticket is about DB-specific bug / feature / capability
  → push to dbio-<driver>
ticket is about release tooling / dist.ini bundle
  → push to dbio-dzil
ticket is about the async base / fork-per-query / an EV transport / an extension
  → push to dbio-async / dbio-forked / dbio-<db>-ev / the extension's repo
ticket is about a retired module name
  → push to dbio-deprecated
ticket needs change in both core + driver
  → split into two tickets, link via tags, set-refs or karr's native `--needs BOARD#ID`
  a driver case for the shared case table
  → one card in core (the case) plus one card per driver
```

## Cross-repo handoff via karr

There is **no shared karr board**. Each repo has its own `refs/karr/*`. Cross-repo handoff = create a ticket in another repo's remote and let its agent pick it up.

### Posting a ticket to another repo

From inside repo A, to post a ticket to repo B:

```bash
# Option 1: CD into the other repo locally (fast, no network)
( cd ../dbio-postgresql \
  && karr create "Add JSONB @? operator" \
       --priority high \
       --body "Originated from dbio core ticket kNN. Needed by SQLMaker test t/sqlmaker/json.t." \
  && karr sync --push )

# Option 2: If remote-only (other repo not checked out)
git push <other-repo-remote> refs/karr/tasks/<new-id>/data
```

The receiving agent picks it up on its next `karr-foundation` run via `karr sync --pull`.

### Loop prevention

Loops would only happen if agents ping-pong tickets back and forth. Prevent by:

1. **Always read existing tickets first** — `karr list` shows all open work and includes prior cross-repo notes. If a ticket already exists pointing to this work, comment on it via `karr edit` instead of creating a new one.
2. **Tag cross-repo tickets** with `from:<source-repo>` and the originating ticket ID — receiving agent can see the chain.
3. **Use `karr set-refs` for shared plan documents** that several agents need to read without each creating a new ticket.
4. **One agent claims the chain end-to-end** when feasible — fewer handoff hops = less drift.

### Handoff back

When repo B completes the work:

```bash
karr handoff <id> --claim "$(karr agentname)" \
  --note "Done. Commit abc123 in dbio-postgresql." \
  --timestamp

# Optionally notify origin repo
( cd ../dbio \
  && karr edit <originating-ticket-id> \
       -a -t "Resolved downstream in dbio-postgresql ticket kNN (commit abc123)" )
```

## Direct cross-repo execution — one block, one head

Ticket-and-wait works for independent work. It does not work for a **block**: one head
ticket (usually in core) plus the driver-side tickets that depend on it. Split across
detached agents, nobody holds the connection between them and the block drifts. For a
block, the coordinating agent drives every repo in one pass.

Cross-repo work is always briefed work: a repo's files are changed by a Claude started
**inside** that repo, which comes up with that repo's `CLAUDE.md`, its house rules under
`.claude/rules/`, its agents and its skills. A subagent spawned from here carries this
repo's briefing only.

**Who does this:** the coordinating main agent — the one holding the block and its
context. A worker agent never starts a target-repo Claude: when it needs downstream
work it files a ticket (a note on its card; the dispatcher files it).

The call (`claude -p` in the target repo with `--model`, `--permission-mode`,
`--max-turns`), the four things the prompt names (ticket id on the target board, why it
exists, the scope, which worker) and the order of running a block (core first, one repo at
a time, keep going on failure, report at the end): `references/direct-execution.md`.
The headless mechanics are skill `claude-headless`.

### Scope of a target-repo run

Allowed: read, implement, run the offline suite, `git commit` locally, and move its karr
ticket (`karr move` / `karr handoff` — board mutations auto-sync, and that is fine: the
board is coordination state, not code).

Outside the scope: `git push`, `git tag`, `dzil release`, any CPAN upload and any Codeberg action. Code leaves the machine only on the maintainer's decision, after the
block report.

**Report the suite, not your own file.** A run reports the result of the whole recursive
suite — including failures it did not cause. A pre-existing red test is a finding to hand
back. The coordinating agent re-runs the suite anyway, so a run that claimed green while
`Result: FAIL` stood spends the trust the whole arrangement rests on. Establish whether a
failure predates the run before reporting it — a throwaway worktree on the previous commit
settles it in a minute:

```bash
git worktree add -q --detach "$TMPDIR/wt-prev" HEAD~1
( cd "$TMPDIR/wt-prev" && prove -l t/the-failing-file.t )   # same failure = not yours
git worktree remove --force "$TMPDIR/wt-prev"
```

## Shared plan storage via set-refs

For plans / specs that multiple repos need to consult but shouldn't be a ticket:

```bash
karr set-refs dbio/plan/jsonb-operators.md <<'EOF'
# JSONB operator addition plan
...
EOF

# Other repos pull:
karr get-refs dbio/plan/jsonb-operators.md
```

Pushes via `karr sync --push`. Other repos see it after their `karr sync --pull`.

## Multi-machine / distributed teams — karr-foundation

Each maintainer's machine has its own clone of each DBIO repo; karr refs are synced via
Git remotes. `karr-foundation` scans configured boards and drains the ones with open
work. Its use, its configuration and the per-board opt-out (`karr disable`) are in skill
`kanban-issues-karr-coordination` (`references/config.md`). Agent execution is opt-in per
repo through its `.karr` file; a global `default_command` in the foundation config turns
every discovered board into an agent board.

## Boundaries

- Another repo's files are changed by a Claude started in that repo, or the work goes there as a ticket (*Direct cross-repo execution*).
- One target-repo Claude runs at a time, serially.
- A target-repo run ends with its local commit; the push is the maintainer's call.
- A ticket is created after checking that none exists for the same work.
- A claim is released across long cross-repo waits, so the originating agent can pick the card up again when downstream is done.
- The directory holding the DBIO checkouts only holds independent checkouts side by side; there is no shared repo and no shared board. Each repo is independent.
- Installed files (`.claude/agents/.local.*`, `.claude/rules/.local.*`, a skill dir carrying a `.gitignore`) are changed in their source repo (family skills, house rules and shared agents: `dbio` core), then `skilletor sync` where they are installed; from a driver that is a ticket on core's board.
- A fresh clone is briefed after `skilletor sync`: the installed skills, the house rules and the shared agents are git-ignored.
