import unittest
import tempfile
import os
import sys
import csv
from csv2_clarid_in import (
    strip_quotes, trim, collapse_spaces, remove_all_spaces,
    remove_suffix, map_values, normalize_sex, bucketize_age,
    apply_ops, main, normalize_multivalue
)

class TestPrimitives(unittest.TestCase):
    def test_strip_quotes(self):
        self.assertEqual(strip_quotes("'hello'"), "hello")
        self.assertEqual(strip_quotes('"world"'), "world")
        self.assertEqual(strip_quotes("noquotes"), "noquotes")
        self.assertIsNone(strip_quotes(None))

    def test_trim(self):
        self.assertEqual(trim("  spaced  "), "spaced")
        self.assertEqual(trim("\ttrim\t"), "trim")
        self.assertIsNone(trim(None))

    def test_collapse_spaces(self):
        self.assertEqual(collapse_spaces("a   b\tc"), "a b c")
        self.assertEqual(collapse_spaces(" single "), "single")
        self.assertIsNone(collapse_spaces(None))

    def test_remove_all_spaces(self):
        self.assertEqual(remove_all_spaces("a b c"), "abc")
        self.assertEqual(remove_all_spaces("   "), "")
        self.assertIsNone(remove_all_spaces(None))

    def test_remove_suffix(self):
        self.assertEqual(remove_suffix("BoneMarrowNOS", "NOS"), "BoneMarrow")
        self.assertEqual(remove_suffix("TestSuffix", "fix"), "TestSuf")
        self.assertEqual(remove_suffix("NoSuffixHere", "XYZ"), "NoSuffixHere")
        self.assertIsNone(remove_suffix(None, "A"))

    def test_map_values(self):
        m = {"A": "Alpha", "B": "Beta"}
        self.assertEqual(map_values("A", m), "Alpha")
        self.assertEqual(map_values("C", m), "C")
        self.assertIsNone(map_values(None, m))

    def test_normalize_sex(self):
        # Valid values get normalized
        self.assertEqual(normalize_sex("male"), "Male")
        self.assertEqual(normalize_sex("   FEMALE  "), "Female")
        # Blank or missing -> None
        self.assertIsNone(normalize_sex(""))
        self.assertIsNone(normalize_sex(None))
        # Literal 'unknown' string is capitalized
        self.assertEqual(normalize_sex("unknown"), "Unknown")
        self.assertEqual(normalize_sex("   unknown  "), "Unknown")

    def test_bucketize_age(self):
        groups = [
            {"name": "Age0to9", "min": 0, "max": 9},
            {"name": "Age10to19", "min": 10, "max": 19},
        ]
        self.assertEqual(bucketize_age("5", groups), "Age0to9")
        self.assertEqual(bucketize_age("10", groups), "Age10to19")
        self.assertEqual(bucketize_age("100", groups), "Unknown")
        self.assertEqual(bucketize_age("notanumber", groups), "Unknown")
        # Blank or missing -> None
        self.assertIsNone(bucketize_age("", groups))
        self.assertIsNone(bucketize_age(None, groups))

class TestApplyOps(unittest.TestCase):
    def test_primitives_chain(self):
        ops = ["strip_quotes", "trim", "collapse_spaces", "remove_all_spaces"]
        val = "  'A   B C'  "
        self.assertEqual(apply_ops(val, ops), "ABC")

    def test_remove_suffix_and_map_values(self):
        ops = [
            "trim",
            {"remove_suffix": "Z"},
            {"map_values": {"X": "Y"}}
        ]
        val = "  XZ  "
               # -> trim -> remove_suffix('Z') -> 'X' -> map_values -> 'Y'
        self.assertEqual(apply_ops(val, ops), "Y")

    def test_custom_ops(self):
        ops = ["strip_quotes", "trim", "normalize_sex"]
        self.assertEqual(apply_ops(" female ", ops), "Female")

    def test_apply_ops_with_normalize_multivalue(self):
        ops = [
            "strip_quotes",
            "trim",
            {"normalize_multivalue": {
                "delimiters": [",", ";"],
                "join_with": ";",
                "map_values": {"foo": "F"}
            }}
        ]
        self.assertEqual(apply_ops('"foo,bar"', ops), "F;bar")

