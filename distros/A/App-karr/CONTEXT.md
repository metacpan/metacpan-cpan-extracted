# App::karr

Git-native, file-compatible kanban board for multi-agent workflows. Canonical
state lives in `refs/karr/*`; the `tasks/` directory is a materialized view.

## Language

**Claim**:
An active, expiring lease an agent holds on a **Task** while working it —
recorded as `claimed_by` (+ `claimed_at`). It is *not* authorship: it expires
(see Pick claim-timeout) and is released when the Task reaches a terminal
status — on a `done`/`archived` Task the claim guards nothing, and `edit`,
`move`, `delete`, `archive` and `handoff` all go through whoever the field
names. `karr board` shows no claimant on such a Task and leaves it out of its
claimed count, because the board shows live work-in-progress, not history;
`karr show` and `--json` still carry the field, as provenance. That provenance
ends where the work resumes: a Task leaving a terminal status for a working one
has `claimed_by`/`claimed_at` cleared, unless the reopening command names a
claimant itself (`move ID todo --claim NAME`, `handoff`), in which case that
agent holds it. `done` → `archived` keeps the name — archiving does not resume
anything.
_Avoid_: owner, lock (the advisory ref lock is a separate mechanism).

**Assignee**:
The intended doer of a **Task** (`assignee`), set by a human/planner. Distinct
from **Claim**: assignee is intent, claim is who actually picked it up now.
_Avoid_: owner.

**Activity log**:
The durable Verlauf of actions, stored in `refs/karr/log/*` and read via
`karr log`. Survives independent of Task frontmatter — so clearing or hiding a
field on a Task never loses its history.
_Avoid_: changelog (that is the release `Changes` file), `.karr.log` (that is
the foundation agent's per-run stdout capture).

**Task lifecycle**:
A **Task** carries timestamps for each milestone it passes: `claimed_at`,
`started`, `completed`. `done` and `archived` are the terminal statuses.
Terminal means *closed*, not *succeeded* — karr has a notion of progress and
none of outcome. A card given up in the backlog and archived is
frontmatter-identical to one archived after `done`: `update_timestamps` stamps
`completed` on every terminal status and backfills `started`, so `karr archive`
on a never-touched card records both a start and a completion, and no field
says why the card ended. This is why a cross-board `needs:` link settles as
soon as the far card is terminal — because that card is *closed*, not because
it succeeded. Narrowing the rule to the `done` equivalent could only guess, and
it would guess wrong in the common case, `done` → `archived` being the normal
way a finished card is put away: the waiting card would stay blocked with
nothing left on the far board able to unblock it, that card being terminal
already. A false success that lets work continue is the cheaper error. The
local `depends_on` side reads the rule the same way, but writes nothing: an
archived dependency satisfies it silently, and `karr show` keeps printing
`Depends: 1 (archived)`, so the word stays on the card. `karr needs --resolve`
does write — tag gone, block gone, in another repository — which is why the
same reading deserves more caution across boards than within one. Giving a card
up is therefore something to say on the far board yourself.
_Avoid_: "settled"/"resolved" read as "succeeded" — both say only that the far
card is closed.

**Identity**:
Who is acting, as `<role>/<git-email>`. The git email comes from git config;
the **Role** disambiguates a human and an AI that share one git email. Keys the
**Activity log** ref (`refs/karr/log/<role>/<email>`) and resolves `show --me`.
_Avoid_: user (the bare word — it is one *value* of Role, not the identity).

**Role**:
`user` (default) or `agent`. Propagated to nested `karr` calls via the
`KARR_ROLE` env var — foundation sets `agent`; an interactive human defaults to
`user`. The env var is the carrier precisely because it propagates to child
processes; a CLI flag would not, so a manual override is also the env var
(`KARR_ROLE=user karr …`).

**Foundation**:
The multi-board coordinator (`karr-foundation`) that sweeps several boards in
sub-directories. It serves two first-class users: a **HUMAN** coordinating their
own work, and an **agent** (role `agent`) driving tasks. Agent execution is
opt-in (`claude: true` or an explicit `command:`); with no agent configured its
default action is the read-only **Overview**.

**Disabled board**:
A board that opted out of automated agent runs in its own karr state
(`foundation.enabled` in `refs/karr/config`, written by `karr disable
[--reason]`). Board state, not machine state — it syncs, so every foundation
instance on every machine honours it, unlike the local `.karr` file. The opt-out
is absolute: checked before agent-command resolution and before the drain
decision, so it wins over `--command`, `default_command`, the `.karr` `command`
and `claude: true`, and `--force` does not override it. A parked backlog stays
fully usable by hand; only automation is switched off.

**Overview**:
Foundation's read-only dashboard (`--status`, or the default when no agent is
configured) — per board: status counts and what is
in-progress/claimed/blocked, plus which repos are locked (agent running) or in
cooldown. Fires no agent.

