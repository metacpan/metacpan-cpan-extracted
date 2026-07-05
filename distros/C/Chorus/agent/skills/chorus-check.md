# Skill — chorus-check

> Trigger: `chorus-check <sandbox-name> <fichier-projet> [--all]`
> Agent: `architect`
>
> `<sandbox-name>`: sandbox containing the KB and YAML rules (produced by `chorus-feed`)
> `<fichier-projet>`: JSON file describing the project elements to validate,
>                      or data provided inline by the user
>                      (ignored when `--all` is present — all `projet-*.json` are used)
> `--all`: run all `projet-*.json` files found in `$SANDBOX/` and produce a synthesis report
>
> **Single responsibility: validate a project against the knowledge base.**
> The project file is **runtime input data** — it does not influence
> infrastructure generation. Two `chorus-check` runs on the same sandbox
> with different projects share exactly the same infrastructure.
>
> Prerequisite: `chorus-feed <sandbox-name>` must have been run beforehand
> (KB org + YAML present in the sandbox).

---

## 🔌 Preliminary — MCP mode detection

**Execute before Step 0, once per `chorus-check` invocation.**

Probe the MCP server by calling `chorus_engine_create` (ident: `"_probe"`):

- **Probe succeeds** → MCP mode active. Immediately call `chorus_reset` to
  discard the probe handle. Set `$MCP_AVAILABLE = true` for this run.
- **Probe fails / tool unavailable** → fallback mode. Set `$MCP_AVAILABLE = false`.

This probe is silent (no user message). The chosen mode is noted at the end
of Phase 6 in the report header.

> ⚠️ `$MCP_AVAILABLE` is a local decision variable for this skill run only.
> It does not affect Phases 0–5 (infrastructure generation) — those are
> identical in both modes.

---

## ⚡ Step 0 — Infrastructure detection (PRIORITY, before any loading)

**This is the first action to execute, without exception.**

Read the directory tree `$SANDBOX` (max_depth=3) and verify:

```
$SANDBOX/run.pl
$SANDBOX/lib/<Namespace>/Feed.pm
$SANDBOX/lib/<Namespace>/Expert.pm
$SANDBOX/lib/<Namespace>/Agent/<Nom>.pm  ← au moins un
```

### ✅ Infrastructure present → hash check

Compare the current KB hash against the stored one:

```bash
sha256sum $SANDBOX/agent/chorus/*.org > /tmp/kb-hash-current
```

- `$SANDBOX/agent/.kb-hash` **absent** → the infrastructure predates hash tracking
  → treat as stale → **FULL PATH** (forced regeneration)
- `$SANDBOX/agent/.kb-hash` **present**, content **identical** to current hash
  → **FAST PATH**: go directly to Phase 6 (single project) or Phase 6-all (`--all`).
  Do not load `chorus-engine.md`.
  Do not read `index.org`. Do not read agent KBs. Do not generate anything.
- `$SANDBOX/agent/.kb-hash` **present**, content **differs** → KB was enriched
  since last generation → **FULL PATH** (forced regeneration, no user prompt needed)

> **Manual forced regeneration**: the user explicitly asks to
> "regenerate" / "rebuild" the infrastructure → FULL PATH regardless of the hash.
> A second `chorus-check` with a different project is **never** a
> forced regeneration (hash comparison handles it automatically).

### ❌ Infrastructure absent or incomplete → FULL PATH

Load:
- `chorus-engine-infra.md` — Perl infrastructure reference (Core Mechanisms, Multi-Specialty Pattern, checklists)
- `chorus-templates.md` — Perl infrastructure templates (T1–T5)
- `$SANDBOX/agent/chorus/index.org` — pipeline, agents, namespace

> ⚠️ Do not read agent KBs (`<slug>.org`) or YAML files at this stage.
> They are only needed during generation (infrastructure absent).

Then execute Phases 0, 1–5, 6, 7 in order.

---

## Phase 0 — KB prerequisite check *(full path only)*

```
$SANDBOX/agent/chorus/index.org     ← must exist
$SANDBOX/agent/chorus/<slug>.org    ← at least one agent
$SANDBOX/rules/<slug>/            ← at least one YAML file per agent
```

