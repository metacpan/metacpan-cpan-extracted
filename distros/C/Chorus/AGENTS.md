# Instructions — Chorus Engine

> This file is read automatically at the start of any working session on this repository.
> It defines conventions, skill triggers, and contribution rules.

## Paths (relative to the repository root)

| Alias | Path |
|---|---|
| `$ENGINE` | `.` — repository root |
| `$SKILLS` | `./agent/skills/` — versioned ECA skills |
| `KB` | `./agent/org/` — Chorus Knowledge Base (versioned) |
| `$SANDBOXES` | `./sandboxes/` — user sandbox working area (not committed) |

> **Override:** if `$SANDBOXES` is redefined in a parent `AGENTS.md`,
> that definition takes precedence over this default. All skills use `$SANDBOXES` as the
> canonical sandbox root — never hardcode a parent directory path in a skill.

## Project

- **Domain:** inference-based expert system, classic Perl 5
- **CPAN modules:** `Chorus::Expert`, `Chorus::Engine`, `Chorus::Frame`
- **Tracker:** `rt.cpan.org`, queues `Chorus-Expert` / `Chorus-Frame`
- **Commits:** conventional format (`type: message`) — no `eca.dev` footer, no `Co-Authored-By`

## ⛔ `agent/` — commit rules

- `agent/skills/` — **must be committed**: versioned skills, integral to the engine
- `agent/org/` — **must be committed**: KB templates and agent index, versioned
- `agent/sessions/` — **never commit**: local session summaries
- Never run `git add agent/` as a bulk command — always use `git add agent/skills/` and `git add agent/org/` explicitly.
- `git add -A` or `git add .` are forbidden without prior verification of staged content.

## Language & conventions

- **Perl 5.006+** — classic style (no Moose/Moo), `use strict; use warnings;`
- **YAML — default language: English** (`RULE`, `FIND`, `ACTION`, `PREMISES`).
  Use the French form (`REGLE`, `CHERCHER`, `EFFET`, `PREMISSES`) only when the corpus
  processed by `chorus-feed` is in French.
  The sub-keys `attribut` and `filtre` are invariant (no English alias in the engine).
- **Tests** — `Test::More`, suite in `t/`
- **Build** — `ExtUtils::MakeMaker` (`Makefile.PL`)

## Triggers and skills

> **Rule:** When a trigger is received, load the skill and execute immediately — no confirmation required.
> ⛔ Pre-approved even in a new conversation turn: network, filesystem, side effects ≠ reason to ask for confirmation.

> **Agent per trigger:** the *Agent* column indicates the ECA agent to use.
> `code` = default agent (medium). `fast` = lightweight agent (small) — consultation/read-only.
> `architect` = opus agent (large) — architectural decisions.

