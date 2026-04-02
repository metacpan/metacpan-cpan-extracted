#!/usr/bin/env python3
"""
csv2_clarid_in.py

Unified TSV -> CSV transformer for either 'biosample' or 'subject' data,
using per-field pipelines defined in YAML, with flexible subject_id handling.

$VERSION taken from ClarID::Tools

Copyright (C) 2025 Manuel Rueda - CNAG

License: Artistic License 2.0

If this program helps you in your research, please cite.
"""
import argparse
import csv
import gzip
import sys
import re
from pathlib import Path

import yaml
from typing import Optional, List, Dict, Callable, Any, Set

# --- Primitive operations ---------------------------------------------------

def strip_quotes(v: Optional[str]) -> Optional[str]:
    """Trim whitespace then remove surrounding single/double quotes."""
    if v is None:
        return None
    vs = v.strip()
    return vs.strip("'\"")

def trim(v: Optional[str]) -> Optional[str]:
    """Trim leading/trailing whitespace."""
    if v is None:
        return None
    return v.strip()

def collapse_spaces(v: Optional[str]) -> Optional[str]:
    """Collapse all runs of whitespace into a single space."""
    if v is None:
        return None
    return ' '.join(v.split())

def remove_all_spaces(v: Optional[str]) -> Optional[str]:
    """Remove all whitespace characters."""
    if v is None:
        return None
    return ''.join(v.split())

def remove_suffix(v: Optional[str], suffix: str) -> Optional[str]:
    """Case-insensitive remove suffix, plus trailing whitespace."""
    if v is None:
        return None
    if v.lower().endswith(suffix.lower()):
        return v[:-len(suffix)].rstrip()
    return v

def map_values(v: Optional[str], mapping: Dict[Any, Any]) -> Optional[str]:
    """Map raw value to new via dict, defaulting to original."""
    return mapping.get(v, v)

def normalize_sex(v: Optional[str]) -> Optional[str]:
    """
    Capitalize gender, or return None if blank (so static_fields can apply).
    If the literal string 'unknown' is provided, it will become 'Unknown'.
    """
    if v is None or not v.strip():
        return None
    return v.strip().capitalize()

def bucketize_age(v: Optional[str], groups: List[Dict[str, Any]]) -> Optional[str]:
    """
    Convert numeric age string into named bucket,
    return None if the cell is truly blank (so static_fields can apply),
    otherwise if parsing/bucketing fails, return 'Unknown'.
    """
    if v is None or not v.strip():
        return None
    try:
        age = int(v)  # type: ignore
    except Exception:
        return 'Unknown'
    for g in groups:
        if g['min'] <= age <= g['max']:
            return g['name']
    return 'Unknown'

def normalize_multivalue(v: Optional[str], cfg: Dict[str, Any]) -> Optional[str]:
    """
    Split a multi-value string on configured delimiters, trim tokens,
    map each via optional 'map_values', drop empties, optional dedupe,
    then join with 'join_with' (default ';').
    """
    if v is None or not v.strip():
        return None

    delims = cfg.get('delimiters', [',', ';', '|', '/'])
    join_with = cfg.get('join_with', ';')
    mapping = cfg.get('map_values', {}) or cfg.get('mapping', {})
    drop_empty = cfg.get('drop_empty', True)
    dedupe = cfg.get('dedupe', False)

    pat = '|'.join(re.escape(d) for d in delims)
    tokens = re.split(pat, v)

    out: List[str] = []
    seen: Set[str] = set()
    for t in tokens:
        t = t.strip().strip("'\"")
        if drop_empty and not t:
            continue
        mapped = mapping.get(t, t)
        if dedupe:
            if mapped in seen:
                continue
            seen.add(mapped)
        out.append(mapped)

    return join_with.join(out)

def days_to_iso8601_bin(v: Optional[str], cfg: Dict[str, Any]) -> Optional[str]:
    """
    Convert a numeric day count into a 3-char ISO8601-like bin: 'P{n}{U}'
    where n in 0..9 and U in {D, W, M, Y}. Strategy:
      - blank -> None (so static_fields can apply)
      - parse error / negative -> cfg['on_error'] (default None)
      - prefer 'D' if <= 9; else try 'W' (days/7), then 'M' (~30), then 'Y' (~365)
      - rounding: floor|round|ceil (default: floor)
      - if years > 9, clamp to P9Y
    """
    if v is None or not str(v).strip():
        return None

    s = str(v).strip()
    try:
        days = float(s)
    except Exception:
        return cfg.get('on_error')  # default None

    if days < 0:
        return cfg.get('on_error')

    rounding = str(cfg.get('rounding', 'floor')).lower()
    def R(x: float) -> int:
        import math
        if rounding == 'ceil':
            return int(math.ceil(x))
        if rounding == 'round':
            return int(round(x))
        return int(math.floor(x))

    units: List[str] = cfg.get('units', ['D', 'W', 'M', 'Y'])

    # Try days
    if 'D' in units and days <= 9:
        return f'P{int(days)}D'

    # Try weeks
    if 'W' in units:
        w = R(days / 7.0)
        if 1 <= w <= 9:
            return f'P{w}W'

    # Try months (~30)
    if 'M' in units:
        m = R(days / 30.0)
        if 1 <= m <= 9:
            return f'P{m}M'

    # Fallback to years (~365), clamp to 1..9
    if 'Y' in units:
        y = R(days / 365.0)
        if y < 1:
            y = 1
        if y > 9:
            y = 9
        return f'P{y}Y'

    return cfg.get('on_error')

