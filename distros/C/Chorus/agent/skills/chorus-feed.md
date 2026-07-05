# Skill — chorus-feed

> Trigger: `chorus-feed <sandbox-name> <corpus> [--enrich] [--harvest-aliases <import-report.org>]`
> Agent: `architect`
>
> `<sandbox-name>`: name of the sandbox directory under `$SANDBOXES/`
> `<corpus>`: plain-text file (`.txt`), Markdown file (`.md`), or inline content —
>              **or** a document file requiring preprocessing (PDF, DOCX, XLSX/CSV, XML/HTML).
>              If a document format is provided, the corresponding conversion skill is called automatically.
> `--enrich`: activates Mode B (incremental enrichment) — absent by default
> `--harvest-aliases <import-report.org>`: activates Mode C — reads a validated import report
>              and integrates its confirmed ✅ mappings into the KB `** Aliases` sections.
>              No `<corpus>` argument is needed in this mode.
>
> **Single responsibility: enrich knowledge.**
> This skill never generates infrastructure code (Feed, shell Agent, Expert, run.pl).
> It produces:
>   - KB org-mode files per agent (`agent/chorus/<slug>.org`)
>   - YAML rule files (`rules/<slug>/R<NN>-xxx.yml`)
>   - Business knowledge Perl helpers (`lib/<Namespace>/Agent/<Slug>/Helpers.pm`)
>   - Pipeline index (`agent/chorus/index.org`)
>
> To validate a project based on this knowledge → use `chorus-check`.

---

## ⛔ Strict sandbox isolation

**Never read any file, KB, YAML, or artifact from a sandbox other than `<sandbox-name>`.**

This applies regardless of context: even if another sandbox appears to contain similar
or related knowledge, it must be completely ignored. Each sandbox is an independent,
self-contained unit. Cross-sandbox reads are forbidden in all modes (A and B).

---

## 0. Prerequisites

Load: `chorus-engine-yaml.md` — YAML authoring reference (Frame essentials, Engine rule triggering, YAML guide, checklists)

### ⛔ Document Format Guard — Auto-conversion

**Before doing anything else**, check the `<corpus>` argument's file extension
(case-insensitive). `chorus-feed` accepts **only** plain-text (`.txt`), Markdown
(`.md`), or inline content (no file extension). **However**, if a preprocessing-required
format is detected, the corresponding conversion skill is invoked automatically.

| Extension | Format | Auto-conversion skill | Extracted file(s) |
|---|---|---|---|
| `.pdf` | PDF | `chorus-pdf <sandbox-name> <file.pdf> --auto` | `<NNN>-<slug>-text.txt` or `-vision.md` |
| `.docx` | Word | `chorus-word <sandbox-name> <file.docx>` | `<NNN>-<slug>-text.txt` or `-vision.md` |
| `.xlsx` / `.csv` | Spreadsheet | `chorus-excel <sandbox-name> <file>` | `<NNN>-<slug>-text.txt` or `-vision.md` |
| `.xml` / `.html` / `.htm` | XML/HTML | `chorus-xml <sandbox-name> <file>` | `<NNN>-<slug>-content.md` or `-vision.md` |
| `.txt` / `.md` / inline | Plain/Markdown | *(none)* | Use as-is |

**Auto-conversion logic:**

```
If <corpus> ends in .pdf, .docx, .xlsx, .csv, .xml, .html, .htm (case-insensitive):
  1. Invoke the corresponding skill (chorus-pdf, chorus-word, chorus-excel, or chorus-xml)
  2. Wait for completion (exit code 0 expected)
  3. Auto-detect the output file: glob corpus/[0-9][0-9][0-9]-*-{text,content,vision}.{txt,md}
     (newest by mtime if multiple outputs)
  4. Use the extracted file as <corpus> for the remainder of Phase 1+

Else:
  <corpus> is accepted as-is (plain .txt, .md, or inline content)
```

**Example:**

```bash
# Input is a PDF
chorus-feed test-05-RGPD corpus/002-norme-publiee.pdf
→ [auto] Detected .pdf format
→ [auto] Calling: chorus-pdf test-05-RGPD corpus/002-norme-publiee.pdf --auto
→ [auto] Waiting for completion...
→ [auto] Output detected: corpus/003-norme-publiee-vision.md
→ [auto] Using corpus/003-norme-publiee-vision.md as source
→ [feed] Mode A initialization with corpus/003-norme-publiee-vision.md
```

Inline content (no file extension) is always accepted as-is.
After auto-conversion (if any), proceed to Phase 0 — Sandbox Initialization.

---

## Mode Selection

**Default: Mode A — always, regardless of the sandbox state.**

The `--enrich` flag is required to activate Mode B.

