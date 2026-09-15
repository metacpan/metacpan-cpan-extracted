#!/usr/bin/env python3
"""
tools/scripts/bump_version.py
Version verification and bump automation for libhisto and all subpackages.
"""

import argparse
import os
import re
import subprocess
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# File locations
VERSION_H = os.path.join(REPO_ROOT, "include", "histo", "version.h")
CMAKELIST_ROOT = os.path.join(REPO_ROOT, "CMakeLists.txt")
PYPROJECT_TOML = os.path.join(REPO_ROOT, "bindings", "python", "pyproject.toml")
NODE_PACKAGE_JSON = os.path.join(REPO_ROOT, "bindings", "node", "package.json")
CHANGELOG_MD = os.path.join(REPO_ROOT, "CHANGELOG.md")
PERL_CHANGES_FILES = {
    "Alien-libhisto": (
        os.path.join(REPO_ROOT, "bindings", "perl", "Alien-libhisto", "Changes"),
        "perl-alien-libhisto-v",
    ),
    "Math-Histo": (
        os.path.join(REPO_ROOT, "bindings", "perl", "Math-Histo", "Changes"),
        "perl-math-histo-v",
    ),
    "Math-Histo-PDL": (
        os.path.join(REPO_ROOT, "bindings", "perl", "Math-Histo-PDL", "Changes"),
        "perl-math-histo-pdl-v",
    ),
}
PERL_MATH_HISTO = os.path.join(REPO_ROOT, "bindings", "perl", "Math-Histo", "lib", "Math", "Histo.pm")
PERL_ALIEN_HISTO = os.path.join(REPO_ROOT, "bindings", "perl", "Alien-libhisto", "lib", "Alien", "libhisto.pm")
PERL_MATH_HISTO_PDL = os.path.join(REPO_ROOT, "bindings", "perl", "Math-Histo-PDL", "lib", "Math", "Histo", "PDL.pm")


def get_core_version():
    with open(VERSION_H, "r", encoding="utf-8") as f:
        content = f.read()
    major = re.search(r"#define\s+HISTO_VERSION_MAJOR\s+(\d+)", content)
    minor = re.search(r"#define\s+HISTO_VERSION_MINOR\s+(\d+)", content)
    patch = re.search(r"#define\s+HISTO_VERSION_PATCH\s+(\d+)", content)
    if not (major and minor and patch):
        raise ValueError("Could not parse version from include/histo/version.h")
    return f"{major.group(1)}.{minor.group(1)}.{patch.group(1)}"


def check_all_versions():
    core_ver = get_core_version()
    print(f"Core libhisto C version: {core_ver}")
    status = True

    # 1. CMakeLists.txt
    with open(CMAKELIST_ROOT, "r", encoding="utf-8") as f:
        cmake_content = f.read()
    m = re.search(r"project\s*\(\s*libhisto\s+VERSION\s+([\d\.]+)", cmake_content)
    if m:
        cmake_ver = m.group(1)
        if cmake_ver != core_ver:
            print(f"[FAIL] CMakeLists.txt version ({cmake_ver}) does not match core ({core_ver})")
            status = False
        else:
            print(f"[OK] CMakeLists.txt: {cmake_ver}")
    else:
        print("[FAIL] Could not find project(libhisto VERSION ...) in CMakeLists.txt")
        status = False

    # 2. Python bindings (pyproject.toml)
    with open(PYPROJECT_TOML, "r", encoding="utf-8") as f:
        py_toml = f.read()
    m = re.search(r'version\s*=\s*"([^"]+)"', py_toml)
    if m:
        py_ver = m.group(1)
        print(f"[OK] Python pyproject.toml: {py_ver} (histo.__version__ dynamically linked to C version.h)")
    else:
        print("[FAIL] Could not find version in pyproject.toml")
        status = False

    # 3. Node.js bindings (package.json)
    if os.path.exists(NODE_PACKAGE_JSON):
        with open(NODE_PACKAGE_JSON, "r", encoding="utf-8") as f:
            node_pkg = f.read()
        m = re.search(r'"version"\s*:\s*"([^"]+)"', node_pkg)
        if m:
            node_ver = m.group(1)
            if node_ver != core_ver:
                print(f"[FAIL] Node.js package.json version ({node_ver}) does not match core ({core_ver})")
                status = False
            else:
                print(f"[OK] Node.js package.json: {node_ver}")
        else:
            print("[FAIL] Could not find version in bindings/node/package.json")
            status = False

    # 3. Perl bindings
    perl_pm_files = []
    for root, _, files in os.walk(os.path.join(REPO_ROOT, "bindings", "perl")):
        if "bundled" in root or "_alien" in root or "blib" in root or ".git" in root:
            continue
        for f in files:
            if f.endswith(".pm"):
                perl_pm_files.append(os.path.join(root, f))

    perl_pm_files.sort()
    for pm_path in perl_pm_files:
        rel_path = os.path.relpath(pm_path, REPO_ROOT)
        with open(pm_path, "r", encoding="utf-8") as f:
            perl_content = f.read()
        m = re.search(r'our\s+\$VERSION\s*=\s*[\'"]([^\'"]+)[\'"]', perl_content)
        if m:
            perl_ver = m.group(1)
            p_parts = perl_ver.split(".")
            c_parts = core_ver.split(".")
            if len(p_parts) == 3 and len(c_parts) == 3 and (p_parts[0], p_parts[1]) == (c_parts[0], c_parts[1]):
                print(f"[OK] {rel_path}: {perl_ver} (aligned with core {c_parts[0]}.{c_parts[1]}.x)")
            else:
                print(f"[FAIL] {rel_path} version ({perl_ver}) does not share major.minor with core ({core_ver})")
                status = False
        else:
            print(f"[FAIL] Could not find $VERSION in {rel_path}")
            status = False

    # 4. Changelog History Preservation Verification
    if not check_changelogs():
        status = False

    return status


