# Chorus Engine — Technical Reference

> The [README](../../README.md) describes the pipeline and the LLM/engine division of labour.
> This guide goes into the mechanics: YAML rule structure, engine behaviour, Perl API reference.
> It is aimed at the domain expert who reads, corrects, and extends the pipeline generated
> by the AI agent.
>
> The Perl engine is the foundation — frames, slots, YAML rules, inference chain.
> An AI agent plugs into it to read the normative corpus and generate the rules.
> The engine then runs without an LLM — deterministic, reproducible.

---

## Inference cycle

### Level 1 — Agent chain

```
Expert.process()  ─  repeats until SOLVED | FAILED
│
▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Agent A   │ ──► │   Agent B   │ ──► │   Agent C   │
│  [R1 R2 R3] │     │  [R1 R2]    │     │  [R1]       │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
    loop()              loop()              loop()
   fixpoint             fixpoint            fixpoint
       │
       │◄── replay() : restarts loop() from R1 (this agent)
       │
◄──────┴─────────────────────────────────────────────────
replay_all() : restarts from Agent A
```

### Level 2 — Fixpoint loop (one agent)

```
loop()  ─  repeats as long as at least one rule fired in the last pass

┌─ Rule R1 ─────────────────────────────────────────────────────────┐
│  FIND resolves frame combinations                                 │
│                                                                   │
│  For each combination:                                            │
│    _APPLY() → 0  (inactive)  ──► next combination                 │
│    _APPLY() → 1  (active)                                         │
│               │                                                   │
│               ├── cut()     ──► stop combis → next rule           │
│               └── TERMINAL  ──► solved() or failed()              │
└───────────────────────────────────────────────────────────────────┘
┌─ Rule R2 ─────────────────────────────────────────────────────────┐
│    last() ─────────────────────────────────────────────────────── ──► Agent B
└───────────────────────────────────────────────────────────────────┘
┌─ Rule R3 ─────────────────────────────────────────────────────────┐
│  ...                                                              │
└───────────────────────────────────────────────────────────────────┘

Quiescence: no rule fired ──► end loop() → next agent
```

**Flow controls available inside `ACTION`:**

| Mechanism | Scope | Effect |
|---|---|---|
| `$SELF->cut()` | combinations | stop scope → next rule |
| `$SELF->last()` | agent's rules | stop loop() → next agent |
| `$SELF->replay()` | current agent | restart loop() from R1 |
| `$SELF->replay_all()` | full chain | restart from Agent A |
| `$SELF->solved()` | global | `BOARD.SOLVED` → stops Expert |
| `$SELF->failed()` | global | `BOARD.FAILED` → stops Expert |
| `TERMINAL: solved\|failed` | YAML shortcut | triggers solved()/failed() if `_APPLY` returns 1 |

---

## Usage levels

Three independent usage levels — pure Perl, YAML rules, AI agent pipeline. Each is a valid entry point.

| Level | What you use | Prerequisites | Who it is for |
|---|---|---|---|
| **1 — Pure Perl** | `addrule()`, `loop()` in Perl | Perl 5 | Discovery, prototyping, small projects |
| **2 — YAML** | YAML DSL rules, `loadRules()` | Perl 5 | Maintainable projects, rich business logic |
| **3 — AI agent** | Pipeline generated from a corpus | Perl 5 + AI agent | Normative domains, large corpora |

Levels 1 and 2 are **100 % self-contained**: pure Perl, no external dependency.
Level 3 adds an AI agent as a *development* tool only — a pipeline generated at
level 3 runs exactly like one written by hand at level 1, without an AI agent or
network.

> **Starting point:** `sandboxes/demo_en` is fully functional without an AI agent:
> `perl sandboxes/demo_en/run.pl sandboxes/demo_en/project-01.json`

---

## YAML DSL — Rule reference

For projects with many rules, the YAML DSL externalises business logic without
repetitive Perl code.

### Structure of a rule

```yaml
RULE: rule-name                  # unique identifier (_ID internally)
PREMISES:                        # slots required on the candidate frame (fast pre-filter)
  - required_slot
FIND:                            # bindings: name → selection criteria
  var:
    attribut: slot_name          # the frame must have this slot
    filtre:   '$_->{slot} > 0'  # Perl expression evaluated on the candidate frame
CONDITION: |                     # global condition (all bindings resolved)
  $var->{slot} > threshold
EXCEPTION: |                     # short-circuit: do not fire if true
  defined $var->{result}
ACTION: |                        # rule body — must return 1 if active
  $var->set('result', compute($var->{slot}));
  1
TERMINAL: solved                 # terminate the pipeline
```