| Condition | Mode |
|---|---|
| No `--enrich` flag | **Mode A** — ignore any existing KB in the sandbox |
| `--enrich` flag present | **Mode B** — read existing KB and enrich |
| `--harvest-aliases <report>` present | **Mode C** — read KB + import report, integrate aliases only |

> ⚠ Without `--enrich`, **never** read `agent/chorus/`, existing YAMLs, or
> any other KB artifact from the sandbox — even if the `<sandbox-name>` directory already exists.
> The provided corpus is treated as a fresh source, independent of any existing context.

---

## Mode A — Initialization (new corpus, fresh base)

Used when `<sandbox-name>` does not yet exist or does not contain a KB.

### Phase 0 — Sandbox Initialization

Create the directory structure:

```bash
SANDBOX="$SANDBOXES/<sandbox-name>"
mkdir -p "$SANDBOX/agent/chorus"
mkdir -p "$SANDBOX/corpus"
mkdir -p "$SANDBOX/rules"
mkdir -p "$SANDBOX/lib"
```

Save the corpus in `corpus/001-<slug-source>.txt`
(convention: numbered to allow incremental enrichment).

Create `README.org`:

```org
#+TITLE: Sandbox <sandbox-name>
#+DATE: <date>
#+STATUS: draft

* Corpus
  | Num | Fichier                    | Source              | Date       |
  |-----+----------------------------+---------------------+------------|
  | 001 | corpus/001-<slug>.txt      | <origine>           | <date>     |

* Identified pipeline
  (filled in during Phase 1)

* Agent status
  | Agent | KB | YAML | Helpers | Enrichments |
  |-------+----+------+---------+-------------|

* Session notes
```

### Phase 1 — Corpus Analysis

**1.1 Identify specialties**

Read the corpus in full. Group rules by coherent theme.
Each group = one agent. Criteria:
- rules concerning the same types of Frames
- same incoming/outgoing slots
- orderable sequentially without cyclic dependencies

Result: ordered list of agents (slug + intent + pipeline position).

**1.2 Identify domain Frames**

For each persistent concept in the corpus (≥ 2 slots, stable identity) → Frame.
Intermediate calculations remain as slots, not Frames.

> ⛔ **Canonical slot name — `type_element` is mandatory.**
> The slot identifying the element type **must always be named `type_element`** across
> the entire sandbox: in the KB org (Slot dictionary, FIND/CHERCHER attribut),
> in the YAML rules (`attribut: type_element`), and in the project JSON files.
> Never use `element_type`, `type`, `kind`, `element_kind`, or any other variant.
> A name mismatch between YAML (`attribut: element_type`) and JSON (`"type_element": ...`)
> causes all Frames to be silently invisible to every agent →
> 0 elements processed, pipeline SOLVED but all entries unprocessed.

**1.3 Identify the pipeline**

Order agents by data dependency:
agent N sets slot X → agent N+1 consumes X → N+1 after N.

**1.4 Extract XREF INDEX (hybrid corpus only)**

If the corpus file is a `-vision.md` produced by `chorus-pdf --hybrid`, it may contain
a `=== XREF INDEX ===` block at the end of the file. This block lists identifiers found
in figures (callout tags, part numbers, element codes) together with their text
occurrences — it is a ready-made synonym/alias map between figure labels and corpus
terms.

**Detection:**

```python
import re

with open(corpus_path, encoding="utf-8") as f:
    corpus_text = f.read()

xref_block_match = re.search(
    r'=== XREF INDEX ===(.*?)=== END XREF INDEX ===',
    corpus_text, re.DOTALL
)
xref_entries = {}   # {identifier: [snippet, ...]}
if xref_block_match:
    block = xref_block_match.group(1)
    current_id = None
    for line in block.splitlines():
        m_id  = re.match(r'^## (.+)$', line.strip())
        m_occ = re.match(r'^\s*Text occurrence \(p\.\d+\):\s*(.+)$', line)
        if m_id:
            current_id = m_id.group(1).strip()
            xref_entries[current_id] = []
        elif m_occ and current_id:
            xref_entries[current_id].append(m_occ.group(1).strip())
```

**Integration into the KB Ontology:**

For each `(identifier, snippets)` pair in `xref_entries`:

1. Search the corpus text and the already-identified Frame types / slot names for a
   term that co-occurs with `identifier` in the snippets (within ≤ 2 sentences).
2. If a confident match is found (same element clearly named by both `identifier`
   and a corpus term):
   - Add an alias entry in the `Ontologie` section of the relevant `<slug>.org`:
     ```org
     ** Aliases from figures
        | Figure label | Corpus term / slot              | Source                  |
        |--------------+---------------------------------+-------------------------|
        | M-001        | montant_porteur                 | xref: Figure 3, p.12    |
        | Z-A2         | lisse_haute                     | xref: Figure 3, p.12    |
     ```
   - If the label maps to a `type_element` value → add it to the `Catalogue des Frames`
     under the matching Frame as an `# alias:` comment:
     ```org
     *** montant_porteur
         # alias: M-001 (figure label — corpus p.12)
         Slots obligatoires : ...
     ```