If any of these is missing → stop and report:
`"KB incomplete — run chorus-feed <sandbox-name> <corpus> first."`

Extract from `index.org`:
- The Perl namespace of the project
- The ordered list of agents (pos, slug, Perl module)
- The termination agent (last)

---

## Phase 1 — Analyse the project file

### 1.1 Expected format

```json
{
  "projet": "<nom>",
  "elements": [
    {
      "id": "<identifiant unique>",
      "type": "<element type>",
      "<slot1>": <valeur1>,
      "<slot2>": <valeur2>
    }
  ]
}
```

If the project file is provided **inline** (data pasted in the message) →
write it to `$SANDBOX/projet.json` before continuing.

### 1.2 Deduce mandatory slots

For each element type present in the project file, cross-reference with the
`Catalogue des Frames` in the KBs to identify slots marked `obligatoire`.
These slots will drive the Feed validation.

### 1.3 Identify the targeting slot for agent 1

Read the `Slots de ciblage` section of the KB for the agent at position 1.
This slot must be present on all Frames created by the Feed.

---

## Phase 2 — Generate `Feed.pm`

Create `$SANDBOX/lib/<Namespace>/Feed.pm` from template **T1** (`chorus-templates.md`).

**Substitutions from the KBs:**
- `%SLOTS_REQUIS` ← `obligatoire` slots from the Catalogue des Frames of each KB
- agent 1 targeting slot comment ← `Slots de ciblage` section KB pos 1

---

## Phase 3 — Generate Agent modules

For each agent in the index, create `$SANDBOX/lib/<Namespace>/Agent/<Nom>.pm`
from template **T2** (`chorus-templates.md`).

This module is **pure infrastructure** — it contains no business logic.
Business logic lives in the YAML files (rules) and in `Helpers.pm` (produced by `chorus-feed`).

**Rule for the termination agent:**
If the KB indicates `TERMINAL: solved` in a YAML → no additional Perl code needed.
If termination requires a global test (e.g. verifying that ALL Frames have
their status set), two approaches are valid:

**Preferred — YAML EXCEPTION + TERMINAL pattern** (MCP-compatible):
```yaml
RULE: check-all-done
TERMINAL: solved
FIND:
  dummy:
    attribut: <targeting_slot>
EXCEPTION: |
  scalar(grep { !defined $_->{<result_slot>} }
         Chorus::Frame::fmatch(slot => '<targeting_slot>')) > 0
ACTION: "1"
```
The `EXCEPTION` fires a fmatch on every cycle but **does not bind** — the rule
is only triggered when no pending frame remains. No infinite loop risk.
`TERMINAL: solved` is handled directly by the Engine's `applyrules()` → reliable termination.
This form is loaded by `loadRules()` and therefore **works natively in MCP mode**.

> `TERMINAL: solved` and `$SELF->solved()` are both valid for termination.
> They can be combined (both in the same rule) or used independently.

> ⚠️ `FIND`/`CHERCHER` must use `attribut:` (not `slot:`) — `slot:` is not a
> recognized YAML DSL key and will silently drop the rule from the engine.

**Fallback — pure Perl `addrule()`** (use only if EXCEPTION pattern is not expressive enough):
Add a pure Perl rule via `addrule()` after `loadRules()`, using template **T3** (`chorus-templates.md`).
⚠️ `addrule()` rules are registered in `build()` — they are **invisible to MCP mode**
(bypass of `build()`), which will cause `chorus_process` to return `failed` even when
all frames are correctly processed.

> ⚠️ **`$SELF` (YAML EFFET) vs `$agent` (pure Perl addrule()):**
> | Context | Correct variable | Reason |
> |---|---|---|
> | YAML EFFET | **`$SELF`** | `$agent` is out of scope in the Engine eval → `Global symbol` crash |
> | `_APPLY` in `addrule()` | **`$agent` (closure)** | `$SELF` is the rule-Frame, not the Engine |
>
> - In a **`.yml` file** → always `$SELF->solved()`, `$SELF->cut()`, etc.
> - In a **pure Perl `addrule()`** → capture `$agent` as a closure, never `$SELF`.

