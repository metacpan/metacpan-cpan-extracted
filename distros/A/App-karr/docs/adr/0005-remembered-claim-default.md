# The claim name is carried per process in `KARR_CLAIM`, and defaults to the checkout

Every claim-taking call wants the same name. `karr move --claim NAME`,
`karr handoff --claim NAME`, `karr pick --claim NAME`, `karr edit --claim NAME`
and `karr list --claimed-by NAME` all name the same agent, and claims are
compared by that name -- `--claim` stamps it, `handoff`/`check_claim` check the
name handed in against the one on the card, `list --claimed-by`/`log --agent`
select on it. Today the name lives only in the caller's shell variable, and
`karr agent-name` mints a *new* random name each call, so an agent that names
itself at move time and again at handoff time no longer matches its own claim.
We want the agent to name itself **once** and have every later call agree.

## Why not remember it in the checkout

The obvious fix -- write the name to the checkout on first use (`git config
--local`, a file under `.git/`) and default from it -- does not survive more
than one agent. Several agents drive one board at once; a per-checkout slot is
one slot, so agent A records its name, agent B overwrites it, and A's next
omitted `--claim` silently adopts B's name. Keying the slot by role
(`user`/`agent`) only tells the human from the agents, never one agent from
another.

The property we need -- a value each concurrent agent keeps to itself, visible
to the nested `karr` calls that agent makes -- is what an environment variable
gives and a shared file cannot: a child `karr` cannot write its parent shell's
environment, and two agents in two process trees never see each other's. This is
the reasoning ADR 0001 used to carry the *role* in `KARR_ROLE`. We apply it to
the claim name.

## Decision: the carrier is `KARR_CLAIM`

The claim name is carried in the **`KARR_CLAIM`** environment variable. Every
command that takes `--claim` (`move`, `handoff`, `pick`, `edit`, `create`) and
`list --claimed-by` defaults to `$KARR_CLAIM` when the flag is omitted. The agent
exports it **once** per session; every nested `karr` call in that process tree
then claims as that name. karr writes nothing to disk, there is no per-checkout
state to collide on, and closing the session forgets the name.

An explicit `--claim` on the command line **always wins** over `KARR_CLAIM`,
which wins over nothing. There is no silent fallback: with neither set, a
`require_claim` column still refuses (see below). A human or agent that wants a
one-off different claim just names it on the line.

`create` takes the default more narrowly (k286): `KARR_CLAIM` is used only
when `--status` names a `require_claim` column -- the card is being started
right there, and that is also the one case the guard below consults the
environment. A card filed into the backlog or `todo` carries no claim from
the environment: a Claim is a lease held *while working* the card
(CONTEXT.md), and a card filed for others is not being worked. Under the
plain rule every bug an agent filed was invisible to every other agent's
`pick` and `list --unclaimed` for `claim_timeout`. An explicit `--claim`
still stamps on any status.

## The value: `agent-name` is the checkout, not a random word

`karr agent-name` returns the **current worktree's root directory name**,
sanitised to a claim-safe token (lowercase, every non-`[a-z0-9]` run folded to a
single `-`, trimmed). The agent working the `karr` checkout is `karr`; the one in
a worktree at `.../graphify-fix` is `graphify-fix`. The source is
`git rev-parse --show-toplevel`, not raw `cwd`, so it does not matter which
subdirectory the agent started in; outside a work tree it falls back to the `cwd`
basename. This replaces the old "random two-word name": the name is now stable,
meaningful in `karr show`, and -- crucially -- distinct per worktree without a
generator.

This **supersedes ticket #176's decision.** #176 deliberately kept `agent-name`
random and stateless, on the reasoning that any name derived from something
stable (board, git identity, host) would be *shared* by every concurrent agent
on that board and turn a refused mismatch into an unrefusable collision. That
reasoning is answered, not ignored: the checkout name is stable but **not**
shared -- concurrent agents run in distinct worktrees (S2), so their names
already differ, and the one case that would collide (S3, one directory) takes
`--unique`. The carrier being `KARR_CLAIM` per process, not a name re-derived on
each call, is what makes a stable name safe where #176 could not.

    export KARR_CLAIM=$(karr agent-name)     # -> karr, wt1, graphify-fix, ...

### Several agents in one directory: `--unique`

