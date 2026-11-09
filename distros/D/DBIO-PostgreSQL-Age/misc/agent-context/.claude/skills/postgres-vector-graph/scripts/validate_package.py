#!/usr/bin/env python3
"""Offline package structure/hash validator. Does not execute or parse SQL/Cypher."""
from __future__ import annotations

import argparse
import ast
import hashlib
import json
import re
from pathlib import Path
from urllib.parse import unquote, urlsplit

IGNORED_PARTS = {"__pycache__", ".git", ".pytest_cache"}


def package_files(root: Path) -> list[Path]:
    return sorted(p for p in root.rglob("*") if p.is_file()
                  and not (set(p.relative_to(root).parts) & IGNORED_PARTS)
                  and p.suffix != ".pyc")


def anchors(text: str) -> set[str]:
    result: set[str] = set()
    for heading in re.findall(r"^#{1,6}\s+(.+?)\s*#*\s*$", text, re.MULTILINE):
        result.add(re.sub(r"[^\w\- ]", "", heading.lower()).replace(" ", "-"))
    return result


def local_link_errors(root: Path, path: Path) -> list[str]:
    errors: list[str] = []
    text = path.read_text(encoding="utf-8")
    for target in re.findall(r"(?<!!)\[[^\]]*\]\(([^)]+)\)", text):
        target = target.split(' "', 1)[0].strip("<>")
        parts = urlsplit(target)
        if parts.scheme or parts.netloc:
            continue
        destination = (path.parent / unquote(parts.path)).resolve() if parts.path else path
        if not destination.is_relative_to(root.resolve()):
            errors.append(f"{path.relative_to(root)}: link escapes package: {target}")
        elif not destination.is_file():
            errors.append(f"{path.relative_to(root)}: missing local file: {target}")
        elif parts.fragment and destination.suffix == ".md":
            if unquote(parts.fragment) not in anchors(destination.read_text(encoding="utf-8")):
                errors.append(f"{path.relative_to(root)}: missing heading anchor: {target}")
    return errors


def validate(root: Path, require_manifest: bool = True) -> list[str]:
    root = root.resolve()
    errors: list[str] = []
    required = ["SKILL.md", "README.md", "LICENSE", "THIRD_PARTY.md", "VALIDATION.md",
                "dependencies.json", "sources.json", "references/INDEX.md", "tests/scenarios.json"]
    for name in required:
        if not (root/name).is_file():
            errors.append(f"Missing required file: {name}")
    if (root/"SKILL.md").is_file():
        skill = (root/"SKILL.md").read_text(encoding="utf-8")
        if not skill.startswith("---\n") or "\n---\n" not in skill[4:]:
            errors.append("SKILL.md lacks delimited frontmatter")
        if not re.search(r"^name: postgres-vector-graph$", skill, re.MULTILINE):
            errors.append("Skill name does not match the package directory contract")
        if not re.search(r"^description:", skill, re.MULTILINE):
            errors.append("Missing skill description")
        if len(skill.split()) > 1800:
            errors.append("SKILL.md exceeds this package's 1800-word routing budget")
    files = package_files(root)
    for path in files:
        try:
            if path.suffix == ".md":
                errors.extend(local_link_errors(root, path))
                if "references" in path.relative_to(root).parts and len(path.read_text(encoding="utf-8").split()) > 1400:
                    errors.append(f"Reference exceeds 1400-word per-file budget: {path.relative_to(root)}")
            elif path.suffix == ".py":
                ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
            elif path.suffix == ".json":
                json.loads(path.read_text(encoding="utf-8"))
        except (SyntaxError, UnicodeError, ValueError) as exc:
            errors.append(f"{path.relative_to(root)}: parse/read error: {exc}")
    if (root/"dependencies.json").is_file():
        deps = json.loads((root/"dependencies.json").read_text(encoding="utf-8"))
        if deps.get("automatic_resolution") is not False or deps.get("vendored") is not False:
            errors.append("Dependency manifest contradicts the no-auto-install/no-vendoring contract")
        if deps.get("profiles", {}).get("standalone", {}).get("required") != []:
            errors.append("Standalone profile must not require companion skills")
        for companion in deps.get("companions", []):
            if not re.fullmatch(r"[0-9a-f]{40}", companion.get("reviewed_commit", "")):
                errors.append(f"Companion lacks a full reviewed commit: {companion.get('id')}")
    manifest_path = root/"MANIFEST.json"
    if require_manifest and not manifest_path.is_file():
        errors.append("Missing MANIFEST.json")
    if require_manifest and manifest_path.is_file():
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        records = manifest.get("files", [])
        listed = [entry["path"] for entry in records]
        actual = {p.relative_to(root).as_posix() for p in files if p != manifest_path}
        if len(listed) != len(set(listed)) or set(listed) != actual:
            errors.append("Manifest file set does not match the package")
        for entry in records:
            path = (root/entry["path"]).resolve()
            if not path.is_relative_to(root) or not path.is_file():
                errors.append(f"Invalid manifest path: {entry['path']}")
                continue
            data = path.read_bytes()
            if len(data) != entry["bytes"] or hashlib.sha256(data).hexdigest() != entry["sha256"]:
                errors.append(f"Manifest hash/size mismatch: {entry['path']}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--without-manifest", action="store_true", help="Authoring-time check only")
    args = parser.parse_args()
    errors = validate(args.root, require_manifest=not args.without_manifest)
    if errors:
        print("FAIL\n" + "\n".join(errors))
        return 1
    print("PASS: local links/anchors, routing budgets, Python AST, JSON, dependency policy"
          + (", and manifest hashes." if not args.without_manifest else ". Manifest not checked."))
    print("No database, SQL/Cypher execution, external URL checks, or performance testing performed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
