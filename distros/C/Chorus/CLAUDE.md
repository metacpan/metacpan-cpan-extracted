# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and test

```sh
perl Makefile.PL          # generate Makefile (once, or after Makefile.PL changes)
make                      # build
make test                 # run full test suite
prove -lv t/10-Frame-get.t  # run a single test file
```

Install from source:
```sh
perl Makefile.PL && make && make test && make install

```

## Paths

| Alias | Path |
|---|---|
| `$ENGINE` | `.` — repository root |
| `$SKILLS` | `./agent/skills/` — versioned AI agent skills |
| `$SANDBOXES` | `../sandboxes/` — user sandbox working area (not committed) |

## Language and conventions

- **Perl 5.006+**, classic style — no Moose/Moo, `use strict; use warnings;`
- **Commits:** conventional format (`type: message`) — no `eca.dev` footer, no `Co-Authored-By`
- **YAML rules — default language: English** (`RULE`, `FIND`, `ACTION`, `PREMISES`). Use French (`REGLE`, `CHERCHER`, `EFFET`, `PREMISSES`) only when the corpus processed by `chorus-feed` is in French. Sub-keys `attribut` and `filtre` are invariant (no English alias in the engine).
- **Tests:** `Test::More`, suite in `t/`

## Architecture

The library implements a classic **recognize–act** expert-system inference cycle (CLIPS / OPS5 lineage) in pure Perl.

### Three core modules

**`Chorus::Frame`** (`lib/Chorus/Frame.pm`) — knowledge representation.
- Every frame is a blessed hash. Slots hold domain data, procedural attachments (`sub {}`), or sub-frames.
- The global variable `$SELF` (exported) holds the frame currently executing a `get()` call — use it inside procedural slots and YAML `ACTION` bodies.
- `fmatch(slot => 'name')` performs O(1) slot-based lookup via an internal `%REPOSITORY` registry. **Critical:** always use `$f->set('slot', $val)` and `$f->delete('slot')` — direct hash assignment (`$f->{slot} = $val`) bypasses the registry and makes the slot invisible to `fmatch`.
- Inheritance via `_ISA` (single frame or arrayref); two resolution modes: **N** (default, breadth-first per valuation key) and **Z** (depth-first per frame). Switch with `Chorus::Frame::setMode(GET => 'Z')`.
- `Chorus::Frame::_reset()` clears all global registries — call between test cases for isolation.

**`Chorus::Engine`** (`lib/Chorus/Engine.pm`) — inference loop.
- An engine instance is itself a `Chorus::Frame` that inherits from an internal `$ENGINE` prototype.
- Rules are added with `addrule(_SCOPE => {...}, _APPLY => sub {...})`. `_SCOPE` values are closures that return arrayrefs of candidate frames; the engine generates their cartesian product and calls `_APPLY` for each combination.
- `loop()` repeats `applyrules()` until no rule fires, `BOARD->{SOLVED/FAILED}` is set, or `_MAX_CYCLES` (default 10,000) is reached.
- YAML rules are loaded from a directory with `loadRules($dir)` (alphabetical order — prefix files `R01-`, `R02-` to control order). YAML compiles to `addrule()` calls via `codeRule()`.
- Flow controls inside `_APPLY` or YAML `ACTION` (always use `$SELF`, never `$agent` in YAML): `cut`, `last`, `replay`, `replay_all`, `solved`, `failed`.

**`Chorus::Expert`** (`lib/Chorus/Expert.pm`) — multi-agent orchestration.
- Chains multiple engines over a shared `BOARD` frame.
- `register($agent1, $agent2, ...)` wires all agents to the same BOARD; `process($input)` runs the outer do/until loop.
- BOARD slots: `SOLVED`, `FAILED`, `INPUT`. Agents communicate via custom BOARD slots.
- `_LOCK_UNTIL_STABLE` on an agent skips it while any earlier agent is still making changes.
- `new()` ignores arguments — set `_MAX_ITER` by direct assignment after construction: `$xprt->{_MAX_ITER} = 50_000`.

### Supporting modules (under `lib/Chorus/Collection/`)

- **`Collection::List`** — ordered frame sequences with bidirectional `prev`/`succ` chaining, merge, and positional tests (`HAS`, `STARTS_WITH`, `ENDS_WITH`).
- **`Collection::Filter`** — regex-like pattern matching over sequences. Call `set_node_test()` before `check()`; capture groups land in `@_VFILTER` immediately after `check()`.

### AI agent skill pipeline

The `agent/skills/` directory holds versioned AI agent skills for AI-assisted development:

| Skill | Purpose |
|---|---|
| `chorus-engine.md` | Full engine reference — load for direct Perl work |
| `chorus-engine-yaml.md` | YAML authoring reference — load when writing rules |
| `chorus-engine-infra.md` | Perl infrastructure generation (Feed, Agent, Expert, run.pl) |
| `chorus-feed.md` | Enrich sandbox KB from a corpus |
| `chorus-check.md` | Generate pipeline + run compliance report |
| `chorus-create-project.md` | Create JSON project files from KB |
| `chorus-strengthen.md` | Classify rule/Feed gaps, produce enrichment roadmap |
| `chorus-import-project.md` | Align project document terminology with KB slots |
| `chorus-pdf.md` | Extract PDFs to enriched corpus |

## `agent/` commit rules

- `agent/skills/` and `agent/org/` **must** be committed (versioned).
- `agent/sessions/` **must never** be committed.
- Never run `git add agent/` in bulk — always `git add agent/skills/` and `git add agent/org/` explicitly.
- `git add -A` and `git add .` are forbidden without prior verification of staged content.

## Key YAML authoring pitfalls

- The last instruction of `ACTION`/`EFFET` **must** return a truthy value; a conditional `if` without an `else` that returns `1` unconditionally causes an infinite loop until `_MAX_CYCLES`.
- Always add `EXCEPTION: defined $var->{slot_set}` for idempotence — without it a rule re-fires on every cycle.
- Perl helper functions used inside YAML rules must be injected into `Chorus::Engine` via typeglob before `loadRules()`:
  ```perl
  { no strict 'refs'; *{'Chorus::Engine::my_helper'} = \&my_helper; }
  $agent->loadRules("$base/rules/my-agent");
  ```
