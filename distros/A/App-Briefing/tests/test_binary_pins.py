"""Black-box contract tests for the binary checksum pin importer."""

import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
IMPORTER = ROOT / "scripts" / "import-binary-sums.py"
VERSION = "0.001"
ASSETS = (
    "briefing-0.001-linux-x86_64",
    "briefing-0.001-linux-arm64",
    "briefing-0.001-macos-x86_64",
    "briefing-0.001-macos-arm64",
    "briefing-0.001-windows-x86_64.exe",
)
HASHES = tuple("%064x" % number for number in range(1, len(ASSETS) + 1))


class BinaryPinImportTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="briefing-binary-pins-"))
        self.addCleanup(shutil.rmtree, str(self.tmp), True)
        self.input = self.tmp / "SHA256SUMS"
        self.output = self.tmp / "briefing-binaries.sha256"

    def sums(self, assets=ASSETS, hashes=HASHES, line_ending="\n"):
        return line_ending.join(
            "%s  %s" % (digest, asset) for digest, asset in zip(hashes, assets)
        ) + line_ending

    def run_importer(self, sums, output=None, version=VERSION):
        self.input.write_bytes(sums.encode("ascii"))
        return subprocess.run(
            [
                sys.executable,
                str(IMPORTER),
                "--version",
                version,
                "--input",
                str(self.input),
                "--output",
                str(output or self.output),
            ],
            cwd=str(ROOT),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=10,
        )

    def assert_rejected(self, sums):
        result = self.run_importer(sums)
        self.assertEqual(result.returncode, 2, result.stderr.decode("utf-8", "replace"))
        self.assertEqual(result.stdout, b"")
        self.assertEqual(
            len(result.stderr.splitlines()),
            1,
            "invalid input must produce one concise stderr error: %r" % result.stderr,
        )
        self.assertFalse(self.output.exists(), "invalid input must not create an output file")

    def test_writes_exact_five_entries_in_canonical_order(self):
        shuffled_assets = (ASSETS[4], ASSETS[2], ASSETS[0], ASSETS[3], ASSETS[1])
        shuffled_hashes = (HASHES[4], HASHES[2], HASHES[0], HASHES[3], HASHES[1])

        result = self.run_importer(self.sums(shuffled_assets, shuffled_hashes))

        self.assertEqual(result.returncode, 0, result.stderr.decode("utf-8", "replace"))
        self.assertEqual(result.stdout, b"")
        self.assertEqual(result.stderr, b"")
        self.assertEqual(
            self.output.read_bytes(),
            self.sums().encode("ascii"),
        )

    def test_normalizes_crlf_and_uppercase_hashes(self):
        result = self.run_importer(
            self.sums(hashes=tuple(digest.upper() for digest in HASHES), line_ending="\r\n")
        )

        self.assertEqual(result.returncode, 0, result.stderr.decode("utf-8", "replace"))
        self.assertEqual(result.stdout, b"")
        self.assertEqual(result.stderr, b"")
        self.assertEqual(self.output.read_bytes(), self.sums().encode("ascii"))

    def test_rejects_missing_duplicate_and_extra_entries(self):
        cases = {
            "missing": self.sums(ASSETS[:-1], HASHES[:-1]),
            "duplicate": self.sums(ASSETS + (ASSETS[0],), HASHES + (HASHES[0],)),
            "extra": self.sums(
                ASSETS + ("briefing-0.001-freebsd-x86_64",),
                HASHES + ("f" * 64,),
            ),
        }

        for name, sums in cases.items():
            with self.subTest(name=name):
                self.assert_rejected(sums)

    def test_rejects_mixed_or_unexpected_versions(self):
        mixed_assets = list(ASSETS)
        mixed_assets[0] = "briefing-0.002-linux-x86_64"
        unexpected_assets = tuple(asset.replace(VERSION, "0.002") for asset in ASSETS)

        for name, sums in {
            "mixed": self.sums(tuple(mixed_assets)),
            "unexpected": self.sums(unexpected_assets),
        }.items():
            with self.subTest(name=name):
                self.assert_rejected(sums)

    def test_rejects_malformed_hashes_paths_and_renamed_assets(self):
        bad_hashes = list(HASHES)
        bad_hashes[0] = "a" * 63
        nonhex_hashes = list(HASHES)
        nonhex_hashes[0] = "g" * 64
        path_assets = list(ASSETS)
        path_assets[0] = "release/" + ASSETS[0]
        absolute_path_assets = list(ASSETS)
        absolute_path_assets[0] = "/tmp/" + ASSETS[0]
        renamed_assets = list(ASSETS)
        renamed_assets[0] = "briefing-0.001-linux-amd64"

        cases = {
            "short-hash": self.sums(hashes=tuple(bad_hashes)),
            "non-hex-hash": self.sums(hashes=tuple(nonhex_hashes)),
            "path-bearing-asset": self.sums(assets=tuple(path_assets)),
            "absolute-asset": self.sums(assets=tuple(absolute_path_assets)),
            "renamed-asset": self.sums(assets=tuple(renamed_assets)),
        }
        for name, sums in cases.items():
            with self.subTest(name=name):
                self.assert_rejected(sums)

    def test_rejects_path_bearing_version_before_deriving_asset_names(self):
        original = b"existing pins must survive invalid version input\n"
        for version in ("0.001/escape", "0.001\\escape", "0.001 escape"):
            with self.subTest(version=version):
                self.output.write_bytes(original)
                manipulated_assets = tuple(asset.replace(VERSION, version) for asset in ASSETS)

                result = self.run_importer(
                    self.sums(assets=manipulated_assets), version=version
                )

                self.assertEqual(result.returncode, 2, result.stderr.decode("utf-8", "replace"))
                self.assertEqual(result.stdout, b"")
                self.assertEqual(len(result.stderr.splitlines()), 1)
                self.assertEqual(self.output.read_bytes(), original)

    def test_failure_does_not_replace_existing_output(self):
        original = b"existing pins must survive validation failure\n"
        self.output.write_bytes(original)
        malformed_hashes = list(HASHES)
        malformed_hashes[0] = "not-a-sha256"

        result = self.run_importer(self.sums(hashes=tuple(malformed_hashes)))

        self.assertEqual(result.returncode, 2, result.stderr.decode("utf-8", "replace"))
        self.assertEqual(result.stdout, b"")
        self.assertEqual(len(result.stderr.splitlines()), 1)
        self.assertEqual(self.output.read_bytes(), original)

    def test_help_documents_the_three_required_options(self):
        result = subprocess.run(
            [sys.executable, str(IMPORTER), "--help"],
            cwd=str(ROOT),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=10,
        )

        self.assertEqual(result.returncode, 0, result.stderr.decode("utf-8", "replace"))
        self.assertEqual(result.stderr, b"")
        for option in ("--version", "--input", "--output"):
            with self.subTest(option=option):
                self.assertIn(option.encode("ascii"), result.stdout)


if __name__ == "__main__":
    unittest.main()
