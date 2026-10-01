# The coordination agent

The third layer of the design, and the only one that is an AI: coordination is
shared state in refs, execution is local, and **judgement** — planning, routing,
reacting to what nobody planned for — is an agent. It is an agent like every
other one: an entry in `agents:`, invoked through its own `command` under its
own `kind` contract, classified from its own result object, and marked
`failing` by the same availability record. What sets it apart is **when** it
runs, which is never in the hot path. `karr-foundation` works through written
plans by itself and calls this one only where a plan is missing or has broken;
between two of those, no AI runs at all.

Which agent it is, is the `role: coordinator` marker on its definition (see
references/configuration.md) — not a second config key naming an agent that is already
named. A fleet that marks none behaves exactly as it did before: the deviations
are printed, and the operator is the planner.

**Four deviations, one call per tick.** Every one of them was already a place
that recorded "the planner is wanted" and nothing else:

- a `kind: plan` step
- a question past its deadline whose policy is `escalate_to_ai`
- a step whose precheck no longer holds (`stale`)
- a repository the assignment cannot route

A tick collects them and makes **one** call at the end of itself, carrying all
of them: five deviations in one tick are one thing learned — the plan is out of
date — and five calls would pay five times to hear it. The call is last because
a planner called half way through would plan against a board the tick was still
moving, and nothing is re-read afterwards: what it wrote is what the **next**
tick runs.

The run happens in the hub, under the hub's own `.karr.lock` (one agent per
repository holds there too), with `KARR_ROLE=coordinator`, and with its
instruction in `$PROMPT`: the deviations, where the fleet's files are, every
agent with its availability and its prose, and the operator's own `routing:`
prose from `config.yml`. Without a hub it is not called and says so once — a
chain and a question live in `refs/karr-foundation/*`, so there would be nowhere
to put the answer. While the coordination agent itself is failing it is not
called either, and the place that wanted it simply waits.

```console
$ karr-foundation
calling the coordination agent 'planner' for 2 deviation(s): step replan: kind: plan is not executed here; /srv/docs-site: no assignment names this repository
the coordination agent 'planner' finished (success); the next tick runs what it wrote
```

**The assignment** is what it writes so that routing needs no AI afterwards —
`assignment.yml`, beside `config.yml` and `agents.state`, so `--config`
relocates it with them:

```yaml
repos:
  /srv/docs-site:
    - minimax
    - claude
    - WAIT
```

Repository path to an ordered list of agents. `karr-foundation` looks the
repository up and takes the **first entry that currently works**; `WAIT` means
"rather wait than use anything further down" and ends the search, and so does a
chain whose agents are all failing. Such a board runs nothing this tick and says
so (`agent-waiting` in the overview) instead of reading as a board nobody
configured an agent for; `--force` does not override that, exactly as it does
not override a cooldown or an agent's availability. An agent name this machine
does not define is skipped with a `--verbose` note and the next one is tried —
definitions are local, so a table written where more of them exist is a normal
thing to meet.

Like the definitions it names, the assignment is **local and never in refs**: a
command that exists on one machine does not exist on the next, so a table naming
agents cannot be shared any more than they can.

What it is **not**: nothing domain-specific reaches karr through it (that is
`on_drained` and the operator's prose), it is no learning algorithm (the
recovery records are read by the agent, not by karr), it lifts no block, and it
does not touch one-agent-per-repository.
