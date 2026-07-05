# Skill — chorus-pdf

> Trigger: `chorus-pdf <sandbox-name> <file.pdf> [--out <slug>] [--auto] [--hybrid] [--images] [--batch]`
> Agent: `architect`
>
> `<sandbox-name>`: name of the sandbox directory under `$SANDBOXES/`
> `<file.pdf>`: path to the PDF — absolute, or relative to `$SANDBOX/corpus/`
> `--out <slug>`: override the output filename stem (default: derived from input filename)
> `--auto`: smart mode — pdfminer on text-only pages, vision LLM on pages with figures
> `--hybrid`: best-quality mode — pdfminer for text on ALL pages + Claude vision on cropped figures only
> `--images`: full vision mode — all pages processed by vision LLM via `pdftoppm` + Anthropic
> `--batch`: process all `*.pdf` files found in `$SANDBOX/corpus/`
>
> **Single responsibility: produce an enriched text file from a PDF.**
> Extracts text, tables, figures, diagrams, and technical annotations that `pdftotext`
> and similar tools silently discard.
>
> Output format depends on mode:
> - Hybrid mode (default when API key available): `corpus/<NNN>-<slug>-vision.md` — pdfminer text + cropped figure vision
> - Text mode (fallback — no API key): `corpus/<NNN>-<slug>-text.txt` — plain text, pdfminer only
> - Auto / Images mode: `corpus/<NNN>-<slug>-vision.md` — Markdown with tables and figure blocks
>
> This skill must be run **before** `chorus-feed` when the corpus contains PDFs.
> `chorus-feed` then takes the output file as its corpus input.

---

## ⛔ Strict sandbox isolation

Never read any KB, YAML, or artifact from a sandbox other than `<sandbox-name>`.
This skill operates exclusively on the `corpus/` directory of the target sandbox.

---

## Overview

Standard PDF-to-text tools (`pdftotext`, `pdf2txt.py`) extract only typographic text.
They silently drop structural diagrams, normative tables rendered as images, multi-column
layouts, and figure annotations. This skill provides three extraction modes of increasing
capability:

### Four extraction modes

| Mode | Flag | Engine | API key | Figures | Tables (vector) | Output |
|------|------|--------|---------|---------|-----------------|--------|
| **Hybrid** (**default**) | *(none — auto-detected)* | `pdfminer` for text on ALL pages + Claude vision on cropped figures only | ✅ `ANTHROPIC_API_KEY` | ✅ described (precise crop) | ✅ `pdfplumber` — Markdown pipe table | `<slug>-vision.md` |
| **Text** (fallback) | *(none — no API key)* | `pdfminer.six` | ❌ not required | `[FIGURE — not extracted]` placeholder | ✅ `pdfplumber` — Markdown pipe table | `<slug>-text.txt` |
| **Auto** | `--auto` | `pdfminer` on text pages + vision LLM on figure pages | ✅ `ANTHROPIC_API_KEY` | ✅ described (targeted) | ⚠️ not reconstructed | `<slug>-vision.md` |
| **Images** | `--images` | `pdftoppm` 150 DPI + vision LLM on all pages | ✅ `ANTHROPIC_API_KEY` | ✅ described (exhaustive) | ⚠️ not reconstructed | `<slug>-vision.md` |

**Choosing a mode:**

```
No flag provided
  → Phase 0.0 auto-detects ANTHROPIC_API_KEY and probes Claude
  → if key valid   : --hybrid activated automatically  ← DEFAULT
  → if key absent or invalid : text mode (fallback)

API key available, document has mixed pages (text + embedded figures)
  → (default — hybrid activated automatically)

API key available, document is text-only or text-dominant (no embedded figures)
  → --auto   ← faster, fewer API calls

API key available, document is mostly diagrams or scanned
  → --images

No API key available
  → (default text mode — forced fallback)
```

> **`--hybrid` is the recommended mode** for building/structural standards
> (Approved Document A, DTU, EC5, NF EN…) when an API key is available.
> It combines pdfminer precision on text (exact characters, no OCR risk) with
> Claude vision on cropped figures only (smaller payload, lower cost, no text
> re-interpretation). On pages with both text and figures, text fidelity is
> maximised and API calls are minimised to the figure bounding boxes.

---

## Phase 0.0 — Auto-detect mode (no explicit flag)

This phase runs **only when neither `--auto`, `--hybrid` nor `--images` was provided**.
Its goal: activate `--hybrid` automatically if Claude is available.

### 0.0.1 Check API key presence

```python
API_KEY = os.environ.get("ANTHROPIC_API_KEY", "")
if not API_KEY:
    # No key → stay in text mode, skip probe
    mode = "text"
    print("[chorus-pdf] No ANTHROPIC_API_KEY — text mode.", file=sys.stderr)
```

If a key is present → proceed to 0.0.2.

### 0.0.2 Probe Claude availability

Send a minimal request to verify the key is valid and the API reachable.
Use `claude-haiku-4-5` (cheapest model, ~1 token, <1s, cost negligible).

```python
def probe_claude(api_key):
    """Probe Claude availability with a minimal 1-token request.
    Returns True  if the key is valid and the API is reachable.
    Returns False if the key is invalid (401/403) or network unreachable.
    Returns True  on rate-limit (429/529) — key is valid, just throttled.
    """
    import json, urllib.request, urllib.error

    payload = {
        "model": "claude-haiku-4-5",
        "max_tokens": 1,
        "messages": [{"role": "user", "content": "ping"}]
    }
    headers = {
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
    }
    try:
        req = urllib.request.Request(
            "https://api.anthropic.com/v1/messages",
            data=json.dumps(payload).encode("utf-8"),
            headers=headers,
            method="POST"
        )
        urllib.request.urlopen(req, timeout=10)
        return True
    except urllib.error.HTTPError as e:
        if e.code in (429, 529):
            return True   # throttled but key is valid
        return False      # 401 Unauthorized / 403 Forbidden
    except Exception:
        return False      # network error, timeout
```

### 0.0.3 Decision table

| `ANTHROPIC_API_KEY` | Probe result | Mode activated | Message |
|---|---|---|---|
| absent | — | text | `No ANTHROPIC_API_KEY — text mode.` |
| present | ✅ valid | **hybrid** | `ANTHROPIC_API_KEY detected — Claude available ✅ — hybrid mode activated.` |
| present | ❌ invalid (401/403) | text | `ANTHROPIC_API_KEY set but key is invalid (HTTP 4xx) — falling back to text mode.` |
| present | ❌ unreachable | text | `Claude unreachable (network error) — falling back to text mode.` |
| present | ⚠️ throttled (429/529) | **hybrid** | `ANTHROPIC_API_KEY detected — Claude available (throttled) ✅ — hybrid mode activated.` |

Print the selected mode to stderr before proceeding to Phase 0.1.

> ⚠️ **Explicit flags always take precedence.**
> `--auto`, `--hybrid` and `--images` bypass Phase 0.0 entirely — no probe, no key check.
> Phase 0.0 is only entered when the user provides no mode flag.

---

## Phase 0 — Resolve inputs

### 0.1 Resolve the sandbox path

```
SANDBOX = $SANDBOXES/<sandbox-name>
```

Verify that `$SANDBOX/corpus/` exists. If not, abort with:
```
⛔ Sandbox '<sandbox-name>' does not exist or has no corpus/ directory.
   Create corpus/ manually or run chorus-feed first to initialize the sandbox.
```

### 0.2 Resolve the PDF path

If `<file.pdf>` is a bare filename → prepend `$SANDBOX/corpus/`.
If it is an absolute path → use as-is.
Verify the file exists and ends in `.pdf` (case-insensitive).

In `--batch` mode: glob `$SANDBOX/corpus/*.pdf` (and `*.PDF`). Process each in turn.
If no PDF found → warn and exit cleanly (not an error).

### 0.3 Resolve the output filename

Determine the next available corpus number:

```
existing = glob("$SANDBOX/corpus/[0-9][0-9][0-9]-*.*")
last_num = max of the leading 3-digit prefix across existing files (default 0)
next_num = last_num + 1   (formatted as %03d)
```

> ⚠️ In `--batch` mode, increment `next_num` for each PDF processed in sequence.

Derive the slug and extension based on mode:

| Mode | Suffix | Extension | Rationale |
|------|--------|-----------|-----------|
| Hybrid (default) | `-vision` | `.md` | pdfminer text + cropped figure vision — default when API key present |
| Text (fallback) | `-text` | `.txt` | Plain text only — no Markdown syntax produced |
| Auto (`--auto`) | `-vision` | `.md` | Contains Markdown tables and `[FIGURE]` blocks |
| Images (`--images`) | `-vision` | `.md` | Contains Markdown tables and `[FIGURE]` blocks |

- If `--out <slug>` provided → use that slug as-is (suffix already included)
- Otherwise → strip leading `NNN-` prefix and `.pdf` extension from the input filename,
  then append the mode suffix

Output filename: `$SANDBOX/corpus/<next_num>-<slug>.<ext>`

Example:
```
Input  : corpus/002-uk-approved-doc-a-2013.pdf

Default : corpus/003-uk-approved-doc-a-2013-text.txt
--auto  : corpus/003-uk-approved-doc-a-2013-vision.md
--images: corpus/003-uk-approved-doc-a-2013-vision.md
```

---

## Phase 1 — PDF assessment

### 1.1 Count pages

```bash
python3 -c "
import sys
try:
    import pypdf
    r = pypdf.PdfReader(sys.argv[1])
    print(len(r.pages))
except Exception as e:
    print('ERROR:', e, file=sys.stderr)
    sys.exit(1)
" "<path/to/file.pdf>"
```

Fallback if `pypdf` unavailable:
```bash
pdfinfo "<path/to/file.pdf>" | grep "^Pages:" | awk '{print $2}'
```

### 1.2 Page classification (--auto mode only)

For `--auto`, each page is classified **before** generating the script,
using `pypdf` to inspect the page content:

