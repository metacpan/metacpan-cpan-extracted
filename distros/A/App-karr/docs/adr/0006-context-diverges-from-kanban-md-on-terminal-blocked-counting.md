# `karr context` diverges from kanban-md on terminal-blocked counting

`karr context` builds a briefing block -- a header count of blocked cards and a
`blocked` section -- that karr and kanban-md maintain together inside a shared
host file (e.g. `AGENTS.md`), delimited by the same `BEGIN/END kanban-md
context` sentinels. Because the markers are shared, whichever tool runs last
rewrites the block. For a while the numbers were shared too: kanban-md's
`computeSummary` counts a card as blocked even once it reaches a terminal status,
and ticket #229 deliberately matched that here so a board co-driven by both
tools always wrote identical numbers.

Ticket #295 reverses that call for the blocked number. A card in a terminal
status (`done`, `archived`, or any board-configured terminal column) is
finished, and a finished card is not an active blocker -- even if it still
carries a `blocked` flag from before it got there. Leaving such cards in the
count made a dead ticket read as a perpetual blocker and, on `karr board`,
counted-but-invisible: the default view hides the terminal column, so the number
named cards nobody could see. `karr board`'s footer already excludes them; this
brings `karr context` in line, so both surfaces answer "what is blocked?" the
same way.

The flag itself is never touched. `block_reason` stays on the card as
provenance (the #223/#224 convention), and `karr list --blocked --status done`
still surfaces it. Only the *default* briefing stops counting and listing it.

## What this accepts

The blocked count karr writes into the shared sentinel block can now differ
from the one kanban-md would write for the same board: kanban-md still counts
terminal-blocked cards, karr no longer does. On a board driven by both tools the
number flips depending on which ran last. This is accepted -- a done card is not
an active blocker, and matching kanban-md on a misleading number was never worth
more than getting the number right. The sentinel *markers* stay identical, so no
block is orphaned and either tool can still update the other's block; only the
value inside may differ.

The header total and the `recently-completed` section are unchanged: finished
work still counts towards the total (kanban-md's `IsArchivedStatus` boundary,
which drops only `archived`), so `context`'s `@context_tasks` stays wide and only
the individual summary values that must not see terminal cards -- `active`,
overdue, the in-progress section, and now `blocked` -- carry their own
`is_terminal_status` test.

## Consequences

`Cmd/Context.pm`'s blocked count and `blocked` section now filter terminal
statuses. The `#229` rationale that once forbade this is superseded here and in
the code comments beside it; a future reader who re-widens the count to "match
kanban-md" would be re-reverting a decision, not fixing a drift. kanban-md has
no parity obligation on this number going forward.
