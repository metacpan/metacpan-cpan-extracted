# CLAUDE.md

Guidance for Claude Code in this repository. `Alien::TinyCDB` is an `Alien::Base` wrapper
that provides Michael Tokarev's **TinyCDB** (corpit.ru cdb) C library to Perl consumers —
either a system install or a build from upstream source — via `cflags`/`libs`/`dynamic_libs`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself — the
principle, the lane definition and this dist's hazards are in
`.claude/rules/alien-tinycdb-rules.md` (auto-loaded every turn).

| Task | Agent |
|---|---|
| Implement / refactor / debug the `alienfile`/`dist.ini` build config, `lib/Alien/TinyCDB.pm`, or `t/` | `alien-tinycdb-worker` (default) |
| Pre-release audit | `alien-tinycdb-release-checker` |

The agents carry their knowledge via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. The TinyCDB specifics — the `alienfile` build
recipe (the `Alien::Build` path, `alien_build=1`), share-vs-system probing, the shared
library built for FFI, that upstream is fetched not vendored, and the consumer contract —
live in skill `alien-tinycdb-core` under
`.claude/skills/`; the rest of the skills there are hardlinks from the shared library,
maintained via `manage-skills` in their home repos.

## Build / test

```bash
cpanm --installdeps .
dzil test            # full share build (download + make) + smoke test
prove -lv t/load.t
```

Coordination is a `karr` board in this repo (`karr board`). Never `dzil release` without
the maintainer's explicit go-ahead.