3. If the match is uncertain (identifier appears in snippets alongside multiple
   candidate terms):
   - Add the entry with a `# TODO: ambiguous alias` comment — do not map silently.
4. If no corpus term co-occurs with the identifier in the snippets:
   - Omit from the Ontology — do not invent a mapping.

> ⚠️ **This phase adds zero API calls.** The XREF INDEX was produced at no extra cost
> by `chorus-pdf --hybrid`. Reading it is a text-only pass on the already-loaded corpus.
>
> **Scope:** only `-vision.md` corpus files contain a XREF INDEX. `.txt` (text mode)
> and `--auto`/`--images` outputs do not — skip this phase silently if the block is absent.

### Phase 2 — Targeting Strategy (_SCOPE)

**Do not skip this phase.**

**2.1 Reminder**

`_SCOPE` → Cartesian product. `fmatch(slot => 'X')` returns all Frames
carrying X. The `filtre` reduces **before** the combinatorial loop.
A Frame is invisible to an agent if it does not carry the targeted slot.

**2.2 Rule A vs B**

```
Volume Frames < 50  AND  discriminating slots well distributed → Strategy A
Otherwise                                                       → Strategy B
```
When in doubt → prefer B (always more efficient).

> ⚠️ **Scalability — volume rule:** if the expected number of Frames exceeds 100,
> **always force Strategy B** (presence slot + `EXCEPTION` on each rule).
> Strategy A without `filtre` on a scope of > 100 Frames risks O(N²)
> as soon as `FIND` has multiple variables (unreduced Cartesian product).

**2.3 `_MAX_CYCLES` sizing**

Document in the `Constraints & Pitfalls` section of each agent KB:

```
_MAX_CYCLES recommended: N_frames × N_rules_agent × N_agents × 10
```

Example for a real construction pipeline (300 elements, 5 agents, 8 rules/agent):

```perl
_MAX_CYCLES => 300 * 8 * 5 * 10,   # = 120 000
```

The engine's default value (`10 000`) is a safeguard against infinite loops
— it must be calibrated to the expected volume, not used as-is.

**2.3 Strategy B — presence slot**
- Name: `besoin_<slug_underscore>` (convention)
- Set by: initial feed (agent 1) or agent N-1 in its ACTION (subsequent agents)

**2.4 Strategy A — discriminating slot**
- Identify the common slot + filter value
- If `fmatch` returns > 100 Frames before `grep` → reconsider B

### Phase 3 — Fill the KB per agent

Create `$SANDBOX/agent/chorus/<slug>.org` from `_template.org`.
Mandatory fill order:

1. Header (`#+AGENT`, `#+PIPELINE_POS`, `#+RULES_DIR`)
2. Domain
3. **Targeting slots** — strategy + table + pre-population contract
4. Pipeline I/O (incoming / outgoing slots)
5. Ontology — including `** Aliases` section (see below)
6. Frame catalog
7. Slot dictionary
8. Rule catalog
9. **Perl Helpers** — signatures + complete business logic code
10. Constraints & Pitfalls

#### Ontology — mandatory `** Aliases` section

Every `<slug>.org` file **must include** a `** Aliases` section inside the `* Ontologie`
heading. This section is the canonical synonym/alias table for `chorus-import-project`
Phase 3 terminology alignment.

**Structure:**

```org
** Aliases
   Sources: corpus §<N> definitions, normative lexicons, XREF INDEX (hybrid corpus)
   | Canonical KB form (slot / type_element value) | Project-side variants                              | Source                        |
   |------------------------------------------------|----------------------------------------------------|-------------------------------|
   | montant_porteur                                | poteau porteur, poteau de rive, stud porteur       | corpus §2.1 — Definitions     |
   | classe_bois "C24"                              | C 24, C24 EN338, classe résistance C24             | NF EN 338 §4 table 1          |
   | entraxe_mm                                     | pas, inter-axe, espacement entre montants          | corpus §3.4                   |
   | epaisseur_mm                                   | e=, ep=, épaisseur totale, ep. isolant             | corpus §5.1                   |
```

**Population rules:**

1. **From corpus definitions/lexicons:** scan the corpus for sections titled
   "Definitions", "Terminology", "Glossary", "Lexique", "Définitions", or equivalent.
   Each defined term → alias entry in the table.

2. **From XREF INDEX (hybrid corpus only):** if a `=== XREF INDEX ===` block was
   processed in Phase 1.4, the confirmed `(identifier → corpus term)` mappings are
   added here with source `xref: Figure N, p.N`.

