"""Static contracts for how Claude Code and Codex reach Windows programs."""

import json
import os
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
PREFIX = "${CLAUDE_PLUGIN_ROOT}/"
MANIFESTS = {
    "claude": REPO_ROOT / "hooks" / "hooks.json",
    "codex": REPO_ROOT / "hooks" / "codex-hooks.json",
}


def entries(harness=None):
    manifests = MANIFESTS.items()
    if harness is not None:
        manifests = ((harness, MANIFESTS[harness]),)
    for name, path in manifests:
        with open(path, encoding="utf-8") as f:
            doc = json.load(f)
        for event, groups in doc["hooks"].items():
            for group in groups:
                for hook in group["hooks"]:
                    yield name, event, hook


def command_path(hook):
    command = hook["command"].split(" ", 1)[0]
    if not command.startswith(PREFIX):
        raise AssertionError("hook command is outside the plugin: %r" % hook["command"])
    return command[len(PREFIX):]


class WindowsWiring(unittest.TestCase):
    def test_claude_entries_are_exec_form(self):
        for _, event, hook in entries("claude"):
            with self.subTest(event=event, command=hook["command"]):
                self.assertIn("args", hook)
                self.assertTrue(hook["command"].startswith(PREFIX))

    def test_every_command_has_a_windows_launcher(self):
        commands = {command_path(hook) for _, _, hook in entries()}
        commands.update(("bin/briefing-doctor", "hooks/briefing-preload"))
        for rel in sorted(commands):
            with self.subTest(command=rel):
                self.assertTrue((REPO_ROOT / (rel + ".exe")).is_file())
                script = REPO_ROOT / rel
                self.assertTrue(script.is_file())
                if rel != "bin/briefing":
                    head = script.read_text(encoding="utf-8").splitlines()[:64]
                    self.assertTrue(
                        any(line.startswith("# winlaunch: run python ") for line in head)
                    )

    def test_briefing_uses_native_bootstrap_directive(self):
        head = (REPO_ROOT / "bin" / "briefing").read_text(
            encoding="utf-8"
        ).splitlines()[:64]
        directives = [line for line in head if line.startswith("# winlaunch:")]
        self.assertEqual(
            directives,
            ["# winlaunch: run bin/briefing-bootstrap.exe"],
        )

    def test_generic_launchers_remain_winlaunch_copies(self):
        bootstrap = REPO_ROOT / "bin" / "briefing-bootstrap.exe"
        launchers = sorted((REPO_ROOT / "hooks").glob("*.exe"))
        launchers.extend(sorted((REPO_ROOT / "bin").glob("*.exe")))
        generic = [path for path in launchers if path != bootstrap]
        reference = REPO_ROOT / "bin" / "briefing.exe"

        self.assertTrue(reference.is_file())
        self.assertGreater(len(generic), 1)
        expected = reference.read_bytes()
        for path in generic:
            with self.subTest(launcher=str(path.relative_to(REPO_ROOT))):
                self.assertEqual(path.read_bytes(), expected)

    def test_bootstrap_exists_and_is_not_a_winlaunch_copy(self):
        bootstrap = REPO_ROOT / "bin" / "briefing-bootstrap.exe"
        winlaunch = REPO_ROOT / "bin" / "briefing.exe"
        self.assertTrue(bootstrap.is_file())
        self.assertNotEqual(bootstrap.read_bytes(), winlaunch.read_bytes())

    def test_claude_and_codex_commands_route_through_bin_briefing(self):
        # k20 changed the earlier claim "each event reaches bin/briefing at most once":
        # SessionStart now reaches it twice, the marketplace notice first and the
        # session-start hook second. Every other event still reaches it exactly once.
        expected = {
            "claude": {
                "PreToolUse": [("hook", "pre-tool-use")],
                "SubagentStart": [("hook", "subagent-start")],
                "SessionStart": [("hook", "marketplace-notice"), ("hook", "session-start")],
            },
            "codex": {
                "SubagentStart": [("hook", "subagent-start")],
                "SessionStart": [("hook", "marketplace-notice"), ("hook", "session-start")],
            },
        }

        for harness, events in expected.items():
            found = {}
            for _, event, hook in entries(harness):
                # No entry may start the Python notice script (or its launcher) directly.
                with self.subTest(harness=harness, event=event, command=hook["command"]):
                    self.assertNotIn("briefing-marketplace-notice", hook["command"])
                    self.assertNotIn("briefing-marketplace-notice", " ".join(hook.get("args", [])))
                if command_path(hook) != "bin/briefing":
                    continue
                if harness == "claude":
                    self.assertEqual(hook["command"], PREFIX + "bin/briefing")
                    invocation = tuple(hook["args"])
                else:
                    words = hook["command"].split(" ")
                    self.assertEqual(words[0], PREFIX + "bin/briefing")
                    self.assertNotIn("args", hook)
                    invocation = tuple(words[1:])
                found.setdefault(event, []).append(invocation)
            self.assertEqual(found, events)

    def test_no_launcher_remains_for_the_python_notice_script(self):
        self.assertTrue((REPO_ROOT / "hooks" / "briefing-marketplace-notice").is_file())
        self.assertFalse((REPO_ROOT / "hooks" / "briefing-marketplace-notice.exe").exists())

    def test_doctor_is_a_script_not_a_symlink(self):
        # A symlink becomes a text file holding its target in a Windows
        # checkout without developer mode.
        self.assertFalse(os.path.islink(REPO_ROOT / "bin" / "briefing-doctor"))


if __name__ == "__main__":
    unittest.main()