**Context block**:
The sentinel-delimited board summary (`karr context --write-to`) maintained
inside a host file such as `AGENTS.md`. karr deliberately writes kanban-md's
markers (`<!-- BEGIN kanban-md context -->`) so both tools can update the same
block and switching tools leaves no orphaned markers — an interop decision,
not a branding leftover.
_Avoid_: renaming the sentinels to "karr" (breaks cross-tool round-trips).

**Claim name**:
The name a card is held under, passed per `pick`/`move`/`handoff`/`edit`/`create`
via `--claim` (defaulting to **KARR_CLAIM** when the flag is omitted), stored in
`claimed_by` and in the **Activity log** entry's `agent` field. `karr agent-name`
derives it from the checkout's own directory name. Distinct from **Identity**: a
single Identity may run under many Claim names over time.

**KARR_CLAIM**:
The **Claim name** carried per process — the default `--claim` reads when the flag
is omitted (ADR 0005). Set once per session (`export KARR_CLAIM=$(karr
agent-name)`); an explicit `--claim` overrides it. Per process and never stored,
so concurrent agents never share one — the counterpart for the claim name of what
`KARR_ROLE` is for the **Role**. Not the log **Identity**: `show --me` stays the
Identity, not `KARR_CLAIM`.
_Avoid_: calling it a "stored" or "remembered" claim — it lives only in the
process environment.

**Parent / Subtask**:
Deliberately *not* a concept. kanban-md's hierarchical cards (`--parent`) are a
documented non-goal: karr's answers to "this card relates to that one" are
`depends_on` (local ordering) and `needs` (cross-board). The `parent` field
round-trips through `karr import` unchanged — no data loss — but no karr
command sets, filters, renders or sorts it (see `Task.pm`), so a kanban-md board
that needs hierarchy keeps it in kanban-md.
_Avoid_: "parent"/"subtask" as karr vocabulary.

## Relationships

- An **Agent** holds at most one **Claim** on a **Task** at a time; the Claim
  expires if not refreshed.
- A **Task** has at most one **Assignee** (intent) and at most one **Claim**
  (active lease) — these may name different agents.
- Every state change to a **Task** appends to the **Activity log** under the
  acting **Identity**.
- One **Identity** (`<role>/<email>`) may use many **Claim names** over time;
  `show --me` resolves the Identity's most recent Activity-log entry.

## Flagged ambiguities

- `claimed_by` read as "authorship/who-finished-it" vs. "active lease" —
  resolved: it is an **active lease**. Provenance of who finished a Task comes
  from the **Activity log**, not from a retained claim. A terminal claim is
  released: it blocks no command, and `karr board` neither shows nor counts it.
  The data field is intentionally kept for interop/provenance, so the detail
  views — `karr show` and every `--json` payload — do still print it. It is
  kept on a *finished* Task only: a reopen that names no claimant clears it,
  because a name carried into a working column is a lease again and made the
  Task unpickable by anyone.
- "owner" used loosely for both **Assignee** and **Claim** — resolved: these
  are distinct; avoid "owner".