3. **From cross-references within the corpus:** when the corpus uses multiple names
   for the same concept (e.g. "montant porteur" and "poteau porteur" used interchangeably
   in different sections), record both as aliases of the canonical KB form.

4. **Unknown variants — leave the table sparse rather than invent:** if the corpus
   provides no synonyms for a term, the aliases column is empty. Never fabricate aliases
   from general knowledge — only record what the corpus explicitly supports.

> ⚠️ **Empty is valid.** A sandbox whose corpus contains no definition section will have
> a `** Aliases` table with zero rows. The table header must still be present — its absence
> is an error. An empty table is a clear signal that `--harvest-aliases` imports will
> contribute the bulk of real-world terminology.

**Aliases from figures — sub-section (hybrid corpus only):**

When Phase 1.4 produced confirmed `(figure label → type_element)` mappings, add a
dedicated sub-section:

```org
*** Aliases from figures
    | Figure label | Corpus term / type_element value | Source                 |
    |--------------+----------------------------------+------------------------|
    | M-001        | montant_porteur                  | xref: Figure 3, p.12   |
    | Z-A2         | lisse_haute                      | xref: Figure 3, p.12   |
```

This sub-section is read first by Phase 3 of `chorus-import-project` (highest confidence).

> **Helpers rule:** a helper belongs to `chorus-feed` (and therefore to the KB)
> if it encodes **knowledge extracted from the corpus**: value tables,
> normalized calculations, regulatory thresholds. It does NOT belong to `chorus-feed`
> if it relates to infrastructure (file access, parsing, networking).

> ⚠️ **Normative tables — externalize into Helpers, not inline in YAMLs.**
> For domains with dense corpora (standards, DTU, EC5, NF EN…), normative
> values (resistances, exposure classes, regulatory thresholds…) must
> be centralized in `Helpers.pm` rather than coded as scalars in YAML `ACTION`s.
> Advantages: updates during a normative revision without touching the YAMLs;
> traceability to the source (comment `Source corpus: §<N> — <title>`);
> unit tests independent of the rules.
>
> **Traceability rule:** each threshold or normative table in `Helpers.pm`
> must be annotated with its corpus source:
> ```perl
> # Source corpus: §5.3 tab. 1 — NF EN 338:2016 — Bending resistance by class
> my %FM_PAR_CLASSE = (C14 => 14, C16 => 16, C18 => 18, C24 => 24, C30 => 30);
> ```
> If the source is not identifiable → document the uncertainty in a `# TODO` comment.

Points to watch:
- Idempotence: `EXCEPTION: defined $var->{<slot_pose>}` on every rule that sets a slot
- Termination: document in which rule and under what condition `solved()` is called
- Naming: `R<NN>-<slug>.yml` — alphabetical order = load order

### Phase 4 — Create `agent/chorus/index.org`

```org
#+TITLE: Pipeline — <sandbox-name>

* Pipeline global
  | Pos | Agent (module Perl)     | Slug    | KB                 | Statut |
  |-----+-------------------------+---------+--------------------+--------|
  |   1 | <Namespace>::Agent::Xxx | <slug>  | agent/chorus/x.org   | draft  |

* Pipeline consistency
  - Agent 1 targeting slot: set by → initial feed
  - Agent 2 targeting slot: set by → agent 1 (R<NN>-xxx.yml, ACTION)
  - Termination agent: <Name> pos <N> → rule <Rxx> → solved()

* Integrated corpus
  | Num | Fichier              | Agents affected     |
  |-----+----------------------+---------------------|
  | 001 | corpus/001-xxx.txt   | all (initialization)|
```

### Phase 5 — Generate YAML files

> **Language rule:** use English keywords by default (`RULE`, `FIND`, `ACTION`, `PREMISES`).
> Use French keywords (`REGLE`, `CHERCHER`, `EFFET`, `PREMISSES`) only when the corpus is in French.
> **Header language must match the corpus language** — see `chorus-engine-yaml.md § Rule Documentation Standard`.

> **Documentation rule — mandatory for every generated rule:**
> Each `.yml` file must open with the structured header defined in
> `chorus-engine-yaml.md § Rule Documentation Standard`.
> Fill in: `RULE`/`REGLE`, `AGENT` (module + pipeline position), `CORPUS` (§N reference),
> `PURPOSE`/`OBJECTIF`, `INPUTS`/`ENTRÉES`, `OUTPUTS`/`SORTIES`, `HELPERS` (if any), `GUARD`.
> The `ACTION`/`EFFET` body must include inline comments per logical block
> (see inline comment rules in `chorus-engine-yaml.md § Rule Documentation Standard`).
> A rule without its header is **incomplete** — treat it as a generation defect.

