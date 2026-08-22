#!/usr/bin/env python3
"""
tools/scripts/bump_version.py
Version verification and bump automation for libhisto and all subpackages.
"""

import argparse
import os
import re
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# File locations
VERSION_H = os.path.join(REPO_ROOT, "include", "histo", "version.h")
CMAKELIST_ROOT = os.path.join(REPO_ROOT, "CMakeLists.txt")
PYPROJECT_TOML = os.path.join(REPO_ROOT, "bindings", "python", "pyproject.toml")
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
            if perl_ver != core_ver:
                print(f"[FAIL] {rel_path} version ({perl_ver}) does not match core ({core_ver})")
                status = False
            else:
                print(f"[OK] {rel_path}: {perl_ver}")
        else:
            print(f"[FAIL] Could not find $VERSION in {rel_path}")
            status = False

    return status


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

    # 4. Perl bindings
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
    args = parser.parse_args()

    if args.set:
        set_version(args.set)
        check_all_versions()
    else:
        success = check_all_versions()
        sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
