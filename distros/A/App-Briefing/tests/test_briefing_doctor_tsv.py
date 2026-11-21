"""Contract of `briefing doctor --tsv` and `briefing hook <event>`.

Both exist only in the Perl CLI, so every test needs BRIEFING_TEST_CLI (a JSON
argv array naming that CLI) and the whole module skips without it: the Python
reference hooks have no --tsv and no event argument.
"""

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from cli_driver import command_for, known_failure_on_windows_perl_cli

TAB = "\t"
EXTERNAL = os.environ.get("BRIEFING_TEST_CLI") is not None

GOOD_SETTINGS = {
    "enabledPlugins": {
        "briefing@getty": True,
        "demo@claude-plugins-official": True,
    },
    "extraKnownMarketplaces": {"getty": {"source": {"source": "github", "repo": "Getty/m"}}},
}


def agent_text(name, skills=("harbor-core",), description="Does the work.", extra="",
               briefing=True, nl="\n"):
    lines = ["---", "name: " + name]
    if description is not None:
        lines.append("description: " + description)
    if extra:
        lines.append(extra.rstrip("\n"))
    if briefing:
        lines.append("briefing:")
        lines.append("  skills:")
        lines += ["    - " + s for s in skills]
    lines += ["---", "", "You are " + name + ".", ""]
    return nl.join(lines)


