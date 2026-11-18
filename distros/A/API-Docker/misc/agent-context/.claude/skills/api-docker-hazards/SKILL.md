---
name: api-docker-hazards
description: "Use when touching the engine, the live tests or the build of the API::Docker distribution: which daemon answers on the socket, GET /version, DOCKER_HOST or the docker CLI, live write tests, prune and push, streaming endpoints, Git::GatherDir, or several agents in one working tree."
---

# API::Docker — hazards and mechanics

The rules file names the prohibitions; this skill carries the mechanics behind them.
Every entry is a trap that makes the wrong thing look right — read the mechanism, then
follow the rule.

## Which engine is there is a fact about the machine

Before any live run, check which sockets exist and what each one announces:

- `/var/run/docker.sock` — the Docker daemon
- `$XDG_RUNTIME_DIR/podman/podman.sock` — Podman's rootless socket

`GET /version` answers with `Platform.Name`, `ApiVersion` and `MinAPIVersion`. Those
are the facts. The `/v1.XX/` in a hand-written curl is what *the request asked for*,
not what the engine is — a curl pinned to `/v1.41/` against an older daemon returns an
error, not a version.

**The trap:** `check_live_access` answers a missing socket with `skip_all`. A live run
pointed at a socket that is not there reports *success* while testing nothing. So read
the skip line before believing a green run.

**Do instead:** a measurement names the engine and the version it was taken on — write
both into the output, or it is not a measurement.

The `docker` CLI is not `/var/run/docker.sock`: it talks to whatever `DOCKER_HOST` or
the active docker context names.

**The trap:** `docker images` or `docker events` can print another engine's answers
under Docker's name. On the maintainer's machine on 2026-11-17 `DOCKER_HOST` pointed at
Podman: two agents checked Docker with the CLI, one reported nothing pulled, while
`/events` on `/var/run/docker.sock` showed two `image pull nginx` — and `docker ps -a`
printed the same list as `podman ps -a`.

**Do instead:** ask the socket itself
(`curl -s --unix-socket <sock> http://localhost/…`), or name the host explicitly
(`docker -H unix:///var/run/docker.sock …`). Never trust the bare `docker` CLI to mean
the Docker daemon.

## Live write tests mutate the real engine

`API_DOCKER_TEST_WRITE=1` creates and removes actual containers, images, networks and
volumes. Cleanup runs in an `END` block, so an interrupted run leaves them behind.

**Do instead:** run the live-write suite only when the task is about live behavior —
and check the engine afterwards for leftovers the `END` block never got to remove.

An unset write flag does not make a live run read-only. `test_docker` drops its routes
in live mode (`api-docker-core`), so a subtest that passes routes and asserts on what
they captured sends its pull, build or create to the real engine (k116).

**The trap:** without `API_DOCKER_TEST_WRITE` the run looks safe, and an earlier subtest
dying first can hide the next unguarded one until it stops dying.

**Do instead:** every new subtest that passes routes to `test_docker` and asserts on
what they captured opens with
`plan skip_all => 'route assertions are fixture-only' if is_live();`. After any live
run, read the engine's `/events` over the socket for the run's window.

## `prune` destroys, and `dangling => 0` destroys MORE, not less

`POST /images/prune` with `filters => { dangling => ['false'] }` removes every unused
*tagged* image on the engine — locally built ones included — and they are not
recoverable.

**The trap:** the filter reads like a narrowing ("only the untagged ones") and is the
opposite. This has already cost a locally built image, during what its caller believed
was a read-only probe.

**No `prune` of any kind — images, containers, networks, volumes, build cache — and no
`rm -a` or `system reset`, on either engine, ever, unless the user names the command.**
Probing what an endpoint answers is not a reason: measure it against something you
created yourself.

## `images->push` publishes

With credentials it writes to a real registry under the maintainer's account. Never run
it — nor any test that does — without explicit instruction.

## Streaming endpoints block until the daemon closes

`_request` still buffers a whole response by default, so `system->events` or
`containers->stats` without a bound and without `on_event`/`on_frame`/`on_chunk` never
returns.

**Do instead:** bound the window, pass a callback to consume the response as it arrives,
or wrap a manual probe in `timeout`.
A callback still needs `$stop->()` called from somewhere, or it runs until the daemon
closes the connection on its own.