```python
import pypdf
reader = pypdf.PdfReader(pdf_path)
for i, page in enumerate(reader.pages, 1):
    text      = page.extract_text() or ""
    has_image = len(page.images) > 0
    has_text  = len(text.strip()) > 50   # threshold: ignore near-empty pages

    if has_image or not has_text:
        category = 'vision'   # → pdftoppm + Claude
    else:
        category = 'text'     # → pdfminer
```

Report the classification to the user before generating the script:
```
[chorus-pdf] Page classification:
   → 38 text-only pages  (pdfminer — no API call)
   → 16 pages with figures (vision LLM — 4 chunks × 4 pages)
```

### 1.3 Chunk sizes

| Mode | Chunk size | Rationale |
|------|-----------|-----------|
| Text (default) | N/A — single pass | pdfminer processes the whole file at once |
| Auto (`--auto`) | 5 vision pages per call | only figure pages are chunked |
| Hybrid (`--hybrid`) | 1 figure crop per call | each `LTFigure` bbox sent individually |
| Images (`--images`) | 5 pages per call | all pages, one PNG each (~500 KB) |

### 1.4 Figure detection for `--hybrid` mode

For `--hybrid`, figure bounding boxes are detected via `pdfminer` layout analysis.
Each `LTFigure` element exposes its `(x0, y0, x1, y1)` coordinates in PDF space.

### 1.4b Vector table detection (all modes)

Many normative PDFs (EU directives, JOUE publications, regulatory annexes) encode their
tables as **vectors** (`LTCurve` elements — thin lines forming cell borders), not as
`LTFigure` or embedded images. Standard pdfminer text extraction silently discards the
table structure and dumps cell contents in Y-order, mixing columns.

**Detection heuristic** — applied during `analyse_pages` on every page:

```python
from pdfminer.layout import LTCurve

h_lines = [el for el in layout if isinstance(el, LTCurve)
           and (el.y1 - el.y0) < 3 and (el.x1 - el.x0) > 50]   # horizontal rule
v_lines = [el for el in layout if isinstance(el, LTCurve)
           and (el.x1 - el.x0) < 3 and (el.y1 - el.y0) > 30]   # vertical separator

has_table = len(h_lines) >= 2 and len(v_lines) >= 1
```

Store `has_table` in the `analyse_pages` result so that the assembly phase knows
which pages require `pdfplumber` table reconstruction.

**Reconstruction with `pdfplumber`:**

When `has_table` is `True`, use `pdfplumber` to reconstruct the table as a Markdown
pipe table. The key insight is that pdfplumber's automatic column detection often fails
on PDF files with doubled/hairline lines (linewidth ≈ 0). Use `'vertical_strategy':
'explicit'` with column x-coordinates derived from the V-edges detected above:

```python
def detect_table_columns(page):
    """Detect explicit vertical column separators from V-edges on this pdfplumber page.
    Returns a sorted list of x-coordinates, or None if no table structure found."""
    edges  = page.edges
    v_edges = [e for e in edges if e['orientation'] == 'v' and e['height'] > 30]
    h_edges = [e for e in edges if e['orientation'] == 'h' and e['width']  > 50]
    if len(h_edges) < 2 or len(v_edges) < 1:
        return None
    # Cluster x-coordinates — snap duplicates within 3 pt
    xs = sorted(set(e['x0'] for e in v_edges))
    clustered = []
    for x in xs:
        if not clustered or x - clustered[-1] > 3:
            clustered.append(x)
    # Add left/right boundaries from the widest H-edge
    widest = max(h_edges, key=lambda e: e['width'])
    all_xs = sorted(set([widest['x0']] + clustered + [widest['x1']]))
    return all_xs if len(all_xs) >= 2 else None

def extract_tables_from_page(page):
    """Extract tables from a pdfplumber page as (bbox, markdown) tuples."""
    col_xs = detect_table_columns(page)
    if col_xs is None:
        return []
    settings = {
        'vertical_strategy':   'explicit',
        'horizontal_strategy': 'lines',
        'explicit_vertical_lines': col_xs,
        'snap_tolerance': 6,
        'join_tolerance':  6,
        'edge_min_length': 10,
    }
    result = []
    try:
        for tobj in page.find_tables(table_settings=settings):
            rows = tobj.extract()
            if not rows or not any(any(c for c in row) for row in rows):
                continue
            # Build Markdown pipe table
            def cell(c):
                return str(c or "").replace("\n", " ").replace("|", "｜").strip()
            lines = []
            lines.append("| " + " | ".join(cell(c) for c in rows[0]) + " |")
            lines.append("| " + " | ".join("---" for _ in rows[0]) + " |")
            for row in rows[1:]:
                lines.append("| " + " | ".join(cell(c) for c in row) + " |")
            result.append((tobj.bbox, "\n".join(lines)))
    except Exception:
        pass
    return result
```

**Coordinate system — pdfplumber `top` → pdfminer `y_center`:**

pdfplumber uses origin=top-left (`top` increases downward); pdfminer uses
origin=bottom-left (`y` increases upward). Convert with:

```python
def pdfplumber_top_to_pdfminer_y(top, page_height_pt):
    return page_height_pt - top
```

**Deduplication:** after inserting a table block at its Y-position, suppress all
`LTTextBox` elements whose `y_center` falls within the table's vertical range —
they are already represented by the Markdown table.

**Dependency:** `pdfplumber` — installed in the pipx venv at
`~/.local/share/pipx/venvs/pdfplumber/bin/python3` if not available system-wide.
The script must detect the correct interpreter or fall back gracefully.

```python
from pdfminer.high_level import extract_pages
from pdfminer.layout import LAParams, LTTextBox, LTFigure

laparams = LAParams(boxes_flow=0.5, char_margin=2.0)
page_figures = {}   # {page_num: [(x0, y0, x1, y1), ...]}
page_texts   = {}   # {page_num: [(text_block, y_center), ...]}

for page_num, layout in enumerate(extract_pages(pdf_path, laparams=laparams), 1):
    figures = []
    texts   = []
    page_height = layout.height
    for el in layout:
        if isinstance(el, LTFigure):
            figures.append((el.x0, el.y0, el.x1, el.y1))
        elif isinstance(el, LTTextBox):
            t = el.get_text().strip()
            if t:
                y_center = (el.y0 + el.y1) / 2
                texts.append((t, y_center))
    page_figures[page_num] = figures
    page_texts[page_num]   = texts
```

**Coordinate conversion — PDF space → PNG pixels:**

PDF coordinates have their origin at the **bottom-left**; PNG pixels have theirs at
the **top-left**. Convert with:

```python
def pdf_bbox_to_png_crop(x0, y0, x1, y1, page_height, dpi=150):
    """Convert a PDF LTFigure bbox to PIL crop coordinates (left, upper, right, lower)."""
    scale  = dpi / 72.0
    left   = int(x0 * scale)
    upper  = int((page_height - y1) * scale)   # flip vertical axis
    right  = int(x1 * scale)
    lower  = int((page_height - y0) * scale)
    # Add a small margin to capture borders
    margin = int(4 * scale)
    return (
        max(0, left  - margin),
        max(0, upper - margin),
        right  + margin,
        lower  + margin,
    )
```

**Reading order reconstruction:**

After mixing text blocks and `[FIGURE N]` placeholders, sort all elements by their
`y_center` in **descending** order (top of page = highest PDF y-coordinate):

```python
elements = []
for text, y_center in page_texts[page_num]:
    elements.append((y_center, 'text', text))
for fig_idx, (x0, y0, x1, y1) in enumerate(page_figures[page_num], 1):
    y_center_fig = (y0 + y1) / 2
    elements.append((y_center_fig, 'figure', fig_idx))

elements.sort(key=lambda e: e[0], reverse=True)   # top-to-bottom reading order
```

---

## Phase 1.5 — nohup gate (hybrid mode only)

After the layout analysis (`analyse_pages`), the script knows the **exact number of
`LTFigure` elements** to send to Claude. Each figure = 1 API call ≈ 30 s average.
The IDE has a hard timeout of ~10 minutes.

**Decision rule — applied inside the generated script:**

| Figures detected (`n_figs`) | Estimated time | Action |
|----------------------------:|---------------:|--------|
| ≤ 15 | ≤ 7.5 min | proceed directly |
| 16–19 | 8–9.5 min | borderline — script still exits with a warning |
| ≥ 16 | > 8 min | **exit(2)** + print `nohup` command |

The script prints the exact `nohup` command to copy-paste, then exits with code **2**
(not an error — "nohup required"). Exit code 0 is reserved for successful completion.

```
[chorus-pdf]   → 31 pages, 12 with figures, 18 figure(s) total
[chorus-pdf] ⚠️  18 figures detected — estimated time ~9–13 min (threshold: 15).
[chorus-pdf]    Run with nohup to avoid a 10-min IDE timeout:
[chorus-pdf]    CHORUS_PDF_FORCE=1 nohup python3 /path/to/agent/extract-pdf-<slug>.py > corpus/<NNN>-<slug>-vision.md.log 2>&1 &
```

The threshold constant `NOHUP_THRESHOLD = 15` is defined at the top of the script
and can be adjusted if the API is consistently faster (lower latency environment).

**Bypass `CHORUS_PDF_FORCE=1`:** when the script is launched via `nohup` (detached from
the IDE), set `CHORUS_PDF_FORCE=1` to skip the gate and proceed unconditionally.
Without this flag, the gate fires even under `nohup` because the script cannot detect
whether it is running inside the IDE or not.

> ⚠️ **instruction:** when executing the script and receives exit code 2, it must **not** retry automatically. Instead, it must
> set `CHORUS_PDF_FORCE=1` and relaunch with `nohup` — **launch the nohup command**
> (pre-approved, no confirmation required).

---

## Phase 2 — Generate the extraction script

Create `$SANDBOX/agent/` if it does not exist.
writes `$SANDBOX/agent/extract-pdf-<slug>.py`, then executes it

### Vision extraction prompt (used verbatim in `--auto` and `--images` scripts)