**Key aliases** — `RULE` / `FIND` / `ACTION` / `PREMISES` are the preferred English
forms; `REGLE` / `CHERCHER` / `EFFET` / `PREMISSES` are accepted aliases for
French-language corpora. Sub-keys `attribut` and `filtre` are invariant (no English alias).

### The `TERMINAL` field — v2.0

`TERMINAL` replaces the Perl code that called `solved()` or `failed()` from
`_APPLY`. It is declared directly in the YAML rule, without any glue code:

```yaml
RULE: all-checked
FIND:
  obj:
    attribut: status
CONDITION: |
  $obj->{status} eq 'ok'
TERMINAL: solved
```

Accepted values: `solved` · `failed`.

When the rule fires and `TERMINAL` is present, the engine calls `solved()` or
`failed()` and exits the loop immediately.

### Loading rules

```perl
$agent->loadRules('rules/my-agent/');       # all *.yml files in the directory
$agent->loadRules('rules/R01-my-rule.yml'); # single file
```

### Context variables in `ACTION`

Variables bound by `FIND` are directly accessible by name in the `ACTION` block.
`$SELF` refers to the engine (`Chorus::Engine`) — not a frame — and gives access to the shared board via `$SELF->BOARD`:

```yaml
ACTION: |
  my $val = $source->{measure} * $target->{factor};
  $target->set('corrected_value', $val);
  1
```

---

### `_MAX_CYCLES` — infinite loop guard

`loop()` stops after `_MAX_CYCLES` cycles (default: 10 000) and emits a warning.
Each instance has its own limit, independent of other agents in the same
`Chorus::Expert`.

Recommended sizing: `N_frames × N_rules × N_agents × 10`. The KB generated by
`chorus-feed` documents the target value in each agent's org file.

---

## Chorus::Frame

| Concept | Description |
|---|---|
| `Chorus::Frame->new(%slots)` | Creates a frame; `_ISA => $parent` activates inheritance |
| `$f->set('slot', $val)` / `$f->delete('slot')` | Indexed mutation — **never** use `$f->{slot} = …` directly (bypasses the `fmatch` index) |
| `fmatch(slot => 'name')` | Returns all frames with that slot; filter with `grep` |

> `perldoc Chorus::Frame` — procedural slots, inheritance, N/Z modes, demons, `fselect`, `complete()`, `_TERMINAL_SLOTS`, `_ALTERNATIVES`

---

## Chorus::Engine

| Concept | Description |
|---|---|
| `Chorus::Engine->new(_IDENT => …, _MAX_CYCLES => N)` | Creates an agent; `_IDENT` for logs |
| `$agent->addrule(_SCOPE => …, _APPLY => sub {})` | Adds a Perl rule |
| `$agent->loadRules('rules/my-agent/')` | Loads YAML rules from a directory or single file |
| `$agent->loop()` | Runs the fixpoint loop (standalone, without Expert) |

> `perldoc Chorus::Engine` — rules, inference loop, YAML DSL, flow control

---

## Chorus::Expert

| Concept | Description |
|---|---|
| `Chorus::Expert->new(_MAX_ITER => N)` | Creates the orchestrator; `_MAX_ITER` limits passes over the chain |
| `$xprt->register($a, $b, …)` | Registers agents in execution order |
| `$xprt->process($data)` | Runs the full cycle → `1` (solved) or `undef` (failed / timeout) |
| `$xprt->BOARD->set/get('key', …)` | Shared board accessible to all agents |

> `perldoc Chorus::Expert` — multi-agent orchestration, shared BOARD, `_LOCK_UNTIL_STABLE`

---

## Further reading

- [`02-ai-agent.md`](02-ai-agent.md) — LLM vs Chorus positioning, daemon architecture, full pipeline
- [`03-applications.md`](03-applications.md) — application domains, onboarding by sector
- [`04-chorus-commands.md`](04-chorus-commands.md) — full `chorus-*` command reference
- `perldoc Chorus::Engine` — rules, inference loop, YAML DSL, flow control
- `perldoc Chorus::Frame` — slots, inheritance, N/Z modes, demons (`_NEEDED`/`_AFTER`/`_ON_DELETE`), `fmatch`, `fselect`, `complete()`, `_TERMINAL_SLOTS`, `_ALTERNATIVES`
- `perldoc Chorus::Expert` — multi-agent orchestration, shared BOARD
- `perldoc Chorus::Collection::List` — ordered frame sequences
- `perldoc Chorus::Collection::Filter` — pattern matching on sequences
