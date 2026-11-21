"""Contract of the sh starter bin/briefing.

The starter runs a cached release binary (verified against the checksum pinned in
bin/briefing-binaries.sha256), downloads it only for `hook session-start`, and otherwise
falls back to the Python hook, so a spawn is never unbriefed. Every test runs a copy of the
plugin with an isolated HOME, CLAUDE_CONFIG_DIR and cwd, a fake binary and a file:// download.

Skipped on Windows (the starter is POSIX sh; Windows starts bin/briefing.exe) and wherever sh,
a checksum tool or a pinned platform is missing; download tests also need curl.
"""

import hashlib
import http.server
import json
import os
import platform
import re
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VERSION = "1.2.3"
MARKER = "STARTER-MARKER-X"
NOW = "1700000000"
CANONICAL_PLATFORMS = (
    ("linux", "x86_64"),
    ("linux", "arm64"),
    ("macos", "x86_64"),
    ("macos", "arm64"),
    ("windows", "x86_64"),
)

SKIP_REASON = None
OS_NAME = ARCH = None
if sys.platform.startswith("win"):
    SKIP_REASON = "skipped on Windows: bin/briefing is a POSIX sh starter"
else:
    OS_NAME = {"Linux": "linux", "Darwin": "macos"}.get(platform.system())
    ARCH = {"x86_64": "x86_64", "amd64": "x86_64", "aarch64": "arm64", "arm64": "arm64"}.get(
        platform.machine().lower())
    if shutil.which("sh") is None:
        SKIP_REASON = "skipped: no sh on PATH"
    elif OS_NAME is None or ARCH is None:
        SKIP_REASON = "skipped: no binary is pinned for %s %s" % (platform.system(), platform.machine())
    elif shutil.which("sha256sum") is None and shutil.which("shasum") is None:
        SKIP_REASON = "skipped: neither sha256sum nor shasum is available"
    elif shutil.which("python3") is None:
        SKIP_REASON = "skipped: no python3 on PATH for the fallback hook"

HAVE_CURL = shutil.which("curl") is not None
FAKE_BINARY = b'#!/bin/sh\necho "FAKE $PAR_GLOBAL_TEMP|$*"\n'
EVIL_BINARY = b"#!/bin/sh\necho EVIL-RAN\n"


def sha256(data):
    return hashlib.sha256(data).hexdigest()


