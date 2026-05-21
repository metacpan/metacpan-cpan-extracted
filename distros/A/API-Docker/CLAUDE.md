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

6. **Load the `perl-core` skill before editing any Perl** in this
   workspace. It encodes Getty's house rules; the rules below are the
   TL;DR.

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
    version automatically — never bump it by hand before a release.

12. **`{{$NEXT}}` in `Changes` is the placeholder for the upcoming
    release.** Add entries under it as you change behavior; `dzil
    release` replaces it with the version + timestamp.

## What this distribution is

A pure-Perl client for the Docker Engine API. No LWP, no shell-outs —
HTTP/1.1 (incl. chunked) is spoken directly over the daemon's Unix
socket (default) or a TCP endpoint.

The synchronous `_request` core lives in
`API::Docker::Role::HTTP`; resource-specific API methods live in
`API::Docker::API::*`. Entity wrappers (`API::Docker::Container`,
`API::Docker::Image`, ...) hang off the resource APIs.

## Layout

```
lib/API/Docker.pm                       # main client, version negotiation
lib/API/Docker/Role/HTTP.pm             # HTTP/1.1 transport (unix:// + tcp://)
lib/API/Docker/API/System.pm            # /version, /info, /_ping
lib/API/Docker/API/Containers.pm        # container endpoints
lib/API/Docker/API/Images.pm            # image endpoints (build, pull, push, ...)
lib/API/Docker/API/Networks.pm          # network endpoints
lib/API/Docker/API/Volumes.pm           # volume endpoints
lib/API/Docker/API/Exec.pm              # exec endpoints
lib/API/Docker/{Container,Image,Network,Volume}.pm  # entity classes
t/                                      # tests (prove -l t/)
t/lib/Test/API/Docker/Mock.pm           # fixture-driven mock helper
t/fixtures/*.json                       # captured daemon responses
```

## Build and test

```bash
dzil build              # build the dist
dzil test               # full test suite
prove -lv t/images.t    # single test
cpanm --installdeps .   # install deps from cpanfile
```

By default tests are fixture-driven (no Docker daemon needed). Set
`API_DOCKER_TEST_HOST=unix:///var/run/docker.sock` to also exercise the
read-only live paths; add `API_DOCKER_TEST_WRITE=1` to enable mutating
tests (create/remove containers, etc.).

## API conventions

- **Resource accessors live under the client:** `$docker->images`,
  `$docker->containers`, etc. Each returns a `*::API::*` instance.
- **List/inspect endpoints return entity objects** (e.g.
  `$docker->images->list` returns `[API::Docker::Image, ...]`); raw
  endpoints (e.g. `tag`, `push`) return the raw daemon response.
- **`$docker->_request($method, $path, %opts)`** is the single transport
  entry point. Opts: `body` (auto-JSON-encoded), `raw_body` +
  `content_type` (e.g. tarballs), `params` (query string),
  `headers` (extra HTTP headers — used by push for `X-Registry-Auth`).
- **`/build`, `/images/create`, `/images/.../push`** are streaming
  endpoints. `_request` parses newline-delimited JSON and returns an
  arrayref of events; callers iterate and look for `errorDetail`,
  `progress`, `aux`, etc.
- **`X-Registry-Auth` is required on every push** by the Docker Engine —
  even anonymous attempts. `images->push` always sends the header; pass
  `auth => { username, password, serveraddress, identitytoken }` to
  authenticate, omit it for the empty-`{}` form.

## Testing notes

- New tests should use the `Test::API::Docker::Mock` helper. Pass a
  `'METHOD /path' => $fixture_or_coderef` route table; the helper
  monkey-patches `_request` to dispatch against it.
- Don't add network-dependent assertions to default test runs. Gate them
  on `is_live()` / `can_write()` from the mock helper.
- Fixtures live in `t/fixtures/*.json`. Capture them from a real daemon
  rather than hand-rolling — keeps drift detectable.

## When changing behavior

- Add a `Changes` entry under `{{$NEXT}}`.
- Update the POD on the affected class. POD lives next to the code
  (`=method`, `=attr`, `=head1 SYNOPSIS` ...) and is woven by the
  `@Author::GETTY` bundle.
- If you change a public method signature, check that callers in the
  workspace (notably `../p5-dist-zilla-plugin-docker-api`) still build
  and test green.