```
You are a technical document extraction engine.
Your task is to produce a complete, faithful plain-text reconstruction of this PDF page.

Apply the following rules strictly:

TEXT
- Extract all text in reading order (top to bottom, left to right).
- For multi-column layouts: extract column 1 fully, then column 2. Insert a blank line between columns.
- Preserve section numbers, article numbers, and clause references exactly as printed.
- Preserve all footnote markers and footnote text (append footnotes at end of page output).
- Do not summarize, paraphrase, or omit any text.

TABLES
- Reconstruct every table in Markdown format (pipe syntax).
- Preserve all column headers, row labels, units, and footnote references inside the table.
- If a table spans multiple pages: output the fragment visible on this page; prefix it with
  [TABLE CONTINUED — <table title or number>] if this is a continuation.

FIGURES AND DIAGRAMS
- For every figure, diagram, or illustration: output a block of the form:
    [FIGURE <N> — <title or caption>]
    <Structured description of all visual content:>
    - Labeled dimensions, dimensions with units
    - Named components and their spatial relationships
    - Numerical values visible in or next to the figure
    - Arrows, load paths, connection points, hinge symbols, support symbols
    - Hatching patterns and what material or condition they represent
    - Scale bar if present
    [END FIGURE <N>]
- If there is no figure number or caption in the PDF, assign [FIGURE ?] and describe anyway.

EQUATIONS AND FORMULAS
- Render every equation in linearized form (e.g., σ = F / A).
- Preserve all variable names, subscripts, and units as printed.

HEADERS AND FOOTERS
- If a page has a running header or footer containing normative information (standard number,
  edition date, section title): include it once at the top of the page output as:
    [HEADER: <content>]
- Omit purely decorative headers/footers (page number alone, logo only).

OUTPUT FORMAT
- Begin each page with: === PAGE <N> ===
- End each page with: === END PAGE <N> ===
- Separate pages with a single blank line.
- Use UTF-8. Preserve all special characters (±, ≤, ≥, ×, °, ², ³, φ, σ, …).
- Do not add commentary outside the === PAGE === markers.
```

---

### Script template — Text mode (no flag + Claude unavailable, or forced text mode)

Uses `pdfminer.six` only. No API key, no network. Figures produce a placeholder.
Output: `<NNN>-<slug>-text.txt`

```python
#!/usr/bin/env python3
"""
chorus-pdf extraction script — text mode (default)
Generated by chorus-pdf skill
Sandbox : <sandbox-name>
Source  : <input-pdf-path>
Output  : <output-txt-path>   (e.g. corpus/003-uk-approved-doc-a-2013-text.txt)
"""

import sys
import os

PDF_PATH    = "<input-pdf-path>"
OUTPUT_PATH = "<output-txt-path>"

FIGURE_PLACEHOLDER = (
    "[FIGURE — not extracted]\n"
    "[Run chorus-pdf with --hybrid, --auto or --images to extract figures via LLM vision]"
)


def analyse_pages_text(pdf_path):
    """Extract text + detect figures and vector tables. Returns list of
    (page_num, text_blocks, has_figure, has_table, page_height)."""
    try:
        from pdfminer.high_level import extract_pages as pm_extract
        from pdfminer.layout import LAParams, LTTextBox, LTFigure, LTCurve
    except ImportError:
        print("⛔ pdfminer.six not installed. Run: pip install pdfminer.six", file=sys.stderr)
        sys.exit(1)

    laparams = LAParams(
        line_overlap=0.5,
        char_margin=2.0,
        line_margin=0.5,
        word_margin=0.1,
        boxes_flow=0.5,
        detect_vertical=False,
        all_texts=False
    )

    result = []
    for page_num, layout in enumerate(pm_extract(pdf_path, laparams=laparams), 1):
        blocks     = []
        has_figure = False
        curves     = []
        for el in layout:
            if isinstance(el, LTTextBox):
                t = el.get_text().strip()
                if t:
                    blocks.append((t, (el.y0 + el.y1) / 2, el.x0, el.x1))
            elif isinstance(el, LTFigure):
                has_figure = True
            elif isinstance(el, LTCurve):
                curves.append(el)
        h_lines   = [c for c in curves if (c.y1 - c.y0) < 3 and (c.x1 - c.x0) > 50]
        v_lines   = [c for c in curves if (c.x1 - c.x0) < 3 and (c.y1 - c.y0) > 30]
        has_table = len(h_lines) >= 2 and len(v_lines) >= 1
        result.append((page_num, blocks, has_figure, has_table, layout.height))
    return result


def detect_table_columns(page):
    edges   = page.edges
    v_edges = [e for e in edges if e['orientation'] == 'v' and e['height'] > 30]
    h_edges = [e for e in edges if e['orientation'] == 'h' and e['width']  > 50]
    if len(h_edges) < 2 or len(v_edges) < 1:
        return None
    xs = sorted(set(e['x0'] for e in v_edges))
    clustered = []
    for x in xs:
        if not clustered or x - clustered[-1] > 3:
            clustered.append(x)
    widest = max(h_edges, key=lambda e: e['width'])
    all_xs = sorted(set([widest['x0']] + clustered + [widest['x1']]))
    return all_xs if len(all_xs) >= 2 else None


def extract_tables_from_page(page):
    col_xs = detect_table_columns(page)
    if col_xs is None:
        return []
    settings = {
        'vertical_strategy':       'explicit',
        'horizontal_strategy':     'lines',
        'explicit_vertical_lines': col_xs,
        'snap_tolerance': 6, 'join_tolerance': 6, 'edge_min_length': 10,
    }
    def cell(c):
        return str(c or "").replace("\n", " ").replace("|", "｜").strip()
    result = []
    try:
        for tobj in page.find_tables(table_settings=settings):
            rows = tobj.extract()
            if not rows or not any(any(c for c in row) for row in rows):
                continue
            lines = ["| " + " | ".join(cell(c) for c in rows[0]) + " |",
                     "| " + " | ".join("---" for _ in rows[0]) + " |"]
            for row in rows[1:]:
                lines.append("| " + " | ".join(cell(c) for c in row) + " |")
            result.append((tobj.bbox, "\n".join(lines)))
    except Exception:
        pass
    return result


def main():
    # Optional pdfplumber for vector table reconstruction
    try:
        import pdfplumber as pdfplumber_mod
        HAS_PDFPLUMBER = True
    except ImportError:
        HAS_PDFPLUMBER = False
        print("[chorus-pdf] ⚠️  pdfplumber not available — vector tables will not be reconstructed",
              file=sys.stderr)

    print(f"[chorus-pdf] Text mode — {PDF_PATH}", file=sys.stderr)
    page_data = analyse_pages_text(PDF_PATH)
    plumber_pdf = pdfplumber_mod.open(PDF_PATH) if HAS_PDFPLUMBER else None

    parts = []
    fig_pages   = 0
    total_tables = 0

    for page_num, blocks, has_figure, has_table, page_height in page_data:
        elements = []  # (y_center, content)

        # Vector table reconstruction
        table_y_ranges = []
        if plumber_pdf and has_table:
            table_entries = extract_tables_from_page(plumber_pdf.pages[page_num - 1])
            for (tx0, t_top, tx1, t_bottom), md in table_entries:
                y_min = page_height - t_bottom
                y_max = page_height - t_top
                y_c   = (y_min + y_max) / 2
                table_y_ranges.append((y_min, y_max))
                elements.append((y_c, md))
                total_tables += 1

        # Text blocks — suppressed if inside a table bbox
        for (text, y_center, x0, x1) in blocks:
            if any(y_min <= y_center <= y_max for (y_min, y_max) in table_y_ranges):
                continue
            elements.append((y_center, text))

        # Figure placeholder
        if has_figure:
            elements.append((0, FIGURE_PLACEHOLDER))
            fig_pages += 1

        elements.sort(key=lambda e: e[0], reverse=True)
        body = "\n\n".join(c for (_, c) in elements)
        parts.append(f"=== PAGE {page_num} ===\n{body}\n=== END PAGE {page_num} ===")

    if plumber_pdf:
        plumber_pdf.close()

    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        f.write("\n\n".join(parts))

    print(f"[chorus-pdf] ✅ {len(page_data)} pages extracted, {total_tables} table(s)", file=sys.stderr)
    if fig_pages:
        print(f"[chorus-pdf]    {fig_pages} page(s) contain figures — use --hybrid or --auto to extract them",
              file=sys.stderr)
    print(f"[chorus-pdf] Written to {OUTPUT_PATH}", file=sys.stderr)


if __name__ == "__main__":
    main()
```

> ⚠️ **Dependencies**: `pip install pdfminer.six pdfplumber` (`pdfplumber` optional — graceful fallback if absent)

---

### Script template — Hybrid mode (`--hybrid`)

Best-quality mode for documents with mixed pages (text + embedded figures).
`pdfminer` extracts text on **every** page with full precision. For each `LTFigure`
found, `pdftoppm` renders the page and `Pillow` crops the figure bounding box;
Claude describes the cropped image only. Text and figure descriptions are merged
in reading order (sorted by Y-coordinate).

Output: `<NNN>-<slug>-vision.md`

