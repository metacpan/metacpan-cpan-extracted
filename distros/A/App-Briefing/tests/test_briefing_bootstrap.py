#!/usr/bin/env python3
"""Build and native process-contract tests for briefing-bootstrap.exe.

On Windows an explicit bootstrap may be supplied as the first argument:

    python tests/test_briefing_bootstrap.py C:\\absolute\\path\\to\\briefing-bootstrap.exe

Without that argument the bootstrap and the native fixture child are built in a
temporary directory. Runtime tests are native-Windows evidence and are skipped
elsewhere; the reproducible cross-build test runs on any host with ziglang.
"""

import faulthandler
import hashlib
import http.server
import importlib.util
import json
import os
import re
import shutil
import socket
import ssl
import struct
import subprocess
import sys
import tempfile
import threading
import time
import unittest
import warnings
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
BUILD = REPO_ROOT / "briefing-bootstrap" / "build.py"
SOURCE = REPO_ROOT / "briefing-bootstrap" / "briefing-bootstrap.c"
STUB_SOURCE = REPO_ROOT / "tests" / "fixtures" / "briefing-bootstrap-stub.c"
EXPLICIT_BOOTSTRAP = None
IS_WINDOWS = os.name == "nt"
VERSION = "0.001"
# The pin directory of the gated fixture child: the 16 lowercase hex digits the bootstrap
# requires between the version directory and the file.
FIXTURE_PIN = "0123456789abcdef"
ASSETS = (
    "briefing-0.001-linux-x86_64",
    "briefing-0.001-linux-arm64",
    "briefing-0.001-macos-x86_64",
    "briefing-0.001-macos-arm64",
    "briefing-0.001-windows-x86_64.exe",
)
WINDOWS_ASSET = ASSETS[-1]
# Loopback-only self-signed end-entity certificate (CA:FALSE, serverAuth, SAN localhost and
# 127.0.0.1 only), valid to 2036, so that even a leftover trust entry can only vouch for
# loopback. Generated with:
#   openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -days 3650 \
#     -subj "/CN=briefing-bootstrap-local-test-leaf" \
#     -addext "basicConstraints=critical,CA:FALSE" \
#     -addext "keyUsage=critical,digitalSignature,keyEncipherment" \
#     -addext "extendedKeyUsage=serverAuth" \
#     -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
TEST_CERTIFICATE = """-----BEGIN CERTIFICATE-----
MIIDezCCAmOgAwIBAgIUWhK6kquCp4vSY+3xZ+fNodCpAzYwDQYJKoZIhvcNAQEL
BQAwLTErMCkGA1UEAwwiYnJpZWZpbmctYm9vdHN0cmFwLWxvY2FsLXRlc3QtbGVh
ZjAeFw0yNjExMTgwNzEzMzlaFw0zNjExMTUwNzEzMzlaMC0xKzApBgNVBAMMImJy
aWVmaW5nLWJvb3RzdHJhcC1sb2NhbC10ZXN0LWxlYWYwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQDCGU1zwc4NrbZOoPXBgeSKclOcLfQSUfZQmNUu2GEO
1uRp3qf2EvlZNvckGA26LoJ6lX8x5SQCNpYMBZ6yf3HVmnm6w/6anGdeWRcqHKSk
hEuFouiVkpT+E0VlrcsPlnfFwFjnxlJDE285g5VcriIvMm06PeejBzwjvggO5Gqa
memgkGFuOiaVM5URObYPaa5q4b/oQWEuKZMSBeInCXAX7tGVOlMq1A18/Qc8BRQW
eVfBSLL3i99N0PooanAEsgzayo4831QU1SiUnznSOQX7bjPggaTHQMrk7q7MQVJA
qXNh5/7f14eU0lGns5bDHN2e6Nq+v1qym+rBuu5MjJARAgMBAAGjgZIwgY8wHQYD
VR0OBBYEFP/10UbGGTRu/5V9BIxtx36kgJVEMB8GA1UdIwQYMBaAFP/10UbGGTRu
/5V9BIxtx36kgJVEMAwGA1UdEwEB/wQCMAAwDgYDVR0PAQH/BAQDAgWgMBMGA1Ud
JQQMMAoGCCsGAQUFBwMBMBoGA1UdEQQTMBGCCWxvY2FsaG9zdIcEfwAAATANBgkq
hkiG9w0BAQsFAAOCAQEAYYm4MvhBFUrSLmFzPGwItHfawKpF84S2m0qe6D2xQ+KJ
0fZlb51dUrnk2SWAIVOG8Ph/2p0zv6xe2fEj8clT4JTxKMWKbTw1E8ApEtMSlKFx
fj8mtf7F/rqERWE4Fvcuje77ea6bgKX+gUchT052oPgCCzViPDjQzYu6xUEhEPiy
emzJ+JJBGPznMC5WytfkqmoPQwkl87fo2LrKB6kgXGCVeEJe0h0V7ve1cYGM9PFf
zbV6DnAwYSZXk1aI5XNU/mP1aA+tfaYG4AYZGn40Qf3fUdUP4ecq9IrOHeObaFV/
ovlwWmx4VEoafOc7dfjaVTVxiawnZhzQV/fbU/UdfA==
-----END CERTIFICATE-----
"""
TEST_PRIVATE_KEY = """-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDCGU1zwc4NrbZO
oPXBgeSKclOcLfQSUfZQmNUu2GEO1uRp3qf2EvlZNvckGA26LoJ6lX8x5SQCNpYM
BZ6yf3HVmnm6w/6anGdeWRcqHKSkhEuFouiVkpT+E0VlrcsPlnfFwFjnxlJDE285
g5VcriIvMm06PeejBzwjvggO5GqamemgkGFuOiaVM5URObYPaa5q4b/oQWEuKZMS
BeInCXAX7tGVOlMq1A18/Qc8BRQWeVfBSLL3i99N0PooanAEsgzayo4831QU1SiU
nznSOQX7bjPggaTHQMrk7q7MQVJAqXNh5/7f14eU0lGns5bDHN2e6Nq+v1qym+rB
uu5MjJARAgMBAAECggEAE3/nQBHgWY9yGUQibGZYR3Bk5fPX6V9Cl6ZDBInIdm0w
VVKBHT+avVPAUGf6ORIjGZ2bQa/7hh1lxZ9q6hPTo9n5EMJP+chsuhXJNfnasIx5
6dsL8rrfLQdSmXx0QgSj08IXLHHIIeT575VAlCcKWCOAxbEibEZ1zEFzHcvkydMv
tf25/czc9ebjTx9Hpx8WCNWV3KHiCZjSDYoD2Xrw2heZmHbEgSQK9QGSJ2GVGAG2
tu8PwwC8KBo40jh0bs/SVNugLyuHTLzjoH0wQ30KQQK1iDRxnCk/zyXOKRo9xdUj
h3tA8/TRgjXKcdqolgm1iSsRZ69lpWzfgA8uxj74gQKBgQDvd5Pah3SmlXeHsAn8
1wpnYOgCSbg13VjNo+raaBpT6gLlDdcatNxzs7JXXpPZ+ohxm/TJONqYZyyqT9Y7
reIHcMXS1uN3dFdqbN8R8xYUqRFDRe1pDxbB1KRYbDNy/+eXOENj4bWXwuhg8Uxd
X+PVQjxMK00nkppXeXgzVsilfQKBgQDPf976KqBgeYTytMKXEOq93aopKKe0W0fD
oKZUcOfddhG6wdopiJv9mEeb65sLsylABCGSkZHkkwfQc2+NVHhCMwpyMPWzPvep
ujoPlTWxoX1YsdTc0s3O4Wnb3HYetKsZkoQ9FYxqua25q1Fa9GWvmU6Eg9yvXEDW
5qPTUoxJJQKBgQDeKYD5T4vwdGCFeNN7SAG18Rit7rjA+E7H0Zgz8jriuQrgeFuk
wkB38zG0juD6bM0jIX4TJPTgSXANva3ShjpZjs1pEsXLcBsdeE3nuC83EbcbQ4fD
XSVOxDmIczG0MigoiiEzTBaN6lxue87OHgUgN6f7Pn0BBqi8GMxkTNIvfQKBgAjE
XVZykJ4i5EQg8QvS8igdgoAEsLlFFg4k7oIo1xMbVvpuEFqq4/ReB8CFvuJKqpaC
1ixMLD7dG3pqNi9hf0dEws86VFdDdNFeBe/8nO0pZpNlyBmgaoOwMHnSoccAWS5W
a3HtRCaKO9XZcDGIm/dEYfXlYGCkZDTwP8HA/h5lAoGBAOa9iXf7bkkv/Edhk9H0
JoE2P3t65Ed35pjDJPpf527ZbovNdHbxWxGN90d2Mm7iL8hMvCvPI0xhrHZbb1E4
UE4zWa2FlOhN9l+fSTGNWcH8PXTedW+C4584s4t36cJEESQ6M0VhrWGNyXy/cAym
P8Knf8JlVtE4XMjsNUgu33Am
-----END PRIVATE KEY-----
"""


def _text(data):
    if data is None:
        return ""
    if isinstance(data, bytes):
        return data.decode("utf-8", "replace")
    return str(data)


def canonical_path(path):
    """One spelling per directory entry: long form, real case, no alias.

    The bootstrap may hand a child the 8.3 alias (C:\\Users\\RUNNER~1\\...) of a long
    path; a test that compares such a path with a resolve()d one compares identity,
    not text. Comparison keys are used only for paths that exist.
    """
    path = str(path)
    if os.name == "nt":
        try:
            import ctypes

            buffer = ctypes.create_unicode_buffer(32768)
            length = ctypes.windll.kernel32.GetLongPathNameW(path, buffer, 32768)
            if 0 < length < 32768:
                path = buffer.value
        except (OSError, AttributeError):
            pass
    return os.path.normcase(os.path.realpath(path))


def canonical_arg(argument):
    """Canonicalise a path-valued argument; leave switches and plain words alone.

    The fallbacks receive the plugin paths in the spelling the bootstrap was launched
    with (the 8.3 form on a Windows runner), so paths are compared by identity.
    """
    if argument.startswith("-I") and len(argument) > 2:
        return "-I" + canonical_path(argument[2:])
    if os.path.isabs(argument):
        return canonical_path(argument)
    return argument


def canonical_args(arguments):
    return [canonical_arg(argument) for argument in arguments]


def describe_output(stdout, stderr, returncode=None):
    """Return one message fragment carrying a run's exit code and both streams."""
    return "exit=%r\nstdout:\n%s\nstderr:\n%s" % (returncode, _text(stdout), _text(stderr))


