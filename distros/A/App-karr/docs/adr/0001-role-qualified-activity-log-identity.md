# Role-qualified Activity-log identity

The Activity log keys entries by acting identity under `refs/karr/log/<id>`. We
key on `<role>/<git-email>` (role ∈ `user` | `agent`, a ref path segment —
a literal colon is invalid in Git ref names) rather than the bare git
email, because a human and an AI agent routinely share one git config on the
same machine, and we need `show --me` and `karr log` to tell their actions
apart. The role is carried by the `KARR_ROLE` env var (foundation sets `agent`;
interactive use defaults to `user`) — *not* a CLI flag — because the agent
spawns nested `karr` processes mid-run and only an inherited env var propagates
to them; a flag on the outer command never reaches the inner calls. A manual
override is therefore also an env var (`KARR_ROLE=user karr …`) — not a CLI
flag, which could not propagate and would collide with the role attribute the
command roles already expose.

## Considered Options

- **Bare git email** — simplest, but conflates human and AI sharing one email.
- **Separate git email per persona** — rejected: we explicitly support the
  shared-email case.
- **A `--role` CLI flag as the carrier** — rejected: does not propagate to the
  nested `karr` calls an agent makes during a run, and `MooX::Options` cannot
  declare an option over the `role` accessor the command roles already provide.

## Consequences

Log refs written before this change live under the bare `<email>`. Resolution
for role `user` falls back to the bare-email ref when the `user:`-prefixed ref
is absent, so pre-change history is not orphaned.
