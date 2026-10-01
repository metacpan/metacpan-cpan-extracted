# A terminal status is finished, and `archived` is one of them

karr does not distinguish "done" from "given up". Every status the board
configures as terminal -- `done` and `archived` in the default config -- means
the card is finished. Cross-board links settle on any of them, `karr needs`
reports `settled`, and `karr needs --resolve` unblocks the card that was
waiting.

This was raised as a defect (ticket #250): a card escalated from board B to
board A, then abandoned and archived on A, reports success to B, and someone
there carries on from a result that does not exist. `karr delete` is louder in
that moment -- `karr needs` calls the link `missing` and refuses to resolve it.

It is not a defect. karr records **progress, not outcome**. The status list is
the only axis it has for this, and terminal is a property of that list (ticket
#67). "Was it achieved?" is a second axis, and adding one would mean a new
field in the ref, a `CrossBoard` that reads it, and a rule for every board that
already settled links under the old one. That is a large change for a
distinction karr does not otherwise make anywhere: nothing else in the tool
asks whether finished work succeeded.

Archiving is also the deliberate exit for an escalated card, precisely because
it keeps the ref readable and the link resolvable (ticket #242). Making
`archived` mean "not achieved" would take that door away again and leave
`delete` -- which breaks the link -- as the only honest way to end one.

## What this accepts

A card abandoned on A unblocks a card on B. The remedy is not a status: whoever
gives up on an escalated card says so where the waiting card is read -- a
comment or a fresh block on B's own card. `karr archive` warns about exactly
this, and `App::karr::Cmd::Delete`'s CROSS-BOARD LINKS section says settling
means closed and not succeeded.

## Consequences

`CrossBoard`'s `link_state` and `karr needs --resolve` stay as they are. No
existing board is re-judged.

Ticket #258 -- have `karr needs` additionally report that the far card was put
away -- must be read against this decision before it is built. It was split off
from #250 on the premise that "given up" is a state worth reporting; under this
ADR karr has no such state to report, and the ticket needs a new premise or
closing.

> Later: karr-foundation compared a card's status to the literal strings
> `done`/`archived` for its own drain detection and the `board_actionable`
> fact, rather than asking the board. k305 changed both to read
> `BoardStore->is_terminal_status` instead -- the same board-derived terminal
> rule this ADR describes now governs foundation too.
