---
name: dbio-coordination
description: "Cross-repo workflow for the DBIO distribution family. Which repo owns what. How to hand off work via karr tickets pushed to other repos' remotes."
user-invocable: false
allowed-tools: Read, Bash, Glob
model: sonnet
---

# DBIO Cross-Repo Coordination

The DBIO family is **many independent CPAN distributions**, each its own Git repo. There is no central workspace. Coordination happens via `karr` tickets pushed to repo remotes, picked up by the receiving repo's agent on next `karr sync --pull`.

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
| Async pool, pipelining (Pg/MySQL Async) | `dbio-<driver>-async` |
| Dist::Zilla bundle `[@DBIO]` | `dbio-dzil` |
| Cross-driver coordination skill (this) | `dbio` (source of truth, hardlinked) |

## Decision rule when a ticket arrives

```
ticket is about SQL gen abstraction / Storage API / Schema / Test::Storage
  → keep in dbio
ticket is about DB-specific bug / feature / capability
  → push to dbio-<driver>
ticket is about release tooling / dist.ini bundle
  → push to dbio-dzil
ticket needs change in both core + driver
  → split into two tickets, link via tags or set-refs
```

## Cross-repo handoff via karr

There is **no shared karr board**. Each repo has its own `refs/karr/*`. Cross-repo handoff = create a ticket in another repo's remote and let its agent pick it up.

### Posting a ticket to another repo

From inside repo A, to post a ticket to repo B:

```bash
# Option 1: CD into the other repo locally (fast, no network)
( cd ~/dev/perl/dbio-dev/dbio-postgresql \
  && karr create "Add JSONB @? operator" \
       --priority high \
       --body "Originated from dbio core ticket #42. Needed by SQLMaker test t/sqlmaker/json.t." \
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
( cd ~/dev/perl/dbio-dev/dbio \
  && karr edit <originating-ticket-id> \
       --note "Resolved downstream in dbio-postgresql ticket #N (commit abc123)" )
```

## Shared plan storage via set-refs

For plans / specs that multiple repos need to consult but shouldn't be a ticket:

```bash
karr set-refs dbio/plan/jsonb-operators.md - <<'EOF'
# JSONB operator addition plan
...
EOF

# Other repos pull:
karr get-refs dbio/plan/jsonb-operators.md
```

Pushes via `karr sync --push`. Other repos see it after their `karr sync --pull`.

## Multi-machine / distributed teams

Each maintainer's machine has its own clone of each DBIO repo. karr refs are synced via Git remotes. `karr-foundation` (when implemented) polls each `.karr` configured repo periodically and runs the configured agent command on state change. Result: 24/7 agent network with no central server.

## What NOT to do

- ❌ Edit code in another repo from this repo's agent. Cross-repo work = ticket, not direct push.
- ❌ Create a ticket without first checking if one already exists for the same work.
- ❌ Hold a claim across long-running cross-repo waits — release the claim and let the originating agent pick it up again when downstream is done.
- ❌ Treat dbio-dev/ as a workspace root. It is a graveyard for archived material. Each repo is independent.