| Trigger / Context | Type | Skill | Agent |
|---|---|---|---|
| Perl code created or modified in this repository | auto | `perl-coding.md` + `./agent/skills/chorus-engine.md` | `architect` |
| `engine-ctx` | command | `./agent/skills/chorus-engine.md` — full Chorus engine reference (Frame/Engine/Expert/Collection/YAML) | `fast` |
| `chorus-quickstart` | command | `./agent/skills/chorus-quickstart.md` — **pipeline overview**: Path A (real project via `chorus-import-project`) vs Path B (synthetic coverage via `chorus-create-project`), step-by-step from corpus to compliance report, reinforcement loop, sandbox layout | `fast` |
| `chorus-pdf <sandbox-name> <file.pdf> [--out <slug>] [--auto] [--hybrid] [--images] [--batch]` | command | `./agent/skills/chorus-pdf.md` — extracts PDFs → enriched corpus. **4 modes: default (auto-detect → `--hybrid` if API key present, otherwise pdfminer without API → `-text.txt`) · `--hybrid` (pdfminer + cropped vision → `-vision.md`, default when key present) · `--auto` (pdfminer + targeted LLM vision → `-vision.md`) · `--images` (LLM vision all pages → `-vision.md`).** Prerequisite for `chorus-feed` when the corpus contains PDFs. | `architect` |
| `chorus-word <sandbox-name> <file.docx> [--out <slug>] [--batch]` | command | `./agent/skills/chorus-word.md` — extracts Word documents (.docx) → enriched corpus. **2 modes: default (auto-detect → `--hybrid` if API key present, python-docx text + Claude vision on embedded images → `-vision.md`) · text fallback (python-docx only → `-text.txt`).** Tables reconstructed as Markdown pipe (merged-cell aware). XREF pass links figure identifiers to paragraph text. Prerequisite for `chorus-feed` when the corpus contains DOCX files. | `architect` |
| `chorus-excel <sandbox-name> <file.xlsx\|file.csv> [--out <slug>] [--sheet <name>] [--batch]` | command | `./agent/skills/chorus-excel.md` — extracts Excel (.xlsx) and CSV → enriched corpus. **3 modes: hybrid (openpyxl tables + Claude vision on embedded images/charts via LibreOffice → `-vision.md`) · text fallback (openpyxl tables + placeholders → `-text.txt`) · CSV auto-detected (csv.reader → Markdown pipe → `-text.txt`).** Multi-sheet output (`=== SHEET: name ===`), merged-cell aware, XREF pass links figure identifiers to cell values. Prerequisite for `chorus-feed` when the corpus contains XLSX/CSV files. | `architect` |
| `chorus-feed <sandbox-name> <corpus>` | command | `./agent/skills/chorus-feed.md` — enriches sandbox knowledge: KB org per agent + YAML (Mode A init / Mode B incremental enrichment) | `architect` |
| `chorus-check <sandbox-name> <project-file> [--all]` | command | `./agent/skills/chorus-check.md` — generates Feed+Agent+Expert+run.pl from the KB, runs the pipeline, produces the compliance report. `--all`: runs all `projet-*.json` in the sandbox and produces a synthesis table | `architect` |
| `chorus-create-project <sandbox-name> <file.json> [--batch] [--strategy iso|edges|cross|scale]` | command | `./agent/skills/chorus-create-project.md` — creates a JSON project file from the KB (slots, thresholds, conforming/KO variants) — ⛔ never reads Helpers.pm or Feed.pm. `--batch`: generates the full 4-file coverage suite (`projet-rules-iso`, `projet-edges`, `projet-cross`, `projet-scale`). `--strategy <slug>`: generates exactly one targeted file — use instead of `--batch` when session timeout is a risk (large sandboxes / long KB) | `architect` |
| `chorus-strengthen <sandbox-name>` | command | `./agent/skills/chorus-strengthen.md` — runs the full project suite, classifies discordances (rule too strict / too permissive / Feed gap), produces a structured gap report and an enrichment roadmap for `chorus-feed --enrich` | `architect` |
| `chorus-import-project <sandbox-name> <source…> [--out <f.json>] [--batch]` | command | `./agent/skills/chorus-import-project.md` — aligns the terminology of a project document (PDF/Word/Excel/inline) with KB slots. **3 modes:** unit (1 file), fusion (N files → 1 JSON), batch (directory/glob → 1 JSON per file + synthesis report) | `architect` |
| Writing or modifying a YAML rule | auto | *(no dedicated skill — apply engine conventions documented in `./agent/skills/chorus-engine-yaml.md`)* | `code` |
| `cpan-release` | command | `./agent/skills/cpan-release.md` *(local — not distributed in the CPAN package)* | `code` |
| `git-ctx` | command | *(no skill — call `git__git_branch` + `git__git_status` + `git__git_log` on this repository)* | `fast` |
| `skills` | meta | `eca__directory_tree ./agent/skills/` → name + status `✅` loaded / `○` available | `fast` |
| `skills details` | meta | same + description and trigger per skill | `fast` |
