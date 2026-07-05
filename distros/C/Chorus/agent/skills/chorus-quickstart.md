# Skill — chorus-quickstart

> Trigger: `chorus-quickstart` or `skills details` (included in the pipeline overview)
> Agent: `fast`
>
> **Single responsibility: guide the user through the complete pipeline from a raw
> corpus to a compliance report.**
> This skill does not execute any command — it explains the two available paths,
> the decision fork, and the reinforcement loop.

---

## Overview

The Chorus pipeline transforms a **raw corpus** (text, PDF, Word, Excel…) into a
**knowledge base** (KB), then validates one or more **projects** against that KB.

Two parallel paths exist depending on the origin of the project to validate:

```
                         RAW CORPUS
                             │
                    (PDF? → chorus-pdf)
                             │
                        chorus-feed
                             │
                    ┌────────┴────────┐
                    │                 │
           Real project?       Testing / coverage?
                    │                 │
         chorus-import-project  chorus-create-project
                    │                 │
                    └────────┬────────┘
                             │
                        chorus-check
                             │
                     Converged? ──No──→ chorus-strengthen
                             │                   │
                            Yes        enrich → chorus-feed --enrich
                             │                   │
                        ✅ DONE          loop until converged
```

---

## Path A — Real project (engineer document)

Use this path when you have **an actual project document** to validate against the KB
(PDF, Word, Excel, inline table from the engineer).

```
chorus-pdf  <sandbox> <file.pdf>          # only if corpus is PDF
chorus-feed <sandbox> <corpus.txt>        # build or update the KB
chorus-import-project <sandbox> <doc>     # align engineer terms → KB slots → projet-import-NNN.json
chorus-check <sandbox> projet-import-NNN.json
```

`chorus-import-project` reads the engineer's document, maps its terminology to KB slots,
and produces a `projet-*.json` ready for `chorus-check`.

---

## Path B — Synthetic coverage suite (testing)

Use this path to **generate test projects automatically** from the KB and verify that
the rules cover the full domain (conforming, edge cases, cross-type, scale).

```
chorus-pdf  <sandbox> <file.pdf>          # only if corpus is PDF
chorus-feed <sandbox> <corpus.txt>        # build or update the KB
chorus-create-project <sandbox> --batch   # generate 4 coverage files
chorus-check <sandbox> --all              # validate all projet-*.json
```

`chorus-create-project` synthesises conforming and non-conforming elements from the KB —
it never reads a real project document.

---

## Choosing between Path A and Path B

| Situation | Path |
|---|---|
| You have a real document from an engineer | **A** — `chorus-import-project` |
| You want to stress-test your rules | **B** — `chorus-create-project` |
| You want to verify domain coverage after enrichment | **B** — `chorus-create-project --batch` |
| You have both a real doc AND want coverage tests | Run both paths on the same sandbox |

> ⚠️ Both skills produce a `projet-*.json` consumed by `chorus-check`,
> but they serve opposite purposes. Do not confuse them.

---

## Step-by-step reference

### Step 0 — PDF pre-processing (if needed)

```
chorus-pdf <sandbox-name> <file.pdf>
```

- Extracts text from the PDF into `corpus/<NNN>-<slug>-text.txt` (default) or
  a vision-enriched `corpus/<NNN>-<slug>-vision.md` (with `--hybrid` / `--images`).
- **Must be run before `chorus-feed`** when the corpus source is a PDF.
- Outputs the exact `chorus-feed` command to run next.

See: `chorus-pdf.md`

---

### Step 1 — Build the knowledge base

```
chorus-feed <sandbox-name> <corpus.txt>           # Mode A — initial creation
chorus-feed <sandbox-name> <corpus.txt> --enrich  # Mode B — incremental enrichment
```

