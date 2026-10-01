# The hub: chain, plan, and questions

Every command here works out of the hub, and each is an error without one
rather than a quiet local no-op — chain and mailbox are fleet state.

**`karr-foundation plan`** writes the chain. It takes the whole chain as one
YAML document on stdin (JSON reads through the same parser), or from the file
`--input` names, and **replaces** what the hub holds:

```bash
karr-foundation plan <<'CHAIN'
steps:
  - id: 1
    kind: ticket
    repo: /srv/karr
    ticket: 41
    precheck: ticket_status == todo
  - id: 2
    kind: shell
    repo: /srv/karr
    needs: [ 1 ]
    command: ./release-gate.sh
limits:
  concurrent: 2
note: what this plan is for
CHAIN

karr-foundation plan --dry-run < chain.yml   # check it, write nothing
```

A document rather than options, because a DAG is nested and the writer that
matters most — the coordination agent — already produces structure; a bare list
of steps is a document too. It replaces rather than appends because only steps
whose chain id matches the header are ever ready, so an append would be a new
chain over old steps and new ones with a merge policy of its own. The step keys
are the ones under "Step kinds" below (`id`, `kind`, `repo`, `ticket`, `needs`,
`timeout`, `precheck`, `command`, `note`, plus `on_*` policies) and beside
`steps:` the document takes `limits:`, `note:` and `planner:` — nothing else,
so a misspelled key is refused instead of silently doing nothing. The whole
document is validated before the first ref is written: a chain karr will not
take leaves the one in the hub untouched, and a chain that still has a step
`running` is refused unless `--force`.

**`karr-foundation chain`** executes what the plan in the hub says is ready. It
pulls the namespace first and refuses the tick when that fails (everywhere else
a failed fetch is a warning; here the fallback would be running a step another
machine is already running), measures each step's precheck against facts it
reads off the boards, runs it, and pushes the step state and the run log back.

```bash
karr-foundation chain              # execute what is ready
karr-foundation chain --dry-run    # list the ready set and its verdicts
```

Step kinds: `ticket` goes through the target repo's **ticket mode**, `shell`
runs a command in the target repo under that repo's own lock, `question`
resolves a mailbox question under its policy, `plan` is recognised and left
pending — and where the fleet marks a coordination agent, a plan step is one of
the four deviations that call it once at the end of the tick. The chain is a layer **above** the run modes and not a fourth `mode:`
— a step inherits the board lock, the claim discipline, the ownership guard and
the run's own report from the mode it calls. A `failed` step stops its own
branch by construction (a step is released only when everything it `needs` is
`done`); a common error and a skipped board (disabled, locked, in cooldown, on
a failing agent) requeue it as `pending` instead, and a step naming a
repository this machine does not have is left untouched and unclaimed. With a hub but no chain written, this says so and returns 0.

**The question mailbox.** A question is a file with an answer field, not a
dialogue — which is what removes the special case for "a human happens to be
present". The chain writes one and carries on with everything that does not
depend on it; whoever answers needs to know nothing about the chain.

```bash
karr-foundation ask "Which registry do we publish to?" \
    --context "the release gate is waiting" \
    --options cpan,darkpan --default cpan --policy use_default \
    --wait 3600 --step 4

karr-foundation answer 7 darkpan --note "this release is a private one"
```

`--policy` is what happens when nobody answers: `block` (the default: wait),
`use_default` (`--default` becomes the answer once `--wait` seconds have
passed) or `escalate_to_ai` (the question is handed to the coordination agent
at the end of the tick where the fleet marks one, and recorded and left waiting
where it does not — the step is never answered on that agent's behalf). `--step` names the chain step waiting on the answer. Both commands
sync the fleet namespace around what they write. `answer` refuses an id that
already has an answer and an answer outside `--options`; `--force` overrides
both. `--status` lists the open mailbox with the id each one is answered by;
answered questions age out, open ones never do.
