---
name: kanban-issues-karr-coordination
description: Use when reading a karr board, picking or claiming cards, creating cards, handing cards to subagents, filing on another repository's board, or configuring and syncing karr. For working one card you were handed: kanban-issues-karr-ticket.
---

# karr — Kanban Assignment & Responsibility Registry

Git-native kanban board for multi-agent work. The board is the repository's
`refs/karr/*`: commands read and write those refs directly and sync them with
the remote; nothing lands in the work tree. In prose (commit subjects, card
bodies) a card is `k12`, never `#12` — the forge resolves `#12` against its
own issue 12. Commands take `k12` as well as `12`.

## Name yourself once

```bash
export KARR_CLAIM=$(karr agent-name)     # the checkout's directory name, e.g. "karr"
```

Claims are matched by name: `--claim` stamps it, `handoff` checks it,
`list --claimed-by` selects on it. Export `KARR_CLAIM` once per session and
leave `--claim` off: `pick`, `handoff` and `list --claimed-by` default to it,
and `move` and `edit` know a card you hold by it. `create`, `move` and `edit`
write it onto a card only when the card ends up in a `require_claim` column:
filing a card, promoting it to `todo` or adding a note leaves it free.
`archive` and `delete` ignore it — a card you hold needs `--claim NAME` there.
An explicit `--claim NAME` still wins. Agents in separate worktrees already
differ by name; several agents in the **same** directory take
`karr agent-name --unique` (`karr-8fa`).

## Read the board

```bash
karr list --compact                      # open cards, one line each
karr board                               # per-column summary; --done shows the final column too
karr show 12                             # one card in full, body included
karr list --unclaimed --status todo      # todo cards no live claim holds
karr list --blocked                      # what is stuck, and why
karr show --me                           # the card you last touched (re-orient)
```

`list` hides the final column (`done`) and the archive unless asked for by
name (`--status done`, `--archived`).

## Hand out and close cards

The coordinating agent picks and claims; whoever does the work gets the card id
and works it with skill `kanban-issues-karr-ticket` — load both when you work a
card yourself.

```bash
karr pick --status todo --move in-progress       # most urgent free card, claimed as $KARR_CLAIM
karr move 12 in-progress                         # or take a specific one
karr move 12 in-progress --claim NAME            # explicit claim, wins over KARR_CLAIM
karr list --status review                        # what workers handed back
karr edit 12 --release && karr move 12 done      # close it once the work is committed
```

Columns with `require_claim` (`in-progress`, `review` on a default board)
refuse a move without a claim. A claim expires after `claim_timeout` (default
1h) and the card is free again; `pick` skips blocked cards and live claims.

`backlog` is held back: `pick` and karr-foundation never take a card from it
(`pick --status backlog` exits 2), and it holds no claim (`--claim` there is
refused; moving a card into it releases the claim). `todo` is the pool.
Promoting a card out of backlog (`karr move ID todo`) is the maintainer's
call, not a coordinating agent's: leave backlog alone unless told to promote.

Life cycle with subagents: you claim and hand the id out → the worker notes on
the card and hands it to `review` → whoever commits the work moves it to
`done`, naming the commit. A subagent in the same directory gets the same
`agent-name`, so your claim is its claim.

**Serialize board mutations when fanning out.** Every mutating command pulls and
pushes `refs/karr/*`; N of them landing at once is a resource event. Hand out
cards one after another, and batch your own moves sequentially.

## Create a card

```bash
karr create "Title" --priority high --tags cli,bug --body 'What is wrong, how to reproduce, what done looks like'
karr create "Start now" --status in-progress     # claimed as $KARR_CLAIM at creation
karr create "Ship it" --depends-on 2,3           # board-local dependency; ids must exist
karr create "New card" --json                    # the card as JSON: pipe the id onward
```

Waiting for another project's release is not a card, and no reason to keep
one open or blocked: the dependency pin (`cpanfile`, `package.json`, …) set to
the version in that project's tree — its next release — already says it. Close
the card once the work is committed.

Bugs found on the way become cards, not silent fixes. A new card lands in
`backlog`, unclaimed, unless `--status` puts it elsewhere: into a
`require_claim` column when you are starting it, with the claim that needs.

## Create a card on another repository's board

The board is the *target* repository's `refs/karr/*`, so a card is filed by
running `create` inside a checkout of that repository — there is no way to
name a remote and post to it directly:

```bash
karr --dir ../other-board create "Title" --body '...'   # a sibling checkout you already have
git clone URL ../other-board && cd ../other-board       # or clone one first, as a sibling
karr create "Title" --body '...'                        # create; it pulls, then pushes
```

Check the clone out as a **sibling of your current checkout — never inside its
working tree** — named for the board, where your fleet keeps its repositories.
Inside the tree it would be mixed into this repo and could be committed by
accident; a sibling stays separate, and a `needs:BOARD#ID` reference resolves
the board name to a directory by that basename (from `--board NAME=PATH` or the
fleet config) — a clone parked anywhere else is a card no one can trace back.
A fresh `git clone` carries no `refs/karr/*`, but `create` pulls the board
first (it is a mutating command), so the new id continues the remote's count —
no separate `karr sync --pull`. To record the new card as
something work *here* waits on, escalate it —
[references/cross-board.md](references/cross-board.md).

## Output flags

`--json` is taken by every board command, not by `backup`, `restore`,
`destroy`, `sync`, `set-refs`, `get-refs`. `--compact` exists on exactly nine:
`board`, `config`, `context`, `dashboard`, `list`, `log`, `metrics`, `pick`,
`show` — anywhere else it is `Unknown option: compact`, exit 2.

## When you need more

| Need | Read |
|---|---|
| Every option of `create`, `show`, `move`, `edit`, `delete`, `archive`; dependency rules | [references/cards.md](references/cards.md) |
| `list` filters and sorting, `board`, `dashboard`, `log`, `metrics`, `context --write-to` | [references/queries.md](references/queries.md) |
| `pick` ordering, `handoff` options, `unlock` for stale locks, timeouts, several agents on one board | [references/claims.md](references/claims.md) |
| A card waits on another repository: `--needs BOARD#ID`, `--escalated-from`, `karr needs --resolve` | [references/cross-board.md](references/cross-board.md) |
| `config get/set`, writable keys, the config YAML, `disable`/`enable` for karr-foundation | [references/config.md](references/config.md) |
| `sync`, fresh clones, stored card format, `materialize`/`import`, `repair`, `backup`/`restore`/`destroy`, `set-refs`/`get-refs` | [references/storage.md](references/storage.md) |
| `init`, `skill install/check/update`, `completion`, Docker | [references/setup.md](references/setup.md) |