```python
#!/usr/bin/env python3
"""
chorus-pdf extraction script — hybrid mode (--hybrid)
Generated by chorus-pdf skill
Sandbox : <sandbox-name>
Source  : <input-pdf-path>
Output  : <output-md-path>    (e.g. corpus/003-uk-approved-doc-a-2013-vision.md)
Pages   : <total-pages>
"""

import sys
import base64
import json
import re
import time
import tempfile
import subprocess
import urllib.request
import urllib.error
import os
import io

PDF_PATH    = "<input-pdf-path>"
OUTPUT_PATH = "<output-md-path>"
DPI         = 150
MAX_RETRIES = 4
API_KEY     = os.environ.get("ANTHROPIC_API_KEY", "")
API_URL     = "https://api.anthropic.com/v1/messages"

FIGURE_PROMPT = """You are a technical document extraction engine.
Describe this figure extracted from a normative PDF document.

Apply the following rules strictly:

FIGURES AND DIAGRAMS
- Output a block of the form:
    [FIGURE <N> — <title or caption if visible>]
    <Structured description of all visual content:>
    - Labeled dimensions, dimensions with units
    - Named components and their spatial relationships
    - Numerical values visible in or next to the figure
    - Arrows, load paths, connection points, hinge symbols, support symbols
    - Hatching patterns and what material or condition they represent
    - Scale bar if present
    [END FIGURE <N>]
    IDENTIFIERS: ["<id1>", "<id2>", ...]
- If there is no caption visible, assign [FIGURE ?] and describe anyway.
- For IDENTIFIERS: list every alphanumeric code, label, designation or identifier
  visible in the figure (callout tags, part numbers, zone codes, element IDs,
  article references, dimension labels with letters). Use the exact string as printed.
  Exclude purely numeric values (dimensions, measurements), single letters used as
  generic variables, and common stopwords. Output valid JSON array on a single line
  immediately after [END FIGURE <N>]. Output [] if no identifiers found.
- Do not add text outside the [FIGURE] ... [END FIGURE] block and IDENTIFIERS line.
- Use UTF-8. Preserve all special characters (±, ≤, ≥, ×, °, ², ³, …).
"""


# ---------------------------------------------------------------------------
# pdfminer layout analysis — extract text blocks AND figure bboxes per page
# ---------------------------------------------------------------------------

def analyse_pages(pdf_path):
    """Return {page_num: {'texts': [(text, y_center, x0, x1)], 'figures': [(x0,y0,x1,y1)],
                          'height': float, 'has_table': bool}}"""
    try:
        from pdfminer.high_level import extract_pages
        from pdfminer.layout import LAParams, LTTextBox, LTFigure, LTCurve
    except ImportError:
        print("⛔ pdfminer.six not installed. Run: pip install pdfminer.six", file=sys.stderr)
        sys.exit(1)

    laparams = LAParams(boxes_flow=0.5, char_margin=2.0)
    result = {}
    for page_num, layout in enumerate(extract_pages(pdf_path, laparams=laparams), 1):
        texts   = []
        figures = []
        curves  = []
        for el in layout:
            if isinstance(el, LTTextBox):
                t = el.get_text().strip()
                if t:
                    y_center = (el.y0 + el.y1) / 2
                    texts.append((t, y_center, el.x0, el.x1))
            elif isinstance(el, LTFigure):
                figures.append((el.x0, el.y0, el.x1, el.y1))
            elif isinstance(el, LTCurve):
                curves.append(el)
        # Detect vector table structure: ≥2 H-rules (w>50) + ≥1 V-separator (h>30)
        h_lines = [c for c in curves if (c.y1 - c.y0) < 3 and (c.x1 - c.x0) > 50]
        v_lines = [c for c in curves if (c.x1 - c.x0) < 3 and (c.y1 - c.y0) > 30]
        has_table = len(h_lines) >= 2 and len(v_lines) >= 1
        result[page_num] = {
            'texts':     texts,
            'figures':   figures,
            'height':    layout.height,
            'has_table': has_table,
        }
    return result


# ---------------------------------------------------------------------------
# pdfplumber — vector table detection and Markdown reconstruction
# ---------------------------------------------------------------------------

def detect_table_columns(page):
    """Detect explicit vertical column separators from V-edges on this pdfplumber page.
    Returns a sorted list of x-coordinates, or None if no table structure found."""
    edges   = page.edges
    v_edges = [e for e in edges if e['orientation'] == 'v' and e['height'] > 30]
    h_edges = [e for e in edges if e['orientation'] == 'h' and e['width']  > 50]
    if len(h_edges) < 2 or len(v_edges) < 1:
        return None
    # Cluster x-coordinates — snap duplicates within 3 pt
    xs = sorted(set(e['x0'] for e in v_edges))
    clustered = []
    for x in xs:
        if not clustered or x - clustered[-1] > 3:
            clustered.append(x)
    # Add left/right boundaries from the widest H-edge
    widest = max(h_edges, key=lambda e: e['width'])
    all_xs = sorted(set([widest['x0']] + clustered + [widest['x1']]))
    return all_xs if len(all_xs) >= 2 else None


def extract_tables_from_page(page):
    """Extract tables from a pdfplumber page as (bbox, markdown) tuples.
    bbox = (x0, top, x1, bottom) in pdfplumber coords."""
    col_xs = detect_table_columns(page)
    if col_xs is None:
        return []
    settings = {
        'vertical_strategy':       'explicit',
        'horizontal_strategy':     'lines',
        'explicit_vertical_lines': col_xs,
        'snap_tolerance':          6,
        'join_tolerance':          6,
        'edge_min_length':         10,
    }

    def cell(c):
        return str(c or "").replace("\n", " ").replace("|", "｜").strip()

    result = []
    try:
        for tobj in page.find_tables(table_settings=settings):
            rows = tobj.extract()
            if not rows or not any(any(c for c in row) for row in rows):
                continue
            lines = []
            lines.append("| " + " | ".join(cell(c) for c in rows[0]) + " |")
            lines.append("| " + " | ".join("---" for _ in rows[0]) + " |")
            for row in rows[1:]:
                lines.append("| " + " | ".join(cell(c) for c in row) + " |")
            result.append((tobj.bbox, "\n".join(lines)))
    except Exception:
        pass
    return result


def pdfplumber_top_to_pdfminer_y(top, page_height_pt):
    """Convert pdfplumber 'top' (origin top-left) to pdfminer y (origin bottom-left)."""
    return page_height_pt - top


# ---------------------------------------------------------------------------
# Coordinate conversion: PDF space → PIL crop box
# ---------------------------------------------------------------------------

def pdf_bbox_to_png_crop(x0, y0, x1, y1, page_height, dpi=DPI):
    """Convert a PDF LTFigure bbox to PIL crop coordinates (left, upper, right, lower)."""
    scale  = dpi / 72.0
    left   = int(x0 * scale)
    upper  = int((page_height - y1) * scale)
    right  = int(x1 * scale)
    lower  = int((page_height - y0) * scale)
    margin = int(4 * scale)
    return (
        max(0, left  - margin),
        max(0, upper - margin),
        right  + margin,
        lower  + margin,
    )


# ---------------------------------------------------------------------------
# Render a single page to PNG via pdftoppm, crop to figure bbox via Pillow
# ---------------------------------------------------------------------------

def render_and_crop(pdf_path, page_num, bbox, page_height, tmpdir):
    """Render page to PNG, crop the figure bbox, return PNG bytes."""
    try:
        from PIL import Image
    except ImportError:
        print("⛔ Pillow not installed. Run: pip install Pillow", file=sys.stderr)
        sys.exit(1)

    prefix = os.path.join(tmpdir, f"p{page_num:04d}")
    result = subprocess.run(
        ["pdftoppm", "-r", str(DPI), "-png",
         "-f", str(page_num), "-l", str(page_num),
         pdf_path, prefix],
        capture_output=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"pdftoppm failed on page {page_num}:\n{result.stderr.decode()}")

    import glob
    files = sorted(glob.glob(prefix + "*.png"))
    if not files:
        raise RuntimeError(f"No PNG produced for page {page_num}")

    img  = Image.open(files[0])
    crop = pdf_bbox_to_png_crop(*bbox, page_height, DPI)
    # Clamp to image size
    w, h = img.size
    crop = (
        min(crop[0], w), min(crop[1], h),
        min(crop[2], w), min(crop[3], h),
    )
    cropped = img.crop(crop)
    buf = io.BytesIO()
    cropped.save(buf, format="PNG")
    return buf.getvalue()


# ---------------------------------------------------------------------------
# Claude vision — describe a single figure crop
# ---------------------------------------------------------------------------

def call_claude_figure(png_bytes, page_num, fig_idx):
    """Send a single figure crop to Claude and return the [FIGURE] block."""
    b64 = base64.standard_b64encode(png_bytes).decode("utf-8")
    content = [
        {"type": "text",  "text": f"[Page {page_num}, Figure {fig_idx}]\n\n{FIGURE_PROMPT}"},
        {"type": "image", "source": {"type": "base64", "media_type": "image/png", "data": b64}},
    ]
    payload = {
        "model": "claude-opus-4-5",
        "max_tokens": 2048,
        "messages": [{"role": "user", "content": content}]
    }
    headers = {
        "x-api-key": API_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
    }
    for attempt in range(MAX_RETRIES):
        req = urllib.request.Request(
            API_URL,
            data=json.dumps(payload).encode("utf-8"),
            headers=headers,
            method="POST"
        )
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                return json.loads(resp.read().decode("utf-8"))["content"][0]["text"].strip()
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", errors="replace")
            if e.code in (429, 529) and attempt < MAX_RETRIES - 1:
                wait = 10 * (2 ** attempt)
                print(f"  HTTP {e.code} — retrying in {wait}s ...", file=sys.stderr)
                time.sleep(wait)
            else:
                raise RuntimeError(f"HTTP {e.code} p{page_num} fig{fig_idx}: {body[:300]}")


# ---------------------------------------------------------------------------
# Assemble one page: merge text blocks and figure descriptions in reading order
# ---------------------------------------------------------------------------

def assemble_page(page_num, page_data, figure_descriptions, table_entries=None):
    """
    Merge text blocks, [FIGURE] descriptions and Markdown tables sorted by Y (top-to-bottom).

    figure_descriptions : {fig_idx: description_text}
    table_entries       : list of (plumber_bbox, markdown_string)
                          bbox = (x0, top, x1, bottom) in pdfplumber coords
    """
    if table_entries is None:
        table_entries = []

    elements = []   # (y_center, kind, content, x0, x1)

    for text, y_center, x0, x1 in page_data['texts']:
        elements.append((y_center, 'text', text, x0, x1))

    for fig_idx, (fx0, fy0, fx1, fy1) in enumerate(page_data['figures'], 1):
        y_center_fig = (fy0 + fy1) / 2
        desc = figure_descriptions.get(fig_idx, f"[FIGURE {fig_idx} — description unavailable]")
        elements.append((y_center_fig, 'figure', desc, fx0, fx1))

    # Insert table blocks + record their Y-ranges for text deduplication
    table_y_ranges = []
    page_height_pt = page_data['height']
    for (tx0, t_top, tx1, t_bottom), md in table_entries:
        y_min_pm = pdfplumber_top_to_pdfminer_y(t_bottom, page_height_pt)
        y_max_pm = pdfplumber_top_to_pdfminer_y(t_top,    page_height_pt)
        y_center_pm = (y_min_pm + y_max_pm) / 2
        table_y_ranges.append((y_min_pm, y_max_pm))
        elements.append((y_center_pm, 'table', md, tx0, tx1))

    # Suppress text blocks whose y_center falls inside a table bounding box
    def is_inside_table(y_center):
        return any(y_min <= y_center <= y_max for (y_min, y_max) in table_y_ranges)

    filtered = [
        el for el in elements
        if not (el[1] == 'text' and is_inside_table(el[0]))
    ]

    # Sort top-to-bottom (highest PDF y first)
    filtered.sort(key=lambda e: e[0], reverse=True)

    blocks = [content for (_, _, content, _, _) in filtered]
    body   = "\n\n".join(blocks)
    return f"=== PAGE {page_num} ===\n{body}\n=== END PAGE {page_num} ==="


# ---------------------------------------------------------------------------
# Phase 2.5 — Cross-reference pass
# ---------------------------------------------------------------------------

# Identifiers to ignore even if they match the extraction pattern:
# single letters used as generic variables, Greek letters spelled out, and
# common structural-engineering stopwords.
_XREF_STOPWORDS = {
    "N", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L",
    "M", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "kN", "mm", "cm", "m", "kg", "kPa", "MPa", "GPa", "kNm",
    "Figure", "Table", "Clause", "Section", "Annex", "NOTE", "Fig",
}

# Minimum length for an identifier to be considered (avoids noise like "a1")
_XREF_MIN_LEN = 2


def parse_identifiers(description: str) -> list:
    """Extract the IDENTIFIERS JSON array from a [FIGURE] description block.

    Returns a de-duplicated, filtered list of identifier strings.
    Falls back to regex extraction if the JSON line is absent or malformed.
    """
    ids = []

    # 1. Try the structured IDENTIFIERS: [...] line
    m = re.search(r'^IDENTIFIERS:\s*(\[.*?\])\s*$', description, re.MULTILINE)
    if m:
        try:
            raw = json.loads(m.group(1))
            ids = [str(x).strip() for x in raw if str(x).strip()]
        except json.JSONDecodeError:
            pass

    # 2. Fallback: scan the description for plausible identifiers
    #    Pattern: 2+ chars, at least one letter, mix of letters/digits/hyphens
    if not ids:
        ids = re.findall(r'\b([A-Za-z][A-Za-z0-9\-_]{1,19})\b', description)

    # 3. Filter
    seen = set()
    result = []
    for ident in ids:
        if ident in _XREF_STOPWORDS:
            continue
        if len(ident) < _XREF_MIN_LEN:
            continue
        if ident.lower() in seen:
            continue
        seen.add(ident.lower())
        result.append(ident)

    return result


def find_text_occurrences(identifier: str, page_texts: dict) -> list:
    """Search all text blocks for occurrences of *identifier* as a whole word.

    Returns a list of (page_num, snippet) tuples, one per matching text block.
    The snippet is ≤ 120 chars centred on the first match in the block.
    """
    pattern = re.compile(r'\b' + re.escape(identifier) + r'\b')
    results = []
    for page_num in sorted(page_texts):
        for entry in page_texts[page_num]:
            block_text = entry[0]   # texts tuple: (text, y_center, x0, x1)
            m = pattern.search(block_text)
            if m:
                start = max(0, m.start() - 55)
                end   = min(len(block_text), m.end() + 55)
                snippet = block_text[start:end].replace('\n', ' ').strip()
                if start > 0:
                    snippet = '…' + snippet
                if end < len(block_text):
                    snippet = snippet + '…'
                results.append((page_num, snippet))
    return results


def _fmt_occ(occurrences: list) -> str:
    """Format occurrence list as a compact multi-line string for the XREF block."""
    if not occurrences:
        return "    (no occurrence found in text)"
    lines = []
    for page_num, snippet in occurrences:
        lines.append(f"    p.{page_num}: {snippet}")
    return '\n'.join(lines)


def xref_pass(all_figure_descs: dict, page_texts: dict) -> tuple:
    """Run the full cross-reference pass.

    Parameters
    ----------
    all_figure_descs : {(page_num, fig_idx): description_text}
    page_texts       : {page_num: [(text_block, y_center), ...]}  (from analyse_pages)

    Returns
    -------
    (annotated_descs, xref_index_block)

    annotated_descs   : same keys as all_figure_descs, descriptions now include
                        a [XREF FIGURE N] annotation appended after [END FIGURE N]
    xref_index_block  : string — the global === XREF INDEX === section
    """
    annotated = {}
    # Global index: {identifier: [(page_num, fig_idx, occurrences), ...]}
    global_index = {}

    for (page_num, fig_idx), desc in all_figure_descs.items():
        identifiers = parse_identifiers(desc)
        if not identifiers:
            annotated[(page_num, fig_idx)] = desc
            continue

        xref_lines = [f"[XREF FIGURE {fig_idx} — page {page_num}]"]
        for ident in identifiers:
            occs = find_text_occurrences(ident, page_texts)
            xref_lines.append(f"  {ident}:")
            xref_lines.append(_fmt_occ(occs))
            # Accumulate in global index
            global_index.setdefault(ident, []).append((page_num, fig_idx, occs))
        xref_lines.append(f"[END XREF FIGURE {fig_idx}]")

        # Append the XREF annotation to the description, after [END FIGURE …]
        annotated_desc = re.sub(
            r'(\[END FIGURE[^\]]*\])',
            r'\1\n' + '\n'.join(xref_lines),
            desc,
            count=1
        )
        # If [END FIGURE] marker is absent (malformed), just append
        if annotated_desc == desc:
            annotated_desc = desc + '\n' + '\n'.join(xref_lines)
        annotated[(page_num, fig_idx)] = annotated_desc

    # Build the global XREF INDEX block
    index_lines = ["=== XREF INDEX ===",
                   "# Cross-reference: identifiers found in figures → text occurrences",
                   ""]
    for ident in sorted(global_index):
        entries = global_index[ident]
        all_occs_flat = []
        fig_refs = []
        for page_num, fig_idx, occs in entries:
            fig_refs.append(f"Figure {fig_idx} (p.{page_num})")
            all_occs_flat.extend(occs)
        index_lines.append(f"## {ident}")
        index_lines.append(f"   Appears in: {', '.join(fig_refs)}")
        if all_occs_flat:
            # De-duplicate occurrences by page
            seen_pages = set()
            for p, snip in all_occs_flat:
                if p not in seen_pages:
                    index_lines.append(f"   Text occurrence (p.{p}): {snip}")
                    seen_pages.add(p)
        else:
            index_lines.append("   Text occurrence: (none found)")
        index_lines.append("")
    index_lines.append("=== END XREF INDEX ===")

    return annotated, '\n'.join(index_lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    # Check pdfplumber availability (optional — graceful fallback)
    try:
        import pdfplumber as _pdfplumber
        HAS_PDFPLUMBER = True
    except ImportError:
        HAS_PDFPLUMBER = False
        print("[chorus-pdf] ⚠️  pdfplumber not available — vector tables will not be reconstructed",
              file=sys.stderr)

    if not API_KEY:
        print("⛔ ANTHROPIC_API_KEY not set", file=sys.stderr)
        sys.exit(1)

    print("[chorus-pdf] Hybrid mode — analysing layout ...", file=sys.stderr)
    pages = analyse_pages(PDF_PATH)
    total      = len(pages)
    n_with_fig = sum(1 for p in pages.values() if p['figures'])
    n_figs     = sum(len(p['figures']) for p in pages.values())
    n_with_tbl = sum(1 for p in pages.values() if p['has_table'])
    print(f"[chorus-pdf]   → {total} pages, {n_with_fig} with figures, "
          f"{n_figs} figure(s), {n_with_tbl} page(s) with tables",
          file=sys.stderr)

    # --- nohup gate -----------------------------------------------------------
    NOHUP_THRESHOLD = 15
    force = os.environ.get("CHORUS_PDF_FORCE", "") == "1"
    if n_figs > NOHUP_THRESHOLD and not force:
        print(
            f"[chorus-pdf] ⚠️  {n_figs} figures detected — estimated time "
            f"~{n_figs * 30 // 60}–{n_figs * 45 // 60} min "
            f"(threshold: {NOHUP_THRESHOLD}).\n"
            f"[chorus-pdf]    Run with nohup to avoid a 10-min IDE timeout:\n"
            f"[chorus-pdf]    CHORUS_PDF_FORCE=1 nohup python3 {os.path.abspath(__file__)} "
            f"> {OUTPUT_PATH}.log 2>&1 &",
            file=sys.stderr
        )
        sys.exit(2)   # exit code 2 = "nohup required" (not an error)
    elif n_figs > NOHUP_THRESHOLD and force:
        print(
            f"[chorus-pdf] ⚠️  {n_figs} figures — CHORUS_PDF_FORCE=1 → proceeding without gate.",
            file=sys.stderr
        )
    # --------------------------------------------------------------------------

    parts = []
    all_figure_descs = {}
    total_tables = 0

    # Open pdfplumber once for the main extraction loop
    import pdfplumber as pdfplumber_mod
    plumber_pdf = pdfplumber_mod.open(PDF_PATH) if HAS_PDFPLUMBER else None

    with tempfile.TemporaryDirectory(prefix="chorus-pdf-") as tmpdir:
        for page_num in sorted(pages):
            page_data = pages[page_num]

            # --- Table extraction (pdfplumber) ---
            table_entries = []
            if plumber_pdf and page_data['has_table']:
                table_entries = extract_tables_from_page(plumber_pdf.pages[page_num - 1])
                if table_entries:
                    total_tables += len(table_entries)
                    print(f"[chorus-pdf] Page {page_num} — {len(table_entries)} table(s) extracted",
                          file=sys.stderr)

            # --- Figure extraction (Claude vision) ---
            if page_data['figures']:
                print(f"[chorus-pdf] Page {page_num} — {len(page_data['figures'])} figure(s) ...",
                      file=sys.stderr)
                for fig_idx, bbox in enumerate(page_data['figures'], 1):
                    png_bytes = render_and_crop(PDF_PATH, page_num, bbox,
                                               page_data['height'], tmpdir)
                    desc = call_claude_figure(png_bytes, page_num, fig_idx)
                    all_figure_descs[(page_num, fig_idx)] = desc
                    print(f"[chorus-pdf]   fig {fig_idx} → {len(desc)} chars", file=sys.stderr)
            elif not table_entries:
                print(f"[chorus-pdf] Page {page_num} — text only (pdfminer)", file=sys.stderr)

    if plumber_pdf:
        plumber_pdf.close()

    # --- Phase 2.5 — Cross-reference pass ------------------------------------
    if all_figure_descs:
        print("[chorus-pdf] Phase 2.5 — cross-reference pass ...", file=sys.stderr)
        page_texts = {pn: pd['texts'] for pn, pd in pages.items()}
        annotated_descs, xref_index = xref_pass(all_figure_descs, page_texts)
        total_xref = sum(len(parse_identifiers(d)) for d in all_figure_descs.values())
        print(f"[chorus-pdf]   → {total_xref} identifier(s) cross-referenced", file=sys.stderr)
    else:
        annotated_descs = {}
        xref_index = None

    # --- Assemble pages -------------------------------------------------------
    per_page_figs = {}
    for (page_num, fig_idx), desc in annotated_descs.items():
        per_page_figs.setdefault(page_num, {})[fig_idx] = desc

    # Re-open pdfplumber for assembly pass (table_entries needed per page)
    plumber_pdf2 = pdfplumber_mod.open(PDF_PATH) if HAS_PDFPLUMBER else None

    for page_num in sorted(pages):
        page_data = pages[page_num]
        figure_descriptions = per_page_figs.get(page_num, {})
        table_entries = []
        if plumber_pdf2 and page_data['has_table']:
            table_entries = extract_tables_from_page(plumber_pdf2.pages[page_num - 1])
        page_block = assemble_page(page_num, page_data, figure_descriptions, table_entries)
        parts.append(page_block)

    if plumber_pdf2:
        plumber_pdf2.close()

    if xref_index:
        parts.append(xref_index)

    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        f.write("\n\n".join(parts))
    print(f"[chorus-pdf] ✅ {total} pages, {n_figs} figure(s), {total_tables} table(s) — "
          f"Written to {OUTPUT_PATH}", file=sys.stderr)


if __name__ == "__main__":
    main()
```