---

## Phase 4 — Generate `Expert.pm`

Create `$SANDBOX/lib/<Namespace>/Expert.pm` from template **T4** (`chorus-templates.md`).

**Substitutions:** one `use` + one `->build()` per agent in `#+PIPELINE_POS` order.
Force `$xprt->{_MAX_ITER}` after `new()` (known bug: `new()` ignores its arguments).
Document BOARD inter-agent keys in `index.org` if agents communicate via BOARD slots.

---

## Phase 5 — Generate `run.pl`

Create `$SANDBOX/run.pl` from template **T5** (`chorus-templates.md`).

**Substitutions:**
- `<Namespace>` ← from `index.org`
- `@slots_resultat_display` ← result slots from the pipeline KB (statut_conformite, raison_non_conformite, motif_refus, besoin_*, etc.)
- `@pipeline_def` ← one entry per agent: `[ label, slot_ciblage, slot_resultat_ok ]` from `index.org` pipeline table

**Rule:** `run.pl` contains **no hardcoded data** — all project input comes from the JSON argument.

---

## Phase 5.5 — Record KB hash *(full path only, after Phases 1–5)*

Once all infrastructure files have been generated successfully, record the
current KB fingerprint so that the next `chorus-check` can detect staleness:

```bash
sha256sum $SANDBOX/agent/chorus/*.org > $SANDBOX/agent/.kb-hash
```

This file is **never committed** (local artefact, like `sessions/`).
It is invalidated (deleted) by `chorus-feed` at the end of each run.

---

## Phase 6 — Execution and report

### 6A — MCP mode (`$MCP_AVAILABLE = true`)

Orchestrate the pipeline directly via MCP tools — no `run.pl` invocation:

```
chorus_reset
chorus_engine_create (ident: "<Nom1>")  →  h1
chorus_engine_create (ident: "<Nom2>")  →  h2   (one per agent in pipeline order)

# ⚠️ Inject helpers BEFORE loadRules — one call per Helpers.pm, any order.
# Injection is global (process-wide): a function injected once is available
# to all engines of this run. Skip agents without a Helpers.pm.
chorus_engine_inject (helpers_module: "<Namespace>::Agent::<Nom1>::Helpers",
                      lib_paths: ["$SANDBOX/lib", "$ENGINE/lib"])
chorus_engine_inject (helpers_module: "<Namespace>::Agent::<Nom2>::Helpers",
                      lib_paths: ["$SANDBOX/lib", "$ENGINE/lib"])
# ... repeat for each agent that has a Helpers.pm

chorus_engine_loadrules (h1, "$SANDBOX/rules/<slug1>/")
chorus_engine_loadrules (h2, "$SANDBOX/rules/<slug2>/")
chorus_expert_create (engine_handles: [h1, h2])  →  hX
chorus_feed_load (namespace: "<Namespace>",
                  json_path:  "$SANDBOX/projet.json",
                  lib_paths:  ["$SANDBOX/lib", "$ENGINE/lib"])
chorus_board_set (hX, { INPUT: <project_data> })   ← if agents read BOARD->INPUT
chorus_process   (hX)                               →  "solved" | "failed"
```

After `chorus_process`, collect results:

```
chorus_frames_list (slot: "statut_conformite",
                    extra_slots: ["id", "type", "raison_non_conformite", ...])
chorus_board_get   (hX, <inter-agent slot>)   ← repeat for each BOARD slot of interest
chorus_reset                                  ← cleanup after collection
```

Build the compliance report from the collected frame data.
Apply the same report structure as Phase 6B (blocks 1–4 from T5).

> **Advantages over 6B:**
> - No `run.pl` required — infrastructure can be partially absent.
> - Frame introspection between agents (call `chorus_frames_list` after each
>   `chorus_process` step if agents are run individually).
> - Report built directly from MCP responses, without parsing stdout.
> - Helpers injected via `chorus_engine_inject` — same semantics as `build()`.

If `chorus_process` returns `failed`:

**Graceful-failed detection** — before falling through to 6B, inspect frames:
1. Call `chorus_frames_list` with `slot: <termination_targeting_slot>` and
   `extra_slots: ["id", "<result_slot>"]`.
2. If **all** frames have their result slot defined (no `undef`) →
   the pipeline completed correctly but the termination rule was not reached
   (typical cause: `addrule()` in `build()`, bypassed in MCP mode).
   → Build the report from MCP frame data directly. Do **not** fall through to 6B.
   → Note in the report header: `Mode: MCP ✅ (graceful-failed — termination via addrule bypassed)`
3. If one or more frames have `undef` result slots → genuine failure.
   → Call `chorus_reset` to clean up.
   → Report the failure clearly, then fall through to 6B as a safety net.

> ℹ️ To avoid graceful-failed in the future, prefer the YAML EXCEPTION pattern
> for termination (see Phase 3) — it is loaded by `loadRules()` and is fully
> MCP-compatible without requiring `build()`.

---

### 6B — Fallback mode (`$MCP_AVAILABLE = false`)

Run the pipeline via the generated `run.pl`:

```bash
perl $SANDBOX/run.pl $SANDBOX/projet.json
```

Capture the output. If Perl errors occur:
- `loadRules` error → check the YAML files (syntax, indentation)
- `Can't locate` error → check `use lib` and the namespace
- `FAILED/TIMEOUT` pipeline → check the termination rule

**Display the complete verbatim output** in a code block — always, without
summarizing or rephrasing in its place. This is the primary report output.

### 6.1 — Post-verbatim structured report (mandatory)

After the verbatim output, always produce the following structured report:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  chorus-check  <sandbox-name>  <fichier-projet>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Status       : SOLVED ✅ / FAILED ❌
  Éléments     : N total  (Bat:N  Voie:N  Fac:N  …)
  CONFORME     : N
  NON_CONFORME : N
  Unprocessed  : N
  Discordances : N / N_total
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Column definitions (identical to Phase 6-all):
- **CONFORME / NON_CONFORME**: count from the verbatim output
- **Unprocessed**: elements that produced no result slot at all (no `statut_conformite`,
  no `voie_acces_ok`, no `famille` — depending on type); targeting slot probably missing from Feed
- **Discordances**: elements whose actual result differs from the expected result implied
  by the ID naming convention (`-OK-` → expected CONFORME or OK, `-KO-` → expected NON_CONFORME or KO)
  or from `_resultats_attendus` in the JSON if present

If **Discordances > 0**, list them:

```
  Discordances :
    <id>  expected CONFORME   → got NON_CONFORME
    <id>  expected NON_CONF   → got CONFORME
    <id>  expected OK         → got KO
```

If **Unprocessed > 0**, list them:

```
  Unprocessed :
    <id>  (<type>) → targeting slot probably missing from Feed
```

### 6.2 — Convergence verdict

```
  CONVERGED ✅   — SOLVED, 0 discordances, 0 unprocessed
  NOT CONVERGED ❌ — N discordance(s) and/or N unprocessed
```

If **NOT CONVERGED** → recommend:
```
  Next step: chorus-strengthen <sandbox-name>
```

---

## Phase 6-all — `--all` mode (batch run)

> This phase is used **instead of Phase 6** when `--all` is present.
> Infrastructure detection (Step 0) is shared — the hash check runs once.
>
> **Orchestrator mode:** the current agent discovers project files and spawns
> one sub-agent per project file via `eca__spawn_agent`. Each sub-agent has its
> own IDE session and token — no timeout risk from extended thinking between runs
> or during output analysis.

### 6-all.1 Discover project files

```bash
ls $SANDBOX/projet-*.json
```

If no `projet-*.json` file is found → stop and report:
```
⛔ No projet-*.json file found in $SANDBOX/.
   Run chorus-create-project <sandbox-name> --batch first.
```

### 6-all.2 Spawn sub-agents

Spawn one sub-agent per discovered project file via `eca__spawn_agent`
(agent: `general`). Sub-agents can run in parallel if the IDE permits,
otherwise spawn sequentially.

Use this task template for each, substituting `<SANDBOX>` and `<FILE>`:

```
You are a chorus-check sub-agent. Your sole task: run ONE project file through
the pipeline and return a structured result block.

SANDBOX: <absolute path>
PROJECT FILE: <SANDBOX>/<FILE>

YOUR TASKS:
1. Run the pipeline:
      perl <SANDBOX>/run.pl <SANDBOX>/<FILE> 2>&1
   Capture the complete output.

2. Parse the output and extract:
   - STATUS  : "SOLVED" if "Pipeline : SOLVED ✅" appears in output, "FAILED" otherwise
   - CONFORME     : count of CONFORME elements
   - NON_CONFORME : count of NON_CONFORME elements
   - UNPROCESSED  : count of elements tagged "(unprocessed)" in output
   - DISCORDANCES : elements whose actual result differs from the expected result
       • id contains "-OK-" or "-ok-" → expected CONFORME
       • id contains "-KO-" or "-ko-" → expected NON_CONFORME
       Also check "_resultats_attendus" in the JSON if present.

3. Return EXACTLY this block (no other text before or after):
   FILE: <FILE>
   STATUS: SOLVED|FAILED
   CONFORME: N
   NON_CONFORME: N
   UNPROCESSED: N
   DISCORDANCES: N
   DISC_DETAIL:
     <id>  expected CONFORME  → got NON_CONFORME
     <id>  expected NON_CONF  → got CONFORME
   UNPROC_DETAIL:
     <id>  (<type>) → targeting slot probably missing from Feed
   (omit DISC_DETAIL lines if DISCORDANCES=0; omit UNPROC_DETAIL lines if UNPROCESSED=0)
```

### 6-all.3 Collect results and produce synthesis table

After all sub-agents complete, assemble the synthesis table from the
returned structured blocks:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  chorus-check --all  <sandbox-name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Project file         │ Status      │ CONFORME │ NON_CONF │ Unproc │ Disc
  ─────────────────────┼─────────────┼──────────┼──────────┼────────┼─────
  projet-rules-iso     │ SOLVED ✅   │    N     │    N     │   0    │  0
  projet-edges         │ SOLVED ✅   │    N     │    N     │   0    │  0
  projet-cross         │ SOLVED ✅   │    N     │    N     │   0    │  0
  projet-scale         │ SOLVED ✅   │    N     │    N     │   0    │  0
  <other-projet>       │ FAILED ❌   │    N     │    N     │   N    │  N
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Overall: SOLVED ✅ / FAILED ❌     Discordances: N / N_total
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Column definitions:
- **Status**: `SOLVED ✅` if sub-agent returned `STATUS: SOLVED`, `FAILED ❌` otherwise
- **CONFORME** / **NON_CONF**: counts from the sub-agent block
- **Unproc**: `UNPROCESSED` count from the sub-agent block
- **Disc**: `DISCORDANCES` count from the sub-agent block

### 6-all.4 Discordance detail

For each file with `Disc > 0`, list the discordant elements
(from sub-agent `DISC_DETAIL`):

```
  projet-edges — 2 discordances:
    E-MUR-OK-SLEND-01  expected CONFORME   → got NON_CONFORME  (R03-slenderness)
    E-POT-KO-THICK-02  expected NON_CONF   → got CONFORME      (no rule fired)
```

For each file with `Unproc > 0`, list the unprocessed elements
(from sub-agent `UNPROC_DETAIL`):

```
  projet-scale — 3 unprocessed:
    S-OSS-OK-C24-11    → targeting slot 'besoin_ossature' probably missing from Feed
```

### 6-all.5 Convergence verdict

```
CONVERGED ✅   — all projects SOLVED, 0 discordances, 0 unprocessed
NOT CONVERGED ❌ — N discordances and/or N unprocessed across M project files
```

If **NOT CONVERGED** → recommend:
```
  Next step: chorus-strengthen <sandbox-name>
```

> **Sub-agent mode guarantee:** each sub-agent has its own IDE session and token.
> No timeout risk regardless of pipeline complexity or number of project files.
> Running N projects costs exactly N sub-agent spawns + N × `perl run.pl`.
> If a sub-agent fails (token error, crash) → re-run
> `chorus-check <sandbox> <projet-file>` (single-file mode) for the failed
> project only — no need to rerun the whole batch.