def parse_semver_tuple(v_str):
    m = re.match(r"^v?(\d+)\.(\d+)(?:\.(\d+))?", v_str)
    if not m:
        return (0, 0, 0)
    return (int(m.group(1)), int(m.group(2)), int(m.group(3) or 0))


def get_git_tags():
    try:
        res = subprocess.run(
            ["git", "tag", "-l"],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        return [t.strip() for t in res.stdout.splitlines() if t.strip()]
    except Exception:
        return []


def check_changelogs():
    status = True
    git_tags = get_git_tags()

    # 1. Root CHANGELOG.md
    if not os.path.exists(CHANGELOG_MD):
        print(f"[FAIL] Missing {CHANGELOG_MD}")
        return False

    with open(CHANGELOG_MD, "r", encoding="utf-8") as f:
        changelog_content = f.read()

    core_changelog_versions = re.findall(r"^##\s+\[(\d+\.\d+(?:\.\d+)?)\]", changelog_content, re.MULTILINE)
    if not core_changelog_versions:
        print("[FAIL] No version entries found in CHANGELOG.md")
        status = False
    else:
        parsed = [parse_semver_tuple(v) for v in core_changelog_versions]
        if parsed != sorted(parsed, reverse=True):
            print(f"[FAIL] CHANGELOG.md versions are not in descending order: {core_changelog_versions}")
            status = False

        core_tags = [t[1:] for t in git_tags if re.match(r"^v\d+\.\d+\.\d+$", t)]
        for tag_ver in core_tags:
            if tag_ver not in core_changelog_versions:
                print(f"[FAIL] Released tag v{tag_ver} is missing from CHANGELOG.md! Historical changelogs must NEVER be deleted.")
                status = False
        if status:
            print(f"[OK] CHANGELOG.md: {len(core_changelog_versions)} versions tracked in descending order (history intact)")

    # 2. Perl CPAN Changes files
    for dist_name, (changes_path, tag_prefix) in PERL_CHANGES_FILES.items():
        rel_path = os.path.relpath(changes_path, REPO_ROOT)
        if not os.path.exists(changes_path):
            print(f"[FAIL] Missing {rel_path}")
            status = False
            continue

        with open(changes_path, "r", encoding="utf-8") as f:
            changes_content = f.read()

        changes_versions = re.findall(r"^(\d+\.\d+(?:\.\d+)?)\s+\d{4}-\d{2}-\d{2}", changes_content, re.MULTILINE)
        if not changes_versions:
            print(f"[FAIL] No version entries found in {rel_path}")
            status = False
            continue

        parsed = [parse_semver_tuple(v) for v in changes_versions]
        if parsed != sorted(parsed, reverse=True):
            print(f"[FAIL] {rel_path} versions are not in descending order: {changes_versions}")
            status = False

        dist_tags = [t[len(tag_prefix):] for t in git_tags if t.startswith(tag_prefix)]
        for tag_ver in dist_tags:
            if tag_ver not in changes_versions:
                print(f"[FAIL] Released tag {tag_prefix}{tag_ver} is missing from {rel_path}! Historical changelogs must NEVER be deleted.")
                status = False

        if status:
            print(f"[OK] {rel_path}: {len(changes_versions)} releases tracked in descending order (history intact)")

    return status


def set_perl_version(dist_name, new_version):
    parts = new_version.split(".")
    if len(parts) != 3 or not all(p.isdigit() for p in parts):
        raise ValueError(f"Version must be in MAJOR.MINOR.PATCH format, got: {new_version}")

    dist_dir = os.path.join(REPO_ROOT, "bindings", "perl", dist_name)
    if not os.path.isdir(dist_dir):
        raise ValueError(f"Unknown Perl distribution directory: {dist_dir}")

    print(f"Setting Perl distribution {dist_name} version to: {new_version}")
    for root, _, files in os.walk(dist_dir):
        if "bundled" in root or "_alien" in root or "blib" in root or ".git" in root:
            continue
        for f in files:
            if f.endswith(".pm"):
                pm_path = os.path.join(root, f)
                rel_path = os.path.relpath(pm_path, REPO_ROOT)
                with open(pm_path, "r", encoding="utf-8") as fh:
                    content = fh.read()
                content = re.sub(r'(our\s+\$VERSION\s*=\s*[\'"])[^\'"]+([\'"])', rf"\g<1>{new_version}\g<2>", content)
                with open(pm_path, "w", encoding="utf-8") as fh:
                    fh.write(content)
                print(f"[UPDATED] {rel_path}")


def set_version(new_version):
    parts = new_version.split(".")
    if len(parts) != 3 or not all(p.isdigit() for p in parts):
        raise ValueError(f"Version must be in MAJOR.MINOR.PATCH format, got: {new_version}")
    major, minor, patch = parts

    print(f"Setting unified version to: {new_version}")

    # 1. include/histo/version.h
    with open(VERSION_H, "r", encoding="utf-8") as f:
        content = f.read()
    content = re.sub(r"(#define\s+HISTO_VERSION_MAJOR\s+)\d+", rf"\g<1>{major}", content)
    content = re.sub(r"(#define\s+HISTO_VERSION_MINOR\s+)\d+", rf"\g<1>{minor}", content)
    content = re.sub(r"(#define\s+HISTO_VERSION_PATCH\s+)\d+", rf"\g<1>{patch}", content)
    content = re.sub(r'(#define\s+HISTO_VERSION_STRING\s+)"[^"]+"', rf'\g<1>"{new_version}"', content)
    with open(VERSION_H, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"[UPDATED] {VERSION_H}")

    # 2. CMakeLists.txt
    with open(CMAKELIST_ROOT, "r", encoding="utf-8") as f:
        content = f.read()
    content = re.sub(r"(project\s*\(\s*libhisto\s+VERSION\s+)[\d\.]+", rf"\g<1>{new_version}", content)
    with open(CMAKELIST_ROOT, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"[UPDATED] {CMAKELIST_ROOT}")

    # 3. Python pyproject.toml
    with open(PYPROJECT_TOML, "r", encoding="utf-8") as f:
        content = f.read()
    content = re.sub(r'(version\s*=\s*)"[^"]+"', rf'\g<1>"{new_version}"', content)
    with open(PYPROJECT_TOML, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"[UPDATED] {PYPROJECT_TOML}")

    # 4. Node.js package.json
    if os.path.exists(NODE_PACKAGE_JSON):
        with open(NODE_PACKAGE_JSON, "r", encoding="utf-8") as f:
            content = f.read()
        content = re.sub(r'("version"\s*:\s*)"[^"]+"', rf'\g<1>"{new_version}"', content)
        with open(NODE_PACKAGE_JSON, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"[UPDATED] {NODE_PACKAGE_JSON}")

    # 5. Perl bindings
    perl_pm_files = []
    for root, _, files in os.walk(os.path.join(REPO_ROOT, "bindings", "perl")):
        if "bundled" in root or "_alien" in root or "blib" in root or ".git" in root:
            continue
        for f in files:
            if f.endswith(".pm"):
                perl_pm_files.append(os.path.join(root, f))

    perl_pm_files.sort()
    for pm_path in perl_pm_files:
        rel_path = os.path.relpath(pm_path, REPO_ROOT)
        with open(pm_path, "r", encoding="utf-8") as f:
            content = f.read()
        content = re.sub(r'(our\s+\$VERSION\s*=\s*[\'"])[^\'"]+([\'"])', rf"\g<1>{new_version}\g<2>", content)
        with open(pm_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"[UPDATED] {rel_path}")


def main():
    parser = argparse.ArgumentParser(description="Version verification and bump tool for libhisto.")
    parser.add_argument("--check", action="store_true", help="Check and print all component versions.")
    parser.add_argument("--set", type=str, metavar="X.Y.Z", help="Set new version across all components.")
    parser.add_argument("--set-perl", nargs=2, metavar=("DIST", "X.Y.Z"), help="Set version for a specific Perl distribution (e.g. Math-Histo 0.2.1).")
    args = parser.parse_args()

    if args.set:
        set_version(args.set)
        check_all_versions()
    elif args.set_perl:
        set_perl_version(args.set_perl[0], args.set_perl[1])
        check_all_versions()
    else:
        success = check_all_versions()
        sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
