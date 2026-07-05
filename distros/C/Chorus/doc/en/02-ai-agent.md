# Chorus in the age of LLMs

## Symbolic AI and LLMs — a natural complementarity

Rule-based systems from the 1980s–90s (CLIPS, OPS5, commercial expert systems)
shared a solid theoretical foundation: explicit knowledge, traceable reasoning,
deterministic output. They run into three structural difficulties:

1. **Knowledge acquisition** — filling a rule base required dedicated knowledge
   engineers and didn't scale. Every new domain was a fresh, expensive undertaking.
2. **Natural language** — the real world communicates in prose, tables, PDFs,
   and informal notes. Symbolic parsers broke on the first exception.
3. **Maintenance** — as rule bases grew, rules conflicted, exceptions multiplied,
   and the knowledge base became unmanageable.

Chorus-2.0 addresses all three, not by abandoning the symbolic approach, but by
delegating exactly these three problems to a language model:

| Symbolic AI alone | Chorus-2.0 |
|---|---|
| Knowledge acquisition | `chorus-feed` reads raw documents and populates the KB automatically |
| Natural language input | The LLM extracts and structures; the engine never parses free text |
| Rule maintenance | YAML rules are short, readable, versionable, and auditable by hand |

The LLM handles what it does well — reading ambiguous text at scale. The inference
engine handles what it does well — applying rules deterministically. Neither
encroaches on the other's domain.

> **On terminology.** The label *neuro-symbolic* is sometimes applied to systems
> like Chorus. It is not accurate. In neuro-symbolic systems, a neural model learns
> to simulate logical rules. In Chorus, the symbolic engine is real — frames, slots,
> an explicit inference chain — and the LLM structures and formalises the knowledge, without taking part in the reasoning. *Augmented
> symbolic* is a more precise description.

---

## Complementarity rather than competition

| Task | Right tool |
|---|---|
| Free-text understanding, extraction, generation | LLM |
| Strict business constraint validation | Chorus |
| Decision justification and traceability | Chorus |
| Fast adaptation to a new domain | LLM |
| Guaranteed compliance with a standard | Chorus |

A LLM can extract and structure the input data; Chorus applies the business rules
and certifies the result. The two complement each other without competing.

---

## Coupling with an AI agent — the AI-assisted architecture

Picture this: you have a 150-page PDF — a construction standard, a technical
specification, a regulatory document. By the end of the session you want a
running Chorus inference pipeline that validates real projects against it. Not a
prototype: a full engine with specialised agents, idempotent YAML rules, normative
tables extracted from the document, correctly wired Perl infrastructure, and a
structured conformity report.

Without assistance: several days of expert Perl work. With an AI agent and its Chorus
skills, it is the work of one session.

> **The AI agent is not an execution dependency.** The pipeline it generates is pure
> Perl — `Feed.pm`, `Agent/*.pm`, `Expert.pm`, `run.pl`. It runs on any machine
> with Perl installed, without an AI agent, without a network connection. Once generated,
> the pipeline is entirely self-contained for execution.
>
> **The AI agent is a project dependency.** Adapting a sandbox to a new project —
> aligning engineer documents with KB slots and producing a valid project JSON —
> requires `chorus-create-project` or `chorus-import-project`, both AI agent skills.
> The dependency is real and by design: the LLM reads the KB and handles the
> terminology gap that no static script can cover generically. An AI agent is also
> needed when the normative corpus changes — to re-run `chorus-feed --enrich`
> and `chorus-check`.

> Chorus skills work from any AI terminal — Claude, Copilot, or any
> `AGENTS.md`-compatible agent.

**What the chain does in practice:**

