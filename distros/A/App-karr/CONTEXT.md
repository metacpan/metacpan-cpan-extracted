# App::karr

Git-native, file-compatible kanban board for multi-agent workflows. Canonical
state lives in `refs/karr/*`; the `tasks/` directory is a materialized view.

## Language

**Claim**:
An active, expiring lease an agent holds on a **Task** while working it —
recorded as `claimed_by` (+ `claimed_at`). It is *not* authorship: it expires
(see Pick claim-timeout) and is conceptually released when the Task reaches a
terminal status. The board hides claims on `done`/`archived` Tasks because the
board shows live work-in-progress, not history.
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

**Overview**:
Foundation's read-only dashboard (`--status` / `--overview`, or the default when
no agent is configured) — per board: status counts and what is
in-progress/claimed/blocked, plus which repos are locked (agent running) or in
cooldown. Fires no agent.

**Claim name**:
The ephemeral two-word agentname (e.g. `agent-fox`) passed per `pick`/`move`
via `--claim`, stored in `claimed_by` and in the **Activity log** entry's
`agent` field. Distinct from **Identity**: a single Identity may run under many
Claim names over time.

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
  from the **Activity log**, not from a retained claim. Display hides terminal
  claims; the data field is intentionally kept for interop/provenance.
- "owner" used loosely for both **Assignee** and **Claim** — resolved: these
  are distinct; avoid "owner".