def kill_tree(process):
    """Kill a process and, on Windows, its descendants that may hold the pipes open."""
    if process.poll() is not None:
        return
    if os.name == "nt":
        try:
            subprocess.run(
                ["taskkill", "/T", "/F", "/PID", str(process.pid)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=15,
            )
        except (OSError, subprocess.SubprocessError):
            pass
    try:
        process.kill()
    except OSError:
        pass


def communicate_bounded(process, input_bytes=b"", timeout=30, label="process"):
    """communicate() that turns a hang into an AssertionError carrying partial output.

    After the timeout the whole process tree is killed and the drained pipes are read
    once more with a second, short bound, so a descendant holding a pipe cannot hang
    the run a second time.
    """
    try:
        return process.communicate(input_bytes, timeout=timeout)
    except subprocess.TimeoutExpired as expired:
        stdout, stderr = expired.stdout, expired.stderr
        kill_tree(process)
        try:
            stdout, stderr = process.communicate(timeout=10)
        except subprocess.TimeoutExpired as again:
            stdout = again.stdout if again.stdout is not None else stdout
            stderr = again.stderr if again.stderr is not None else stderr
        raise AssertionError(
            "%s did not finish within %ss and was killed\n%s"
            % (label, timeout, describe_output(stdout, stderr, process.returncode))
        )


def run_bounded(command, timeout, label=None, input_bytes=None, **kwargs):
    """subprocess.run replacement with the bounded, reporting hang handling above."""
    process = subprocess.Popen(
        command,
        stdin=subprocess.PIPE if input_bytes is not None else None,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        **kwargs
    )
    try:
        stdout, stderr = communicate_bounded(
            process, input_bytes if input_bytes is not None else None,
            timeout=timeout, label=label or str(command[0]))
    finally:
        kill_tree(process)
    return subprocess.CompletedProcess(command, process.returncode, stdout, stderr)


def build_executable(output, source=None):
    command = [sys.executable, str(BUILD), str(output)]
    if source is not None:
        command.extend(("--src", str(source)))
    result = run_bounded(command, 120, label="executable build", cwd=str(REPO_ROOT))
    if result.returncode != 0:
        raise AssertionError(
            "build failed (%s):\nstdout:\n%s\nstderr:\n%s"
            % (
                result.returncode,
                result.stdout.decode("utf-8", "replace"),
                result.stderr.decode("utf-8", "replace"),
            )
        )


def pe_header(data):
    if len(data) < 0x40:
        raise AssertionError("output is too short to contain a PE header")
    offset = struct.unpack_from("<I", data, 0x3C)[0]
    if offset + 24 > len(data) or data[offset:offset + 4] != b"PE\0\0":
        raise AssertionError("output does not contain a valid PE signature")
    machine = struct.unpack_from("<H", data, offset + 4)[0]
    timestamp = struct.unpack_from("<I", data, offset + 8)[0]
    return machine, timestamp


class BootstrapBuildTests(unittest.TestCase):
    def test_build_is_reproducible_and_has_zero_coff_timestamp(self):
        self.assertTrue(BUILD.is_file(), "briefing-bootstrap/build.py is missing")
        self.assertTrue(SOURCE.is_file(), "briefing-bootstrap/briefing-bootstrap.c is missing")
        if importlib.util.find_spec("ziglang") is None:
            self.skipTest("ziglang is not installed; reproducible PE build is unproved")

        with tempfile.TemporaryDirectory(prefix="briefing-bootstrap-build-") as temp:
            root = Path(temp)
            first = root / "first.exe"
            second = root / "second.exe"
            build_executable(first)
            build_executable(second)

            first_bytes = first.read_bytes()
            second_bytes = second.read_bytes()
            self.assertEqual(first_bytes, second_bytes)
            for output, data in ((first, first_bytes), (second, second_bytes)):
                with self.subTest(output=output.name):
                    machine, timestamp = pe_header(data)
                    self.assertEqual(machine, 0x8664, "default target must be x86_64 PE")
                    self.assertEqual(timestamp, 0, "COFF TimeDateStamp must be zero")
                    self.assertFalse(output.with_suffix(".pdb").exists())
                    self.assertFalse(output.with_suffix(".lib").exists())


def is_reparse_point(path):
    """True for a symlink or a Windows junction, without following it."""
    try:
        info = os.lstat(str(path))
    except OSError:
        return False
    attributes = getattr(info, "st_file_attributes", 0)
    return os.path.islink(str(path)) or bool(attributes & 0x400)


def current_user_sid():
    """The current user's SID as text, from `whoami /user` (immune to non-ASCII names)."""
    result = subprocess.run(
        ["whoami", "/user", "/fo", "csv", "/nh"], stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, timeout=30)
    fields = result.stdout.decode("ascii", "replace").strip().strip('"').split('","')
    sid = fields[-1].strip('"') if result.returncode == 0 and fields else ""
    return sid if sid.startswith("S-") else None


def restore_access(path):
    """Grant the current user full control on `path`; return the failed steps ([] = ok).

    The provisioner applies a protected, non-inheritable current-user DACL to the private
    cache and propagates it to existing children. A junction made beforehand then ends up
    with an empty DACL and cannot be removed; a reset would not help (nothing is
    inheritable), so the grant is always applied. `/L` acts on the link itself, never on
    its target. If the grant is refused, ownership is taken and the grant repeated.
    Windows only; elsewhere nothing to do.
    """
    if os.name != "nt":
        return []
    steps = []
    try:
        sid = current_user_sid()
        if sid is None:
            return ["whoami /user: no SID"]
        grant = ["icacls", str(path), "/grant:r", "*%s:(F)" % sid, "/L"]
        if subprocess.run(grant, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          timeout=30).returncode == 0:
            return []
        steps.append("icacls /grant:r")
        if subprocess.run(["takeown", "/F", str(path)], stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, timeout=30).returncode != 0:
            steps.append("takeown /F")
        if subprocess.run(grant, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          timeout=30).returncode != 0:
            steps.append("icacls /grant:r (after takeown)")
    except (OSError, subprocess.SubprocessError) as error:
        steps.append("access restore raised %r" % (error,))
    return steps


def remove_reparse_point(path):
    """Remove a junction or symlink itself, never its target. Absent is fine.

    Raises OSError naming the failed access steps if the link cannot be removed.
    """
    if not is_reparse_point(path):
        return
    steps = restore_access(path)
    try:
        os.rmdir(str(path))  # a junction is removed as a directory, not unlinked
    except OSError:
        try:
            os.unlink(str(path))
        except OSError as error:
            raise OSError(
                "cannot remove reparse point %s (failed steps: %s): %s"
                % (path, ", ".join(steps) or "none before removal", error))


def scrub_tree(root):
    """Remove a test tree that may hold junctions or protected objects.

    Junctions go first, as links; read-only attributes are cleared; only then does
    rmtree run. A leftover is a warning, because teardown cannot tell a test's own
    failure from an object the OS refuses to release; each test asserts its own result.
    """
    def walk(directory):
        try:
            entries = list(os.scandir(str(directory)))
        except OSError:
            steps = restore_access(directory)
            if steps:
                warnings.warn("cannot restore access to %s: %s" % (directory, ", ".join(steps)))
            try:
                entries = list(os.scandir(str(directory)))
            except OSError as error:
                warnings.warn("cannot list %s: %s" % (directory, error))
                return
        for entry in entries:
            path = Path(entry.path)
            try:
                if is_reparse_point(path):
                    remove_reparse_point(path)
                elif entry.is_dir(follow_symlinks=False):
                    walk(path)
                else:
                    os.chmod(entry.path, 0o700)
            except OSError as error:
                warnings.warn("scrub step failed for %s: %s" % (path, error))

    root = Path(root)
    if is_reparse_point(root):
        try:
            remove_reparse_point(root)
        except OSError as error:
            warnings.warn(str(error))
    else:
        walk(root)
    shutil.rmtree(str(root), ignore_errors=True)
    if root.exists():
        warnings.warn("test tree left behind: %s" % root)


def sha256(data):
    return hashlib.sha256(data).hexdigest()


class AssetServer:
    def __init__(
        self,
        testcase,
        data=b"",
        redirect=None,
        truncate=False,
        delay=0,
        tls=False,
        hold_requests=0,
        version=None,
    ):
        self.version = version or VERSION
        self.paths = []
        self.requests_ready = threading.Event()
        self.release_requests = threading.Event()
        self._stopped = False
        paths = self.paths

        class Handler(http.server.BaseHTTPRequestHandler):
            # A client that connects and never speaks (or never finishes a TLS
            # handshake) must not pin a handler thread forever.
            timeout = 15

            def do_GET(handler_self):
                paths.append(handler_self.path)
                if hold_requests and len(paths) >= hold_requests:
                    self.requests_ready.set()
                if hold_requests:
                    self.release_requests.wait(timeout=10)
                if delay:
                    time.sleep(delay)
                if redirect is not None:
                    handler_self.send_response(302)
                    handler_self.send_header("Location", redirect)
                    handler_self.end_headers()
                    return
                handler_self.send_response(200)
                handler_self.send_header("Content-Length", str(len(data)))
                handler_self.end_headers()
                payload = data[: max(1, len(data) // 2)] if truncate else data
                try:
                    handler_self.wfile.write(payload)
                    handler_self.wfile.flush()
                except (BrokenPipeError, ConnectionResetError):
                    pass
                if truncate:
                    try:
                        handler_self.connection.shutdown(socket.SHUT_RDWR)
                    except OSError:
                        pass

            def log_message(self, format_, *args):
                pass

        self.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.server.daemon_threads = True
        self.scheme = "http"
        self.host = "127.0.0.1"
        if tls:
            certificate = testcase.case_root / "localhost-cert.pem"
            private_key = testcase.case_root / "localhost-key.pem"
            certificate.write_text(TEST_CERTIFICATE, encoding="ascii")
            private_key.write_text(TEST_PRIVATE_KEY, encoding="ascii")
            context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            context.load_cert_chain(str(certificate), str(private_key))
            # The handshake runs lazily in the handler thread: an eager handshake in
            # accept() would stall serve_forever, and with it shutdown(), whenever a
            # client opens a connection and never completes it.
            self.server.socket = context.wrap_socket(
                self.server.socket, server_side=True, do_handshake_on_connect=False
            )
            self.scheme = "https"
            self.host = "127.0.0.1"
        self.thread = threading.Thread(target=self.server.serve_forever)
        self.thread.daemon = True
        self.thread.start()
        testcase.addCleanup(self.stop)

    @property
    def base_url(self):
        return "%s://%s:%d/%s" % (
            self.scheme,
            self.host,
            self.server.server_port,
            self.version,
        )

    def stop(self):
        if self._stopped:
            return
        self._stopped = True
        self.release_requests.set()
        # shutdown() blocks until serve_forever returns; bound it so cleanup of a
        # wedged server cannot hang the whole run.
        stopper = threading.Thread(target=self.server.shutdown)
        stopper.daemon = True
        stopper.start()
        stopper.join(timeout=10)
        self.thread.join(timeout=5)
        self.server.server_close()


class TokenOwnerControl:
    def __init__(self):
        import ctypes
        from ctypes import wintypes

        class SidAndAttributes(ctypes.Structure):
            _fields_ = [("Sid", ctypes.c_void_p), ("Attributes", wintypes.DWORD)]

        class TokenGroups(ctypes.Structure):
            _fields_ = [
                ("GroupCount", wintypes.DWORD),
                ("Groups", SidAndAttributes * 1),
            ]

        class TokenOwner(ctypes.Structure):
            _fields_ = [("Owner", ctypes.c_void_p)]

        self.ctypes = ctypes
        self.wintypes = wintypes
        self.SidAndAttributes = SidAndAttributes
        self.TokenGroups = TokenGroups
        self.TokenOwner = TokenOwner
        self.advapi32 = ctypes.WinDLL("advapi32", use_last_error=True)
        self.kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
        self.token = ctypes.c_void_p()
        self.expected = None
        self.closed = False

        self.kernel32.GetCurrentProcess.argtypes = []
        self.kernel32.GetCurrentProcess.restype = ctypes.c_void_p
        self.kernel32.CloseHandle.argtypes = [ctypes.c_void_p]
        self.kernel32.CloseHandle.restype = wintypes.BOOL
        self.advapi32.OpenProcessToken.argtypes = [
            ctypes.c_void_p,
            wintypes.DWORD,
            ctypes.POINTER(ctypes.c_void_p),
        ]
        self.advapi32.OpenProcessToken.restype = wintypes.BOOL
        self.advapi32.GetTokenInformation.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_void_p,
            wintypes.DWORD,
            ctypes.POINTER(wintypes.DWORD),
        ]
        self.advapi32.GetTokenInformation.restype = wintypes.BOOL
        self.advapi32.SetTokenInformation.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_void_p,
            wintypes.DWORD,
        ]
        self.advapi32.SetTokenInformation.restype = wintypes.BOOL
        self.advapi32.GetLengthSid.argtypes = [ctypes.c_void_p]
        self.advapi32.GetLengthSid.restype = wintypes.DWORD

        if not self.advapi32.OpenProcessToken(
            self.kernel32.GetCurrentProcess(),
            0x0008 | 0x0080,
            ctypes.byref(self.token),
        ):
            raise ctypes.WinError(ctypes.get_last_error())
        self.original = self._query_sid(4)
        self.user = self._query_sid(1)

    def _query_buffer(self, information_class):
        needed = self.wintypes.DWORD()
        self.advapi32.GetTokenInformation(
            self.token, information_class, None, 0, self.ctypes.byref(needed)
        )
        if needed.value == 0:
            raise self.ctypes.WinError(self.ctypes.get_last_error())
        buffer = self.ctypes.create_string_buffer(needed.value)
        if not self.advapi32.GetTokenInformation(
            self.token,
            information_class,
            buffer,
            needed.value,
            self.ctypes.byref(needed),
        ):
            raise self.ctypes.WinError(self.ctypes.get_last_error())
        return buffer

    def _sid_bytes(self, sid):
        length = self.advapi32.GetLengthSid(sid)
        if length == 0:
            raise self.ctypes.WinError(self.ctypes.get_last_error())
        return self.ctypes.string_at(sid, length)

    def _query_sid(self, information_class):
        buffer = self._query_buffer(information_class)
        sid = self.ctypes.cast(
            buffer, self.ctypes.POINTER(self.TokenOwner)
        ).contents.Owner
        return self._sid_bytes(sid)

    def _owner_groups(self):
        buffer = self._query_buffer(2)
        groups = self.ctypes.cast(
            buffer, self.ctypes.POINTER(self.TokenGroups)
        ).contents
        first = self.ctypes.addressof(groups) + self.TokenGroups.Groups.offset
        entries = self.ctypes.cast(
            first, self.ctypes.POINTER(self.SidAndAttributes)
        )
        return [
            self._sid_bytes(entries[index].Sid)
            for index in range(groups.GroupCount)
            if entries[index].Attributes & 0x00000008
        ]

    def set_owner(self, sid_bytes):
        sid = self.ctypes.create_string_buffer(sid_bytes)
        owner = self.TokenOwner(self.ctypes.cast(sid, self.ctypes.c_void_p))
        return bool(
            self.advapi32.SetTokenInformation(
                self.token,
                4,
                self.ctypes.byref(owner),
                self.ctypes.sizeof(owner),
            )
        )

    def select_distinct_owner(self):
        if self.original != self.user:
            self.expected = self.original
            return True
        for candidate in self._owner_groups():
            if candidate != self.user and self.set_owner(candidate):
                self.expected = candidate
                return True
        return False

    def apply_expected(self):
        if self.expected is None or not self.set_owner(self.expected):
            raise self.ctypes.WinError(self.ctypes.get_last_error())

    @property
    def expected_hex(self):
        return self.expected.hex()

    def close(self):
        if self.closed:
            return
        self.closed = True
        restored = self.set_owner(self.original)
        error = self.ctypes.get_last_error() if not restored else 0
        if self.token:
            self.kernel32.CloseHandle(self.token)
            self.token = None
        if not restored:
            raise self.ctypes.WinError(error)


class TrustedTestRoot:
    """Trust the test CA in the LocalMachine ROOT store, non-interactively.

    The CurrentUser ROOT store is deliberately not used: Windows confirms an addition
    there with a modal security dialog that a headless runner can never answer, which
    hangs the test forever. LocalMachine needs an elevated process (the CI runner is);
    without one, unavailable() names the reason and the TLS-dependent tests skip.
    """

    CERT_STORE_PROV_SYSTEM_W = 10
    CERT_SYSTEM_STORE_LOCAL_MACHINE = 0x00020000

    def __init__(self):
        self.store = None
        self.context = None

    @classmethod
    def _open_store(cls, crypt32):
        import ctypes

        crypt32.CertOpenStore.argtypes = [
            ctypes.c_void_p, ctypes.c_uint, ctypes.c_void_p, ctypes.c_uint, ctypes.c_wchar_p
        ]
        crypt32.CertOpenStore.restype = ctypes.c_void_p
        return crypt32.CertOpenStore(
            cls.CERT_STORE_PROV_SYSTEM_W, 0, None, cls.CERT_SYSTEM_STORE_LOCAL_MACHINE, "ROOT"
        )

    @classmethod
    def unavailable(cls):
        """Return None when the test certificate may be trusted, else the skip reason.

        Trusting is machine-wide and so opt-in: it happens only on GitHub Actions or with
        BRIEFING_BOOTSTRAP_TRUST_TEST_ROOT=1, and needs a writable LocalMachine ROOT store.
        """
        if os.name != "nt":
            return "the Windows certificate store exists only on Windows"
        if (os.environ.get("GITHUB_ACTIONS") != "true"
                and os.environ.get("BRIEFING_BOOTSTRAP_TRUST_TEST_ROOT") != "1"):
            return (
                "skipped: trusting the loopback test certificate in the machine-wide "
                "LocalMachine ROOT store is opt-in; set BRIEFING_BOOTSTRAP_TRUST_TEST_ROOT=1 "
                "(it is set automatically on GitHub Actions)"
            )
        import ctypes

        crypt32 = ctypes.WinDLL("crypt32", use_last_error=True)
        crypt32.CertCloseStore.argtypes = [ctypes.c_void_p, ctypes.c_uint]
        crypt32.CertCloseStore.restype = ctypes.c_int
        store = cls._open_store(crypt32)
        if not store:
            error = ctypes.get_last_error()
            return (
                "skipped: the LocalMachine ROOT certificate store is not writable "
                "(error %d; the process is not elevated), so the test certificate cannot be "
                "trusted non-interactively; the CurrentUser store is never used because "
                "it raises a modal dialog" % error
            )
        crypt32.CertCloseStore(store, 0)
        return None

    def __enter__(self):
        import ctypes

        crypt32 = ctypes.WinDLL("crypt32", use_last_error=True)
        crypt32.CertAddEncodedCertificateToStore.argtypes = [
            ctypes.c_void_p,
            ctypes.c_uint,
            ctypes.c_void_p,
            ctypes.c_uint,
            ctypes.c_uint,
            ctypes.POINTER(ctypes.c_void_p),
        ]
        crypt32.CertAddEncodedCertificateToStore.restype = ctypes.c_int
        crypt32.CertDeleteCertificateFromStore.argtypes = [ctypes.c_void_p]
        crypt32.CertDeleteCertificateFromStore.restype = ctypes.c_int
        crypt32.CertCloseStore.argtypes = [ctypes.c_void_p, ctypes.c_uint]
        crypt32.CertCloseStore.restype = ctypes.c_int
        self._crypt32 = crypt32
        self.store = self._open_store(crypt32)
        if not self.store:
            raise ctypes.WinError(ctypes.get_last_error())
        der = ssl.PEM_cert_to_DER_cert(TEST_CERTIFICATE)
        self._encoded = ctypes.create_string_buffer(der)
        context = ctypes.c_void_p()
        if not crypt32.CertAddEncodedCertificateToStore(
            self.store,
            1,
            self._encoded,
            len(der),
            4,
            ctypes.byref(context),
        ):
            error = ctypes.get_last_error()
            crypt32.CertCloseStore(self.store, 0)
            self.store = None
            raise ctypes.WinError(error)
        self.context = context
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        if self.context:
            self._crypt32.CertDeleteCertificateFromStore(self.context)
            self.context = None
        if self.store:
            self._crypt32.CertCloseStore(self.store, 0)
            self.store = None


def inspect_security(path):
    import ctypes
    from ctypes import wintypes

    class AclSizeInformation(ctypes.Structure):
        _fields_ = [
            ("AceCount", wintypes.DWORD),
            ("AclBytesInUse", wintypes.DWORD),
            ("AclBytesFree", wintypes.DWORD),
        ]

    class AceHeader(ctypes.Structure):
        _fields_ = [
            ("AceType", ctypes.c_ubyte),
            ("AceFlags", ctypes.c_ubyte),
            ("AceSize", wintypes.WORD),
        ]

    class SidAndAttributes(ctypes.Structure):
        _fields_ = [("Sid", ctypes.c_void_p), ("Attributes", wintypes.DWORD)]

    class TokenUser(ctypes.Structure):
        _fields_ = [("User", SidAndAttributes)]

    advapi32 = ctypes.WinDLL("advapi32", use_last_error=True)
    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    advapi32.GetNamedSecurityInfoW.argtypes = [
        ctypes.c_wchar_p,
        ctypes.c_uint,
        ctypes.c_uint,
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_void_p),
        ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_void_p),
    ]
    advapi32.GetNamedSecurityInfoW.restype = ctypes.c_uint
    advapi32.GetSecurityDescriptorControl.argtypes = [
        ctypes.c_void_p,
        ctypes.POINTER(wintypes.WORD),
        ctypes.POINTER(wintypes.DWORD),
    ]
    advapi32.GetSecurityDescriptorControl.restype = wintypes.BOOL
    advapi32.GetAclInformation.argtypes = [
        ctypes.c_void_p,
        ctypes.c_void_p,
        wintypes.DWORD,
        ctypes.c_int,
    ]
    advapi32.GetAclInformation.restype = wintypes.BOOL
    advapi32.GetAce.argtypes = [
        ctypes.c_void_p,
        wintypes.DWORD,
        ctypes.POINTER(ctypes.c_void_p),
    ]
    advapi32.GetAce.restype = wintypes.BOOL
    advapi32.OpenProcessToken.argtypes = [
        ctypes.c_void_p,
        wintypes.DWORD,
        ctypes.POINTER(ctypes.c_void_p),
    ]
    advapi32.OpenProcessToken.restype = wintypes.BOOL
    advapi32.GetTokenInformation.argtypes = [
        ctypes.c_void_p,
        ctypes.c_int,
        ctypes.c_void_p,
        wintypes.DWORD,
        ctypes.POINTER(wintypes.DWORD),
    ]
    advapi32.GetTokenInformation.restype = wintypes.BOOL
    advapi32.EqualSid.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
    advapi32.EqualSid.restype = wintypes.BOOL
    kernel32.GetCurrentProcess.argtypes = []
    kernel32.GetCurrentProcess.restype = ctypes.c_void_p
    kernel32.CloseHandle.argtypes = [ctypes.c_void_p]
    kernel32.CloseHandle.restype = wintypes.BOOL
    kernel32.LocalFree.argtypes = [ctypes.c_void_p]
    kernel32.LocalFree.restype = ctypes.c_void_p
    owner = ctypes.c_void_p()
    dacl = ctypes.c_void_p()
    descriptor = ctypes.c_void_p()
    token = ctypes.c_void_p()
    status = advapi32.GetNamedSecurityInfoW(
        str(path),
        1,
        1 | 4,
        ctypes.byref(owner),
        None,
        ctypes.byref(dacl),
        None,
        ctypes.byref(descriptor),
    )
    if status != 0:
        raise OSError(status, "GetNamedSecurityInfoW failed for %s" % path)
    try:
        control = wintypes.WORD()
        revision = wintypes.DWORD()
        if not advapi32.GetSecurityDescriptorControl(
            descriptor, ctypes.byref(control), ctypes.byref(revision)
        ):
            raise ctypes.WinError(ctypes.get_last_error())
        information = AclSizeInformation()
        if not advapi32.GetAclInformation(
            dacl, ctypes.byref(information), ctypes.sizeof(information), 2
        ):
            raise ctypes.WinError(ctypes.get_last_error())
        if not advapi32.OpenProcessToken(
            kernel32.GetCurrentProcess(), 0x0008, ctypes.byref(token)
        ):
            raise ctypes.WinError(ctypes.get_last_error())
        needed = wintypes.DWORD()
        advapi32.GetTokenInformation(token, 1, None, 0, ctypes.byref(needed))
        token_buffer = ctypes.create_string_buffer(needed.value)
        if not advapi32.GetTokenInformation(
            token, 1, token_buffer, needed, ctypes.byref(needed)
        ):
            raise ctypes.WinError(ctypes.get_last_error())
        current_sid = ctypes.cast(token_buffer, ctypes.POINTER(TokenUser)).contents.User.Sid
        owner_is_current = bool(advapi32.EqualSid(current_sid, owner))
        aces = []
        for index in range(information.AceCount):
            ace = ctypes.c_void_p()
            if not advapi32.GetAce(dacl, index, ctypes.byref(ace)):
                raise ctypes.WinError(ctypes.get_last_error())
            header = ctypes.cast(ace, ctypes.POINTER(AceHeader)).contents
            same_user = False
            if header.AceType == 0:
                same_user = bool(advapi32.EqualSid(current_sid, ace.value + 8))
            aces.append((header.AceType, header.AceFlags, same_user))
        return owner_is_current, bool(control.value & 0x1000), aces
    finally:
        if token:
            kernel32.CloseHandle(token)
        kernel32.LocalFree(descriptor)


