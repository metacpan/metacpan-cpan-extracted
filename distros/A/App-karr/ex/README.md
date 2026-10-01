# App::karr — a runnable sandbox

This directory is a self-contained sandbox for [App::karr](..): it builds two
sample repositories with real boards, wires them into one
[karr-foundation](../bin/karr-foundation) fleet, and lets you run every scenario
the documentation talks about — ticket mode, drain mode, review cards staying
actionable, stalls and auto-blocking, cooldown, and the chain with its question
mailbox — against a real setup, on one machine, without a server or a remote.

Everything generated here is **machine-local and never committed**: the board
state lives in git refs (`refs/karr/*`), and refs are not carried by `git
clone`, so the boards are built at run time by `setup.sh`. What *is* committed
is this README, `setup.sh`, `bin/`, `scripts/` and the article below.

## Prerequisites

- Perl (5.20+) with the dependencies of this checkout installed. From the
  repository root, `cpanm --installdeps .` or whatever your
  [Dist::Zilla](https://dzil.org) setup prefers; running `prove -l t/` once
  from the root is a good sanity check.
- `git` on `PATH`.
- Nothing else: no server, no network, no credentials.

## Build the sandbox

```bash
./ex/setup.sh           # create (idempotent: existing pieces are left alone)
./ex/setup.sh --reset   # wipe the generated state and rebuild from scratch
```

The script creates `ex/webapp/` and `ex/docs-site/` (each a git repo with a
karr board seeded with sample cards and a `.karr` file), `ex/fleet-hub/` (the
fleet's hub repository holding the chain), `ex/config.yml` (the
karr-foundation config pointing at all of them), and writes a demo chain into
the hub.

By default the sandbox calls the `karr`/`karr-foundation` binaries from this
checkout (`perl -Ilib bin/karr …`). Set `KARR_BIN` to point at an installed
binary if you would rather exercise that: `KARR_BIN="$(command -v karr)"
./ex/setup.sh`.

## Look at the boards

```bash
perl -Ilib bin/karr --dir ex/webapp board
perl -Ilib bin/karr --dir ex/docs-site board
```

`webapp` carries six cards — a login bug being worked, a rate-limit card that
depends on it, release notes in review, a blocked TLS upgrade, integration
tests, and a cross-board release card waiting on `docs-site#1`. `docs-site`
carries two.

## Run the fleet

A karr-foundation run is one pass over every repository in the config:

```bash
perl -Ilib bin/karr-foundation --config ex/config.yml --status    # read-only overview
perl -Ilib bin/karr-foundation --config ex/config.yml --dry_run   # what would run
perl -Ilib bin/karr-foundation --config ex/config.yml             # the run
```

What you see on a fresh sandbox:

```
fake-agent: working on #5
Moved task 5: todo -> review
Handed off task 5 -> review (claim released)
fake-agent: #5 -> review, handed off
drain-agent: working on #1
Moved task 1: todo -> done
Updated task 1: Update the installation quickstart
drain-agent: #1 -> done
drain-agent: nothing to pick
```

- **webapp runs in `mode: ticket`.** karr-foundation picks the next assignable
  card itself and tells the agent about it (`$KARR_TASK`, plus a line in the
  prompt). `fake-agent.sh` moves it to review and hands it off under a fresh
  claim, releasing the claim at the end.
- **docs-site runs in `mode: drain`.** The agent picks its own work
  (`drain-agent.sh` uses `karr pick`). It works each card all the way to
  `done`, because a drain run only terminates when no actionable cards are
  left — an agent that parks cards in review would keep the drain going.

Run it again and watch `Moved task 5: review -> review`: a card in review is
still *actionable*, so it keeps getting picked until somebody moves it to a
terminal state. Finish it yourself with:

```bash
perl -Ilib bin/karr --dir ex/webapp move 5 done
```

## Scenarios worth trying

**A stalled agent and auto-block.** Reset the sandbox first
(`./ex/setup.sh --reset && ./ex/setup.sh`), then point `webapp`'s `.karr` at
`lazy-agent.sh` (which prints "I cannot make progress" and exits 0, without
ever calling `karr`) by adding a `command:` line, which overrides the
configured agent:

```yaml
# ex/webapp/.karr
mode: ticket
agent: demo
prompt: "You are a demo agent. Work the assigned card, move it to review and hand it off under your own claim."
max_attempts: 2
command: /absolute/path/to/ex/bin/lazy-agent.sh
```

Not `docs-site`: it runs in `mode: drain`, and a drain only auto-blocks a card
its *own* agent is on record as having touched — an activity-log entry under
the claim it wrote. `lazy-agent.sh` never calls `karr`, so it never creates
that record; pointed at `docs-site` it stalls forever and nothing is ever
blocked. Ticket mode carries no such requirement: foundation assigned the
card itself, so the assignment already is the evidence, and an agent that
leaves it untouched still stalls it.

Run the fleet twice — `max_attempts` is 2 in the sample:

```console
$ perl -Ilib bin/karr-foundation --config ex/config.yml
lazy-agent: I cannot make progress on #5
drain-agent: working on #1
Moved task 1: todo -> done
Updated task 1: Update the installation quickstart
drain-agent: #1 -> done
drain-agent: nothing to pick

$ perl -Ilib bin/karr-foundation --config ex/config.yml
lazy-agent: I cannot make progress on #5
drain-agent: nothing to pick
```

(`docs-site`'s own card drains alongside it under its unmodified `.karr` —
that's `drain-agent`'s output above, not part of this scenario.) The second
run is card #5's second stall, so it is auto-blocked:

```console
$ perl -Ilib bin/karr --dir ex/webapp show 5
...
Blocked:  auto-block: no progress after 2 attempts (foundation)
```

Reset the board with `--reset` afterwards.

**A failing agent and cooldown.** Point a `.karr` at `failing-agent.sh` (exits
1 with an "API error"). The run is a *common-error* and the repository goes
into cooldown, starting at 1m and backing off exponentially — visible in
`--status` as the repo being on hold.

**The chain.** The hub already holds a demo chain (`scripts/write-chain.pl`
wrote it): a docs build, a smoke test, a *question* step ("Shall we publish
0.6?") that gates a publish step. Execute what is ready:

```bash
perl -Ilib bin/karr-foundation --config ex/config.yml chain
```

On a fresh sandbox the shell steps run (docs, smoke) and the question step
goes *stale*: nothing in the question mailbox names it, and a question step
does not ask its own question — the planner asks it:

```bash
perl -Ilib bin/karr-foundation ask "Shall we publish 0.6?" \
    --config ex/config.yml --step registry --options yes,no \
    --policy use_default --default yes --wait 3600 \
    --context "smoke and docs are green"
perl -Ilib bin/karr-foundation answer 1 yes --config ex/config.yml \
    --note "all green, ship it"
```

A step that went stale stays stale — re-plan the chain so the answered
question resolves it:

```bash
perl -Ilib ex/scripts/write-chain.pl ex/fleet-hub
perl -Ilib bin/karr-foundation --config ex/config.yml chain
# step registry (question): done — question #1 answered 'yes'
# step publish (shell) in .../webapp: done — exit=0
```

## How the pieces fit

| Path | Role |
|---|---|
| `ex/setup.sh` | builds the sandbox (repos, boards, `.karr` files, config, chain) |
| `ex/config.yml` | karr-foundation config: `dirs`, `hub`, `concurrent`, agent `demo` |
| `ex/webapp/.karr` | `mode: ticket` — foundation names the card |
| `ex/docs-site/.karr` | `mode: drain` — the agent picks its own work |
| `ex/bin/fake-agent.sh` | ticket-mode agent: card → review, hand off, release claim |
| `ex/bin/drain-agent.sh` | drain-mode agent: card → done, so the drain terminates |
| `ex/bin/lazy-agent.sh` | stall/auto-block demo |
| `ex/bin/failing-agent.sh` | cooldown demo |
| `ex/scripts/write-chain.pl` | writes the demo chain into the hub |
| `ex/scripts/build-docs.sh`, `smoke-test.sh`, `publish.sh` | chain step stand-ins |

The `.karr` files, `config.yml`, the boards and the hub are generated state —
edit them to experiment, and `--reset` to start over. `setup.sh` is the only
thing you should not need to touch.

---

# The full article

*A kanban board that lives in Git refs — and the VM that runs agents on it.*

This is the English translation of the article about `App::karr` and
`karr-foundation` (the German original lives next to this checkout as
`karr-artikel.md`). Everything this sandbox lets you run is exactly what the
article describes — read along while you play the scenarios above.

---

# A kanban board that lives in Git refs — and the VM that runs agents on it

*About `App::karr` and `karr-foundation`: why board state doesn't belong in the
repository as files, what a drain loop is, and why in this design no agent runs
in the hot path.*

---

## 1. The problem

It's not about kanban.

There are enough kanban tools, and another one wouldn't be worth a line of code.
The problem from which `karr` grew looks different: **several agents work on
several repositories, and the state of this work has to live somewhere where
everyone can see it and nobody can break it.**

These two requirements contradict each other in the obvious solution. The
obvious solution is a file in the repository — a `TODO.md`, a `tasks/` directory
with one file per card, the way [kanban-md](https://github.com/antopolskiy/kanban-md)
does it, the Go implementation from which `karr` descends. That works
wonderfully as long as a human touches the cards. As soon as two processes write
at the same time, it falls apart:

- **Merge conflicts in places where they have no business.** Two agents touching
  two different cards still collide as soon as both touch the same board file.
  And a merge conflict in board state is particularly unpleasant because nobody
  wants to resolve it: it's not a substantive question, just bookkeeping.
- **Commits nobody wants.** Every status change becomes a commit. `git log`
  fills up with "move #14 to in-progress". The history of the project and the
  history of the work organization lie in the same strand, and one makes the
  other unreadable.
- **The working tree is not a good place for shared state.** Someone sitting on
  a feature branch sees a different board than someone on `main`. A `git
  checkout` changes the board state. That's exactly backwards: the board is a
  property of the project, not of the branch.

`karr` therefore doesn't store the board state in files but in **Git refs**:
`refs/karr/*`. What that means in practice is the core of the whole thing, so
it's worth spelling it out.

### Refs instead of files

A Git ref is a name that points at an object. Branches and tags are refs
(`refs/heads/main`, `refs/tags/v1.0`), but the namespace is open: you may create
your own refs, and Git doesn't care what's in them. `karr` keeps its board under
them:

```text
refs/karr/config                 sparse YAML mit den Board-Einstellungen
refs/karr/meta/next-id           der nächste freie numerische Karten-Identifier
refs/karr/tasks/<id>/data        eine Karte: Markdown mit YAML-Frontmatter
refs/karr/log/<role>/<email>     das Aktivitätslog, JSON-Zeilen
```

Four things follow from this, and each one is a reason for the design:

**No commit.** Moving a card rewrites a ref. The working tree isn't touched,
`git status` stays clean, `git log` remains the history of the code. Board
activity and code history are two separate things and now live separately.

**No merge conflict.** Two agents changing two different cards write two
different refs. There's no shared file they could rub against. A conflict only
arises where it's also a substantive one: both touch the same card.

**Synchronizable over normal Git transport.** Refs are pushed and fetched like
everything else. No server, no database, no service needed — anyone allowed to
clone the repository has the board. `karr sync` does this explicitly, every
writing command does it on the side: `pull refs → change card → push refs`.

**CAS-protected against concurrent writers.** A ref update can be secured in Git
against the old object ID: *only write if the ref still points at X*. That's a
compare-and-swap, and `karr` uses it everywhere two processes could touch the
same ref — when issuing the next card ID, when claiming a card, when advancing
a chain step. If a writer loses the swap, it has written nothing and tries again
(32 attempts with capped backoff, then it gives up loudly). No "last one wins",
no silent loss.

There's a price, and it isn't hidden: `git clone` does **not** fetch
`refs/karr/*`. A fresh clone initially sees no board. That's exactly why `karr
init` asks the remote whether a board already exists there before it creates one
— otherwise "freshly cloned" couldn't be told apart from "never had a board",
and you'd get a second board next to the first.

### Origin: kanban-md

`karr` is a Perl reimplementation of `kanban-md` (Go), with the stated goal of
feature parity — and with a file-compatible card format. What lies in a ref is
exactly what `kanban-md` would write into a file:

```markdown
---
id: 1
title: Fix login bug
status: in-progress
priority: high
class: standard
claimed_by: agent-fox
created: 2026-03-12T10:00:00Z
updated: 2026-03-12T10:00:00Z
---

Task description here.
```

This compatibility isn't nostalgia but a bridge. `karr materialize` writes the
refs out as a file tree (`tasks/` plus `config.yml`), `karr import --yes` reads
it back. That's the way to `kanban-md` and back, and the way for everything
you'd rather grep than query. It's explicitly **not** a second storage format:
the file tree is a materialized view, it always sits in `.gitignore`, and it's
never committed. The refs are canonical.

The compatibility also has a consequence you see in an unexpected place.
Cross-board references (more on that later) sit on the card as a **tag**,
`needs:<board>#<id>`, and not as its own frontmatter field. Reason: a field that
`kanban-md` doesn't model survives reading, but is dropped on the next write —
Go reads the document into a struct and writes it back out of that. `karr`
preserves unknown keys, `kanban-md` doesn't return the favor. `tags` is modeled
on both sides and survives. That's the reason for a design decision that would
otherwise look like a hack.

### And the second half

The board is one half. The other is `karr-foundation`: a standalone binary that
watches **many** such boards, decides per board whether there's work there, and
starts a configured agent there. It's single-shot and idempotent — every tick is
complete in itself — and so a cron line is a fully-fledged scheduler:

```bash
*/5 * * * * karr-foundation
```

Without this second half, `karr` would be another file-based kanban. With it,
it's what it was built for. The largest part of this article is about it.

---

## 2. Installation, from scratch

### Prerequisites

`karr` is a Perl distribution. If you have Perl, you have the interpreter;
`cpanm` pulls in everything else:

```bash
cpanm App::karr
```

The runtime dependencies are unspectacular and live in the `cpanfile`: `Moo`,
`MooX::Cmd` and `MooX::Options` for the object system and subcommand dispatch,
`YAML::XS` for the frontmatter, `Path::Tiny` for file access, `JSON::MaybeXS`,
`Try::Tiny`, `Time::Piece`, `File::ShareDir` and a few core modules. Only three
are interesting:

```perl
requires 'Git::Native',    '0.005';
requires 'Git::Libgit2',   '0.007';
requires 'Alien::Libgit2', '0.002';
```

`Git::Native` is the FFI binding to libgit2. All local object and ref operations
— reading, writing, deleting refs, blobs, trees, commits — run natively, without
`fork`/`exec`. That's why a `karr list` on a board with hundreds of cards
doesn't start hundreds of `git` processes.

`Alien::Libgit2` is there even though `karr` never calls it directly:
`Git::Libgit2` loads the C library through it. The pin on `0.002` is a scar. In
libgit2 before 1.9.3, the SSH transport spins forever when the peer accepts the
connection and then stays silent — libssh2 does its own reads, and no
libgit2 timeout option reaches that loop. Which means `KARR_TRANSPORT_TIMEOUT`
can't cap it either, the environment variable with which `karr` otherwise caps
every transport run (default 120 seconds, `0` disables). Upstream has fixed it;
`Alien::Libgit2` 0.002 raises the pkg-config floor to 1.9.3, so an old
distribution library isn't picked at all and the bundled source build takes
over. A pin that excludes a hang-causing class is cheaper than a ticket "karr
sometimes hangs on push".

A word on transport in general, because it'll come up again with
`karr-foundation`: `fetch` and `push` first try the native libgit2 transport and
fall back to the system `git` on failure (via `IPC::Open3`). Reason is
`~/.ssh/config`: libgit2/libssh2 doesn't read it and can't run a `ProxyCommand`,
so `Host` aliases, `IdentityFile` and `insteadOf` only work via the CLI.
`KARR_NO_CLI_FALLBACK=1` disables the fallback if you want to see native
transport errors directly.

### Docker

If you don't want to pull `karr` into the project as a Perl dependency, take the
image:

```bash
docker run --rm -it -w /work -v "$(pwd):/work" raudssus/karr:latest --help
```

There are two published images. `raudssus/karr:latest` briefly starts as root,
looks at `/work` and then switches to the owner of the mounted workspace — so
host files don't end up root. `raudssus/karr:user` is the image with a fixed
user (default `1000:1000`) and the better base for a deterministic derived
image.

For real use the alias is longer, and every part of it has a reason:

```bash
alias karr='docker run --rm -it \
  -w /work \
  -e HOME=/home/karr \
  -v "$(pwd):/work" \
  -v "$HOME/.gitconfig:/home/karr/.gitconfig:ro" \
  -v "$HOME/.ssh:/home/karr/.ssh:ro" \
  raudssus/karr:latest'
```

The `.ssh` mount is what makes an `ssh://` remote work at all. `HOME` in the
container is `/home/karr`; that's where libgit2 *and* `ssh` look for
`known_hosts` and keys; without the mount they find nothing, and `karr` reports
the host as unknown no matter how often you run `ssh-keyscan` on the host.
Read-only, so a container can never overwrite the keys.

A trap when mounting the whole directory: the image ships a current OpenSSH, and
a `~/.ssh/config` written against an older one is flatly rejected —
`Bad key types '+ssh-dss'`, and the connection never comes up. Remedy:

```bash
GIT_SSH_COMMAND="ssh -F /dev/null -o UserKnownHostsFile=/home/karr/.ssh/known_hosts"
```

If the key needs a passphrase, you forward the agent instead of relying on the
key files. That does *not* belong in an alias, because `docker run` flatly
rejects the mount when no agent is running — so a shell function:

```bash
karr() {
  local ssh_agent=()
  [ -n "$SSH_AUTH_SOCK" ] && ssh_agent=(-v "$SSH_AUTH_SOCK:$SSH_AUTH_SOCK" -e SSH_AUTH_SOCK)
  docker run --rm -it -w /work -e HOME=/home/karr \
    -v "$(pwd):/work" \
    -v "$HOME/.gitconfig:/home/karr/.gitconfig:ro" \
    -v "$HOME/.ssh:/home/karr/.ssh:ro" \
    "${ssh_agent[@]}" raudssus/karr:latest "$@"
}
```

### Creating a board

In an existing Git repository:

```bash
karr init --name "My Project"
```

What happens:

1. **It asks the remote.** `git clone` doesn't fetch `refs/karr/*`, so a fresh
   clone can't be told apart from a repository that never had a board. If the
   remote advertises `refs/karr/*`, the board already exists and is one `karr
   sync` away — `init` then refuses and says so, instead of opening a second
   board next to it. Any other answer (no remote, unreachable, no answer within
   the budget) lets `init` through: it has to work offline. `--new-board` skips
   the question entirely, for the case where a clone deliberately runs its own
   board.
2. **It writes the refs.** `refs/karr/config` gets the sparse overrides (with
   `init --name` exactly the name), `refs/karr/meta/next-id` the counter.
3. **It augments `.gitignore`** — namely for the materialized file view:
   `tasks/` and `config.yml`. If these paths are already tracked by Git in the
   repository, `init` leaves `.gitignore` alone and says so.

Options: `--statuses` replaces the default status list with your own
(comma-separated), `--claude-skill` places the two shipped skills at
`.claude/skills/kanban-issues-karr-coordination/` and
`.claude/skills/kanban-issues-karr-ticket/` — each file written in place, so
the inode of an already existing `SKILL.md` is preserved and a shared hardlink
chain isn't broken — and removes a leftover `kanban-issues-karr-cli/` from an
earlier release.

### The `.gitignore` trap

There was a bug here for a long time, and it's important enough for its own
paragraph.

`karr init` writes **only** `tasks/` and `config.yml` into `.gitignore`. That's
the materialized file view of the board, and it's enough for that. But
`karr-foundation` lays down four more files per repository, and `init` doesn't
write those in — simply because `init` knows nothing about `karr-foundation`.
Anyone using `karr-foundation` adds them by hand:

```gitignore
.karr
.karr.state
.karr.lock
.karr.log
```

All four are **machine-local**. `.karr` is the execution configuration for this
repository on this machine, the other three are written by `karr-foundation`
itself. None of them belongs in the repository, and why is the core of section
4.

---

## 3. `karr` alone — the board part

Before it's about agents: `karr` is usable on its own. A human can use it as a
board without ever configuring an agent. This half is told quickly because it
follows a well-known model.

### The data model

A card has a numeric identifier, a title, a status, a priority, a class of
service, optionally an assignee, tags, a due date, an estimate, a parent, a list
of `depends_on` identifiers, a Markdown body — and the lifecycle stamps
`created`, `updated`, `started`, `completed` as well as `claimed_by` /
`claimed_at` and `blocked` / `block_reason`.

The board defaults, as `App::karr::Config` provides them:

| Setting | Default |
|---|---|
| `statuses` | `backlog`, `todo`, `in-progress`\*, `review`\*, `done`, `archived` |
| `priorities` | `low`, `medium`, `high`, `critical` |
| `classes` | `expedite`, `fixed-date`, `standard`, `intangible` |
| `claim_timeout` | `1h` |
| `lock_timeout` | `5m` |
| `defaults` | status `backlog`, priority `medium`, class `standard` |
| `foundation.enabled` | `1` |

\* `in-progress` and `review` are configured with `require_claim`: a card
doesn't get there without a claim.

`refs/karr/config` stores **sparsely** — only the keys that deviate from these
defaults. A board that hasn't reconfigured anything has nothing in its config
ref. That's why `karr enable` makes the whole `foundation` key disappear again:
the value is back on the code default, so there's nothing left to override.

### The usual flow

```bash
karr create "Fix login bug" --priority high
karr list
karr board
karr show 1
karr move 1 in-progress --claim agent-fox
karr edit 1 -a "Reproduced on staging"
karr handoff 1 --claim agent-fox --note "Ready for review" --timestamp
karr archive 1
```

`create` takes the title positionally and with it `--status`, `--priority`,
`--assignee`, `--tags` (comma-separated), `--due`, `--estimate`, `--class`,
`--body`, `--depends-on` (comma-separated card identifiers), `--needs` and
`--escalated-from` (the cross-board references, see below).

`list` is the filter: `--status`, `--priority`, `--assignee`, `--tag`,
`--search`/`-s`, `--claimed-by`, `--sort`, `--reverse`/`-r`, `--archived`. Like
all read commands it can do `--json` and `--compact`, which is the difference
between "a human reads this" and "a script reads this".

`show ID` shows a card completely. Plus three modes built for agents: `--me`
shows the card that your own identity last acted on (the command for finding
your way back after a loss of context), `--last N` the N most recent, `--agent
NAME` the ones most recently touched by a given claim name.

`move ID STATUS` changes the status explicitly, `--next` and `--prev` move by
one column. `--claim` sets the claim at the same time.

`edit ID` is the Swiss-army knife: `--title`, `--status`, `--priority`,
`--assignee`, `--add-tag` / `--remove-tag`, `--add-depends-on` /
`--remove-depends-on`, `--add-needs` / `--remove-needs`, `--due`, `--body`,
`--append-body`/`-a`, `--claim`, `--release`, `--block "Grund"`, `--unblock`.

`board` groups by status. The `done` column is hidden by default (`--done`
brings it along), `--tags` shows an indented tag line per card.

`archive ID` is the soft delete: the card goes to status `archived`, the ref
stays, history and metadata are preserved, it disappears from the normal
`list` output. A card with a live claim is **not** archived unless `--claim`
names its holder — archiving is a status change like any other, and it does not
read `KARR_CLAIM`. Otherwise release it first (`karr edit ID --release`) or wait
out the `claim_timeout`.

`delete ID --yes` removes the ref permanently. That's the difference to
`archive`, and that's why it needs the confirmation.

### The claim mechanism

A claim is a name on a card plus a timestamp. It answers a single question:
*who is working on it right now?*

It exists because otherwise parallel agents would process the same card twice.
A claim is not a lock in the technical sense — it expires (`claim_timeout`,
default one hour), because an agent that dies mid-work must not take a card out
of circulation forever. It's the agreement, not the enforcement.

`karr agent-name` supplies the name for it, and `KARR_CLAIM` carries it:

```bash
export KARR_CLAIM=$(karr agent-name)
karr pick --status todo --move in-progress
karr handoff 1 --note "Implementation complete" --timestamp
```

The name is the checkout's own directory name — `karr` for the `karr`
checkout, `graphify-fix` for a worktree of that name — so it means something in
`karr show`, and it comes out the same every time you ask in the same checkout.
Exported once per session, it stands in for an omitted `--claim`: `pick` and
`handoff` claim under it, `move` and `edit` recognize a card you already hold by
it, and `list --claimed-by` selects on it. `create`, `move` and `edit` write it
onto a card only when the card ends up in a `require_claim` column, so a card
you file, promote to `todo` or annotate stays free for whoever picks next. An
explicit `--claim NAME` still wins for a one-off.

Claims are checked by name comparison: `move`, `edit` and `handoff` compare the
name with the one on the card, `list --claimed-by` and `log --agent` select on
it. Claiming under one name and handing off under another is rejected — one
name per session is the whole rule.

The name is deliberately **not** stored anywhere, neither on the board nor in a
file in the checkout. Any anchor that survives a `karr` process — the board,
the Git identity, the hostname — is shared just the same by every other agent on
the same board, and a name derived from it would give two simultaneous agents
the same claim. That's strictly worse than a mismatch: a mismatch is rejected, a
collision is indistinguishable from the rightful owner. The checkout is the
boundary that works — give each agent its own worktree and their names differ
by themselves. Several agents in the **same** directory take `karr agent-name
--unique` (`karr-8fa`), captured once into `KARR_CLAIM` like the plain name;
`karr-foundation` does exactly that for every run it starts.

If you've lost the name after all, you can read it back: `karr pick` prints
`(claimed by NAME)`, `karr show ID` shows `Claimed:`, and the rejection on a
mismatch names the current holder.

### `pick` vs. `list` — what the difference is

`list` reads. `pick` **decides and writes**, atomically.

That's the whole difference, but it has depth. `karr pick --claim NAME` looks
for the next workable card, claims it and optionally moves it along (`--move
in-progress`). The selection part:

- **Allowed statuses.** Without `--status` the terminal statuses fall away — the
  last configured status and `archived`, on a default board that's `done` and
  `archived`. `backlog` falls away always: it is held back until someone
  promotes a card to `todo`, and `pick --status backlog` is refused outright.
- **Claim expiry.** Already claimed cards are invisible, unless their claim has
  expired after `claim_timeout`. A `claimed_by` that is an empty string isn't a
  claim — that's how `kanban-md` spells "not claimed".
- **Order.** Class of service, then priority, then card identifier. The lists
  for class and priority come from the board configuration, not from a
  hardwired table — a board imported from `kanban-md` with a longer priority
  list is sorted by its own list.
- `--tags` restricts further, `--move` sets the target status.

And the exclusivity part, which is the actual reason for a command of its own:
the board is read once to rank candidates, but **nothing** is decided on that
reading. After taking its lock, every candidate is read again from its ref,
tested a second time against the same predicate, and then written back under a
compare-and-swap on the object ID just read. Whoever loses the swap has picked
nothing and moves on to the next candidate.

Why double-secured? Because the lock ref alone doesn't make a pick exclusive:
its holder identity is the `user.email` of the clone, and all agents on one
machine share that. Twelve agents under the same identity all take "the same"
lock and overwrite each other's claims. The compare-and-swap is what actually
holds.

With `--json`, a successful pick prints the card as a JSON object, and if there
was nothing to pick, `{"picked":null}` — exit code `0` in both cases. A polling
agent decodes the output and tests for a card, instead of interpreting exit
codes or message text.

`karr unlock` is the other half of it: it shows the held pick locks (with card,
holder identity, hold duration and whether that's already past `lock_timeout`)
and breaks them on request (`karr unlock 12`, `karr unlock --all`). Locks expire
on their own, which is what an unattended agent needs; this command is the way
for a human to clean up now instead of waiting — and the only way out on a board
that has set `lock_timeout: 0s`.

### Blocking, dependencies, cross-board

Three mechanisms that are easily confused, and that do very different things:

**`blocked`** is a flag with a reason (`karr edit ID --block "warum"`). It's the
only one of the three that actually takes a card out of the `pick` candidate
pool. It's a **decision**.

**`depends_on`** is a list of card identifiers on the same board. It blocks
nothing: `karr pick` hands the card out and says what it's waiting on. It's a
**fact**.

**Cross-board references** are facts about another repository. A card that can't
be worked on until something is fixed elsewhere carries `needs:<board>#<id>`;
the card opened in the other repository carries the other half,
`escalated-from:<board>#<id>`. Both through the typed doors: `karr create
--needs`, `karr edit --add-needs`.

What's remarkable is what the reference **carries**: a board **name** and a card
ID. Never a path. That's the dividing line of the whole design — coordination is
shared and travels in refs, execution is local — and a path fails on it in the
first test: two clones of the same fleet have the same cards and different
directories. A path written onto a card is wrong on every machine except the one
that wrote it. The board name is the directory basename, i.e. the same name
`karr-foundation --status` prints anyway.

`karr needs` reads both ends back:

```bash
karr needs                                   # worauf wartet dieses Board?
karr needs --board other-repo=/srv/other     # ... und wo dieses Board liegt
karr needs --resolve                         # was erledigt ist, aufräumen
```

Without `--resolve` it reports and changes nothing: which cards carry a
reference, what status the remote card has (as far as the remote board is
readable), and whether the remote card points back. With `--resolve`, all
references whose remote card has reached a terminal status **of the remote
board** fall away, and if that was the last open reference of a card, the
`blocked` flag is lifted too — with the reason printed, so nothing silently
disappears.

Two honest limitations: `karr needs` **doesn't fetch**. The remote board is read
the way it stands in that working copy, so the answer is as fresh as that
board's last `karr sync`. And a board name that this machine can't resolve is
reported, but the command still exits `0` — a machine that has four of six
repositories of a fleet has an honest report to give about the four, and
aborting at the first unresolvable name would give none at all.

### The activity log

Every writing operation leaves a line in `refs/karr/log/<role>/<email>`. The
key is role-qualified — role `user` or `agent` — so that a human and an AI
sharing a Git configuration stay separate. That isn't cosmetics:
`karr-foundation` sets `KARR_ROLE=agent` for agent runs and `KARR_ROLE=hook` for
the domain hook, and exactly by that it later recognizes whether an agent has
touched a card (see "Stall" in section 4).

```bash
karr log                      # die 20 jüngsten Einträge
karr log --agent agent-fox    # was dieser Claim-Name getan hat
karr log --task 12 --last 50  # was mit dieser Karte passiert ist
```

### `context` and `metrics`

`karr context` builds a concise board summary for embedding into agent context
files like `AGENTS.md`. Sections are `in-progress`, `blocked`, `overdue`,
`recently-completed` and `activity`, selectable via `--sections`. `--write-to
FILE` replaces the content between the sentinels `BEGIN kanban-md context` and
`END kanban-md context`, or appends the block when the sentinels are missing.

A detail that reveals the intent: the `activity` section shows **only the
entries of other identities**, bounded by `--activity-limit` (default 5). An
agent reading its own briefing already knows what it has done itself — that's
what `karr show --me` is for. What belongs in a briefing is what everyone
*else* has done.

`karr metrics` reports flow metrics, exclusively from the lifecycle stamps
`created`, `started` and `completed`: throughput over 7 and 30 days (fixed
windows, like in `kanban-md`, so both tools mean the same thing), mean lead time
(`completed - created`), mean cycle time (`completed - started`), flow
efficiency and the cards running too long (started, not terminal, no
completion, oldest first). Archived cards never count.

Two details that put honesty before polish. Lead time is **never capped**: a
board with day-granular stamps can produce negative samples, and how many there
are is reported alongside as `negative_lead_samples`, instead of silently
pulling them to zero. And flow efficiency is computed over the cards that
contributed to *both* means, and over their own lead time — that's the one
deliberate deviation from `kanban-md`, which divides the mean cycle time by the
mean lead time, even when the two means were formed over different populations.
Where every finished card has a usable start, the same comes out; where not,
`kanban-md`'s definition can report an efficiency above 100%, and that describes
nothing.

### Board administration

```bash
karr config                    # zusammengeführte Einstellungen ansehen
karr config get foundation.enabled
karr config set foundation.enabled false
karr config --defaults         # die eingebauten Vorgaben statt dieses Boards

karr sync                      # refs/karr/* explizit holen und pushen
karr backup > karr-backup.yml  # ganzes Board als YAML
karr restore --yes < karr-backup.yml
karr destroy --yes
```

`karr sync` synchronizes `refs/karr/*` with the remote — without flags first
fetch, then push, plus one delete refspec for each ref that this clone has
deleted and not yet published (read off the tombstones under
`refs/karr-local/deleted/`). The push does **no prune**: a remote ref this clone
has never seen is another agent's card and not leftover — pruning it is the way
a card has actually been lost once.

After that, the same command does the same for `refs/karr-foundation/*`, the
shared namespace of `karr-foundation` (chain, run logs, questions mailbox). One
command for both, because a second one would be a second thing you could forget
— and the forgetting would be silent. The board half runs first, and the fleet
half never alone: the board identity and wipe refusals are what protects the
fleet refs against a swapped remote, because this namespace has none of its own.

`restore` is deliberately destructive — it first deletes the current
`refs/karr/*` and then plays in the snapshot. `destroy` removes the board
completely. If a remote exists, both also prune there.

### Helper refs

Not every shared state is a card. `karr set-refs` and `karr get-refs` put
arbitrary payloads into refs outside of `refs/karr/*`:

```bash
karr set-refs superpowers/spec/1234.md draft ready
karr set-refs superpowers/spec/1234.md < design.md    # mehrzeilig über stdin
karr get-refs superpowers/spec/1234.md
```

The arguments after the ref are joined with a space, so they're a single-line
payload. A document comes via stdin: without a content argument, `karr set-refs
REF < file` stores the file verbatim, and `karr get-refs REF > file` returns it
unchanged. Good for planning blobs, generated specs, agent scratch state,
workflow metadata you want synced through Git without modeling it as a card.

Protected namespaces are locked: branches, tags, remotes, stash, `refs/karr/*`
and `refs/karr-local/*` (where `karr pick` keeps its process-local locks).
`refs/karr-foundation/chain/*`, `.../log/*` and `.../questions/*` are
**read-only** for `set-refs` — those are written by `karr-foundation` with
schema and compare-and-swap — while `get-refs` reads them freely. That's exactly
how you look at a step, a run log or a question.

### Skills

The distribution ships two agent skills, installable locally in the repository
or globally in the home directory: `kanban-issues-karr-coordination` (reading a
board, picking, creating and routing cards, config, sync) and
`kanban-issues-karr-ticket` (working the one card an agent was handed). Every
`karr skill` action handles both as one set:

```bash
karr skill install
karr skill install --agent claude-code
karr skill install --agent codex --global --force
karr skill check --global
karr skill update
karr skill show [NAME]      # both SKILL.md files, or the one named
```

Targets are `claude-code`, `codex` and `cursor`. Earlier releases shipped a
single `kanban-issues-karr-cli` skill instead; `install` and `update` remove a
leftover one, and `check` reports it as `stale` and exits 1, so `karr skill
update` alone migrates an old install.

### Characters inside, octets only at the edge

A rule that has no command line but affects every output: everything between the
CLI entry point and the Git ref blob is a Perl **character** string.
`App::karr::Encoding` owns every crossing — `@ARGV`, STDOUT/STDERR, ref reading
and writing, YAML, JSON — and nothing else may encode or decode directly. Boards
written before this rule are detected via `refs/karr/meta/encoding` and repaired
on read; `karr repair` migrates them permanently. The reason this is worth
mentioning at all: a double-encoded UTF-8 in a card title is the bug nobody
notices until the board has been broken for months.

---

## 4. `karr-foundation` — the coordinator

A board is half the battle. `karr-foundation` is the other half and the reason
why `karr` isn't just a file-based kanban.

It's a single-shot, idempotent companion binary. It watches **many**
repositories, decides per board whether there's work there, and lets the
configured agent command run until the board stops moving. Cron, a systemd
timer or a `while` loop point at it; every tick is complete in itself.

And it has two operating modes, each useful on its own:

| If you want | you call | you get |
|---|---|---|
| a picture of every board | `karr-foundation --status` | status counters, in-progress/blocked cards, lock, cooldown, agent state, open questions — read-only, an agent is never started |
| agents to work the boards | `karr-foundation` | one agent per repository, per the `.karr` file in it. If there is no `.karr` anywhere, it prints the overview instead |

**Agent execution is opt-in.** That isn't reticence but the security design: a
default that suddenly starts four agents on an operator's laptop would be a
surprise, and the surprise would land on a machine, not in a review.

### What a tick does

In order — and the order is the interesting part. (The hub commands `ask`,
`answer` and `chain` come before it and never discover a board: a question is
fleet state in the hub and has nothing to do with which repositories this
machine drains.)

1. **Discover repositories.** From `dirs:` (explicit list) and `scan:` (direct
   children of a directory that have a `.karr` file or are themselves a karr
   board). A repository reachable both ways is processed **once**, not twice —
   deduplicated over the canonical filesystem path, because the same thing can
   appear as a string, with a trailing slash, or as a symlink and its target.
   If nothing is found at all, that's a runtime error with exit code `1`.
2. **`--status`?** Then print the overview and be done.
3. **Is an agent even running anywhere?** Per board it's resolved once whether
   it is disabled and which command (and which named agent) would run. If the
   answer is "none" everywhere, `karr-foundation` prints the overview — with a
   line saying why, and how to turn it on.
4. **Pull the fleet namespace.** `refs/karr-foundation/*` from the hub, and
   before anything reads it, so this tick's limits are the fleet's current ones
   and not the ones this machine happened to fetch last. An ordinary tick writes
   **nothing** back there.
5. **Install signal handling.** `SIGTERM`/`SIGINT`/`SIGHUP` take every running
   agent along: first `TERM`, then `KILL` to the **process group** of the
   agent. Without it the agent would remain behind as an orphan at `init`, while
   the `.karr.lock` names a dead PID — and the next cron tick would read the
   dead PID as free and start a second agent on the same board.
6. **Work the boards**, serially or concurrently (see `concurrent:` below).

Per repository, in exactly this order:

1. Is there a board here at all? (`.karr` file or `refs/karr/config`)
2. **Is the board disabled?** — first, before everything else.
3. Resolve the agent command. None? Skipped.
4. Is the `.karr.lock` held? Then someone is already working on it.
5. Is the board in cooldown?
6. Is the named agent currently down?
7. Pull `refs/karr/*` — and then check the disabling **again**, because the
   pull may have just brought in the flag from another machine.
8. Is there reason to run? (`--force`, or the board has moved since the last
   tick, or there are workable cards, or `on_idle: always-run`)
9. Take the lock (`flock(2)`), drain, run `on_drained`, release the lock.
10. Advance cooldown and agent availability, write `.karr.state`.

### Where the pieces live — and which ones travel

This table is the most important of the section because it makes the design
decision visible:

| File or ref | Scope | Written by |
|---|---|---|
| `~/.config/karr-foundation/config.yml` | this machine (`--config` moves it) | you |
| `<repo>/.karr` | this machine, this repository | you |
| `<repo>/.karr.state`, `.karr.lock`, `.karr.log` | this machine, this repository | foundation |
| `agents.state`, next to `config.yml` | this machine | foundation |
| `refs/karr/config` → `foundation.enabled` | **the board — synchronized** | `karr disable` / `karr enable` |
| `refs/karr-foundation/*` in the hub — chain, run logs, questions mailbox | **the fleet — synchronized** | `karr-foundation chain` / `ask` / `answer` |

### Why execution configuration never lies in the repository

That isn't a matter of taste, and it's worth writing out the reasoning because
it carries the whole architecture.

**Which agent commands exist is a property of the machine.** A `claude` wrapper
that exists on the development laptop doesn't exist on the build server. A
repository that names a command in its shared configuration schedules work that
can't run elsewhere.

**Whether an agent currently works is a property of the machine and the
account.** A spent quota belongs to a person, not a project. If it were board
state, a push would distribute the spent limit of *one* person to the fleet of
*all*.

**How many agents may run at once is a property of the machine.** It protects
the CPU and memory of this box. It says nothing about what any account may
spend.

Hence: `.karr` and `config.yml` and `agents.state` are local, always, without
exception. The one thing that belongs to execution and is still synchronized is
the refusal — `karr disable` — and that is deliberately board state, because
"nothing shall run automatically on this board" is a statement about the
*project* and not about the machine.

### The first run

With nothing configured at all:

```console
$ karr-foundation
karr-foundation: config not found at /home/dev/.config/karr-foundation/config.yml — nothing to do
karr-foundation: no repos found — check config
$ echo $?
1
```

Naming the repository:

```yaml
# ~/.config/karr-foundation/config.yml
dirs:
  - /srv/webapp
```

That's already enough for the read-only half:

```console
$ karr-foundation --status
webapp
  3 tasks
  backlog:1  todo:2
```

An ordinary tick still does nothing, and says why:

```console
$ karr-foundation
No agent will run on any board. Showing overview (set 'command:', 'agent:' or 'claude: true' in a .karr file to enable agents; a board disabled with 'karr disable' never runs one).

webapp
  3 tasks
  backlog:1  todo:2
```

Now the opt-in, and that is **in the repository itself**:

```yaml
# /srv/webapp/.karr
mode: ticket
command: my-agent --task "$KARR_TASK" --prompt "$PROMPT"
max_runtime: 1800
max_attempts: 2
```

### The three modes: `drain`, `single`, `ticket`

`mode:` says what **one pass over a repository** is:

| Mode | Meaning |
|---|---|
| `drain` (default) | run the agent again and again until the board stops moving |
| `single` | exactly one agent run; the agent finds its own work |
| `ticket` | exactly one agent run, over **one card that foundation names** |

`drain: true|false` is the older spelling of the first two and stays valid
(`true` = `drain`, `false` = `single`). Two keys that both mean "one run" would
be a trap, so it's one key with an alias: `mode` is asked first, `drain` only
answers when `mode` is missing, and a `drain` per repository still wins over a
`mode` from the global configuration. An unknown `mode` is an error that skips
the repository — never a silent fallback to "well then drain".

**Ticket mode deserves its own explanation**, because it's the mode the chain
builds on. Before starting the agent, foundation selects the card that the run
is about — with `karr pick`'s own eligibility and ranking check (not terminal,
not held back in `backlog`, not blocked, not held by a live claim; class, then
priority, then identifier).
These rules live in *one* role that both `karr pick` and foundation's picker
compose. Until that was the case, they stood written out twice, and only the
fact that they were copied from each other kept them in agreement — while a
coordinator that names a different card than the board would hand out argues
with its own board.

The card is told to the agent **twice**: as the closing sentence in the
`$PROMPT`, which names the identifier, and as `$KARR_TASK` for a command
template that wants the bare number. That the identifier is spliced into the
prompt and not the prompt itself writes `$KARR_TASK` has a prosaic reason: the
prompt reaches the agent as `$PROMPT`, and `/bin/sh` doesn't rescan an expanded
value — a prompt that contained `$KARR_TASK` would give the agent those ten
characters.

And: **foundation names the card, it doesn't claim it.** The claim is the
agent's work session: foundation exports `KARR_CLAIM` for the run (the
checkout's `karr agent-name --unique`, minted once per run), and the agent's
own `move` and `handoff` calls default to it. The environment is the whole
protocol — a claim foundation stamped itself would need one of its own to reach
the agent. The board's `.karr.lock` and the rule
"one agent per repository" keep everyone else away for the duration of the run
anyway. An agent that dies mid-run leaves at most its own claim — resolved by
`claim_timeout` or `karr unlock` — and costs one attempt on foundation's
counter.

If there is no assignable card at all, **no agent** runs in ticket mode;
`.karr.log` gets `TICKET none assignable`, and the result is `idle`. `--force`
and `on_idle: always-run` force the check, not a run without a card.

### Look first, then run

```console
$ karr-foundation --dry-run --verbose
sync --pull /srv/webapp
[2026-08-18T05:35:34] 1565842: TICKET task#1
[2026-08-18T05:35:34] 1565842: START command=my-agent --task "$KARR_TASK" --prompt "$PROMPT"
exec in /srv/webapp: my-agent --task "$KARR_TASK" --prompt "$PROMPT"
[2026-08-18T05:35:34] 1565842: DRY-RUN (skipped)
[2026-08-18T05:35:34] 1565842: STALL task#1 — no report from the agent
```

A dry run starts nothing and writes nothing — no agent, no `.karr.state`, no
`.karr.log`, and not even the pull that the first line announces. It's also mute
without `--verbose`: those lines are the verbose stream, not a report.

Then the real thing:

```console
$ karr-foundation --verbose
sync --pull /srv/webapp
[2026-08-18T05:35:34] 1565844: TICKET task#1
[2026-08-18T05:35:34] 1565844: START command=my-agent --task "$KARR_TASK" --prompt "$PROMPT"
exec in /srv/webapp: my-agent --task "$KARR_TASK" --prompt "$PROMPT"
working on #1 as fund-duty
[2026-08-18T05:35:35] 1565844: END elapsed=1s exit=0
```

The agent's output is streamed to the terminal in real time when there is one
(or with `--verbose`), and always appended to `.karr.log`. The card has moved,
so there's nothing more to say. `.karr.state` now carries the board fingerprint
against which the next tick compares:

```json
{"hash":"e256a65404833f0e801b323e1e2301fd","last_exit":0,"last_run":"2026-08-18T05:35:35"}
```

The command is a **shell template**, not a string that `karr` rewrites. Exported
into the child's environment: `PROMPT` (the instruction), `KARR_REPO` (where it
is), `KARR_ROLE` (`agent` or `hook`), `KARR_TASK` (the identifier in ticket
mode, otherwise empty) and `KARR_CLAIM` (the claim name the child's `karr`
calls default to).

### How a run is judged

After every agent run, foundation classifies the result from what it can observe
— the run's own report where the agent gave one, otherwise from the exit code,
the board's ref movement and the captured output:

| Result | What it means | What follows |
|---|---|---|
| **progress** | the board has moved (in ticket mode: *this* card has moved) | keep draining |
| **stall** | a card the agent was working on hasn't moved | increment that card's attempt counter; at `max_attempts` automatically block |
| **common-error** | non-zero exit, timeout, or an error pattern in a run that moved nothing | no card is punished; the repository goes into exponential cooldown |
| **idle** | the agent did nothing and took nothing | stop |

The order of evidence is intentional: **what the run did is asked before what it
printed.** A run that ended with 0 and moved the board is progress, no matter
what text scrolled by, and is never reclassified by its own transcript. The text
scan is evidence only where there is no other — for a run that produced no board
movement at all, which looks exactly like a rate-limited or unauthenticated
agent. A pattern in a run that moved the board **after all** is noted in
`.karr.log` and otherwise ignored.

Correspondingly tight are the default patterns: a symptom word only counts next
to an error word in the same line ("network error", "invalid credentials",
"quota exceeded"), not on its own, and an HTTP status only counts where
something next to it identifies it as such ("API error: 429", "429 Too Many
Requests") — not in a diffstat and not in a line number. Before that, an agent
that printed its own board triggered the scan on a backlog title, and a diffstat
with 403 changed lines on the `403`. `error_patterns:` in the `.karr` adds your
own case-insensitive substrings.

**The run's own report.** An agent invoked with `--output-format json` ends its
output with one line: a JSON object that says whether the run failed, how it
ended, how many turns it needed, how long it ran and what it cost. Where there
is such a report, foundation classifies from it, and the text scan doesn't run
at all.

Foundation isn't **configured** for it and doesn't inspect the command for it
either — it reads the end of the output, because that's where the format puts
its result, and then nothing has to be kept in agreement. Only the **last**
non-empty line counts: prose before it is irrelevant, prose that itself contains
such an object can't be confused with it, and anything after it makes the run
unstructured again, upon which the scan takes over.

The **kind** of the reported error then decides:

| Reported kind | Consequence |
|---|---|
| `api_error_status` (a provider status) | exactly the case the scan was written for: board goes into cooldown |
| `error_max_turns` (turn budget exhausted) | **no** cooldown. The agent worked, the provider answered, the task was bigger than the budget — it's logged, the board isn't parked, the run is judged afterwards by what it moved |
| everything else (`error_during_execution`) | keeps its name and cools the board down |

A non-zero exit that a report of *success* doesn't explain is still a common
error: the report belongs to the agent, the exit code maybe to its wrapper.

In ticket mode the report finally separates the two stalls that previously
looked the same — "the agent reports it can't get further" and "the agent did
nothing" — and `.karr.log` names which one it was (`STALL task#N — the agent ran
out of turns`). Without a report it says exactly that instead of guessing.

### Stall, auto-blocking, and what "engaged" means

A stall that repeats ends the loop instead of spinning on it. Here the same
agent ran twice and left its card where it was — only the end of each tick:

```console
$ karr-foundation --force --verbose
...
I cannot make progress on #2
[2026-08-18T05:35:43] 1565933: END elapsed=0s exit=0
[2026-08-18T05:35:43] 1565933: STALL task#2 — no report from the agent

$ karr-foundation --force --verbose
...
I cannot make progress on #2
[2026-08-18T05:35:43] 1565937: END elapsed=0s exit=0
[2026-08-18T05:35:43] 1565937: STALL task#2 — no report from the agent
[2026-08-18T05:35:43] 1565937: AUTOBLOCK task#2: auto-block: no progress after 2 attempts (foundation)
```

The auto-block is a **fallback, not a verdict**: the agent may set a better
reason itself at any time (`karr edit --block`), and a card someone else holds
is never blocked on foundation's word.

And that's the sharpest part of the mechanism. **Engaged** means that foundation
can *prove* that the agent worked on this card in **this** drain: the agent runs
with `KARR_ROLE=agent`, so every `karr` write operation it makes lands in the
board's activity log under the `agent` identity — and only the cards named
there, that nobody holds or that stand under a claim name the agent itself has
written, may be punished.

If this evidence is missing entirely — an agent that doesn't write via `karr`,
an unreadable log — foundation blocks **nothing** and doesn't guess. The drain
then simply ends at its iteration cap (`max_iterations`, default 50), which is
orders of magnitude cheaper than blocking a human's in-progress card out from
under their hands.

### Cooldown: exponential, without an operator

A `common-error` parks the board:

```console
$ karr-foundation --verbose
sync --pull refs/karr-foundation/*
sync --pull /srv/docs-site
[2026-08-18T05:36:04] 1579195: START agent=cheap command=my-small-agent --quiet
exec in /srv/docs-site: my-small-agent --quiet
API error: 429 Too Many Requests
[2026-08-18T05:36:04] 1579195: END elapsed=0s exit=1
[2026-08-18T05:36:04] 1579195: COMMON-ERROR exit=1
cooldown /srv/docs-site — 1m (level 1)
```

In `.karr.state`:

```json
{"cooldown_level":1,"cooldown_until":1787031424,"hash":"06f46bec5e62ca7d8cddafac75eb8299","last_error":"exit=1","last_exit":1,"last_run":"2026-08-18T05:36:04"}
```

The wait grows as `cooldown_base × 2^level` minutes up to `cooldown_max`
(defaults: 1 and 64 minutes) and is reset on the next clean run. `--force` does
**not** override it: it's bounded in time and ends on its own, so it needs no
operator.

`last_error` describes the **last** run and is removed again by the next run
that isn't a common error — otherwise it would outlive the cooldown it caused
and contradict the `last_exit` written next to it. The same goes for
`last_result`, the last report.

### Named agents, and what happens when one breaks

A board has *one* command. A fleet has several agent commands with different
strengths and different failure modes, so the configuration names them, and a
board picks one:

```yaml
# ~/.config/karr-foundation/config.yml
agents:
  main:
    command: claude
    kind: claude-code         # karr hängt -p "$PROMPT", Ausgabeformat und Limits an
    permission_mode: bypassPermissions
    max_turns: 30
    concurrent: 2
    probe_every: 15m
    description: >-
      Strong on refactors and tests. Expensive.
  cheap:
    command: my-small-agent --quiet
    probe_every: 5m
    description: >-
      Fine for copy edits and docs. Weak on multi-file changes.
default_agent: cheap
```

```yaml
# /srv/docs-site/.karr
agent: cheap
mode: drain
```

**The two invocation contracts.** `kind` says what `karr` may append to the
`command` of a definition:

- **`kind: shell`** (the default) — `karr` appends **nothing**. The command is a
  complete shell template. That's exactly what a `.karr`'s `command` has always
  been, and the reason is banal: `karr` can't know what the thing on the other
  end understands.
- **`kind: claude-code`** — the one contract `karr` knows. It appends
  `-p "$PROMPT"`, the output format and `--permission-mode`, `--max-turns` and
  `--allowed-tools` from the definition. That makes privilege escalation a
  property of the agent definition instead of something baked into a wrapper
  script.

The output format is `stream-json --verbose --include-partial-messages` and not
the plain `json` — that's the one deliberate choice in this contract. `karr`
needs the run's own report, which only a structured format produces; but `json`
prints **nothing at all** until the run ends, which silently switched off the
live output on exactly the runs that take half an hour. `stream-json` ends with
the same result object and streams along the way. The ticket identifier is
**not** appended: `claude-code` has no flag for that, so it travels on as the
closing sentence in the `$PROMPT` and as `$KARR_TASK`.

`description` is **never read** by `karr`. It's carried for the agent that
distributes work across the fleet: the thing that selects is a language model,
and that reads prose better than it matches taxonomies. That's why there are no
classes and no enums here. `--status --verbose` prints it:

```console
$ karr-foundation --status --verbose
...
Agents
  cheap  ok
         kind: shell
         Fine for copy edits and docs. Weak on multi-file changes.
  main   ok
         kind: claude-code
         Strong on refactors and tests. Expensive.
```

**Availability: the minimum you can know.** `karr` keeps per named agent `ok`,
or `failing` since a point in time, with the next attempt at a later one. No
costs, no tokens, no quotas — a rate limit and a spent budget look identical
from the outside (the command no longer works), so **one** mechanism covers
both, and every other reason a command can stop working comes along for free.

After the 429 above there are two records, one level apart. The **board** cools
down (see above), and the **agent** is marked as failing, in `agents.state` next
to the configuration file:

```json
{"cheap":{"failing_since":1787031364,"last_error":"exit=1","next_attempt":1787031664,"state":"failing"}}
```

The second record is the one that scales: as long as an agent is down, **every**
board that uses it is skipped — the fact concerns the command and this machine,
not a repository. Two boards on one agent share the failure instead of each
burning its own time window rediscovering it.

```console
$ karr-foundation --status
docs-site
  2 tasks  [cooldown 60s (exit=1), agent:cheap failing]
  in-progress:1  todo:1
  in-progress: #2

Agents
  cheap  failing since 2026-08-18T05:36:04, next attempt at 2026-08-18T05:41:04 (exit=1)
```

```console
$ karr-foundation --verbose
sync --pull refs/karr-foundation/*
skip /srv/docs-site — in cooldown for 59s
```

Neither of the two wait times is overridden by `--force`, and neither needs an
operator. The agent is tried again after `probe_every` — and **the probe is the
run itself**: it isn't tested separately but simply worked on the waiting work
again. If `probe_every` isn't set, the fleet-wide `probe_every` applies,
otherwise ten minutes. Short enough that a five-minute outage doesn't park a
fleet for an hour, long enough that a hard rate limit isn't hammered every
minute.

And then one more thing, which is more intent than function: **every recovery
is recorded** — from when it broke to when it went again, with the error
pattern, bounded to the last twenty per agent. `karr` reads nothing out of it.
Spotting a pattern in these records is the job of the coordination agent, never
of a learning algorithm in `karr`. Twenty failures are already more form than
anyone needs.

Why `agents.state` lies next to the configuration file and not at one of the two
obvious places: `.karr.state` is per repository and this isn't; and the board
configuration synchronizes, which would push one person's spent limit into the
fleet of all. Since several boards can run at the same time, every
read-modify-write is serialized over a `flock(2)` on a sibling file
`agents.state.lock` — a lost update costs in one direction an extra attempt and
in the other every board on this agent its next window.

### `concurrent:`, `scan:`, the `hub:`

```yaml
# ~/.config/karr-foundation/config.yml
scan:
  - /srv                    # jedes direkte Unterverzeichnis, das ein Board ist
concurrent: 3               # Boards, die gleichzeitig einen Agenten haben dürfen (Vorgabe: 1)
hub: /srv/fleet-hub         # das Repository, das refs/karr-foundation/* trägt
```

**`scan:`** takes the direct children of a directory that have a `.karr` file or
are themselves karr boards. **`dirs:`** names repositories explicitly. Both
together are allowed; a doubly reachable repository is processed once.

**`concurrent:`** is a **machine cap**, not a quota. The hard rule stays: **one
agent per repository.** Two agents in one working tree would get in each other's
way over index and checkout, so concurrency is *across* repositories and never
*within* one. Anything else would need a Git worktree per agent and is
deliberately out of scope.

The unit of concurrency is a forked child process that runs the whole pass for
exactly one repository and holds its `.karr.lock` for the duration of its drain.
Forking the whole pass instead of teaching the drain loop to interleave several
agents is the cheap half of this rule: every piece of board state — the lock
file descriptors, `.karr.state`, the engagement record, the attempt counters —
keeps exactly one writer, without a single line of it changing. The only truly
shared state is `agents.state`, and that's locked.

Three levels bound what actually runs, and **the tightest wins**:

| Level | Where | What it is |
|---|---|---|
| machine cap | `concurrent:` in the local configuration | protects the CPU and memory of this box; default `1` |
| operator estimate | `concurrent:` on an agent definition | roughly where this agent's session limit sits |
| plan announcement | `limits:` in the chain header | what this one run declares; can only tighten |

The middle number is an **estimate about someone else's rate limit** and is
allowed to be wrong, because being wrong is cheap here: the agent starts
failing, is marked as such, every board on it is skipped for a probe interval,
and the fallback takes over. This number needs no more error budget than that.

A broken number is treated by where it comes from. In the local configuration
it's a user error — it's the operator's own file, and a `concurrent: "two"`
that silently means one is exactly the quietly wrong answer this distribution
rejects. In the chain header it warns and is ignored: the header was written on
another machine, and not running the fleet because of a foreign typo is worse
than running it at the local cap. Likewise, a `per_agent:` name that this
machine doesn't define is dropped with a verbose note instead of rejected —
agent definitions are local and only local, so a chain written on a machine with
`minimax` that reaches a machine without `minimax` is the normal case and not a
broken plan.

The scheduler **searches** the queue instead of working through it in order: a
board whose agent sits at its own limit is passed over, not waited out.
Head-of-line blocking here would let one busy agent idle the whole machine while
boards wait on another agent.

`--dry-run` stays serial no matter what the cap says: it starts no agent, so
concurrency would buy nothing and would cost the output the order you read it
in.

**`hub:`** names the one repository of a fleet that carries
`refs/karr-foundation/*` — the chain, its run logs and the questions mailbox.
That's a **role, not a separate project**: any repository can take it over, and
a fleet without a dedicated coordination repository appoints one of its own to
it. The local configuration names it. An ordinary tick pulls this namespace
before it reads anything and writes nothing back; executing the chain is a
command of its own.

A missing hub is a **warning, not an error** — everything foundation does
without the chain, it keeps doing. Only the commands that mean nothing without a
hub (`ask`, `answer`, `chain`) fail hard.

### `on_drained` — the hook that `karr` deliberately doesn't understand

When a board has been drained — no workable card left, everything in the
board's own final status (or archived), held back in `backlog`, or blocked —
foundation may run exactly one command in it:

```yaml
# /srv/gate/.karr
command: my-agent --prompt "$PROMPT"
on_drained: ./release-gate.sh
on_drained_max_runtime: 1800
on_drained_max_rounds: 3
```

```console
$ karr-foundation --verbose
sync --pull /srv/gate
[2026-08-18T05:35:54] 1566032: START command=my-agent --prompt "$PROMPT"
exec in /srv/gate: my-agent --prompt "$PROMPT"
no card assigned, nothing to do
[2026-08-18T05:35:54] 1566032: END elapsed=0s exit=0
[2026-08-18T05:35:54] 1566032: START role=hook command=./release-gate.sh
exec in /srv/gate: ./release-gate.sh
release gate in /srv/gate (role=hook)
[2026-08-18T05:35:54] 1566032: END elapsed=0s exit=0
[2026-08-18T05:35:54] 1566032: ON-DRAINED exit=0
```

**`karr` doesn't know what this command does, and must not know it.** In the
fleet this design comes from, it starts a release gate that builds a
distribution, installs it, tests every dependent consumer against it and raises
version requirements — across 44 distributions, of which `karr` may not learn a
single detail.

Everything domain-specific — what "done" means for a project, how a release is
verified, which project depends on which — reaches `karr` via `on_drained` and
via **nothing else**. That's why the exit code is written to `.karr.log` and
`.karr.state` and is **interpreted by nobody**: a failing hook doesn't park the
board, doesn't mark its agent as failing, and never becomes the run's
`last_error`. It isn't an agent run and isn't classified as one — no report is
read from it, no error pattern matched against it, no card assigned to it.

It's told where it is, and nothing else: `KARR_REPO`, and `KARR_ROLE=hook`, so
its own `karr` write operations land in their own activity log instead of
counting as an agent's tussle with a card. `PROMPT` and `KARR_TASK` are empty.
It runs in the board's directory, under its own `.karr.lock`, with the same
process-group kill and the same tee to `.karr.log` that an agent gets — a gate
that sends a build to the background must not outlive the run that started it —
but with its own budget (`on_drained_max_runtime`), because how long an agent
may take says nothing about how long a release gate may take.

**"Drained" is a fact about the board, not a name for a result**: there is no
workable card left on it. A backlog card waits for a person to promote it, not
for an agent, so a board with only backlog left is drained too. That's
deliberately the same question that `--force` and `on_idle: always-run` are
answers to, and the only one that keeps the same meaning across all modes. A
drain that ends in a `common-error` doesn't count: a rate-limited agent leaves
behind a board that looks exactly like one it worked through, and foundation
doesn't believe that run itself.

**An empty board isn't the same as finished work.** The hook may fail and create
tickets; then the board is no longer empty, the next tick works them, the board
runs empty again, and the hook is asked again. This cycle **is** the point of
the thing — a gate that reports what it found and runs again as soon as it's
fixed. So it's bounded instead of forbidden, with two guards:

- **The same board isn't asked twice.** The board fingerprint at which the hook
  last ran stands in `.karr.state`; a board that hasn't moved since doesn't get
  a second run. Without that, a repository nobody touches would start a release
  gate on every cron tick, forever — because an empty board stays empty.
- **A chain that never settles is capped.** Every hook run that puts work back
  on the board changes the fingerprint, so the first guard can't see the loop
  "hook creates a ticket, agent works it, board runs empty, hook creates the
  next one". Consecutive rounds in which the hook itself produced work are
  counted; a run that leaves the board alone — the gate that finally passed —
  resets the counter, and at `on_drained_max_rounds` (default 3, `0` disables)
  the hook is suppressed, with a line in `.karr.log` that says so.

`--force` overrides both. They're statements about board state, and `--force`
overrides exactly that, per its documentation; and unlike cooldown and agent
availability, the cap isn't bounded in time and doesn't end on its own — so it
needs a way out, and the operator is it.

### The chain: write a plan, run it, read the run log

`karr-foundation chain` is the VM for the sentence that carries the whole
design: *the AI is the compiler, the chain is the program, karr-foundation is
the VM.* The chain lies in the hub as a DAG of steps; the executor takes what
the plan marks ready, checks every `precheck` against facts it measures on the
boards itself, executes and writes state and run log back.

The namespace:

```text
refs/karr-foundation/chain/meta         der Chain-Header (YAML)
refs/karr-foundation/chain/step/<id>    ein Schritt (YAML)
refs/karr-foundation/log/<date>-<id>    das Log eines Laufs (JSON-Zeilen)
refs/karr-foundation/questions/<id>/ask     die Frage (YAML)
refs/karr-foundation/questions/<id>/answer  die Antwort (YAML)
```

**A chain is written with `karr-foundation plan`**: one YAML (or JSON)
document on stdin or `--input PATH`, validated whole before it replaces the
chain in the hub (`--dry-run` checks without writing). Schema, cycle check and
compare-and-swap are why `karr set-refs` flatly refuses this namespace. The
Perl API underneath is the same path — it is what `ex/scripts/write-chain.pl`
uses, and it reads like this:

```perl
use App::karr::Git;
use App::karr::Foundation::ChainStore;

my $chain = App::karr::Foundation::ChainStore->new(
    git => App::karr::Git->new( dir => '/srv/fleet-hub' ) );

$chain->write_chain( [
    { id => 'docs',     kind => 'shell', repo => '/srv/docs-site',
      command => './build-docs.sh', precheck => 'board_actionable == yes' },
    { id => 'smoke',    kind => 'shell', repo => '/srv/webapp',
      command => './smoke-test.sh' },
    { id => 'registry', kind => 'question', needs => [ 'docs', 'smoke' ] },
    { id => 'publish',  kind => 'shell', repo => '/srv/webapp',
      needs => [ 'registry' ], command => './publish.sh' },
], limits => { concurrent => 4 }, note => 'release 0.6' );
```

**The chain is a DAG.** A step lists the step identifiers it `needs`. Steps
without an edge between them may run at the same time — that's how the planner
expresses parallelism: it leaves out edges instead of serializing by hand. The
whole query is "the pending steps whose `needs` are all `done`". **Cycles are
rejected at write time**, not discovered at run time: a chain with a cycle has
steps that never become ready, and a store that accepted it would answer
"nothing to do" forever and look healthy doing it.

A step may carry the following: `id`, `kind`, `repo`, `ticket`, `needs`,
`timeout`, `precheck`, `command`, `note` — plus everything starting with `on_`
(a policy; what its value means is decided by the executor, not the store). Its
state is one of `pending`, `running`, `done`, `failed`, `stale`. "blocked" is
deliberately **not** a state: whether a step waits on another is read off the
`needs` edges, and a second stored copy of it would be another thing that can
contradict the graph.

**A step may not name an agent.** Whoever tries gets a rejection, not a silent
ignoring:

```text
Chain step 'x' names an agent: the chain is shared state and an agent is a
property of a machine, so routing belongs in the local config
```

That's the same dividing line as everywhere else: the chain is shared state, an
agent is a property of a machine, and a chain that names one schedules work that
can't run anywhere else.

**The four kinds:**

| Kind | What it is |
|---|---|
| `ticket` | a card through the **ticket mode** of the target repository — lock, claim discipline, ownership guards and the run's own report come from there, not from a second copy here |
| `shell` | a command in the repository, under its own `.karr.lock`, with `KARR_ROLE=chain` |
| `question` | waits on the mailbox (see below) |
| `plan` | recognized, stays pending, the planner is logged as wanted — see section 6 |

That a `kind: ticket` step **calls** the existing ticket mode instead of
rebuilding it is why the executor isn't a fourth `mode:` variant next to
`drain`, `single` and `ticket`. Those are per repository, the chain is
fleet-wide; a `mode: chain` in a `.karr` file couldn't even answer the one
question that counts here — **which step of the DAG is next** — because that
answer lies in the hub and concerns all repositories at once. So the executor is
the **caller** of these modes and not another one next to them, and the ticket
mode stays a unit that can be tested on its own.

**Prechecks.** A `precheck` is the condition the planner assumed, in the grammar
`<fact> == <value>` (or `!=`). The facts are small and countable:

| Fact | Values |
|---|---|
| `board_actionable` | `yes` / `no` — is there any card not in a terminal status, not in `backlog`, not blocked |
| `ticket_status` | the status of the step's own card |
| `ticket_blocked` | `yes` / `no` |
| `ticket_claimed` | the claim name on it, or the empty string |
| `ticket_links` | `settled` / `open` / `missing` — the far cards of the card's cross-board `needs:` links |
| `question_state` | `answered` / `open` / `overdue` — only for a `kind: question` step |

The division of labor behind it is deliberate: the `ChainStore` **knows the
grammar and measures nothing**, because measuring facts means reading a board,
and reading a board is execution. Everything about a board comes from **one**
board reading. `question_state` is the one fact that isn't measured at a board
at all — it comes from the mailbox, and only for a question step, because that's
the only kind a question has. Measuring it for every step would bring a fact
over which the precheck of no other kind could be, and would cost a mailbox
reading per step.

And the rule that makes the mechanism meaningful at all: **a fact that can't be
measured is absent** — a repository this machine doesn't have, a card that isn't
on the board, a question step that nothing in the mailbox names. An absent fact
does **not** let the precheck hold, whichever operator it uses. There's no
reading of `!=` under which "I couldn't find out" should let a step run. Every
uncertainty falls on the side that costs a planning round instead of the side
that executes the wrong thing.

A step whose precheck no longer holds isn't executed: it's marked `stale` and
the planner is noted as wanted. That's what keeps an outdated chain from doing
harm — it costs time, not correctness. For the same reason chains stay short: a
long chain goes stale faster than it is worked through.

**The pull–claim–push order** is the actual protection, not the compare-and-swap.
Two machines that never exchange refs would each read `pending` from their own
clone and each win their own local CAS. Hence:

- **First pull** — and abort the tick if the pull fails. Everywhere else in
  `karr-foundation`, a failed fetch is a warning, because the fallback is this
  machine's own view and that's the safe direction. Here, the fallback is
  executing a step someone else is already executing — so the tick rather stops.
- **Publish the claim before the work begins.** The window that counts is the
  length of the step, not the length of the write operation: a claim published
  after a half-hour agent run would have left the step readable as `pending`
  for that half hour. A claim that can't be published is rolled back locally to
  `pending` — no other machine ever saw it — and the step stays for the next
  tick.
- **Push result and run log**, best-effort: the work has already happened, the
  state is written locally, the next tick publishes it. Refusing to record a
  completed run would be the worse answer.

**Look first:**

```console
$ karr-foundation chain --dry-run
chain 20260818T053250Z-18641c: 2 step(s) ready (dry run, nothing pulled, claimed or executed)
  step docs (shell) in /srv/docs-site: would run
  step smoke (shell) in /srv/webapp: would run
```

**Then run it:**

```console
$ karr-foundation chain
step docs (shell) in /srv/docs-site: done — exit=0
step smoke (shell) in /srv/webapp: done — exit=0
step registry (question): left pending — question #1 is unanswered (policy: block)
chain 20260818T053250Z-18641c: 2 done, 1 pending
```

**What a failure does to the DAG: nothing** — and that's the design, not an
omission. A step only becomes ready when everything it `needs` is `done`. A step
that ends as `failed` or `stale` therefore stops its own branch
**constructively**: its dependents never become ready, no cascade has to be
computed, and every branch that doesn't run through it continues. The chain can
then no longer finish, and exactly this unreachability is the signal that
`on_stall: plan` names.

Three outcomes are deliberately **not** failures, because none of them is a
statement about the plan:

- A **common error** (a rate-limited or broken agent command) puts the step back
  to `pending`. The board's cooldown and the agent's availability record have
  already been written by the drain; the step just doesn't belong to this
  machine right now.
- A **skipped board** — disabled, locked by another tick, in cooldown or on a
  just-failed agent — is deferred just the same, with the note of which of the
  cases it was.
- A step that **names a repository this machine doesn't have** stays untouched
  and unclaimed. The chain is shared and the machines aren't; that's the normal
  case in a fleet, not a broken plan.

**The run log** is one ref per run in the hub, and reading it is exactly what
`get-refs` is for:

```console
$ cd /srv/fleet-hub
$ git for-each-ref --format='%(refname)' refs/karr-foundation/log/
refs/karr-foundation/log/2026-08-18-053250a33ef5
refs/karr-foundation/log/2026-08-18-0532510c55f1

$ karr get-refs refs/karr-foundation/log/2026-08-18-053250a33ef5
{"chain":"20260818T053250Z-18641c","event":"start","host":"fleet-01","pid":1563039,"ts":"2026-08-18T05:32:50Z"}
{"event":"step","kind":"shell","repo":"/srv/docs-site","state":"running","step":"docs","ts":"2026-08-18T05:32:50Z"}
{"detail":"exit=0","event":"step","state":"done","step":"docs","ts":"2026-08-18T05:32:50Z"}
{"event":"step","kind":"shell","repo":"/srv/webapp","state":"running","step":"smoke","ts":"2026-08-18T05:32:50Z"}
{"detail":"exit=0","event":"step","state":"done","step":"smoke","ts":"2026-08-18T05:32:50Z"}
{"detail":"question #1 is unanswered (policy: block)","event":"step","kind":"question","state":"pending","step":"registry","ts":"2026-08-18T05:32:50Z"}
{"chain":"20260818T053250Z-18641c","done":2,"event":"end","pending":1,"ts":"2026-08-18T05:32:50Z"}
```

The waiting step has a `pending` entry and **no** `running` entry before it —
nothing was claimed and nothing was started.

Run logs are segmented and prune themselves. Segmented, because a ref holds one
blob and a blob is rewritten in full on every append: an uncapped log ref makes
every entry as expensive as a copy of the whole history. Quadratic, and measured
at about 4.6 GB of objects for 1 MB of log. So it's appended to the most recent
segment until it reaches 8 KB, and then the next entry opens
`...<run>+000001`. Retention is the other half of the bound: runs older than 14
days fall away, and regardless of age everything beyond the newest 500. That
runs on its own when a run log is opened — a retention policy that only runs
when someone types a command bounds nothing.

**Steps are executed one after another within a tick.** The chain's concurrency
is the one *across machines* — that's what the pull-claim-push order is for —
and the machine-local concurrency of several boards stays where it is.

And finally: **`chain` is a command of its own** and not something an ordinary
tick does along the way. `karr-foundation` without arguments means "drain the
boards in my configuration", for as long as the program exists. Picking up the
chain automatically would mean that every cron line of a fleet does something
different on the day someone writes a plan into it.

### The questions mailbox

**A question is a file with an answer field, not a dialog.** That single
decision is what eliminates the special case "right now a human happens to be
present". The chain writes the question and continues with everything that
doesn't depend on it; whoever answers — a human at the terminal, a chat bridge,
the coordination agent — writes into the same mailbox without knowing that there
is a chain. One mailbox, many writers.

```console
$ karr-foundation ask "Which registry do we publish the 0.6 release to?" \
    --context "the release gate is waiting" \
    --options cpan,darkpan --default cpan --policy use_default --wait 3600
Asked question #1: Which registry do we publish the 0.6 release to?
  answer with: karr-foundation answer 1 <cpan|darkpan>
  nobody answers: use_default after 2026-08-18T06:37:44Z
```

Open questions show up in the overview, with the identifier that `answer`
takes:

```console
$ karr-foundation --status
...
Open questions
  #1  Which registry do we publish the 0.6 release to?
      options: cpan, darkpan  use_default after 2026-08-18T06:37:44Z
```

```console
$ karr-foundation answer 1 darkpan --note "this one is a private release"
Answered question #1: darkpan
  Which registry do we publish the 0.6 release to?
```

**The three policies** say what happens when nobody answers:

| Policy | When `--wait` has elapsed |
|---|---|
| `block` (default) | keep waiting — that's exactly what blocking means |
| `use_default` | `--default` becomes the answer |
| `escalate_to_ai` | is recorded, and the planner is noted as wanted — **no** agent is called, because there is none |

`use_default` and `escalate_to_ai` require a deadline without exception, because
a policy without a deadline fires at the moment the question is asked and nobody
would ever get to answer; `use_default` additionally requires a `--default`.
Both are rejected where they're written, instead of being discovered where
they're read.

An answer is **create-only** and validated against the options that were
offered — so two answers can't silently merge into one; `--force` on `answer`
is the deliberate way to replace one. Both commands synchronize the fleet
namespace around what they write. `--step ID` is what binds a question to a
chain step.

Two storage decisions that look exaggerated at first glance and aren't. **The
answer is its own ref.** The question could have carried an `answer:` field —
that's how the design document draws it — and deliberately doesn't:
`refs/karr-foundation/*` resolves a ref that both sides have changed in favor
of the remote version and does **not** keep the local one. A plan that lost a
race is re-planned, not read back — so nothing is lost. An answer is not a plan.
It's someone's decision, typed once, and re-planning doesn't reconstruct it.
With the answer in its own ref, asker and answerer never write the same ref, and
the case can't even arise in ordinary use. The other half of it: the question is
written **once** and never rewritten.

**And the answer names the question it answers.** Identifiers are small
integers, minted per clone from the refs that clone can see — two clones that
both ask between two syncs mint the same identifier. The question that loses is
lost (the board's card IDs have the same window, and `ask` narrows it the same
way: it pulls the namespace first). What must not happen is an answer standing
next to someone else's question — so the answer records the question text it
received, and the resolution refuses the pairing if it doesn't match. Loudly,
and a single string comparison.

**Retention:** answered questions age out, open ones **never**. An open
question is work nobody has done, however old it is, and a mailbox that silently
forgot one would be worse than a big one.

**A `kind: question` step resolves a question, it doesn't ask one.** The planner
asks the question first, with `karr-foundation ask --step ID`, and the step does
nothing but resolve it. That's a decision about schemas, not convenience: a
self-asking step would have to carry the question text, the `options`, the
`policy`, the `default` and the `deadline` in the step itself — the mailbox's
schema written out a second time and kept in agreement with the first by hand.

The consequence: a ready question step that **nothing in the mailbox names** is
a planning error and is reported as such — `stale`, with the reason in the run
log and in the tick output, instead of silently waiting for a question that will
never come.

What a question step does is the state of the mailbox plus the policy:

| Mailbox state | The step |
|---|---|
| `answered` | **done**, with the answer in the run log |
| `open` | **pending and unclaimed** — dependents wait, every other branch runs |
| `overdue` + `block` | keeps waiting: waiting **is** what `block` means |
| `overdue` + `use_default` | **done**, with the `--default` as the answer |
| `overdue` + `escalate_to_ai` | pending, and the planner noted as wanted — **no agent is called**, because there is none |
| nothing in the mailbox names the step | **`stale`** — a planning error, reported as such |

**Waiting never holds up the tick.** The question step is looked at once, said
out loud and left lying — pending and unclaimed, without a counted attempt and
without a start stamp, so the next tick finds it exactly as the planner left it.
Its dependents wait constructively, every other branch runs in the same tick.
Answer it and it goes on:

```console
$ karr-foundation answer 1 darkpan
Answered question #1: darkpan
  Which registry do we publish the 0.6 release to?

$ karr-foundation chain
step registry (question): done — question #1 answered 'darkpan' by Dev <dev@example.com>
step publish (shell) in /srv/webapp: done — exit=0
chain 20260818T053250Z-18641c: 2 done
```

With `--policy use_default` and a `--default`, an elapsing deadline settles the
step without anyone typing — here the whole chain runs through in one tick:

```console
$ karr-foundation chain
step docs (shell) in /srv/docs-site: done — exit=0
step smoke (shell) in /srv/webapp: done — exit=0
step registry (question): done — question #1 went unanswered past its deadline; its default 'cpan' stands as the answer
step publish (shell) in /srv/webapp: done — exit=0
chain 20260818T053024Z-e7bc10: 4 done
```

And the planning error is reported instead of waited out:

```console
$ karr-foundation chain
step docs (shell) in /srv/docs-site: done — exit=0
step smoke (shell) in /srv/webapp: done — exit=0
step registry (question): stale — no question in the mailbox names step registry — a question step is asked by the planner ('karr-foundation ask ... --step registry'), it does not ask itself
chain 20260818T052941Z-acdde8: 2 done, 1 stale
the planner is wanted for step(s) registry (no question was ever asked about it) — no planner runs from here yet; re-plan the chain
```

A step waits until **every** question that names it is settled. A planner
normally doesn't write more than one question onto a step; the decider is the
alternative — the first answer would free a step that someone asked a second
question about, and thereby drop an unanswered question, which this mailbox does
nowhere else. A question whose step isn't ready yet is simply not looked at, and
that's the good case: it can be answered long before the step, and then the step
never waits.

One limitation worth knowing: **a question names a step identifier and nothing
else.** A later chain that reuses an identifier inherits what the earlier one
left unanswered underneath it. That can't be fixed by scoping the question to a
chain — a question asked **before** the chain that waits on it is the good case
from just now, and no timestamp can tell the two apart. It's fixed by answering
or deleting a question that no longer interests the fleet.

### The board's refusal: `disable` / `enable`

A board may refuse automated runs **in its own karr state** — which is what
makes a fleet-wide `default_command` possible in the first place:

```console
$ karr disable --reason "docs freeze until the 0.6 release"
Board disabled for automated agent runs (karr-foundation).
  Reason: docs freeze until the 0.6 release

$ karr-foundation --status
docs-site
  2 tasks  [disabled]
  in-progress:1  todo:1
  disabled:    docs freeze until the 0.6 release
  in-progress: #2

$ karr enable
Board enabled for automated agent runs (karr-foundation).
```

Unlike `.karr`, that's **board state** (`foundation.enabled` in
`refs/karr/config`), so it synchronizes, and every foundation instance on every
machine honors it. A disabled board is skipped **entirely**: the flag is checked
before the agent command is resolved and before the drain is decided — no drain,
no auto-block, no agent run. It wins over `--command`, `default_command`, the
`command` from the `.karr` and `claude: true`, and **`--force` doesn't override
it**. Disabled means disabled.

Otherwise nothing changes: the board stays fully usable for humans and for
hand-driven agents. The use case is a repository whose backlog is parked rather
than abandoned — a kept legacy project that a globally configured
`default_command` would otherwise drain through.

The same state is readable and writable via `karr config get` / `karr config
set` (`foundation.enabled`, `foundation.reason`). There's one truth in the board
configuration, and `disable`/`enable` are the ergonomic front door to it. `karr
enable` makes the `foundation` key disappear again entirely from the sparse
overrides, because the value is back on its code default.

### Reference

`karr-foundation` options:

| Option | Effect |
|---|---|
| `--config PATH` | configuration file (default `~/.config/karr-foundation/config.yml`); also moves `agents.state` |
| `--status` | read-only overview of every board, then exit |
| `--dry-run` | decide everything, execute nothing (serial, and mute without `--verbose`) |
| `--verbose` | log lines and agent output on the terminal, agent descriptions in `--status` |
| `--force` | run regardless of board state; with `answer`: replace an existing answer |
| `--command CMD` | one agent command for every board, overrides any `.karr` |
| `ask` / `answer` / `chain` | the hub commands (`--context`, `--options`, `--default`, `--policy`, `--wait`, `--step`; `--note`) |

**Exit codes** follow the same contract as `karr`:

| Code | Meaning |
|---|---|
| `0` | the tick ran through — boards drained, overview printed, question asked or answered, chain worked through |
| `1` | runtime error: no repository found, unreadable configuration, a hub command without a hub, an already answered question, or `chain` couldn't fetch `refs/karr-foundation/*` |
| `2` | usage error: unknown command, unknown option, invalid option value, missing or extra positional argument |

A **failed chain step doesn't change the exit code** — that's a statement about
the plan, not about the binary. A run terminated by `SIGTERM`, `SIGINT` or
`SIGHUP` ends with `128 + signal`, after taking its agents along.

`config.yml` keys:

| Key | Meaning |
|---|---|
| `dirs:` | explicit board repositories |
| `scan:` | parent directories whose direct children are checked for a board |
| `concurrent:` | machine cap of simultaneous boards with an agent (default 1) |
| `hub:` | the repository that carries `refs/karr-foundation/*` |
| `agents:` / `default_agent:` / `probe_every:` | named agent definitions, the fallback agent, the default retry interval |
| `default_command:` / `default_prompt:` | fleet-wide command and fleet-wide prompt |
| `mode:`, `claude:`, `claude_bin:`, `claude_max_turns:`, `claude_permission_mode:`, `on_drained:`, `on_drained_max_runtime:`, `on_drained_max_rounds:` | fleet-wide defaults for the `.karr` keys of the same name |

`.karr` keys per repository (each wins over the fleet-wide value):

| Key | Meaning |
|---|---|
| `command:` | the agent command; a shell template, `$PROMPT` and `$KARR_TASK` are exported into it |
| `prompt:` | the instruction passed as `$PROMPT` |
| `agent:` | a named agent from `agents:` |
| `claude:` / `claude_bin:` / `claude_max_turns:` / `claude_permission_mode:` | synthesizes the canonical claude command (opt-in) |
| `mode:` | `drain` (default), `single`, `ticket`; `drain: true\|false` is the older spelling of the first two |
| `on_idle:` | `skip` (default) or `always-run` |
| `max_runtime:` | SIGKILL per command in seconds (`0` = no timeout) |
| `max_attempts:` | stalls on a card until it is auto-blocked (default 2) |
| `max_iterations:` | hard cap for drain iterations (default 50) |
| `cooldown_base:` / `cooldown_max:` | cooldown minutes at level 0 (default 1) and the ceiling (default 64) |
| `error_patterns:` | additional case-insensitive substrings that count as common error |
| `on_drained:` / `on_drained_max_runtime:` / `on_drained_max_rounds:` | the domain hook, its budget and its round cap |

**Command resolution order**, highest first: `--command`, `default_command`, the
`command` from the `.karr`, the `agent` from the `.karr`, `default_agent`,
`claude: true`. A board disabled with `karr disable` runs none of them. A board
that names an agent the configuration doesn't define is an error that skips
**this board** — not one that silently stops everything.

Full details: `perldoc App::karr::Foundation`, and for the chain
`perldoc App::karr::Foundation::Executor`,
`perldoc App::karr::Foundation::ChainStore`,
`perldoc App::karr::Foundation::Questions`,
`perldoc App::karr::Foundation::Agents`.

---

## 5. The architecture idea

Everything up to here is mechanics. The reason the mechanics look the way they
do and not otherwise is three layers.

### The three layers

**Coordination — shared, in refs.** Cards, dependencies, escalations, the chain
of planned steps, open questions, the run log. All of it lies in Git refs and is
synchronized with the remote, so every machine and every person sees the same
picture.

**Execution — local, never in the repository.** Which agent commands exist on
this machine, whether they currently work, when to try again, how many may run
at once. Never in the repository: an agent command that exists on one machine
may not exist on the next, and an account limit is a property of a person, not
of a project.

**Judgement — an agent.** Planning, routing, reacting to the unexpected. That's
a coordination agent, invoked like any other agent, and **only when a written
plan is missing or broken.**

`karr` owns the first two. The third is the one that was never built — see
section 6.

### The sentence that carries the whole thing

> **The AI is the compiler, the chain is the program, karr-foundation is the
> VM. No agent runs in the hot path.**

That's the interesting part, and it's worth unpacking.

The obvious construction for "coordinate several agents across several
repositories" is an orchestrator agent: a language model that reads the state of
all boards, decides what happens next, and then starts workers. That works
immediately and has three properties that make it unfit:

- **It costs on every decision.** Every tick is an inference call. With a cron
  line on a five-minute cadence and 44 repositories, that's a permanent expense
  for decisions that mostly haven't changed at all.
- **It isn't reproducible.** Twice the same state, twice possibly a different
  plan. That's exactly the property you don't want in a scheduler.
- **It isn't auditable.** Why did step 7 run before step 4? "The model found it
  better." There's no artifact you can look into.

The inversion is the design here. The AI is called **once** and writes a plan —
the chain. The plan is an artifact: it lies in refs, it has a schema, it has a
DAG, it has prechecks, and anyone can read it. After that, a dumb, deterministic
machine executes it, step by step. Between two deviations **no AI runs at all**,
and that's exactly what makes the thing affordable.

The `precheck` is the seam between compiler and VM. It's the condition the
planner assumed when it wrote the step, captured in machine form. If it still
holds, the step runs without anyone having to think. If it no longer holds, the
plan is outdated at that point — and then, and only then, the compiler is back
in. That's why a step names no agent: that would be an execution decision in the
program, and the program is shared.

That an absent fact does **not** let the precheck hold is the same thought in
its hardest form. The VM never guesses. It rather falls back into a planning
round — which costs time — than into the execution of the wrong thing — which
costs what the step does.

And from the same direction comes the rule for chain length: a long chain goes
stale faster than it is worked through. A plan isn't a project plan, it's a
compiled artifact with a limited half-life.

### The boundary: `karr` learns nothing about the projects

The second carrying thought is an omission.

`karr-foundation` doesn't know what a release is. It doesn't know what a build
is, what a test is, what "done" means for a particular project, which project
depends on which. It knows: there are boards, on boards lie cards, cards have
statuses, and there's a command you can run.

Everything beyond that reaches it through **exactly one** channel: `on_drained`.
A command in the repository whose exit code lands in `.karr.log` and
`.karr.state` and is interpreted by nobody.

That's the reason a release gate in the fleet this design comes from can run
across 44 distributions without `karr` containing a line about Dist::Zilla,
CPAN, version requirements or dependency graphs. The temptation to build in
"just a little rule" about exit codes is there with every such hook, and giving
in to it is the way a generic tool becomes the special tool of a single fleet.

### Escalation across repository boundaries

The most common real-world abort in a fleet is "that won't work until X is
fixed elsewhere". An agent may neither give up nor reach into the neighboring
repository. It reports:

1. `karr create` in the other repository, tagged `escalated-from:<repo>#<id>`
2. `karr edit <id> --block "needs <repo>#<id>: <Grund>"` in its own
3. release the claim, exit

The coordinator sees both sides in the next cycle. **The order is therefore not
planned, it is discovered** — and that's why work rotates between repositories
instead of finishing them one after another: a newly discovered prerequisite
simply moves up in the rotation instead of breaking a plan.

`App::karr::CrossBoard` and `karr needs` are the half of it that was made
explicit: the reference is a tag with a board **name** and card ID, and
`--resolve` cleans up what has resolved itself. The automatic resolution
*within a chain* it is not — that's for the next section.

---

## 6. What isn't built

This section isn't a weakness of the article. It's the reason you can believe
the rest.

> **Since this was written**, three of the gaps below have been closed: the
> coordination agent (`role: coordinator` on an agent definition, called at the
> end of a tick for the deviations it met, writing the assignment, chains and
> questions — so `escalate_to_ai` reaches it where one is marked), writing a
> chain from the CLI (`karr-foundation plan`), and cross-board links in a chain
> (the `ticket_links` precheck fact). The table and the subsections after it,
> and the remarks in sections 5 and 7 that the judgement layer is missing,
> describe the state before that; the "What is built, and what is not" table in
> the distribution's `README.md` is the current one.

| Piece | Status |
|---|---|
| overview, discovery, `drain`/`single`/`ticket`, cooldown, stall detection, auto-block | built |
| `disable` / `enable`, lock and state per repository, concurrency, `on_drained` | built |
| named agents, `kind: claude-code`, availability probing, `agents.state` | built |
| the questions mailbox: `ask`, `answer`, listing in `--status`, the policies | built |
| `chain` with `kind: ticket`, `kind: shell`, `kind: question`, prechecks, run logs | built |
| `kind: question` against the mailbox | built — pending and unclaimed while the answer is `open`; done as soon as it's there; `use_default` takes the default; `stale` when nothing in the mailbox names the step |
| `kind: plan` steps | **not executed.** Recognized, stay pending, the planner is noted as wanted |
| the coordination agent / planner | **not built.** The one layer of the design that was never written, and it doesn't even have a ticket |
| writing a chain via the CLI | not built — a chain is written via `App::karr::Foundation::ChainStore` |
| `escalate_to_ai` | only recorded, for the same reason: there is no agent to escalate to |
| cross-board links in a chain | not built — no step and no precheck fact reaches a card on another board; `karr needs` is the hand-work half |

### The judgement layer doesn't exist

That's the most important line in this table. The design has three layers, `karr`
owns two of them, and the third — the agent that plans and routes — was never
written.

It isn't half built, not hidden, not behind a feature flag. It isn't there.
That's why "the planner is wanted" is an **output line** and not a call:

```console
$ karr-foundation chain
step smoke (shell) in /srv/webapp: done — exit=0
step replan (plan): left pending — this foundation runs kind: ticket, kind: shell and kind: question
chain 20260818T053131Z-c075f7: 1 done, 1 skipped
the planner is wanted for step(s) replan (kind: plan is not executed here) — no planner runs from here yet; re-plan the chain
```

And where the design says "call the planner", nothing is written that a future
planner would have to undo, and no agent is invented to fill the gap. That's the
difference between an open seam and a dummy.

Concretely that means:

- **`kind: plan`** is recognized and stays pending. The executor behaves exactly
  as with `escalate_to_ai`.
- **`escalate_to_ai`** as a question policy is recorded. No agent is called.
  Whoever sets this policy must know that today it works like `block`, only with
  an extra log line.
- **The routing over agents** — the part of the spec in which the coordination
  agent reads the prose descriptions and writes an assignment with fallback
  chains — doesn't exist. What exists are the two inputs it would need, and both
  are plain local files today: the `agents:` section of the configuration and
  `agents.state` next to it. There's deliberately no CLI surface around it. If
  it turns out that a coordination agent wants one, that's a new ticket.

### Cross-board links don't resolve in a chain

`karr needs` reads and cleans up cross-board references, but **no chain step and
no precheck fact reaches a card on another board**. The natural place for it
would be the executor's fact table (a fact about the remote card) or a step kind
of its own. Both are seams that were deliberately left open, and both hang at
exactly one place in the code — which is why it's an open seam and not a thread
through the whole class.

### You write a chain in Perl

There is no `karr-foundation chain write`. A chain comes into being via
`App::karr::Foundation::ChainStore->write_chain`, from Perl. That's a
consequence and not a convenience — schema, cycle check and compare-and-swap
updates are the reason `karr set-refs` refuses this namespace at all. But it
also means: whoever wants to write a chain today writes a Perl script.

You can consider that an interim state. But you shouldn't consider it an
oversight: the tool that should write a chain is the planner, and that's the
layer that doesn't exist. A CLI that lets humans write chains by hand would be
an answer to a different question.

### And a few smaller honest edges

- **A question names a step identifier and nothing else.** A later chain that
  reuses an identifier inherits unanswered questions underneath it.
- **`karr needs` doesn't fetch.** The remote board's state is as fresh as its
  last `karr sync`.
- **`karr init` doesn't write the foundation files into `.gitignore`.** Four
  lines by hand, see section 2.
- **`git clone` doesn't fetch `refs/karr/*`.** A fresh clone needs a `karr
  sync` before it sees the board.
- **Cross-board references live in `tags`**, so `karr edit --add-tag` can bypass
  the validation and `--remove-tag` can tear a reference apart. The typed doors
  (`--needs`, `--add-needs`, `karr needs`) are the documented ones; the cost of
  the convention is spoken out loud instead of hidden.

---

## 7. Why the whole thing

Back to the beginning: several agents, several repositories, and the state of
this work has to live somewhere where everyone can see it and nobody can break
it.

The answer `karr` gives has two parts, and both are rather omissions than
inventions.

**The state lies in Git refs.** Not in files, not in a database, not in a
service. That costs a fresh clone having to synchronize first, and it buys that
there are no merge conflicts over board bookkeeping, no commits nobody wants, no
server someone has to operate, and a compare-and-swap Git could already do
anyway.

**The decisions lie in a written plan.** Not in a model that rethinks on every
tick. That costs that someone — today: a human with a Perl script, tomorrow
maybe a coordination agent — has to write the plan, and it buys that no
inference runs between two deviations, that the plan is a readable artifact, and
that an outdated assumption says `stale` loudly instead of quietly doing the
wrong thing.

What is deliberately missing is just as much part of the answer. `karr` knows
nothing about releases, nothing about builds, nothing about what "done" means in
any concrete project. These things reach it through a single command called
`on_drained`, whose exit code is interpreted by nobody. A kanban tool that
starts to understand release processes stops being a kanban tool.

And the judgement layer is also missing, deliberately visible. `kind: plan`
stays lying, `escalate_to_ai` only logs, and the output line says "the planner
is wanted" instead of inventing one. A tool that did something plausible at this
point would be harder to repair than one that says what it can't do.

That's the state: the VM runs. The compiler is still missing.

---

*`App::karr` is free software under the same terms as Perl 5 itself. The source
for this text is the distribution's README and its code; every command and every
output shown here comes from a real run or from the code that produces it.*