> ⚠️ **Dependencies**: `pip install pdfminer.six pypdf Pillow pdfplumber`
>
> ⚠️ **`pdftoppm` required**: `sudo apt install poppler-utils`
>
> ⚠️ **API key**: `export ANTHROPIC_API_KEY="sk-ant-..."`
>
> ℹ️ **API calls**: 1 call per `LTFigure` element (not per page) — maximally targeted.
> A 30-page document with 8 figures = 8 API calls, regardless of page count.
>
> ℹ️ **Vector tables**: detected automatically on every page via `LTCurve` heuristic.
> `pdfplumber` is used to reconstruct them as Markdown pipe tables, with column
> separators derived from the V-edges of the PDF. Falls back gracefully if
> `pdfplumber` is unavailable (tables suppressed, text dumped in Y-order).

---

### Script template — Auto mode (`--auto`)

Classifies pages first. Text-only pages use `pdfminer`. Pages with figures use
`pdftoppm` + Claude vision. Only figure pages consume API tokens.
Output: `<NNN>-<slug>-vision.md`

```python
#!/usr/bin/env python3
"""
chorus-pdf extraction script — auto mode (--auto)
Generated by chorus-pdf skill
Sandbox : <sandbox-name>
Source  : <input-pdf-path>
Output  : <output-md-path>    (e.g. corpus/003-uk-approved-doc-a-2013-vision.md)
Pages   : <total-pages>  (<N-text> text, <N-vision> vision)
"""

import sys
import base64
import json
import glob
import re
import time
import tempfile
import subprocess
import urllib.request
import urllib.error
import os

PDF_PATH    = "<input-pdf-path>"
OUTPUT_PATH = "<output-txt-path>"
CHUNK_SIZE  = 5
DPI         = 150
MAX_RETRIES = 4
API_KEY     = os.environ.get("ANTHROPIC_API_KEY", "")
API_URL     = "https://api.anthropic.com/v1/messages"

PROMPT = """<verbatim vision extraction prompt — see Phase 2>"""


# ---------------------------------------------------------------------------
# Page classification
# ---------------------------------------------------------------------------

def classify_pages(pdf_path):
    """Return {page_num: 'text'|'vision'} for all pages."""
    try:
        import pypdf
    except ImportError:
        print("⛔ pypdf not installed. Run: pip install pypdf", file=sys.stderr)
        sys.exit(1)

    reader = pypdf.PdfReader(pdf_path)
    result = {}
    for i, page in enumerate(reader.pages, 1):
        text      = page.extract_text() or ""
        has_image = len(page.images) > 0
        has_text  = len(text.strip()) > 50
        result[i] = 'vision' if (has_image or not has_text) else 'text'
    return result


# ---------------------------------------------------------------------------
# Text extraction — pdfminer
# ---------------------------------------------------------------------------

def extract_text_page(pdf_path, page_num):
    """Extract text from a single page using pdfminer."""
    try:
        from pdfminer.high_level import extract_pages
        from pdfminer.layout import LAParams, LTTextBox
    except ImportError:
        print("⛔ pdfminer.six not installed. Run: pip install pdfminer.six", file=sys.stderr)
        sys.exit(1)

    laparams = LAParams(boxes_flow=0.5, char_margin=2.0)
    blocks = []
    for pnum, layout in enumerate(extract_pages(pdf_path, laparams=laparams), 1):
        if pnum == page_num:
            for el in layout:
                if isinstance(el, LTTextBox):
                    t = el.get_text().strip()
                    if t:
                        blocks.append(t)
            break
    return "\n".join(blocks)


# ---------------------------------------------------------------------------
# Vision extraction — pdftoppm + Claude
# ---------------------------------------------------------------------------

def render_page(pdf_path, page_num, tmpdir):
    """Render a single PDF page to PNG via pdftoppm."""
    prefix = os.path.join(tmpdir, f"p{page_num:04d}")
    result = subprocess.run(
        ["pdftoppm", "-r", str(DPI), "-png",
         "-f", str(page_num), "-l", str(page_num),
         pdf_path, prefix],
        capture_output=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"pdftoppm failed on page {page_num}:\n{result.stderr.decode()}")
    files = sorted(glob.glob(prefix + "*.png"))
    if not files:
        raise RuntimeError(f"No PNG produced for page {page_num}")
    return files[0]


def image_to_b64(path):
    with open(path, "rb") as f:
        return base64.standard_b64encode(f.read()).decode("utf-8")


def call_claude(pages_with_pngs):
    """Send a chunk of (page_num, png_path) pairs to Claude vision.
    Returns the raw text response."""
    content = []
    for page_num, path in pages_with_pngs:
        content.append({
            "type": "text",
            "text": f"[Processing page {page_num}]\n\n{PROMPT}"
        })
        content.append({
            "type": "image",
            "source": {
                "type": "base64",
                "media_type": "image/png",
                "data": image_to_b64(path)
            }
        })

    payload = {
        "model": "claude-opus-4-5",
        "max_tokens": 8192,
        "messages": [{"role": "user", "content": content}]
    }
    headers = {
        "x-api-key": API_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
    }
    label = f"{pages_with_pngs[0][0]}-{pages_with_pngs[-1][0]}"
    for attempt in range(MAX_RETRIES):
        req = urllib.request.Request(
            API_URL,
            data=json.dumps(payload).encode("utf-8"),
            headers=headers,
            method="POST"
        )
        try:
            with urllib.request.urlopen(req, timeout=300) as resp:
                return json.loads(resp.read().decode("utf-8"))["content"][0]["text"]
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", errors="replace")
            if e.code in (429, 529) and attempt < MAX_RETRIES - 1:
                wait = 10 * (2 ** attempt)
                print(f"  HTTP {e.code} — retrying in {wait}s ...", file=sys.stderr)
                time.sleep(wait)
            else:
                raise RuntimeError(f"HTTP {e.code} on pages {label}: {body[:500]}")


def split_page_markers(text, expected_pages):
    """Parse Claude's response into {page_num: page_block}.
    Falls back gracefully if markers are absent."""
    result = {}
    matches = list(re.finditer(
        r'(=== PAGE (\d+) ===.*?=== END PAGE \d+ ===)', text, re.DOTALL
    ))
    if matches:
        for m in matches:
            pnum = int(m.group(2))
            result[pnum] = m.group(1)
    else:
        # No markers — assign full response to first page
        result[expected_pages[0]] = (
            f"=== PAGE {expected_pages[0]} ===\n{text.strip()}\n"
            f"=== END PAGE {expected_pages[0]} ==="
        )
    # Fill any missing pages with a warning block
    for p in expected_pages:
        if p not in result:
            result[p] = (
                f"=== PAGE {p} ===\n"
                f"[WARNING: page {p} not found in Claude response]\n"
                f"=== END PAGE {p} ==="
            )
    return result


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    if not API_KEY:
        print("⛔ ANTHROPIC_API_KEY not set", file=sys.stderr)
        sys.exit(1)

    print("[chorus-pdf] Auto mode — classifying pages ...", file=sys.stderr)
    classification = classify_pages(PDF_PATH)
    text_pages   = sorted(p for p, t in classification.items() if t == 'text')
    vision_pages = sorted(p for p, t in classification.items() if t == 'vision')
    total = len(classification)
    print(f"[chorus-pdf]   → {len(text_pages)}/{total} text-only pages  (pdfminer)", file=sys.stderr)
    print(f"[chorus-pdf]   → {len(vision_pages)}/{total} pages with figures (vision LLM)", file=sys.stderr)

    results = {}

    # --- Text pages ---
    if text_pages:
        print("[chorus-pdf] Extracting text pages ...", file=sys.stderr)
        for pnum in text_pages:
            text = extract_text_page(PDF_PATH, pnum)
            results[pnum] = (
                f"=== PAGE {pnum} ===\n{text}\n=== END PAGE {pnum} ==="
            )

    # --- Vision pages ---
    if vision_pages:
        chunks = [
            vision_pages[i:i+CHUNK_SIZE]
            for i in range(0, len(vision_pages), CHUNK_SIZE)
        ]
        print(f"[chorus-pdf] Processing vision pages — {len(chunks)} chunk(s) ...", file=sys.stderr)
        with tempfile.TemporaryDirectory(prefix="chorus-pdf-") as tmpdir:
            for cidx, chunk in enumerate(chunks, 1):
                label = f"{chunk[0]}-{chunk[-1]}"
                print(f"[chorus-pdf] Vision chunk {cidx}/{len(chunks)} (pages {label}) ...",
                      file=sys.stderr)
                pages_with_pngs = [
                    (pnum, render_page(PDF_PATH, pnum, tmpdir))
                    for pnum in chunk
                ]
                response = call_claude(pages_with_pngs)
                parsed   = split_page_markers(response, chunk)
                results.update(parsed)
                print(f"[chorus-pdf]   → {sum(len(t) for t in parsed.values())} chars",
                      file=sys.stderr)

    # --- Assemble in page order ---
    parts = [results[p] for p in sorted(results)]
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        f.write("\n\n".join(parts))
    print(f"[chorus-pdf] ✅ Written to {OUTPUT_PATH}", file=sys.stderr)


if __name__ == "__main__":
    main()
```

