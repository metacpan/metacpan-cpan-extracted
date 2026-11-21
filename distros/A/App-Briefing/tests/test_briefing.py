"""End-to-end tests for hooks/briefing-preload.

The hook is invoked as a subprocess with a controlled HOME and cwd so
that nothing on the developer's machine leaks into the test sandbox.
"""

import json
import os
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

from cli_driver import (assert_skill_dir, command_for,
                        known_failure_on_windows_perl_cli)

REPO_ROOT = Path(__file__).resolve().parent.parent
HOOK = REPO_ROOT / "hooks" / "briefing-preload"


def run_hook(payload, *, fake_home):
    env = {
        **os.environ,
        "HOME": str(fake_home),
        "PYTHONIOENCODING": "utf-8",
    }
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


def enable_plugin(settings_file, key, value):
    """Record enabledPlugins[key]=value in a Claude Code settings.json the way
    the CLI does when a plugin is enabled or disabled, merging into whatever
    the file already holds."""
    data = (json.loads(settings_file.read_text())
            if settings_file.exists() else {})
    data.setdefault("enabledPlugins", {})[key] = value
    write(settings_file, json.dumps(data))


def install_plugin(home, name, *, version="1.0.0", marketplace="mp",
                   skills=(), manifest=None, scope="user", project=None,
                   enabled=True):
    """Lay a plugin out the way Claude Code installs it: a versioned cache
    directory, registered in installed_plugins.json, and enabled in the user
    settings.json. `skills` maps a path below the plugin root to a SKILL.md
    body. `enabled` mirrors the enabledPlugins entry the CLI writes: True or
    False sets it; None leaves the plugin unlisted (never enabled)."""
    root = home / ".claude/plugins/cache" / marketplace / name / version
    for rel, body in dict(skills).items():
        write(root / rel / "SKILL.md", body)
    if manifest is not None:
        write(root / ".claude-plugin/plugin.json", json.dumps(manifest))
    index = home / ".claude/plugins/installed_plugins.json"
    data = (json.loads(index.read_text()) if index.exists()
            else {"version": 2, "plugins": {}})
    entry = {"scope": scope, "installPath": str(root), "version": version}
    if project is not None:
        entry["projectPath"] = str(project)
    data["plugins"].setdefault(f"{name}@{marketplace}", []).append(entry)
    write(index, json.dumps(data))
    if enabled is not None:
        enable_plugin(home / ".claude/settings.json",
                      f"{name}@{marketplace}", enabled)
    return root