For each rule in the `Rule catalog` of each KB:

```yaml
##
# RULE: <R0N-rule-slug>                          ← or REGLE: for French corpus
# AGENT: <Namespace>::Agent::<Name>  (pos. N / total)
# CORPUS: §<N> — <standard> — <section title>
#
# PURPOSE
#   <What this rule checks and why. Mention restricted element types if applicable.>
#
# INPUTS  (slots read)
#   <targeting_slot>  : targeting slot — set by <feed | previous agent RNN>
#   <slot_a>          : <type and meaning>
#
# OUTPUTS (slots written)
#   <result_slot>     : <domain values> — result of this rule
#
# HELPERS  (omit if none)
#   <helper_name>(<args>)  → <return type>
#
# GUARD — EXCEPTION: defined $<var>->{<slot_set>}
#   Idempotence — prevents re-processing a Frame already handled in a previous cycle.
##
RULE: <kebab-case-name>          # mandatory — becomes _ID (deduplication)
TERMINAL: solved                 # optional — 'solved' or 'failed'
                                 # when the rule fires AND TERMINAL is present →
                                 # the engine calls solved()/failed() automatically
PREMISES:                        # optional — prerequisite slots for reorder()
  - <slot-prerequisite>          # used by $agent->reorder(\&fn) to sort
  - <another-slot>               # rules by relevance dynamically
FIND:                            # mandatory — defines _SCOPE
  <var>:
    attribut: <targeting-slot>
    filtre: '<expression for strategy A>'
EXCEPTION: defined $<var>->{<slot_set>}    # idempotence — return if
CONDITION: '<optional-guard>'              # return unless
ACTION: |
  # ⚠️ Flow controls in ACTION: use $SELF (not $agent) → chorus-engine §1.3
  # <Logical block comment>
  <Perl code with inline comments per block>
  1
```

**When to use `TERMINAL` vs `$SELF->solved()` in ACTION:**
- `TERMINAL: solved` — the rule fires on ONE Frame and that alone is sufficient to terminate
- `$SELF->solved()` in ACTION — when the rule must check a condition before concluding.
  ⚠️ `$agent` is **not** available in a YAML ACTION (error `Global symbol "$agent"`) —
  use **exclusively `$SELF`** for flow control in ACTIONs.

> ⚠️ **Critical antipattern — YAML termination + global fmatch = infinite loop:**
> A YAML rule with a global `fmatch` in the ACTION (without an `EXCEPTION` covering the final slot)
> never converges: it fires on every Frame, returns 0 indefinitely, and
> `applyrules()` can never conclude. `_MAX_CYCLES` will be reached on every run.
>
> ```yaml
> # ⛔ ANTIPATTERN — guaranteed infinite loop
> RULE: termination
> FIND:
>   p:
>     attribut: needs_check
> ACTION: |
>   my @pending = grep { !defined $_->{status} }
>                 Chorus::Frame::fmatch(slot => 'needs_check');
>   if (@pending == 0) { $SELF->solved(); return 1 }
>   0
> ```
>
> **Solution**: global termination rule → **pure Perl `addrule()`** in the shell Agent,
> with `$agent` captured in a closure (see `chorus-check.md`, Phase 3, termination rule).
> Never code a termination via global `fmatch` in a YAML.

**When to document `PREMISES`:**
Always document if the agent is likely to use `reorder()` to
optimize rule order at runtime. PREMISES declare
the slots the rule needs — the sorting code consults them via `$rule->_PREMISSES`.

YAML Checklist:
- [ ] ⛔ **`type_element` — canonical name enforced:** the slot identifying the element type
      is always named `type_element` in YAML (`attribut: type_element`), the KB Slot dictionary,
      and the project JSON. Never `element_type`, `type`, `kind`, or any variant.
      A mismatch silently produces 0 processed frames (SOLVED but all unprocessed).
- [ ] **Header present** — every `.yml` file opens with the structured `##` header (RULE/REGLE, AGENT, CORPUS, PURPOSE/OBJECTIF, INPUTS/ENTRÉES, OUTPUTS/SORTIES, HELPERS, GUARD). Header language matches the corpus language.
- [ ] **CORPUS line filled** — references the exact §N article from the corpus. If not identifiable → `# CORPUS: TODO — source not identified`.
- [ ] **ACTION/EFFET body commented** — each logical block has a one-line comment; early `return 0` statements explain why the Frame is skipped.
- [ ] Slot names = Slot dictionary from the KB
- [ ] **`CHERCHER`/`FIND` has a named scope variable** — the scope key must be a variable name (`f:`, `e:`, `p:` …), not directly `attribut:`. Without it the engine treats `attribut` itself as the variable name → runtime crash.
      ```yaml
      # ⛔ WRONG — no scope variable; engine crashes at rule compilation
      CHERCHER:
        attribut: type_element
        filtre: "defined $_->{type_element}"
      # ✅ CORRECT
      CHERCHER:
        f:
          attribut: type_element
          filtre: "defined $_->{type_element}"
      ```
