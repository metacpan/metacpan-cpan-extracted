#!/usr/bin/env python3
"""Native pp build only: Python and Perl are required on the BUILD HOST, not at runtime."""
import argparse
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parent

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--perl", default="perl")
args = parser.parse_args()
perl = shutil.which(args.perl)
if not perl:
    parser.error("Perl not found on BUILD host")
build = ROOT / "build"
build.mkdir(exist_ok=True)
output = build / ("probe.exe" if os.name == "nt" else "probe")
env = os.environ.copy()
env["PAR_VERBATIM"] = "1"  # As in skilletor: do not use pp's filter that removes POD.
env["PAR_GLOBAL_TEMP"] = str(build / "pack-cache")
versions = subprocess.check_output([
    perl, "-MJSON::PP", "-MPAR::Packer", "-MPath::Tiny", "-MConfig", "-e",
    'print JSON::PP->new->canonical->encode({perl=>"$^V", '
    'pp=>$PAR::Packer::VERSION, path_tiny=>$Path::Tiny::VERSION, '
    'arch=>$Config{archname}})',
], env=env, text=True)
command = [perl, "-Mpp", "-e", "pp->go()", "--", "-o", str(output), str(ROOT / "probe.pl")]
start = time.perf_counter()
subprocess.run(command, cwd=ROOT, env=env, check=True)
report = {"command": command, "environment": {"PAR_VERBATIM": "1", "PAR_GLOBAL_TEMP": env["PAR_GLOBAL_TEMP"]},
          "versions": json.loads(versions), "host": {"os": platform.system(), "arch": platform.machine()},
          "seconds": round(time.perf_counter() - start, 3), "bytes": output.stat().st_size}
text = json.dumps(report, indent=2) + "\n"
(build / "build.json").write_text(text, encoding="utf-8")
print(text, end="")
