---
name: kanban-issues-karr-ticket
description: Use when you were handed one karr card that is already claimed for you — reading it, noting progress, blocking it, handing it to review. Not for picking, creating or routing cards.
---

# karr — working the card you were handed

Someone else chose and claimed this card and gave you its id. Your whole board
surface is that one card: read it, write what you learn onto it, and hand it
on. The card outlives your session — anything you know that is not on the card
is lost when you stop.

In prose (notes, commit subjects) a card is `k12`, never `#12` — the forge
resolves `#12` against its own issue 12. Commands take `k12` as well as `12`.

## Your name

```bash
export KARR_CLAIM=$(karr agent-name)
```

The claim is matched by name, and `agent-name` is the checkout's directory, so
in the directory where the card was claimed you get the same name and every
command below works without `--claim`. If your brief names a different
claimer, pass `--claim NAME` with exactly that name.

## The card

```bash
karr show 12                                         # full card, body included — read it first
karr edit 12 -a "Cause is in Foo.pm: …" -t           # timestamped note; do this as you learn things
karr edit 12 --block "needs the API change in k7"    # stuck: say why, keep the claim
karr edit 12 --unblock
karr handoff 12 --note "Done: <what changed, how verified>" -t   # to review
```

- **Note as you go**, not only at the end: the cause you found, the decision you
  took and why, what you verified and how.
- **Found something outside the card?** A note on *this* card
  (`-a "Also found: …"`), not a new card and not a silent fix — whoever handed
  you the card decides what becomes of it.
- **Stuck?** `--block` with the reason, then stop and report. Do not wait in a
  loop.
- **Only waiting for another project's release?** Not a block. Once the work
  runs against that project's current tree, pin the dependency (`cpanfile`,
  `package.json`, …) to the version in that tree — its next release — and hand
  the card on. The pin already says the rest.
- **Finished?** `handoff` with a note that says what changed and how it was
  verified. The card is in `review` — that is where your part ends.

## What you do not do

- `pick`, `move` to another column, `create`, `delete`, `archive`, `sync`, or
  anything on another card or another board.
- Move the card to `done`: `done` means the work is committed and accepted,
  and that is not yours to declare.
- Take over a claim: if a command says the card is claimed by someone else or
  the claim expired, stop and report instead of passing a different `--claim`.

Everything else karr can do: skill `kanban-issues-karr-coordination`.