class TestNormalizeMultivalueUnit(unittest.TestCase):
    def test_normalize_multivalue_basic(self):
        cfg = {
            "delimiters": [",", ";", "|", "/"],
            "join_with": ";",
            "map_values": {"A": "X", "B": "Y", "--": "Z"},
            "dedupe": False
        }
        s = ' A | B, C / "--" '
        self.assertEqual(normalize_multivalue(s, cfg), "X;Y;C;Z")

    def test_normalize_multivalue_dedupe(self):
        cfg = {
            "delimiters": [",", ";"],
            "join_with": ";",
            "map_values": {"A": "X", "B": "Y"},
            "dedupe": True
        }
        s = "A;A,B"
        self.assertEqual(normalize_multivalue(s, cfg), "X;Y")

class TestSubjectID(unittest.TestCase):
    def _sanity_check_tsv(self, input_data: str):
        lines = input_data.splitlines()
        if not lines:
            return
        header_cols = lines[0].split('\t')
        for i, line in enumerate(lines[1:], start=2):
            if not line.strip():
                continue
            if len(line.split('\t')) != len(header_cols):
                raise AssertionError(f"Bad TSV on line {i}: {line!r}")

    def run_parser(self, input_data, mapping_yaml):
        # Sanity: ensure TSV columns align
        self._sanity_check_tsv(input_data)

        # Helper to run parser with given TSV input and YAML mapping
        with tempfile.NamedTemporaryFile('w+', delete=False, suffix='.tsv') as tsvfile, \
             tempfile.NamedTemporaryFile('w+', delete=False, suffix='.yaml') as ymfile, \
             tempfile.NamedTemporaryFile('w+', delete=False, suffix='.csv') as outfile:
            tsvfile.write(input_data)
            tsvfile.flush()
            ymfile.write(mapping_yaml)
            ymfile.flush()
            old_argv = sys.argv
            sys.argv = [old_argv[0], '--entity', 'subject', '-i', tsvfile.name, '-o', outfile.name, '-m', ymfile.name]
            try:
                main()
            finally:
                sys.argv = old_argv
            with open(outfile.name, 'r') as f:
                result = f.read().strip().splitlines()
        os.unlink(tsvfile.name)
        os.unlink(ymfile.name)
        os.unlink(outfile.name)
        return result

    def test_pure_counter_subject_id(self):
        # No source for subject_id -> every row gets a new ID
        input_data = "raw_id\tval\nA\tx\nA\ty\n"
        mapping_yaml = """
output_headers:
  - subject_id
  - val
fields:
  subject_id:
    operations: []
  val:
    source: val
    operations: []
"""
        out_lines = self.run_parser(input_data, mapping_yaml)
        self.assertEqual(out_lines[0], 'subject_id,val')
        ids = [line.split(',')[0] for line in out_lines[1:]]
        self.assertEqual(ids, ['1', '2'])

    def test_group_mode_subject_id(self):
        # Source provided -> group-mode assignment
        input_data = "raw_id\tval\nA\tx\nA\ty\nB\tz\nB\tw\n"
        mapping_yaml = """
output_headers:
  - subject_id
  - val
fields:
  subject_id:
    source: raw_id
    operations: []
  val:
    source: val
    operations: []
"""
        out_lines = self.run_parser(input_data, mapping_yaml)
        self.assertEqual(out_lines[0], 'subject_id,val')
        # Only check subject_id grouping
        ids = [line.split(',')[0] for line in out_lines[1:]]
        self.assertEqual(ids, ['1', '1', '2', '2'])

