# Skill — chorus-strengthen

> Trigger: `chorus-strengthen <sandbox-name>`
> Agent: `architect`
>
> `<sandbox-name>`: sandbox with a KB, YAML rules, and a coverage suite (`projet-*.json`)
>
> **Single responsibility: identify rule gaps and produce an enrichment roadmap.**
> This skill runs the full project suite, analyses every discordance and unprocessed
> element, produces a structured gap report, and recommends the enrichment corpus
> to pass to `chorus-feed --enrich`.
>
> It does NOT modify any KB, YAML, or Perl file — it only reads and reports.
>
> Prerequisites:
> - `chorus-feed <sandbox-name>` must have been run (KB + YAML present)
> - `chorus-check <sandbox-name> <any-project>` must have been run at least once (infra present)
> - At least one `projet-*.json` file must exist in `$SANDBOX/`
>   (ideally the full batch from `chorus-create-project <sandbox-name> --batch`)

---

## Phase 0 — Sandbox inventory

Read the directory tree $SANDBOX/ (max_depth=3) to confirm:

- `$SANDBOX/run.pl` — infrastructure present
- `$SANDBOX/agent/.kb-hash` — hash present (infra is up to date)
- `$SANDBOX/projet-*.json` — at least one project file

If the infrastructure is absent or the hash is missing → stop:
```
⛔ Infrastructure not generated yet.
   Run: chorus-check <sandbox-name> <any-project.json>
```

If no `projet-*.json` → stop:
```
⛔ No coverage suite found in $SANDBOX/.
   Run: chorus-create-project <sandbox-name> --batch
```

---

## Phase 1 — Run the full suite (`chorus-check --all`)

Execute `chorus-check <sandbox-name> --all` (fast path — no regeneration).

This produces the synthesis table with CONFORME / NON_CONFORME / Unproc / Disc
counts per project file. Capture the full output.

If **all files converge** (SOLVED, 0 discordances, 0 unprocessed) → report:

```
✅ Suite converged — no gaps detected.
   The KB covers all tested cases. No enrichment needed at this time.
```

and stop. No gap report is needed.

---

## Phase 2 — Classify discordances

For each discordant element (expected ≠ actual), classify into one of three
gap types:

| Gap type | Pattern | Root cause |
|---|---|---|
| **Rule too strict** | Expected CONFORME → got NON_CONFORME | A rule rejects a valid case — threshold wrong, CONDITION too narrow, or edge case not covered |
| **Rule too permissive** | Expected NON_CONFORME → got CONFORME | No rule fires on this case — missing rule, threshold too high, or CONDITION excludes this type |
| **Feed gap** | Element is `(unprocessed)` | Targeting slot not set by Feed for this element type — `besoin_<slug>` missing from `%SLOTS_REQUIS` or Feed logic |

For each element, identify:
- The element `id` and `type_element`
- The expected result (from `_resultats_attendus` in the JSON, or from the ID naming convention)
- The actual result (from the pipeline output)
- The rule that fired (if any) — visible in the pipeline output as `raison_non_conformite`
  or from the absence of any firing rule
- The project file it belongs to (`projet-rules-iso`, `projet-edges`, etc.)

---

## Phase 3 — Read the relevant KB sections

For each gap identified in Phase 2, read only the sections of the relevant
agent KB that cover the implicated rule:

- `Règles` / `Rule catalog` section → rule intent, CONDITION, threshold
- `Helpers Perl` section → normative tables for the implicated slot
- `Contraintes & Pitfalls` section → known edge cases

> **Strict isolation:** read only `$SANDBOX/agent/chorus/<slug>.org`.
> Never read any file from another sandbox.

---

## Phase 4 — Produce the gap report

Display a structured report:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  chorus-strengthen  <sandbox-name>
  <N> gap(s) detected across <M> project file(s)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

For each gap, one entry:

