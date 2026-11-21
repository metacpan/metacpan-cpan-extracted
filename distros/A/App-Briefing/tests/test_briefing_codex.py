"""End-to-end tests for the Codex side of hooks/briefing-preload.

Codex spawns subagents through a `SubagentStart` hook event rather than a
`PreToolUse` on an Agent tool, declares agents as TOML, and takes injected
context via `additionalContext` instead of a rewritten prompt. Same hook
script, different world — these tests drive it the way Codex would.

The hook runs as a subprocess with a controlled HOME and cwd so nothing on
the developer's machine leaks in.
"""

import json
import os
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

from cli_driver import assert_skill_dir, command_for

REPO_ROOT = Path(__file__).resolve().parent.parent
HOOK = REPO_ROOT / "hooks" / "briefing-preload"


def run_hook(payload, *, fake_home, extra_env=None):
    env = {k: v for k, v in os.environ.items() if k != "CODEX_HOME"}
    env["HOME"] = str(fake_home)
    env["PYTHONIOENCODING"] = "utf-8"
    env.update(extra_env or {})
    proc = subprocess.run(
        command_for("hook", ["python3", str(HOOK)]),
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        encoding="utf-8",
        env=env,
        timeout=10,
    )
    return proc


def write(path: Path, body: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(textwrap.dedent(body).lstrip("\n"), encoding="utf-8")


class CodexHookTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.cwd = self.root / "project"
        self.home = self.root / "home"
        self.cwd.mkdir()
        self.home.mkdir()

    def tearDown(self):
        self.tmp.cleanup()

    def _payload(self, **overrides):
        payload = {
            "hook_event_name": "SubagentStart",
            "agent_type": "demo",
            "agent_id": "agent_123",
            "turn_id": "turn_123",
            "cwd": str(self.cwd),
        }
        payload.update(overrides)
        return payload

    def _agent(self, body):
        write(self.cwd / ".codex/agents/demo.toml", body)

    def _skill(self, name, body="Skill body here.\n", root=None):
        base = root if root is not None else self.cwd / ".agents/skills"
        write(
            base / name / "SKILL.md",
            "---\nname: %s\ndescription: d\n---\n\n%s" % (name, body),
        )

    def _out(self, proc):
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertTrue(proc.stdout, "hook produced no stdout")
        return json.loads(proc.stdout)

    # --- the core path ---------------------------------------------------

    def test_declared_skill_is_injected_as_additional_context(self):
        self._agent("""
            name = "demo"
            description = "x"
            # briefing: skills = ["demo-skill"]
            developer_instructions = "do things"
        """)
        self._skill("demo-skill", "The body of the demo skill.\n")

        out = self._out(run_hook(self._payload(), fake_home=self.home))

        hso = out["hookSpecificOutput"]
        self.assertEqual(hso["hookEventName"], "SubagentStart")
        self.assertIn("The body of the demo skill.", hso["additionalContext"])

    # --- resolution -------------------------------------------------------

    def test_skill_resolves_from_user_agents_root(self):
        self._agent("""
            name = "demo"
            # briefing: skills = ["user-skill"]
        """)
        self._skill("user-skill", "From the user root.\n", root=self.home / ".agents/skills")

        out = self._out(run_hook(self._payload(), fake_home=self.home))

        self.assertIn("From the user root.", out["hookSpecificOutput"]["additionalContext"])

    def test_project_root_wins_over_user_root(self):
        self._agent("""
            name = "demo"
            # briefing: skills = ["dup"]
        """)
        self._skill("dup", "PROJECT COPY\n")
        self._skill("dup", "USER COPY\n", root=self.home / ".agents/skills")

        ctx = self._out(run_hook(self._payload(), fake_home=self.home))["hookSpecificOutput"]["additionalContext"]

        self.assertIn("PROJECT COPY", ctx)
        self.assertNotIn("USER COPY", ctx)

    def test_plugin_namespaced_skill_resolves_from_plugin_cache(self):
        # Codex addresses plugin skills as `plugin:skill`, same syntax as
        # Claude Code, and installs them under a versioned cache path.
        self._agent("""
            name = "demo"
            # briefing: skills = ["someplugin:tool"]
        """)
        write(
            self.home / ".codex/plugins/cache/mp/someplugin/1.2.3/skills/tool/SKILL.md",
            "---\nname: tool\ndescription: d\n---\n\nPlugin skill body.\n",
        )

        out = self._out(run_hook(self._payload(), fake_home=self.home))

        self.assertIn("Plugin skill body.", out["hookSpecificOutput"]["additionalContext"])

    # --- the failure path -------------------------------------------------

    def test_missing_skill_yields_abort_instruction_not_content(self):
        # Codex cannot deny a spawn, so the nearest thing to Claude Code's
        # hard fail is an agent that starts and refuses to work.
        self._agent("""
            name = "demo"
            # briefing: skills = ["gone"]
        """)

        out = self._out(run_hook(self._payload(), fake_home=self.home))
        ctx = out["hookSpecificOutput"]["additionalContext"]

        self.assertIn("gone", ctx)
        self.assertIn("NOT", ctx)
        self.assertIn("briefing", out["systemMessage"])
        self.assertIn("gone", out["systemMessage"])

    def test_one_missing_skill_aborts_even_when_others_resolve(self):
        self._agent("""
            name = "demo"
            # briefing: skills = ["present", "absent"]
        """)
        self._skill("present", "SHOULD NOT BE USED AS A BRIEFING\n")

        ctx = self._out(run_hook(self._payload(), fake_home=self.home))["hookSpecificOutput"]["additionalContext"]

        self.assertIn("absent", ctx)
        self.assertNotIn("SHOULD NOT BE USED AS A BRIEFING", ctx)

    # --- no-op cases ------------------------------------------------------

    def test_other_hook_event_is_noop(self):
        proc = run_hook(
            {"hook_event_name": "SubagentStop", "agent_type": "demo", "cwd": str(self.cwd)},
            fake_home=self.home,
        )
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout, "")

    def test_unknown_agent_is_noop(self):
        proc = run_hook(self._payload(agent_type="nosuch"), fake_home=self.home)
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout, "")

    def test_agent_without_briefing_declaration_is_noop(self):
        self._agent("""
            name = "demo"
            description = "x"
            developer_instructions = "do things"
        """)
        proc = run_hook(self._payload(), fake_home=self.home)
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout, "")

    def test_codex_own_skills_config_is_not_read_as_a_briefing(self):
        # `[[skills.config]]` is Codex's own enable/disable mechanism. It
        # means "visible to the agent", not "preloaded", and briefing must
        # not quietly reinterpret it.
        self._agent("""
            name = "demo"

            [[skills.config]]
            path = "/somewhere/tool/SKILL.md"
            enabled = true
        """)
        proc = run_hook(self._payload(), fake_home=self.home)
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout, "")

    # --- where the declaration lives ---------------------------------------

    def test_declaration_comment_inside_multiline_string_is_ignored(self):
        # A `# briefing:` line inside developer_instructions is prompt text,
        # not a declaration — e.g. an agent whose instructions explain briefing.
        self._agent('''
            name = "demo"
            developer_instructions = """
            # briefing: skills = ["quoted-only"]
            """
        ''')
        self._skill("quoted-only", "MUST NOT BE INJECTED\n")

        proc = run_hook(self._payload(), fake_home=self.home)
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout, "")

    def test_declaration_comment_after_multiline_string_is_read(self):
        self._agent('''
            name = "demo"
            developer_instructions = """
            do things
            """
            # briefing: skills = ["late"]
        ''')
        self._skill("late", "LATE OK\n")

        ctx = self._out(run_hook(self._payload(), fake_home=self.home))["hookSpecificOutput"]["additionalContext"]

        self.assertIn("LATE OK", ctx)

    def test_legacy_briefing_table_still_briefs_but_warns(self):
        # Codex 0.147 accepted a [briefing] table; 0.153 rejects the whole
        # agent file over it ("unknown field `briefing`"). Where it still
        # spawns, brief it — and tell the human to migrate.
        self._agent("""
            name = "demo"

            [briefing]
            skills = ["legacy"]
        """)
        self._skill("legacy", "LEGACY BODY\n")

        out = self._out(run_hook(self._payload(), fake_home=self.home))

        self.assertIn("LEGACY BODY", out["hookSpecificOutput"]["additionalContext"])
        self.assertIn("[briefing]", out["systemMessage"])
        self.assertIn("# briefing: skills", out["systemMessage"])

    def test_comment_wins_over_legacy_table(self):
        self._agent("""
            name = "demo"
            # briefing: skills = ["new"]

            [briefing]
            skills = ["old"]
        """)
        self._skill("new", "NEW BODY\n")
        self._skill("old", "OLD BODY\n")

        out = self._out(run_hook(self._payload(), fake_home=self.home))
        ctx = out["hookSpecificOutput"]["additionalContext"]

        self.assertIn("NEW BODY", ctx)
        self.assertNotIn("OLD BODY", ctx)
        self.assertIn("[briefing]", out["systemMessage"])

    def test_comment_form_needs_no_warning(self):
        self._agent("""
            name = "demo"
            # briefing: skills = ["quiet"]
        """)
        self._skill("quiet", "QUIET\n")

        out = self._out(run_hook(self._payload(), fake_home=self.home))

        self.assertNotIn("[briefing]", out["systemMessage"])
        self.assertIn("quiet", out["systemMessage"])

    def test_large_briefing_warns_in_system_message(self):
        self._agent("""
            name = "demo"
            # briefing: skills = ["big"]
        """)
        self._skill("big", "x" * (70 * 1024))

        out = self._out(run_hook(self._payload(), fake_home=self.home))

        self.assertIn("additionalContext", out["hookSpecificOutput"])
        self.assertIn("over 64 kB", out["systemMessage"])

    def test_successful_briefing_is_audited_and_wrapped(self):
        self._agent("""
            name = "demo"
            # briefing: skills = ["one", "two"]
        """)
        self._skill("one", "ONE\n")
        self._skill("two", "TWO\n")

        out = self._out(run_hook(self._payload(), fake_home=self.home))
        ctx = out["hookSpecificOutput"]["additionalContext"]

        self.assertRegex(ctx, r'<skill name="one"[^>]*>\s*ONE\s*</skill>')
        self.assertIn('<skill name="two"', ctx)
        self.assertEqual(len(out["systemMessage"].splitlines()), 1)
        self.assertIn("demo", out["systemMessage"])
        self.assertIn("one, two", out["systemMessage"])

    def test_skill_element_carries_its_directory_for_references(self):
        self._agent("""
            name = "demo"
            # briefing: skills = ["one"]
        """)
        self._skill("one", "See references/api.md.\n")
        write(self.cwd / ".agents/skills/one/references/api.md", "API\n")

        out = self._out(run_hook(self._payload(), fake_home=self.home))
        ctx = out["hookSpecificOutput"]["additionalContext"]

        skill_dir = os.path.abspath(self.cwd / ".agents/skills/one")
        assert_skill_dir(self, ctx, "one", skill_dir)
        self.assertIn("relative to", ctx)
        self.assertNotIn("\nAPI\n", ctx)

    # --- finding the agent file the way Codex does -------------------------

    def test_agent_found_by_name_field_not_file_name(self):
        # Codex takes the role name from `name`; the file name is free.
        write(self.cwd / ".codex/agents/whatever.toml", """
            name = "demo"
            # briefing: skills = ["by-name"]
        """)
        self._skill("by-name", "BY NAME\n")

        ctx = self._out(run_hook(self._payload(), fake_home=self.home))["hookSpecificOutput"]["additionalContext"]

        self.assertIn("BY NAME", ctx)

    def test_agent_found_in_subdirectory(self):
        # Codex discovers every *.toml under agents/, recursively.
        write(self.cwd / ".codex/agents/team/demo.toml", """
            name = "demo"
            # briefing: skills = ["nested"]
        """)
        self._skill("nested", "NESTED\n")

        ctx = self._out(run_hook(self._payload(), fake_home=self.home))["hookSpecificOutput"]["additionalContext"]

        self.assertIn("NESTED", ctx)

    def test_file_named_after_agent_but_declaring_another_name_is_not_it(self):
        write(self.cwd / ".codex/agents/demo.toml", """
            name = "someone_else"
            # briefing: skills = ["wrong"]
        """)
        self._skill("wrong", "WRONG AGENT\n")

        proc = run_hook(self._payload(), fake_home=self.home)
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout, "")

    def test_agent_found_in_repo_root_from_subdirectory(self):
        # Every directory from the project root down to cwd is a config layer.
        (self.cwd / ".git").mkdir()
        sub = self.cwd / "pkg" / "deep"
        sub.mkdir(parents=True)
        self._agent("""
            name = "demo"
            # briefing: skills = ["rooted"]
        """)
        self._skill("rooted", "ROOTED\n")

        ctx = self._out(run_hook(self._payload(cwd=str(sub)), fake_home=self.home))["hookSpecificOutput"]["additionalContext"]

        self.assertIn("ROOTED", ctx)

    def test_nearest_project_layer_wins(self):
        (self.cwd / ".git").mkdir()
        sub = self.cwd / "pkg"
        write(self.cwd / ".codex/agents/demo.toml", """
            name = "demo"
            # briefing: skills = ["outer"]
        """)
        write(sub / ".codex/agents/demo.toml", """
            name = "demo"
            # briefing: skills = ["inner"]
        """)
        self._skill("outer", "OUTER\n")
        self._skill("inner", "INNER\n")

        ctx = self._out(run_hook(self._payload(cwd=str(sub)), fake_home=self.home))["hookSpecificOutput"]["additionalContext"]

        self.assertIn("INNER", ctx)
        self.assertNotIn("OUTER", ctx)

    def test_nothing_above_the_project_root_is_read(self):
        (self.cwd / ".git").mkdir()
        write(self.root / ".codex/agents/demo.toml", """
            name = "demo"
            # briefing: skills = ["outside"]
        """)
        self._skill("outside", "OUTSIDE\n")

        proc = run_hook(self._payload(), fake_home=self.home)
        self.assertEqual(proc.stdout, "")

    def test_agent_declared_in_config_toml_with_config_file(self):
        # `[agents.<name>] config_file` points anywhere; relative paths are
        # relative to the config.toml, and the file need not carry `name`.
        write(self.cwd / ".codex/config.toml", """
            [agents.demo]
            description = "declared"
            config_file = "roles/demo-role.toml"
        """)
        write(self.cwd / ".codex/roles/demo-role.toml", """
            # briefing: skills = ["declared-skill"]
            developer_instructions = "x"
        """)
        self._skill("declared-skill", "DECLARED\n")

        ctx = self._out(run_hook(self._payload(), fake_home=self.home))["hookSpecificOutput"]["additionalContext"]

        self.assertIn("DECLARED", ctx)

    def test_declared_role_wins_over_discovered_file_in_same_layer(self):
        write(self.cwd / ".codex/config.toml", """
            [agents.demo]
            config_file = "roles/demo.toml"
        """)
        write(self.cwd / ".codex/roles/demo.toml", """
            # briefing: skills = ["declared"]
        """)
        self._agent("""
            name = "demo"
            # briefing: skills = ["discovered"]
        """)
        self._skill("declared", "DECLARED WINS\n")
        self._skill("discovered", "DISCOVERED\n")

        ctx = self._out(run_hook(self._payload(), fake_home=self.home))["hookSpecificOutput"]["additionalContext"]

        self.assertIn("DECLARED WINS", ctx)
        self.assertNotIn("DISCOVERED", ctx)

    def test_declared_role_is_found_without_tomllib(self):
        # The default Python driver proves its tomllib fallback. A configured
        # Perl CLI ignores this Python-only shim; that run verifies only the
        # equivalent declared-role semantics.
        shim = self.root / "notoml"
        write(shim / "tomllib.py", "raise ImportError('blocked for test')\n")
        write(self.cwd / ".codex/config.toml", """
            model = "x"

            [agents.other]
            config_file = "roles/other.toml"

            [agents.demo]
            description = "d"
            config_file = 'roles/demo.toml'
        """)
        write(self.cwd / ".codex/roles/demo.toml", """
            # briefing: skills = ["fallback-declared"]
        """)
        self._skill("fallback-declared", "FALLBACK DECLARED\n")

        out = self._out(run_hook(
            self._payload(), fake_home=self.home, extra_env={"PYTHONPATH": str(shim)},
        ))

        self.assertIn("FALLBACK DECLARED", out["hookSpecificOutput"]["additionalContext"])

    # --- CODEX_HOME ---------------------------------------------------------

    def test_codex_home_is_honoured_for_agents_skills_and_plugins(self):
        ch = self.root / "codexhome"
        write(ch / "agents/demo.toml", """
            name = "demo"
            # briefing: skills = ["home-skill", "someplugin:tool"]
        """)
        self._skill("home-skill", "CODEX HOME SKILL\n", root=ch / "skills")
        write(
            ch / "plugins/cache/mp/someplugin/1.0.0/skills/tool/SKILL.md",
            "---\nname: tool\ndescription: d\n---\n\nCODEX HOME PLUGIN\n",
        )

        out = self._out(run_hook(
            self._payload(), fake_home=self.home, extra_env={"CODEX_HOME": str(ch)},
        ))
        ctx = out["hookSpecificOutput"]["additionalContext"]

        self.assertIn("CODEX HOME SKILL", ctx)
        self.assertIn("CODEX HOME PLUGIN", ctx)

    # --- skill roots Codex searches ----------------------------------------

    def test_skill_resolves_from_project_codex_skills(self):
        self._agent("""
            name = "demo"
            # briefing: skills = ["layer-skill"]
        """)
        self._skill("layer-skill", "LAYER SKILL\n", root=self.cwd / ".codex/skills")

        ctx = self._out(run_hook(self._payload(), fake_home=self.home))["hookSpecificOutput"]["additionalContext"]

        self.assertIn("LAYER SKILL", ctx)

    def test_skill_resolves_from_repo_root_agents_skills(self):
        (self.cwd / ".git").mkdir()
        sub = self.cwd / "a" / "b"
        sub.mkdir(parents=True)
        self._agent("""
            name = "demo"
            # briefing: skills = ["repo-skill"]
        """)
        self._skill("repo-skill", "REPO ROOT SKILL\n")

        ctx = self._out(run_hook(self._payload(cwd=str(sub)), fake_home=self.home))["hookSpecificOutput"]["additionalContext"]

        self.assertIn("REPO ROOT SKILL", ctx)

    def test_skill_resolves_from_system_skill_cache(self):
        self._agent("""
            name = "demo"
            # briefing: skills = ["bundled"]
        """)
        self._skill("bundled", "BUNDLED\n", root=self.home / ".codex/skills/.system")

        ctx = self._out(run_hook(self._payload(), fake_home=self.home))["hookSpecificOutput"]["additionalContext"]

        self.assertIn("BUNDLED", ctx)

    # --- Python tomllib fallback and cross-driver TOML semantics ---------

    def test_comment_declaration_is_parsed_without_tomllib(self):
        # The default Python driver proves its import fallback. With
        # BRIEFING_TEST_CLI, PYTHONPATH cannot prove a Perl import behavior;
        # it only keeps this comment-declaration fixture semantic coverage.
        shim = self.root / "notoml"
        write(shim / "tomllib.py", "raise ImportError('blocked for test')\n")
        self._agent('''
            name = "demo"
            developer_instructions = """
            # briefing: skills = ["must-not-be-read"]
            """
            # briefing: skills = ["double", 'single']
        ''')
        self._skill("double", "DOUBLE OK\n")
        self._skill("single", "SINGLE OK\n")

        env = {
            **os.environ,
            "HOME": str(self.home),
            "PYTHONIOENCODING": "utf-8",
            "PYTHONPATH": str(shim),
        }
        proc = subprocess.run(
            command_for("hook", ["python3", str(HOOK)]),
            input=json.dumps(self._payload()),
            capture_output=True,
            text=True,
            encoding="utf-8",
            env=env,
            timeout=10,
        )

        ctx = json.loads(proc.stdout)["hookSpecificOutput"]["additionalContext"]
        self.assertIn("DOUBLE OK", ctx)
        self.assertIn("SINGLE OK", ctx)
        self.assertNotIn("must-not-be-read", ctx)

    def test_legacy_table_is_parsed_without_tomllib(self):
        # See the comment-declaration case above: the shim proves the Python
        # fallback only, while a configured Perl CLI covers these TOML inputs.
        shim = self.root / "notoml"
        write(shim / "tomllib.py", "raise ImportError('blocked for test')\n")
        self._agent("""
            name = "demo"

            [briefing]
            skills = [
              "multi-line",
              'single-quoted',
            ]

            [other]
            skills = ["must-not-be-read"]
        """)
        self._skill("multi-line", "MULTI OK\n")
        self._skill("single-quoted", "SINGLE OK\n")

        env = {
            **os.environ,
            "HOME": str(self.home),
            "PYTHONIOENCODING": "utf-8",
            "PYTHONPATH": str(shim),
        }
        proc = subprocess.run(
            command_for("hook", ["python3", str(HOOK)]),
            input=json.dumps(self._payload()),
            capture_output=True,
            text=True,
            encoding="utf-8",
            env=env,
            timeout=10,
        )

        ctx = json.loads(proc.stdout)["hookSpecificOutput"]["additionalContext"]
        self.assertIn("MULTI OK", ctx)
        self.assertIn("SINGLE OK", ctx)
        self.assertNotIn("must-not-be-read", ctx)