class TestConditionMultivalueE2E(unittest.TestCase):
    def run_parser(self, input_data, mapping_yaml):
        with tempfile.NamedTemporaryFile('w+', delete=False, suffix='.tsv') as tsvfile, \
             tempfile.NamedTemporaryFile('w+', delete=False, suffix='.yaml') as ymfile, \
             tempfile.NamedTemporaryFile('w+', delete=False, suffix='.csv') as outfile:
            tsvfile.write(input_data)
            tsvfile.flush()
            ymfile.write(mapping_yaml)
            ymfile.flush()
            old_argv = sys.argv
            sys.argv = [old_argv[0], '--entity', 'subject', '-i', tsvfile.name, '-o', outfile.name, '-m', ymfile.name]
            try:
                main()
            finally:
                sys.argv = old_argv
            with open(outfile.name, 'r') as f:
                result = f.read().strip().splitlines()
        os.unlink(tsvfile.name)
        os.unlink(ymfile.name)
        os.unlink(outfile.name)
        return result

    def test_condition_multivalue_mapping_and_join(self):
        input_data = (
            "cond\n"
            "Acute myeloid leukemia (AML) | Induction Failure AML (AML-IF), --\n"
            "--\n"
        )
        mapping_yaml = """
output_headers:
  - condition
fields:
  condition:
    source: cond
    operations:
      - strip_quotes
      - trim
      - normalize_multivalue:
          delimiters: [",", ";", "|", "/"]
          join_with: ";"
          dedupe: false
          map_values:
            "Acute myeloid leukemia (AML)": C92.0
            "Induction Failure AML (AML-IF)": C92.0
            "--": Z00.00
"""
        out_lines = self.run_parser(input_data, mapping_yaml)
        self.assertEqual(out_lines[0], "condition")
        self.assertEqual(out_lines[1], "C92.0;C92.0;Z00.00")
        self.assertEqual(out_lines[2], "Z00.00")

    def test_condition_multivalue_dedupe(self):
        input_data = (
            "cond\n"
            "Acute myeloid leukemia (AML); Induction Failure AML (AML-IF)\n"
        )
        mapping_yaml = """
output_headers:
  - condition
fields:
  condition:
    source: cond
    operations:
      - normalize_multivalue:
          delimiters: [",", ";"]
          join_with: ";"
          dedupe: true
          map_values:
            "Acute myeloid leukemia (AML)": C92.0
            "Induction Failure AML (AML-IF)": C92.0
"""
        out_lines = self.run_parser(input_data, mapping_yaml)
        self.assertEqual(out_lines[0], "condition")
        self.assertEqual(out_lines[1], "C92.0")