```
  ── Gap #N — <gap-type> ─────────────────────────────────────
  Element    : <id>  (<type_element>)  in <projet-file>
  Expected   : <CONFORME|NON_CONFORME>
  Got        : <CONFORME|NON_CONFORME|unprocessed>
  Rule fired : <R0N-slug> — "<rule name>"  (or: none)
  Agent      : <agent-slug>

  Hypothesis : <concise description of the probable cause>
               e.g. "Threshold for slot 'hauteur_libre' is set to 2.50 m
                     in R02 but the corpus §4.2 states 2.40 m for class C."

  Corpus ref : §<N> — <section title> — <document>
               (or: unknown — needs manual verification)

  Suggested fix:
    → YAML: adjust CONDITION/threshold in <R0N-slug>.yml
    → OR: add new rule R<NN>-<slug>.yml covering this case
    → OR: Feed: add 'besoin_<slug>' to %SLOTS_REQUIS for type <X>
```

After all gaps:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Summary by gap type
  Rule too strict    : N gap(s)  → thresholds or CONDITION to relax
  Rule too permissive: N gap(s)  → missing rules or thresholds to tighten
  Feed gap           : N gap(s)  → %SLOTS_REQUIS or Feed logic to extend
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 5 — Enrichment roadmap

### 5.1 Group gaps by corrective action

Group all gaps into three buckets:

| Bucket | Content | Action |
|---|---|---|
| **A — Corpus clarification** | Gaps where the normative source is unclear or ambiguous | Need to re-read the original corpus §, possibly extract a correction text |
| **B — Rule adjustment** | Gaps where the corpus reference is known and the fix is a threshold / CONDITION change | Direct YAML edit (does not require `chorus-feed --enrich`) |
| **C — Missing coverage** | Gaps where the KB has no rule at all for this case | New rule needed → `chorus-feed --enrich` with a targeted corpus fragment |

### 5.2 Enrichment corpus recommendation

For bucket **C** (missing coverage), produce a recommendation:

```
Recommended enrichment corpus
──────────────────────────────
For each missing-coverage gap, draft the normative text fragment that covers it.
This text should be passed to:

  chorus-feed <sandbox-name> <corpus-correctif.txt> --enrich

Suggested corpus-correctif.txt content:
─────────────────────────────────────────
[Gap #N — <type>/<slot>]
<Normative extract or paraphrase covering the missing rule.
 Include: element type, triggering condition, threshold value, rejection reason.>

[Gap #M — <type>/<slot>]
<...>
─────────────────────────────────────────
After running chorus-feed --enrich, re-run:
  chorus-check <sandbox-name> --all
  chorus-strengthen <sandbox-name>   ← to verify convergence
```

### 5.3 Convergence loop reminder

```
Reinforcement loop:
  chorus-create-project <sb> --batch          ← (once, or if suite is stale)
       ↓
  chorus-strengthen <sb>                      ← identify gaps
       ↓
  [edit YAML directly]                        ← bucket B fixes
  chorus-feed <sb> corpus-correctif.txt --enrich  ← bucket C new rules
       ↓
  chorus-check <sb> --all                     ← verify
       ↓
  chorus-strengthen <sb>                      ← check convergence
       ↓
  ✅ CONVERGED  — all projects pass, 0 discordances
```

---

## Separation of responsibilities

| | `chorus-feed` | `chorus-create-project` | `chorus-check` | `chorus-strengthen` |
|---|---|---|---|---|
| **Reads** | corpus | sandbox org KB | org KB + YAML | pipeline output + org KB |
| **Produces** | KB org, YAML, Helpers.pm | `projet-*.json` | Feed.pm, Agent shells, Expert.pm, run.pl | gap report + enrichment roadmap |
| **Modifies KB** | ✅ | ✗ | ✗ | ✗ |
| **Modifies YAML** | ✅ | ✗ | ✗ | ✗ |
| **Triggered by** | new standard | coverage need | project to validate | failed `chorus-check --all` |