## `[@Author::GETTY]` gathers through `Git::GatherDir` — tracked files only

A new `.pm`, test file or fixture is invisible to `dzil build`/`dzil test` until it is
`git add`-ed — while `prove -lr t/` stays green the whole time, because it reads `lib/`
and `t/` directly rather than through the gathered file list.

**The trap:** a `dzil build` failure that looks like a missing module, or a passing
`prove` next to a failing `dzil test`, is this before anything else.

**Do instead:** check `git status` for an untracked file first.

## The fixtures are real captures, and arranging them was not trivial

All eight files in `t/fixtures/*.json` are captures from a real daemon — that was not
true until karr k101 and its follow-up. The header of `t/type_fixture_passthrough.t`
names the engine and the API version each one was taken on, including
`containers_list.json`, `container_inspect.json` and `volumes_list.json`: those came
from a disposable container and a disposable volume, created and removed for the
purpose, because an earlier recapture pass found neither engine reachable from the
machine that held the fixtures to read.

**The trap:** a hand-rolled fixture passes the suite and proves nothing about the
daemon. Engine drift shows up only in a real capture.

**Do instead:** read the fixture header before trusting a fixture, and recapture on the
engine instead of editing the JSON by hand.

## The consumer repo makes a signature change cross-repo

`../p5-dist-zilla-plugin-docker-api` consumes this API. A public signature or
return-shape change is a cross-repo change: verify that repo, or file a ticket on its
board before landing.

## Parallel agents share one working tree

Subagents share one working tree with the orchestrator and with each other. A global
git command in one reaches all of them.

- **A subagent never mutates git** — no `stash`, `reset`, `checkout -- <path>`, `clean`,
  `add` or `commit`. The orchestrator owns git and commits. Say so in every subagent
  prompt, but do not rely on the prompt alone: a subagent's `git stash`/`reset`/`checkout`
  has thrown away another agent's uncommitted work three times (k111) even when the
  prompt forbade it.
- **When two or more code-touching agents run at once, isolate them.** Launch each with
  `isolation: "worktree"` so a stray git command in one cannot reach another's tree, or
  run them sequentially in the shared tree. Never fan out parallel code-touching agents
  into the same working tree without isolation.
- **A worktree may branch from a stale base.** Integrate its result by the diff
  (`git diff <merge-base> <branch> -- <files>` piped to `git apply`, or a cherry-pick),
  never by `git checkout <branch> -- <file>` for a file the main tree has since changed —
  that reverts the main tree to the stale copy. Check the merge-base against what main
  touched first.
- **Commit a verified-green checkpoint before the next mutating fan-out.** A committed
  HEAD is immune to a later stray `stash`/`reset`; uncommitted work is not.

## The two workers split by question, not by file

"What does the engine answer here?" is the engine-worker's. "How is this distribution
built?" is the plain worker's. Only the engine-worker carries the Engine API reference —
the other one guessing at daemon behavior is how a wrong assumption gets cemented.

## Where a change reaches further than it looks

`Role::HTTP` is the single seam every resource API and entity class hangs off. A change
to `_request`'s options, return shape or error handling reaches every module in `lib/`
and the mock harness at once.

A test that can't fail when the logic changes is wrong — and a helper that normalises
its input before asserting is that test. Reproduce a bug before fixing it; leave the
regression behind.

In this distribution a skip is the default failure mode: "tests pass" is wrong if any
were skipped.

## What a release actually does

The release plugin bumps `$VERSION` across all of `lib/` and tags on release. That is why a
release is the maintainer's go-ahead and never the next step you may take yourself.

## Where the rest of the conventions live

Do not restate them here or in the rules file:

- module loading, `$VERSION`, cpanfile pinning, house style — `getty-perl-core`,
  `getty-perl-moo`
- `[@Author::GETTY]`, POD weaving, `{{$NEXT}}` — `getty-perl-release-author-getty`
- dist.ini mechanics — `perl-release-dist-ini`
- commit messages — `getty-git-commit-style`
- architecture and transport invariants — `api-docker-core`
- what the daemon itself does (wire formats, response shapes, filters, registry auth) —
  `docker-engine-api` (briefed only into the engine-worker, the test-writer and the
  type-writer)
