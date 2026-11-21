#!/usr/bin/env python3
"""Diagnostic only: compare identical file access unpacked and packaged."""
import argparse
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary", type=Path)
    parser.add_argument("--perl", default="perl")
    parser.add_argument("--source", type=Path, default=ROOT / "probe.pl")
    parser.add_argument("--report", type=Path, default=ROOT / "build/path-controls.json")
    args = parser.parse_args()
    perl = shutil.which(args.perl)
    if not perl:
        parser.error("Build interpreter not found: " + args.perl)
    perl = str(Path(perl).resolve(strict=True))
    binary = args.binary.resolve(strict=True)
    source = args.source.resolve(strict=True)
    if not binary.is_file() or not source.is_file():
        parser.error("Binary and source must be files")
    scratch = ROOT / ".work"
    if not str(scratch).isascii():
        parser.error("Diagnostics require an ASCII path to the prototype directory")
    scratch.mkdir(exist_ok=True)
    report = {
        "diagnostic_only": True,
        "note": "Separate path controls; they replace neither the smoke test nor its failure status.",
        "host": {"os": platform.system(), "release": platform.release(),
                 "architecture": platform.machine()},
        "environment_difference": {
            "common": {"LANG": "C", "LC_ALL": "C"},
            "packed": {"PATH": "", "PERL5LIB": None},
            "source": {"PATH": "inherited build-host PATH for interpreter libraries",
                       "PERL5LIB": os.environ.get("PERL5LIB")},
        },
        "results": [],
    }
    with tempfile.TemporaryDirectory(prefix="path-controls-", dir=scratch) as temporary:
        work = Path(temporary)
        target = work / ("probe.exe" if os.name == "nt" else "probe")
        shutil.copy2(binary, target)
        content = "Grüße 雪.\n"
        expected = {"ok": True, "skills": [{"name": "control", "body": content}]}
        for label, directory in (("ascii", "ascii"), ("umlaut", "Grüße"), ("cjk", "技能")):
            fixture = work / directory / "SKILL.md"
            fixture.parent.mkdir()
            fixture.write_bytes(content.encode("utf-8"))
            payload = json.dumps({"skills": [{"name": "control", "path": str(fixture)}]},
                                 ensure_ascii=False).encode("utf-8")
            for mode, command in (("source", [perl, str(source)]), ("packed", [str(target)])):
                cache = work / ("cache-" + label + "-" + mode)
                cache.mkdir()
                env = {"PATH": "", "HOME": str(work), "PAR_GLOBAL_TEMP": str(cache),
                       "TMPDIR": str(work), "TMP": str(work), "TEMP": str(work),
                       "LANG": "C", "LC_ALL": "C"}
                for key in ("SystemRoot", "WINDIR"):
                    if key in os.environ:
                        env[key] = os.environ[key]
                if mode == "source":
                    # Only the source requires the build interpreter and its dependencies.
                    env["PATH"] = os.environ.get("PATH", "")
                    if "PERL5LIB" in os.environ:
                        env["PERL5LIB"] = os.environ["PERL5LIB"]
                result = subprocess.run(command, input=payload, capture_output=True,
                                        env=env, cwd=work, timeout=60)
                try:
                    matches = json.loads(result.stdout.decode("utf-8")) == expected
                except (UnicodeError, ValueError):
                    matches = False
                report["results"].append({
                    "case": label, "mode": mode, "command": command, "fixture": str(fixture),
                    "PAR_GLOBAL_TEMP": str(cache),
                    "check": "PASS" if result.returncode == 0 and not result.stderr and matches else "FAIL",
                    "exit_code": result.returncode,
                    "stdout": result.stdout.decode("utf-8", errors="replace"),
                    "stderr": result.stderr.decode("utf-8", errors="replace"),
                    "stdout_hex": result.stdout.hex(), "stderr_hex": result.stderr.hex(),
                })
    # Control failures are findings, not infrastructure failures; the latter are not caught.
    report["diagnostic_status"] = "completed"
    text = json.dumps(report, indent=2, ensure_ascii=True) + "\n"
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(text, encoding="utf-8")
    print(text, end="")


if __name__ == "__main__":
    main()