- [ ] **`filtre` uses `$_`, not `$f`** — see `chorus-engine-yaml.md` checklist.
- [ ] **`CONDITION` tests data presence, not conformance** — see `chorus-engine-yaml.md` checklist.
- [ ] Every rule that sets a slot has its idempotence `EXCEPTION: defined $var->{slot_set}`
- [ ] `ACTION` ends with `1` or a truthy expression
- [ ] ⛔ **`$f->{slot} = val` in ACTION** → silent pipeline break (`fmatch` returns 0 Frames downstream) — always use `$f->set('slot', val)` → `chorus-engine §5`
- [ ] ⛔ **CONDITION too restrictive on `type_element`** → silently excludes Frames of other types — prefer testing slot presence → `chorus-engine §5`
- [ ] ⛔ **Conditional ACTION without `else`** → returns `1` even when nothing modified → infinite loop at scale — always `return 1` inside the `if`, `0` as fallback → `chorus-engine §5`
- [ ] Use `|` (block scalar) for multi-line `ACTION` — never `>`
- [ ] Files named `R<NN>-<slug>.yml` (alphabetical = load order)
- [ ] ⛔ **Termination via global `fmatch` in YAML** → guaranteed infinite loop — use pure Perl `addrule()` instead (see `chorus-check.md` Phase 3)
- [ ] If `PREMISES` present: consistent with the KB `Slot dictionary`

### Phase 5.5 — Generate Perl Helpers

For each agent whose KB contains a non-empty `Perl Helpers` section,
create `$SANDBOX/lib/<Namespace>/Agent/<Slug>/Helpers.pm`.

**Criteria for including a helper here:**
The code encodes knowledge extracted from the corpus:
- normative value tables (e.g. resistances by class NF EN 338)
- regulatory calculations (e.g. EC5 §6.3 formula)
- threshold or range from a standard article

**What is NOT a knowledge helper** (→ stays in `chorus-check`):
- file parsing, database access, network calls
- orchestration logic (loops over agents, error handling)

#### Template `Helpers.pm`

```perl
package <Namespace>::Agent::<Slug>::Helpers;

use strict;
use warnings;
use Exporter 'import';

# Exhaustive list of exported helpers — chorus-check imports them all
our @EXPORT_OK = qw(
    <helper1>
    <helper2>
);

# -------------------------------------------------------
# <helper1>
# Source corpus : §<N> — <titre section>
# -------------------------------------------------------
# Signature : <helper1>(<args>) → <type retour>
# Called by: R<NN>-<slug>.yml (ACTION)
sub <helper1> {
    my (<args>) = @_;
    # <corps extrait du corpus>
}

# -------------------------------------------------------
# <helper2>
# Source corpus : §<N> — <titre section>
# -------------------------------------------------------
sub <helper2> {
    my (<args>) = @_;
    # <corps extrait du corpus>
}

1;
```

#### Generation rules

- **One `Helpers.pm` file per agent** — even if there is only one helper.
- **Exhaustive `@EXPORT_OK`** — all helpers listed, none missing.
  `chorus-check` does a full `use ... qw(...)` to make them available
  in the namespace before `loadRules()`.
- **`Source corpus` comment** on each helper — traceability to the standard.
- **⚠️ Org KB parity — mandatory:** after writing `Helpers.pm`, immediately
  update (or write for the first time) the `Perl Helpers` section of
  `agent/chorus/<slug>.org` with the **exact same numeric values and defaults**.
  The org KB is the single source of truth for `chorus-create-project`;
  a divergence here silently corrupts all generated JSON files.
- If a helper is **shared between multiple agents** → place it in
  `lib/<Namespace>/Helpers/Shared.pm` and document it in the KB of
  both agents involved.
- **No side effects** in a helper: no slot writes, no call to
  `$SELF`, no `fmatch`. Helpers compute and return a value —
  the YAML calls `$frame->set()`.
- **Out-of-scope types — defensive fallback:** when a helper is a table lookup
  (section minimums, resistances, thresholds…) and the `type_element` is outside
  the perimeter of the rule (e.g. `chevron` passed to a helper designed for
  `montant_porteur`), always return a neutral value that makes the downstream
  `is_xxx_suffisante` check pass rather than fail:
  ```perl
  sub section_min_requise {
    my (undef, $type, ...) = @_;
    # types outside ossature perimeter → no constraint
    unless ($type =~ /^(montant_porteur|montant_non_porteur|lisse_basse|lisse_haute)$/) {
      return (0, 0);   # (0, 0) → any section satisfies b >= 0 && h >= 0
    }
    ...
  }
  ```
  Returning the maximum sentinel (`(63, 220)`, `9999`…) as fallback causes false
  negatives on out-of-scope elements — they fail a check that was never meant
  for them, producing silently incorrect `NON` verdicts.
  Document out-of-scope handling with a `# types outside perimeter → neutral value` comment.