> ⚠️ **Dependencies**: `pip install pdfminer.six pypdf`
>
> ⚠️ **`pdftoppm` required**: `sudo apt install poppler-utils`
>
> ⚠️ **API key**: `export ANTHROPIC_API_KEY="sk-ant-..."`

---

### Script template — Images mode (`--images`)

All pages rendered to PNG at 150 DPI via `pdftoppm`, submitted to Claude vision.
Use when the document is mostly diagrams or scanned.
Output: `<NNN>-<slug>-vision.md`

```python
#!/usr/bin/env python3
"""
chorus-pdf extraction script — images mode (--images)
Generated by chorus-pdf skill
Sandbox : <sandbox-name>
Source  : <input-pdf-path>
Output  : <output-md-path>    (e.g. corpus/003-uk-approved-doc-a-2013-vision.md)
Pages   : <total-pages>
DPI     : 150
"""

import sys
import base64
import json
import glob
import re
import time
import tempfile
import subprocess
import urllib.request
import urllib.error
import os

PDF_PATH    = "<input-pdf-path>"
OUTPUT_PATH = "<output-txt-path>"
CHUNK_SIZE  = 5
DPI         = 150
MAX_RETRIES = 4
API_KEY     = os.environ.get("ANTHROPIC_API_KEY", "")
API_URL     = "https://api.anthropic.com/v1/messages"

PROMPT = """<verbatim vision extraction prompt — see Phase 2>"""


def render_pages(pdf_path, tmpdir):
    """Render all PDF pages to PNG files using pdftoppm."""
    prefix = os.path.join(tmpdir, "page")
    result = subprocess.run(
        ["pdftoppm", "-r", str(DPI), "-png", pdf_path, prefix],
        capture_output=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"pdftoppm failed:\n{result.stderr.decode()}")
    pages = sorted(glob.glob(os.path.join(tmpdir, "page-*.png")))
    if not pages:
        pages = sorted(glob.glob(os.path.join(tmpdir, "page.*.png")))
    if not pages:
        raise RuntimeError("pdftoppm produced no PNG files — is the PDF password-protected?")
    return pages


def image_to_b64(path):
    with open(path, "rb") as f:
        return base64.standard_b64encode(f.read()).decode("utf-8")


def call_claude(page_paths, page_offset):
    """Send a chunk of page PNGs to Claude vision."""
    content = []
    for i, path in enumerate(page_paths):
        page_num = page_offset + i + 1
        content.append({
            "type": "text",
            "text": f"[Processing page {page_num}]\n\n{PROMPT}"
        })
        content.append({
            "type": "image",
            "source": {
                "type": "base64",
                "media_type": "image/png",
                "data": image_to_b64(path)
            }
        })

    payload = {
        "model": "claude-opus-4-5",
        "max_tokens": 8192,
        "messages": [{"role": "user", "content": content}]
    }
    headers = {
        "x-api-key": API_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
    }
    label = f"{page_offset+1}-{page_offset+len(page_paths)}"
    for attempt in range(MAX_RETRIES):
        req = urllib.request.Request(
            API_URL,
            data=json.dumps(payload).encode("utf-8"),
            headers=headers,
            method="POST"
        )
        try:
            with urllib.request.urlopen(req, timeout=300) as resp:
                return json.loads(resp.read().decode("utf-8"))["content"][0]["text"]
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", errors="replace")
            if e.code in (429, 529) and attempt < MAX_RETRIES - 1:
                wait = 10 * (2 ** attempt)
                print(f"  HTTP {e.code} — retrying in {wait}s ...", file=sys.stderr)
                time.sleep(wait)
            else:
                raise RuntimeError(f"HTTP {e.code} on pages {label}: {body[:500]}")


def main():
    if not API_KEY:
        print("⛔ ANTHROPIC_API_KEY not set", file=sys.stderr)
        sys.exit(1)

    r = subprocess.run(["pdftoppm", "--help"], capture_output=True)
    if r.returncode not in (0, 99):
        print("⛔ pdftoppm not found. Install: sudo apt install poppler-utils", file=sys.stderr)
        sys.exit(1)

    with tempfile.TemporaryDirectory(prefix="chorus-pdf-") as tmpdir:
        print(f"[chorus-pdf] Rendering pages at {DPI} DPI ...", file=sys.stderr)
        pages  = render_pages(PDF_PATH, tmpdir)
        total  = len(pages)
        chunks = [pages[i:i+CHUNK_SIZE] for i in range(0, total, CHUNK_SIZE)]
        print(f"[chorus-pdf] {total} pages → {len(chunks)} chunk(s) of {CHUNK_SIZE}",
              file=sys.stderr)

        all_text = []
        for idx, chunk in enumerate(chunks):
            start = idx * CHUNK_SIZE
            label = f"{start+1}-{start+len(chunk)}"
            print(f"[chorus-pdf] Chunk {idx+1}/{len(chunks)} (pages {label}) ...",
                  file=sys.stderr)
            text = call_claude(chunk, start)
            all_text.append(text)
            print(f"[chorus-pdf]   → {len(text)} chars", file=sys.stderr)

    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        f.write("\n\n".join(all_text))
    print(f"[chorus-pdf] ✅ Written to {OUTPUT_PATH}", file=sys.stderr)


if __name__ == "__main__":
    main()
```

