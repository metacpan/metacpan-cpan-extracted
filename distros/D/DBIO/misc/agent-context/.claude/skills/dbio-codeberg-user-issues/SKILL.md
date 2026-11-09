---
name: dbio-codeberg-user-issues
description: Use whenever Codeberg, Forgejo, the fj CLI, public issues or user bug reports come up in a DBIO repo. Not the agent work board — that is kanban-issues-karr-coordination.
---

# DBIO Codeberg User Issues (`fj`)

DBIO has **two separate trackers. Do not confuse them.**

| Tracker | What it holds | Tool | Who writes it |
|---|---|---|---|
| **karr** | AI/agent work board — internal kanban, cross-repo handoffs | `karr` CLI (`refs/karr/*`) | agents, internally |
| **Codeberg issues** | **PUBLIC user tickets** — real humans' bug reports & feature requests | `fj` CLI | the community |

`karr` is *ours*, internal, churned freely. Codeberg issues are **outward-facing and
written by real people**. They are a different universe — never route agent/internal work
there, and never treat a Codeberg issue as if it were a karr ticket.

## THE HARD RULE — `fj` only on explicit instruction

**Never invoke `fj` on your own initiative — not even to read.** No proactive listing,
searching, viewing, commenting, editing, or closing of Codeberg issues. You touch this
tracker *only* when the user explicitly tells you to (e.g. "look at Codeberg issue #42",
"reply to that bug report"). With no such instruction, stay out of `fj` entirely.

Even **with** an instruction, every *write* (`create` / `comment` / `edit` / `close` /
`assign`) is published to a public tracker under **the signed-in Codeberg account** —
outward-facing and hard to take back. Confirm the exact wording before sending; when in
doubt, show the draft and ask. Reading (`search` / `view`) needs the instruction but no
extra confirmation.

## Setup — authenticate first (each person, each machine)

`fj` acts under **whoever is logged in**, not a shared account — every person working in this
repo signs in with their own Codeberg login. Nothing below works until you have:

```bash
fj auth login      # sign in to codeberg.org (token/browser flow); once per machine
fj whoami          # confirm the signed-in account
fj auth list       # list instances you're logged into
```

If `fj whoami` errors or shows no one, you are not logged in — there is no access until
`fj auth login` is run (and only do so when the user actually wants `fj` used; see the hard
rule). Every DBIO repo's `origin` points at `git@codeberg.org:dbio/<dist>.git`, so once
signed in `fj` targets the current repo's public issues by default; `-R origin` makes it explicit.

## Reading issues (only when instructed)

```bash
fj issue search                       # open issues on this repo's origin
fj issue search "limit prefetch" -s all   # query; -s open|closed|all
fj issue search -l bug -a <user>      # filter by --labels / --assignee / --creator
fj issue view 42                      # title + body of issue #42
fj issue view 42 comments             # list its comments
fj issue templates                    # available issue templates
```

`fj pr search` / `fj pr view <id>` read pull requests the same way.

## Writing issues (only when explicitly instructed — outward-facing)

```bash
fj issue comment 42 "Fixed in <sha>, thanks for the report."   # public comment
fj issue create "Title" --body "…"        # or --body-file FILE; omit --body opens $EDITOR
fj issue edit 42 title|body|labels|comment # edit a field
fj issue close 42 -w "Resolved in vX.Y"    # close, optional closing comment
fj issue assign 42 <user>                  # assign user(s)
```

Prefer `--body-file` for anything multi-line so the published text is exactly what was
reviewed. Same shape for `fj pr comment|edit|close|merge`.

## Quick guard checklist

- [ ] Did the user explicitly ask me to touch Codeberg / `fj` / a user issue? If not → **do not run `fj` at all.**
- [ ] Is this a *user* ticket (Codeberg), not an *agent* ticket (karr)? Right tool for the tracker.
- [ ] Writing? It is public and under the signed-in Codeberg account → confirm the wording first.
