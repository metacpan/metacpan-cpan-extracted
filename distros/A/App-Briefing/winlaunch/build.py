#!/usr/bin/env python3
"""Build winlaunch.exe reproducibly.

    python3 build.py OUT.exe [--target x86_64-windows-gnu] [--src mcpoff.c]

Needs the ziglang package (pip install ziglang==0.13.0.post1). zig's linker
stamps the link time into the PE header; that field is zeroed afterwards so
the same source gives the same bytes on every host.
"""
import struct
import subprocess
import sys
from pathlib import Path

ZIG = "0.13.0"


def main(argv):
    if not argv or argv[0].startswith("-"):
        sys.exit(__doc__)
    out = Path(argv[0])
    target = argv[argv.index("--target") + 1] if "--target" in argv else "x86_64-windows-gnu"
    src = Path(__file__).with_name(argv[argv.index("--src") + 1] if "--src" in argv else "winlaunch.c")

    version = subprocess.run([sys.executable, "-m", "ziglang", "version"],
                             capture_output=True, text=True, check=True).stdout.strip()
    if version != ZIG:
        sys.exit(f"build.py: zig {ZIG} required, found {version}")

    subprocess.run([sys.executable, "-m", "ziglang", "cc", "-target", target,
                    "-Os", "-s", "-o", str(out), str(src)], check=True)

    data = bytearray(out.read_bytes())
    pe = struct.unpack_from("<I", data, 0x3C)[0]
    if data[pe:pe + 4] != b"PE\0\0":
        sys.exit("build.py: output is not a PE file")
    struct.pack_into("<I", data, pe + 8, 0)  # COFF TimeDateStamp
    for name in (out.with_suffix(".pdb"), out.with_suffix(".lib")):
        name.unlink(missing_ok=True)
    out.write_bytes(bytes(data))


if __name__ == "__main__":
    main(sys.argv[1:])