```
chorus-pdf   standard.pdf         → corpus/001-standard-vision.md
chorus-word  annex.docx           → corpus/002-annex-vision.md
chorus-excel ref-tables.xlsx      → corpus/003-ref-tables-text.txt

chorus-feed my-sandbox corpus/
    → identifies specialities → agents
    → designs the slot ontology
    → writes agent/agents/<speciality>.org (KB per agent)
    → generates rules/<speciality>/R01-xxx.yml … (YAML rules)
    → generates lib/MyApp/Agent/<Speciality>/Helpers.pm (normative tables)

chorus-check my-sandbox project.json
    → reads the KB, generates Feed.pm + Agent/*.pm + Expert.pm + run.pl
    → runs perl run.pl project.json
    → prints the conformity report
```

Corpus extraction (PDF, Word, Excel) + `chorus-feed` + `chorus-check` cover the entire pipeline.

**What makes this possible:**

The central mechanism is the **local knowledge base** — org-mode files produced
by the AI agent, one per agent, containing everything the engine needs to know: the domain
ontology, the slot dictionary, the rule catalogue with code, and Perl helpers
annotated with their normative source (`# §4.2 DTU 31.2`).

These files are readable by a domain expert without knowing any Perl. They can
correct a table, challenge a rule, refine a constraint. The AI agent re-reads the updated
KB and regenerates the downstream artefacts. Chorus executes the result without
involving the LLM — deterministically, identically, as many times as needed.

```
standard.pdf
    │ chorus-pdf
    ▼
corpus/
    │ chorus-feed
    ▼
agent/agents/*.org  ←──── domain expert reads, corrects, refines
rules/**/*.yml
lib/**/Helpers.pm
    │ chorus-check
    ▼
Feed.pm · Agent/*.pm · Expert.pm · run.pl
    │ perl run.pl project.json
    ▼
✅ COMPLIANT / ❌ NON_COMPLIANT  — with reason, per element, per agent
```

**When the standard changes:**

```
chorus-feed my-sandbox new-corpus.txt --enrich
chorus-check my-sandbox project.json
```

The KB is updated incrementally. The Perl infrastructure is regenerated. The
pipeline runs again — result guaranteed to conform to the rules as defined, with
no drift.

**In practice, on a real domain:**

A test sandbox for timber-frame construction (COB, DTU 31.2) was built with this
chain: 7 specialised agents, 37 YAML rules, 7 helper modules with EC5 and NF EN
338 lookup tables, a pipeline validating 210 building elements in a single pass.
The entire Perl and YAML codebase — around 2 000 lines — was generated by an AI agent
from the corpus. Not a single line written by hand.

> The AI agent skills for Chorus (`chorus-pdf`, `chorus-feed`, `chorus-check`,
> `chorus-create-project`, `chorus-import-project`) are versioned in
> `$ENGINE/agent/skills/` and documented in the repository.

> **Explore the demo sandbox:** the `sandboxes/demo_en` sandbox illustrates
> concretely what the pipeline produces. At the start, it contained only a
> single file — the raw corpus:
>
> ```
> corpus/001-timber-frame-intro-simul.txt   ← starting point
> ```
>
> An AI agent then ran `chorus-feed` followed by `chorus-check` to generate
> everything you find there today: KB org files, YAML rules, `Feed.pm`,
> `Agent/*.pm`, `Expert.pm`, `run.pl`. You can run the pipeline as-is:
>
> ```sh
> perl sandboxes/demo_en/run.pl sandboxes/demo_en/project-01.json
> ```
>
> or start from the corpus alone and replay `chorus-feed` + `chorus-check` to
> watch the chain build itself from scratch. Adapting to a new project (project
> JSON file) requires an AI agent (`chorus-create-project` or
> `chorus-import-project`).

---

## The `chorus-*` commands

> See [`04-chorus-commands.md`](04-chorus-commands.md) — complete reference for
> `chorus-pdf`, `chorus-feed`, `chorus-check`, `chorus-create-project`,
> `chorus-import-project`: syntax, modes, prerequisites, outputs, end-to-end
> workflow and quick-reference table.

## Application domains

> See [`03-applications.md`](03-applications.md) — sector-by-sector analysis,
> compatibility pattern, estimated onboarding time per domain.