> ⚠️ **Dependencies**: `pip install pypdf`
>
> ⚠️ **`pdftoppm` required**: `sudo apt install poppler-utils`
>
> ⚠️ **API key**: `export ANTHROPIC_API_KEY="sk-ant-..."`

---

## Phase 2.5 — Cross-reference pass (hybrid mode only)

After all figure descriptions have been obtained from Claude (Phase 2), and **before**
assembling the final Markdown output, the hybrid script runs an automatic cross-reference
pass at no extra API cost. This pass links identifiers visible in figures to their
occurrences in the surrounding text.

### 2.5.1 — Collect identifiers from figures

For each `[FIGURE N]` block, parse the `IDENTIFIERS: [...]` JSON line appended by
Claude (see `FIGURE_PROMPT`). Each item is an alphanumeric code, label, callout tag,
part number, or element ID as printed in the figure.

Filtering rules applied by `parse_identifiers()`:
- Remove entries in `_XREF_STOPWORDS` (single letters, unit abbreviations, structural-engineering stopwords)
- Remove entries shorter than `_XREF_MIN_LEN = 2`
- De-duplicate case-insensitively
- Fallback: if the `IDENTIFIERS:` line is absent or malformed, scan the description
  body with the regex `[A-Za-z][A-Za-z0-9\-_]{1,19}` and apply the same filters

### 2.5.2 — Search text occurrences

For each identifier, `find_text_occurrences()` searches all `page_texts` blocks
(the raw pdfminer text extracted in `analyse_pages`) using a whole-word regex
`\bIDENTIFIER\b`. For each matching block, a ≤ 120-char snippet centred on the match
is recorded along with its page number.

### 2.5.3 — Annotate figure descriptions

A `[XREF FIGURE N]` block is appended immediately after each `[END FIGURE N]` marker:

```
[XREF FIGURE 3 — page 12]
  M-001:
    p.12: …The member M-001 shall be designed for…
    p.14: …see M-001 in the elevation detail…
  Z-A2:
    (no occurrence found in text)
[END XREF FIGURE 3]
```

This annotation is embedded in the page block, immediately following the figure it
annotates, so `chorus-feed` picks it up as part of the same semantic unit.

### 2.5.4 — Append global XREF INDEX

After all page blocks, a global index is appended at the end of the `-vision.md` file:

```
=== XREF INDEX ===
# Cross-reference: identifiers found in figures → text occurrences

## M-001
   Appears in: Figure 3 (p.12), Figure 7 (p.24)
   Text occurrence (p.12): …The member M-001 shall be designed for…
   Text occurrence (p.22): …load path through M-001 and M-002…

## Z-A2
   Appears in: Figure 3 (p.12)
   Text occurrence: (none found)

=== END XREF INDEX ===
```

