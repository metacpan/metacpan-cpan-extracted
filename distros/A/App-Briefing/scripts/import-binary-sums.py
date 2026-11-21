#!/usr/bin/env python3
"""Import one release's binary SHA-256 checksums as canonical pins."""

import argparse
import os
import re
import sys
import tempfile
from pathlib import Path
from typing import Dict, Optional, Sequence, Tuple


_HASH_LINE = re.compile(r"^([0-9A-Fa-f]{64})[ \t]+\*?([^ \t\r\n]+)$")
_VERSION_TOKEN = re.compile(r"[A-Za-z0-9][A-Za-z0-9._+-]*")


class _ArgumentParser(argparse.ArgumentParser):
    """Report argument errors through main's one-line error contract."""

    def error(self, message: str) -> None:
        raise ValueError(message)


def _expected_assets(version: str) -> Tuple[str, ...]:
    """Return the release asset names in their canonical output order."""
    prefix = "briefing-{}-".format(version)
    return (
        prefix + "linux-x86_64",
        prefix + "linux-arm64",
        prefix + "macos-x86_64",
        prefix + "macos-arm64",
        prefix + "windows-x86_64.exe",
    )


def _parse_sums(contents: bytes, expected_assets: Tuple[str, ...]) -> Dict[str, str]:
    """Validate SHA256SUMS contents and return hashes indexed by asset name."""
    try:
        text = contents.decode("ascii")
    except UnicodeDecodeError as error:
        raise ValueError("SHA256SUMS must be ASCII") from error

    entries: Dict[str, str] = {}
    expected = set(expected_assets)
    for line in text.splitlines():
        match = _HASH_LINE.fullmatch(line)
        if match is None:
            raise ValueError("malformed SHA256SUMS entry")

        digest, asset = match.groups()
        if asset not in expected or asset in entries:
            raise ValueError("unexpected SHA256SUMS entry")
        entries[asset] = digest.lower()

    if set(entries) != expected:
        raise ValueError("incomplete SHA256SUMS entries")

    return entries


def _canonical_contents(entries: Dict[str, str], expected_assets: Tuple[str, ...]) -> bytes:
    """Render the validated checksum entries as canonical ASCII pins."""
    return "".join(
        "{}  {}\n".format(entries[asset], asset) for asset in expected_assets
    ).encode("ascii")


def _write_output(output_path: Path, contents: bytes) -> None:
    """Write contents beside output_path, then atomically replace it."""
    descriptor: Optional[int] = None
    temporary_path: Optional[str] = None
    try:
        descriptor, temporary_path = tempfile.mkstemp(
            prefix=".briefing-binaries-", dir=str(output_path.parent)
        )
        with os.fdopen(descriptor, "wb") as temporary_file:
            descriptor = None
            temporary_file.write(contents)
            temporary_file.flush()
            os.fsync(temporary_file.fileno())
        os.replace(temporary_path, output_path)
        temporary_path = None
    finally:
        if descriptor is not None:
            os.close(descriptor)
        if temporary_path is not None:
            try:
                os.unlink(temporary_path)
            except FileNotFoundError:
                pass


def _parser() -> argparse.ArgumentParser:
    parser = _ArgumentParser(
        description="Import release binary SHA-256 checksums as canonical pins."
    )
    parser.add_argument("--version", required=True, help="expected release version")
    parser.add_argument("--input", required=True, help="path to release SHA256SUMS")
    parser.add_argument("--output", required=True, help="path for canonical pin file")
    return parser


def _error(message: str) -> int:
    sys.stderr.write("error: {}\n".format(message))
    return 2


def main(argv: Optional[Sequence[str]] = None) -> int:
    """Import a release SHA256SUMS file and return a process status."""
    try:
        arguments = _parser().parse_args(argv)
    except ValueError:
        return _error("invalid arguments")
    except SystemExit as error:
        return int(error.code)

    if not arguments.version or _VERSION_TOKEN.fullmatch(arguments.version) is None:
        return _error("invalid arguments")

    try:
        input_contents = Path(arguments.input).read_bytes()
    except OSError:
        return _error("unable to read input")

    expected_assets = _expected_assets(arguments.version)
    try:
        entries = _parse_sums(input_contents, expected_assets)
    except ValueError:
        return _error("invalid SHA256SUMS")

    try:
        _write_output(Path(arguments.output), _canonical_contents(entries, expected_assets))
    except OSError:
        return _error("unable to write output")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