@unittest.skipUnless(EXTERNAL, "doctor --tsv exists only in the Perl CLI: set BRIEFING_TEST_CLI")
class TsvBase(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.cwd = self.root / "project"
        self.home = self.root / "home"
        self.cwd.mkdir()
        self.home.mkdir()

    def tearDown(self):
        self.tmp.cleanup()

    def put(self, rel, text, base=None, raw=False):
        path = (base or self.cwd) / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        if raw:
            path.write_bytes(text)
        else:
            with open(str(path), "w", newline="", encoding="utf-8") as handle:
                handle.write(text)
        return path

    def agent(self, file_name, name=None, **kw):
        name = name or file_name[:-3]
        return self.put(".claude/agents/" + file_name, agent_text(name, **kw))

    def settings(self, data=None, raw=None):
        text = raw if raw is not None else json.dumps(GOOD_SETTINGS if data is None else data)
        return self.put(".claude/settings.json", text)

    def team(self):
        self.agent("harbor-worker.md")
        self.agent("harbor-reviewer.md")
        self.put(".claude/skills/harbor-core/SKILL.md", "---\nname: harbor-core\n---\nCORE\n")
        self.settings()

    def env(self):
        env = {k: v for k, v in os.environ.items() if k not in ("CODEX_HOME", "CLAUDE_PLUGIN_ROOT")}
        env["HOME"] = str(self.home)
        env["USERPROFILE"] = str(self.home)
        return env

    def run_cmd(self, argv, stdin=None):
        return subprocess.run(argv, input=stdin, capture_output=True, text=True,
                              encoding="utf-8", env=self.env(), cwd=str(self.cwd), timeout=60)

    def tsv(self, *args):
        return self.run_cmd(command_for("doctor", ["unused"], "--tsv", "--cwd", str(self.cwd), *args))

    def hook(self, payload, *args):
        return self.run_cmd(command_for("hook", ["unused"], *args), stdin=json.dumps(payload))

    @staticmethod
    def rows(result):
        return [line.split(TAB) for line in result.stdout.split("\n") if line]

    def of(self, result, what, status=None, name=None):
        return [r for r in self.rows(result)
                if r[0] == what and (status is None or r[1] == status)
                and (name is None or r[2] == name)]

    def one(self, result, what, status, name):
        hits = self.of(result, what, status, name)
        self.assertEqual(len(hits), 1, "%s %s %s in:\n%s" % (what, status, name, result.stdout))
        return hits[0]

    def install_plugin(self, plugin, skill, enabled=True, market="getty"):
        root = self.home / ".claude" / "plugins" / "cache" / market / plugin / "1.0.0"
        self.put("skills/%s/SKILL.md" % skill, "PLUGIN\n", base=root)
        key = "%s@%s" % (plugin, market)
        self.put(".claude/plugins/installed_plugins.json", json.dumps(
            {"version": 2, "plugins": {key: [{"scope": "user", "installPath": str(root)}]}}),
            base=self.home)
        self.put(".claude/settings.json", json.dumps({"enabledPlugins": {key: enabled}}),
                 base=self.home)


class TsvRows(TsvBase):
    def test_good_team_prints_exactly_the_ok_rows(self):
        self.team()
        r = self.tsv()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertEqual(r.stderr, "")
        self.assertEqual(self.rows(r), [
            ["agent", "ok", "harbor-reviewer.md", ""],
            ["agent", "ok", "harbor-worker.md", ""],
            ["skill", "ok", "harbor-core", ""],
            ["settings", "ok", ".claude/settings.json", ""],
            ["hook", "ok", "harbor-worker", ""],
        ])
        # the empty last field keeps its tab
        self.assertTrue(r.stdout.startswith("agent\tok\tharbor-reviewer.md\t\n"), repr(r.stdout))
        self.assertTrue(all(line.endswith(TAB) for line in r.stdout.splitlines()
                            if "\tok\t" in line))

    def test_warn_alone_exits_zero_missing_exits_one(self):
        self.team()
        self.agent("harbor-plain.md", briefing=False)
        r = self.tsv()
        self.assertEqual(r.returncode, 0, r.stdout)
        self.assertEqual(self.one(r, "agent", "warn", "harbor-plain.md")[3], "no briefing")
        self.agent("harbor-worker.md", skills=("harbor-gone",))
        r = self.tsv()
        self.assertEqual(r.returncode, 1, r.stdout)
        row = self.one(r, "skill", "missing", "harbor-gone")
        self.assertTrue(row[3].startswith("harbor-worker.md declares it; "), row)
        self.assertIn("harbor-gone", self.one(r, "hook", "missing", "harbor-worker")[3])

    def test_usage_errors_exit_two_with_empty_stdout(self):
        self.team()
        cases = [
            command_for("doctor", ["unused"], "--tsv", "--cwd", str(self.root / "nowhere")),
            command_for("doctor", ["unused"], "--tsv", "--cwd", str(self.cwd), "--harness", "codex"),
            command_for("doctor", ["unused"], "--tsv", "--cwd", str(self.cwd), "--bogus"),
            command_for("doctor", ["unused"], "--tsv", "--cwd"),
        ]
        for argv in cases:
            with self.subTest(argv=argv[-3:]):
                r = self.run_cmd(argv)
                self.assertEqual(r.returncode, 2, r.stdout + r.stderr)
                self.assertEqual(r.stdout, "")
                self.assertNotEqual(r.stderr, "")
        for harness in ("claude", "both"):
            self.assertEqual(self.tsv("--harness", harness).returncode, 0)

    def test_no_agents_is_missing(self):
        self.settings()
        r = self.tsv()
        self.assertEqual(r.returncode, 1)
        self.assertEqual(self.one(r, "agent", "missing", ".claude/agents"),
                         ["agent", "missing", ".claude/agents", "no agent files"])
        self.assertEqual(self.of(r, "hook"), [])

    @known_failure_on_windows_perl_cli(
        "k9", "the Perl doctor does not see a dangling symlink on Windows; "
              "t/40-doctor-tsv.t skips it there too")
    def test_dangling_symlink_warns_and_is_no_agent(self):
        self.team()
        link = self.cwd / ".claude" / "agents" / "harbor-gone.md"
        try:
            os.symlink(str(self.root / "nowhere.md"), str(link))
        except (OSError, NotImplementedError):
            self.skipTest("no symlinks here")
        r = self.tsv()
        self.assertEqual(r.returncode, 0, r.stdout)
        row = self.one(r, "agent", "warn", "harbor-gone.md")
        self.assertIn("dangling", row[3])
        self.assertEqual(self.of(r, "hook", None, "harbor-gone"), [])

    def test_folded_description_is_text(self):
        self.team()
        for marker in (">", "|"):
            with self.subTest(marker=marker):
                self.put(".claude/agents/harbor-worker.md",
                         "---\nname: harbor-worker\ndescription: %s\n  Does the\n  work.\n"
                         "briefing:\n  skills:\n    - harbor-core\n---\nbody\n" % marker)
                r = self.tsv()
                self.assertEqual(r.returncode, 0, r.stdout)
                self.one(r, "agent", "ok", "harbor-worker.md")
        self.put(".claude/agents/harbor-worker.md",
                 "---\nname: harbor-worker\ndescription: >\nbriefing:\n  skills:\n"
                 "    - harbor-core\n---\nbody\n")
        self.assertEqual(self.one(self.tsv(), "agent", "missing", "harbor-worker.md")[3],
                         "description is empty")

    def test_unclosed_flow_list_is_not_readable(self):
        self.team()
        self.put(".claude/agents/harbor-worker.md",
                 "---\nname: harbor-worker\ndescription: x\nbriefing:\n  skills: [harbor-core,\n"
                 "    harbor-extra]\n---\n")
        r = self.tsv()
        self.assertEqual(r.returncode, 1)
        self.assertEqual(self.one(r, "agent", "missing", "harbor-worker.md")[3],
                         'briefing.skills is not readable (keep the list on one line or use one '
                         '"- name" per line)')
        self.assertEqual(self.of(r, "agent", "warn"), [])

    def test_bom_before_frontmatter(self):
        self.team()
        path = self.cwd / ".claude" / "agents" / "harbor-worker.md"
        path.write_bytes(b"\xef\xbb\xbf" + path.read_bytes())
        r = self.tsv()
        self.assertEqual(r.returncode, 0, r.stdout)
        self.one(r, "agent", "ok", "harbor-worker.md")
        self.one(r, "hook", "ok", "harbor-worker")
        spawn = self.hook({"hook_event_name": "SubagentStart", "agent_type": "harbor-worker",
                           "cwd": str(self.cwd)})
        self.assertIn("CORE", spawn.stdout)

    def test_crlf_files_read_the_same(self):
        self.team()
        self.put(".claude/agents/harbor-worker.md", agent_text("harbor-worker", nl="\r\n"))
        r = self.tsv()
        self.assertEqual(r.returncode, 0, r.stdout)
        self.assertNotIn("\r", r.stdout)
        self.one(r, "agent", "ok", "harbor-worker.md")

    def test_name_description_allowed_tools_top_level_skills(self):
        self.team()
        self.agent("harbor-worker.md", name="harbor-other")
        self.assertEqual(self.one(self.tsv(), "agent", "missing", "harbor-worker.md")[3],
                         "name 'harbor-other' differs from the file name")
        self.agent("harbor-worker.md", description="")
        self.assertEqual(self.one(self.tsv(), "agent", "missing", "harbor-worker.md")[3],
                         "description is empty")
        self.agent("harbor-worker.md", extra="allowed-tools: Read")
        self.assertEqual(self.one(self.tsv(), "agent", "missing", "harbor-worker.md")[3],
                         "allowed-tools: ignored by Claude Code; use disallowedTools")
        self.agent("harbor-worker.md", extra="skills:\n  - harbor-core")
        r = self.tsv()
        self.assertEqual(r.returncode, 0, r.stdout)
        self.assertEqual(self.one(r, "agent", "warn", "harbor-worker.md")[3],
                         "skills: briefing reads only briefing.skills")

    def test_local_prefix_is_stripped_from_the_file_name_only(self):
        self.team()
        self.put(".claude/agents/.local.harbor-checker.md", agent_text("harbor-checker"))
        self.put(".claude/agents/harbor-api.local.md", agent_text("harbor-api.local"))
        self.put(".claude/agents/harbor-bad.local.md", agent_text("harbor-bad"))
        r = self.tsv()
        self.one(r, "agent", "ok", ".local.harbor-checker.md")
        self.one(r, "agent", "ok", "harbor-api.local.md")
        self.one(r, "agent", "missing", "harbor-bad.local.md")

    def test_plugin_colon_skill(self):
        self.team()
        self.install_plugin("kit", "deploy")
        self.agent("harbor-worker.md", skills=("kit:deploy", "harbor-core"))
        r = self.tsv()
        self.assertEqual(r.returncode, 0, r.stdout)
        self.one(r, "skill", "ok", "kit:deploy")
        self.agent("harbor-worker.md", skills=("other:deploy",))
        r = self.tsv()
        self.assertEqual(r.returncode, 1)
        self.one(r, "skill", "missing", "other:deploy")
        self.agent("harbor-worker.md", skills=("kit:deploy",))
        self.install_plugin("kit", "deploy", enabled=False)
        self.assertEqual(self.tsv().returncode, 1)
        self.install_plugin("kit", "deploy", enabled="true")
        self.assertEqual(self.tsv().returncode, 1)

    def test_settings_rows(self):
        self.team()
        (self.cwd / ".claude" / "settings.json").unlink()
        r = self.tsv()
        self.assertEqual(r.returncode, 1)
        self.assertEqual(self.one(r, "settings", "missing", ".claude/settings.json")[3],
                         "not found or not readable")
        self.settings(raw="not json at all\n")
        r = self.tsv()
        self.assertEqual(r.returncode, 1)
        self.one(r, "settings", "missing", ".claude/settings.json")
        self.assertEqual(self.of(r, "settings", "ok"), [])
        self.settings({"enabledPlugins": {"briefing@getty": True, "tool@elsewhere": True},
                       "extraKnownMarketplaces": {"getty": {}}})
        r = self.tsv()
        self.assertEqual(self.one(r, "settings", "missing", "tool@elsewhere")[3],
                         "marketplace 'elsewhere' is not in extraKnownMarketplaces")
        self.settings({"enabledPlugins": {"skilletor@getty": True},
                       "extraKnownMarketplaces": {"getty": {}}})
        self.one(self.tsv(), "settings", "missing", "briefing")
        self.settings({"enabledPlugins": {"briefing@getty": True, "tool@elsewhere": False},
                       "extraKnownMarketplaces": {"getty": {}}})
        self.assertEqual(self.tsv().returncode, 0)

    def test_enabled_plugins_only_literal_true_counts(self):
        self.team()
        for value in ('"true"', "1", "null", '"yes"'):
            with self.subTest(value=value):
                self.settings(raw='{"enabledPlugins": {"briefing@getty": %s}, '
                                  '"extraKnownMarketplaces": {"getty": {}}}' % value)
                r = self.tsv()
                self.assertEqual(r.returncode, 1, r.stdout)
                self.one(r, "settings", "missing", "briefing")
        self.settings(raw='{"enabledPlugins": {"briefing@getty": true}, '
                          '"extraKnownMarketplaces": {"getty": {}}}')
        self.assertEqual(self.tsv().returncode, 0)
        # a nested key and settings.local.json do not count
        self.settings(raw='{"x": {"enabledPlugins": {"briefing@getty": true}}}')
        self.assertEqual(self.tsv().returncode, 1)
        (self.cwd / ".claude" / "settings.json").unlink()
        self.put(".claude/settings.local.json", json.dumps(GOOD_SETTINGS))
        self.one(self.tsv(), "settings", "missing", ".claude/settings.json")


class WorkerSelection(TsvBase):
    """The hook row follows ack-team check: it covers the worker, not the first agent."""

    def test_hook_check_goes_to_the_worker_not_the_scout(self):
        self.agent("a-scout.md", briefing=False)
        self.agent("b-worker-perl.md")
        self.put(".claude/skills/harbor-core/SKILL.md", "---\nname: harbor-core\n---\nCORE\n")
        self.settings()
        r = self.tsv()
        self.assertEqual(r.returncode, 0, r.stdout)
        self.one(r, "hook", "ok", "b-worker-perl")
        self.assertEqual(self.of(r, "hook", None, "a-scout"), [], r.stdout)
        self.assertEqual(len(self.of(r, "hook")), 1, r.stdout)

    def test_worker_with_a_missing_skill_is_reported_not_the_scout(self):
        self.agent("a-scout.md", briefing=False)
        self.agent("b-worker-perl.md", skills=("harbor-gone",))
        self.settings()
        r = self.tsv()
        self.assertEqual(r.returncode, 1, r.stdout)
        self.assertIn("harbor-gone", self.one(r, "hook", "missing", "b-worker-perl")[3])


class HookEvent(TsvBase):
    def payload(self, **extra):
        data = {"agent_type": "harbor-worker", "cwd": str(self.cwd), "session_id": "s1"}
        data.update(extra)
        return data

    def test_event_argument_routes_in_any_case(self):
        self.team()
        self.assertEqual(self.hook(self.payload()).stdout, "")
        for spelling in ("subagent-start", "SUBAGENT-START", "Subagent-Start", "SubagentStart"):
            with self.subTest(spelling=spelling):
                r = self.hook(self.payload(), spelling)
                self.assertEqual(r.returncode, 0, r.stderr)
                self.assertIn("CORE", r.stdout)
        # the argument replaces the payload's own event
        r = self.hook(self.payload(hook_event_name="PreToolUse"), "subagent-start")
        self.assertIn("CORE", r.stdout)
        r = self.hook(self.payload(hook_event_name="SubagentStart"), "pre-tool-use")
        self.assertNotIn("CORE", r.stdout)

    def test_pre_tool_use_denies_a_missing_skill(self):
        self.team()
        self.agent("harbor-worker.md", skills=("harbor-gone",))
        spawn = {"cwd": str(self.cwd), "session_id": "s1", "tool_name": "Agent",
                 "tool_input": {"subagent_type": "harbor-worker", "description": "x"}}
        for spelling in ("pre-tool-use", "PRE-TOOL-USE", "PreToolUse"):
            with self.subTest(spelling=spelling):
                r = self.hook(spawn, spelling)
                self.assertEqual(r.returncode, 0, r.stderr)
                out = json.loads(r.stdout)["hookSpecificOutput"]
                self.assertEqual(out["permissionDecision"], "deny")
                self.assertIn("harbor-gone", out["permissionDecisionReason"])

    def test_session_start_by_argument_equals_by_payload(self):
        self.team()
        self.agent("harbor-worker.md", skills=("harbor-gone",))
        base = {"cwd": str(self.cwd), "session_id": "s1", "source": "startup"}
        by_arg = self.hook(base, "session-start")
        by_payload = self.hook(dict(base, hook_event_name="SessionStart"))
        self.assertEqual((by_arg.returncode, by_arg.stdout), (by_payload.returncode, by_payload.stdout))
        self.assertIn("harbor-gone", by_arg.stdout)

    def test_unknown_event_exits_zero_without_briefing(self):
        # Invalid hook input never fails a hook: an unknown event is ignored, exit 0.
        self.team()
        payload = self.payload(hook_event_name="SubagentStart")
        for bad in ("bogus", "subagent", "stop", "subagent-stop"):
            with self.subTest(argument=bad):
                r = self.hook(payload, bad)
                self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
                self.assertNotIn("CORE", r.stdout)


if __name__ == "__main__":
    unittest.main()
