# CLAUDE.md

Repo-specific guidance for Claude Code working on `API::Docker`.

## The 12 Rules

These are the operating rules for this repo. They inherit from the global
and workspace `CLAUDE.md` — what's listed here is the authoritative set
for this distribution.

1. **Use `mcp__serper__google_search` or `mcp__firecrawl__firecrawl_search`**
   over `WebSearch` for any web lookup.

2. **Use `mcp__firecrawl__firecrawl_scrape`** over `WebFetch` for fetching
   page content.

3. **Use `context7` for library docs** (CPAN, npm, etc.) — *except* this
   distribution itself. For `API::Docker` always read the local source
   under `lib/`, never context7.

4. **Untracked files that are not in `.gitignore` belong in the commit.**
   `.gitignore` is the source of truth. Only obvious secrets
   (`.env`, credentials) are excluded — and even then warn, don't silently
   drop them.

5. **Auto-Memory is for personal/user preferences only.** Project
   conventions belong in this `CLAUDE.md` or in a skill, never in
   auto-memory.

6. **Load the `getty-perl-core` skill before editing any Perl** in this
   workspace. It encodes Getty's house rules; the rules below are the
   TL;DR. The `api-docker-*` agents get it force-loaded — see
   [Delegation](#delegation).

7. **`use Module;` to load modules.** Only use `require` when there's a
   real runtime reason (lazy plugin loading, optional deps), not just to
   defer cost.

8. **`->instance` for `MooX::Singleton` / `MooseX::Singleton` classes.**
   `->new` for everything else.

9. **Never copy `$VERSION` from a Getty-authored repo into a cpanfile.**
   The repo version is the *next* unreleased version. Check
   `cpanm --info` for the actual released version when pinning.

10. **Pin every Getty-authored dependency** to its latest released CPAN
    version in `cpanfile`.

11. **The version in `lib/API/Docker.pm` is the NEXT release.** What's
    currently on CPAN is the previous tag. `dzil release` bumps the
    version automatically — never bump it by hand before a release. The
    same literal is repeated in every `lib/**/*.pm` file and must
    stay in sync -- 45 of them as of 0.004, and the generated
    `API::Docker::Type::*` classes make that number move. Count them, do
    not trust a number written down here.

12. **`{{$NEXT}}` in `Changes` is the placeholder for the upcoming
    release.** Add entries under it as you change behavior; `dzil
    release` replaces it with the version + timestamp.

## What this distribution is

A pure-Perl client for the Docker Engine API. No LWP, no shell-outs —
HTTP/1.1 (incl. chunked) is spoken directly over the daemon's Unix
socket (default) or a TCP endpoint. Any engine serving that API works;
Podman needs nothing but `DOCKER_HOST`.

The synchronous `_request` core lives in
`API::Docker::Role::HTTP`; resource-specific API methods live in
`API::Docker::API::*`. Entities hang off the resource APIs: every resource
returns generated `API::Docker::Type::*` classes with an
`API::Docker::Role::Entity::*` composed onto them (karr k79 step 6/7,
finished in k84). There are no hand-written entity wrapper classes left.

Architecture, transport invariants, the streaming and `X-Registry-Auth`
details, and the mock harness are in skill `api-docker-core` — that is
the source of truth, not this file.

## Layout

```
lib/API/Docker.pm                       # main client, version negotiation
lib/API/Docker/Role/HTTP.pm             # HTTP/1.1 transport (unix:// + tcp://, TLS)
lib/API/Docker/Role/RegistryAuth.pm     # X-Registry-Auth / AuthConfig encoding
lib/API/Docker/Role/Filters.pm          # the `filters` query parameter, shape-normalised
lib/API/Docker/Role/Using.pm            # `using`, the resource class clone that bounds a run of calls
lib/API/Docker/API/System.pm            # /version, /info, /_ping, /auth, /events
lib/API/Docker/API/Containers.pm        # container endpoints (incl. archive, attach)
lib/API/Docker/API/Images.pm            # image endpoints (build, pull, push, tar, commit, ...)
lib/API/Docker/API/Networks.pm          # network endpoints
lib/API/Docker/API/Volumes.pm           # volume endpoints
lib/API/Docker/API/Exec.pm              # exec endpoints
lib/API/Docker/API/Distribution.pm      # /distribution registry manifest lookups
lib/API/Docker/API/Secrets.pm           # /secrets
lib/API/Docker/API/Configs.pm           # /configs
lib/API/Docker/API/Plugins.pm           # /plugins
lib/API/Docker/Type.pm                  # the DSL and attribute registry behind the generated types
lib/API/Docker/Role/Type.pm             # a generated type's own behaviour: serialisation, unknown_fields
lib/API/Docker/Type/                    # generated from spec/, one class per swagger definition -- karr k79
lib/API/Docker/Role/Entity.pm           # the client an entity delegates through
lib/API/Docker/Role/Entity/Container.pm # container operations, composed onto ContainerSummary + ContainerInspectResponse
lib/API/Docker/Role/Entity/Image.pm     # image operations, composed onto ImageSummary + ImageInspect
lib/API/Docker/Role/Entity/Network.pm   # network operations, composed onto Type::Network (one class for list and inspect)
lib/API/Docker/Role/Entity/Volume.pm    # volume operations, composed onto Type::Volume (list, inspect and create)
lib/API/Docker/Role/Entity/Plugin.pm    # plugin operations, composed onto Type::Plugin
lib/API/Docker/Role/Entity/Secret.pm    # secret operations, composed onto Type::Secret
lib/API/Docker/Role/Entity/Config.pm    # config operations, composed onto Type::Config
lib/API/Docker/Error/HTTP.pm            # croaked on a status of 400 or above
lib/API/Docker/Error/Stream.pm          # croaked on a failed build/pull/push stream
lib/API/Docker/Error/Timeout.pm         # croaked when a read_timeout or connect_timeout runs out
lib/API/Docker/Error/Truncated.pm       # croaked when the daemon closed before its announced response was complete
maint/spec-to-type.pl                   # generates lib/API/Docker/Type/*.pm from spec/ -- never overwrites
maint/spec-drift-check.pl               # diffs spec/ against the registry, and spec against spec
maint/spec-common.pl                    # the spec loader shared by the two scripts above
maint/spec-to-type-names.yaml           # inline-class naming exceptions the generator and checker share
maint/spec-to-type-prose.yaml           # hand-written POD for fields/classes the swagger describes poorly
maint/spec-drift-exceptions.yaml        # deliberate deviations the drift checker accepts
maint/spec-overlay.yaml                 # named fields of v1.55 grafted onto the v1.51 base model
spec/v1.41.yaml .. v1.55.yaml           # Docker's own swagger, checked in; generation runs against v1.51 plus the overlay
t/                                      # tests (prove -lr t/)
t/lib/Test/API/Docker/Mock.pm           # fixture-driven mock helper
t/fixtures/*.json                       # captured daemon responses
.claude/agents/                         # the api-docker-* subagents
.claude/rules/api-docker-rules.md       # house rules, auto-loaded every turn
.claude/skills/                         # briefed skills (owned + skilletor-installed)
```

## Build and test

```bash
prove -lr t/            # canonical — recursive; plain `prove -l t/` skips subdirs
prove -lv t/images.t    # single test
dzil build              # build the dist
dzil test               # full suite incl. generated xt/
cpanm --installdeps .   # install deps from cpanfile
```

By default tests are fixture-driven — no daemon, no network, and it stays
that way. For the read-only live paths set `API_DOCKER_TEST_HOST`; add
`API_DOCKER_TEST_WRITE=1` for the mutating ones (they create and remove
real containers, images and volumes).

Which engine is available is a fact about the machine, not about this
file — establish it before every live run rather than assuming it:

```bash
# which sockets exist
ls -l /var/run/docker.sock "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock" 2>/dev/null
# what each one announces: Platform.Name, ApiVersion, MinAPIVersion
curl -s --unix-socket <socket> http://localhost/version
# then
API_DOCKER_TEST_HOST=unix://<socket> prove -lr t/
```

A missing socket makes the suite `skip_all`, so a live run pointed at a
socket that is not there reports success while testing nothing — read the
skip line, not just the exit code. Ask the engine what it announces rather
than reading a version off a path or off the `/v1.XX/` in a hand-written
URL. Run it and read the result. No file or test count belongs here: one was
written down twice and was wrong both times, because the suite grows with
every fixture and every generated type.

`t/system.t`'s `events` subtest used to assert a shape a real daemon does not
return for an empty window; the live
branch was made tolerant of it in `1ad2c28`, and the underlying cause is now
fixed too — `_request` returns `[]` rather than `undef` for a zero-byte
`ndjson` body.

## Delegation

Don't touch behavior-relevant code yourself — hand it to the right agent.
The delegation lock and the publish gate are shared house rules (skilletor
bundle `getty-cpan-dist@getty`); the lanes and the repo's hazards are in
`.claude/rules/api-docker-rules.md`.

| Task | Agent |
|---|---|
| What the daemon does or expects — endpoints, wire formats, filters, registry auth | `api-docker-engine-worker` |
| The Perl side — Moo, transport internals, entities, refactoring, cpanfile | `api-docker-worker` (default) |
| Write/extend tests, add fixtures | `api-docker-test-writer` |
| The generated type model — `API::Docker::Type::*`, the DSL, the drift checker, `spec/` | `api-docker-type-writer` |
| Commits, `Changes`, card → done, pre-release audit | `api-docker-release-manager` |
| POD and README | `api-docker-doc-writer` |

The two workers split by question, not by file. Only `api-docker-engine-worker`
is briefed with `docker-engine-api`, the shared Engine API reference.

`api-docker-type-writer` is briefed with `api-docker-type-model`, which carries the
pattern for the generated classes; see karr k79.

The agents carry their skills via `briefing.skills` (see `.claude/agents/`);
the main agent delegates rather than loading them. Skill sources live under
`.claude/skills/` — `api-docker-core`, `api-docker-hazards` and `api-docker-type-model`
are owned here, the rest are installed by skilletor from `.claude/skilletor.json`
(`docker-engine-api` lives in the shared library and is reused by
`../p5-dist-zilla-plugin-docker-api`).

Ticket coordination runs on the repo's `karr` board (`karr board`).

## When changing behavior

- Add a `Changes` entry under `{{$NEXT}}`, and say what was measured.
- Update the POD on the affected class. POD lives next to the code
  (`=method`, `=attr`, `=head1 SYNOPSIS` ...) and is woven by the
  `@Author::GETTY` bundle.
- If you change a public method signature or a return shape, check that
  callers in the workspace (notably `../p5-dist-zilla-plugin-docker-api`)
  still build and test green.
