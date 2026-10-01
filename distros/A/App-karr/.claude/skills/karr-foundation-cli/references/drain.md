# Run modes, the drain loop, and on_drained

## Run mode

`drain: true|false` is the older spelling of the first two (`true` = `drain`,
`false` = `single`) and still works. They are one key with an alias, not two
switches: `mode` is asked first, `drain` answers only when `mode` is absent, and
a per-repo `drain` still beats a config-wide `mode`. An unrecognised `mode` is an
error that skips that repo, never a silent fall back to draining it.

### Ticket mode

Before the agent starts, foundation picks the card the run is about — `karr
pick`'s eligibility (not terminal, not in `backlog`, not blocked, not held by a
live claim; an expired claim no longer holds one) and `karr pick`'s ranking
(class, then priority, then id). The agent is told twice: the id is spliced
into `$PROMPT` as a closing sentence, and exported as `$KARR_TASK` for a command
template that wants the bare number. Nothing is appended to the command itself.

Foundation names the card; it does **not** claim it. The claim is the agent's
work session (the `KARR_CLAIM` foundation exports for the run, which the
agent's `move` and `handoff` default to),
and `.karr.lock` plus one-agent-per-repository already keep anybody else off the
card for the length of the run. An agent that dies leaves at most its own claim
— cleared by `claim_timeout`, or by `karr unlock` for a pick lock — and one
attempt.

The run is judged by that card, not by the board hash: **progress** when it
moved, **stall** when it did not, whatever else on the board moved meanwhile. A
stall bumps that card's attempt counter and auto-blocks it at `max_attempts`,
under the same ownership guard as a drain. With no assignable card, **no agent
is started at all** (`TICKET none assignable` in `.karr.log`, outcome `idle`);
`--force` and `on_idle: always-run` force the check, not a run without a card.

## Drain loop semantics

Each iteration runs `command` once, then classifies result:

| Outcome | Meaning | Action |
|---------|---------|--------|
| **progress** | board changed | keep draining |
| **stall** | a task *this run's agent engaged* didn't move | bump attempt counter; auto-block after `max_attempts` |
| **common-error** | bad exit, timeout, or an error pattern in a run that moved *nothing* | exponential backoff, no task penalty |
| **idle** | agent did nothing, grabbed nothing | stop |

`--dry-run` never reaches this table: the loop stops right after logging the
would-be START, before progress, stall or idle is scored for that iteration
(#314). So a dry run never logs STALL and never counts toward auto-block.

**What a run did is asked before what it printed.** A run that exited 0 and
moved the board is progress whatever scrolled past it, and is never
reclassified by its own transcript; the output is scanned only for a run that
moved nothing at all — which is what a rate-limited or unauthenticated agent
looks like. A pattern seen in a run that *did* move the board is noted in
`.karr.log` and otherwise ignored. The default patterns are narrow to match: a
symptom word counts next to a failure word on the same line (`network error`,
`invalid credentials`, `quota exceeded`), and an HTTP status only where
something adjacent marks it as one (`API error: 429`, `429 Too Many Requests`)
— not in a diffstat, a byte count or a line number. Before that, an agent
printing its own board tripped the scan on a backlog title and throttled a
healthy board to one run per hour (#160).

### Auto-block

When a task is stuck after `max_attempts`, foundation marks it blocked with:
```
blocked: auto-block: no progress after N attempts (foundation)
```
Agent can override with `karr edit --block "reason"`.

**Engaged** means foundation can prove the agent worked that card during *this*
drain: it runs the command with `KARR_ROLE=agent`, so the agent's `karr` writes
land in the board's activity log under the `agent` identity, and only tasks
named there — unclaimed, or held under a claim name the agent itself wrote
with — can be penalized. A card somebody else holds is never auto-blocked,
nor is one the agent merely left claimed in an earlier run (that is what
`claim_timeout` and `karr unlock` are for). Without that evidence — an agent
command that never calls `karr` — foundation auto-blocks **nothing** rather
than guess (#158).

### Exponential cooldown

On common-error: repo waits `cooldown_base × 2^level` minutes (capped at `cooldown_max`).
Level resets on next clean (non-error) run, which also drops `last_error` from
`.karr.state` — it describes the last run, not a past one.

## The domain hook (`on_drained`)

When a board has **drained** — no actionable task left on it, everything in the
board's own final status (or archived), held back in `backlog`, or blocked —
`on_drained` runs a configured command in it. karr does
not know what that command does and must not: the exit code goes to `.karr.log`
and `.karr.state` and is interpreted by nobody. A hook that fails does not park
the board, does not mark the board's agent failing and is never the run's
`last_error`; it is not an agent run and is not classified as one, so no report
is read out of it, no error pattern is matched against it, no ticket is
assigned to it.

It is told where it is and nothing else: `KARR_REPO`, and `KARR_ROLE=hook` so
its own `karr` writes land in their own activity log instead of counting as the
agent's engagement with a card. `PROMPT` and `KARR_TASK` are empty. It runs in
the board's directory, under the board's own `.karr.lock`, with the same
process-group kill and the same tee to `.karr.log` an agent gets — but on its
own budget, `on_drained_max_runtime` (default 1800), because how long an agent
may take says nothing about how long a release gate may.

A drain that ended in `common-error` does not count as drained: a rate-limited
agent leaves a board that looks exactly like one it worked through, and
foundation does not believe that run. Two guards bound the hook, and `--force`
overrides both:

- **The same board is not asked twice.** The board fingerprint the hook last
  ran at is kept in `.karr.state`; a board that has not moved since gets no
  second run — otherwise a repository nobody touches starts a gate on every
  tick for ever, because a drained board stays drained.
- **A chain that never settles is capped.** Consecutive rounds in which the
  hook itself put work back on the board are counted; a run that leaves the
  board alone — the gate that finally passed — clears the count, and at
  `on_drained_max_rounds` (default 3, `0` disables) the hook is suppressed with
  a line in `.karr.log`.

A hook that files tickets is the point, not a failure mode: the board is no
longer drained, the next tick works them, the board drains again and the hook
is asked again.