@unittest.skipIf(SKIP_REASON is not None, SKIP_REASON or "")
class StarterTest(unittest.TestCase):
    def setUp(self):
        # Resolved: on macOS the temp root lies under the /var symlink, which the
        # starter refuses in any component of the cache path on purpose.
        self.tmp = Path(tempfile.mkdtemp(prefix="briefing-starter-")).resolve()
        self.addCleanup(shutil.rmtree, str(self.tmp), True)
        self.plugin = self.tmp / "plugin"
        self.plugin.mkdir()
        for name in ("bin", "hooks", "lib", "script"):
            shutil.copytree(str(ROOT / name), str(self.plugin / name))
        try:  # start from the "nothing pinned" state, whatever the checkout holds
            (self.plugin / "bin" / "briefing-binaries.sha256").unlink()
        except OSError:
            pass
        self.starter = self.plugin / "bin" / "briefing"
        self.home = self.tmp / "home"
        self.config = self.tmp / "cfg"
        self.proj = self.home / "proj"
        (self.home / ".claude" / "skills" / "s").mkdir(parents=True)
        (self.home / ".claude" / "skills" / "s" / "SKILL.md").write_text(MARKER + "\n")
        (self.proj / ".claude" / "agents").mkdir(parents=True)
        (self.proj / ".claude" / "agents" / "demo.md").write_text(
            "---\nname: demo\nbriefing:\n  skills:\n    - s\n---\nbody\n")
        self.payload = json.dumps({
            "hook_event_name": "SubagentStart",
            "agent_type": "demo",
            "agent_id": "a1",
            "cwd": str(self.proj),
            "transcript_path": str(self.home / ".claude" / "projects" / "p" / "s.jsonl"),
        })
        self.asset = self.asset_for(OS_NAME, ARCH)
        # The version directory: <config>/briefing/bin/<VERSION>. The binary lives one level
        # deeper, in the pin directory (see pin_dir); the swap tests swap this directory.
        self.cache_dir = self.config / "briefing" / "bin" / VERSION
        self.execution_marker = self.tmp / "fixture-executed"
        # BRIEFING_TEST_SHELL points the suite at another POSIX shell (e.g. bash, as macOS /bin/sh is).
        self.shell = os.environ.get("BRIEFING_TEST_SHELL") or shutil.which("sh")
        self.serve(FAKE_BINARY)

    @staticmethod
    def asset_for(os_name, arch):
        suffix = ".exe" if os_name == "windows" else ""
        return "briefing-%s-%s-%s%s" % (VERSION, os_name, arch, suffix)

    def canonical_pins(self, data=FAKE_BINARY):
        digest = sha256(data)
        return [(digest, self.asset_for(os_name, arch))
                for os_name, arch in CANONICAL_PLATFORMS]

    def write_pins(self, pins):
        (self.plugin / "bin" / "briefing-binaries.sha256").write_text(
            "".join("%s  %s\n" % pin for pin in pins), encoding="utf-8")

    def serve(self, data, name="srv", asset=None):
        """Serve `data` as the release asset at file://<tmp>/<name>/<VERSION>; return the URL."""
        directory = self.tmp / name / VERSION
        directory.mkdir(parents=True, exist_ok=True)
        (directory / (asset or self.asset)).write_bytes(data)
        return "file://%s" % directory

    def pin(self, data=FAKE_BINARY):
        self.write_pins(self.canonical_pins(data))
        return sha256(data)

    def pin_dir(self, data=FAKE_BINARY):
        """The pin directory: the first 16 lowercase hex digits of the pinned checksum."""
        return self.cache_dir / sha256(data)[:16]

    def cache_file(self, data=FAKE_BINARY):
        return self.pin_dir(data) / "briefing"

    def par_dir(self, data=FAKE_BINARY):
        return self.pin_dir(data) / "par"

    def cached_binary(self, asset, data=FAKE_BINARY):
        # `asset` stays in the signature: the cache file name no longer carries it.
        cached = self.cache_file(data)
        cached.parent.mkdir(parents=True, exist_ok=True)
        cached.write_bytes(data)
        cached.chmod(0o700)
        return cached

    def marker_binary(self):
        script = (
            "#!/bin/sh\n"
            "printf 'executed\\n' >> %s\n"
            "printf 'FIXTURE %%s|%%s\\n' \"$PAR_GLOBAL_TEMP\" \"$*\"\n"
            % shlex.quote(str(self.execution_marker)))
        return script.encode("utf-8")

    def serve_http(self, data, delay=0):
        """Serve an asset from loopback HTTP; return the base URL through the version."""
        class Handler(http.server.BaseHTTPRequestHandler):
            def do_GET(handler_self):
                if delay:
                    time.sleep(delay)
                handler_self.send_response(200)
                handler_self.send_header("Content-Length", str(len(data)))
                handler_self.end_headers()
                handler_self.wfile.write(data)

            def log_message(self, format_, *args):
                pass

        server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        server.daemon_threads = True
        thread = threading.Thread(target=server.serve_forever)
        thread.daemon = True
        thread.start()

        def stop_server():
            server.shutdown()
            thread.join(timeout=5)
            server.server_close()

        self.addCleanup(stop_server)
        return "http://127.0.0.1:%d/%s" % (server.server_port, VERSION)

    def _swap_window_tools(self, data, foreign, displaced, trigger_stage, macos_hash=None,
                           swap_dir=None):
        if swap_dir is None:
            swap_dir = self.cache_dir
        fixture = self.tmp / ("swap-window-" + trigger_stage + "-fixture")
        fixture.write_bytes(data)
        operations = self.tmp / ("swap-window-" + trigger_stage + "-operations.log")
        triggered = self.tmp / ("swap-window-" + trigger_stage + "-triggered")
        downloaded = self.tmp / ("swap-window-" + trigger_stage + "-downloaded")
        calls = self.tmp / ("swap-window-" + trigger_stage + "-calls.log")
        self.swap_calls = calls
        bindir = self.tmp / ("swap-window-" + trigger_stage + "-tools")
        bindir.mkdir()
        realpath = bindir / "realpath"
        realpath.write_text(
            "#!/bin/sh\nexec %s -c %s \"$@\"\n"
            % (shlex.quote(sys.executable),
               shlex.quote("import os,sys; print(os.path.realpath(sys.argv[-1]))")))
        realpath.chmod(0o755)

        real_mv = shutil.which("mv")
        real_ln = shutil.which("ln")
        real_cp = shutil.which("cp")
        for tool, source in (("mv", real_mv), ("ln", real_ln), ("cp", real_cp)):
            self.assertIsNotNone(source, "missing required test tool %s" % tool)

        curl = bindir / "curl"
        curl.write_text(
            "#!/bin/sh\n"
            "output=\n"
            "while [ \"$#\" -gt 0 ]; do\n"
            "  case $1 in\n"
            "    -o|--output) output=$2; shift 2 ;;\n"
            "    --output=*) output=${1#*=}; shift ;;\n"
            "    -o*) output=${1#-o}; shift ;;\n"
            "    *) shift ;;\n"
            "  esac\n"
            "done\n"
            "printf 'curl output=%%s\\n' \"$output\" >> %s\n"
            "resolved=$(%s -- \"$output\") || exit 95\n"
            "foreign=%s\n"
            "case $resolved in\n"
            "  \"$foreign\"|\"$foreign\"/*)\n"
            "    printf 'download:%%s\\n' \"$resolved\" >> %s\n"
            "    ;;\n"
            "esac\n"
            "%s %s \"$output\"\n"
            ": > %s\n"
            % (shlex.quote(str(calls)), shlex.quote(str(realpath)), shlex.quote(str(foreign)),
               shlex.quote(str(operations)), shlex.quote(real_cp),
               shlex.quote(str(fixture)), shlex.quote(str(downloaded))))
        curl.chmod(0o755)

        shimmed = ("chmod", "env", "ln", "rm")
        if trigger_stage == "post-download":
            shimmed += ("wc",)
        for tool in shimmed:
            source = shutil.which(tool)
            self.assertIsNotNone(source, "missing required test tool %s" % tool)
            trigger = ""
            if tool == "wc" and trigger_stage == "post-download":
                # `wc -c <"$tmp"` follows the post-download `chmod 600` and its revalidation
                # and precedes the warm-up. It is always looked up through PATH; `chmod` is
                # not a usable trigger, because the starter's earlier `command -p chmod` makes
                # bash (macOS /bin/sh) hash /bin/chmod and skip the shim from then on.
                trigger = (
                    "if [ \"${1-}\" = -c ] && [ -e %s ] && [ ! -e %s ]; then\n"
                    "  printf 'trigger: swapping at wc\\n' >> %s\n"
                    "  %s %s %s || { echo 'trigger: mv failed' >> %s; exit 91; }\n"
                    "  %s -s %s %s || { echo 'trigger: ln failed' >> %s; exit 92; }\n"
                    "  : > %s\n"
                    "fi\n"
                    % (shlex.quote(str(downloaded)), shlex.quote(str(triggered)),
                       shlex.quote(str(calls)),
                       shlex.quote(real_mv),
                       shlex.quote(str(swap_dir)), shlex.quote(str(displaced)),
                       shlex.quote(str(calls)),
                       shlex.quote(real_ln), shlex.quote(str(foreign)),
                       shlex.quote(str(swap_dir)), shlex.quote(str(calls)),
                       shlex.quote(str(triggered))))
            elif tool == "ln" and trigger_stage == "ln":
                bin_file = self.cache_file(data)
                trigger = (
                    "if [ ! -e %s ]; then\n"
                    "  for argument do\n"
                    "    resolved_target=$(%s -- \"$argument\" 2>/dev/null) || resolved_target=\n"
                    "    if [ \"$resolved_target\" = %s ]; then\n"
                    "      %s %s %s || exit 91\n"
                    "      %s -s %s %s || exit 92\n"
                    "      : > %s\n"
                    "      break\n"
                    "    fi\n"
                    "  done\n"
                    "fi\n"
                    % (shlex.quote(str(triggered)), shlex.quote(str(realpath)),
                       shlex.quote(str(bin_file)), shlex.quote(real_mv),
                       shlex.quote(str(swap_dir)), shlex.quote(str(displaced)),
                       shlex.quote(real_ln), shlex.quote(str(foreign)),
                       shlex.quote(str(swap_dir)), shlex.quote(str(triggered))))
            elif tool == "rm" and trigger_stage == "rm-retry":
                retry_file = self.pin_dir(data) / ("." + self.asset + ".failed-at")
                trigger = (
                    "if [ ! -e %s ]; then\n"
                    "  for argument do\n"
                    "    resolved_target=$(%s -- \"$argument\" 2>/dev/null) || resolved_target=\n"
                    "    if [ \"$resolved_target\" = %s ]; then\n"
                    "      %s %s %s || exit 91\n"
                    "      %s -s %s %s || exit 92\n"
                    "      : > %s\n"
                    "      break\n"
                    "    fi\n"
                    "  done\n"
                    "fi\n"
                    % (shlex.quote(str(triggered)), shlex.quote(str(realpath)),
                       shlex.quote(str(retry_file)), shlex.quote(real_mv),
                       shlex.quote(str(swap_dir)), shlex.quote(str(displaced)),
                       shlex.quote(real_ln), shlex.quote(str(foreign)),
                       shlex.quote(str(swap_dir)), shlex.quote(str(triggered))))
            wrapper = bindir / tool
            wrapper.write_text(
                "#!/bin/sh\n"
                "printf '%s %%s\\n' \"$*\" >> %s\n" % (tool, shlex.quote(str(calls))) +
                trigger +
                "foreign=%s\n"
                "for argument do\n"
                "  candidate=$argument\n"
                "  case $candidate in\n"
                "    PAR_GLOBAL_TEMP=*) candidate=${candidate#*=} ;;\n"
                "    -*) continue ;;\n"
                "  esac\n"
                "  resolved=$(%s -- \"$candidate\" 2>/dev/null) || resolved=\n"
                "  case $resolved in\n"
                "    \"$foreign\"|\"$foreign\"/*)\n"
                "      printf '%s:%%s\\n' \"$resolved\" >> %s\n"
                "      break\n"
                "      ;;\n"
                "  esac\n"
                "done\n"
                "exec %s \"$@\"\n"
                % (shlex.quote(str(foreign)), shlex.quote(str(realpath)), tool,
                   shlex.quote(str(operations)), shlex.quote(source)))
            wrapper.chmod(0o755)

        if macos_hash is None:
            macos_hash = OS_NAME != "linux"
        hash_tool = "openssl" if macos_hash else "sha256sum"
        hash_source = shutil.which(hash_tool)
        if hash_tool == "openssl" and OS_NAME == "linux":
            # Simulated macOS on Linux: a stand-in for `openssl dgst -sha256 FILE`, as in
            # test_macos_hash_path_uses_native_openssl_not_shasum (no openssl needed).
            digest_script = (
                "import hashlib,sys; "
                "print(hashlib.sha256(open(sys.argv[1], 'rb').read()).hexdigest())")
            hash_source = bindir / "openssl-real"
            hash_source.write_text(
                "#!/bin/sh\n"
                "for argument do file=$argument; done\n"
                "digest=$(%s -c %s \"$file\") || exit 1\n"
                "printf 'SHA2-256(%%s)= %%s\\n' \"$file\" \"$digest\"\n"
                % (shlex.quote(sys.executable), shlex.quote(digest_script)))
            hash_source.chmod(0o755)
            hash_source = str(hash_source)
        self.assertIsNotNone(hash_source, "missing required test tool %s" % hash_tool)
        hash_wrapper = bindir / hash_tool
        if not macos_hash:
            hash_wrapper.write_text(
                "#!/bin/sh\n"
                "foreign=%s\n"
                "resolved=$(%s /proc/$$/fd/0 2>/dev/null) || resolved=\n"
                "case $resolved in\n"
                "  \"$foreign\"|\"$foreign\"/*) printf 'hash:%%s\\n' \"$resolved\" >> %s ;;\n"
                "esac\n"
                "exec %s \"$@\"\n"
                % (shlex.quote(str(foreign)), shlex.quote(str(realpath)),
                   shlex.quote(str(operations)), shlex.quote(hash_source)))
        else:
            hash_wrapper.write_text(
                "#!/bin/sh\n"
                "foreign=%s\n"
                "for argument do\n"
                "  resolved=$(%s -- \"$argument\" 2>/dev/null) || resolved=\n"
                "  case $resolved in\n"
                "    \"$foreign\"|\"$foreign\"/*)\n"
                "      printf 'hash:%%s\\n' \"$resolved\" >> %s\n"
                "      break\n"
                "      ;;\n"
                "  esac\n"
                "done\n"
                "exec %s \"$@\"\n"
                % (shlex.quote(str(foreign)), shlex.quote(str(realpath)),
                   shlex.quote(str(operations)), shlex.quote(hash_source)))
        hash_wrapper.chmod(0o755)
        path = "%s%s%s" % (bindir, os.pathsep, os.environ["PATH"])
        return path, operations, triggered

    def _starter_env(self, url=None, now=None, testing=False, extra_env=None):
        env = {k: v for k, v in os.environ.items() if not k.startswith("BRIEFING_")}
        env.update(HOME=str(self.home), CLAUDE_CONFIG_DIR=str(self.config))
        env.pop("PAR_GLOBAL_TEMP", None)
        # A Claude session's real plugin root must not leak into the notice (k20).
        env.pop("CLAUDE_PLUGIN_ROOT", None)
        if url is not None:
            env["BRIEFING_BINARY_BASE_URL"] = url
        if now is not None:
            env["BRIEFING_STARTER_NOW"] = now
        if testing:
            env["BRIEFING_STARTER_TESTING"] = "1"
        if extra_env is not None:
            env.update(extra_env)
        return env

    def start_starter(self, *args, url=None, now=None, testing=False, extra_env=None):
        return subprocess.Popen(
            [self.shell, str(self.starter)] + list(args),
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            universal_newlines=True, cwd=str(self.proj),
            env=self._starter_env(url=url, now=now, testing=testing, extra_env=extra_env))

    def run_starter(self, *args, url=None, now=None, stdin=None, testing=False,
                    child_umask=None, extra_env=None):
        preexec_fn = None
        if child_umask is not None:
            preexec_fn = lambda: os.umask(child_umask)
        return subprocess.run(
            [self.shell, str(self.starter)] + list(args),
            input=self.payload if stdin is None else stdin,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True,
            cwd=str(self.proj),
            env=self._starter_env(url=url, now=now, testing=testing, extra_env=extra_env),
            preexec_fn=preexec_fn, timeout=60)

    def files_left(self):
        if not self.config.exists():
            return []
        return sorted(str(p.relative_to(self.config)) for p in self.config.rglob("*") if p.is_file())

    def assert_no_cache_payload(self):
        leftovers = [path for path in self.files_left() if not path.endswith(".failed-at")]
        self.assertEqual(leftovers, [])

    def assert_python_briefed(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)
        out = json.loads(result.stdout)
        context = out["hookSpecificOutput"]["additionalContext"]
        self.assertEqual(out["hookSpecificOutput"]["hookEventName"], "SubagentStart")
        self.assertIn(MARKER, context)

    # --- fallback

    def test_no_pin_falls_back_to_python_hook_which_briefs(self):
        result = self.run_starter("hook", "subagent-start")
        self.assert_python_briefed(result)

    def test_empty_pin_downloads_nothing_and_still_briefs(self):
        (self.plugin / "bin" / "briefing-binaries.sha256").write_text("")
        result = self.run_starter("hook", "session-start", url=self.serve(FAKE_BINARY))
        self.assertFalse((self.config / "briefing").exists(), self.files_left())
        self.assertNotIn("FAKE", result.stdout)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_pin_for_another_platform_downloads_nothing(self):
        other = "briefing-%s-freebsd-riscv" % VERSION
        (self.plugin / "bin" / "briefing-binaries.sha256").write_text(
            "%s  %s\n" % (sha256(FAKE_BINARY), other))
        self.run_starter("hook", "session-start", url=self.serve(FAKE_BINARY))
        self.assertFalse((self.config / "briefing").exists(), self.files_left())
        self.assert_python_briefed(self.run_starter("hook", "subagent-start"))

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_rejects_noncanonical_pin_manifest(self):
        pins = self.canonical_pins()
        pins.append(pins[0])
        self.write_pins(pins)

        result = self.run_starter("hook", "session-start", url=self.serve(FAKE_BINARY), now=NOW)

        self.assertFalse((self.config / "briefing").exists(), self.files_left())
        self.assert_python_briefed(result)

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_rejects_mixed_versions_before_selecting_platform(self):
        pins = self.canonical_pins()
        for index, (digest, asset) in enumerate(pins):
            if asset != self.asset:
                pins[index] = (digest, asset.replace(VERSION, "9.9.9", 1))
                break
        self.write_pins(pins)

        result = self.run_starter("hook", "session-start", url=self.serve(FAKE_BINARY), now=NOW)

        self.assertFalse((self.config / "briefing").exists(), self.files_left())
        self.assert_python_briefed(result)

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_selects_current_platform_only_after_full_manifest_validation(self):
        digest = self.pin()
        macos_asset = self.asset_for("macos", ARCH)
        result = self.run_starter(
            "hook", "session-start", url=self.serve(FAKE_BINARY, name="macos", asset=macos_asset),
            now=NOW,
            extra_env={
                "BRIEFING_STARTER_TESTING": "1",
                "BRIEFING_STARTER_TEST_OS": "Darwin",
            })
        cached = self.cache_dir / digest[:16] / "briefing"

        self.assertTrue(cached.is_file(), self.files_left())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(
            result.stdout.startswith("FAKE %s|hook session-start" % (cached.parent / "par")),
            result.stdout)
        self.assertEqual(self.files_left(), [str(cached.relative_to(self.config))])

    def test_macos_hash_path_uses_native_openssl_not_shasum(self):
        self.pin()
        macos_asset = self.asset_for("macos", ARCH)
        self.cached_binary(macos_asset)
        tools = self.tmp / "macos-tools"
        tools.mkdir()
        shasum_log = self.tmp / "shasum.log"
        openssl_log = self.tmp / "openssl.log"

        def passthrough(tool):
            source = shutil.which(tool)
            self.assertIsNotNone(source, "missing native %s" % tool)
            wrapper = tools / tool
            wrapper.write_text("#!/bin/sh\nexec %s \"$@\"\n" % shlex.quote(source))
            wrapper.chmod(0o755)

        for tool in ("dirname", "env"):
            passthrough(tool)
        (tools / "python3").write_text(
            "#!/bin/sh\nexec %s \"$@\"\n" % shlex.quote(sys.executable))
        (tools / "python3").chmod(0o755)
        (tools / "uname").write_text(
            "#!/bin/sh\ncase ${1-} in\n"
            "  -s) printf 'Darwin\\n' ;;\n"
            "  -m) printf '%s\\n' ;;\n"
            "  *) exit 2 ;;\nesac\n" % ARCH)
        (tools / "uname").chmod(0o755)
        (tools / "shasum").write_text(
            "#!/bin/sh\nprintf '%%s\\n' \"$*\" >> %s\nprintf 'shasum must not run\\n' >&2\nexit 97\n"
            % shlex.quote(str(shasum_log)))
        (tools / "shasum").chmod(0o755)
        digest_script = (
            "import hashlib,sys; "
            "print(hashlib.sha256(open(sys.argv[1], 'rb').read()).hexdigest())")
        (tools / "openssl").write_text(
            "#!/bin/sh\nprintf '%%s\\n' \"$*\" >> %s\n"
            "for argument do file=$argument; done\n"
            "digest=$(%s -c %s \"$file\") || exit $?\n"
            "printf 'SHA2-256(%%s)= %%s\\n' \"$file\" \"$digest\"\n"
            % (shlex.quote(str(openssl_log)), shlex.quote(sys.executable),
               shlex.quote(digest_script)))
        (tools / "openssl").chmod(0o755)

        result = self.run_starter(
            "hook", "subagent-start",
            extra_env={
                "PATH": str(tools),
                "BRIEFING_STARTER_TESTING": "1",
                "BRIEFING_STARTER_TEST_OS": "Darwin",
            })

        self.assertFalse(shasum_log.exists(), "shasum was invoked: " + (
            shasum_log.read_text() if shasum_log.exists() else ""))
        self.assertTrue(openssl_log.exists(), "openssl was not invoked")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("|hook subagent-start", result.stdout)

    def test_test_platform_override_is_ignored_without_testing_gate(self):
        self.pin()
        cached = self.cached_binary(self.asset)

        result = self.run_starter(
            "hook", "subagent-start",
            extra_env={"BRIEFING_STARTER_TEST_OS": "FreeBSD"})

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("FAKE", result.stdout)
        self.assertIn(str(cached.parent / "par"), result.stdout)
        self.assertNotIn(MARKER, result.stdout)

    # --- spawn hooks never download

    def test_spawn_hooks_never_download_and_still_brief(self):
        self.pin()
        url = self.serve(FAKE_BINARY)
        for event in ("subagent-start", "pre-tool-use"):
            with self.subTest(event=event):
                result = self.run_starter("hook", event, url=url)
                self.assertFalse((self.config / "briefing").exists(), self.files_left())
                self.assertNotIn("FAKE", result.stdout)
                self.assertEqual(result.returncode, 0, result.stderr)
                if event == "subagent-start":
                    self.assert_python_briefed(result)

    # --- session-start provisions

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for download tests")
    def test_production_rejects_http_and_file_urls(self):
        data = self.marker_binary()
        self.pin(data)
        urls = (
            ("http", self.serve_http(data)),
            ("file", self.serve(data, name="production-file")),
        )

        for scheme, url in urls:
            with self.subTest(scheme=scheme):
                self.config = self.tmp / ("cfg-production-" + scheme)
                self.cache_dir = self.config / "briefing" / "bin" / VERSION
                try:
                    self.execution_marker.unlink()
                except OSError:
                    pass

                result = self.run_starter("hook", "session-start", url=url, now=NOW)

                self.assertFalse(self.execution_marker.exists(),
                                 "an untrusted %s fixture was executed" % scheme)
                self.assert_no_cache_payload()
                self.assert_python_briefed(result)

    def test_wget_rejects_https_to_http_redirect(self):
        data = self.marker_binary()
        self.pin(data)
        fixture = self.tmp / "wget-downgrade-fixture"
        fixture.write_bytes(data)
        wget_log = self.tmp / "wget-downgrade.log"
        bindir = self.tmp / "wget-only-tools"
        bindir.mkdir()

        hash_tool = "sha256sum" if OS_NAME == "linux" else "openssl"
        for tool in ("chmod", "dirname", "env", hash_tool, "ln", "mkdir", "python3",
                     "rm", "uname", "wc"):
            source = shutil.which(tool)
            self.assertIsNotNone(source, "missing required test tool %s" % tool)
            wrapper = bindir / tool
            wrapper.write_text("#!/bin/sh\nexec %s \"$@\"\n" % shlex.quote(source))
            wrapper.chmod(0o755)

        wget = bindir / "wget"
        wget.write_text(
            "#!/bin/sh\n"
            "output=\n"
            "url=\n"
            "while [ \"$#\" -gt 0 ]; do\n"
            "  case $1 in\n"
            "    -O) output=$2; shift 2 ;;\n"
            "    --) shift; url=$1; shift ;;\n"
            "    *) shift ;;\n"
            "  esac\n"
            "done\n"
            "printf '%%s -> http://downgrade.invalid/asset\\n' \"$url\" > %s\n"
            "%s %s \"$output\"\n"
            % (shlex.quote(str(wget_log)), shlex.quote(shutil.which("cp")),
               shlex.quote(str(fixture))))
        wget.chmod(0o755)
        path = str(bindir)
        self.assertIsNone(shutil.which("curl", path=path))
        self.assertEqual(shutil.which("wget", path=path), str(wget))

        result = self.run_starter(
            "hook", "session-start", url="https://origin.invalid", now=NOW,
            extra_env={"PATH": path})

        self.assertFalse(self.execution_marker.exists(),
                         "the wget HTTPS-to-HTTP redirect fixture was executed")
        self.assert_no_cache_payload()
        self.assert_python_briefed(result)

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_testing_gate_allows_local_fixture_url(self):
        data = self.marker_binary()
        digest = self.pin(data)

        result = self.run_starter(
            "hook", "session-start", url=self.serve(data, name="testing-gate"),
            now=NOW, testing=True)
        cached = self.cache_dir / digest[:16] / "briefing"

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.execution_marker.is_file(), "the test fixture was not executed")
        self.assertTrue(cached.is_file(), self.files_left())
        self.assertEqual(sha256(cached.read_bytes()), digest)

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_rejects_symlinked_cache_component(self):
        data = self.marker_binary()
        self.pin(data)
        cases = (
            ("config", ()),
            ("briefing", ("briefing",)),
            ("bin", ("briefing", "bin")),
            ("version", ("briefing", "bin", VERSION)),
            ("pin", ("briefing", "bin", VERSION, sha256(data)[:16])),
        )

        for label, parts in cases:
            with self.subTest(component=label):
                config = self.tmp / ("cfg-symlink-" + label)
                target = self.tmp / ("symlink-target-" + label)
                target.mkdir()
                target.chmod(0o700)
                if parts:
                    component = config.joinpath(*parts)
                    component.parent.mkdir(parents=True)
                    parent = component.parent
                    while True:
                        parent.chmod(0o700)
                        if parent == config:
                            break
                        parent = parent.parent
                    component.symlink_to(target, target_is_directory=True)
                else:
                    config.symlink_to(target, target_is_directory=True)

                self.config = config
                self.cache_dir = self.config / "briefing" / "bin" / VERSION
                try:
                    self.execution_marker.unlink()
                except OSError:
                    pass

                result = self.run_starter(
                    "hook", "session-start", url=self.serve(data, name="symlink-" + label),
                    now=NOW, testing=True)

                self.assertFalse(self.execution_marker.exists(),
                                 "a fixture reached through the %s symlink was executed" % label)
                self.assertEqual(list(target.rglob("*")), [],
                                 "the starter wrote through the %s symlink" % label)
                self.assert_python_briefed(result)

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_rejects_symlinked_config_parent_component(self):
        data = self.marker_binary()
        self.pin(data)
        foreign_parent = self.tmp / "foreign-config-parent"
        nested_parent = foreign_parent / "nested"
        nested_parent.mkdir(parents=True)
        nested_parent.chmod(0o700)
        parent_link = self.tmp / "config-parent-link"
        parent_link.symlink_to(foreign_parent, target_is_directory=True)
        self.config = parent_link / "nested" / "cfg"
        self.cache_dir = self.config / "briefing" / "bin" / VERSION

        result = self.run_starter(
            "hook", "session-start", url=self.serve(data, name="parent-symlink"),
            now=NOW, testing=True)

        self.assertFalse(self.execution_marker.exists(),
                         "a fixture reached through a config parent symlink was executed")
        self.assertEqual(list(nested_parent.rglob("*")), [],
                         "the starter wrote through a config parent symlink")
        self.assert_python_briefed(result)

    def test_cache_directory_swap_during_download_does_not_touch_foreign_path(self):
        data = self.marker_binary()
        self.pin(data)
        fixture = self.tmp / "swap-fixture"
        fixture.write_bytes(data)
        foreign = self.tmp / "foreign-cache"
        foreign.mkdir()
        foreign.chmod(0o700)
        displaced = self.tmp / "displaced-cache"
        swap_log = self.tmp / "cache-swap.log"
        foreign_ops_log = self.tmp / "foreign-cache-operations.log"
        bindir = self.tmp / "cache-swap-tools"
        bindir.mkdir()
        realpath = bindir / "realpath"
        realpath.write_text(
            "#!/bin/sh\nexec %s -c %s \"$@\"\n"
            % (shlex.quote(sys.executable),
               shlex.quote("import os,sys; print(os.path.realpath(sys.argv[-1]))")))
        realpath.chmod(0o755)
        curl = bindir / "curl"
        curl.write_text(
            "#!/bin/sh\n"
            "output=\n"
            "while [ \"$#\" -gt 0 ]; do\n"
            "  case $1 in\n"
            "    -o|--output) output=$2; shift 2 ;;\n"
            "    --output=*) output=${1#*=}; shift ;;\n"
            "    -o*) output=${1#-o}; shift ;;\n"
            "    *) shift ;;\n"
            "  esac\n"
            "done\n"
            "%s %s %s\n"
            "%s -s %s %s\n"
            "resolved=$(%s -- \"$output\") || exit 95\n"
            "printf '%%s\\n' \"$resolved\" > %s\n"
            "foreign=%s\n"
            "case $resolved in\n"
            "  \"$foreign\"|\"$foreign\"/*)\n"
            "    printf 'download:%%s\\n' \"$resolved\" >> %s\n"
            "    ;;\n"
            "esac\n"
            "%s %s >\"$output\"\n"
            % (shlex.quote(shutil.which("mv")), shlex.quote(str(self.cache_dir)),
               shlex.quote(str(displaced)), shlex.quote(shutil.which("ln")),
               shlex.quote(str(foreign)), shlex.quote(str(self.cache_dir)),
               shlex.quote(str(realpath)), shlex.quote(str(swap_log)),
               shlex.quote(str(foreign)), shlex.quote(str(foreign_ops_log)),
               shlex.quote(shutil.which("cat")), shlex.quote(str(fixture))))
        curl.chmod(0o755)

        for tool in ("chmod", "env", "ln", "rm"):
            source = shutil.which(tool)
            self.assertIsNotNone(source, "missing required test tool %s" % tool)
            wrapper = bindir / tool
            wrapper.write_text(
                "#!/bin/sh\n"
                "foreign=%s\n"
                "for argument do\n"
                "  if [ -e \"$argument\" ] || [ -L \"$argument\" ]; then\n"
                "    resolved=$(%s -f -- \"$argument\" 2>/dev/null) || resolved=\n"
                "    case $resolved in\n"
                "      \"$foreign\"|\"$foreign\"/*)\n"
                "        printf '%s:%%s\\n' \"$resolved\" >> %s\n"
                "        break\n"
                "        ;;\n"
                "    esac\n"
                "  fi\n"
                "done\n"
                "exec %s \"$@\"\n"
                % (shlex.quote(str(foreign)), shlex.quote(str(realpath)), tool,
                   shlex.quote(str(foreign_ops_log)), shlex.quote(source)))
            wrapper.chmod(0o755)

        hash_tool = "sha256sum" if OS_NAME == "linux" else "openssl"
        hash_source = shutil.which(hash_tool)
        self.assertIsNotNone(hash_source, "missing required test tool %s" % hash_tool)
        hash_wrapper = bindir / hash_tool
        if OS_NAME == "linux":
            hash_wrapper.write_text(
                "#!/bin/sh\n"
                "foreign=%s\n"
                "resolved=$(%s /proc/$$/fd/0 2>/dev/null) || resolved=\n"
                "case $resolved in\n"
                "  \"$foreign\"|\"$foreign\"/*) printf 'hash:%%s\\n' \"$resolved\" >> %s ;;\n"
                "esac\n"
                "exec %s \"$@\"\n"
                % (shlex.quote(str(foreign)), shlex.quote(str(realpath)),
                   shlex.quote(str(foreign_ops_log)), shlex.quote(hash_source)))
        else:
            hash_wrapper.write_text(
                "#!/bin/sh\n"
                "foreign=%s\n"
                "for argument do\n"
                "  if [ -e \"$argument\" ] || [ -L \"$argument\" ]; then\n"
                "    resolved=$(%s -- \"$argument\" 2>/dev/null) || resolved=\n"
                "    case $resolved in\n"
                "      \"$foreign\"|\"$foreign\"/*)\n"
                "        printf 'hash:%%s\\n' \"$resolved\" >> %s\n"
                "        break\n"
                "        ;;\n"
                "    esac\n"
                "  fi\n"
                "done\n"
                "exec %s \"$@\"\n"
                % (shlex.quote(str(foreign)), shlex.quote(str(realpath)),
                   shlex.quote(str(foreign_ops_log)), shlex.quote(hash_source)))
        hash_wrapper.chmod(0o755)
        path = "%s%s%s" % (bindir, os.pathsep, os.environ["PATH"])

        result = self.run_starter(
            "hook", "session-start", url="https://fixtures.invalid", now=NOW,
            extra_env={"PATH": path})

        self.assertTrue(swap_log.is_file(), "the synchronized cache swap did not run")
        resolved_download = Path(swap_log.read_text().strip())
        foreign_operations = (
            foreign_ops_log.read_text().splitlines() if foreign_ops_log.exists() else [])
        self.assertEqual(
            foreign_operations, [],
            "the swapped foreign cache was touched by provisioning operations")
        self.assertNotEqual(
            os.path.commonpath((str(resolved_download), str(foreign))), str(foreign),
            "the download followed the swapped cache path into the foreign directory")
        self.assertFalse(self.execution_marker.exists(),
                         "the fixture in the swapped foreign cache was executed")
        self.assertEqual(list(foreign.rglob("*")), [],
                         "the starter left content in the foreign cache")
        if displaced.exists():
            self.assertEqual([path for path in displaced.rglob("*") if path.is_file()], [],
                             "the starter left its temporary file after the swap")
        self.assert_python_briefed(result)

    def swap_diagnostics(self, result):
        """Starter outcome and shim call log, for a swap trigger that did not run."""
        calls = self.swap_calls.read_text() if self.swap_calls.exists() else "(no shim call)"
        try:
            message = json.loads(result.stdout).get("systemMessage")
        except (ValueError, AttributeError):
            message = None
        return ("exit=%s\nsystemMessage=%s\nstdout=%s\nstderr=%s\nshim calls:\n%s"
                % (result.returncode, message, result.stdout, result.stderr, calls))

    def test_swap_after_post_download_revalidation_before_warmup_is_rejected(self):
        data = self.marker_binary()
        digest = self.pin(data)
        foreign = self.tmp / "foreign-cache-before-warmup"
        foreign.mkdir()
        foreign.chmod(0o700)
        foreign_pin = foreign / digest[:16]
        foreign_pin.mkdir()
        foreign_pin.chmod(0o700)
        foreign_par = foreign_pin / "par"
        foreign_par.mkdir()
        foreign_par.chmod(0o777)
        displaced = self.tmp / "displaced-cache-before-warmup"
        path, operations, triggered = self._swap_window_tools(
            data, foreign, displaced, "post-download")

        result = self.run_starter(
            "hook", "session-start", url="https://fixtures.invalid", now=NOW,
            extra_env={"PATH": path})

        self.assertTrue(triggered.is_file(),
                        "the pre-warm-up cache swap did not run\n" + self.swap_diagnostics(result))
        foreign_operations = operations.read_text().splitlines() if operations.exists() else []
        self.assertEqual(
            foreign_operations, [],
            "the pre-warm-up swap redirected a path operation into the foreign cache")
        self.assertFalse(self.execution_marker.exists(),
                         "the fixture was warmed after the cache path became unsafe")
        self.assertEqual(stat.S_IMODE(foreign_par.stat().st_mode), 0o777,
                         "the unsafe PAR directory was chmodded through the swapped path")
        self.assertEqual(list(foreign.iterdir()), [foreign_pin],
                         "the pre-warm-up swap changed foreign cache contents")
        self.assertEqual(list(foreign_pin.iterdir()), [foreign_par],
                         "the pre-warm-up swap changed the foreign pin directory")
        self.assertEqual(list(foreign_par.iterdir()), [],
                         "the pre-warm-up swap wrote into the foreign PAR directory")
        if displaced.exists():
            self.assertEqual([path for path in displaced.rglob("*") if path.is_file()], [],
                             "the pre-warm-up swap left a temporary file behind")
        self.assert_python_briefed(result)

    def test_pin_directory_swap_before_warmup_is_rejected(self):
        data = self.marker_binary()
        self.pin(data)
        # The foreign directory stands in for the pin directory: its PAR directory is the
        # unsafe target a path-based warm-up would chmod and fill.
        foreign = self.tmp / "foreign-pin-before-warmup"
        foreign.mkdir()
        foreign.chmod(0o700)
        foreign_par = foreign / "par"
        foreign_par.mkdir()
        foreign_par.chmod(0o777)
        displaced = self.tmp / "displaced-pin-before-warmup"
        path, operations, triggered = self._swap_window_tools(
            data, foreign, displaced, "post-download", swap_dir=self.pin_dir(data))

        result = self.run_starter(
            "hook", "session-start", url="https://fixtures.invalid", now=NOW,
            extra_env={"PATH": path})

        self.assertTrue(triggered.is_file(),
                        "the pin directory swap did not run\n" + self.swap_diagnostics(result))
        foreign_operations = operations.read_text().splitlines() if operations.exists() else []
        self.assertEqual(foreign_operations, [],
                         "the pin directory swap redirected a path operation into the foreign tree")
        self.assertFalse(self.execution_marker.exists(),
                         "the fixture was warmed after the pin directory became unsafe")
        self.assertEqual(stat.S_IMODE(foreign_par.stat().st_mode), 0o777,
                         "the foreign PAR directory was chmodded through the swapped pin directory")
        self.assertEqual(list(foreign.iterdir()), [foreign_par],
                         "the pin directory swap changed the foreign tree")
        self.assertEqual(list(foreign_par.iterdir()), [],
                         "the pin directory swap wrote into the foreign PAR directory")
        self.assertEqual([p for p in displaced.rglob("*") if p.is_file()], [],
                         "the displaced pin directory holds files")
        leftovers = [p for p in (self.config / "briefing" / "bin").iterdir() if p.is_file()]
        self.assertEqual(leftovers, [], "a temporary download was left in briefing/bin")
        self.assert_python_briefed(result)

    def test_swap_after_final_revalidation_before_install_is_rejected(self):
        script = (
            "#!/bin/sh\n"
            "if [ \"${1-}\" = --version ]; then exit 0; fi\n"
            "printf 'executed\\n' >> %s\n"
            "printf 'FIXTURE %%s|%%s\\n' \"$PAR_GLOBAL_TEMP\" \"$*\"\n"
            % shlex.quote(str(self.execution_marker)))
        data = script.encode("utf-8")
        self.pin(data)
        foreign = self.tmp / "foreign-cache-before-install"
        foreign.mkdir()
        foreign.chmod(0o700)
        displaced = self.tmp / "displaced-cache-before-install"
        path, operations, triggered = self._swap_window_tools(
            data, foreign, displaced, "ln")

        result = self.run_starter(
            "hook", "session-start", url="https://fixtures.invalid", now=NOW,
            extra_env={"PATH": path})

        self.assertTrue(triggered.is_file(),
                        "the pre-install cache swap did not run\n" + self.swap_diagnostics(result))
        foreign_operations = operations.read_text().splitlines() if operations.exists() else []
        self.assertEqual(
            foreign_operations, [],
            "the pre-install swap redirected a path operation into the foreign cache")
        self.assertFalse(self.execution_marker.exists(),
                         "the fixture installed through the swapped cache path was executed")
        self.assertEqual(list(foreign.rglob("*")), [],
                         "the pre-install swap modified the foreign cache")
        if displaced.exists():
            self.assertEqual([path for path in displaced.rglob("*") if path.is_file()], [],
                             "the pre-install swap left a temporary file behind")
        self.assert_python_briefed(result)

    def test_post_install_swap_cannot_execute_unverified_public_binary(self):
        self._post_install_swap(simulate_macos=False)

    @unittest.skipUnless(OS_NAME == "linux", "the native macOS leg runs the unsimulated test")
    def test_post_install_swap_on_path_exec_platform_is_detected_and_falls_back(self):
        self._post_install_swap(simulate_macos=True)

    def _swap_outcome(self, result, simulate_macos):
        """Pin the platform's outcome of a cache swap after the verification.

        Linux executes the verified descriptor: the verified bytes run (TRUSTED) however the
        public path changes. macOS has no descriptor exec (no fexecve), so it executes by
        path: the starter re-hashes and re-checks the path components right before execve,
        detects a swap made before that check, refuses to run the swapped bytes and falls
        back. Known limit, not testable from sh: a swap between that final check and
        execve (and an in-place replacement inside the private 0700 cache after the
        re-hash) is not detected; only the cache owner can make either.
        """
        on_macos = simulate_macos or OS_NAME == "macos"
        self.assertEqual(result.returncode, 0, result.stderr)
        if on_macos:
            self.assertNotIn("TRUSTED", result.stdout,
                             "macOS ran a binary after the cache path was swapped")
            self.assert_python_briefed(result)
        else:
            self.assertIn("TRUSTED", result.stdout,
                          "the verified descriptor was not executed: " + result.stdout)

    def test_pin_directory_swap_after_install_cannot_execute_unverified_public_binary(self):
        self._post_install_swap(simulate_macos=False, swap_pin=True)

    @unittest.skipUnless(OS_NAME == "linux", "the native macOS leg runs the unsimulated test")
    def test_pin_directory_swap_on_path_exec_platform_is_detected_and_falls_back(self):
        self._post_install_swap(simulate_macos=True, swap_pin=True)

    def _post_install_swap(self, simulate_macos, swap_pin=False):
        extra_env = {}
        if simulate_macos:
            self.asset = self.asset_for("macos", ARCH)
            extra_env = {"BRIEFING_STARTER_TESTING": "1",
                         "BRIEFING_STARTER_TEST_OS": "Darwin"}
        trusted = (
            "#!/bin/sh\n"
            "if [ \"${1-}\" = --version ]; then exit 0; fi\n"
            "printf 'TRUSTED %%s|%%s\\n' \"$PAR_GLOBAL_TEMP\" \"$*\"\n"
        ).encode("utf-8")
        digest = self.pin(trusted)
        foreign_marker = self.tmp / "post-install-foreign-executed"
        foreign_bytes = (
            "#!/bin/sh\n"
            "printf 'executed\\n' >> %s\n"
            "printf 'FOREIGN\\n'\n"
            % shlex.quote(str(foreign_marker))).encode("utf-8")
        foreign = self.tmp / "foreign-cache-after-install"
        foreign.mkdir()
        foreign.chmod(0o700)
        if swap_pin:
            # The pin directory itself is replaced: the foreign directory is the pin directory.
            foreign_pin = foreign
        else:
            foreign_pin = foreign / digest[:16]
            foreign_pin.mkdir()
            foreign_pin.chmod(0o700)
        foreign_binary = foreign_pin / "briefing"
        foreign_binary.write_bytes(foreign_bytes)
        foreign_binary.chmod(0o700)
        displaced = self.tmp / "displaced-cache-after-install"
        path, _operations, triggered = self._swap_window_tools(
            trusted, foreign, displaced, "rm-retry", macos_hash=simulate_macos or None,
            swap_dir=self.pin_dir(trusted) if swap_pin else None)
        extra_env["PATH"] = path

        result = self.run_starter(
            "hook", "session-start", url="https://fixtures.invalid", now=NOW,
            extra_env=extra_env)

        self.assertTrue(triggered.is_file(),
                        "the post-install cache swap did not run\n" + self.swap_diagnostics(result))
        self.assertFalse(foreign_marker.exists(),
                         "unverified foreign bytes ran after successful installation")
        if swap_pin:
            self.assertEqual(list(foreign.iterdir()), [foreign_binary])
        else:
            self.assertEqual(list(foreign.iterdir()), [foreign_pin])
            self.assertEqual(list(foreign_pin.iterdir()), [foreign_binary])
        self.assertEqual(foreign_binary.read_bytes(), foreign_bytes,
                         "the post-install path changed the foreign binary")
        self.assertEqual(stat.S_IMODE(foreign_binary.stat().st_mode), 0o700)
        self._swap_outcome(result, simulate_macos)

    def test_cache_hit_swap_after_hash_cannot_execute_unverified_public_binary(self):
        self._cache_hit_swap(simulate_macos=False)

    @unittest.skipUnless(OS_NAME == "linux", "the native macOS leg runs the unsimulated test")
    def test_cache_hit_swap_on_path_exec_platform_is_detected_and_falls_back(self):
        self._cache_hit_swap(simulate_macos=True)

    def _cache_hit_swap(self, simulate_macos):
        extra_env = {}
        if simulate_macos:
            self.asset = self.asset_for("macos", ARCH)
            extra_env = {"BRIEFING_STARTER_TESTING": "1",
                         "BRIEFING_STARTER_TEST_OS": "Darwin"}
        trusted = (
            "#!/bin/sh\n"
            "printf 'TRUSTED %%s|%%s\\n' \"$PAR_GLOBAL_TEMP\" \"$*\"\n"
        ).encode("utf-8")
        digest = self.pin(trusted)
        self.cached_binary(self.asset, trusted)
        foreign_marker = self.tmp / "cache-hit-foreign-executed"
        foreign_bytes = (
            "#!/bin/sh\n"
            "printf 'executed\\n' >> %s\n"
            "printf 'FOREIGN\\n'\n"
            % shlex.quote(str(foreign_marker))).encode("utf-8")
        foreign = self.tmp / "foreign-cache-after-hit"
        foreign.mkdir()
        foreign.chmod(0o700)
        foreign_pin = foreign / digest[:16]
        foreign_pin.mkdir()
        foreign_pin.chmod(0o700)
        foreign_binary = foreign_pin / "briefing"
        foreign_binary.write_bytes(foreign_bytes)
        foreign_binary.chmod(0o700)
        displaced = self.tmp / "displaced-cache-after-hit"
        path, _operations, triggered = self._swap_window_tools(
            trusted, foreign, displaced, "rm-retry", macos_hash=simulate_macos or None)
        extra_env["PATH"] = path

        result = self.run_starter(
            "hook", "subagent-start", extra_env=extra_env)

        self.assertTrue(triggered.is_file(), "the cache-hit post-hash swap did not run")
        self.assertFalse(foreign_marker.exists(),
                         "unverified foreign bytes ran after the cache-hit hash check")
        self.assertEqual(list(foreign.iterdir()), [foreign_pin])
        self.assertEqual(list(foreign_pin.iterdir()), [foreign_binary])
        self.assertEqual(foreign_binary.read_bytes(), foreign_bytes,
                         "the cache-hit path changed the foreign binary")
        self.assertEqual(stat.S_IMODE(foreign_binary.stat().st_mode), 0o700)
        self._swap_outcome(result, simulate_macos)

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_cache_directories_and_binary_are_mode_0700(self):
        data = self.marker_binary()
        digest = self.pin(data)

        result = self.run_starter(
            "hook", "session-start", url=self.serve(data, name="private-cache"),
            now=NOW, testing=True, child_umask=0)
        cached = self.cache_dir / digest[:16] / "briefing"

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(cached.is_file(), self.files_left())
        for path in (self.config / "briefing", self.config / "briefing" / "bin",
                     self.cache_dir, cached.parent, cached):
            with self.subTest(path=str(path)):
                self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o700)

    def test_existing_par_directory_is_repaired_to_mode_0700(self):
        data = self.marker_binary()
        self.pin(data)
        cached = self.cached_binary(self.asset, data)
        par_dir = cached.parent / "par"
        par_dir.mkdir()
        par_dir.chmod(0o777)

        result = self.run_starter("hook", "subagent-start")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.execution_marker.exists(), "the verified cached fixture did not run")
        self.assertEqual(stat.S_IMODE(par_dir.stat().st_mode), 0o700)

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_binary_and_par_directory_sit_at_the_short_pin_layout(self):
        digest = self.pin()
        pin = digest[:16]
        self.assertRegex(pin, r"^[0-9a-f]{16}$")
        pin_directory = self.config / "briefing" / "bin" / VERSION / pin

        provision = self.run_starter(
            "hook", "session-start", url=self.serve(FAKE_BINARY), now=NOW, testing=True)
        hit = self.run_starter("hook", "subagent-start", url="file:///nonexistent")

        # The binary has a fixed name; neither the asset name nor the full checksum is in
        # the path, and the PAR directory is plain `par` beside it.
        self.assertEqual(self.files_left(), ["briefing/bin/%s/%s/briefing" % (VERSION, pin)])
        self.assertEqual(sorted(p.name for p in pin_directory.iterdir()), ["briefing"])
        for result in (provision, hit):
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(
                result.stdout.startswith("FAKE %s|hook " % (pin_directory / "par")),
                result.stdout)

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_another_pin_for_the_same_version_provisions_into_a_new_pin_directory(self):
        first = self.marker_binary()
        second = first + b"# rebuilt under the same version\n"
        self.pin(first)
        self.run_starter(
            "hook", "session-start", url=self.serve(first, name="first"), now=NOW, testing=True)
        self.assertTrue(self.cache_file(first).is_file(), self.files_left())
        first_bytes = self.cache_file(first).read_bytes()

        self.pin(second)
        self.execution_marker.unlink()
        self.assertNotEqual(self.pin_dir(first), self.pin_dir(second))
        # With the new pin the old entry is not used: a spawn hook falls back, never downloads.
        spawn = self.run_starter("hook", "subagent-start", url="file:///nonexistent")
        self.assertFalse(self.execution_marker.exists(), "the entry of the old pin was executed")
        self.assert_python_briefed(spawn)
        result = self.run_starter(
            "hook", "session-start", url=self.serve(second, name="second"), now=NOW, testing=True)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.execution_marker.is_file(), "the binary of the new pin did not run")
        self.assertEqual(self.cache_file(second).read_bytes(), second)
        self.assertEqual(stat.S_IMODE(self.pin_dir(second).stat().st_mode), 0o700)
        self.assertEqual(self.cache_file(first).read_bytes(), first_bytes,
                         "the entry of the old pin was changed")
        self.assertEqual(sorted(p.name for p in self.cache_dir.iterdir()),
                         sorted([self.pin_dir(first).name, self.pin_dir(second).name]))

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_temporary_downloads_stay_in_the_bin_directory_and_are_never_left_behind(self):
        good = self.marker_binary()
        cases = (
            ("verified", good, good),
            ("wrong-hash", good, EVIL_BINARY),
        )
        for label, pinned, served in cases:
            with self.subTest(case=label):
                self.config = self.tmp / ("cfg-temp-" + label)
                self.cache_dir = self.config / "briefing" / "bin" / VERSION
                self.pin(pinned)
                fixture = self.tmp / ("temp-fixture-" + label)
                fixture.write_bytes(served)
                log = self.tmp / ("temp-downloads-" + label + ".log")
                bindir = self.tmp / ("temp-tools-" + label)
                bindir.mkdir()
                curl = bindir / "curl"
                curl.write_text(
                    "#!/bin/sh\n"
                    "output=\n"
                    "while [ \"$#\" -gt 0 ]; do\n"
                    "  case $1 in\n"
                    "    -o|--output) output=$2; shift 2 ;;\n"
                    "    --output=*) output=${1#*=}; shift ;;\n"
                    "    -o*) output=${1#-o}; shift ;;\n"
                    "    *) shift ;;\n"
                    "  esac\n"
                    "done\n"
                    "printf '%%s\\n' \"$output\" >> %s\n"
                    "cat %s >\"$output\"\n"
                    % (shlex.quote(str(log)), shlex.quote(str(fixture))))
                curl.chmod(0o755)
                path = "%s%s%s" % (bindir, os.pathsep, os.environ["PATH"])

                self.run_starter(
                    "hook", "session-start", url="https://fixtures.invalid", now=NOW,
                    extra_env={"PATH": path})

                downloads = [Path(line) for line in log.read_text().splitlines()]
                self.assertEqual(len(downloads), 1, downloads)
                bin_directory = self.config / "briefing" / "bin"
                self.assertEqual(downloads[0].parent, bin_directory,
                                 "the temporary download is not in briefing/bin")
                self.assertTrue(downloads[0].name.startswith("." + self.asset + "."), downloads)
                self.assertFalse(downloads[0].exists(), "the temporary download was left behind")
                self.assertEqual(sorted(p.name for p in bin_directory.iterdir()), [VERSION])
                self.assertEqual([p for p in self.cache_dir.iterdir()
                                  if p.is_file() or p.name != sha256(pinned)[:16]], [])
                self.assertEqual(
                    [f for f in self.files_left() if not f.endswith(".failed-at")],
                    ["briefing/bin/%s/%s/briefing" % (VERSION, sha256(pinned)[:16])]
                    if label == "verified" else [])

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_oversized_download_never_reaches_cache(self):
        data = self.marker_binary()
        self.pin(data)

        result = self.run_starter(
            "hook", "session-start", url=self.serve(data, name="oversized"),
            now=NOW, testing=True,
            extra_env={"BRIEFING_STARTER_TEST_MAX_BYTES": str(len(data) - 1)})

        self.assertFalse(self.execution_marker.exists(), "the oversized fixture was executed")
        self.assert_no_cache_payload()
        self.assert_python_briefed(result)

    def test_interrupted_download_leaves_no_trusted_cache_entry(self):
        data = self.marker_binary()
        self.pin(data)
        bindir = self.tmp / "interrupted-tools"
        bindir.mkdir()
        curl = bindir / "curl"
        curl.write_text(
            "#!/bin/sh\n"
            "output=\n"
            "while [ \"$#\" -gt 0 ]; do\n"
            "  case $1 in\n"
            "    -o|--output) output=$2; shift 2 ;;\n"
            "    -o*) output=${1#-o}; shift ;;\n"
            "    *) shift ;;\n"
            "  esac\n"
            "done\n"
            "[ -n \"$output\" ] || exit 98\n"
            "printf 'partial' >\"$output\"\n"
            "exit 56\n")
        curl.chmod(0o755)
        path = "%s%s%s" % (bindir, os.pathsep, os.environ["PATH"])

        result = self.run_starter(
            "hook", "session-start", url="https://fixtures.invalid", now=NOW,
            extra_env={"PATH": path})

        self.assertFalse(self.execution_marker.exists(), "the partial fixture was executed")
        self.assert_no_cache_payload()
        self.assert_python_briefed(result)

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_wrong_hash_is_never_executed(self):
        data = self.marker_binary()
        self.pin(FAKE_BINARY)

        result = self.run_starter(
            "hook", "session-start", url=self.serve(data, name="wrong-hash"),
            now=NOW, testing=True)

        self.assertFalse(self.execution_marker.exists(), "the wrong-hash fixture was executed")
        self.assert_no_cache_payload()
        self.assert_python_briefed(result)

    def test_two_concurrent_provisions_converge_on_one_verified_binary(self):
        data = self.marker_binary()
        digest = self.pin(data)
        fixture = self.tmp / "concurrent-fixture"
        fixture.write_bytes(data)
        log = self.tmp / "concurrent-downloads.log"
        bindir = self.tmp / "concurrent-tools"
        bindir.mkdir()
        curl = bindir / "curl"
        curl.write_text(
            "#!/bin/sh\n"
            "output=\n"
            "while [ \"$#\" -gt 0 ]; do\n"
            "  case $1 in\n"
            "    -o|--output) output=$2; shift 2 ;;\n"
            "    --output=*) output=${1#*=}; shift ;;\n"
            "    -o*) output=${1#-o}; shift ;;\n"
            "    *) shift ;;\n"
            "  esac\n"
            "done\n"
            "if [ ! -f \"$output\" ]; then\n"
            "  printf 'missing:%%s\\n' \"$output\" >> %s\n"
            "  exit 97\n"
            "fi\n"
            "if [ -x \"$output\" ]; then\n"
            "  printf 'executable:%%s\\n' \"$output\" >> %s\n"
            "  exit 96\n"
            "fi\n"
            "printf 'ready:%%s\\n' \"$output\" >> %s\n"
            "sleep 0.25\n"
            "cat %s >\"$output\"\n"
            % (shlex.quote(str(log)), shlex.quote(str(log)), shlex.quote(str(log)),
               shlex.quote(str(fixture))))
        curl.chmod(0o755)
        path = "%s%s%s" % (bindir, os.pathsep, os.environ["PATH"])
        processes = [
            self.start_starter(
                "hook", "session-start", url="https://fixtures.invalid", now=NOW,
                extra_env={"PATH": path})
            for unused in range(2)
        ]
        results = []
        try:
            for process in processes:
                stdout, stderr = process.communicate(self.payload, timeout=60)
                results.append((process.returncode, stdout, stderr))
        finally:
            for process in processes:
                if process.poll() is None:
                    process.kill()
                    process.wait()

        attempts = log.read_text().splitlines() if log.exists() else []
        self.assertTrue(attempts, "neither concurrent provision reached the downloader")
        self.assertTrue(all(line.startswith("ready:") for line in attempts), attempts)
        temporary_paths = [line[len("ready:"):] for line in attempts]
        self.assertEqual(len(temporary_paths), len(set(temporary_paths)), attempts)
        for returncode, stdout, stderr in results:
            self.assertEqual(returncode, 0, stderr)
            self.assertIn("FIXTURE", stdout)
        cached = self.cache_dir / digest[:16] / "briefing"
        self.assertTrue(cached.is_file(), self.files_left())
        self.assertEqual(sha256(cached.read_bytes()), digest)
        self.assertEqual(self.files_left(), [str(cached.relative_to(self.config))])
        self.assertEqual(stat.S_IMODE(cached.stat().st_mode), 0o700)

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_verified_cache_runs_offline_and_tampering_is_rejected(self):
        data = self.marker_binary()
        digest = self.pin(data)
        url = self.serve(data, name="offline-cache")
        provision = self.run_starter(
            "hook", "session-start", url=url, now=NOW, testing=True)
        cached = self.cache_dir / digest[:16] / "briefing"
        self.assertEqual(provision.returncode, 0, provision.stderr)
        self.assertTrue(cached.is_file(), self.files_left())
        self.assertTrue(self.execution_marker.exists(), "the provisioned fixture did not run")

        shutil.rmtree(str(self.tmp / "offline-cache"))
        self.execution_marker.unlink()
        bindir, log = self._fake_source()
        path = "%s%s%s" % (bindir, os.pathsep, os.environ["PATH"])
        offline = self.run_starter(
            "hook", "subagent-start", url="https://offline.invalid",
            extra_env={"PATH": path})
        self.assertEqual(offline.returncode, 0, offline.stderr)
        self.assertTrue(self.execution_marker.exists(), "the verified offline cache did not run")
        self.assertFalse(log.exists(), "the verified cache attempted a download")

        self.execution_marker.unlink()
        with open(str(cached), "ab") as handle:
            handle.write(b"\nprintf 'tampered cache ran\\n'\n")
        tampered = self.run_starter(
            "hook", "subagent-start", url="https://offline.invalid",
            extra_env={"PATH": path})
        self.assertFalse(self.execution_marker.exists(), "the tampered cache was executed")
        self.assertFalse(log.exists(), "a spawn hook attempted to repair the cache")
        self.assert_python_briefed(tampered)

    def test_non_session_start_commands_never_download(self):
        data = self.marker_binary()
        self.pin(data)
        bindir, log = self._fake_source()
        path = "%s%s%s" % (bindir, os.pathsep, os.environ["PATH"])
        commands = (
            ("hook", "subagent-start"),
            ("hook", "pre-tool-use"),
            ("hook", "marketplace-notice"),
            ("--version",),
            ("--help",),
            ("doctor",),
            ("doctor", "--tsv"),
        )

        for args in commands:
            with self.subTest(args=args):
                result = self.run_starter(
                    *args, url="https://fixtures.invalid", now=NOW,
                    extra_env={"PATH": path})
                self.assertFalse(self.execution_marker.exists(),
                                 "a non-SessionStart command executed the fixture")
                self.assertFalse(log.exists(), "a downloader was started: " + (
                    log.read_text() if log.exists() else ""))
                if args == ("hook", "subagent-start"):
                    self.assert_python_briefed(result)
        self.assertFalse((self.config / "briefing").exists(), self.files_left())

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_session_start_downloads_verifies_caches_and_runs_binary(self):
        digest = self.pin()
        result = self.run_starter(
            "hook", "session-start", url=self.serve(FAKE_BINARY), now=NOW, testing=True)
        cached = self.cache_dir / digest[:16] / "briefing"
        self.assertTrue(cached.is_file(), self.files_left())
        self.assertTrue(os.access(str(cached), os.X_OK))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(
            result.stdout.startswith("FAKE %s|hook session-start" % (cached.parent / "par")),
            result.stdout)
        self.assertEqual(self.files_left(), [str(cached.relative_to(self.config))])

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_cache_hit_starts_binary_without_network(self):
        self.pin()
        self.run_starter(
            "hook", "session-start", url=self.serve(FAKE_BINARY), now=NOW, testing=True)
        result = self.run_starter("hook", "subagent-start", url="file:///nonexistent")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("|hook subagent-start", result.stdout)
        self.assertNotIn(MARKER, result.stdout)

    def test_verified_cached_binary_preserves_stdout_stderr_and_exit_status(self):
        data = (
            "#!/bin/sh\n"
            "printf 'CACHE-STDOUT\\n'\n"
            "printf 'CACHE-STDERR\\n' >&2\n"
            "exit 7\n"
        ).encode("utf-8")
        self.pin(data)
        self.cached_binary(self.asset, data)

        result = self.run_starter("stream-contract")

        self.assertEqual(
            (result.stdout, result.stderr, result.returncode),
            ("CACHE-STDOUT\n", "CACHE-STDERR\n", 7))

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_tampered_cache_is_not_run_and_spawn_still_briefed(self):
        digest = self.pin()
        self.run_starter(
            "hook", "session-start", url=self.serve(FAKE_BINARY), now=NOW, testing=True)
        cached = self.cache_dir / digest[:16] / "briefing"
        with open(str(cached), "ab") as handle:
            handle.write(b"echo TAMPERED\n")
        result = self.run_starter("hook", "subagent-start", url="file:///nonexistent")
        self.assertNotIn("FAKE", result.stdout)
        self.assertNotIn("TAMPERED", result.stdout)
        self.assert_python_briefed(result)

    # --- wrong checksum

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_wrong_checksum_is_neither_used_nor_executed_nor_kept(self):
        self.pin()  # pins FAKE_BINARY; the server delivers something else
        url = self.serve(EVIL_BINARY, name="bad")
        result = self.run_starter(
            "hook", "session-start", url=url, now=NOW, testing=True)
        self.assertNotIn("EVIL-RAN", result.stdout + result.stderr)
        self.assertNotIn("FAKE", result.stdout)
        self.assertEqual(result.returncode, 0, result.stderr)
        # Only the backoff marker may remain: no binary, no temp download, no unpacked dir.
        leftovers = [f for f in self.files_left() if not f.endswith(".failed-at")]
        self.assertEqual(leftovers, [])
        # And the Python hook still briefs on the next spawn.
        self.assert_python_briefed(self.run_starter("hook", "subagent-start", url=url))

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_failed_session_start_backs_off_for_fifteen_minutes(self):
        self.pin()
        bad = self.serve(EVIL_BINARY, name="bad")
        good = self.serve(FAKE_BINARY)
        self.run_starter("hook", "session-start", url=bad, now=NOW, testing=True)
        marker = self.pin_dir() / ("." + self.asset + ".failed-at")
        self.assertTrue(marker.is_file(), self.files_left())
        self.assertEqual(marker.read_text().strip(), NOW)
        soon = self.run_starter(
            "hook", "session-start", url=good, now=str(int(NOW) + 899), testing=True)
        self.assertNotIn("FAKE", soon.stdout, "retried inside the backoff window")
        later = self.run_starter(
            "hook", "session-start", url=good, now=str(int(NOW) + 900), testing=True)
        self.assertIn("|hook session-start", later.stdout)
        self.assertFalse(marker.exists(), "a successful provision clears the backoff marker")

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_unreachable_download_leaves_no_binary_and_still_briefs(self):
        self.pin()
        result = self.run_starter(
            "hook", "session-start", url="file:///nonexistent", now=NOW, testing=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([f for f in self.files_left() if not f.endswith(".failed-at")], [])
        self.assert_python_briefed(self.run_starter("hook", "subagent-start"))


    # --- the marketplace notice (k20): the binary when verified, else Python, else silence

    NOTICE_START = "briefing is now also in the shared Getty marketplace"

    def notice_env(self, **values):
        root = self.home / ".claude" / "plugins" / "cache" / "briefing" / "briefing" / "0.1.0"
        env = {"CLAUDE_PLUGIN_ROOT": str(root)}
        env.update(values)
        return env

    def notice_state(self):
        return self.home / ".claude" / ".briefing-marketplace-notice"

    def run_notice(self, extra_env=None, **kwargs):
        stdin = json.dumps({"hook_event_name": "SessionStart", "source": "startup",
                            "cwd": str(self.proj)})
        return self.run_starter("hook", "marketplace-notice", stdin=stdin,
                                extra_env=self.notice_env(**(extra_env or {})), **kwargs)

    def python_free_path(self):
        """A PATH of every ordinary tool the starter may use and no Python or Perl."""
        farm = self.tmp / "python-free-path"
        farm.mkdir(exist_ok=True)
        refused = re.compile(r"^(python|py$|perl|cpan|pip)")
        for directory in ("/usr/bin", "/bin", "/usr/sbin", "/sbin"):
            if not os.path.isdir(directory):
                continue
            for name in sorted(os.listdir(directory)):
                target = os.path.join(directory, name)
                link = farm / name
                if (refused.match(name) or link.is_symlink() or not os.path.isfile(target)
                        or not os.access(target, os.X_OK)):
                    continue
                os.symlink(target, str(link))
        for name in os.listdir(str(farm)):
            self.assertIsNone(refused.match(name), "the PATH farm contains " + name)
        for tool in ("python3", "python"):
            self.assertIsNone(shutil.which(tool, path=str(farm)))
        return str(farm)

    def assert_silent(self, result):
        self.assertEqual((result.stdout, result.stderr, result.returncode), ("", "", 0))

    def test_notice_without_pin_runs_the_python_notice_once(self):
        first = self.run_notice()
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(first.stderr, "")
        message = json.loads(first.stdout)["systemMessage"]
        self.assertTrue(message.startswith(self.NOTICE_START), message)
        self.assertEqual(self.notice_state().read_text(encoding="utf-8"), "briefing\n")
        self.assert_silent(self.run_notice())

    def test_notice_is_silent_where_the_python_notice_is_silent(self):
        getty = self.home / ".claude" / "plugins" / "cache" / "getty" / "briefing" / "0.1.0"
        for label, extra in (("getty marketplace", {"CLAUDE_PLUGIN_ROOT": str(getty)}),
                             ("outside a cache", {"CLAUDE_PLUGIN_ROOT": str(self.plugin)})):
            with self.subTest(case=label):
                self.assert_silent(self.run_notice(extra_env=extra))
        # No plugin root at all (run_starter alone leaves it unset).
        self.assert_silent(self.run_starter("hook", "marketplace-notice"))
        self.assertFalse(self.notice_state().exists())

    def test_notice_without_python_is_silent_and_leaves_no_state(self):
        bindir, log = self._fake_source()
        path = "%s%s%s" % (bindir, os.pathsep, self.python_free_path())
        notice = self.run_notice(extra_env={"PATH": path})
        self.assert_silent(notice)
        self.assertFalse(self.notice_state().exists())
        self.assertFalse(log.exists(), "the notice started a downloader")
        self.assertFalse((self.config / "briefing").exists(), self.files_left())
        # The contrast: every other hook still warns in the same PATH.
        spawn = self.run_starter("hook", "subagent-start", extra_env={"PATH": path})
        self.assertEqual(spawn.returncode, 0, spawn.stderr)
        self.assertRegex(json.loads(spawn.stdout)["systemMessage"],
                         r"^briefing: no binary \(.+\) and no fallback \(.+\)\.$")

    def test_notice_with_python_but_without_the_script_is_silent(self):
        # The notice script is gone; the other hook script goes too, so that no stray Python
        # hook can answer: a courtesy note never turns into the "no fallback" warning.
        (self.plugin / "hooks" / "briefing-marketplace-notice").unlink()
        (self.plugin / "hooks" / "briefing-preload").unlink()
        self.assert_silent(self.run_notice())
        self.assertFalse(self.notice_state().exists())

    def test_notice_with_verified_cache_runs_the_binary_with_exactly_the_hook_words(self):
        self.pin()
        self.cached_binary(self.asset)
        bindir, log = self._fake_source()
        path = "%s%s%s" % (bindir, os.pathsep, self.python_free_path())
        result = self.run_notice(url="https://fixtures.invalid", now=NOW,
                                 extra_env={"PATH": path})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "FAKE %s|hook marketplace-notice\n" % self.par_dir())
        self.assertEqual(result.stderr, "")
        self.assertFalse(log.exists(), "the notice attempted a download")
        self.assertFalse(self.notice_state().exists(), "the Python notice ran beside the binary")

    def test_notice_with_a_pin_but_no_cache_never_provisions(self):
        data = self.marker_binary()
        self.pin(data)
        bindir, log = self._fake_source()
        path = "%s%s%s" % (bindir, os.pathsep, os.environ["PATH"])
        result = self.run_notice(url=self.serve(data), now=NOW, testing=True,
                                 extra_env={"PATH": path})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(json.loads(result.stdout)["systemMessage"].startswith(self.NOTICE_START))
        self.assertFalse(self.execution_marker.exists())
        self.assertFalse(log.exists(), "the notice started a downloader")
        self.assertFalse((self.config / "briefing").exists(), self.files_left())
        # And with no Python to fall back to: silent, still nothing provisioned.
        self.notice_state().unlink()
        silent = self.run_notice(url=self.serve(data), now=NOW, testing=True,
                                 extra_env={"PATH": "%s%s%s" % (bindir, os.pathsep,
                                                                self.python_free_path())})
        self.assert_silent(silent)
        self.assertFalse(log.exists(), "the notice started a downloader")
        self.assertFalse((self.config / "briefing").exists(), self.files_left())

    def test_notice_with_a_tampered_cache_never_runs_it(self):
        data = self.marker_binary()
        self.pin(data)
        cached = self.cached_binary(self.asset, data)
        with open(str(cached), "ab") as handle:
            handle.write(b"\nprintf 'tampered cache ran\\n'\n")
        python = self.run_notice()
        self.assertFalse(self.execution_marker.exists(), "the tampered cache was executed")
        self.assertNotIn("tampered", python.stdout)
        self.assertTrue(json.loads(python.stdout)["systemMessage"].startswith(self.NOTICE_START))
        self.notice_state().unlink()
        silent = self.run_notice(extra_env={"PATH": self.python_free_path()})
        self.assertFalse(self.execution_marker.exists(), "the tampered cache was executed")
        self.assert_silent(silent)

    # --- explicit non-provisioning commands

    def _fake_source(self):
        """Fake `curl`/`wget` on PATH that record any call: nothing may read the source."""
        bindir = self.tmp / "fakebin"
        bindir.mkdir(exist_ok=True)
        log = self.tmp / "fetch.log"
        for tool in ("curl", "wget"):
            script = bindir / tool
            script.write_text('#!/bin/sh\necho "$0 $*" >>"%s"\nexit 1\n' % log)
            script.chmod(0o755)
        return bindir, log

    def test_version_and_doctor_never_download(self):
        self.pin()
        url = self.serve(FAKE_BINARY)
        bindir, log = self._fake_source()
        old_path = os.environ["PATH"]
        os.environ["PATH"] = "%s%s%s" % (bindir, os.pathsep, old_path)
        self.addCleanup(os.environ.__setitem__, "PATH", old_path)
        for args in (("--version",), ("doctor",), ("doctor", "--tsv")):
            with self.subTest(args=args):
                result = self.run_starter(*args, url=url, now=NOW,
                                          stdin="")
                self.assertNotIn("FAKE", result.stdout)
                self.assertFalse((self.config / "briefing").exists(), self.files_left())
                self.assertFalse(log.exists(), "a downloader was started: " + (
                    log.read_text() if log.exists() else ""))

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_download_url_has_no_v_before_the_version(self):
        self.pin()
        # Serve under <base>/<version>/<asset> only: a "v<version>" tag finds nothing.
        base = "file://%s/" % (self.tmp / "tags")
        directory = self.tmp / "tags" / VERSION
        directory.mkdir(parents=True)
        (directory / self.asset).write_bytes(FAKE_BINARY)
        text = self.starter.read_text()
        self.assertIn("release_tag_prefix=\n", text)
        # Rewrite only the prefix so the starter composes the URL itself.
        patched = text.replace("release_url_prefix=https://github.com/Getty/briefing/releases/download/",
                               "release_url_prefix=" + base)
        self.starter.write_text(patched)
        # The CLI command that provisions: a SessionStart hook, using the default URL.
        result = self.run_starter("hook", "session-start", now=NOW, testing=True)
        cached = self.cache_dir / sha256(FAKE_BINARY)[:16] / "briefing"
        self.assertTrue(cached.is_file(), "URL did not resolve to <base>/<version>/<asset>: "
                        + repr(self.files_left()))
        self.assertEqual(result.returncode, 0, result.stderr)

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_version_rule_rejects_what_the_bootstrap_must_also_reject(self):
        # The one version rule of starter and Windows bootstrap: first character [A-Za-z0-9],
        # then only [A-Za-z0-9._+-]. A violating version makes the whole manifest malformed.
        bad = {
            "slash": "1.2/3",
            "backslash": "1.2\\3",
            "leading-dot": ".1.2.3",
            "leading-dash": "-1.2.3",
            "empty": "",
            "space": "1.2 3",
            "colon": "1.2:3",
            "non-ascii": "1.2.3-\u00e4",
        }
        for label, version in bad.items():
            with self.subTest(version=label):
                self.write_pins([
                    (sha256(FAKE_BINARY), "briefing-%s-%s-%s%s" % (
                        version, os_name, arch, ".exe" if os_name == "windows" else ""))
                    for os_name, arch in CANONICAL_PLATFORMS])
                result = self.run_starter(
                    "hook", "session-start", url=self.serve(FAKE_BINARY), now=NOW, testing=True)
                self.assertFalse((self.config / "briefing").exists(), self.files_left())
                self.assertNotIn("FAKE", result.stdout)
                self.assert_python_briefed(result)

    @unittest.skipUnless(HAVE_CURL, "skipped: curl is not available for the file:// download")
    def test_version_rule_accepts_plus_and_other_versions(self):
        for version in ("0.002", "9.9.9", "probe-abc1234", "1.0+build.5", "1.0_rc-1"):
            with self.subTest(version=version):
                if (self.config / "briefing").exists():
                    shutil.rmtree(str(self.config / "briefing"))
                asset = "briefing-%s-%s-%s" % (version, OS_NAME, ARCH)
                self.write_pins([
                    (sha256(FAKE_BINARY), "briefing-%s-%s-%s%s" % (
                        version, os_name, arch, ".exe" if os_name == "windows" else ""))
                    for os_name, arch in CANONICAL_PLATFORMS])
                directory = self.tmp / ("v-" + version.replace("+", "p")) / version
                directory.mkdir(parents=True)
                (directory / asset).write_bytes(FAKE_BINARY)
                result = self.run_starter(
                    "hook", "session-start", url="file://%s" % directory, now=NOW, testing=True)
                cached = (self.config / "briefing" / "bin" / version / sha256(FAKE_BINARY)[:16]
                          / "briefing")
                self.assertTrue(cached.is_file(), self.files_left())
                self.assertRegex(result.stdout, r"\|hook session-start")


if __name__ == "__main__":
    unittest.main()
