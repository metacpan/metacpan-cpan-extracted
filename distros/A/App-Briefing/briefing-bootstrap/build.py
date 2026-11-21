#!/usr/bin/env python3
"""Build briefing-bootstrap.exe reproducibly.

    python3 briefing-bootstrap/build.py OUT.exe [--target TARGET] [--src SOURCE]

The build requires the ziglang==0.13.0.post1 Python package and Zig 0.13.0.
The linker timestamp is cleared after validating the PE output.
"""

import argparse
import struct
import subprocess
import sys
from importlib import metadata
from pathlib import Path


ZIG_PACKAGE = "0.13.0.post1"
ZIG_COMPILER = "0.13.0"
DEFAULT_TARGET = "x86_64-windows-gnu"
NATIVE_LIBRARIES = ("-lwinhttp", "-lbcrypt", "-ladvapi32")


def arguments(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, metavar="OUT.exe")
    parser.add_argument("--target", default=DEFAULT_TARGET)
    parser.add_argument(
        "--src",
        type=Path,
        default=Path(__file__).with_name("briefing-bootstrap.c"),
        metavar="SOURCE",
    )
    return parser.parse_args(argv)


def require_ziglang():
    try:
        package_version = metadata.version("ziglang")
    except metadata.PackageNotFoundError:
        raise SystemExit(
            "build.py: ziglang==%s is required" % ZIG_PACKAGE
        )
    if package_version != ZIG_PACKAGE:
        raise SystemExit(
            "build.py: ziglang==%s required, found %s"
            % (ZIG_PACKAGE, package_version)
        )

    compiler_version = subprocess.run(
        [sys.executable, "-m", "ziglang", "version"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    ).stdout.strip()
    if compiler_version != ZIG_COMPILER:
        raise SystemExit(
            "build.py: zig %s required, found %s"
            % (ZIG_COMPILER, compiler_version)
        )


def clear_coff_timestamp(output):
    data = bytearray(output.read_bytes())
    if len(data) < 0x40 or data[:2] != b"MZ":
        raise SystemExit("build.py: output is not a PE file")
    pe_offset = struct.unpack_from("<I", data, 0x3C)[0]
    if pe_offset < 0x40 or pe_offset + 24 > len(data):
        raise SystemExit("build.py: output has an invalid PE header")
    if data[pe_offset:pe_offset + 4] != b"PE\0\0":
        raise SystemExit("build.py: output is not a PE file")
    struct.pack_into("<I", data, pe_offset + 8, 0)
    output.write_bytes(data)


def main(argv):
    options = arguments(argv)
    if not options.src.is_file():
        raise SystemExit("build.py: source does not exist: %s" % options.src)

    require_ziglang()
    subprocess.run(
        [
            sys.executable,
            "-m",
            "ziglang",
            "cc",
            "-target",
            options.target,
            "-Os",
            "-s",
            "-municode",
            "-o",
            str(options.output),
            str(options.src),
            *NATIVE_LIBRARIES,
        ],
        check=True,
    )
    clear_coff_timestamp(options.output)
    for artifact in (options.output.with_suffix(".pdb"), options.output.with_suffix(".lib")):
        artifact.unlink(missing_ok=True)


if __name__ == "__main__":
    main(sys.argv[1:])
