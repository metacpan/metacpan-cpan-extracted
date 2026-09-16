# CLAUDE.md — BeePack

Primitive MsgPack-based key-value storage: a CDB (constant database) file whose values are
MsgPack-encoded, built to pack small key-values and large binary blobs into one compact
file that low-memory microcontrollers can read and update. One Moo class (`lib/BeePack.pm`)
plus the `bee` CLI (`bin/bee`). The CDB container is `CDB_File`, which carries its own
constant-database implementation — no system library needed.

Build and test: `dzil build`, `dzil test`, `dzil clean`. While iterating: `prove -lr t/`
(**`-r` is required** — plain `prove -l t/` is not recursive). Never `dzil release` without
explicit permission — the version in the tree is the *next* release, and `dzil release`
bumps and tags it.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself — the
principle, the lanes and this repo's hazards are in `.claude/rules/beepack-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug `lib/BeePack.pm` or `bin/bee` (incl. POD) | `beepack-worker` (default) |
| Write or extend tests in `t/` | `beepack-test-writer` |
| Pre-release audit | `beepack-release-checker` |

The agents carry their conventions via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/` —
`beepack-core` holds the distribution internals (CDB+MsgPack model, `nil_exists`, the
open/save modes); the `getty-perl-*` and `perl-release-dist-ini` skills carry the shared
Perl and `[@Author::GETTY]` conventions. Work is tracked on the local `karr` board.
