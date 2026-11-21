#!/usr/bin/env python3
"""Throwaway check of a native binary; Python runs exclusively on the TEST HOST."""
import argparse
import json
import os
from pathlib import Path
import platform
import shutil
import statistics
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parent


def inspect_libraries(binary):
    """Host analysis, NOT part of running the packaged application."""
    system = platform.system()
    candidates = (["ldd", str(binary)] if system == "Linux" else
                  ["otool", "-L", str(binary)] if system == "Darwin" else
                  ["objdump", "-p", str(binary)])
    tool = shutil.which(candidates[0])
    if not tool:
        return {"status": "unavailable", "tool": candidates[0]}
    candidates[0] = tool
    result = subprocess.run(candidates, capture_output=True, timeout=30)
    output = (result.stdout + result.stderr).decode("utf-8", errors="replace")
    if system == "Windows":
        output = "\n".join(line for line in output.splitlines()
                           if "DLL Name:" in line or "file format" in line)
    return {"command": candidates, "exit_code": result.returncode, "output": output}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary", type=Path)
    parser.add_argument("--work-dir", type=Path, default=ROOT / ".work")
    parser.add_argument("--report", type=Path)
    parser.add_argument("--repeat", type=int, default=5)
    parser.add_argument("--expect-arch", choices=["x86_64", "arm64"])
    args = parser.parse_args()
    if args.repeat < 1:
        parser.error("--repeat must be positive")
    machine = platform.machine()
    arch = {"AMD64": "x86_64", "aarch64": "arm64"}.get(machine, machine)
    if args.expect_arch and arch != args.expect_arch:
        parser.error("actual architecture %s != requested %s" % (arch, args.expect_arch))
    binary = args.binary.resolve(strict=True)
    args.work_dir.mkdir(parents=True, exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="smoke-", dir=args.work_dir.resolve()))
    report = {
        "prototype_only": True,
        "host": {"system": platform.system(), "release": platform.release(),
                 "version": platform.version(), "machine": machine,
                 "architecture": arch, "libc": platform.libc_ver()},
        "binary": str(binary), "binary_bytes": binary.stat().st_size,
        "work_dir": str(work), "checks": {}, "timings_ms": {},
        "separate_interpreter_absence": {
            "status": "NOT_PROVEN",
            "reason": "Empty PATH does not hide absolute interpreter/library paths. "
                      "This host test is not an isolated OS without Perl.",
        },
    }
    checks = report["checks"]
    try:
        # Copy instead of symlink: test a real program path with spaces and umlauts.
        target_dir = work / "artifact ü space"
        target_dir.mkdir()
        target = target_dir / binary.name
        shutil.copy2(binary, target)
        fixtures = work / "Pfad ä 技能"
        fixtures.mkdir()
        bodies = ["# Grüße\nVollständig: 雪, café, 🦉.\n", "Second skill: Öl und Fuß.\n"]
        paths = [fixtures / "grüße SKILL.md", fixtures / "zweiter SKILL.md"]
        for path, body in zip(paths, bodies):
            path.write_bytes(body.encode("utf-8"))
        skills = [{"name": "skill-%d" % index, "path": str(path)}
                  for index, path in enumerate(paths)]
        payload = json.dumps({"skills": skills}, ensure_ascii=False).encode("utf-8")
        expected = {"ok": True, "skills": [
            {"name": skill["name"], "body": body}
            for skill, body in zip(skills, bodies)]}

        def run(data, cache, arguments=()):
            cache.mkdir(exist_ok=True)
            # pp resets PAR_TEMP; the public setting is PAR_GLOBAL_TEMP.
            # Locale C is universally available; the protocol and file content use explicit UTF-8.
            env = {"PATH": "", "PAR_GLOBAL_TEMP": str(cache), "HOME": str(work),
                   "TMPDIR": str(work), "TMP": str(work), "TEMP": str(work),
                   "LANG": "C", "LC_ALL": "C"}
            # Required by the Windows loader; no PATH to Perl or Python.
            for key in ("SystemRoot", "WINDIR"):
                if key in os.environ:
                    env[key] = os.environ[key]
            start = time.perf_counter()
            result = subprocess.run([str(target), *arguments], input=data,
                                    capture_output=True, env=env, cwd=work, timeout=60)
            elapsed = (time.perf_counter() - start) * 1000
            if result.returncode != 0 or result.stderr:
                raise AssertionError("exit=%d stderr=%r stdout=%r" %
                                     (result.returncode, result.stderr, result.stdout))
            # Strict decoding and json.loads reject extra text and multiple JSON values.
            value = json.loads(result.stdout.decode("utf-8"))
            if not isinstance(value, dict):
                raise AssertionError("stdout is not one JSON object")
            return value, elapsed

        cold = work / "par cache ä"
        value, elapsed = run(payload, cold)
        assert value == expected, (value, expected)
        assert any(cold.rglob("*")), "PAR ignored the requested cache directory"
        checks["cold_start_unicode_paths_and_complete_json"] = "PASS"
        report["timings_ms"]["first_empty_par_temp"] = round(elapsed, 3)
        warm = []
        for _ in range(args.repeat):
            value, elapsed = run(payload, cold)
            assert value == expected, value
            warm.append(round(elapsed, 3))
        checks["repeated_starts_same_par_temp"] = "PASS"
        report["timings_ms"]["repeated_same_par_temp"] = warm
        report["timings_ms"]["repeated_median"] = round(statistics.median(warm), 3)
        second = work / "second fresh cache"
        value, elapsed = run(payload, second)
        assert value == expected, value
        assert any(second.rglob("*")), "second cache was not populated"
        checks["second_fresh_par_temp"] = "PASS"
        report["timings_ms"]["second_empty_par_temp"] = round(elapsed, 3)
        mixed = {"skills": skills + [{"name": "missing", "path": str(fixtures / "absent.md")}]}
        value, _ = run(json.dumps(mixed).encode("utf-8"), cold)
        assert value == {"ok": False, "error": {"code": "missing_skill", "name": "missing"}}, value
        checks["missing_skill_no_partial_response"] = "PASS"
        value, _ = run(b'{"skills": [broken', cold)
        assert value == {"ok": False, "error": {"code": "invalid_json"}}, value
        checks["invalid_json_defined_error"] = "PASS"
        value, _ = run(b'{"skills": "not-a-list"}', cold)
        assert value == {"ok": False, "error": {"code": "invalid_request"}}, value
        checks["invalid_request_defined_error"] = "PASS"
        version, _ = run(b"", cold, ("--version",))
        assert version["prototype_only"] is True, version
        report["embedded_runtime"] = version
        checks["empty_controlled_path_all_invocations"] = "PASS"
        checks["stdout_one_utf8_json_object_stderr_empty_all_invocations"] = "PASS"
        files = [path for path in cold.rglob("*") if path.is_file()]
        report["par_cache"] = {"files": len(files), "bytes": sum(p.stat().st_size for p in files)}
        report["system_libraries"] = {"executable": inspect_libraries(target), "extracted": {}}
        for path in files:
            if path.suffix.lower() in (".so", ".dll", ".dylib") or ".so." in path.name:
                report["system_libraries"]["extracted"][str(path.relative_to(cold))] = inspect_libraries(path)
        report["functional_status"] = "PASS"
    except (AssertionError, OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        report["functional_status"] = "FAIL"
        report["failure"] = str(error)
    text = json.dumps(report, indent=2, ensure_ascii=True) + "\n"
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(text, encoding="utf-8")
    print(text, end="")
    return 0 if report["functional_status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
