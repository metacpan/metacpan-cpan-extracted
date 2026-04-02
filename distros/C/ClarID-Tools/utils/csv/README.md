# csv2_clarid_in.py 🧪📄

## Overview

`csv2_clarid_in.py` is a script to convert raw TSV or CSV files into a standard CSV format for `biosample` or `subject` entities. It uses a YAML file to define how each field is handled, with support for field transformations and automatic subject ID generation.

🧬 *Included in the containerized version of ClarID-Tools — no installation needed if using the Docker image.*

__Note:__ These helper scripts are intended to work with the ClarID-Tools release they are shipped with.

---

## 🚀 Usage

```bash
./csv2_clarid_in.py --entity {biosample|subject} -i input.tsv[.gz] -o output.csv[.gz] -m mapping.yaml [-d delimiter]
```

### Arguments

- `--entity` — required: `biosample` or `subject`
- `-i` / `--input` — input TSV or CSV (gzip supported)
- `-o` / `--output` — output CSV (gzip supported)
- `-m` / `--mapping` — YAML file with field config
- `-d` — input delimiter (default: tab, use `,` for CSV)

---

## 🗂️ Mapping YAML (minimal example)

```yaml
output_headers:
  - subject_id
  - age_group
  - sex

fields:
  subject_id:
    source: sample_id
    operations:
      - trim

  age_group:
    source: age
    operations:
      - bucketize_age:
          - {name: 'Adult', min: 20, max: 64}

  sex:
    source: gender
    operations:
      - normalize_sex

static_fields:
  sex: Unknown
```

---

## ⏱️ Duration binning (days → ISO8601 PnU)

Many pipelines need a normalized “duration/timepoint” field. This script supports an op that **converts a day count into a strict 3-char ISO-like bin**:

- **Format:** `P[0-9][DWMY]` (examples: `P0D`, `P7D`, `P3M`, `P2Y`)
- **Allowed units:** Days (`D`), Weeks (`W`), Months (`M` ≈ 30 days), Years (`Y` ≈ 365 days)
- **Allowed digits:** `0–9` (values >9 in a unit are escalated to a larger unit; years are clamped to `P9Y`)

> Note: The 3-character limit (PnU) is intentional, designed to keep timepoint duration compact and consistent, rather than attempting to represent every possible duration in full detail.

### Assumptions

- The **input column is in days** (integer or numeric string). This keeps the logic predictable and easy to prepare (you can convert anything to days in Excel/R/Python beforehand).
- **Blank cells and sentinels** can be mapped to `null` (`~` in YAML) and then filled by `static_fields` (e.g., `P0D`).

> Note: `P0D` is the valid zero-duration value. If you used `P0N` before, replace it with `P0D`.

### YAML snippet (duration)

```yaml
output_headers:
  - duration

fields:
  duration:
    source: samples.days_to_collection
    operations:
      - strip_quotes
      - trim
      - map_values:
          "--": ~
          "NA": ~
          "": ~
      - days_to_iso8601_bin:
          rounding: floor      # one of: floor | round | ceil (default: floor)
          units: [D, W, M, Y]  # allowed output units in this priority
          on_error: ~          # if parse/negative/error -> None, so static_fields can apply

static_fields:
  duration: P0D
```

### How it bins

- `0..9` days → `P0D`..`P9D`
- `>=10` days → try weeks (`days/7`, rounded as configured) → `P1W`..`P9W`
- If weeks would be `>=10` → try months (`days/30`) → `P1M`..`P9M`
- If months would be `>=10` → years (`days/365`), clamped to `P1Y`..`P9Y`

**Rounding** affects W/M/Y only (not D). Default is `floor`.

### Examples

Input values (days) → Output:

- `0` → `P0D`
- `7` → `P7D`
- `10` → `P1W`
- `63` → `P9W`
- `70` → `P2M` (≈ 70/30 → 2 with floor)
- `300` → `P1Y`
- `4000` → `P9Y` (clamped)

### Preparing “days” in spreadsheets

If your raw data are dates or timestamps:

- **Excel/LibreOffice**: if A2 is a collection date and A1 is baseline, `=A2 - A1` yields day count (format as General/Number).
- **If strings**: convert to proper date types first, then subtract.
- **If weeks/months/years**: multiply by `7`, `30`, or `365` to approximate days.

### Skipped empty rows

The parser **skips completely empty rows**. To emit a row that falls back to `static_fields`, provide a **sentinel** (e.g., `NA` or `--`) and map it to `~` via `map_values`. A truly blank line at file end won’t produce an output row.

---

## 🔀 Handling multi-value fields (e.g., `condition`)

Some columns (like `condition`) may contain multiple inline values in a single cell, separated by typical CSV/TSV delimiters (`,`, `;`, `|`, `/`). Use the `normalize_multivalue` operation to split, clean, map, and rejoin the values using `;`, which the downstream software expects.

### YAML snippet

```yaml
fields:
  condition:
    source: samples.tumor_code
    operations:
      - strip_quotes
      - trim
      - normalize_multivalue:
          delimiters: [",", ";", "|", "/"]  # what to split on
          join_with: ";"                    # how to rejoin after mapping
          dedupe: false                     # set true to collapse repeats
          map_values:                       # per-token mapping
            "Acute myeloid leukemia (AML)": C92.0
            "Induction Failure AML (AML-IF)": C92.0
            "--": Z00.00
```

### What it does

1. Split on `delimiters`.
2. Trim and unquote each token.
3. Map via `map_values` (unmapped tokens pass through).
4. Drop empties (`drop_empty: true` by default).
5. Optionally de-duplicate (`dedupe: true`).
6. Rejoin with `join_with` (default `;`).

---

## 🧩 Other behaviors & tips

- **Column validation**: the script checks that every `source:` column exists in the input header; missing ones abort with an error.
- **Output order**: strictly follows `output_headers`.
- **`subject_id` assignment**:
  - If `fields.subject_id.source` is **present**: “group mode”—rows that share the same transformed source value receive the same sequential ID (grouped in read order).
  - If absent: “pure counter”—every row receives a new ID.
- **Gzip**: `.gz` extensions are detected automatically for input and output.
- **Empty rows**: completely empty rows (including overflow fields) are skipped.

---

## ✅ Defaults for `normalize_multivalue`

- `delimiters`: `[",", ";", "|", "/"]`
- `join_with`: `";"`
- `drop_empty`: `true`
- `dedupe`: `false`

---

## 📜 License

Artistic License 2.0  
(C) 2025-2026 Manuel Rueda - CNAG