- Creates (or updates) the sandbox KB: `agent/chorus/*.org`, `rules/**/*.yml`, `lib/**/Helpers.pm`.
- Never produces infrastructure code (`Feed.pm`, `Agent/*.pm`, `Expert`, `run.pl`) — that is
  the responsibility of `chorus-check`.
- ⛔ Never pass a `.pdf` directly — use `chorus-pdf` first.

See: `chorus-feed.md`

---

### Step 2A — Import a real project (Path A)

```
chorus-import-project <sandbox-name> <source> [--out projet-import.json]
```

- Accepts PDF, Word, Excel, CSV, or inline text.
- Maps engineer terminology to KB slots → produces `projet-import-<NNN>.json`.
- Proceed to `chorus-check` with this file.

See: `chorus-import-project.md`

---

### Step 2B — Generate a synthetic coverage suite (Path B)

```
chorus-create-project <sandbox-name> --batch
```

Produces four project files in `$SANDBOX/`:
- `projet-rules-iso.json` — one element per rule, isolated
- `projet-edges.json` — boundary / threshold values
- `projet-cross.json` — multi-rule interactions
- `projet-scale.json` — large-scale volume test

Use `--strategy <iso|edges|cross|scale>` to generate a single file (recommended for large sandboxes).

See: `chorus-create-project.md`

---

### Step 3 — Validate

```
chorus-check <sandbox-name> <projet-file.json>   # single project
chorus-check <sandbox-name> --all                # all projet-*.json + synthesis table
```

- Generates infrastructure (`Feed.pm`, shell Agent, `Expert`, `run.pl`) from the KB on first run.
- Runs the pipeline and produces a compliance report.
- Verdict: `CONVERGED` ✅ or `NOT CONVERGED` → run `chorus-strengthen`.

See: `chorus-check.md`

---

### Step 4 — Strengthen (if not converged)

```
chorus-strengthen <sandbox-name>
```

- Runs `chorus-check --all` internally.
- Classifies every discordance: rule too strict, rule too permissive, Feed gap.
- Produces a structured gap report and an enrichment roadmap.
- Recommends corpus excerpts to pass to `chorus-feed --enrich`.

**Reinforcement loop:**

```
chorus-strengthen <sandbox>          ← identify gaps
   ↓
[edit YAML directly]                 ← bucket B: rule calibration
chorus-feed <sandbox> fix.txt --enrich   ← bucket C: KB gap
   ↓
chorus-check <sandbox> --all
   ↓
chorus-strengthen <sandbox>          ← verify convergence
   ↓
✅ CONVERGED
```

See: `chorus-strengthen.md`

---

## Sandbox layout (after a full run)

```
$SANDBOXES/<sandbox-name>/
├── corpus/                  ← source files (text, vision markdown)
├── agent/
│   └── chorus/
│       ├── index.org        ← KB pipeline index
│       └── <slug>.org       ← KB per agent
├── rules/
│   └── <slug>/
│       └── R<NN>-*.yml      ← YAML rules
├── lib/<NS>/Agent/<Slug>/
│   └── Helpers.pm           ← business knowledge helpers  (chorus-feed)
├── Feed.pm                  ← generated infrastructure    (chorus-check)
├── run.pl                   ← pipeline runner             (chorus-check)
├── projet-rules-iso.json    ← synthetic coverage          (chorus-create-project)
├── projet-import-001.json   ← real project                (chorus-import-project)
└── reports/
    └── <timestamp>-report.md
```

---

## Quick command reference

```
# Full Path B (test/synthetic) from a PDF corpus
chorus-pdf     myproject corpus/spec.pdf
chorus-feed    myproject corpus/001-spec-text.txt
chorus-create-project myproject --batch
chorus-check   myproject --all
chorus-strengthen myproject            # if not converged

# Full Path A (real project) from a PDF corpus
chorus-pdf     myproject corpus/spec.pdf
chorus-feed    myproject corpus/001-spec-text.txt
chorus-import-project myproject project-doc.pdf
chorus-check   myproject projet-import-001.json
```
