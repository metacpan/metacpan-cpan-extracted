#!/usr/bin/env python3
"""Behaviour tests for winlaunch.exe. Windows only.

    python test_winlaunch.py PATH\\TO\\winlaunch.exe
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

EXE = None
PY = sys.executable.replace("\\", "/")


class Winlaunch(unittest.TestCase):
    def setUp(self):
        # A space in the root, as under a user name with a space.
        self.root = Path(tempfile.mkdtemp(prefix="winlaunch test "))
        (self.root / "hooks").mkdir()
        (self.root / "lib").mkdir()

    def tearDown(self):
        shutil.rmtree(self.root, ignore_errors=True)

    def hook(self, name, script):
        (self.root / "hooks" / name).write_text(script, encoding="utf-8", newline="\r\n")
        shutil.copyfile(EXE, self.root / "hooks" / (name + ".exe"))
        return str(self.root / "hooks" / (name + ".exe"))

    def run_hook(self, exe, args=(), stdin=b"", env=None):
        e = dict(os.environ)
        e["CLAUDE_PLUGIN_ROOT"] = str(self.root)
        e.pop("PYTHONUTF8", None)
        if env:
            e.update(env)
        return subprocess.run([exe, *args], input=stdin, capture_output=True, env=e, timeout=30)

    def test_no_run_line_is_silent(self):
        exe = self.hook("off", "#!/bin/sh\n# nothing for windows here\nexit 0\n")
        r = self.run_hook(exe, ["x"], b"{}")
        self.assertEqual((r.returncode, r.stdout, r.stderr), (0, b"", b""))

    def test_missing_script_is_silent(self):
        exe = self.hook("gone", "")
        (self.root / "hooks" / "gone").unlink()
        r = self.run_hook(exe)
        self.assertEqual((r.returncode, r.stdout, r.stderr), (0, b"", b""))

    def test_python_hook_gets_utf8_stdin_args_and_env(self):
        (self.root / "lib" / "probe.py").write_text(
            "import json, os, sys\n"
            "d = json.load(sys.stdin)\n"
            "print(json.dumps({'args': sys.argv[1:], 'prompt': d['prompt'],"
            " 'enc': sys.stdin.encoding, 'pp': os.environ.get('PYTHONPATH'),"
            " 'root': os.environ.get('CLAUDE_PLUGIN_ROOT')}, ensure_ascii=False))\n"
            "sys.exit(3)\n",
            encoding="utf-8")
        exe = self.hook("probe",
                        "#!/bin/sh\n"
                        "# winlaunch: env PYTHONPATH={root}/lib\n"
                        "# winlaunch: run python -s {root}/lib/probe.py fixed\n"
                        "exec python3 \"$0\"\n")
        r = self.run_hook(exe, ["Event Name", 'quo"te', "back\\slash\\"],
                          json.dumps({"prompt": "äöüß €"}, ensure_ascii=False).encode("utf-8"))
        self.assertEqual(r.returncode, 3, r.stderr)
        out = json.loads(r.stdout.decode("utf-8"))
        self.assertEqual(out["args"], ["fixed", "Event Name", 'quo"te', "back\\slash\\"])
        self.assertEqual(out["prompt"], "äöüß €")
        self.assertEqual(out["enc"], "utf-8")
        self.assertEqual(out["pp"], str(self.root) + "/lib")

    def test_skip_unless(self):
        (self.root / "lib" / "say.py").write_text("print('ran')\n", encoding="utf-8")
        exe = self.hook("skippy",
                        "# winlaunch: skip Hot unless {data}/pending/*\n"
                        "# winlaunch: run python {root}/lib/say.py\n")
        data = self.root / "data"
        (data / "pending").mkdir(parents=True)
        env = {"CLAUDE_PLUGIN_DATA": str(data)}
        self.assertEqual(self.run_hook(exe, ["Hot"], env=env).stdout, b"")
        self.assertIn(b"ran", self.run_hook(exe, ["Cold"], env=env).stdout)
        (data / "pending" / "abc").write_text("0\n")
        self.assertIn(b"ran", self.run_hook(exe, ["Hot"], env=env).stdout)
        # No data directory at all: the hot path stays quiet.
        self.assertEqual(self.run_hook(exe, ["Hot"], env={"CLAUDE_PLUGIN_DATA": ""}).stdout, b"")

    def test_no_python_is_silent(self):
        exe = self.hook("needs-py", "# winlaunch: run python {root}/lib/x.py\n")
        system = os.environ.get("SystemRoot", r"C:\Windows")
        # Only the Store stub directory and a directory without Python.
        path = os.path.join(os.environ["LOCALAPPDATA"], "Microsoft", "WindowsApps") + ";" + str(self.root)
        r = self.run_hook(exe, env={"PATH": path, "SystemRoot": system})
        self.assertEqual((r.returncode, r.stdout, r.stderr), (0, b"", b""))

    def test_program_relative_to_root(self):
        shutil.copyfile(sys.executable, self.root / "lib" / "mypy.exe")
        for dll in Path(sys.executable).parent.glob("python*.dll"):
            shutil.copyfile(dll, self.root / "lib" / dll.name)
        exe = self.hook("rel", "# winlaunch: run lib/mypy.exe -V\n")
        r = self.run_hook(exe)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertTrue(r.stdout.startswith(b"Python 3"), r.stdout)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    EXE = sys.argv.pop(1)
    unittest.main()