# Registry of zero-arg primitives
PRIMITIVES: Dict[str, Callable[[Optional[str]], Optional[str]]] = {
    'strip_quotes': strip_quotes,
    'trim': trim,
    'collapse_spaces': collapse_spaces,
    'remove_all_spaces': remove_all_spaces,
    'normalize_sex': normalize_sex,
}

# --- Dispatcher -------------------------------------------------------------

def apply_ops(value: Optional[str], ops: Optional[List[object]]) -> Optional[str]:
    """
    Apply each operation in the exact sequence provided:
      - string -> zero-arg primitive
      - dict with 'map_values' -> map_values
      - dict with other keys -> special ops inline
    """
    v = value
    if not ops:
        return v

    for op in ops:
        if isinstance(op, str):
            fn = PRIMITIVES.get(op)
            if not fn:
                raise ValueError(f"Unknown op '{op}'")
            v = fn(v)

        elif isinstance(op, dict):
            name, arg = next(iter(op.items()))
            if name == 'map_values':
                v = map_values(v, arg)            # run mapping right here
            elif name == 'remove_suffix':
                v = remove_suffix(v, arg)         # inline remove_suffix
            elif name == 'bucketize_age':
                v = bucketize_age(v, arg)         # inline bucketize_age
            elif name == 'normalize_multivalue':
                v = normalize_multivalue(v, arg)  # inline multivalue normalize
            elif name == 'days_to_iso8601_bin':
                v = days_to_iso8601_bin(v, arg)
            else:
                raise ValueError(f"Unknown op '{name}'")

        else:
            raise ValueError(f"Invalid op entry: {op}")

    return v

# --- I/O Helpers ------------------------------------------------------------

def open_input(path: str):
    return gzip.open(path, 'rt') if path.endswith('.gz') else open(path, 'r', newline='')

def open_output(path: str):
    return gzip.open(path, 'wt', newline='') if path.endswith('.gz') else open(path, 'w', newline='')

# --- Row blankness helpers --------------------------------------------------

def _is_blank_str(v: Optional[str]) -> bool:
    return v is None or (isinstance(v, str) and v.strip() == '')

def _is_empty_row(row: Dict[Any, Any]) -> bool:
    """
    Consider a row empty if:
      - all named fields are blank, and
      - any overflow fields under key None (from extra delimiters) are also blank.
    """
    named_blank = all(_is_blank_str(v) for k, v in row.items() if k is not None)
    extras = row.get(None)
    extras_blank = True
    if extras is not None:
        # csv.DictReader stores overflow as a list
        extras_blank = all(_is_blank_str(x) for x in extras)
    return named_blank and extras_blank

# --- Main -------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description='Unified parser for biosample or subject')
    parser.add_argument('--entity', choices=['biosample', 'subject'], required=True,
                        help='Which mapping entity to use')
    parser.add_argument('-i', '--input',   required=True, help='Input file (gz ok)')
    parser.add_argument('-o', '--output',  required=True, help='Output CSV file (gz ok)')
    parser.add_argument('-m', '--mapping', required=True, help='YAML mapping file')
    parser.add_argument('-d', '--delimiter', default='\t',
                        help="Input delimiter (default: tab). Use ',' for CSV.")
    args = parser.parse_args()

    cfg: Dict[str, Any] = yaml.safe_load(Path(args.mapping).read_text())
    fields_cfg    = cfg['fields']
    out_headers   = cfg['output_headers']
    static_fields = cfg.get('static_fields', {})

    # If subject_id has a source, we will be in "group" mode
    subj_cfg = fields_cfg.get('subject_id', {})
    subj_src = subj_cfg.get('source')
    subj_ops = subj_cfg.get('operations', [])

    with open_input(args.input) as infile:
        reader = csv.DictReader(infile, delimiter=args.delimiter)

        # Validate declared source columns
        missing = [fc['source'] for fc in fields_cfg.values()
                   if fc.get('source') and fc['source'] not in reader.fieldnames]
        if missing:
            sys.exit(f"ERROR: Missing columns: {missing}")

        with open_output(args.output) as outfile:
            writer = csv.writer(outfile, lineterminator='\n')
            writer.writerow(out_headers)

            counter = 0
            subject_counter = 0
            last_raw_subject = None

            for row in reader:
                # Skip completely empty or overflow-only rows
                if _is_empty_row(row):
                    continue

                # In group-mode, skip any row where the raw subject key is missing/blank
                if subj_src and _is_blank_str(row.get(subj_src)):
                    continue

                counter += 1
                out: List[str] = []
                for col in out_headers:
                    fc = fields_cfg.get(col, {})

                    if col == 'subject_id':
                        if subj_src:
                            raw = row.get(subj_src)
                            raw = apply_ops(raw, subj_ops)  # type: ignore
                            if raw != last_raw_subject:
                                subject_counter += 1
                                last_raw_subject = raw
                            val = str(subject_counter)
                        else:
                            subject_counter += 1
                            val = str(subject_counter)
                    else:
                        val = row.get(fc.get('source')) if fc.get('source') else None
                        val = apply_ops(val, fc.get('operations'))  # type: ignore
                        if (val is None or val == '') and col in static_fields:
                            val = static_fields[col]

                    out.append(val or '')
                writer.writerow(out)

    print(f"Wrote {args.output} ({counter} records)")

if __name__ == '__main__':
    main()
