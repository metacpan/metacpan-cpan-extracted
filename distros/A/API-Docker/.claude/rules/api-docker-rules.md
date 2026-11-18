# API-Docker House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Perl client for the Docker Engine API. Read first: `Role::HTTP` — the seam every resource API
and entity class hangs off.

## Agent team

| Task | Agent |
|---|---|
| What the daemon does or expects — endpoints, wire formats, filters, registry auth, version gating | `api-docker-engine-worker` |
| The Perl side — Moo, transport internals, entity classes, refactoring, cpanfile | `api-docker-worker` (default) |
| Write/extend tests, add fixtures | `api-docker-test-writer` |
| The generated type model, the `API::Docker::Type` DSL, the drift checker, `spec/` | `api-docker-type-writer` |
| Commits, `Changes`, card → done, pre-release audit | `api-docker-release-manager` |
| POD and README | `api-docker-doc-writer` |
| Read-only research, audit, gap analysis | `api-docker-worker` ("read-only, change nothing") |

The two workers split by *question*, not by file — only `api-docker-engine-worker` carries the
Engine API reference.

Behavior-relevant = the HTTP transport and everything it returns, the resource API method
surface, entity wrappers, request/response encoding, error handling, `cpanfile`, and tests —
not prose, not `Changes`.

## Parallel fan-out — isolate the working tree

- **A subagent never mutates git** — no `stash`, `reset`, `checkout --`, `clean`, `add`,
  `commit`; the orchestrator owns git.
- **Two or more code-touching agents at once must be isolated** — `isolation: "worktree"` or
  sequentially, never in one tree.
- **A worktree may branch from a stale base.** Integrate by diff, never
  `git checkout <branch> -- <file>` — that reverts main.
- **Commit a verified-green checkpoint before the next mutating fan-out** — a committed HEAD
  survives a stray `reset`.

## Deviations from the house rules

- **CPAN RT counts as a public tracker** alongside GitHub issues on `Getty/p5-api-docker`.

## Hazards — mechanics in skill `api-docker-hazards`

- **Which engine is there is a fact about the machine.** `check_live_access` answers a missing
  socket with `skip_all`, so a live run can report success while testing nothing. A measurement
  names engine and version.
- **Live write tests mutate the real engine.** `API_DOCKER_TEST_WRITE=1` creates and removes
  real containers, images, networks and volumes; an interrupted run leaves them behind. Run only
  when the task is about live behavior.
- **No `prune` of any kind, no `rm -a`, no `system reset`, on either engine, ever, unless the
  user names the command.** `dangling => ['false']` removes every unused *tagged* image, locally
  built ones included.
- **`images->push` publishes.** With credentials it writes to a real registry under the
  maintainer's account. Never run it — or any test that does — without explicit instruction.
- **Streaming endpoints block until the daemon closes, unless given a callback.** Pass
  `on_event`/`on_frame`/`on_chunk` or bound the window; a callback still needs `$stop->()`.
- **`../p5-dist-zilla-plugin-docker-api` consumes this API.** A public signature or
  return-shape change is a cross-repo change: verify that repo or file a ticket there.
- **`[@Author::GETTY]` gathers through `Git::GatherDir` — tracked files only.** A new `.pm`,
  test or fixture is invisible to `dzil build`/`dzil test` until it is `git add`-ed;
  `prove -lr t/` stays green.

## Perl specifics — reference, don't restate

Skills `api-docker-core`, `docker-engine-api`, `api-docker-hazards`; Perl house skills
`getty-perl-core`, `getty-perl-moo`, `getty-perl-release-author-getty`, `perl-release-dist-ini`,
`getty-git-commit-style` (force-loaded for `api-docker-*` agents).