Worktrees share one board (`refs/karr/*` lives in the common git dir), so the
right way to run several agents on a board is **one worktree each** -- their
directory names already differ, so their claims differ, with no collision.

The one case the directory name cannot cover is several agents started in the
**same** directory: they would all be `karr` and, because claims match by name,
would stamp, steal and hand off over each other unprotected (the `check_claim`
guard only stops a *different* name). For that case `karr agent-name --unique`
appends a short random suffix -- `karr-8fa` -- keeping the checkout identity
visible while making each agent distinct:

    export KARR_CLAIM=$(karr agent-name --unique)   # karr-8fa, karr-3k2, ...

Captured once into `KARR_CLAIM`, the suffix is stable for that session. `--unique`
is where the old random-name behaviour now lives.

## Scenarios

| | Setup | `agent-name` gives | Result |
|---|---|---|---|
| S1 | one agent/human, main checkout | `karr` | stable, no collision |
| S2 | several agents, one worktree each | `karr`, `wt1`, `wt2` | distinct, no collision -- the recommended multi-agent shape |
| S3 | several agents, one shared directory | all `karr` | collide -- use `agent-name --unique` per agent |

## The character/octet boundary

`KARR_CLAIM` crosses the same edge as every environment value: octets in the
process environment, characters inside karr. `App::karr::Encoding` owns the
crossing -- reading `$ENV{KARR_CLAIM}` decodes, foundation writing it encodes
through the same `to_octets_for_env` path `KARR_TASK` already uses. No command
decodes or encodes it itself.

## `require_claim` names both ways out

A `require_claim` column is satisfied by `KARR_CLAIM`. When it is unset and no
`--claim` is passed, the refusal ADR 0002 / ticket #263 already prints names
**both** ways side by side, so neither is a secret:

    Status 'in-progress' requires a claim, and KARR_CLAIM is unset. Either:
      karr create 'In flight' --status in-progress --claim NAME
      export KARR_CLAIM=$(karr agent-name)     # once per session

`pick --claim`, required today, stops being required -- the env default fills it.

## Not the log identity

`show --me` keeps meaning the activity-log identity (`<role>/<git-email>`,
ADR 0001), not `KARR_CLAIM`. Who *acted* and what name a card is *held under* are
two axes; CONTEXT.md keeps them apart. `list --claimed-by` reads the default like
the others but is a question about the board, not a claim the caller makes, so it
sets nothing.

## Rejected alternatives

- **A remembered per-checkout default** (`git config --local`, a file), keyed by
  role or not -- the collision above: one slot cannot serve several concurrent
  agents, and auto-capturing into it makes the clobber silent.
- **An automatic fallback to the directory name** when both are unset -- rejected
  as a silent claim: in a shared directory (S3) it would quietly give every agent
  the same name. Naming is explicit; the directory name is a value you pass, via
  `agent-name`, not one karr assumes.
- **A PID suffix for S3** -- a PID is a fresh value per `karr` invocation, so it
  would differ between an agent's own calls; a random suffix captured once into
  `KARR_CLAIM` is stable for the session, which is what matching needs.

## Consequences

`karr agent-name` changes contract: its default output becomes the checkout name
rather than a random word, and the random behaviour moves behind `--unique`. Its
POD, README's multi-agent section, and the bundled skill (`share/claude-skill.md`
and its in-repo copy) stop teaching the `NAME=$(karr agent-name)` dance and
instead state the two ways to claim: pass `--claim NAME` on every claiming call,
or `export KARR_CLAIM=$(karr agent-name)` once (adding `--unique` when several
agents share a directory). The seven commands that each declare their own
`option claim` today gain a shared home for the option and its env-default
resolution. `Foundation/Runner` exports `KARR_CLAIM` for the agent process,
alongside the `KARR_ROLE`/`KARR_TASK` it already sets, through the same
`to_octets_for_env` boundary. Its value is the checkout's `agent-name --unique`
form (checkout name plus a per-run suffix), produced by the *same* name helper
`karr agent-name` uses so the strings agree: foundation is the multi-claimer
context by definition -- several runs, possibly two checkouts of one shared
board, may write claims at once -- so the per-run suffix keeps them distinct
where the bare checkout name would collide, and `claim_timeout`, not name reuse,
recovers a crashed run's cards. Nothing is written to `refs/karr/*` or to the
working tree (ticket #281).