def bootstrap_plan(explicit, ziglang_available):
    """Decide where the process tests get their bootstrap.

    Returns ("skip", reason), ("copy", path) or ("build", None). Without an explicit
    bootstrap the tests build one, which needs ziglang; the native `perl-native` Windows
    job of ci.yml has none, and the `bootstrap-windows` job owns the proof there. An
    explicit bootstrap is never skipped: if it cannot be used, that is a failure.
    """
    if explicit is None:
        if not ziglang_available:
            return (
                "skip",
                "ziglang is not installed; the bootstrap process contract is proved by the "
                "bootstrap-windows job in .github/workflows/ci.yml",
            )
        return ("build", None)
    if not explicit.is_absolute():
        raise AssertionError("the explicit bootstrap path must be absolute")
    if not explicit.is_file():
        raise AssertionError("the explicit bootstrap does not exist: %s" % explicit)
    return ("copy", explicit)


class BootstrapPlanTests(unittest.TestCase):
    def test_missing_ziglang_without_explicit_bootstrap_skips_naming_the_owning_job(self):
        action, reason = bootstrap_plan(None, False)
        self.assertEqual(action, "skip")
        self.assertIn("bootstrap-windows", reason)
        self.assertIn(".github/workflows/ci.yml", reason)

    def test_ziglang_without_explicit_bootstrap_builds(self):
        self.assertEqual(bootstrap_plan(None, True), ("build", None))

    def test_explicit_bootstrap_is_never_skipped_for_missing_ziglang(self):
        with tempfile.TemporaryDirectory() as temp:
            explicit = Path(temp).resolve() / "briefing-bootstrap.exe"
            explicit.write_bytes(b"x")
            self.assertEqual(bootstrap_plan(explicit, False), ("copy", explicit))

    def test_unusable_explicit_bootstrap_fails_loudly(self):
        with tempfile.TemporaryDirectory() as temp:
            missing = Path(temp).resolve() / "missing.exe"
            for ziglang in (False, True):
                with self.subTest(case="missing", ziglang=ziglang):
                    with self.assertRaises(AssertionError):
                        bootstrap_plan(missing, ziglang)
                with self.subTest(case="relative", ziglang=ziglang):
                    with self.assertRaises(AssertionError):
                        bootstrap_plan(Path("relative.exe"), ziglang)


class BootstrapSourceTests(unittest.TestCase):
    def test_release_version_is_not_compiled_into_the_bootstrap(self):
        # The version comes from the pin manifest, like the POSIX starter's read_pins.
        source = SOURCE.read_text(encoding="utf-8")
        self.assertIn("releases/download/", source)
        self.assertNotRegex(source, r"download/0\.001")
        self.assertNotRegex(source, r"briefing-0\.001")