class TestDaysToISO8601Bin(unittest.TestCase):
    def test_blank_and_error_handling(self):
        # Blank/None -> None (so static_fields can apply downstream)
        self.assertIsNone(apply_ops("", [{"days_to_iso8601_bin": {}}]))
        self.assertIsNone(apply_ops(None, [{"days_to_iso8601_bin": {}}]))
        # Negative or non-numeric -> None by default (on_error not set)
        self.assertIsNone(apply_ops("-5", [{"days_to_iso8601_bin": {}}]))
        self.assertIsNone(apply_ops("not_a_number", [{"days_to_iso8601_bin": {}}]))

    def test_basic_bins_floor(self):
        # Days 0..9 -> PnD
        self.assertEqual(apply_ops("0", [{"days_to_iso8601_bin": {"rounding": "floor"}}]), "P0D")
        self.assertEqual(apply_ops("9", [{"days_to_iso8601_bin": {"rounding": "floor"}}]), "P9D")
        # 10 days -> 1 week
        self.assertEqual(apply_ops("10", [{"days_to_iso8601_bin": {"rounding": "floor"}}]), "P1W")
        # 63 days -> 9 weeks
        self.assertEqual(apply_ops("63", [{"days_to_iso8601_bin": {"rounding": "floor"}}]), "P9W")
        # 70 days -> weeks would be 10, so fallback to months (~30d) -> 2 months
        self.assertEqual(apply_ops("70", [{"days_to_iso8601_bin": {"rounding": "floor"}}]), "P2M")
        # 300 days -> months would be 10, fallback to years (~365d) -> clamp min 1Y
        self.assertEqual(apply_ops("300", [{"days_to_iso8601_bin": {"rounding": "floor"}}]), "P1Y")
        # Very large -> clamp to P9Y
        self.assertEqual(apply_ops("4000", [{"days_to_iso8601_bin": {"rounding": "floor"}}]), "P9Y")

    def test_rounding_variants(self):
        # Check that rounding affects W/M/Y calculations (not D)
        self.assertEqual(apply_ops("13", [{"days_to_iso8601_bin": {"rounding": "floor"}}]), "P1W")
        self.assertEqual(apply_ops("13", [{"days_to_iso8601_bin": {"rounding": "round"}}]), "P2W")
        self.assertEqual(apply_ops("13", [{"days_to_iso8601_bin": {"rounding": "ceil"}}]), "P2W")

    def test_units_constraint_and_on_error(self):
        # If only D and W are allowed, large values that exceed 9W should trigger on_error
        self.assertEqual(
            apply_ops("4000", [{"days_to_iso8601_bin": {"units": ["D", "W"], "rounding": "floor", "on_error": "ERR"}}]),
            "ERR"
        )
        # If months/years are permitted, same input should map to P9Y
        self.assertEqual(
            apply_ops("4000", [{"days_to_iso8601_bin": {"units": ["D", "W", "M", "Y"], "rounding": "floor"}}]),
            "P9Y"
        )


class TestDurationBinningE2E(unittest.TestCase):
    def run_parser(self, input_data, mapping_yaml):
        with tempfile.NamedTemporaryFile('w+', delete=False, suffix='.tsv') as tsvfile, \
             tempfile.NamedTemporaryFile('w+', delete=False, suffix='.yaml') as ymfile, \
             tempfile.NamedTemporaryFile('w+', delete=False, suffix='.csv') as outfile:
            tsvfile.write(input_data)
            tsvfile.flush()
            ymfile.write(mapping_yaml)
            ymfile.flush()
            old_argv = sys.argv
            sys.argv = [old_argv[0], '--entity', 'subject', '-i', tsvfile.name, '-o', outfile.name, '-m', ymfile.name]
            try:
                main()
            finally:
                sys.argv = old_argv
            with open(outfile.name, 'r') as f:
                result = f.read().strip().splitlines()
        os.unlink(tsvfile.name)
        os.unlink(ymfile.name)
        os.unlink(outfile.name)
        return result

    def test_e2e_days_to_iso_bin(self):
        input_data = (
            "days\n"
            "0\n"
            "1\n"
            "10\n"
            "63\n"
            "70\n"
            "300\n"
            "4000\n"
            "--\n"
            "NA\n"
        )
        mapping_yaml = """
output_headers:
  - duration
fields:
  duration:
    source: days
    operations:
      - strip_quotes
      - trim
      - map_values:
          "--": ~
          "NA": ~
          "": ~
      - days_to_iso8601_bin:
          rounding: floor
static_fields:
  duration: P0D
"""
        out_lines = self.run_parser(input_data, mapping_yaml)
        self.assertEqual(out_lines[0], "duration")
        # Row-by-row expectations
        self.assertEqual(out_lines[1], "P0D")  # 0
        self.assertEqual(out_lines[2], "P1D")  # 1
        self.assertEqual(out_lines[3], "P1W")  # 10
        self.assertEqual(out_lines[4], "P9W")  # 63
        self.assertEqual(out_lines[5], "P2M")  # 70
        self.assertEqual(out_lines[6], "P1Y")  # 300
        self.assertEqual(out_lines[7], "P9Y")  # 4000 (clamped)
        self.assertEqual(out_lines[8], "P0D")  # "--" -> None -> static
        self.assertEqual(out_lines[9], "P0D")  # blank -> None -> static

if __name__ == '__main__':
    unittest.main()
