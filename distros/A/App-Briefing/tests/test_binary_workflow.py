"""Static contracts for standalone binary workflow integration.

These tests intentionally parse only the narrow configuration fragments that form
this repository's binary-delivery contract.  They use no YAML parser so the
retained Python test suite stays standard-library-only.
"""

import hashlib
import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
BINARY_WORKFLOW = ROOT / ".github" / "workflows" / "binaries.yml"
CI_WORKFLOW = ROOT / ".github" / "workflows" / "ci.yml"
DIST_INI = ROOT / "dist.ini"
STARTER = ROOT / "bin" / "briefing"
WINLAUNCH_CHECK = ROOT / ".cicd" / "python+3.12+test.winlaunch.sh"
BINARY_SMOKE = ROOT / "scripts" / "binary-smoke.sh"
TEST_WORKFLOW = ROOT / ".github" / "workflows" / "test.yml"
OS_RELEASE = Path("/etc/os-release")

CANONICAL_PLATFORMS = frozenset(
    (
        "linux-x86_64",
        "linux-arm64",
        "macos-x86_64",
        "macos-arm64",
        "windows-x86_64",
    )
)
RUN_LEVEL_EVIDENCE_FIELDS = (
    "source_commit",
    "workflow_commit",
    "runner_image",
    "runner_version",
)


class BinaryWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.binaries = BINARY_WORKFLOW.read_text(encoding="utf-8")
        self.ci = CI_WORKFLOW.read_text(encoding="utf-8")
        self.dist_ini = DIST_INI.read_text(encoding="utf-8")
        self.starter = STARTER.read_text(encoding="utf-8")
        self.winlaunch_check = WINLAUNCH_CHECK.read_text(encoding="utf-8")
        self.binary_smoke = BINARY_SMOKE.read_text(encoding="utf-8")
        self.test_workflow = TEST_WORKFLOW.read_text(encoding="utf-8")

    def test_binary_workflow_uses_full_commit_sha(self):
        references = re.findall(
            r"(?m)^\s*uses:\s*([^\s#]+)", self.binaries
        )
        binary_references = [
            reference
            for reference in references
            if reference.endswith("/dzil-binary.yml")
            or "/dzil-binary.yml@" in reference
        ]
        self.assertEqual(
            len(binary_references),
            1,
            "binaries.yml must call exactly one dzil-binary reusable workflow",
        )
        self.assertRegex(
            binary_references[0],
            r"^Getty/p5-dist-zilla-pluginbundle-author-getty/"
            r"\.github/workflows/dzil-binary\.yml@[0-9A-Fa-f]{40}$",
            "the reusable binary workflow must be pinned to a full immutable commit SHA",
        )

    def test_bundle_ref_pins_the_called_workflow_code_to_the_same_sha(self):
        uses = re.search(
            r"(?m)^\s*uses:\s*\S*/dzil-binary\.yml@([0-9A-Fa-f]{40})\s*$",
            self.binaries,
        )
        self.assertIsNotNone(uses, "binaries.yml must call dzil-binary.yml at a full SHA")
        bundle_ref = re.search(
            r"(?m)^\s*bundle_ref:\s*[\"']?([^\s\"'#]+)[\"']?\s*(?:#.*)?$",
            self.binaries,
        )
        self.assertIsNotNone(
            bundle_ref,
            "binaries.yml must pass bundle_ref: the called workflow otherwise checks "
            "its scripts out at the mutable default tag binary-v1",
        )
        self.assertEqual(
            bundle_ref.group(1),
            uses.group(1),
            "bundle_ref must equal the 40-hex SHA of the uses: line",
        )

    def test_binary_workflow_has_five_canonical_platforms(self):
        match = re.search(
            r"(?m)^\s*binary_platforms\s*=\s*(?P<platforms>\S(?:.*\S)?)\s*$",
            self.dist_ini,
        )
        self.assertIsNotNone(match, "dist.ini must declare binary_platforms")
        platforms = tuple(match.group("platforms").split())
        self.assertEqual(
            len(platforms),
            len(set(platforms)),
            "binary_platforms must not duplicate a platform",
        )
        self.assertEqual(
            frozenset(platforms),
            CANONICAL_PLATFORMS,
            "binary_platforms must build exactly the five supported native platforms",
        )

    def test_windows_asset_contract_requires_exe(self):
        self.assertRegex(
            self.starter,
            r"(?ms)^\s*windows:x86_64\)\s*\n"
            r"\s*printf\s+'briefing-%s-windows-x86_64\.exe\\n'\s+"
            r'"\$platform_version"\s*\n\s*;;',
            "the Windows platform must select the release asset with its .exe suffix",
        )

    def test_cpan_excludes_all_plugin_bin_files(self):
        self.assertRegex(
            self.dist_ini,
            r"(?m)^\s*gather_exclude_match\s*=\s*\^bin/\s*$",
            "the distribution gather rule must exclude every plugin-only bin/ file",
        )
        execdir = re.search(
            r"(?ms)^\[ExecDir\]\s*$\n(?P<body>.*?)(?=^\[|\Z)", self.dist_ini
        )
        self.assertIsNotNone(execdir, "dist.ini must declare the CPAN executable directory")
        self.assertRegex(
            execdir.group("body"),
            r"(?m)^\s*dir\s*=\s*script\s*$",
            "CPAN must install script/briefing instead of a plugin bin/ launcher",
        )

    def tracked_launchers(self):
        try:
            out = subprocess.run(
                ["git", "ls-files", "--", "bin/*.exe", "hooks/*.exe"],
                cwd=str(ROOT), stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                universal_newlines=True, check=True,
            ).stdout.split()
        except (OSError, subprocess.CalledProcessError):
            out = [
                str(path.relative_to(ROOT))
                for pattern in ("bin/*.exe", "hooks/*.exe")
                for path in ROOT.glob(pattern)
            ]
        return set(out)

    def generic_loop_coverage(self):
        loop = re.search(
            r"(?ms)^\s*for exe in (?P<words>[^;\n]+); do\s*$(?P<body>.*?)^\s*done\s*$",
            self.winlaunch_check,
        )
        self.assertIsNotNone(loop, "the winlaunch check must loop over generic launchers")
        listing = subprocess.run(
            ["sh", "-c", 'for exe in %s; do printf "%%s\\n" "$exe"; done' % loop.group("words")],
            env={"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "CICD_WORKSPACE": str(ROOT)},
            stdout=subprocess.PIPE, universal_newlines=True, check=True,
        ).stdout.split("\n")
        prefix = str(ROOT) + "/"
        covered = {
            word[len(prefix):]
            for word in listing
            if word.startswith(prefix) and Path(word).exists()
        }
        if re.search(r"briefing-bootstrap\.exe", loop.group("body")):
            covered.discard("bin/briefing-bootstrap.exe")
        return covered

    def test_winlaunch_check_covers_every_generic_launcher_but_the_bootstrap(self):
        expected = self.tracked_launchers() - {"bin/briefing-bootstrap.exe"}
        self.assertIn("hooks/briefing-preload.exe", expected, "tracked launcher set is implausible")
        covered = self.generic_loop_coverage()
        self.assertEqual(
            expected - covered,
            set(),
            "every tracked bin/*.exe and hooks/*.exe except the bootstrap must be "
            "byte-compared with the winlaunch rebuild",
        )
        self.assertNotIn(
            "bin/briefing-bootstrap.exe",
            covered,
            "the generic winlaunch comparison must not classify briefing-bootstrap.exe",
        )

    def test_winlaunch_check_rebuilds_bootstrap_separately(self):
        self.assertRegex(
            self.winlaunch_check,
            r"(?m)^\s*\"\$CICD_OUTPUT/venv/bin/python\"\s+"
            r"\"\$CICD_WORKSPACE/briefing-bootstrap/build\.py\"\s+"
            r"\"\$CICD_OUTPUT/briefing-bootstrap\.exe\"\s*$",
            "the bootstrap must be rebuilt by its own reproducible builder",
        )
        self.assertRegex(
            self.winlaunch_check,
            r"(?m)^\s*if cmp -s \"\$CICD_WORKSPACE/bin/briefing-bootstrap\.exe\"\s+"
            r"\"\$CICD_OUTPUT/briefing-bootstrap\.exe\"; then\s*$",
            "the committed bootstrap must be compared with its own rebuild",
        )

    def test_native_windows_ci_runs_bootstrap_suite(self):
        self.assertRegex(
            self.ci,
            r"(?m)^\s*-\s+os:\s+windows-[0-9]+\s*$",
            "ci.yml must retain a native Windows runner",
        )
        step_blocks = re.findall(
            r"(?ms)^\s{6}- name:.*?(?=^\s{6}- name:|\Z)", self.ci
        )
        bootstrap_steps = [
            step
            for step in step_blocks
            if re.search(
                r"\bpython(?:3)?\b[^\n]*(?:tests/test_briefing_bootstrap\.py|"
                r"tests\.test_briefing_bootstrap)\b",
                step,
            )
        ]
        self.assertTrue(
            bootstrap_steps,
            "ci.yml must invoke tests/test_briefing_bootstrap.py or its unittest module",
        )
        conditional_windows_step = any(
            re.search(r"(?m)^\s*if:\s*runner\.os\s*==\s*'Windows'\s*$", step)
            for step in bootstrap_steps
        )
        job_blocks = re.findall(
            r"(?ms)^  [A-Za-z0-9_-]+:\s*$\n(?P<body>.*?)(?=^  [A-Za-z0-9_-]+:\s*$|\Z)",
            self.ci,
        )
        dedicated_windows_job = any(
            re.search(
                r"(?m)^\s{4}runs-on:\s*windows-[0-9]+\s*$", job
            )
            and re.search(
                r"\bpython(?:3)?\b[^\n]*(?:tests/test_briefing_bootstrap\.py|"
                r"tests\.test_briefing_bootstrap)\b",
                job,
            )
            for job in job_blocks
        )
        self.assertTrue(
            conditional_windows_step or dedicated_windows_job,
            "the bootstrap suite must run in a native Windows CI leg",
        )

    def syntax_check_invocations(self):
        step = re.search(
            r"(?ms)- name: Check Python and shell syntax\s*\n\s*run: \|\n(?P<body>.*?)(?=^\s*- name:|\Z)",
            self.test_workflow,
        )
        self.assertIsNotNone(step, "test.yml must keep its syntax-check step")
        body = step.group("body")
        loops = {
            m.group("var"): m.group("words").split()
            for m in re.finditer(
                r"(?m)\bfor (?P<var>\w+) in (?P<words>[^;\n]+);", body
            )
        }
        checked = []
        for m in re.finditer(r"(?m)\b(?P<shell>sh|bash) -n(?P<operands>[^;\n&|]*)", body):
            operands = m.group("operands").split()
            self.assertEqual(
                len(operands),
                1,
                "'%s -n%s' parses only its first operand; check each script "
                "in its own invocation" % (m.group("shell"), m.group("operands")),
            )
            operand = operands[0].strip("\"'")
            variable = re.fullmatch(r"\$\{?(\w+)\}?", operand)
            files = loops.get(variable.group(1), []) if variable else [operand]
            checked.extend((m.group("shell"), name) for name in files)
        return checked

    def test_ci_syntax_step_checks_every_script_on_its_own(self):
        checked = self.syntax_check_invocations()
        expected = [
            "bin/briefing",
            "bin/briefing-doctor",
            "scripts/binary-lib.sh",
            "scripts/binary-pp-args.sh",
            "scripts/binary-smoke.sh",
            "scripts/binary-verify.sh",
            ".cicd/python+3.12+test.winlaunch.sh",
        ]
        for name in expected:
            with self.subTest(script=name):
                shebang = (ROOT / name).read_text(encoding="utf-8").split("\n", 1)[0]
                shell = "sh" if shebang in ("#!/bin/sh", "#!/bin/dash") else "bash"
                self.assertIn(
                    (shell, name),
                    checked,
                    "%s must be syntax-checked by its own '%s -n' invocation" % (name, shell),
                )

    @unittest.skipUnless(
        shutil.which("bash") and OS_RELEASE.is_file() and os.uname().sysname == "Linux",
        "needs Linux with bash and /etc/os-release; proves only the Linux evidence "
        "path (macOS and Windows evidence are not exercised here)",
    )
    def test_release_evidence_reports_machine_facts_only(self):
        with tempfile.TemporaryDirectory() as tmp:
            dist = Path(tmp)
            (dist / "lib" / "App").mkdir(parents=True)
            (dist / "lib" / "App" / "Briefing.pm").write_text(
                "package App::Briefing;\nour $VERSION = '0.001';\n1;\n", encoding="utf-8"
            )
            binary = dist / "briefing-fake-linux-x86_64"
            binary.write_text("#!/bin/sh\necho 'fake binary' >&2\nexit 1\n", encoding="utf-8")
            binary.chmod(0o755)
            env = {
                "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
                "GITHUB_SHA": "0" * 40,
                "ImageOS": "poison-image",
                "ImageVersion": "poison-version",
                "RUNNER_OS": "PoisonOS",
                "RUNNER_ARCH": "poison-arch",
                "RUNNER_IMAGE": "poison-image",
                "RUNNER_VERSION": "poison-version",
            }
            result = subprocess.run(
                ["bash", str(BINARY_SMOKE), binary.name],
                cwd=str(dist), env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                universal_newlines=True, timeout=120,
            )
            evidence = {}
            for line in result.stdout.splitlines():
                m = re.match(r"release_evidence (\w+)=(.*)$", line)
                if m:
                    evidence.setdefault(m.group(1), []).append(m.group(2))
            digest = hashlib.sha256(binary.read_bytes()).hexdigest()
            uname_m = subprocess.run(
                ["uname", "-m"], stdout=subprocess.PIPE, universal_newlines=True, check=True
            ).stdout.strip()
        release = {}
        for line in OS_RELEASE.read_text(encoding="utf-8", errors="replace").splitlines():
            m = re.match(r"(\w+)=(.*)$", line)
            if m:
                release[m.group(1)] = m.group(2).strip("\"'")
        context = "stdout=%r stderr=%r" % (result.stdout, result.stderr)

        self.assertEqual(len(evidence.get("os", [])), 1, "one os line expected: " + context)
        os_value = evidence["os"][0].lower()
        self.assertNotIn("poisonos", os_value, "os must come from the machine, not RUNNER_OS")
        self.assertTrue(
            any(release.get(k, "").lower() in os_value for k in ("ID", "NAME") if release.get(k)),
            "os must carry the /etc/os-release name (%s): %s" % (release.get("ID"), context),
        )
        if release.get("VERSION_ID"):
            self.assertIn(
                release["VERSION_ID"].lower(), os_value,
                "os must carry the /etc/os-release VERSION_ID: " + context,
            )
        self.assertEqual(
            evidence.get("architecture"), [uname_m],
            "architecture must be uname -m, not RUNNER_ARCH: " + context,
        )
        self.assertEqual(
            evidence.get("asset_hashes"),
            ["%s=sha256:%s" % (binary.name, digest)],
            "asset_hashes must be the binary's name and SHA-256: " + context,
        )
        self.assertEqual(len(evidence.get("abi", [])), 1, "one abi line expected: " + context)
        for field in RUN_LEVEL_EVIDENCE_FIELDS:
            self.assertNotIn(
                field, evidence,
                "%s is run-level evidence the smoke step cannot know truthfully" % field,
            )

if __name__ == "__main__":
    unittest.main()