@unittest.skipUnless(
    IS_WINDOWS,
    "requires native Windows; a Linux cross-build is not process-contract evidence",
)
class BootstrapProcessTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = Path(tempfile.mkdtemp(prefix="briefing bootstrap native-"))
        cls.addClassCleanup(scrub_tree, cls.root)
        cls.plugin = cls.root / "Plugin-ä-世界"
        (cls.plugin / "bin").mkdir(parents=True)
        for name in ("hooks", "lib", "script"):
            shutil.copytree(str(REPO_ROOT / name), str(cls.plugin / name))
        cls.pin_file = cls.plugin / "bin" / "briefing-binaries.sha256"
        cls.bootstrap = cls.plugin / "bin" / "briefing-bootstrap.exe"

        action, detail = bootstrap_plan(
            EXPLICIT_BOOTSTRAP, importlib.util.find_spec("ziglang") is not None
        )
        if action == "skip":
            raise unittest.SkipTest(detail)
        if action == "build":
            build_executable(cls.bootstrap)
        else:
            shutil.copyfile(detail, cls.bootstrap)

        cls.fixture = cls.root / "briefing-bootstrap-stub.exe"
        build_executable(cls.fixture, STUB_SOURCE)
        cls.cwd = cls.root / "Arbeitsbereich-ö-東京"
        cls.cwd.mkdir()

    def setUp(self):
        # Diagnostic watchdog: a test stuck beyond every bound below dumps all thread
        # stacks to stderr, so the log names the hang instead of ending silently.
        faulthandler.dump_traceback_later(240, exit=False)
        self.addCleanup(faulthandler.cancel_dump_traceback_later)
        try:
            self.pin_file.unlink()
        except OSError:
            pass
        self.case_root = self.root / self._testMethodName
        self.case_root.mkdir()
        self.config = self.case_root / "Konfiguration-ä-世界"
        # self.cache is the version directory; the binary and the fixture child live one level
        # deeper, in the pin directory <V>\\<16 hex>.
        self.cache = self.config / "briefing" / "bin" / VERSION
        (self.cache / FIXTURE_PIN).mkdir(parents=True)
        self.child = self.cache / FIXTURE_PIN / "briefing-bootstrap-stub.exe"
        shutil.copyfile(self.fixture, self.child)
        self.marker = self.case_root / "native-child-started"
        self.empty_path = self.case_root / "empty-path"
        self.empty_path.mkdir()

    def use_production_config(self, suffix=""):
        name = "Produktionskonfiguration" + ("-" + suffix if suffix else "")
        self.config = self.case_root / name
        self.cache = self.config / "briefing" / "bin" / VERSION
        self.marker = self.case_root / ("production-child-started" + suffix)

    def environment(self, mode, **values):
        env = {
            name: value
            for name, value in os.environ.items()
            if not name.startswith("BRIEFING_")
        }
        for name in ("CLAUDE_CONFIG_DIR", "PAR_GLOBAL_TEMP"):
            env.pop(name, None)
        env.update(
            {
                "BRIEFING_BOOTSTRAP_TESTING": "1",
                "BRIEFING_BOOTSTRAP_TEST_CHILD": str(self.child.resolve()),
                "BRIEFING_BOOTSTRAP_STUB_MODE": mode,
                "CLAUDE_CONFIG_DIR": str(self.config.resolve()),
            }
        )
        env.update(values)
        return env

    def bootstrap_environment(
        self,
        testing=False,
        base_url=None,
        max_bytes=None,
        path=None,
        mode="exit",
        exit_status="0",
        marker=None,
        **values
    ):
        env = {
            name: value
            for name, value in os.environ.items()
            if not name.startswith("BRIEFING_")
        }
        env.pop("PAR_GLOBAL_TEMP", None)
        env["CLAUDE_CONFIG_DIR"] = str(self.config.absolute())
        env["PATH"] = str(path or self.empty_path)
        env["BRIEFING_BOOTSTRAP_STUB_MODE"] = mode
        env["BRIEFING_BOOTSTRAP_STUB_EXIT"] = exit_status
        env["BRIEFING_BOOTSTRAP_STUB_MARKER"] = str((marker or self.marker).resolve())
        if testing:
            env["BRIEFING_BOOTSTRAP_TESTING"] = "1"
        if base_url is not None:
            env["BRIEFING_BINARY_BASE_URL"] = base_url
        if max_bytes is not None:
            env["BRIEFING_BOOTSTRAP_TEST_MAX_BYTES"] = str(max_bytes)
        env.update(values)
        return env

    def canonical_manifest(self, data=None, digest=None, version=VERSION):
        if digest is None:
            digest = sha256(data if data is not None else self.fixture.read_bytes())
        assets = tuple(asset.replace(VERSION, version, 1) for asset in ASSETS)
        return "".join("%s  %s\n" % (digest, asset) for asset in assets).encode("utf-8")

    def write_manifest(self, contents):
        self.pin_file.write_bytes(contents)

    def cached_path(self, data=None, digest=None, version=VERSION):
        if digest is None:
            digest = sha256(data if data is not None else self.fixture.read_bytes())
        return self.config / "briefing" / "bin" / version / digest[:16] / "briefing.exe"

    def put_cached_fixture(self, data=None, digest=None):
        payload = data if data is not None else self.fixture.read_bytes()
        cached = self.cached_path(data=payload, digest=digest)
        cached.parent.mkdir(parents=True, exist_ok=True)
        cached.write_bytes(payload)
        return cached

    def start_bootstrap(self, args=(), input_bytes=b"", cwd=None, env=None):
        return subprocess.Popen(
            [str(self.bootstrap), *args],
            cwd=str(cwd or self.cwd),
            env=env,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

    def assert_safe_hook_warning(self, result):
        detail = describe_output(result.stdout, result.stderr, result.returncode)
        self.assertEqual(result.returncode, 0, detail)
        self.assertEqual(result.stderr, b"", detail)
        self.assertEqual(len(result.stdout.splitlines()), 1, detail)
        output = json.loads(result.stdout.decode("utf-8"))
        self.assertEqual(set(output), {"systemMessage"})
        self.assertRegex(
            output["systemMessage"],
            r"^briefing: no binary \(.+\) and no fallback \(.+\)\.$",
        )

    def assert_non_hook_failure(self, result):
        detail = describe_output(result.stdout, result.stderr, result.returncode)
        self.assertEqual(result.returncode, 1, detail)
        self.assertEqual(result.stdout, b"", detail)
        self.assertEqual(len(result.stderr.splitlines()), 1, detail)
        self.assertRegex(
            result.stderr.decode("utf-8").rstrip("\r\n"),
            r"^briefing: no binary \(.+\) and no fallback \(.+\)\.$",
        )

    def assert_no_trusted_cache_entry(self, digest):
        self.assertFalse(self.cached_path(digest=digest).exists())
        binary_root = self.config / "briefing" / "bin"
        if binary_root.exists():
            leftovers = [
                path for path in binary_root.rglob("*")
                if path.is_file() and not path.name.endswith(".failed-at")
            ]
            self.assertEqual(leftovers, [], "untrusted cache files remain: %r" % leftovers)

    def invocation_records(self, log):
        fields = log.read_bytes().split(b"\0")
        self.assertEqual(fields[-1], b"", "invocation log must end at a boundary")
        records = []
        record = []
        for field in fields[:-1]:
            if field == b"":
                values = [value.decode("utf-8") for value in record]
                records.append(values[:1] + canonical_args(values[1:]))
                record = []
            else:
                record.append(field)
        self.assertEqual(record, [])
        return records

    def create_junction(self, link, target):
        command = os.environ.get("COMSPEC", r"C:\Windows\System32\cmd.exe")
        result = run_bounded(
            [command, "/d", "/c", "mklink", "/J", str(link), str(target)],
            20, label="mklink /J")
        self.assertEqual(
            result.returncode,
            0,
            "cannot create native reparse-point fixture: %s"
            % result.stderr.decode("utf-8", "replace"),
        )

    def attempt_parent_replacement(self, source, displaced, foreign_target):
        try:
            source.rename(displaced)
        except OSError as error:
            if getattr(error, "winerror", None) in (32, 33):
                return "blocked-by-sharing-lock"
            raise
        self.create_junction(source, foreign_target)
        return "replaced-with-junction"

    def wait_for_path(self, path, timeout=10):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if path.exists():
                return True
            time.sleep(0.02)
        return path.exists()

    def assert_current_user_security(
        self, path, require_protected=True, require_inheritance=False
    ):
        owner_is_current, protected, aces = inspect_security(path)
        self.assertTrue(owner_is_current, "owner is not the current TokenUser: %s" % path)
        if require_protected:
            self.assertTrue(protected, "DACL inherits broader parent entries: %s" % path)
        self.assertTrue(aces, "current-user-only object has an empty DACL: %s" % path)
        self.assertTrue(
            all(ace_type == 0 and same_user for ace_type, flags, same_user in aces),
            "DACL contains a non-current-user or non-allow ACE for %s: %r"
            % (path, aces),
        )
        if require_inheritance:
            self.assertTrue(
                any((flags & 0x03) == 0x03 for ace_type, flags, same_user in aces),
                "PAR DACL has no current-user ACE inheritable by files and directories: %r"
                % (aces,),
            )

    def foreign_fixture_bytes(self):
        data = self.fixture.read_bytes()
        self.assertEqual(
            data.count(b"started\n"),
            1,
            "fixture marker literal is not uniquely patchable",
        )
        return data.replace(b"started\n", b"foreign\n", 1)

    def assert_verified_bytes_or_safe_hook_fallback(self, result, marker):
        detail = describe_output(result.stdout, result.stderr, result.returncode)
        self.assertEqual(result.returncode, 0, detail)
        self.assertEqual(result.stderr, b"", detail)
        if marker.exists():
            self.assertEqual(
                marker.read_bytes(),
                b"started\n",
                "foreign executable bytes reached CreateProcessW",
            )
        if result.stdout:
            self.assert_safe_hook_warning(result)
        else:
            self.assertTrue(marker.exists(), "neither verified bytes nor safe fallback ran")

    def provision_par_tree(self, suffix):
        self.use_production_config(suffix)
        data = self.fixture.read_bytes()
        digest = sha256(data)
        self.write_manifest(self.canonical_manifest(data=data))
        server = AssetServer(self, data=data)
        result = self.run_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True,
                base_url=server.base_url,
                marker=self.marker,
                mode="par-tree",
            ),
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode("utf-8", "replace"))
        self.assertEqual(result.stdout, b"")
        self.assertEqual(result.stderr, b"")
        cached = self.cached_path(digest=digest)
        par = cached.parent / "par"
        child_directory = par / "fixture-child-directory"
        child_file = child_directory / "fixture-child-file"
        self.assertTrue(child_file.is_file(), "fixture did not create the PAR child tree")
        return cached, par, child_directory, child_file

    def run_bootstrap(self, args=(), input_bytes=b"", cwd=None, env=None):
        return run_bounded(
            [str(self.bootstrap), *args],
            30,
            label="briefing-bootstrap " + " ".join(args),
            input_bytes=input_bytes,
            cwd=str(cwd or self.cwd),
            env=env or self.environment("exit", BRIEFING_BOOTSTRAP_STUB_EXIT="0"),
        )

    def assert_rejected_before_child_start(self, result, marker):
        detail = describe_output(result.stdout, result.stderr, result.returncode)
        self.assertEqual(result.returncode, 1, detail)
        self.assertEqual(result.stdout, b"", detail)
        self.assertTrue(
            result.stderr.startswith(b"briefing-bootstrap:"),
            "rejection must be a graceful bootstrap error, not a process crash: "
            + detail,
        )
        self.assertFalse(marker.exists(), "rejected input must not start the child")

    def test_cached_child_receives_unicode_argv_and_cwd(self):
        arguments = [
            "plain",
            "Grüße-世界",
            "",
            'quote"inside',
            'slashes\\before\\"quote',
            "trailing\\",
        ]
        environment_value = "Umgebung-ß-大阪"
        result = self.run_bootstrap(
            arguments,
            env=self.environment(
                "argv", BRIEFING_BOOTSTRAP_STUB_VALUE=environment_value
            ),
        )

        self.assertEqual(result.returncode, 0, result.stderr.decode("utf-8", "replace"))
        self.assertEqual(result.stderr, b"")
        fields = result.stdout.split(b"\0")
        self.assertEqual(fields[-1], b"", "fixture output must end at a field boundary")
        decoded = [field.decode("utf-8") for field in fields[:-1]]
        self.assertEqual(len(decoded), len(arguments) + 2)
        self.assertEqual(
            canonical_path(decoded[0]),
            canonical_path(str(self.cwd.resolve())),
        )
        self.assertEqual(decoded[1], environment_value)
        self.assertEqual(decoded[2:], arguments)

    def test_cached_child_round_trips_utf8_stdin_stdout_stderr(self):
        payload = '{"message":"Grüße aus 東京","ok":true}\n'.encode("utf-8")
        result = self.run_bootstrap(
            input_bytes=payload,
            env=self.environment("stdio"),
        )

        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, payload)
        self.assertEqual(result.stderr, payload)

    def test_returns_exact_child_exit_code(self):
        result = self.run_bootstrap(
            env=self.environment("exit", BRIEFING_BOOTSTRAP_STUB_EXIT="37")
        )

        self.assertEqual(result.returncode, 37)
        self.assertEqual(result.stdout, b"")
        self.assertEqual(result.stderr, b"")

    def test_par_global_temp_is_versioned_under_private_cache(self):
        inherited = str((self.root / "caller-controlled-par").resolve())
        env = self.environment("par", PAR_GLOBAL_TEMP=inherited)
        first = self.run_bootstrap(env=env)
        second = self.run_bootstrap(env=env)

        self.assertEqual(first.returncode, 0, first.stderr.decode("utf-8", "replace"))
        self.assertEqual(second.returncode, 0, second.stderr.decode("utf-8", "replace"))
        self.assertEqual(first.stderr, b"")
        self.assertEqual(second.stderr, b"")
        self.assertEqual(first.stdout, second.stdout, "PAR path must be stable")
        par = Path(first.stdout.decode("utf-8"))
        expected = self.child.resolve().parent / "par"
        self.assertEqual(
            canonical_path(str(par)),
            canonical_path(str(expected)),
        )
        relative = Path(canonical_path(par)).relative_to(
            Path(canonical_path(self.config.resolve())))
        self.assertEqual(relative.parts[:2], ("briefing", "bin"))
        self.assertRegex(relative.parts[2], re.compile(r"^[0-9][A-Za-z0-9._+-]*$"))
        self.assertEqual(relative.parts[2], VERSION)
        self.assertEqual(relative.parts[3:], (FIXTURE_PIN, "par"))

    def short_ascii_config(self):
        """A short ASCII configuration root outside %TEMP%.

        %TEMP% is itself an 8.3 alias on CI runners, so a root below it would hand the child an
        alias for reasons unrelated to the cache layout. The system drive root or RUNNER_TEMP
        keeps the whole cache path plain, ASCII and far below MAX_PATH.
        """
        base = os.environ.get("RUNNER_TEMP") or (os.environ.get("SystemDrive", "C:") + "\\")
        try:
            root = Path(tempfile.mkdtemp(prefix="bc", dir=base))
        except OSError as error:
            self.skipTest("no writable short ASCII root (%s): %s" % (base, error))
        self.addCleanup(scrub_tree, root)
        if "~" in str(root) or not str(root).isascii() or len(str(root)) > 40:
            self.skipTest("the short ASCII root is not short and plain: %s" % root)
        return root

    def provision_under_short_config(self, label):
        """Provision the stub into a short ASCII config; return (expected binary path, digest, child invocation records)."""
        self.config = self.short_ascii_config()
        self.marker = self.case_root / (label + "-child-started")
        data = self.fixture.read_bytes()
        digest = sha256(data)
        self.write_manifest(self.canonical_manifest(data=data))
        server = AssetServer(self, data=data)
        log = self.case_root / (label + "-invocations.bin")
        result = self.run_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True,
                base_url=server.base_url,
                marker=self.marker,
                mode="record",
                BRIEFING_BOOTSTRAP_STUB_LOG=str(log.absolute()),
            ),
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode("utf-8", "replace"))
        self.assertTrue(self.marker.exists(), "the provisioned stub did not run")
        # Exactly this spelling, character for character: <config>\briefing\bin\<V>\<pin>\
        # briefing.exe. The drive letter's case is the one spelling the bootstrap may normalize.
        expected = "%s\\briefing\\bin\\%s\\%s\\briefing.exe" % (
            self.config, VERSION, digest[:16])
        return expected, digest, self.invocation_records(log)

    def assert_plain_path(self, expected, actual):
        self.assertNotIn("~", actual, "the child got an 8.3 alias: " + actual)
        self.assertEqual(actual[1:], expected[1:], "not the plain long cache path")
        self.assertEqual(actual[:1].lower(), expected[:1].lower())

    def assert_provisioning_records(self, expected, records):
        """Provisioning starts exactly two children, both in the pin directory.

        First the `--version` warm-up of the temporary download (it inherits the record mode
        and the log), then the real run. The warm-up's program name is the longest one and so
        sets the interpreter reserve; it must be plain too.
        """
        self.assertEqual(len(records), 2, records)
        pin_directory = expected[: -len("briefing.exe")]
        warm_up, real = records
        self.assertEqual(warm_up[1:], ["--version"])
        name = warm_up[0][len(pin_directory):]
        self.assertNotIn("~", warm_up[0], "the warm-up got an 8.3 alias: " + warm_up[0])
        self.assertEqual(warm_up[0][1:len(pin_directory)], pin_directory[1:],
                         "the warm-up is not inside the plain pin directory")
        self.assertEqual(warm_up[0][:1].lower(), pin_directory[:1].lower())
        self.assertRegex(
            name,
            r"^\.briefing-%s-windows-x86_64\.exe\.[0-9]+\.[0-9]+\.[0-9]+\.tmp$"
            % re.escape(VERSION),
        )
        self.assertEqual(real[1:], ["hook", "session-start"])
        self.assert_plain_path(expected, real[0])

    def assert_hit_records(self, expected, records):
        """A cache hit starts the binary once and runs no warm-up."""
        self.assertEqual(len(records), 1, records)
        self.assertEqual(records[0][1:], ["hook", "subagent-start"])
        self.assert_plain_path(expected, records[0][0])

    def test_child_gets_the_plain_long_path_under_a_short_ascii_config(self):
        expected, digest, records = self.provision_under_short_config("short-ascii")
        self.assert_provisioning_records(expected, records)

        # A cache hit hands over the same plain binary path and a PAR directory beside it.
        hit_log = self.case_root / "short-ascii-hit-invocations.bin"
        hit = self.run_bootstrap(
            ("hook", "subagent-start"),
            env=self.bootstrap_environment(
                marker=self.marker,
                mode="record",
                BRIEFING_BOOTSTRAP_STUB_LOG=str(hit_log.absolute()),
            ),
        )
        self.assertEqual(hit.returncode, 0, hit.stderr.decode("utf-8", "replace"))
        self.assert_hit_records(expected, self.invocation_records(hit_log))

        par_hit = self.run_bootstrap(
            ("hook", "subagent-start"),
            env=self.bootstrap_environment(marker=self.marker, mode="par"),
        )
        self.assertEqual(par_hit.returncode, 0, par_hit.stderr.decode("utf-8", "replace"))
        par = par_hit.stdout.decode("utf-8")
        expected_par = expected[: -len("briefing.exe")] + "par"
        self.assertNotIn("~", par)
        self.assertEqual(par[1:], expected_par[1:], "PAR_GLOBAL_TEMP is not the plain path")
        self.assertEqual(par[:1].lower(), expected_par[:1].lower())

    @unittest.skipUnless(
        os.name == "nt" and __import__("ctypes").windll.shell32.IsUserAnAdmin(),
        "needs an elevated token: fsutil 8dot3name strip is admin-only (the optional "
        "proof that the cache starts without any 8.3 alias)",
    )
    def test_cache_hit_starts_after_the_8dot3_names_are_stripped(self):
        expected, digest, records = self.provision_under_short_config("stripped")
        self.assert_provisioning_records(expected, records)
        import ctypes

        def short_form(path):
            buffer = ctypes.create_unicode_buffer(32768)
            ctypes.windll.kernel32.GetShortPathNameW(str(path), buffer, 32768)
            return buffer.value

        # Record whether the strip has anything to remove: the short form differs from the
        # long form only while an 8.3 alias exists. The CI log then shows what was tested.
        below = len(Path(str(self.config)).parts)
        before_pin = Path(expected).parent
        had_alias = Path(short_form(before_pin)).parts[below:] != before_pin.parts[below:]
        sys.stderr.write(
            "8dot3 strip: pin directory had an 8.3 alias before the strip: %s\n"
            % ("yes" if had_alias else "no (volume generates none; the strip proves nothing new)")
        )
        try:
            strip = subprocess.run(
                ["fsutil", "8dot3name", "strip", "/s", "/f", str(self.config)],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=120,
            )
        except subprocess.TimeoutExpired:
            self.skipTest("fsutil 8dot3name strip did not finish within 120 s on this runner")
        if strip.returncode != 0:
            self.skipTest(
                "fsutil could not strip 8.3 names on this volume: "
                + strip.stdout.decode("utf-8", "replace")
            )
        # fsutil strips the names inside the config directory, not the config directory's own
        # name or its ancestors, so only the components below it are compared. On a volume
        # that already generates no 8.3 names the short form equals the long form and the
        # same assertion holds.
        pin_directory = Path(expected).parent
        short = short_form(pin_directory)
        self.assertTrue(short)
        self.assertEqual(
            Path(short).parts[below:],
            pin_directory.parts[below:],
            "the cache path below the config directory still has an 8.3 alias",
        )

        log = self.case_root / "stripped-hit-invocations.bin"
        hit = self.run_bootstrap(
            ("hook", "subagent-start"),
            env=self.bootstrap_environment(
                marker=self.marker,
                mode="record",
                BRIEFING_BOOTSTRAP_STUB_LOG=str(log.absolute()),
            ),
        )
        self.assertEqual(hit.returncode, 0, hit.stderr.decode("utf-8", "replace"))
        self.assert_hit_records(expected, self.invocation_records(log))

    def test_malformed_extended_config_path_is_rejected_before_child_start(self):
        marker = self.root / "malformed-extended-config-child-started"
        result = self.run_bootstrap(
            env=self.environment(
                "exit",
                CLAUDE_CONFIG_DIR=r"\\?\U",
                BRIEFING_BOOTSTRAP_STUB_EXIT="0",
                BRIEFING_BOOTSTRAP_STUB_MARKER=str(marker.resolve()),
            )
        )

        self.assert_rejected_before_child_start(result, marker)

    def test_fixture_child_override_requires_exact_gate_and_versioned_cache_path(self):
        relative_child = self.cwd / "relative-bootstrap-stub.exe"
        outside_child = self.root / "outside-cache-bootstrap-stub.exe"
        shutil.copyfile(self.child, relative_child)
        shutil.copyfile(self.child, outside_child)
        # A child must sit in <V>\\<exactly 16 lowercase hex digits>\\<file>.
        misplaced = {
            "directly-in-version-directory": self.cache,
            "uppercase-pin-directory": self.cache / "FEDCBA9876543210",
            "short-pin-directory": self.cache / FIXTURE_PIN[:15],
            "long-pin-directory": self.cache / (FIXTURE_PIN + "0"),
            "non-hex-pin-directory": self.cache / (FIXTURE_PIN[:15] + "g"),
            "two-levels-below-version": self.cache / FIXTURE_PIN / "nested",
        }
        misplaced_children = {}
        for name, directory in misplaced.items():
            directory.mkdir(parents=True, exist_ok=True)
            misplaced_children[name] = directory / ("misplaced-" + name + ".exe")
            shutil.copyfile(self.child, misplaced_children[name])

        cases = (
            ("missing-gate", None, str(self.child.resolve())),
            ("wrong-gate-zero", "0", str(self.child.resolve())),
            ("wrong-gate-text", "true", str(self.child.resolve())),
            ("wrong-gate-numeric", "01", str(self.child.resolve())),
            ("relative-child", "1", relative_child.name),
            ("outside-versioned-cache", "1", str(outside_child.resolve())),
        ) + tuple(
            (name, "1", str(child.resolve())) for name, child in misplaced_children.items()
        )
        for name, gate, child in cases:
            with self.subTest(case=name):
                marker = self.root / (name + "-child-started")
                env = self.environment(
                    "exit",
                    BRIEFING_BOOTSTRAP_TEST_CHILD=child,
                    BRIEFING_BOOTSTRAP_STUB_EXIT="0",
                    BRIEFING_BOOTSTRAP_STUB_MARKER=str(marker.resolve()),
                )
                if gate is None:
                    env.pop("BRIEFING_BOOTSTRAP_TESTING")
                else:
                    env["BRIEFING_BOOTSTRAP_TESTING"] = gate

                result = self.run_bootstrap(env=env)

                self.assert_rejected_before_child_start(result, marker)

    def test_relative_config_dir_is_rejected(self):
        marker = self.root / "relative-config-child-started"
        result = self.run_bootstrap(
            env=self.environment(
                "exit",
                CLAUDE_CONFIG_DIR=r"relative\\configuration",
                BRIEFING_BOOTSTRAP_STUB_EXIT="0",
                BRIEFING_BOOTSTRAP_STUB_MARKER=str(marker.resolve()),
            )
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, b"")
        self.assertFalse(marker.exists(), "relative config must be rejected before child start")

    def test_rejects_every_noncanonical_pin_class(self):
        data = self.fixture.read_bytes()
        digest = sha256(data)
        canonical = self.canonical_manifest(data=data)
        lines = canonical.splitlines(keepends=True)
        mixed = list(lines)
        mixed[3] = mixed[3].replace(b"0.001", b"9.9.9", 1)
        reordered = list(lines)
        reordered[0], reordered[1] = reordered[1], reordered[0]
        cases = {
            "missing": b"".join(lines[1:]),
            "duplicate-name-and-platform": canonical + lines[0],
            "extra-platform": canonical + (b"f" * 64) + b"  briefing-0.001-freebsd-x86_64\n",
            "wrong-order": b"".join(reordered),
            "mixed-version": b"".join(mixed),
            "short-hash": canonical.replace(digest.encode("ascii"), b"a" * 63, 1),
            "nonhex-hash": canonical.replace(digest.encode("ascii"), b"g" * 64, 1),
            "uppercase-hash": canonical.replace(
                digest.encode("ascii"), digest.upper().encode("ascii"), 1
            ),
            "one-space-separator": lines[0].replace(b"  ", b" ", 1) + b"".join(lines[1:]),
            "tab-separator": lines[0].replace(b"  ", b"\t", 1) + b"".join(lines[1:]),
            "three-space-separator": lines[0].replace(b"  ", b"   ", 1) + b"".join(lines[1:]),
            "crlf": canonical.replace(b"\n", b"\r\n"),
            "relative-path": canonical.replace(
                ASSETS[0].encode("ascii"), ("release/" + ASSETS[0]).encode("ascii"), 1
            ),
            "absolute-path": canonical.replace(
                ASSETS[0].encode("ascii"), ("C:/release/" + ASSETS[0]).encode("ascii"), 1
            ),
            "renamed-platform": canonical.replace(b"linux-x86_64", b"linux-amd64", 1),
            "windows-without-exe": canonical.replace(b"windows-x86_64.exe", b"windows-x86_64", 1),
            "blank-line": canonical + b"\n",
            "embedded-nul": canonical[:-1] + b"\0\n",
            "oversized": canonical + (b"x" * 1024 * 1024),
        }

        self.use_production_config("noncanonical")
        self.write_manifest(canonical)
        server = AssetServer(self, data=data)
        provision = self.run_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True, base_url=server.base_url, marker=self.marker
            ),
        )
        self.assertEqual(
            provision.returncode, 0, provision.stderr.decode("utf-8", "replace")
        )
        self.assertTrue(self.marker.exists(), "canonical setup bytes did not execute")
        self.marker.unlink()
        extensionless = self.cached_path(digest=digest).with_name("briefing")
        extensionless.write_bytes(data)

        for name, manifest in cases.items():
            with self.subTest(pin_class=name):
                if self.marker.exists():
                    self.marker.unlink()
                self.write_manifest(manifest)
                result = self.run_bootstrap(
                    ("hook", "subagent-start"),
                    env=self.bootstrap_environment(marker=self.marker),
                )

                self.assertFalse(
                    self.marker.exists(),
                    "noncanonical %s manifest selected executable bytes" % name,
                )
                self.assert_safe_hook_warning(result)

    def test_selects_windows_exe_name_only(self):
        self.use_production_config()
        data = self.fixture.read_bytes()
        digest = sha256(data)
        self.write_manifest(self.canonical_manifest(data=data))
        server = AssetServer(self, data=data)

        result = self.run_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True, base_url=server.base_url, marker=self.marker
            ),
        )

        self.assertEqual(result.returncode, 0, result.stderr.decode("utf-8", "replace"))
        self.assertEqual(result.stderr, b"")
        self.assertEqual(
            server.paths,
            ["/%s/%s" % (VERSION, WINDOWS_ASSET)],
            "the provisioner must request only the canonical Windows .exe asset",
        )
        self.assertTrue(self.marker.exists(), "the selected Windows fixture did not execute")
        cached = self.cached_path(digest=digest)
        self.assertEqual(cached.read_bytes(), data)

    def test_production_rejects_plain_http_origin(self):
        data = self.fixture.read_bytes()
        digest = sha256(data)
        self.write_manifest(self.canonical_manifest(data=data))

        self.use_production_config("plain-http")
        plain = AssetServer(self, data=data)
        plain_result = self.run_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(base_url=plain.base_url, marker=self.marker),
        )
        self.assertEqual(plain.paths, [], "production contacted a plain-HTTP origin")
        self.assertFalse(self.marker.exists(), "plain-HTTP bytes were executed")
        self.assert_no_trusted_cache_entry(digest)
        self.assert_safe_hook_warning(plain_result)

    def test_production_rejects_tls_downgrade(self):
        unavailable = TrustedTestRoot.unavailable()
        if unavailable is not None:
            self.skipTest(unavailable)
        data = self.fixture.read_bytes()
        digest = sha256(data)
        self.write_manifest(self.canonical_manifest(data=data))

        self.use_production_config("tls-downgrade")
        downgrade_target = AssetServer(self, data=data)
        redirect_url = downgrade_target.base_url + "/" + WINDOWS_ASSET
        tls_origin = AssetServer(self, redirect=redirect_url, tls=True)
        with TrustedTestRoot():
            downgrade_result = self.run_bootstrap(
                ("hook", "session-start"),
                env=self.bootstrap_environment(
                    base_url=tls_origin.base_url, marker=self.marker
                ),
            )
        self.assertEqual(
            tls_origin.paths,
            ["/%s/%s" % (VERSION, WINDOWS_ASSET)],
            "the trusted HTTPS fixture was not reached",
        )
        self.assertEqual(
            downgrade_target.paths,
            [],
            "WinHTTP followed an HTTPS-to-HTTP downgrade",
        )
        self.assertFalse(self.marker.exists(), "downgraded bytes were executed")
        self.assert_no_trusted_cache_entry(digest)
        self.assert_safe_hook_warning(downgrade_result)

    def test_hash_mismatch_and_oversize_never_execute(self):
        data = self.fixture.read_bytes()
        digest = sha256(data)

        self.use_production_config("wrong-hash")
        self.write_manifest(self.canonical_manifest(data=data))
        wrong_hash_server = AssetServer(self, data=data + b"wrong hash")
        wrong_hash = self.run_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True, base_url=wrong_hash_server.base_url, marker=self.marker
            ),
        )
        self.assertFalse(self.marker.exists(), "wrong-hash PE bytes were executed")
        self.assert_no_trusted_cache_entry(digest)
        self.assert_safe_hook_warning(wrong_hash)

        self.use_production_config("oversize")
        self.write_manifest(self.canonical_manifest(data=data))
        oversize_server = AssetServer(self, data=data)
        oversize = self.run_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True,
                base_url=oversize_server.base_url,
                max_bytes=len(data) - 1,
                marker=self.marker,
            ),
        )
        self.assertFalse(self.marker.exists(), "oversized PE bytes were executed")
        self.assert_no_trusted_cache_entry(digest)
        self.assert_safe_hook_warning(oversize)

    def test_reparse_point_cache_component_is_rejected(self):
        data = self.fixture.read_bytes()
        self.write_manifest(self.canonical_manifest(data=data))
        server = AssetServer(self, data=data)
        cases = (
            ("config", ()),
            ("briefing", ("briefing",)),
            ("bin", ("briefing", "bin")),
            ("version", ("briefing", "bin", VERSION)),
            ("pin", ("briefing", "bin", VERSION, sha256(data)[:16])),
        )

        for name, parts in cases:
            with self.subTest(component=name):
                self.use_production_config("reparse-" + name)
                self.marker = self.case_root / ("reparse-" + name + "-executed")
                target = self.case_root / ("reparse-target-" + name)
                target.mkdir()
                link = self.config.joinpath(*parts) if parts else self.config
                link.parent.mkdir(parents=True, exist_ok=True)
                self.create_junction(link, target)
                # Registered per case, before the run: the junction goes first, as a link.
                self.addCleanup(remove_reparse_point, link)

                result = self.run_bootstrap(
                    ("hook", "session-start"),
                    env=self.bootstrap_environment(
                        testing=True, base_url=server.base_url, marker=self.marker
                    ),
                )

                self.assertFalse(self.marker.exists(), "reparse-point bytes were executed")
                self.assertEqual(
                    list(target.rglob("*")),
                    [],
                    "the provisioner wrote through the %s reparse point" % name,
                )
                self.assert_safe_hook_warning(result)

    def test_provision_parent_reparse_swap_never_touches_foreign_tree(self):
        data = self.fixture.read_bytes()
        foreign_data = self.foreign_fixture_bytes()
        digest = sha256(data)
        anchor = self.case_root / "provision-anchor"
        self.config = anchor / "config"
        self.cache = self.config / "briefing" / "bin" / VERSION
        ready = self.case_root / "warm-child-ready"
        release = self.case_root / "release-warm-child"
        self.marker = ready
        self.write_manifest(self.canonical_manifest(data=data))
        server = AssetServer(self, data=data)
        process = self.start_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True,
                base_url=server.base_url,
                marker=ready,
                mode="pause",
                BRIEFING_BOOTSTRAP_STUB_RELEASE=str(release.absolute()),
            ),
        )
        reached_window = self.wait_for_path(ready)
        swap_error = None
        replacement_result = None
        foreign_temporary = None
        foreign_destination = None
        foreign_par_sentinel = None
        displaced_anchor = self.case_root / "displaced-provision-anchor"
        foreign_anchor = self.case_root / "foreign-provision-anchor"
        original_temporary = None

        if reached_window:
            try:
                temporary_files = [
                    path for path in self.cached_path(digest=digest).parent.iterdir()
                    if path.is_file() and path.name.endswith(".tmp")
                ]
                if len(temporary_files) != 1:
                    raise AssertionError(
                        "warm-up window did not expose exactly one private temporary file: %r"
                        % temporary_files
                    )
                original_temporary = temporary_files[0]
                destination = self.cached_path(digest=digest)
                foreign_version = (
                    foreign_anchor / "config" / "briefing" / "bin" / VERSION
                )
                foreign_pin = foreign_version / destination.parent.name
                foreign_pin.mkdir(parents=True)
                foreign_temporary = foreign_pin / original_temporary.name
                foreign_temporary.write_bytes(b"foreign temporary sentinel")
                foreign_destination = foreign_pin / destination.name
                foreign_destination.write_bytes(foreign_data)
                foreign_par = foreign_pin / "par"
                foreign_par.mkdir()
                foreign_par_sentinel = foreign_par / "foreign-par-sentinel"
                foreign_par_sentinel.write_bytes(b"foreign PAR sentinel")

                replacement_result = self.attempt_parent_replacement(
                    anchor, displaced_anchor, foreign_anchor
                )
                ready.unlink()
            except Exception as error:
                swap_error = error

        release.write_bytes(b"release\n")
        try:
            stdout, stderr = communicate_bounded(process, label="bootstrap process")
        finally:
            if process.poll() is None:
                process.kill()
                process.wait(timeout=10)

        if swap_error is not None:
            raise swap_error
        self.assertTrue(reached_window, "fixture never reached the warm-up swap window")
        self.assertIn(
            replacement_result,
            ("blocked-by-sharing-lock", "replaced-with-junction"),
            "the reparse-parent replacement was not attempted",
        )
        result = subprocess.CompletedProcess([], process.returncode, stdout, stderr)
        self.assert_verified_bytes_or_safe_hook_fallback(result, ready)
        self.assertTrue(
            foreign_temporary.is_file(),
            "cleanup followed the exchanged parent and deleted a foreign temp name",
        )
        self.assertEqual(
            foreign_temporary.read_bytes(), b"foreign temporary sentinel"
        )
        self.assertEqual(foreign_destination.read_bytes(), foreign_data)
        self.assertEqual(
            foreign_par_sentinel.read_bytes(), b"foreign PAR sentinel"
        )
        cleanup_config = (
            displaced_anchor / "config"
            if replacement_result == "replaced-with-junction"
            else anchor / "config"
        )
        displaced_temporaries = [
            path
            for path in cleanup_config.rglob("*.tmp")
            if path.is_file()
        ]
        self.assertEqual(
            displaced_temporaries,
            [],
            "the process-owned temporary file was not cleaned from the original tree",
        )

    def test_parent_swap_before_warm_create_never_starts_foreign_fixture(self):
        data = self.fixture.read_bytes()
        foreign_data = self.foreign_fixture_bytes()
        digest = sha256(data)
        anchor = self.case_root / "before-warm-anchor"
        self.config = anchor / "config"
        self.cache = self.config / "briefing" / "bin" / VERSION
        marker = self.case_root / "before-warm-executed"
        ready = self.case_root / "before-warm-ready"
        release = self.case_root / "before-warm-release"
        displaced = self.case_root / "before-warm-displaced"
        foreign_anchor = self.case_root / "before-warm-foreign"
        self.write_manifest(self.canonical_manifest(data=data))
        server = AssetServer(self, data=data)
        process = self.start_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True,
                base_url=server.base_url,
                marker=marker,
                BRIEFING_BOOTSTRAP_TEST_SYNC_POINT="warm-before-create",
                BRIEFING_BOOTSTRAP_TEST_SYNC_READY=str(ready.absolute()),
                BRIEFING_BOOTSTRAP_TEST_SYNC_RELEASE=str(release.absolute()),
            ),
        )
        reached = self.wait_for_path(ready, timeout=5)
        swap_error = None
        replacement_result = None
        foreign_temp = foreign_destination = foreign_par_sentinel = None
        if reached:
            try:
                temporary_files = [
                    path for path in self.cached_path(digest=digest).parent.iterdir()
                    if path.is_file() and path.name.endswith(".tmp")
                ]
                if len(temporary_files) != 1:
                    raise AssertionError(
                        "pre-warm sync exposed unexpected temp files: %r"
                        % temporary_files
                    )
                destination = self.cached_path(digest=digest)
                foreign_version = (
                    foreign_anchor / "config" / "briefing" / "bin" / VERSION
                )
                foreign_pin = foreign_version / destination.parent.name
                foreign_pin.mkdir(parents=True)
                foreign_temp = foreign_pin / temporary_files[0].name
                foreign_temp.write_bytes(foreign_data)
                foreign_destination = foreign_pin / destination.name
                foreign_destination.write_bytes(foreign_data)
                foreign_par = foreign_pin / "par"
                foreign_par.mkdir()
                foreign_par_sentinel = foreign_par / "sentinel"
                foreign_par_sentinel.write_bytes(b"foreign PAR sentinel")
                replacement_result = self.attempt_parent_replacement(
                    anchor, displaced, foreign_anchor
                )
            except Exception as error:
                swap_error = error
        release.write_bytes(b"release\n")
        try:
            stdout, stderr = communicate_bounded(process, label="bootstrap process")
        finally:
            if process.poll() is None:
                process.kill()
                process.wait(timeout=10)
        if swap_error is not None:
            raise swap_error

        result = subprocess.CompletedProcess([], process.returncode, stdout, stderr)
        self.assertTrue(reached, "bootstrap did not expose the pre-warm sync point")
        self.assertIn(
            replacement_result,
            ("blocked-by-sharing-lock", "replaced-with-junction"),
            "pre-warm public-cache replacement was not attempted",
        )
        self.assert_verified_bytes_or_safe_hook_fallback(result, marker)
        self.assertEqual(foreign_temp.read_bytes(), foreign_data)
        self.assertEqual(foreign_destination.read_bytes(), foreign_data)
        self.assertEqual(foreign_par_sentinel.read_bytes(), b"foreign PAR sentinel")

    def test_parent_swap_after_install_never_reopens_or_deletes_foreign_target(self):
        data = self.fixture.read_bytes()
        foreign_data = self.foreign_fixture_bytes()
        digest = sha256(data)
        anchor = self.case_root / "after-install-anchor"
        self.config = anchor / "config"
        self.cache = self.config / "briefing" / "bin" / VERSION
        marker = self.case_root / "after-install-executed"
        ready = self.case_root / "after-install-ready"
        release = self.case_root / "after-install-release"
        displaced = self.case_root / "after-install-displaced"
        foreign_anchor = self.case_root / "after-install-foreign"
        self.write_manifest(self.canonical_manifest(data=data))
        server = AssetServer(self, data=data)
        process = self.start_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True,
                base_url=server.base_url,
                marker=marker,
                BRIEFING_BOOTSTRAP_TEST_SYNC_POINT="install-before-reopen",
                BRIEFING_BOOTSTRAP_TEST_SYNC_READY=str(ready.absolute()),
                BRIEFING_BOOTSTRAP_TEST_SYNC_RELEASE=str(release.absolute()),
            ),
        )
        reached = self.wait_for_path(ready, timeout=5)
        swap_error = None
        replacement_result = None
        foreign_temp = foreign_destination = foreign_par_sentinel = None
        if reached:
            try:
                destination = self.cached_path(digest=digest)
                if not destination.is_file():
                    raise AssertionError(
                        "post-install sync ran before the destination existed"
                    )
                foreign_version = (
                    foreign_anchor / "config" / "briefing" / "bin" / VERSION
                )
                foreign_pin = foreign_version / destination.parent.name
                foreign_pin.mkdir(parents=True)
                foreign_temp = foreign_pin / ".foreign-temp-sentinel.tmp"
                foreign_temp.write_bytes(b"foreign temp sentinel")
                foreign_destination = foreign_pin / destination.name
                foreign_destination.write_bytes(foreign_data)
                foreign_par = foreign_pin / "par"
                foreign_par.mkdir()
                foreign_par_sentinel = foreign_par / "sentinel"
                foreign_par_sentinel.write_bytes(b"foreign PAR sentinel")
                replacement_result = self.attempt_parent_replacement(
                    anchor, displaced, foreign_anchor
                )
            except Exception as error:
                swap_error = error
        release.write_bytes(b"release\n")
        try:
            stdout, stderr = communicate_bounded(process, label="bootstrap process")
        finally:
            if process.poll() is None:
                process.kill()
                process.wait(timeout=10)
        if swap_error is not None:
            raise swap_error

        result = subprocess.CompletedProcess([], process.returncode, stdout, stderr)
        self.assertTrue(reached, "bootstrap did not expose the post-install sync point")
        self.assertIn(
            replacement_result,
            ("blocked-by-sharing-lock", "replaced-with-junction"),
            "post-install public-cache replacement was not attempted",
        )
        self.assert_verified_bytes_or_safe_hook_fallback(result, marker)
        self.assertEqual(foreign_temp.read_bytes(), b"foreign temp sentinel")
        self.assertEqual(foreign_destination.read_bytes(), foreign_data)
        self.assertEqual(foreign_par_sentinel.read_bytes(), b"foreign PAR sentinel")

    def test_cache_hit_swap_before_final_create_never_starts_foreign_fixture(self):
        data = self.fixture.read_bytes()
        foreign_data = self.foreign_fixture_bytes()
        digest = sha256(data)
        anchor = self.case_root / "cache-hit-anchor"
        self.config = anchor / "config"
        self.cache = self.config / "briefing" / "bin" / VERSION
        marker = self.case_root / "cache-hit-executed"
        self.write_manifest(self.canonical_manifest(data=data))
        server = AssetServer(self, data=data)
        provision = self.run_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True, base_url=server.base_url, marker=marker
            ),
        )
        self.assertEqual(
            provision.returncode, 0, provision.stderr.decode("utf-8", "replace")
        )
        self.assertEqual(self.cached_path(digest=digest).read_bytes(), data)
        self.assertTrue(marker.exists(), "cache-hit setup did not execute verified bytes")
        marker.unlink()

        ready = self.case_root / "cache-hit-ready"
        release = self.case_root / "cache-hit-release"
        displaced = self.case_root / "cache-hit-displaced"
        foreign_anchor = self.case_root / "cache-hit-foreign"
        process = self.start_bootstrap(
            ("hook", "subagent-start"),
            env=self.bootstrap_environment(
                testing=True,
                marker=marker,
                BRIEFING_BOOTSTRAP_TEST_SYNC_POINT="cache-hit-before-create",
                BRIEFING_BOOTSTRAP_TEST_SYNC_READY=str(ready.absolute()),
                BRIEFING_BOOTSTRAP_TEST_SYNC_RELEASE=str(release.absolute()),
            ),
        )
        reached = self.wait_for_path(ready, timeout=5)
        swap_error = None
        replacement_result = None
        foreign_temp = foreign_destination = foreign_par_sentinel = None
        if reached:
            try:
                destination = self.cached_path(digest=digest)
                foreign_version = (
                    foreign_anchor / "config" / "briefing" / "bin" / VERSION
                )
                foreign_pin = foreign_version / destination.parent.name
                foreign_pin.mkdir(parents=True)
                foreign_temp = foreign_pin / ".foreign-temp-sentinel.tmp"
                foreign_temp.write_bytes(b"foreign temp sentinel")
                foreign_destination = foreign_pin / destination.name
                foreign_destination.write_bytes(foreign_data)
                foreign_par = foreign_pin / "par"
                foreign_par.mkdir()
                foreign_par_sentinel = foreign_par / "sentinel"
                foreign_par_sentinel.write_bytes(b"foreign PAR sentinel")
                replacement_result = self.attempt_parent_replacement(
                    anchor, displaced, foreign_anchor
                )
            except Exception as error:
                swap_error = error
        release.write_bytes(b"release\n")
        try:
            stdout, stderr = communicate_bounded(process, label="bootstrap process")
        finally:
            if process.poll() is None:
                process.kill()
                process.wait(timeout=10)
        if swap_error is not None:
            raise swap_error

        result = subprocess.CompletedProcess([], process.returncode, stdout, stderr)
        self.assertTrue(reached, "bootstrap did not expose the cache-hit sync point")
        self.assertIn(
            replacement_result,
            ("blocked-by-sharing-lock", "replaced-with-junction"),
            "cache-hit public-cache replacement was not attempted",
        )
        self.assert_verified_bytes_or_safe_hook_fallback(result, marker)
        self.assertEqual(foreign_temp.read_bytes(), b"foreign temp sentinel")
        self.assertEqual(foreign_destination.read_bytes(), foreign_data)
        self.assertEqual(foreign_par_sentinel.read_bytes(), b"foreign PAR sentinel")

    def test_ancestor_swap_after_final_identity_check_never_starts_foreign_fixture(self):
        data = self.fixture.read_bytes()
        foreign_data = self.foreign_fixture_bytes()
        digest = sha256(data)
        replaceable_parent = self.case_root / "final-create-parent-one"
        nested_parent = replaceable_parent / "final-create-parent-two"
        self.config = nested_parent / "config"
        self.cache = self.config / "briefing" / "bin" / VERSION
        marker = self.case_root / "final-create-executed"
        self.write_manifest(self.canonical_manifest(data=data))
        server = AssetServer(self, data=data)
        provision = self.run_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True, base_url=server.base_url, marker=marker
            ),
        )
        self.assertEqual(
            provision.returncode, 0, provision.stderr.decode("utf-8", "replace")
        )
        self.assertEqual(self.cached_path(digest=digest).read_bytes(), data)
        self.assertTrue(marker.exists(), "final-create setup did not run verified bytes")
        marker.unlink()

        ready = self.case_root / "final-create-ready"
        release = self.case_root / "final-create-release"
        displaced = self.case_root / "final-create-displaced-parent"
        foreign_parent = self.case_root / "final-create-foreign-parent"
        process = self.start_bootstrap(
            ("hook", "subagent-start"),
            env=self.bootstrap_environment(
                testing=True,
                marker=marker,
                BRIEFING_BOOTSTRAP_TEST_SYNC_POINT="final-before-create",
                BRIEFING_BOOTSTRAP_TEST_SYNC_READY=str(ready.absolute()),
                BRIEFING_BOOTSTRAP_TEST_SYNC_RELEASE=str(release.absolute()),
            ),
        )
        reached = self.wait_for_path(ready, timeout=5)
        swap_error = None
        replacement_result = None
        foreign_temp = foreign_destination = foreign_par_sentinel = None
        if reached:
            try:
                destination = self.cached_path(digest=digest)
                foreign_version = (
                    foreign_parent
                    / "final-create-parent-two"
                    / "config"
                    / "briefing"
                    / "bin"
                    / VERSION
                )
                foreign_pin = foreign_version / destination.parent.name
                foreign_pin.mkdir(parents=True)
                foreign_temp = foreign_pin / ".foreign-temp-sentinel.tmp"
                foreign_temp.write_bytes(b"foreign temp sentinel")
                foreign_destination = foreign_pin / destination.name
                foreign_destination.write_bytes(foreign_data)
                foreign_par = foreign_pin / "par"
                foreign_par.mkdir()
                foreign_par_sentinel = foreign_par / "sentinel"
                foreign_par_sentinel.write_bytes(b"foreign PAR sentinel")
                replacement_result = self.attempt_parent_replacement(
                    replaceable_parent, displaced, foreign_parent
                )
            except Exception as error:
                swap_error = error
        release.write_bytes(b"release\n")
        try:
            stdout, stderr = communicate_bounded(process, label="bootstrap process")
        finally:
            if process.poll() is None:
                process.kill()
                process.wait(timeout=10)
        if swap_error is not None:
            raise swap_error

        result = subprocess.CompletedProcess([], process.returncode, stdout, stderr)
        self.assertTrue(
            reached, "bootstrap did not expose the final-before-create sync point"
        )
        self.assertIn(
            replacement_result,
            ("blocked-by-sharing-lock", "replaced-with-junction"),
            "ancestor replacement above config root was not attempted",
        )
        self.assert_verified_bytes_or_safe_hook_fallback(result, marker)
        self.assertEqual(foreign_temp.read_bytes(), b"foreign temp sentinel")
        self.assertEqual(foreign_destination.read_bytes(), foreign_data)
        self.assertEqual(foreign_par_sentinel.read_bytes(), b"foreign PAR sentinel")

    def test_cache_dacl_is_current_user_only(self):
        self.use_production_config()
        data = self.fixture.read_bytes()
        digest = sha256(data)
        self.write_manifest(self.canonical_manifest(data=data))
        server = AssetServer(self, data=data)

        result = self.run_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True, base_url=server.base_url, marker=self.marker
            ),
        )

        self.assertEqual(result.returncode, 0, result.stderr.decode("utf-8", "replace"))
        cached = self.cached_path(digest=digest)
        for path in (
            self.config / "briefing",
            self.config / "briefing" / "bin",
            self.cache,
            cached.parent,
            cached,
        ):
            with self.subTest(path=str(path)):
                self.assert_current_user_security(path)

    def test_cache_and_par_objects_are_owned_by_current_token_user(self):
        cached, par, child_directory, child_file = self.provision_par_tree("owners")
        objects = (
            self.config / "briefing",
            self.config / "briefing" / "bin",
            self.cache,
            cached.parent,
            cached,
            par,
            child_directory,
            child_file,
        )

        for path in objects:
            with self.subTest(path=str(path)):
                owner_is_current, unused_protected, unused_aces = inspect_security(path)
                self.assertTrue(
                    owner_is_current,
                    "cache/PAR owner does not equal the current TokenUser: %s" % path,
                )

    def test_par_acl_inherits_current_user_only_to_child_objects(self):
        cached, par, child_directory, child_file = self.provision_par_tree(
            "par-inheritance"
        )

        self.assert_current_user_security(par, require_inheritance=True)
        for path in (child_directory, child_file):
            with self.subTest(path=str(path)):
                self.assert_current_user_security(path, require_protected=False)

    def test_default_token_owner_is_restored_before_children_and_fallbacks(self):
        data = self.fixture.read_bytes()
        self.use_production_config("token-owner-child")
        regular_config = self.config
        self.write_manifest(self.canonical_manifest(data=data))
        server = AssetServer(self, data=data)

        fallback_config = self.case_root / "token-owner-config-is-a-file"
        fallback_config.write_bytes(b"not a cache directory\n")
        python_path = self.case_root / "token-owner-python-path"
        perl_path = self.case_root / "token-owner-perl-path"
        python_path.mkdir()
        perl_path.mkdir()
        shutil.copyfile(self.fixture, python_path / "python.exe")
        shutil.copyfile(self.fixture, perl_path / "perl.exe")
        python_log = self.case_root / "token-owner-python.log"
        python_invocations = self.case_root / "token-owner-python-invocations.bin"
        perl_log = self.case_root / "token-owner-perl.log"
        perl_invocations = self.case_root / "token-owner-perl-invocations.bin"

        owner = TokenOwnerControl()
        if not owner.select_distinct_owner():
            owner.close()
            self.skipTest(
                "native token has no distinct owner-capable SID; TokenOwner restoration is unproved"
            )
        self.addCleanup(owner.close)
        expected = owner.expected_hex

        owner.apply_expected()
        self.config = regular_config
        self.cache = self.config / "briefing" / "bin" / VERSION
        regular = self.run_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True,
                base_url=server.base_url,
                mode="token-owner",
                marker=self.marker,
            ),
        )
        self.assertEqual(regular.returncode, 0, regular.stderr.decode("utf-8", "replace"))
        self.assertEqual(regular.stderr, b"")
        self.assertEqual(regular.stdout.decode("ascii").strip(), expected)

        owner.apply_expected()
        self.config = fallback_config
        python_result = self.run_bootstrap(
            ("hook", "subagent-start"),
            env=self.bootstrap_environment(
                path=python_path,
                mode="owner-record",
                exit_status="23",
                BRIEFING_BOOTSTRAP_STUB_LOG=str(python_invocations.absolute()),
                BRIEFING_BOOTSTRAP_STUB_OWNER_LOG=str(python_log.absolute()),
            ),
        )
        self.assertEqual(python_result.returncode, 23)
        self.assertEqual(python_result.stdout, b"")
        self.assertEqual(python_result.stderr, b"")
        self.assertEqual(python_log.read_text(encoding="ascii").splitlines(), [expected])

        owner.apply_expected()
        perl_result = self.run_bootstrap(
            ("--version",),
            env=self.bootstrap_environment(
                path=perl_path,
                mode="owner-record",
                exit_status="29",
                BRIEFING_BOOTSTRAP_STUB_LOG=str(perl_invocations.absolute()),
                BRIEFING_BOOTSTRAP_STUB_OWNER_LOG=str(perl_log.absolute()),
            ),
        )
        self.assertEqual(perl_result.returncode, 29)
        self.assertEqual(perl_result.stdout, b"")
        self.assertEqual(perl_result.stderr, b"")
        self.assertEqual(
            perl_log.read_text(encoding="ascii").splitlines(),
            [expected, expected],
        )

    def test_concurrent_loser_retries_sharing_violation_and_runs_verified_cache(self):
        self.use_production_config("concurrent-loser")
        data = self.fixture.read_bytes()
        digest = sha256(data)
        self.write_manifest(self.canonical_manifest(data=data))
        server = AssetServer(self, data=data)
        winner_ready = self.case_root / "winner-install-handle-ready"
        winner_release = self.case_root / "winner-install-handle-release"
        winner_marker = self.case_root / "winner-executed"
        loser_ready = self.case_root / "loser-sharing-violation-ready"
        loser_release = self.case_root / "loser-sharing-violation-release"
        loser_marker = self.case_root / "loser-executed"

        winner = self.start_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True,
                base_url=server.base_url,
                marker=winner_marker,
                mode="warm-zero-exit",
                exit_status="31",
                BRIEFING_BOOTSTRAP_TEST_SYNC_POINT="install-before-reopen",
                BRIEFING_BOOTSTRAP_TEST_SYNC_READY=str(winner_ready.absolute()),
                BRIEFING_BOOTSTRAP_TEST_SYNC_RELEASE=str(winner_release.absolute()),
            ),
        )
        winner_reached = self.wait_for_path(winner_ready, timeout=10)
        if not winner_reached:
            winner_release.write_bytes(b"release\n")
            stdout, stderr = communicate_bounded(winner, label="bootstrap process")
            self.fail(
                "winner never held the installed read/delete handle: stdout=%r stderr=%r"
                % (stdout, stderr)
            )
        self.assertIsNone(winner.poll(), "winner left its gated install window early")
        self.assertTrue(
            self.cached_path(digest=digest).is_file(),
            "winner seam ran before the relative install became public",
        )

        loser = self.start_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True,
                base_url=server.base_url,
                marker=loser_marker,
                mode="warm-zero-exit",
                exit_status="37",
                BRIEFING_BOOTSTRAP_TEST_SYNC_POINT=(
                    "concurrent-loser-sharing-violation"
                ),
                BRIEFING_BOOTSTRAP_TEST_SYNC_READY=str(loser_ready.absolute()),
                BRIEFING_BOOTSTRAP_TEST_SYNC_RELEASE=str(loser_release.absolute()),
            ),
        )
        loser_reached = self.wait_for_path(loser_ready, timeout=10)
        loser_waited = loser.poll() is None

        winner_release.write_bytes(b"release\n")
        try:
            winner_stdout, winner_stderr = communicate_bounded(winner, label="bootstrap process")
        finally:
            if winner.poll() is None:
                winner.kill()
                winner.wait(timeout=10)
        loser_release.write_bytes(b"release\n")
        try:
            loser_stdout, loser_stderr = communicate_bounded(loser, label="bootstrap process")
        finally:
            if loser.poll() is None:
                loser.kill()
                loser.wait(timeout=10)

        self.assertTrue(
            loser_reached,
            "loser did not expose the deterministic sharing-violation retry seam",
        )
        self.assertTrue(loser_waited, "loser fell back instead of waiting for the winner")
        self.assertEqual(winner.returncode, 31, winner_stderr.decode("utf-8", "replace"))
        self.assertEqual(loser.returncode, 37, loser_stderr.decode("utf-8", "replace"))
        self.assertEqual(winner_stdout, b"")
        self.assertEqual(winner_stderr, b"")
        self.assertEqual(loser_stdout, b"")
        self.assertEqual(loser_stderr, b"")
        self.assertEqual(winner_marker.read_bytes(), b"started\n")
        self.assertEqual(loser_marker.read_bytes(), b"started\n")
        self.assertEqual(self.cached_path(digest=digest).read_bytes(), data)
        self.assertEqual(
            server.paths,
            ["/%s/%s" % (VERSION, WINDOWS_ASSET)],
            "loser downloaded instead of waiting for and rehashing the winner's cache",
        )
        leftovers = [
            path
            for path in (self.config / "briefing" / "bin").rglob("*")
            if path.is_file()
            and path != self.cached_path(digest=digest)
            and not path.name.endswith(".failed-at")
        ]
        self.assertEqual(leftovers, [], "concurrent install left private temp files")

    def test_interrupted_and_concurrent_downloads_are_atomic(self):
        data = self.fixture.read_bytes()
        digest = sha256(data)
        self.write_manifest(self.canonical_manifest(data=data))

        self.use_production_config("interrupted")
        interrupted_server = AssetServer(self, data=data, truncate=True)
        interrupted = self.run_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True, base_url=interrupted_server.base_url, marker=self.marker
            ),
        )
        self.assertFalse(self.marker.exists(), "partial PE bytes were executed")
        self.assert_no_trusted_cache_entry(digest)
        self.assert_safe_hook_warning(interrupted)

        self.use_production_config("concurrent")
        self.marker = self.case_root / "concurrent-executed"
        concurrent_server = AssetServer(self, data=data, hold_requests=2)
        env = self.bootstrap_environment(
            testing=True, base_url=concurrent_server.base_url, marker=self.marker
        )
        processes = [
            self.start_bootstrap(("hook", "session-start"), env=env)
            for unused in range(2)
        ]
        results = []
        ready = concurrent_server.requests_ready.wait(timeout=10)
        temporary_during_download = []
        temporary_root = self.config / "briefing" / "bin"
        if ready and temporary_root.exists():
            temporary_during_download = [
                path
                for path in temporary_root.rglob("*")
                if path.is_file()
                and path != self.cached_path(digest=digest)
                and not path.name.endswith(".failed-at")
            ]
        concurrent_server.release_requests.set()
        try:
            for process in processes:
                stdout, stderr = communicate_bounded(process, label="bootstrap process")
                results.append((process.returncode, stdout, stderr))
        finally:
            for process in processes:
                if process.poll() is None:
                    process.kill()
                    process.wait(timeout=10)

        self.assertTrue(ready, "both concurrent provisions did not reach the downloader")
        self.assertEqual(
            len(temporary_during_download),
            2,
            "concurrent provisions did not hold distinct private temporary files: %r"
            % temporary_during_download,
        )
        self.assertEqual(
            len({str(path) for path in temporary_during_download}),
            2,
            "concurrent provisions collided on one temporary path",
        )
        for returncode, stdout, stderr in results:
            self.assertEqual(returncode, 0, stderr.decode("utf-8", "replace"))
            self.assertEqual(stdout, b"")
            self.assertEqual(stderr, b"")
        cached = self.cached_path(digest=digest)
        self.assertEqual(cached.read_bytes(), data)
        self.assertTrue(self.marker.exists(), "neither concurrent caller ran verified bytes")
        leftover_files = [
            path
            for path in (self.config / "briefing" / "bin").rglob("*")
            if path.is_file()
            and path != cached
            and not path.name.endswith(".failed-at")
        ]
        self.assertEqual(
            leftover_files, [], "concurrent temporary files remain: %r" % leftover_files
        )

    def test_cached_binary_is_rehashed_before_every_execution(self):
        self.use_production_config()
        data = self.fixture.read_bytes()
        digest = sha256(data)
        self.write_manifest(self.canonical_manifest(data=data))
        server = AssetServer(self, data=data)
        provision = self.run_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True, base_url=server.base_url, marker=self.marker
            ),
        )
        self.assertEqual(
            provision.returncode, 0, provision.stderr.decode("utf-8", "replace")
        )
        cached = self.cached_path(digest=digest)
        self.assertEqual(cached.read_bytes(), data)
        self.assertTrue(self.marker.exists(), "the provisioned cache did not execute")
        self.marker.unlink()
        env = self.bootstrap_environment(marker=self.marker)

        first = self.run_bootstrap(("hook", "subagent-start"), env=env)
        self.assertEqual(first.returncode, 0, first.stderr.decode("utf-8", "replace"))
        self.assertTrue(self.marker.exists(), "the initially verified cache did not run")

        self.marker.unlink()
        with cached.open("ab") as handle:
            handle.write(b"tampered-after-first-execution")
        second = self.run_bootstrap(("hook", "subagent-start"), env=env)

        self.assertFalse(self.marker.exists(), "changed cached bytes ran without rehashing")
        self.assert_safe_hook_warning(second)

    def test_verified_cache_runs_without_network_perl_python_or_powershell(self):
        self.use_production_config()
        data = self.fixture.read_bytes()
        digest = sha256(data)
        self.write_manifest(self.canonical_manifest(data=data))
        server = AssetServer(self, data=data)
        provision = self.run_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True, base_url=server.base_url, marker=self.marker
            ),
        )
        self.assertEqual(provision.returncode, 0, provision.stderr.decode("utf-8", "replace"))
        self.assertEqual(self.cached_path(digest=digest).read_bytes(), data)
        self.assertTrue(self.marker.exists(), "the provisioned fixture did not execute")
        request_count = len(server.paths)
        server.stop()
        self.marker.unlink()

        offline = self.run_bootstrap(
            ("offline", "Grüße-世界"),
            env=self.bootstrap_environment(
                base_url="http://127.0.0.1:9/%s" % VERSION,
                path=self.empty_path,
                marker=self.marker,
                exit_status="41",
            ),
        )

        self.assertEqual(offline.returncode, 41)
        self.assertEqual(offline.stdout, b"")
        self.assertEqual(offline.stderr, b"")
        self.assertTrue(self.marker.exists(), "the verified offline cache did not execute")
        self.assertEqual(len(server.paths), request_count, "an offline cache hit used the network")
        self.assertEqual(list(self.empty_path.iterdir()), [], "a runtime was added to isolated PATH")

    def test_early_config_failure_still_dispatches_fallbacks_safely(self):
        relative_config = r"relative\configuration"

        with self.subTest(command="hook-python"):
            runtime = self.case_root / "early-python-path"
            runtime.mkdir()
            python = runtime / "python.exe"
            shutil.copyfile(self.fixture, python)
            log = self.case_root / "early-python-invocations.bin"
            result = self.run_bootstrap(
                ("hook", "subagent-start"),
                input_bytes=b'{"hook_event_name":"SubagentStart"}\n',
                env=self.bootstrap_environment(
                    path=runtime,
                    mode="record",
                    exit_status="23",
                    CLAUDE_CONFIG_DIR=relative_config,
                    BRIEFING_BOOTSTRAP_STUB_LOG=str(log.absolute()),
                ),
            )
            self.assertEqual(result.returncode, 23)
            self.assertEqual(result.stdout, b"")
            self.assertEqual(result.stderr, b"")
            records = self.invocation_records(log)
            self.assertEqual(len(records), 1, records)
            self.assertEqual(
                canonical_path(records[0][0]),
                canonical_path(str(python.resolve())),
            )
            self.assertEqual(
                records[0][1:],
                canonical_args([str((self.plugin / "hooks" / "briefing-preload").resolve())]),
            )

        with self.subTest(command="hook-no-runtime"):
            result = self.run_bootstrap(
                ("hook", "subagent-start"),
                env=self.bootstrap_environment(
                    path=self.empty_path, CLAUDE_CONFIG_DIR=relative_config
                ),
            )
            self.assert_safe_hook_warning(result)

        with self.subTest(command="cli-perl"):
            runtime = self.case_root / "early-perl-path"
            runtime.mkdir()
            perl = runtime / "perl.exe"
            shutil.copyfile(self.fixture, perl)
            log = self.case_root / "early-perl-invocations.bin"
            arguments = ("--version",)
            result = self.run_bootstrap(
                arguments,
                env=self.bootstrap_environment(
                    path=runtime,
                    mode="record",
                    exit_status="29",
                    CLAUDE_CONFIG_DIR=relative_config,
                    BRIEFING_BOOTSTRAP_STUB_LOG=str(log.absolute()),
                ),
            )
            self.assertEqual(result.returncode, 29)
            self.assertEqual(result.stdout, b"")
            self.assertEqual(result.stderr, b"")
            include = "-I" + str((self.plugin / "lib").resolve())
            records = self.invocation_records(log)
            self.assertEqual(len(records), 2, records)
            executable = canonical_path(str(perl.resolve()))
            for record in records:
                self.assertEqual(
                    canonical_path(record[0]), executable
                )
            self.assertEqual(
                records[0][1:],
                canonical_args([include, "-e", "require App::Briefing::CLI"]),
            )
            self.assertEqual(
                records[1][1:],
                canonical_args([
                    include,
                    str((self.plugin / "script" / "briefing").resolve()),
                    *arguments,
                ]),
            )

    def test_hook_falls_back_to_python_when_provisioning_is_unavailable(self):
        self.use_production_config()
        runtime = self.case_root / "python-only-path"
        runtime.mkdir()
        python = runtime / "python.exe"
        shutil.copyfile(self.fixture, python)
        log = self.case_root / "python-invocations.bin"
        result = self.run_bootstrap(
            ("hook", "subagent-start"),
            input_bytes=b'{"hook_event_name":"SubagentStart"}\n',
            env=self.bootstrap_environment(
                path=runtime,
                mode="record",
                exit_status="23",
                BRIEFING_BOOTSTRAP_STUB_LOG=str(log.resolve()),
            ),
        )

        self.assertEqual(result.returncode, 23)
        self.assertEqual(result.stdout, b"")
        self.assertEqual(result.stderr, b"")
        records = self.invocation_records(log)
        self.assertEqual(len(records), 1, records)
        self.assertEqual(
            canonical_path(records[0][0]),
            canonical_path(str(python.resolve())),
        )
        self.assertEqual(
            records[0][1:],
            canonical_args([str((self.plugin / "hooks" / "briefing-preload").resolve())]),
        )

    def test_cli_falls_back_to_perl_when_provisioning_is_unavailable(self):
        self.use_production_config()
        runtime = self.case_root / "perl-only-path"
        runtime.mkdir()
        perl = runtime / "perl.exe"
        shutil.copyfile(self.fixture, perl)
        log = self.case_root / "perl-invocations.bin"
        arguments = ("--version", "Grüße-世界")
        result = self.run_bootstrap(
            arguments,
            env=self.bootstrap_environment(
                path=runtime,
                mode="record",
                exit_status="29",
                BRIEFING_BOOTSTRAP_STUB_LOG=str(log.resolve()),
            ),
        )

        self.assertEqual(result.returncode, 29)
        self.assertEqual(result.stdout, b"")
        self.assertEqual(result.stderr, b"")
        include = "-I" + str((self.plugin / "lib").resolve())
        executable = canonical_path(str(perl.resolve()))
        records = self.invocation_records(log)
        self.assertEqual(len(records), 2, records)
        for record in records:
            self.assertEqual(canonical_path(record[0]), executable)
        self.assertEqual(
            records[0][1:],
            canonical_args([include, "-e", "require App::Briefing::CLI"]),
        )
        self.assertEqual(
            records[1][1:],
            canonical_args(
                [include, str((self.plugin / "script" / "briefing").resolve()), *arguments]),
        )

    def test_hook_without_binary_or_runtime_uses_safe_warning_exit_contract(self):
        self.use_production_config()
        result = self.run_bootstrap(
            ("hook", "subagent-start"),
            input_bytes=b'{"hook_event_name":"SubagentStart"}\n',
            env=self.bootstrap_environment(path=self.empty_path),
        )

        self.assert_safe_hook_warning(result)

    def test_non_hook_without_binary_or_runtime_reports_failure(self):
        self.use_production_config()
        result = self.run_bootstrap(
            ("--version",),
            env=self.bootstrap_environment(path=self.empty_path),
        )

        self.assert_non_hook_failure(result)


    # --- the release version comes from the pin manifest (the starter's rule)

    def run_version_manifest(self, version, suffix):
        self.use_production_config(suffix)
        data = self.fixture.read_bytes()
        self.write_manifest(self.canonical_manifest(data=data, version=version))
        server = AssetServer(self, data=data, version=version)
        result = self.run_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True, base_url=server.base_url, marker=self.marker
            ),
        )
        return data, server, result

    def test_version_is_taken_from_the_pin_manifest(self):
        # Not covered natively: the default download URL (no BRIEFING_BINARY_BASE_URL) needs
        # the network; the asset name and the base-URL composition are checked here.
        for index, version in enumerate(("0.002", "9.9.9", "1.0+build.5", "probe-abc1234")):
            with self.subTest(version=version):
                if self.marker.exists():
                    self.marker.unlink()
                data, server, result = self.run_version_manifest(version, "ok%d" % index)
                asset = "briefing-%s-windows-x86_64.exe" % version
                self.assertEqual(result.returncode, 0, result.stderr.decode("utf-8", "replace"))
                self.assertEqual(result.stderr, b"")
                self.assertEqual(server.paths, ["/%s/%s" % (version, asset)])
                self.assertTrue(self.marker.exists(), "the selected asset did not execute")
                self.assertEqual(
                    self.cached_path(data=data, version=version).read_bytes(), data
                )

    def test_version_violating_the_starters_rule_makes_the_manifest_malformed(self):
        # The rule is bin/briefing platform_asset: first character [A-Za-z0-9], then only
        # [A-Za-z0-9._+-].
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
        for name, version in bad.items():
            with self.subTest(version=name):
                data, server, result = self.run_version_manifest(version, "bad-" + name)
                self.assertEqual(server.paths, [], "a malformed manifest reached the network")
                self.assertFalse(self.marker.exists(), "malformed manifest selected bytes")
                self.assert_safe_hook_warning(result)
                binary_root = self.config / "briefing" / "bin"
                leftovers = (
                    [
                        p for p in binary_root.rglob("*")
                        if p.is_file() and not p.name.endswith(".failed-at")
                    ]
                    if binary_root.exists()
                    else []
                )
                self.assertEqual(leftovers, [])

    # --- the Python fallback follows winlaunch's interpreter rules

    def fallback_path(self, *directories):
        return os.pathsep.join(str(directory) for directory in directories)

    def stub_in(self, directory, name):
        directory.mkdir(parents=True, exist_ok=True)
        target = directory / name
        shutil.copyfile(self.fixture, target)
        return target

    def run_python_fallback(self, path, log, extra=None, payload=b'{"hook_event_name":"SubagentStart"}\n'):
        self.use_production_config()
        env = self.bootstrap_environment(
            path=path,
            mode="record",
            exit_status="23",
            BRIEFING_BOOTSTRAP_STUB_LOG=str(log.resolve()),
        )
        env.pop("PYTHONUTF8", None)
        env.update(extra or {})
        return self.run_bootstrap(("hook", "subagent-start"), input_bytes=payload, env=env)

    def started_programs(self, log):
        if not log.exists():
            return []
        return [
            (canonical_path(record[0]), record[1:])
            for record in self.invocation_records(log)
        ]

    def test_python_fallback_skips_windowsapps_store_stubs(self):
        store = self.case_root / "Users" / "x" / "AppData" / "Local" / "Microsoft" / "WINDOWSAPPS"
        good = self.case_root / "real-python"
        self.stub_in(store, "python3.exe")
        self.stub_in(store, "python.exe")
        python = self.stub_in(good, "python.exe")
        log = self.case_root / "store-invocations.bin"
        result = self.run_python_fallback(self.fallback_path(store, good), log)
        self.assertEqual(result.returncode, 23, result.stderr.decode("utf-8", "replace"))
        self.assertEqual(
            self.started_programs(log),
            [
                (
                    canonical_path(str(python.resolve())),
                    canonical_args([str((self.plugin / "hooks" / "briefing-preload").resolve())]),
                )
            ],
            "the WindowsApps stub must never be started; python.exe must be",
        )

    def test_python_fallback_prefers_python3_over_python(self):
        directory = self.case_root / "both"
        python3 = self.stub_in(directory, "python3.exe")
        self.stub_in(directory, "python.exe")
        log = self.case_root / "prefer-invocations.bin"
        result = self.run_python_fallback(self.fallback_path(directory), log)
        self.assertEqual(result.returncode, 23, result.stderr.decode("utf-8", "replace"))
        programs = self.started_programs(log)
        self.assertEqual(
            [program for program, _ in programs],
            [canonical_path(str(python3.resolve()))],
        )

    def test_python_fallback_uses_the_py_launcher_with_dash_3(self):
        store = self.case_root / "Microsoft" / "WindowsApps"
        self.stub_in(store, "python3.exe")
        self.stub_in(store, "python.exe")
        launcher_directory = self.case_root / "launcher-only"
        launcher = self.stub_in(launcher_directory, "py.exe")
        log = self.case_root / "py-invocations.bin"
        result = self.run_python_fallback(self.fallback_path(store, launcher_directory), log)
        self.assertEqual(result.returncode, 23, result.stderr.decode("utf-8", "replace"))
        self.assertEqual(
            self.started_programs(log),
            [
                (
                    canonical_path(str(launcher.resolve())),
                    canonical_args(
                        ["-3", str((self.plugin / "hooks" / "briefing-preload").resolve())]),
                )
            ],
        )

    def test_python_fallback_runs_in_utf8_mode_with_the_payload_intact(self):
        directory = self.case_root / "utf8-python"
        self.stub_in(directory, "python.exe")
        log = self.case_root / "utf8-invocations.bin"
        capture = self.case_root / "utf8-capture.bin"
        payload = json.dumps(
            {"hook_event_name": "SubagentStart", "cwd": "C:\\Arbeit\\Gr\u00fc\u00dfe-\u4e16\u754c-\u6771\u4eac"},
            ensure_ascii=False,
        ).encode("utf-8") + b"\n"
        for ambient in (None, "0"):
            with self.subTest(ambient_pythonutf8=ambient):
                if capture.exists():
                    capture.unlink()
                extra = {"BRIEFING_BOOTSTRAP_STUB_CAPTURE": str(capture.resolve())}
                if ambient is not None:
                    extra["PYTHONUTF8"] = ambient
                self.use_production_config()
                env = self.bootstrap_environment(
                    path=self.fallback_path(directory),
                    mode="capture",
                    BRIEFING_BOOTSTRAP_STUB_LOG=str(log.resolve()),
                )
                env.pop("PYTHONUTF8", None)
                env.update(extra)
                result = self.run_bootstrap(
                    ("hook", "subagent-start"), input_bytes=payload, env=env
                )
                self.assertEqual(result.returncode, 0, result.stderr.decode("utf-8", "replace"))
                first, _, received = capture.read_bytes().partition(b"\n")
                self.assertEqual(first, b"PYTHONUTF8=1")
                self.assertEqual(received, payload, "the UTF-8 payload did not arrive byte-exactly")


    # --- the marketplace notice (k20): a verified cached binary, else Python, else silence

    NOTICE_ARGUMENTS = ("hook", "marketplace-notice")
    SESSION_PAYLOAD = b'{"hook_event_name":"SessionStart","source":"startup"}\n'

    def notice_script(self):
        return str((self.plugin / "hooks" / "briefing-marketplace-notice").resolve())

    def run_notice(self, path, log=None, exit_status="23", extra=None, bootstrap=None, **kwargs):
        self.use_production_config()
        env = self.bootstrap_environment(path=path, mode="record", exit_status=exit_status, **kwargs)
        if log is not None:
            env["BRIEFING_BOOTSTRAP_STUB_LOG"] = str(log.resolve())
        env.pop("PYTHONUTF8", None)
        env.update(extra or {})
        return run_bounded(
            [str(bootstrap or self.bootstrap), *self.NOTICE_ARGUMENTS],
            30,
            label="briefing-bootstrap hook marketplace-notice",
            input_bytes=self.SESSION_PAYLOAD,
            cwd=str(self.cwd),
            env=env,
        )

    def assert_silent_success(self, result):
        detail = describe_output(result.stdout, result.stderr, result.returncode)
        self.assertEqual((result.stdout, result.stderr, result.returncode), (b"", b"", 0), detail)

    def provision_cached_fixture(self):
        """Provision the fixture into the verified cache through session-start; return digest, server."""
        self.use_production_config()
        data = self.fixture.read_bytes()
        digest = sha256(data)
        self.write_manifest(self.canonical_manifest(data=data))
        server = AssetServer(self, data=data)
        provision = self.run_bootstrap(
            ("hook", "session-start"),
            env=self.bootstrap_environment(
                testing=True, base_url=server.base_url, marker=self.marker
            ),
        )
        self.assertEqual(provision.returncode, 0, provision.stderr.decode("utf-8", "replace"))
        self.assertEqual(self.cached_path(digest=digest).read_bytes(), data)
        return digest, server

    def test_notice_without_binary_runs_the_python_notice_script_alone(self):
        python = self.stub_in(self.case_root / "python-only", "python.exe")
        log = self.case_root / "notice-python.bin"
        result = self.run_notice(self.fallback_path(python.parent), log)
        self.assertEqual(result.returncode, 23, result.stderr.decode("utf-8", "replace"))
        self.assertEqual((result.stdout, result.stderr), (b"", b""))
        self.assertEqual(
            self.started_programs(log),
            [(canonical_path(str(python.resolve())), canonical_args([self.notice_script()]))],
            "exactly one Python call with the notice script and no hook words",
        )

    def test_notice_without_binary_uses_the_py_launcher_with_dash_3(self):
        launcher = self.stub_in(self.case_root / "launcher-only", "py.exe")
        log = self.case_root / "notice-py.bin"
        result = self.run_notice(self.fallback_path(launcher.parent), log)
        self.assertEqual(result.returncode, 23, result.stderr.decode("utf-8", "replace"))
        self.assertEqual(
            self.started_programs(log),
            [(canonical_path(str(launcher.resolve())),
              canonical_args(["-3", self.notice_script()]))],
        )

    def test_notice_without_binary_or_python_is_silent_with_exit_zero(self):
        self.assert_silent_success(self.run_notice(self.empty_path))

    def test_notice_without_its_script_is_silent_and_starts_no_python(self):
        alternate = self.case_root / "plugin-without-notice"
        (alternate / "bin").mkdir(parents=True)
        shutil.copytree(str(REPO_ROOT / "hooks"), str(alternate / "hooks"))
        (alternate / "hooks" / "briefing-marketplace-notice").unlink()
        shutil.copyfile(str(self.bootstrap), str(alternate / "bin" / "briefing-bootstrap.exe"))
        python = self.stub_in(self.case_root / "python-present", "python.exe")
        log = self.case_root / "notice-no-script.bin"
        result = self.run_notice(
            self.fallback_path(python.parent), log,
            bootstrap=alternate / "bin" / "briefing-bootstrap.exe",
        )
        self.assert_silent_success(result)
        self.assertEqual(self.started_programs(log), [])

    def test_notice_with_a_pin_but_no_cache_never_provisions(self):
        self.use_production_config()
        data = self.fixture.read_bytes()
        self.write_manifest(self.canonical_manifest(data=data))
        server = AssetServer(self, data=data)
        python = self.stub_in(self.case_root / "python-pinned", "python.exe")
        log = self.case_root / "notice-pinned.bin"

        with self.subTest(runtime="python"):
            result = self.run_notice(
                self.fallback_path(python.parent), log,
                testing=True, base_url=server.base_url, marker=self.marker,
            )
            self.assertEqual(result.returncode, 23, result.stderr.decode("utf-8", "replace"))
            self.assertEqual(
                self.started_programs(log),
                [(canonical_path(str(python.resolve())), canonical_args([self.notice_script()]))],
            )
        # The fixture touches the marker on every start, and the Python fallback
        # stub is the same fixture: after the python run the marker proves
        # nothing. There the invocation log is the proof (exactly one python.exe
        # record; a started cache would record itself). The marker is judged only
        # in the run without any Python on PATH.
        if self.marker.exists():
            self.marker.unlink()
        with self.subTest(runtime="none"):
            result = self.run_notice(
                self.empty_path, testing=True, base_url=server.base_url, marker=self.marker,
            )
            self.assert_silent_success(result)
            self.assertFalse(self.marker.exists(), "the notice started the fixture binary")
        self.assertEqual(server.paths, [], "the notice made an HTTP request")
        self.assert_no_trusted_cache_entry(sha256(data))

    def test_notice_with_a_verified_cache_runs_the_binary_with_exactly_the_hook_words(self):
        digest, server = self.provision_cached_fixture()
        requests = len(server.paths)
        python = self.stub_in(self.case_root / "python-beside-cache", "python.exe")
        log = self.case_root / "notice-cached.bin"
        result = self.run_notice(
            self.fallback_path(python.parent), log, exit_status="17", marker=self.marker,
        )
        self.assertEqual(result.returncode, 17, result.stderr.decode("utf-8", "replace"))
        self.assertEqual((result.stdout, result.stderr), (b"", b""))
        self.assertEqual(
            self.started_programs(log),
            [(canonical_path(str(self.cached_path(digest=digest).resolve())),
              list(self.NOTICE_ARGUMENTS))],
            "the binary, alone, with exactly the hook words; no Python beside it",
        )
        self.assertEqual(len(server.paths), requests, "the notice used the network")

    def test_notice_with_a_tampered_cache_never_runs_it(self):
        digest, server = self.provision_cached_fixture()
        requests = len(server.paths)
        self.marker.unlink()
        with self.cached_path(digest=digest).open("ab") as handle:
            handle.write(b"tampered-after-provisioning")
        python = self.stub_in(self.case_root / "python-after-tamper", "python.exe")
        log = self.case_root / "notice-tampered.bin"

        with self.subTest(runtime="python"):
            result = self.run_notice(
                self.fallback_path(python.parent), log, marker=self.marker,
            )
            self.assertEqual(result.returncode, 23, result.stderr.decode("utf-8", "replace"))
            self.assertEqual(
                self.started_programs(log),
                [(canonical_path(str(python.resolve())), canonical_args([self.notice_script()]))],
            )
        # The python run's fallback stub is the fixture and touches the marker
        # itself; judge the marker only in the run without Python on PATH.
        if self.marker.exists():
            self.marker.unlink()
        with self.subTest(runtime="none"):
            self.assert_silent_success(self.run_notice(self.empty_path, marker=self.marker))
            self.assertFalse(self.marker.exists(), "the tampered cache was executed")
        self.assertEqual(len(server.paths), requests, "the notice repaired the cache")


if __name__ == "__main__":
    if len(sys.argv) > 1 and not sys.argv[1].startswith("-"):
        EXPLICIT_BOOTSTRAP = Path(sys.argv.pop(1))
    unittest.main()