class BriefingHookTests(unittest.TestCase):
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
        """SubagentStart as Claude Code 2.1.318 sends it — the briefing."""
        return {
            "session_id": "s1",
            "transcript_path": str(self.home / ".claude/projects/p/s1.jsonl"),
            "cwd": str(self.cwd),
            "prompt_id": "p1",
            "agent_id": "a1",
            "agent_type": "demo",
            "hook_event_name": "SubagentStart",
            **overrides,
        }

    def _guard_payload(self, **overrides):
        """PreToolUse on the Agent tool — the guard."""
        ti = {"subagent_type": "demo", "prompt": "ORIGINAL"}
        ti.update(overrides.pop("tool_input", {}))
        return {
            "hook_event_name": "PreToolUse",
            "tool_name": "Agent",
            "permission_mode": "auto",
            "cwd": str(self.cwd),
            "tool_input": ti,
            **overrides,
        }

    def _declare(self, *skills):
        items = "".join(f"\n    - {s}" for s in skills)
        write(self.cwd / ".claude/agents/demo.md",
              f"---\nbriefing:\n  skills:{items}\n---\nbody\n")

    def _briefed(self):
        """The injected context, or None if the spawn was not briefed."""
        proc = run_hook(self._payload(), fake_home=self.home)
        ctx = json.loads(proc.stdout)["hookSpecificOutput"]["additionalContext"]
        return None if ctx.startswith("# Briefing — FAILED") else ctx

    # --- passthrough cases ----------------------------------------------

    def test_non_agent_tool_is_noop(self):
        proc = run_hook(
            {"tool_name": "Bash", "tool_input": {"command": "ls"}},
            fake_home=self.home,
        )
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout, "")

    def test_agent_without_frontmatter_is_noop(self):
        write(self.cwd / ".claude/agents/demo.md", "Just a body, no frontmatter.\n")
        proc = run_hook(self._payload(), fake_home=self.home)
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout, "")

    def test_bom_before_frontmatter_still_briefs(self):
        """An agent file saved with a UTF-8 BOM is read like one without.

        Runs the reference Python hook (and the Perl CLI under BRIEFING_TEST_CLI):
        the BOM must not hide the opening "---" and so silently unbrief the spawn.
        """
        write(self.home / ".claude/skills/s/SKILL.md", "BOM-MARKER\n")
        path = self.cwd / ".claude/agents/demo.md"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(b"\xef\xbb\xbf"
                         + b"---\nbriefing:\n  skills:\n    - s\n---\nbody\n")
        ctx = self._briefed()
        self.assertIsNotNone(ctx)
        self.assertIn("BOM-MARKER", ctx)

    def test_agent_without_briefing_block_is_noop(self):
        write(self.cwd / ".claude/agents/demo.md", """
            ---
            name: demo
            description: x
            ---
            body
        """)
        proc = run_hook(self._payload(), fake_home=self.home)
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout, "")

    def test_bare_top_level_skills_key_is_ignored(self):
        # `skills:` at the top level belongs to Claude Code itself; the
        # briefing hook MUST NOT read it. Only `briefing.skills` counts.
        write(self.cwd / ".claude/agents/demo.md", """
            ---
            name: demo
            skills:
              - foo
            ---
            body
        """)
        write(self.cwd / ".claude/skills/foo/SKILL.md", "FOO")
        proc = run_hook(self._payload(), fake_home=self.home)
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout, "")

    def test_unknown_agent_is_noop(self):
        proc = run_hook(self._payload(), fake_home=self.home)
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout, "")

    def test_garbage_stdin_is_noop(self):
        proc = subprocess.run(
            command_for("hook", ["python3", str(HOOK)]),
            input="this is not json",
            capture_output=True,
            text=True,
            encoding="utf-8",
            env={
                **os.environ,
                "HOME": str(self.home),
                "PYTHONIOENCODING": "utf-8",
            },
        )
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout, "")

    def test_hook_helper_decodes_utf8_under_ascii_parent_locale(self):
        tests_dir = Path(__file__).resolve().parent
        script = textwrap.dedent(
            f'''\
            import json
            import os
            import tempfile
            from pathlib import Path

            import sys
            sys.path.insert(0, {str(tests_dir)!r})
            from test_briefing import run_hook

            with tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                emitter = root / "utf8-emitter.py"
                newline = chr(10)
                emitter.write_text(newline.join((
                    "import sys",
                    "sys.stdout.write(chr(123) + chr(125))",
                    "sys.stderr.write(chr(0x00E4) + chr(0x6280) + chr(0x80FD))",
                )) + newline, encoding="ascii")
                os.environ["BRIEFING_TEST_CLI"] = json.dumps([sys.executable, str(emitter)])
                result = run_hook(dict(), fake_home=root)
                expected = chr(0x00E4) + chr(0x6280) + chr(0x80FD)
                assert result.returncode == 0
                assert result.stderr == expected
            print("ok")
            '''
        )
        env = {
            **os.environ,
            "LC_ALL": "C",
            "LANG": "C",
            "PYTHONCOERCECLOCALE": "0",
            "PYTHONUTF8": "0",
            "PYTHONPATH": str(tests_dir),
        }
        env.pop("PYTHONIOENCODING", None)
        env.pop("BRIEFING_TEST_CLI", None)

        proc = subprocess.run(
            [sys.executable, "-c", script],
            capture_output=True,
            text=True,
            encoding="utf-8",
            env=env,
            timeout=10,
        )

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(proc.stdout, "ok\n")

    # --- frontmatter parsing -------------------------------------------

    def test_block_list_parses(self):
        write(self.cwd / ".claude/agents/demo.md", """
            ---
            briefing:
              skills:
                - foo
                - "bar"
                - 'baz'
            ---
            body
        """)
        for s in ("foo", "bar", "baz"):
            write(self.cwd / f".claude/skills/{s}/SKILL.md", f"# {s}\n")
        proc = run_hook(self._payload(), fake_home=self.home)
        self.assertEqual(proc.returncode, 0)
        out = json.loads(proc.stdout)
        prompt = out["hookSpecificOutput"]["additionalContext"]
        self.assertIn('<skill name="foo"', prompt)
        self.assertIn('<skill name="bar"', prompt)
        self.assertIn('<skill name="baz"', prompt)
        self.assertNotIn("ORIGINAL", prompt)

    def test_flow_list_parses(self):
        write(self.cwd / ".claude/agents/demo.md", """
            ---
            briefing:
              skills: [foo, "bar", 'baz']
            ---
            body
        """)
        for s in ("foo", "bar", "baz"):
            write(self.cwd / f".claude/skills/{s}/SKILL.md", f"# {s}\n")
        proc = run_hook(self._payload(), fake_home=self.home)
        self.assertEqual(proc.returncode, 0)
        out = json.loads(proc.stdout)
        prompt = out["hookSpecificOutput"]["additionalContext"]
        self.assertIn('<skill name="foo"', prompt)
        self.assertIn('<skill name="bar"', prompt)
        self.assertIn('<skill name="baz"', prompt)

    def test_quoted_zero_agent_and_skill_names_are_not_treated_as_empty(self):
        write(self.cwd / ".claude/agents/zero.md", """
            ---
            name: "0"
            briefing:
              skills:
                - "0"
            ---
            body
        """)
        write(self.cwd / ".claude/skills/0/SKILL.md", "ZERO SKILL BODY\n")

        proc = run_hook(self._payload(agent_type="0"), fake_home=self.home)

        self.assertEqual(proc.returncode, 0)
        prompt = json.loads(proc.stdout)["hookSpecificOutput"]["additionalContext"]
        self.assertIn('<skill name="0"', prompt)
        self.assertIn("ZERO SKILL BODY", prompt)

    def test_skill_crlf_fixture_uses_universal_newlines(self):
        self._declare("crlf")
        skill = self.cwd / ".claude/skills/crlf/SKILL.md"
        skill.parent.mkdir(parents=True)
        skill.write_bytes(b"CRLF-ONE\r\nCRLF-TWO\rCRLF-THREE\r\n")

        proc = run_hook(self._payload(), fake_home=self.home)

        self.assertEqual(proc.returncode, 0)
        prompt = json.loads(proc.stdout)["hookSpecificOutput"]["additionalContext"]
        self.assertIn("CRLF-ONE\nCRLF-TWO\nCRLF-THREE", prompt)
        self.assertNotIn("\r", prompt)

    def test_briefing_block_coexists_with_other_frontmatter(self):
        write(self.cwd / ".claude/agents/demo.md", """
            ---
            name: demo
            description: a demo
            allowed-tools: Read, Bash
            briefing:
              skills:
                - foo
            model: sonnet
            ---
            body
        """)
        write(self.cwd / ".claude/skills/foo/SKILL.md", "FOO BODY")
        proc = run_hook(self._payload(), fake_home=self.home)
        out = json.loads(proc.stdout)
        prompt = out["hookSpecificOutput"]["additionalContext"]
        self.assertIn("FOO BODY", prompt)

    # --- resolution order ----------------------------------------------

    def test_project_beats_user(self):
        write(self.cwd / ".claude/agents/demo.md", """
            ---
            briefing:
              skills:
                - foo
            ---
            body
        """)
        write(self.cwd / ".claude/skills/foo/SKILL.md", "PROJECT FOO")
        write(self.home / ".claude/skills/foo/SKILL.md", "USER FOO")
        proc = run_hook(self._payload(), fake_home=self.home)
        self.assertEqual(proc.returncode, 0)
        out = json.loads(proc.stdout)
        prompt = out["hookSpecificOutput"]["additionalContext"]
        self.assertIn("PROJECT FOO", prompt)
        self.assertNotIn("USER FOO", prompt)

    @known_failure_on_windows_perl_cli(
        "k14", "the Perl process on Windows already holds characters outside the ANSI code "
        "page as \"?\" in its own wide environment, so no read inside Perl recovers a "
        "non-ANSI HOME")
    def test_user_skill_resolves_from_unicode_home(self):
        unicode_home = self.root / "home-ä-技能"
        unicode_home.mkdir()
        self._declare("user-skill")
        skill = unicode_home / ".claude/skills/user-skill/SKILL.md"
        skill.parent.mkdir(parents=True)
        skill.write_text("UNICODE HOME USER BODY\n", encoding="utf-8")

        proc = run_hook(self._payload(), fake_home=unicode_home)

        self.assertEqual(proc.returncode, 0)
        prompt = json.loads(proc.stdout)["hookSpecificOutput"]["additionalContext"]
        skill_dir = os.path.abspath(unicode_home / ".claude/skills/user-skill")
        self.assertIn("UNICODE HOME USER BODY", prompt)
        assert_skill_dir(self, prompt, "user-skill", skill_dir)

    def test_user_beats_plugin(self):
        self._declare("foo")
        write(self.home / ".claude/skills/foo/SKILL.md", "USER FOO")
        install_plugin(self.home, "somepl", skills={"skills/foo": "PLUGIN FOO"})
        prompt = self._briefed()
        self.assertIn("USER FOO", prompt)
        self.assertNotIn("PLUGIN FOO", prompt)

    def test_plugin_cache_resolves(self):
        self._declare("foo")
        install_plugin(self.home, "somepl", skills={"skills/foo": "PLUGIN FOO"})
        self.assertIn("PLUGIN FOO", self._briefed())

    # --- namespaced form -----------------------------------------------

    def test_namespaced_skill(self):
        self._declare("superpowers:brainstorming")
        install_plugin(self.home, "superpowers", version="6.4.1",
                       skills={"skills/brainstorming": "BRAIN BODY"})
        prompt = self._briefed()
        self.assertIn('<skill name="superpowers:brainstorming"', prompt)
        self.assertIn("BRAIN BODY", prompt)

    def test_namespaced_skill_comes_from_the_installed_version(self):
        # The cache keeps versions that are no longer installed, and some
        # versions are commit hashes, so neither "highest" nor "newest" is
        # a safe guess. installed_plugins.json says which one is live.
        self._declare("superpowers:brainstorming")
        install_plugin(self.home, "superpowers", version="6.3.0",
                       skills={"skills/brainstorming": "INSTALLED"})
        write(self.home / ".claude/plugins/cache/mp/superpowers/6.4.1"
              "/skills/brainstorming/SKILL.md", "NOT INSTALLED")
        prompt = self._briefed()
        self.assertIn("INSTALLED", prompt)
        self.assertNotIn("NOT INSTALLED", prompt)

    def test_namespaced_skill_the_manifest_places_in_a_category(self):
        self._declare("mattpocock-skills:domain-modeling")
        install_plugin(
            self.home, "mattpocock-skills", version="1.2.3",
            skills={"skills/engineering/domain-modeling": "DOMAIN BODY"},
            manifest={"name": "mattpocock-skills",
                      "skills": ["./skills/engineering/domain-modeling"]},
        )
        prompt = self._briefed()
        self.assertIn("DOMAIN BODY", prompt)
        skill_dir = os.path.abspath(
            self.home / ".claude/plugins/cache/mp/mattpocock-skills/1.2.3"
            "/skills/engineering/domain-modeling")
        assert_skill_dir(self, prompt, "mattpocock-skills:domain-modeling", skill_dir)

    def test_manifest_skills_path_may_hold_several_skills(self):
        self._declare("somepl:tool")
        install_plugin(self.home, "somepl",
                       skills={"extra-skills/tool": "EXTRA TOOL"},
                       manifest={"name": "somepl", "skills": "./extra-skills/"})
        self.assertIn("EXTRA TOOL", self._briefed())

    def test_manifest_skills_add_to_the_default_scan(self):
        self._declare("somepl:plain", "somepl:extra")
        install_plugin(self.home, "somepl",
                       skills={"skills/plain": "PLAIN", "more/extra": "EXTRA"},
                       manifest={"name": "somepl", "skills": ["./more/extra"]})
        prompt = self._briefed()
        self.assertIn("PLAIN", prompt)
        self.assertIn("EXTRA", prompt)

    def test_nested_skill_the_manifest_does_not_declare_is_unknown(self):
        # Claude Code scans skills/<name>/ and the manifest's paths, nothing
        # deeper, so neither does briefing.
        self._declare("somepl:draft")
        install_plugin(self.home, "somepl",
                       skills={"skills/in-progress/draft": "DRAFT"},
                       manifest={"name": "somepl"})
        self.assertIsNone(self._briefed())

    def test_plugin_namespace_is_the_manifest_name(self):
        self._declare("real-name:tool")
        install_plugin(self.home, "entry-name",
                       skills={"skills/tool": "BY MANIFEST NAME"},
                       manifest={"name": "real-name"})
        self.assertIn("BY MANIFEST NAME", self._briefed())

    def test_project_scoped_plugin_serves_only_its_project(self):
        self._declare("somepl:tool")
        install_plugin(self.home, "somepl", skills={"skills/tool": "TOOL"},
                       scope="project", project=self.root / "elsewhere")
        self.assertIsNone(self._briefed())

        install_plugin(self.home, "somepl", version="2.0.0",
                       skills={"skills/tool": "HERE"},
                       scope="project", project=self.cwd)
        self.assertIn("HERE", self._briefed())

    @unittest.skipIf(os.name == "nt", "Backslash is a path separator on Windows.")
    def test_project_scoped_plugin_does_not_treat_posix_backslash_as_separator(self):
        scoped_project = self.root / "a"
        sibling = self.root / r"a\b"
        scoped_project.mkdir()
        sibling.mkdir()
        write(sibling / ".claude/agents/demo.md", """
            ---
            briefing:
              skills:
                - somepl:tool
            ---
            body
        """)
        install_plugin(
            self.home,
            "somepl",
            skills={"skills/tool": "SCOPED PLUGIN BODY"},
            scope="project",
            project=scoped_project,
        )

        proc = run_hook(
            self._payload(cwd=str(sibling)), fake_home=self.home
        )

        self.assertEqual(proc.returncode, 0)
        context = json.loads(proc.stdout)["hookSpecificOutput"]["additionalContext"]
        self.assertIn("FAILED", context)
        self.assertNotIn("SCOPED PLUGIN BODY", context)

    # --- plugin enablement ---------------------------------------------

    def test_disabled_plugin_is_unknown(self):
        # enabledPlugins says false, so Claude Code loads none of its skills;
        # briefing must not resolve one either.
        self._declare("somepl:tool")
        install_plugin(self.home, "somepl",
                       skills={"skills/tool": "TOOL"}, enabled=False)
        self.assertIsNone(self._briefed())

    def test_plugin_never_enabled_is_unknown(self):
        # A marketplace plugin fetched into installed_plugins.json but absent
        # from every enabledPlugins map is disabled by default.
        self._declare("somepl:tool")
        install_plugin(self.home, "somepl",
                       skills={"skills/tool": "TOOL"}, enabled=None)
        self.assertIsNone(self._briefed())

    def test_bare_name_skips_a_disabled_plugin(self):
        self._declare("tool")
        install_plugin(self.home, "somepl",
                       skills={"skills/tool": "TOOL"}, enabled=False)
        self.assertIsNone(self._briefed())

    def test_local_settings_re_enable_a_user_disabled_plugin(self):
        # Precedence: project-local settings win over user settings.
        self._declare("somepl:tool")
        install_plugin(self.home, "somepl",
                       skills={"skills/tool": "TOOL"}, enabled=False)
        enable_plugin(self.cwd / ".claude/settings.local.json",
                      "somepl@mp", True)
        self.assertIn("TOOL", self._briefed())

    def test_local_settings_disable_a_user_enabled_plugin(self):
        self._declare("somepl:tool")
        install_plugin(self.home, "somepl", skills={"skills/tool": "TOOL"})
        enable_plugin(self.cwd / ".claude/settings.local.json",
                      "somepl@mp", False)
        self.assertIsNone(self._briefed())

    # --- hard-fail -----------------------------------------------------

    def test_missing_skill_denies(self):
        write(self.cwd / ".claude/agents/demo.md", """
            ---
            briefing:
              skills:
                - foo
                - missing-one
            ---
            body
        """)
        write(self.cwd / ".claude/skills/foo/SKILL.md", "FOO")
        proc = run_hook(self._guard_payload(), fake_home=self.home)
        self.assertEqual(proc.returncode, 0)
        out = json.loads(proc.stdout)
        hso = out["hookSpecificOutput"]
        self.assertEqual(hso["permissionDecision"], "deny")
        self.assertIn("missing-one", hso["permissionDecisionReason"])
        self.assertNotIn("updatedInput", hso)

    # --- frontmatter is stripped from injected body -------------------

    def test_skill_frontmatter_is_stripped(self):
        write(self.cwd / ".claude/agents/demo.md", """
            ---
            briefing:
              skills:
                - foo
            ---
            body
        """)
        write(self.cwd / ".claude/skills/foo/SKILL.md", """
            ---
            name: foo
            description: secret-metadata
            ---
            VISIBLE BODY
        """)
        proc = run_hook(self._payload(), fake_home=self.home)
        out = json.loads(proc.stdout)
        prompt = out["hookSpecificOutput"]["additionalContext"]
        self.assertIn("VISIBLE BODY", prompt)
        self.assertNotIn("secret-metadata", prompt)

    # --- limits ----------------------------------------------------------

    def test_large_briefing_still_spawns_but_warns(self):
        write(self.cwd / ".claude/agents/demo.md", """
            ---
            briefing:
              skills:
                - big
            ---
            body
        """)
        write(self.cwd / ".claude/skills/big/SKILL.md", "x" * (70 * 1024))
        proc = run_hook(self._payload(), fake_home=self.home)
        out = json.loads(proc.stdout)
        self.assertIn("x" * 1024, out["hookSpecificOutput"]["additionalContext"])
        self.assertIn("over 64 kB", out["systemMessage"])
        self.assertIn("over 64 kB", proc.stderr)

    def test_small_briefing_has_no_size_warning(self):
        write(self.cwd / ".claude/agents/demo.md", """
            ---
            briefing:
              skills:
                - foo
            ---
            body
        """)
        write(self.cwd / ".claude/skills/foo/SKILL.md", "FOO")
        out = json.loads(run_hook(self._payload(), fake_home=self.home).stdout)
        self.assertNotIn("over 64 kB", out["systemMessage"])

    def test_skills_are_leaves_not_expanded_recursively(self):
        # A skill that itself declares briefing.skills is injected as it is;
        # its own list is not followed, so there is nothing to cycle on.
        write(self.cwd / ".claude/agents/demo.md", """
            ---
            briefing:
              skills:
                - outer
            ---
            body
        """)
        write(self.cwd / ".claude/skills/outer/SKILL.md", """
            ---
            name: outer
            briefing:
              skills:
                - outer
                - inner
            ---
            OUTER BODY
        """)
        write(self.cwd / ".claude/skills/inner/SKILL.md", "INNER BODY")
        out = json.loads(run_hook(self._payload(), fake_home=self.home).stdout)
        prompt = out["hookSpecificOutput"]["additionalContext"]
        self.assertEqual(prompt.count("OUTER BODY"), 1)
        self.assertNotIn("INNER BODY", prompt)

    # --- what the human and the agent see ------------------------------

    def test_successful_briefing_is_audited_in_one_line(self):
        write(self.cwd / ".claude/agents/demo.md", """
            ---
            briefing:
              skills:
                - foo
                - bar
            ---
            body
        """)
        write(self.cwd / ".claude/skills/foo/SKILL.md", "FOO")
        write(self.cwd / ".claude/skills/bar/SKILL.md", "BAR")
        out = json.loads(run_hook(self._payload(), fake_home=self.home).stdout)
        msg = out["systemMessage"]
        self.assertEqual(len(msg.splitlines()), 1)
        self.assertIn("demo", msg)
        self.assertIn("foo, bar", msg)
        self.assertIn("kB", msg)

    def test_each_skill_is_wrapped_in_a_skill_element(self):
        write(self.cwd / ".claude/agents/demo.md", """
            ---
            briefing:
              skills:
                - foo
            ---
            body
        """)
        write(self.cwd / ".claude/skills/foo/SKILL.md", "---\nname: foo\n---\nFOO BODY\n")
        out = json.loads(run_hook(self._payload(), fake_home=self.home).stdout)
        prompt = out["hookSpecificOutput"]["additionalContext"]
        self.assertRegex(prompt, r'<skill name="foo"[^>]*>\s*FOO BODY\s*</skill>')
        self.assertNotIn("## Skill:", prompt)

    def test_skill_element_carries_its_directory_for_references(self):
        write(self.cwd / ".claude/agents/demo.md", """
            ---
            briefing:
              skills:
                - foo
            ---
            body
        """)
        write(self.cwd / ".claude/skills/foo/SKILL.md", "See references/api.md.\n")
        write(self.cwd / ".claude/skills/foo/references/api.md", "API\n")
        out = json.loads(run_hook(self._payload(), fake_home=self.home).stdout)
        prompt = out["hookSpecificOutput"]["additionalContext"]
        skill_dir = os.path.abspath(self.cwd / ".claude/skills/foo")
        assert_skill_dir(self, prompt, "foo", skill_dir)
        self.assertIn("relative to", prompt)
        self.assertNotIn("\nAPI\n", prompt)

    # --- finding the agent the way Claude Code does ----------------------

    def test_agent_found_by_frontmatter_name_not_file_name(self):
        write(self.cwd / ".claude/agents/some-file.md", """
            ---
            name: demo
            briefing:
              skills:
                - foo
            ---
            body
        """)
        write(self.cwd / ".claude/skills/foo/SKILL.md", "BY NAME")
        out = json.loads(run_hook(self._payload(), fake_home=self.home).stdout)
        self.assertIn("BY NAME", out["hookSpecificOutput"]["additionalContext"])

    def test_agent_found_in_subdirectory(self):
        write(self.cwd / ".claude/agents/team/demo.md", """
            ---
            name: demo
            briefing:
              skills:
                - foo
            ---
            body
        """)
        write(self.cwd / ".claude/skills/foo/SKILL.md", "NESTED")
        out = json.loads(run_hook(self._payload(), fake_home=self.home).stdout)
        self.assertIn("NESTED", out["hookSpecificOutput"]["additionalContext"])

    def test_unicode_named_agent_file_is_found_by_declaration(self):
        unicode_cwd = self.root / "project-ä-技能"
        unicode_cwd.mkdir()
        write(unicode_cwd / ".claude/agents/技能.md", """
            ---
            name: fallback-agent
            briefing:
              skills:
                - fallback-skill
            ---
            body
        """)
        write(
            unicode_cwd / ".claude/skills/fallback-skill/SKILL.md",
            "UNICODE AGENT ENTRY BODY\n",
        )

        proc = run_hook(
            self._payload(cwd=str(unicode_cwd), agent_type="fallback-agent"),
            fake_home=self.home,
        )

        self.assertEqual(proc.returncode, 0)
        self.assertTrue(proc.stdout, proc.stderr)
        prompt = json.loads(proc.stdout)["hookSpecificOutput"]["additionalContext"]
        self.assertIn("UNICODE AGENT ENTRY BODY", prompt)

    def test_current_directory_duplicate_agent_wins_over_nested_agent(self):
        write(self.cwd / ".claude/agents/z-role.md", """
            ---
            name: duplicate-agent
            briefing:
              skills:
                - root-skill
            ---
            body
        """)
        write(self.cwd / ".claude/agents/a-team/role.md", """
            ---
            name: duplicate-agent
            briefing:
              skills:
                - nested-skill
            ---
            body
        """)
        write(self.cwd / ".claude/skills/root-skill/SKILL.md", "ROOT AGENT BODY\n")
        write(self.cwd / ".claude/skills/nested-skill/SKILL.md", "NESTED AGENT BODY\n")

        proc = run_hook(
            self._payload(agent_type="duplicate-agent"), fake_home=self.home
        )

        self.assertEqual(proc.returncode, 0)
        prompt = json.loads(proc.stdout)["hookSpecificOutput"]["additionalContext"]
        self.assertIn("ROOT AGENT BODY", prompt)
        self.assertNotIn("NESTED AGENT BODY", prompt)

    def test_file_named_after_agent_but_named_otherwise_is_not_it(self):
        write(self.cwd / ".claude/agents/demo.md", """
            ---
            name: someone-else
            briefing:
              skills:
                - foo
            ---
            body
        """)
        write(self.cwd / ".claude/skills/foo/SKILL.md", "WRONG")
        proc = run_hook(self._payload(), fake_home=self.home)
        self.assertEqual(proc.stdout, "")


    # --- PreToolUse is only a guard ------------------------------------

    def test_guard_never_rewrites_a_briefable_spawn(self):
        # Auto mode reviews the Agent call before hooks run and refuses one
        # whose input a hook changed, so the guard must stay silent.
        self._declare("foo")
        write(self.cwd / ".claude/skills/foo/SKILL.md", "FOO")
        proc = run_hook(self._guard_payload(), fake_home=self.home)
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout, "")

    def test_guard_deny_carries_no_updated_input(self):
        self._declare("missing-one")
        out = json.loads(run_hook(self._guard_payload(), fake_home=self.home).stdout)
        hso = out["hookSpecificOutput"]
        self.assertEqual(hso["hookEventName"], "PreToolUse")
        self.assertEqual(hso["permissionDecision"], "deny")
        self.assertNotIn("updatedInput", hso)
        self.assertNotIn("updatedInput", out)

    def test_guard_ignores_an_agent_without_declaration(self):
        write(self.cwd / ".claude/agents/demo.md", "---\nname: demo\n---\nbody\n")
        proc = run_hook(self._guard_payload(), fake_home=self.home)
        self.assertEqual(proc.stdout, "")

    # --- SubagentStart in Claude Code ----------------------------------

    def test_subagent_start_briefs_as_additional_context(self):
        self._declare("foo")
        write(self.cwd / ".claude/skills/foo/SKILL.md", "FOO BODY")
        out = json.loads(run_hook(self._payload(), fake_home=self.home).stdout)
        hso = out["hookSpecificOutput"]
        self.assertEqual(hso["hookEventName"], "SubagentStart")
        self.assertIn("FOO BODY", hso["additionalContext"])
        self.assertIn("Skill tool", hso["additionalContext"])
        self.assertTrue(out["systemMessage"].startswith("briefing: demo ← foo"))

    def test_subagent_start_with_missing_skill_tells_the_agent_to_stop(self):
        # Normally the guard has denied the spawn already; if the skill
        # vanished in between, the agent must not run half-briefed.
        self._declare("foo", "missing-one")
        write(self.cwd / ".claude/skills/foo/SKILL.md", "FOO BODY")
        out = json.loads(run_hook(self._payload(), fake_home=self.home).stdout)
        ctx = out["hookSpecificOutput"]["additionalContext"]
        self.assertIn("FAILED", ctx)
        self.assertIn("missing-one", ctx)
        self.assertNotIn("FOO BODY", ctx)
        self.assertIn("missing-one", out["systemMessage"])

    def test_claude_transcript_picks_the_claude_agent_over_a_codex_one(self):
        self._declare("foo")
        write(self.cwd / ".claude/skills/foo/SKILL.md", "CLAUDE SIDE")
        write(self.cwd / ".codex/agents/demo.toml",
              'name = "demo"\n# briefing: skills = ["bar"]\n')
        write(self.cwd / ".agents/skills/bar/SKILL.md", "CODEX SIDE")
        prompt = self._briefed()
        self.assertIn("CLAUDE SIDE", prompt)
        self.assertNotIn("CODEX SIDE", prompt)

    def test_payload_without_transcript_finds_the_claude_agent(self):
        self._declare("foo")
        write(self.cwd / ".claude/skills/foo/SKILL.md", "FOO BODY")
        payload = self._payload()
        del payload["transcript_path"]
        out = json.loads(run_hook(payload, fake_home=self.home).stdout)
        self.assertIn("FOO BODY", out["hookSpecificOutput"]["additionalContext"])

    def test_skilletor_local_agent_is_found_by_agent_type(self):
        write(self.cwd / ".claude/agents/.local.demo.md", """
            ---
            name: demo
            briefing:
              skills:
                - foo
            ---
            body
        """)
        write(self.cwd / ".claude/skills/foo/SKILL.md", "LOCAL")
        self.assertIn("LOCAL", self._briefed())
        self.assertEqual(
            run_hook(self._guard_payload(), fake_home=self.home).stdout, "")

    def test_built_in_agent_type_is_noop(self):
        proc = run_hook(self._payload(agent_type="general-purpose"),
                        fake_home=self.home)
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout, "")

    def test_hooks_json_lifts_the_context_limit_for_subagent_start(self):
        hooks = json.loads((REPO_ROOT / "hooks/hooks.json").read_text())["hooks"]
        entry = hooks["SubagentStart"][0]["hooks"][0]
        self.assertEqual(entry["additionalContextLimit"], 0)
        self.assertNotIn("matcher", hooks["SubagentStart"][0])


if __name__ == "__main__":
    unittest.main()