This index gives `chorus-feed` a ready-made cross-reference map: it can create YAML
slots that link a figure-designated component to the normative text clauses that define
or constrain it.

### 2.5 — Output format summary

| Section | Location in output | Purpose |
|---|---|---|
| `[XREF FIGURE N]` block | Inline, after each `[END FIGURE N]` | Local annotation — kept with the figure for `chorus-feed` |
| `=== XREF INDEX ===` | End of file | Global map — all identifiers with all occurrences |

> ⚠️ **Hybrid mode only** — the cross-reference pass requires both the pdfminer text
> blocks (`page_texts`) and the Claude figure descriptions to be available
> simultaneously. It is not implemented in `--auto` or `--images` modes (those modes
> do not retain separate text blocks after page-level vision processing).

---

## Phase 3 — Execute and validate

### 3.1 Execute the script

```bash
python3 "$SANDBOX/agent/extract-pdf-<slug>.py"
```

Capture stderr for progress reporting. Exit code 0 = success.

### 3.2 Validate the output

```bash
python3 - "$SANDBOX/corpus/<NNN>-<slug>-vision.txt" <<'EOF'
import sys, re

path = sys.argv[1]
text = open(path, encoding="utf-8").read()
pages        = re.findall(r'=== PAGE \d+ ===', text)
figures      = re.findall(r'\[FIGURE', text)
tables       = re.findall(r'^\|', text, re.MULTILINE)
placeholders = text.count('not extracted')
xref_local   = re.findall(r'\[XREF FIGURE', text)
xref_index   = 1 if '=== XREF INDEX ===' in text else 0

print(f"Pages found      : {len(pages)}")
print(f"Figures found    : {len(figures)}")
print(f"XREF annotations : {len(xref_local)}  (inline, hybrid mode)")
print(f"XREF INDEX       : {'present' if xref_index else 'absent'}")
print(f"Table rows       : {len(tables)}")
print(f"Placeholders     : {placeholders}")
print(f"Total chars      : {len(text)}")
if len(pages) == 0:
    print("⚠️  WARNING: no === PAGE === markers — output may be malformed")
if len(text) < 500:
    print("⚠️  WARNING: output is suspiciously short")
if placeholders > 0:
    print(f"ℹ️  {placeholders} figure(s) not extracted — run with --auto to extract them")
if len(figures) > 0 and len(xref_local) == 0:
    print("ℹ️  Figures found but no XREF annotations — check IDENTIFIERS: lines in figure descriptions")
EOF
```

Report the sanity check results to the user before proceeding.

### 3.3 Failure handling

| Symptom | Likely cause | Action |
|---------|-------------|--------|
| `pdfminer.six` ImportError | Missing dependency | `pip install pdfminer.six` |
| `pypdf` ImportError | Missing dependency | `pip install pypdf` |
| `Pillow` ImportError | Missing dependency (`--hybrid`) | `pip install Pillow` |
| `pdftoppm` not found | `poppler-utils` absent | `sudo apt install poppler-utils` |
| `ANTHROPIC_API_KEY not set` | Missing env var | `export ANTHROPIC_API_KEY="sk-ant-..."` |
| HTTP 400 | PDF chunk too large | Reduce `CHUNK_SIZE` to 3 |
| HTTP 429 / 529 | API rate limit / overload | Retry handled automatically (exponential backoff) |
| No PNG files rendered | Password-protected PDF | Decrypt first: `qpdf --decrypt in.pdf out.pdf` |
| Output < 500 chars | Extraction returned nothing | Check API key validity; verify PDF is not encrypted |
| Figures described but values wrong | Dense diagram | Increase `DPI = 200` in script header; keep `CHUNK_SIZE = 3` |
| Text mode: garbled multi-column | pdfminer layout | Normal on very complex layouts — use `--auto` instead |
| Auto mode: page miscategorised | `pypdf` image detection | Force individual pages to vision by adjusting text threshold in `classify_pages` |

---

## Phase 4 — Update sandbox metadata

### 4.1 Update `README.org`

Add a row for the new file in the `Corpus` table:

```org
| <NNN> | corpus/<NNN>-<slug>-text.txt   | pdfminer from <source-pdf>                    | <date> |
| <NNN> | corpus/<NNN>-<slug>-vision.md  | hybrid(pdfminer+cropped vision) from <source> | <date> |
| <NNN> | corpus/<NNN>-<slug>-vision.md  | auto(pdfminer+vision) from <source>           | <date> |
| <NNN> | corpus/<NNN>-<slug>-vision.md  | vision(LLM) from <source-pdf>                 | <date> |
```

(use the row matching the mode used)

Do **not** remove the row for the original PDF or any prior file — all versions are
kept for traceability.

### 4.2 Report to the user

```
✅ chorus-pdf completed
   Mode     : text  (or: auto — 38 text / 16 vision  |  images — 150 DPI)
   Source   : corpus/<source.pdf>  (<N> pages)
   Output   : corpus/<NNN>-<slug>-text.txt   (or: -vision.md)
   Pages    : <N>
   Figures  : <N> blocks extracted  (or: <N> placeholders — use --hybrid or --auto to extract)
   XREF     : <N> identifier(s) cross-referenced across <N> figure(s)  [hybrid only]
   Table rows: <N>
   Size     : <N> chars

   Next step: chorus-feed <sandbox-name> corpus/<NNN>-<slug>-text.txt
              (or: corpus/<NNN>-<slug>-vision.md)
```

---

## Integration with chorus-feed

`chorus-pdf` is a **pre-processing step**, not a replacement for `chorus-feed`.
Typical workflow:

```
# No flag — hybrid activated automatically if API key present (DEFAULT)
chorus-pdf  <sandbox> corpus/002-uk-approved-doc-a-2013.pdf
→ corpus/003-uk-approved-doc-a-2013-vision.md   (hybrid mode)

# No API key — text mode fallback
chorus-pdf  <sandbox> corpus/002-uk-approved-doc-a-2013.pdf
→ corpus/003-uk-approved-doc-a-2013-text.txt

# API key available — text-dominant document, faster
chorus-pdf  <sandbox> corpus/002-uk-approved-doc-a-2013.pdf --auto
→ corpus/003-uk-approved-doc-a-2013-vision.md

# Mostly diagrams or scanned PDF
chorus-pdf  <sandbox> corpus/002-uk-approved-doc-a-2013.pdf --images
→ corpus/003-uk-approved-doc-a-2013-vision.md

# Then in all cases:
chorus-feed <sandbox> corpus/003-uk-approved-doc-a-2013-text.txt
            (or: corpus/003-uk-approved-doc-a-2013-vision.md)
```

If a `.txt` from `pdftotext` already exists alongside the PDF, prefer the `-text.txt`
(text mode) or `-vision.md` (hybrid/auto/images) for `chorus-feed`.
The `pdftotext` output can be kept for diff/audit purposes.

---

## Quick Reference — Naming Conventions

| Artifact | Convention | Example |
|----------|-----------|---------|
| Extraction script | `agent/extract-pdf-<slug>.py` | `agent/extract-pdf-uk-approved-doc-a.py` |
| Text mode output | `corpus/<NNN>-<slug>-text.txt` | `corpus/003-uk-approved-doc-a-2013-text.txt` |
| Auto/Hybrid/Images output | `corpus/<NNN>-<slug>-vision.md` | `corpus/003-uk-approved-doc-a-2013-vision.md` |
| Original PDF | kept as-is in `corpus/` | `corpus/002-uk-approved-doc-a-2013.pdf` |

---

## Troubleshooting

**"The output in text mode is identical to what pdftotext produced"**
→ Both tools read the same embedded text layer. The gain from pdfminer is the layout
  ordering (multi-column), not the character content. For richer extraction, use `--auto`.

**"Text mode output has garbled column order"**
→ `pdfminer` uses `boxes_flow=0.5` which handles most two-column layouts. For unusual
  layouts (three columns, overlapping regions), `--auto` or `--images` will be more
  reliable since Claude reconstructs column order visually.

**"Figures are described but values seem invented"**
→ LLMs can hallucinate values in dense technical diagrams. Always cross-check critical
  normative values against the original PDF. Mark uncertain values with
  `# TODO: verify against PDF §<N>` in `Helpers.pm`.

**"Auto mode: a text page was sent to vision unnecessarily"**
→ The threshold `len(text.strip()) > 50` in `classify_pages` may be too low for sparse
  pages (cover pages, blank pages, page numbers only). Increase to `> 200` if needed.

**"Chunk boundaries cut through a table"**
→ The fragment is prefixed `[TABLE CONTINUED — ...]`. `chorus-feed` treats both
  fragments as separate text blocks — rarely an issue for KB extraction.

**"Too slow — 54-page PDF with --auto takes a long time"**
→ Only the vision pages hit the API. If 16/54 pages have figures: 4 chunks × ~30s = ~2 min.
  The text pages (pdfminer) complete in seconds. Total: ~2–3 minutes for a 54-page standard.

**"Script exited with code 2 — nohup required"**
→ The layout analysis detected ≥ 16 figures. The script aborted before any API call.
  Copy the `nohup` command printed to stderr and run it in a terminal:
  ```bash
  nohup python3 $SANDBOX/agent/extract-pdf-<slug>.py > $SANDBOX/corpus/<NNN>-<slug>-vision.md.log 2>&1 &
  tail -f $SANDBOX/corpus/<NNN>-<slug>-vision.md.log
  ```
  The threshold `NOHUP_THRESHOLD = 15` can be raised in the script header if your
  API responses are consistently faster (< 20s/call on average).

**"I want higher quality on specific diagram pages"**
→ Increase `DPI = 200` in the script header. Keep `CHUNK_SIZE = 3` at 200 DPI
  (PNG ≈ 900 KB/page → 3 pages ≈ 2.7 MB payload).
