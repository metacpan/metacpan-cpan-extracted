"""Tests for hooks/briefing-marketplace-notice.

The hook runs as a subprocess with a controlled HOME and CLAUDE_PLUGIN_ROOT so
nothing on the developer's machine leaks into the sandbox.

The plugin starts the notice as `briefing hook marketplace-notice` (k20); `briefing notice`
stays. Without BRIEFING_TEST_CLI both spellings run the Python reference script, which
ignores its arguments; with it, each spelling is driven through the Perl CLI. Every claim
holds for both.
"""

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from cli_driver import command_for

REPO_ROOT = Path(__file__).resolve().parent.parent
HOOK = REPO_ROOT / "hooks" / "briefing-marketplace-notice"
NOTICE = (
    "briefing is now also in the shared Getty marketplace, alongside the other "
    "plugins: /plugin marketplace add Getty/marketplace \u2014 then /plugin install "
    "briefing@getty. Your install from Getty/briefing keeps working and stays "
    "maintained, so there is nothing you have to do."
)


def run_hook(*, fake_home, plugin_root, spelling="notice"):
    env = {
        **os.environ,
        "HOME": str(fake_home),
        "PYTHONIOENCODING": "utf-8",
    }
    if plugin_root is None:
        env.pop("CLAUDE_PLUGIN_ROOT", None)
    else:
        env["CLAUDE_PLUGIN_ROOT"] = str(plugin_root)
    if spelling == "notice":
        command = command_for("notice", ["python3", str(HOOK)])
    else:
        command = command_for("hook", ["python3", str(HOOK)], "marketplace-notice")
    return subprocess.run(
        command,
        capture_output=True,
        text=True,
        encoding="utf-8",
        env=env,
        timeout=10,
    )


class MarketplaceNoticeTests(unittest.TestCase):
    spelling = "notice"

    def run_hook(self, **kwargs):
        return run_hook(spelling=self.spelling, **kwargs)

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name) / "home"
        self.home.mkdir()

    def tearDown(self):
        self.tmp.cleanup()

    def cache_root(self, marketplace):
        return self.home / ".claude/plugins/cache" / marketplace / "briefing/0.1.0"

    def test_notice_shown_for_the_old_marketplace(self):
        proc = self.run_hook(fake_home=self.home, plugin_root=self.cache_root("briefing"))
        self.assertEqual(proc.returncode, 0)
        payload = json.loads(proc.stdout)
        self.assertIn("Getty/marketplace", payload["systemMessage"])
        self.assertIn("briefing@getty", payload["systemMessage"])

    def test_notice_says_the_old_path_keeps_working(self):
        proc = self.run_hook(fake_home=self.home, plugin_root=self.cache_root("briefing"))
        message = json.loads(proc.stdout)["systemMessage"]
        self.assertIn("keeps working", message)

    def test_silent_on_the_shared_marketplace(self):
        proc = self.run_hook(fake_home=self.home, plugin_root=self.cache_root("getty"))
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout.strip(), "")

    def test_silent_without_a_plugin_root(self):
        # --plugin-dir and local checkouts have no marketplace to move away from.
        proc = self.run_hook(fake_home=self.home, plugin_root=None)
        self.assertEqual(proc.stdout.strip(), "")

    def test_silent_outside_the_plugin_cache(self):
        proc = self.run_hook(fake_home=self.home, plugin_root=REPO_ROOT)
        self.assertEqual(proc.stdout.strip(), "")

    def test_shown_only_once(self):
        first = self.run_hook(fake_home=self.home, plugin_root=self.cache_root("briefing"))
        self.assertNotEqual(first.stdout.strip(), "")
        second = self.run_hook(fake_home=self.home, plugin_root=self.cache_root("briefing"))
        self.assertEqual(second.stdout.strip(), "")

    def test_unwritable_state_still_notifies(self):
        # Saying it every session beats never saying it.
        state_dir = self.home / ".claude"
        state_dir.mkdir(parents=True)
        state_dir.chmod(0o500)
        try:
            proc = self.run_hook(fake_home=self.home, plugin_root=self.cache_root("briefing"))
            self.assertEqual(proc.returncode, 0)
            self.assertIn("Getty/marketplace", json.loads(proc.stdout)["systemMessage"])
        finally:
            state_dir.chmod(0o700)

    def test_the_message_is_exactly_the_notice(self):
        proc = self.run_hook(fake_home=self.home, plugin_root=self.cache_root("briefing"))
        self.assertEqual(json.loads(proc.stdout), {"systemMessage": NOTICE})
        self.assertEqual(len(proc.stdout.splitlines()), 1)

    def test_records_the_marketplace_it_saw(self):
        self.run_hook(fake_home=self.home, plugin_root=self.cache_root("briefing"))
        state = self.home / ".claude" / ".briefing-marketplace-notice"
        self.assertEqual(state.read_text(encoding="utf-8"), "briefing\n")

    def test_silent_runs_leave_no_state(self):
        for root in (self.cache_root("getty"), None, REPO_ROOT):
            with self.subTest(root=root):
                proc = self.run_hook(fake_home=self.home, plugin_root=root)
                self.assertEqual((proc.stdout, proc.stderr, proc.returncode), ("", "", 0))
        self.assertFalse((self.home / ".claude").exists())

    def test_dot_and_dotdot_components_are_folded_like_normpath(self):
        cache = self.home / ".claude/plugins/cache"
        windows = os.name == "nt"
        shapes = (
            ("a dot before cache", str(cache.parent) + "/./cache/briefing/briefing/0.1.0", True),
            ("a dotdot leaving a cache", str(cache) + "/getty/../briefing/briefing/0.1.0", True),
            ("a dotdot entering getty", str(cache) + "/briefing/../getty/briefing/0.1.0", False),
            ("a dotdot removing cache", str(cache) + "/../briefing/0.1.0", False),
            ("a dotdot above the root", "/../cache/briefing/briefing/0.1.0", True),
            ("cache as the last component", str(cache), False),
            ("a backslash path", "\\home\\x\\plugins\\cache\\briefing\\briefing\\0.1.0", windows),
        )
        for label, root, shown in shapes:
            with self.subTest(label=label):
                state = self.home / ".claude" / ".briefing-marketplace-notice"
                if state.exists():
                    state.unlink()
                proc = self.run_hook(fake_home=self.home, plugin_root=root)
                self.assertEqual(proc.returncode, 0)
                self.assertEqual(proc.stderr, "")
                if shown:
                    self.assertEqual(json.loads(proc.stdout), {"systemMessage": NOTICE})
                else:
                    self.assertEqual(proc.stdout, "")

    def test_never_writes_to_stderr(self):
        proc = self.run_hook(fake_home=self.home, plugin_root=self.cache_root("briefing"))
        self.assertEqual(proc.stderr, "")


class MarketplaceNoticeHookWordTests(MarketplaceNoticeTests):
    """The plugin's own spelling, `hook marketplace-notice`, behaves exactly alike."""

    spelling = "hook"


if __name__ == "__main__":
    unittest.main()
