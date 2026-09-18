# Storage: refs, sync, stored format, file view, snapshots, helper refs

The board is `refs/karr/*` in the repository: `refs/karr/tasks/*/data` holds
one card each, `refs/karr/config` the overrides, `refs/karr/meta/next-id` the
counter. Mutating commands pull before and push after; read commands do not
sync as a rule.

## sync

```bash
karr sync                          # pull, then push
karr sync --pull
karr sync --push
karr sync --prune                  # accept a pull that deletes every remaining board ref
karr sync --accept-foreign-board   # accept a pull whose remote presents a different board identity
```

`karr sync` also carries `refs/karr-foundation/*` (chain, run logs, question
mailbox, design documents) after the board, in the same run; mutating commands
sync the board only. Deletions travel: a pruned run log does not come back.

**A fresh clone fetches the board by itself.** `git clone` does not carry
`refs/karr/*`. Where nothing exists under `refs/karr/` and the remote has a
board, the read commands (`board`, `list`, `show`, `log`, `context`,
`metrics`, `needs`, `config show`/`get`) fetch it once and say so on STDERR,
never STDOUT. No remote, or no board there, exits 1 rather than rendering an
empty board — the only place `karr init` is the answer. `KARR_NO_AUTO_FETCH=1`
switches the fetch off where karr must not touch the network.

## Stored card format

```markdown
---
class: standard
created: 2026-03-12T10:00:00Z
id: 1
priority: high
status: backlog
tags:
  - devops
  - needs:other-repo#7
title: Set up CI pipeline
updated: 2026-03-12T10:00:00Z
---

Optional body with more detail.
```

Keys in alphabetical order; `started`, `claimed_at`, `claimed_by`, `completed`
appear once the card reaches that point. This is the document under
`refs/karr/tasks/*/data` and the file `materialize` writes — the format to read
or generate when working on cards programmatically.

## File view (kanban-md interop)

```bash
karr materialize            # refs -> tasks/ + config.yml on disk
karr materialize --force    # overwrite git-tracked cards there
karr import --yes           # tasks/ on disk -> refs (destructive)
```

`tasks/` is a gitignored view for grepping or for kanban-md, never the source
of truth: losing it costs nothing, editing it costs nothing until `import`.
`materialize` refuses to write over paths the project tracks in git unless
`--force` is given.

## repair

```bash
karr repair          # report what would change
karr repair --yes    # migrate
```

Boards written by karr 0.402 or earlier stored UTF-8 double-encoded; they are
repaired on read meanwhile, and this migrates the refs once. It also raises a
`started` stamp written as a bare date (before k68) up to the card's own
`created` — the dry run says how many cards. `completed` stamps with the same
problem are reported, not touched.

## backup / restore / destroy

```bash
karr backup > karr-backup.yml
karr backup --output karr-backup.yml
karr restore --yes < karr-backup.yml       # replaces the whole refs/karr/* namespace
karr restore --yes --input karr-backup.yml
karr destroy --yes                         # deletes refs/karr/* here AND on the remote
```

`restore` and `destroy` are destructive; take a `backup` first.

## Helper refs

```bash
karr set-refs superpowers/spec/1234.md draft ready     # arguments joined with one space: a one-line payload
karr set-refs superpowers/spec/1234.md < design.md      # no content argument: stdin, stored verbatim
karr get-refs superpowers/spec/1234.md > design.md      # back unchanged
```

Shared payloads in Git refs outside the protected namespaces (`refs/karr/*`,
branches, tags): planning blobs, agent scratch data, anything that should sync
through Git without becoming a card. `refs/karr-foundation/chain/*`, `log/*`
and `questions/*` are read-only for `set-refs`; `get-refs` reads them freely.
