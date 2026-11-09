"""Static contract checks, not SQL or Cypher semantic tests."""
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"scripts"))
from validate_package import anchors, local_link_errors, package_files, validate


class PackageTests(unittest.TestCase):
    def test_structure(self):
        self.assertEqual(validate(ROOT,require_manifest=False),[])
    def test_frontmatter_name(self):
        self.assertIn("name: postgres-vector-graph\n",(ROOT/"SKILL.md").read_text(encoding="utf-8"))
    def test_main_context_budget(self):
        self.assertLess(len((ROOT/"SKILL.md").read_text(encoding="utf-8").split()),1800)
    def test_references_indexed(self):
        index=(ROOT/"references/INDEX.md").read_text(encoding="utf-8")
        for p in (ROOT/"references").rglob("*.md"):
            if p.name != "INDEX.md": self.assertIn(p.relative_to(ROOT/"references").as_posix(),index)
    def test_sql_psql_guards(self):
        for p in (ROOT/"examples/sql").glob("*.sql"):
            self.assertIn(r"\set ON_ERROR_STOP on",p.read_text(encoding="utf-8"),str(p))
    def test_no_automatic_destructive_cleanup(self):
        for p in (ROOT/"examples/sql").glob("*.sql"):
            self.assertIsNone(re.search(r"(?mi)^\s*DROP\s+",p.read_text(encoding="utf-8")),str(p))
    def test_no_nonportable_quit_exit_argument(self):
        for p in (ROOT/"examples/sql").glob("*.sql"):
            self.assertNotIn(r"\quit 1",p.read_text(encoding="utf-8"),str(p))
    def test_preflight_read_only(self):
        text=(ROOT/"examples/sql/00_preflight.sql").read_text(encoding="utf-8")
        self.assertIn("BEGIN READ ONLY",text)
        self.assertIsNone(re.search(r"(?mi)^\s*(CREATE|ALTER|INSERT|UPDATE|DELETE|LOAD)\s+",text))
    def test_generated_column_explicit_stored(self):
        self.assertIn(") STORED",(ROOT/"examples/sql/02_schema_and_seed.sql").read_text(encoding="utf-8"))
    def test_read_role_has_no_bypass(self):
        self.assertIn("NOBYPASSRLS",(ROOT/"examples/sql/08_rls_setup.sql").read_text(encoding="utf-8"))
    def test_optional_dependency_contract(self):
        d=json.loads((ROOT/"dependencies.json").read_text(encoding="utf-8"))
        self.assertEqual(d["profiles"]["standalone"]["required"],[])
        self.assertFalse(d["automatic_resolution"])
    def test_anchor_normalization(self):
        self.assertIn("operations",anchors("## Operations\n"))
    def test_missing_link_detected(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory); p=root/"a.md"; p.write_text("[bad](missing.md)")
            self.assertTrue(local_link_errors(root,p))
    def test_escape_detected(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory); p=root/"a.md"; p.write_text("[bad](../outside.md)")
            self.assertTrue(local_link_errors(root,p))
    def test_external_links_not_fetched(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory); p=root/"a.md"; p.write_text("[external](https://example.invalid/no-network)")
            self.assertEqual(local_link_errors(root,p),[])
    def test_ignored_caches(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory); (root/"__pycache__").mkdir()
            (root/"__pycache__/a.pyc").write_bytes(b"test")
            self.assertEqual(package_files(root),[])


if __name__ == "__main__": unittest.main()
