"""Tests for the checks that run before any spawn.

`briefing-doctor` walks every briefing-aware agent of a project in both
harnesses and reports what would fail at spawn time. The `SessionStart`
branch of the hook runs the same checks and tells the human, so a broken
declaration surfaces before a subagent burns tokens on it.

Same sandboxing as the other suites: controlled HOME and cwd, the hook run
as a subprocess.
"""

import json
import os
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

from cli_driver import command_for

REPO_ROOT = Path(__file__).resolve().parent.parent
HOOK = REPO_ROOT / "hooks" / "briefing-preload"
# On Windows the command is bin/briefing-doctor.exe (winlaunch); CreateProcess
# would take the sh script itself if named without .exe.
DOCTOR = REPO_ROOT / "bin" / ("briefing-doctor" + (".exe" if os.name == "nt" else ""))


def write(path: Path, body: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(textwrap.dedent(body).lstrip("\n"), encoding="utf-8")


class Sandbox(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.cwd = self.root / "project"
        self.home = self.root / "home"
        self.cwd.mkdir()
        self.home.mkdir()

    def tearDown(self):
        self.tmp.cleanup()

    def env(self):
        env = {k: v for k, v in os.environ.items() if k != "CODEX_HOME"}
        env["HOME"] = str(self.home)
        env["PYTHONIOENCODING"] = "utf-8"
        return env

    def claude_agent(self, name, skills, file_name=None):
        items = "".join(f"    - {s}\n" for s in skills)
        write(
            self.cwd / ".claude/agents" / f"{file_name or name}.md",
            f"---\nname: {name}\nbriefing:\n  skills:\n{items}---\nbody\n",
        )

    def codex_agent(self, name, body):
        write(self.cwd / ".codex/agents" / f"{name}.toml", body)

    def claude_skill(self, name, body="BODY\n"):
        write(self.cwd / ".claude/skills" / name / "SKILL.md", body)

    def codex_skill(self, name, body="BODY\n"):
        write(self.cwd / ".agents/skills" / name / "SKILL.md", body)


class DoctorTests(Sandbox):
    def doctor(self, *args):
        return subprocess.run(
            command_for(
                "doctor", [str(DOCTOR)], "--cwd", str(self.cwd), *args
            ),
            capture_output=True,
            text=True,
            encoding="utf-8",
            env=self.env(),
            timeout=10,
        )

    def test_healthy_agents_exit_zero_and_are_listed(self):
        self.claude_agent("reviewer", ["foo"])
        self.claude_skill("foo")
        self.codex_agent("helper", 'name = "helper"\n# briefing: skills = ["bar"]\n')
        self.codex_skill("bar")

        proc = self.doctor()

        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        self.assertIn("reviewer", proc.stdout)
        self.assertIn("helper", proc.stdout)
        self.assertNotIn("FAIL", proc.stdout)

    def test_unknown_skill_fails(self):
        self.claude_agent("reviewer", ["foo", "gone"])
        self.claude_skill("foo")

        proc = self.doctor()

        self.assertEqual(proc.returncode, 1)
        self.assertIn("FAIL", proc.stdout)
        self.assertIn("gone", proc.stdout)

    def test_codex_unknown_skill_fails(self):
        self.codex_agent("helper", 'name = "helper"\n# briefing: skills = ["gone"]\n')

        proc = self.doctor()

        self.assertEqual(proc.returncode, 1)
        self.assertIn("gone", proc.stdout)

    def test_legacy_briefing_table_fails(self):
        # Codex 0.153 drops the whole agent over it — that is a failure,
        # even though every skill would resolve.
        self.codex_agent("helper", 'name = "helper"\n\n[briefing]\nskills = ["bar"]\n')
        self.codex_skill("bar")

        proc = self.doctor()

        self.assertEqual(proc.returncode, 1)
        self.assertIn("[briefing]", proc.stdout)

    def test_oversized_briefing_warns_without_failing(self):
        self.claude_agent("reviewer", ["big"])
        self.claude_skill("big", "x" * (70 * 1024))

        proc = self.doctor()

        self.assertEqual(proc.returncode, 0)
        self.assertIn("WARN", proc.stdout)

    def test_agents_without_declaration_are_not_listed(self):
        write(self.cwd / ".claude/agents/plain.md", "---\nname: plain\n---\nbody\n")
        self.codex_agent("plain_codex", 'name = "plain_codex"\n')

        proc = self.doctor()

        self.assertEqual(proc.returncode, 0)
        self.assertNotIn("plain", proc.stdout)

    def test_harness_filter(self):
        self.claude_agent("reviewer", ["gone"])
        self.codex_agent("helper", 'name = "helper"\n# briefing: skills = ["bar"]\n')
        self.codex_skill("bar")

        proc = self.doctor("--harness", "codex")

        self.assertEqual(proc.returncode, 0)
        self.assertNotIn("reviewer", proc.stdout)

    def test_hook_script_takes_doctor_subcommand(self):
        self.claude_agent("reviewer", ["gone"])

        proc = subprocess.run(
            command_for(
                "doctor", ["python3", str(HOOK), "doctor"], "--cwd", str(self.cwd)
            ),
            capture_output=True,
            text=True,
            encoding="utf-8",
            env=self.env(),
            timeout=10,
        )

        self.assertEqual(proc.returncode, 1)
        self.assertIn("gone", proc.stdout)


class PreflightTests(Sandbox):
    def session_start(self, transcript_path=None, source="startup"):
        payload = {
            "hook_event_name": "SessionStart",
            "session_id": "s",
            "cwd": str(self.cwd),
            "source": source,
            "transcript_path": transcript_path,
        }
        return subprocess.run(
            command_for("hook", ["python3", str(HOOK)]),
            input=json.dumps(payload),
            capture_output=True,
            text=True,
            encoding="utf-8",
            env=self.env(),
            timeout=10,
        )

    def test_broken_agent_is_reported_at_session_start(self):
        self.claude_agent("reviewer", ["gone"])

        proc = self.session_start()

        self.assertEqual(proc.returncode, 0)
        out = json.loads(proc.stdout)
        self.assertIn("reviewer", out["systemMessage"])
        self.assertIn("gone", out["systemMessage"])
        # a warning for the human, never context for the model
        self.assertNotIn("hookSpecificOutput", out)

    def test_healthy_project_is_silent(self):
        self.claude_agent("reviewer", ["foo"])
        self.claude_skill("foo")

        proc = self.session_start()

        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout, "")

    def test_oversized_briefing_is_not_a_session_start_warning(self):
        # Too big still works: that is for the doctor and the spawn-time
        # audit line, not for a warning at every session start.
        self.claude_agent("reviewer", ["big"])
        self.claude_skill("big", "x" * (70 * 1024))

        proc = self.session_start()

        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout, "")

    def test_project_without_agents_is_silent(self):
        proc = self.session_start()
        self.assertEqual(proc.stdout, "")

    def test_only_the_running_harness_is_checked(self):
        self.claude_agent("reviewer", ["gone"])
        self.codex_agent("helper", 'name = "helper"\n# briefing: skills = ["also-gone"]\n')

        codex = self.session_start(transcript_path=f"{self.home}/.codex/sessions/x.jsonl")
        claude = self.session_start(transcript_path=f"{self.home}/.claude/projects/p/x.jsonl")

        codex_msg = json.loads(codex.stdout)["systemMessage"]
        claude_msg = json.loads(claude.stdout)["systemMessage"]
        self.assertIn("also-gone", codex_msg)
        self.assertNotIn("reviewer", codex_msg)
        self.assertIn("reviewer", claude_msg)
        self.assertNotIn("also-gone", claude_msg)

    def test_compaction_does_not_repeat_the_check(self):
        self.claude_agent("reviewer", ["gone"])

        proc = self.session_start(source="compact")

        self.assertEqual(proc.stdout, "")

    def test_garbage_agent_file_does_not_break_session_start(self):
        write(self.cwd / ".codex/agents/broken.toml", "this is = = not toml [[[\n")
        write(self.cwd / ".claude/agents/broken.md", "---\n: : :\n---\n")

        proc = self.session_start()

        self.assertEqual(proc.returncode, 0)


if __name__ == "__main__":
    unittest.main()