- **`$SELF` pitfall**: in an `_AFTER` hook or a closure that calls `set()`
  on another Frame, capture `$SELF` **before** any call to `set()`:
  ```perl
  # WRONG — $SELF will be overwritten by the internal set()
  _AFTER => sub { $other->set('x', $SELF->val) }
  # CORRECT
  _AFTER => sub { my $ctx = $SELF; $other->set('x', $ctx->val) }
  ```
  This pitfall concerns helpers called from an `_AFTER` or a procedural slot —
  not pure helpers (compute → return value).

#### Helpers Checklist

- [ ] Every helper referenced in a YAML ACTION has its implementation in `Helpers.pm`
- [ ] `@EXPORT_OK` covers all helpers in the file
- [ ] Every helper has its `Source corpus` comment
- [ ] No side effects (no `set`, no `fmatch`, no I/O)
- [ ] Shared helpers are in `Shared.pm` and documented in both KBs
- [ ] Any helper called from an `_AFTER` or procedural slot: capture `$SELF`
      before any `set()` on another Frame (`my $ctx = $SELF; ...`)
- [ ] ⚠️ **Org ↔ Helpers.pm parity** — the numeric values in the `Perl Helpers`
      section of `agent/chorus/<slug>.org` **must match exactly** the tables in
      `Helpers.pm`. Generate the `.org` section **from the same source** as the
      `.pm` code (same values, same defaults). Any divergence silently corrupts
      every JSON generated by `chorus-create-project` for this sandbox, because
      the skill reads the org KB — not `Helpers.pm` — as its source of truth.

### Phase 6 — Closing

Update `README.org`:
- `Agent status` section: KB ✓, YAML ✓, Helpers ✓ (or `-` if none)
- `Identified pipeline` section: complete table

Invalidate the infrastructure hash so the next `chorus-check` triggers a
full regeneration:

```bash
rm -f $SANDBOX/agent/.kb-hash
```

---

## Mode B — Incremental Enrichment (`--enrich` required)

Used **only** when `--enrich` is present in the command.
`<sandbox-name>` must exist and contain a KB.

### Phase B0 — Read existing KB

1. Read `agent/chorus/index.org` → current pipeline, known agents
2. Read each `agent/chorus/<slug>.org` → Slot dictionary, Rule catalog
3. Read existing YAML files → already codified rules

### Phase B1 — Analyze the new corpus

Classify each rule/prescription from the new corpus into **3 categories**:

| Category | Criterion | Action |
|---|---|---|
| **Refinement** | Concerns a Frame and slots already known | Add rule to an existing agent |
| **Extension** | Concerns new slots of a known Frame | Extend existing agent KB + new YAML rules |
| **New domain** | Concerns Frames or concepts absent from the KB | Create a new agent |

### Phase B2 — Save the new corpus

Number incrementally: `corpus/002-<slug-source>.txt`, `003-...`
Update the `Integrated corpus` table in `index.org`.

### Phase B3 — Apply changes

**Refinement case:**
- Open `agent/chorus/<slug>.org`
- Add the rule to `Rule catalog`
- Update `Slot dictionary` if new slots
- Generate the corresponding YAML file in `rules/<slug>/`
- If the rule requires a helper: add the helper to `Helpers.pm`
  and update `@EXPORT_OK`
- Verify idempotence and order of R<NN> files

**Extension case:**
- Update `Frame catalog` (new slots)
- Update `Slot dictionary`
- Add rules to `Rule catalog`
- Generate the new YAML files
- Add required helpers to `Helpers.pm`
- Verify that new slots do not conflict with those
  of other agents (Slot dictionary of the index)

**New domain case:**
- Apply Mode A (Phases 1 to 5.5) on the fragment only
- Determine the position of the new agent in the pipeline:
  - Does it read a slot set by an existing agent? → after it
  - Does it set a slot consumed by an existing agent? → before it
- Update `index.org`: insert the new agent at the correct position
- ⚠ Verify that the insertion does not break the chain of targeting slots

### Phase B4 — Enrichment closing

Update `README.org`:
- Add the row in `Corpus` (number + file + source + date)
- Update `Agent status` (KB, YAML, Helpers — new or enriched)
- Increment the enrichment counter of each modified agent

Invalidate the infrastructure hash so the next `chorus-check` triggers a
full regeneration:

```bash
rm -f $SANDBOX/agent/.kb-hash
```

---