---

> **Mode used** is reported in the compliance report header:
> `Mode: MCP ✅` or `Mode: run.pl (MCP unavailable)`

---

## Phase 7 — Final verification *(post-generation only)*

> ⚠️ This checklist applies **only after generation** of Phases 1–5.
> Do not run it on the fast path (infrastructure already present).

- [ ] `agent/.kb-hash` written after generation — contains `sha256sum` of all `agent/chorus/*.org`
- [ ] ⛔ **`type_element` — YAML ↔ Feed alignment:** verify that the `attribut:` key in every
      `FIND`/`CHERCHER` block of every YAML rule that targets element type is named `type_element`.
      Then verify that `Feed.pm` creates Frames with the slot key `type_element`.
      A mismatch between YAML and Feed causes a SOLVED pipeline with all elements unprocessed.
- [ ] `Feed.pm`: agent 1 targeting slot present in `%SLOTS_REQUIS`
- [ ] `Feed.pm`: mandatory slot validation covers all element types in the project
- [ ] `Feed.pm`: unknown types → `warn + next` (not `die`) — safety net for mixed-sandbox JSON
- [ ] `Expert.pm`: `register()` order = `#+PIPELINE_POS` order
- [ ] `Expert.pm`: `$xprt->{_MAX_ITER}` forced **after** `new()` (known bug: `new()` ignores its arguments)
- [ ] `run.pl`: `../../Engine/lib` path correct from the sandbox
- [ ] `run.pl`: no hardcoded data
- [ ] Report: no unexpected `(unprocessed)` elements
- [ ] `_MAX_CYCLES`: value calibrated to the actual expected Frame volume.
      Heuristic: `N_frames × N_rules_total × N_agents × 10 < _MAX_CYCLES`.
      In `run.pl`: compute from `scalar(@elements)` and pass via `Expert->run(max_cycles => ...)`.
      Never leave the default value (`10_000`) for a production pipeline.
- [ ] Termination agent: prefer the **YAML EXCEPTION pattern** for the termination rule
      (loaded by `loadRules()` → MCP-compatible). See Phase 3 for the template.
      If using a pure Perl `addrule()` instead: `solved()` must be called on `$agent`
      (closure), never on `$SELF` — and be aware that `addrule()` is invisible to MCP mode.
      ⛔ **Never use a global `fmatch` in a YAML `FIND`/`CHERCHER` block** → guaranteed infinite loop.
      ✅ A `fmatch` in a YAML `EXCEPTION`/`CONDITION` block is safe — it is evaluated
      per-cycle but does not bind frames.
- [ ] If `reorder()` is used: the sort function consults `_PREMISSES` — consistent with the YAML files
- [ ] If `_LOCK_UNTIL_STABLE` is enabled: the agent may be skipped — verify this is the intended behaviour
- [ ] BOARD: inter-agent keys are documented in `index.org`
- [ ] **YAML — conditional EFFET without `else`**: if the `if` modifies nothing and the rule returns `1`,
      the engine loops until `_MAX_CYCLES` (warning). Check every YAML whose EFFET
      contains an `if` without `else` → return `0` when no slot is modified:
      `if (...) { ...; return 1 } 0`

---

## Separation of concerns — summary

| | `chorus-feed` | `chorus-check` |
|---|---|---|
| **Reads** | standards corpus | sandbox KB org + YAML + Helpers.pm |
| **Produces** | KB org, YAML, `Helpers.pm` | `Feed.pm`, `Agent/<Nom>.pm` (shell), `Expert.pm`, `run.pl` |
| **Does not produce** | infrastructure code | KB org, YAML, Helpers.pm |
| **Triggered by** | new standard / enrichment | project to validate |
| **Output** | persistent knowledge | compliance report |

> A sandbox can undergo N successive `chorus-feed` runs (enrichments)
> then N independent `chorus-check` runs (different projects).
> The KB and Helpers are stable and cumulative.
> Infrastructure artefacts (Feed, Agent shell, Expert, run.pl)
> are regenerated at each `chorus-check`.
