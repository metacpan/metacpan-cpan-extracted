# CLAUDE.md — DBIO::GraphQL

This distribution tracks only its own `dbio-graphql*` skills and its config
(`.claude/skilletor.json`). The family skills, the shared agents and the house rules
(`.claude/rules/.local.dbio-rules.md`: discipline, delegation, release) are installed from the
`dbio-core` source through skilletor and are git-ignored. Claude Code auto-loads the rules for
the main agent and all subagents — once they exist.

## Fresh clone — run `skilletor sync` first

A fresh clone or worktree has none of the installed files (rules, family skills, agents) until
`skilletor sync` has run; everything named in this file refers to them. Prerequisites: the
skilletor plugin/CLI (`skilletor@getty`) and network access to the sources in
`.claude/skilletor.json` (github.com/Getty/skills, Getty/karr, codeberg.org/dbio/dbio). Never
edit an installed copy — change the source, then sync again.

## Delegation

Delegate behavior-relevant code (GraphQL schema/type generation, resolvers, mutations,
filters, scalar mapping) to this repo's `dbio-worker-graphql` instead of touching it yourself. Lane
and principle: `.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-graphql` (default),
`dbio-release-manager`, `dbio-adr-auditor`, `karr-coordinator`.

## Namespace

- `DBIO::GraphQL` — GraphQL schema layer over a DBIO schema
- `DBIO::GraphQL::{Relationship,Mutation,Filter,ScalarMap}` — schema/resolver building blocks

DBIO::GraphQL is a schema-generation layer over a DBIO schema, not a database driver — so
there is no Storage/SQLMaker/deploy triad. It owns `dbio-graphql` (using the layer) and
`dbio-graphql-engine` (the underlying GraphQL.pm engine — the counterpart to a DB driver's
`-database` skill); it does not carry `dbio-driver-development`.

## Testing

The suite is offline: the tests build an in-memory SQLite schema (`t/lib/My/Test.pm`, `dbi:SQLite:dbname=:memory:`),
so there is no server, no `DBIO_TEST_*` variable and no live suite for this dist. `t/` has a
`t/lib` subdirectory, so verify recursively and always through the wrapper (house rule 9):

```
../dbio/maint/capped-test prove -lr t/          # whole suite
../dbio/maint/capped-test dzil test             # build + suite
prove -l t/03-queries.t                         # a single file only
```

`prove -l t/` without `-r` skips subdirectories; `capped-test` is core's `maint/capped-test`
(a sibling checkout `../dbio`) and needs no copy here.