## Mode C — Alias Harvest (`--harvest-aliases <import-report.org>`)

Used **only** when `--harvest-aliases` is present. No `<corpus>` argument is needed.
The sandbox must exist and contain a KB (at least one `<slug>.org` file).

**Purpose:** promote validated project-side terminology (from a past import) into the
KB `** Aliases` tables permanently. Future `chorus-import-project` runs on this sandbox
will resolve these terms at ✅ confidence without re-deriving them.

### Phase C0 — Read existing KB

Read each `$SANDBOX/agent/chorus/<slug>.org` into memory (Slot dictionary, Catalogue
des Frames, current `** Aliases` table). Build a fast-lookup map:
```
alias_map : { canonical_kb_form → set(known_aliases) }
```

### Phase C1 — Parse the import report

Read `<import-report.org>`. Extract the **alignment table** rows where:
- Confidence column = `✅` (certain)
- Decision column = confirmed (not rejected, not pending)

For each such row, collect:
```
(project_term, kb_slot_or_type, kb_value, source_file)
```

Ignore rows with `⚠️`, `❓`, `⛔` or `⬜` confidence — only ✅ mappings are harvested.

### Phase C2 — Deduplicate against existing aliases

For each `(project_term, kb_form)` pair:
- Look up `alias_map[kb_form]`
- If `project_term` (case-insensitive) **already present** → skip (log: "already known")
- If **absent** → mark as new

Output:
```
N_total  : total ✅ rows in the report
N_known  : already present in KB aliases
N_new    : new aliases to integrate
```

If `N_new == 0` → display "Nothing to harvest — all mappings already known in the KB."
and stop.

### Phase C3 — Integrate new aliases into KB

For each new alias, locate the correct `<slug>.org` file:
- Match `kb_slot_or_type` against the `Slot dictionary` and `Catalogue des Frames`
  of each slug to find the owning agent.
- Insert the alias row into the `** Aliases` table of that slug's org file:

```org
| <canonical_kb_form> | <project_term>  | harvested from import-report-NNN.org |
```

If `kb_form` maps to a `type_element` value, also add an `# alias:` comment in the
`Catalogue des Frames` under the matching Frame:
```org
*** montant_porteur
    # alias: "poteau porteur" — harvested from import-report-003.org
```

If no owning slug is found for a mapping → log as unresolved and skip.

### Phase C4 — Harvest closing

1. Invalidate the KB hash:
```bash
rm -f $SANDBOX/agent/.kb-hash
```

2. Display a summary:
```
✅ Alias harvest complete — $SANDBOX

   Report read    : <import-report-NNN.org>
   ✅ rows parsed  : N_total
   Already known  : N_known (skipped)
   New aliases    : N_new integrated

   Modified KB files:
     agent/chorus/<slug1>.org  (+N aliases)
     agent/chorus/<slug2>.org  (+N aliases)

   Next chorus-import-project run on this sandbox will resolve
   these N terms at ✅ confidence without re-asking.
```

3. **Do not** regenerate YAML, Helpers.pm, Feed.pm, or any infrastructure file.
   Mode C modifies only `<slug>.org` files — exclusively the `** Aliases` section.
   The KB hash invalidation ensures `chorus-check` regenerates infrastructure on next run.

| Artifact          | Convention                              | Example                           |
|-------------------|-----------------------------------------|-----------------------------------|
| Sandbox           | `test-<NNN>` or `test-<slug>`           | `test-01`, `test-norme-ec5`       |
| Agent slug        | kebab-case                              | `conformite-fiscale`              |
| KB file           | `<slug>.org`                            | `conformite-fiscale.org`          |
| YAML directory    | `rules/<slug>/`                         | `rules/conformite-fiscale/`       |
| YAML files        | `R<NN>-<slug-rule>.yml`                 | `R01-verif-montant.yml`           |
| **Element type slot** | **always `type_element`** ⛔ never `element_type` / `type` / `kind` | `type_element: montant_porteur` |
| Agent helpers     | `lib/<Namespace>/Agent/<Slug>/Helpers.pm` | `lib/CB/Agent/Ossature/Helpers.pm` |
| Shared helpers    | `lib/<Namespace>/Helpers/Shared.pm`     | `lib/CB/Helpers/Shared.pm`        |
| Initial corpus    | `corpus/001-<slug-source>.txt`          | `corpus/001-dtu-31-2.txt`         |
| Enrichment corpus | `corpus/<NNN>-<slug>.txt`               | `corpus/002-ec5-sect3.txt`        |
| Project namespace | CamelCase, defined at startup           | `MonProjet`                       |

> ⚠ `chorus-feed` never generates: `Feed.pm`, shell Agent module (`build()`),
> `Expert.pm`, `run.pl`. These artifacts are the exclusive responsibility of `chorus-check`.
