#!/usr/bin/env python3
"""
test_container.py - Multi-architecture and cross-platform container test runner for libhisto.

Automates building and testing libhisto across diverse CPU architectures (ARM64, s390x Big-Endian,
RISC-V, ARMv7, 32-bit x86) and C standard libraries (musl libc vs glibc) using Docker or Podman
with QEMU binfmt emulation and native host multilib.
"""

import argparse
import os
import platform
import shlex
import shutil
import subprocess
import sys
import time
from pathlib import Path

TARGETS = {
    "hermetic": {
        "description": "Minimal Hermetic Core C Environment (Debian x86_64, ISO C99 toolchain, zero interpreters)",
        "image": "debian:bookworm-slim",
        "platform": "linux/amd64",
        "install_cmd": "apt-get update -qq && apt-get install -y -qq --no-install-recommends gcc libc6-dev make cmake",
        "install_full_cmd": "apt-get update -qq && apt-get install -y -qq --no-install-recommends gcc libc6-dev make cmake",
        "arch": "x86_64",
        "endian": "little",
        "bits": 64,
        "cmake_flags": "-DLIBHISTO_BUILD_TOOLS=OFF -DLIBHISTO_BUILD_BENCHMARKS=OFF -DLIBHISTO_BUILD_EXAMPLES=OFF -DLIBHISTO_ENABLE_FUZZING=OFF",
    },
    "musl": {
        "description": "Alpine Linux (x86_64, musl libc, strict ISO C99 verification)",
        "image": "alpine:latest",
        "platform": "linux/amd64",
        "install_cmd": "apk add --no-cache build-base cmake bash gdb",
        "install_full_cmd": "apk add --no-cache build-base cmake bash gdb python3 python3-dev py3-setuptools",
        "arch": "x86_64",
        "endian": "little",
        "bits": 64,
    },
    "s390x": {
        "description": "Ubuntu Linux (s390x IBM Z, 64-bit Big-Endian, wire format & byte-swapping)",
        "image": "ubuntu:24.04",
        "platform": "linux/s390x",
        "install_cmd": "apt-get update -qq && apt-get install -y -qq build-essential cmake gdb",
        "install_full_cmd": "apt-get update -qq && apt-get install -y -qq build-essential cmake gdb python3 python3-dev python3-setuptools perl libperl-dev",
        "arch": "s390x",
        "endian": "big",
        "bits": 64,
    },
    "i386": {
        "description": "Debian Linux (i386, 32-bit x86 container, ILP32 data model & size_t limits)",
        "image": "debian:bookworm-slim",
        "platform": "linux/386",
        "install_cmd": "apt-get update -qq && apt-get install -y -qq build-essential cmake gdb",
        "install_full_cmd": "apt-get update -qq && apt-get install -y -qq build-essential cmake gdb python3 python3-dev python3-setuptools perl libperl-dev",
        "arch": "i386",
        "endian": "little",
        "bits": 32,
    },
    "arm64": {
        "description": "Ubuntu Linux (aarch64 / ARM64, ARM NEON SIMD acceleration)",
        "image": "ubuntu:24.04",
        "platform": "linux/arm64",
        "install_cmd": "apt-get update -qq && apt-get install -y -qq build-essential cmake gdb",
        "install_full_cmd": "apt-get update -qq && apt-get install -y -qq build-essential cmake gdb python3 python3-dev python3-setuptools perl libperl-dev",
        "arch": "aarch64",
        "endian": "little",
        "bits": 64,
    },
    "armv7": {
        "description": "Ubuntu Linux (arm32v7 / ARMv7, 32-bit ARM embedded architecture)",
        "image": "ubuntu:24.04",
        "platform": "linux/arm/v7",
        "install_cmd": "apt-get update -qq && apt-get install -y -qq build-essential cmake gdb",
        "install_full_cmd": "apt-get update -qq && apt-get install -y -qq build-essential cmake gdb python3 python3-dev python3-setuptools perl libperl-dev",
        "arch": "armv7l",
        "endian": "little",
        "bits": 32,
    },
    "riscv64": {
        "description": "Ubuntu Linux (riscv64, 64-bit RISC-V portable scalar fallback)",
        "image": "ubuntu:24.04",
        "platform": "linux/riscv64",
        "install_cmd": "apt-get update -qq && apt-get install -y -qq build-essential cmake gdb",
        "install_full_cmd": "apt-get update -qq && apt-get install -y -qq build-essential cmake gdb python3 python3-dev python3-setuptools perl libperl-dev",
        "arch": "riscv64",
        "endian": "little",
        "bits": 64,
    },
    "native-32bit": {
        "description": "Host Native 32-bit x86 (-m32 multilib execution directly on Linux host)",
        "image": None,
        "platform": None,
        "arch": "i686",
        "endian": "little",
        "bits": 32,
    },
}

ALIASES = {
    "alpine": "musl",
    "big-endian": "s390x",
    "bigendian": "s390x",
    "32bit": "i386",
    "x86": "i386",
    "aarch64": "arm64",
    "arm": "armv7",
    "riscv": "riscv64",
    "32bit-native": "native-32bit",
}

ALL_LOCAL_TARGETS = ["hermetic", "musl", "s390x", "i386", "native-32bit", "arm64", "armv7", "riscv64"]

# Flag whether container execution requires "sg docker -c" group elevation
USE_SG_DOCKER = False


def log(msg, color="1;34"):
    if sys.stdout.isatty():
        print(f"\033[{color}m==>\033[0m \033[1m{msg}\033[0m")
    else:
        print(f"==> {msg}")


def log_success(msg):
    log(msg, color="1;32")


def log_error(msg):
    log(msg, color="1;31")


def exec_container_cmd(cmd, **kwargs):
    """Execute container command, applying sg docker elevation if necessary."""
    if USE_SG_DOCKER and cmd[0] == "docker":
        wrapped = ["sg", "docker", "-c", " ".join(shlex.quote(a) for a in cmd)]
        return subprocess.run(wrapped, **kwargs)
    return subprocess.run(cmd, **kwargs)


def test_engine_connectivity(engine):
    """Test if container engine binary exists and can communicate with daemon/socket."""
    if not shutil.which(engine):
        return False, f"'{engine}' binary not found in PATH", False
    try:
        res = subprocess.run(
            [engine, "info"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            text=True,
            timeout=10
        )
        if res.returncode == 0:
            return True, "", False
        if engine == "docker" and shutil.which("sg") and "permission denied" in res.stderr.lower():
            sg_res = subprocess.run(
                ["sg", "docker", "-c", f"{engine} info"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
                text=True,
                timeout=10
            )
            if sg_res.returncode == 0:
                return True, "", True
        return False, res.stderr.strip(), False
    except Exception as e:
        return False, str(e), False


def detect_container_engine(preferred="auto"):
    """Detect an available and working container engine (docker or podman)."""
    global USE_SG_DOCKER
    candidates = ["docker", "podman"] if preferred == "auto" else [preferred]
    errors = {}

    for engine in candidates:
        if shutil.which(engine):
            ok, err, use_sg = test_engine_connectivity(engine)
            if ok:
                USE_SG_DOCKER = use_sg
                return engine
            errors[engine] = err

    # If we reached here, no engine was fully working
    print("\n" + "=" * 70)
    log_error("No working container engine (Docker or Podman) accessible.")
    print("=" * 70)
    for engine, err in errors.items():
        print(f"  * {engine}: {err}")
    print("\nTroubleshooting & Fixes:")
    print("  1. If using Docker: Ensure your user has permission to access the Docker daemon:")
    print("     $ sudo usermod -aG docker $USER")
    print("     (Log out and log back in, or run with 'newgrp docker')")
    print("  2. Or use Podman (rootless by default without daemon permissions):")
    print("     $ sudo apt-get install -y podman   # Debian/Ubuntu")
    print("     $ sudo dnf install -y podman       # Fedora/RHEL")
    print("=" * 70 + "\n")
    return None


def is_foreign_arch(target_arch):
    """Check if target architecture differs from host and requires QEMU emulation."""
    host = platform.machine().lower()
    if host in ["x86_64", "amd64"]:
        return target_arch not in ["x86_64", "i386", "i686"]
    if host in ["aarch64", "arm64"]:
        return target_arch not in ["aarch64", "arm64", "armv7l"]
    return target_arch != host


def ensure_binfmt_registered(engine, targets_to_run):
    """Ensure QEMU binfmt handlers are registered only if running foreign architectures."""
    if platform.system() != "Linux":
        return

    foreign_targets = [
        t for t in targets_to_run
        if TARGETS[t].get("arch") and is_foreign_arch(TARGETS[t]["arch"])
    ]
    if not foreign_targets:
        return

    binfmt_path = Path("/proc/sys/fs/binfmt_misc")
    if binfmt_path.exists():
        entries = list(binfmt_path.iterdir())
        has_qemu = any("qemu-" in e.name for e in entries)
        if has_qemu:
            return

    log("Registering QEMU user-mode binfmt handlers via multiarch/qemu-user-static...")
    try:
        cmd = [engine, "run", "--rm", "--privileged", "multiarch/qemu-user-static", "--reset", "-p", "yes"]
        exec_container_cmd(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    except Exception as e:
        log_error(f"Warning: Failed to auto-register binfmt handlers ({e}). Foreign architectures may fail if not pre-configured.")


def run_native_32bit(repo_root, jobs, build_type="Release", full=False):
    """Run native 32-bit test on host using -m32 flags."""
    build_dir = repo_root / "build-x86_32"
    log(f"Running Host Native 32-bit Build & Test in {build_dir}...")

    cmake_args = [
        "cmake",
        f"-B{build_dir}",
        f"-S{repo_root}",
        f"-DCMAKE_BUILD_TYPE={build_type}",
        "-DCMAKE_C_FLAGS=-m32",
        "-DCMAKE_EXE_LINKER_FLAGS=-m32",
        "-DCMAKE_SHARED_LINKER_FLAGS=-m32",
        "-DCMAKE_MODULE_LINKER_FLAGS=-m32",
    ]

    t0 = time.time()
    try:
        subprocess.run(cmake_args, check=True)
    except subprocess.CalledProcessError as e:
        log_error("Host 32-bit multilib build configuration failed.")
        print("\nTroubleshooting 32-Bit Multilib:")
        print("  Install multilib development packages on your host:")
        print("    $ sudo apt-get install -y gcc-multilib libc6-dev-i386   # Debian/Ubuntu")
        print("    $ sudo dnf install -y glibc-devel.i686 libgcc.i686      # Fedora/RHEL")
        print("    $ sudo pacman -S lib32-glibc lib32-gcc-libs            # Arch Linux")
        print("  Alternatively, run 32-bit tests inside an isolated container:")
        print("    $ make test-32bit\n")
        raise e

    subprocess.run(["cmake", "--build", str(build_dir), f"-j{jobs}"], check=True)
    subprocess.run(["ctest", "--test-dir", str(build_dir), f"-j{jobs}", "--output-on-failure"], check=True)

    elapsed = time.time() - t0
    log_success(f"Host Native 32-bit Test PASSED in {elapsed:.2f}s")
    return True


def run_container_target(repo_root, target_name, config, engine, jobs, build_type="Release", full=False):
    """Run build and test inside a container target with enhanced crash reporting."""
    image = config["image"]
    build_dir_name = f"build-container-{target_name}"
    install_cmd = config["install_full_cmd"] if full else config["install_cmd"]

    effective_jobs = jobs
    if config.get("arch") and is_foreign_arch(config["arch"]):
        max_emulated_jobs = 2 if config.get("arch") in ["s390x", "armv7l"] else 4
        if jobs > max_emulated_jobs:
            effective_jobs = max_emulated_jobs
            log(f"Notice: Clamped parallel concurrency to -j{effective_jobs} for emulated target '{target_name}' (QEMU user-mode stability safeguard).")

    extra_cmake_flags = config.get("cmake_flags", "")
    cmake_config_cmd = f"cmake -B {build_dir_name} -S . -DCMAKE_BUILD_TYPE={build_type}"
    if extra_cmake_flags:
        cmake_config_cmd += f" {extra_cmake_flags}"

    # Ensure stale binding artifacts from earlier targets or aborted runs are cleaned first
    pre_clean_cmd = (
        "rm -rf bindings/python/build bindings/python/histo/*.so "
        "bindings/perl/Alien-libhisto/Makefile bindings/perl/Alien-libhisto/blib "
        "bindings/perl/Alien-libhisto/_Inline bindings/perl/Alien-libhisto/_alien "
        "bindings/perl/Math-Histo/Makefile bindings/perl/Math-Histo/blib "
        "bindings/perl/Math-Histo/_Inline bindings/perl/Math-Histo/*.o "
        "bindings/perl/Math-Histo/*.so 2>/dev/null || true"
    )

    test_commands = [
        "ulimit -c unlimited || true",
        pre_clean_cmd,
        install_cmd,
        cmake_config_cmd,
        f"(cmake --build {build_dir_name} -j{effective_jobs} || cmake --build {build_dir_name} -j1)",
        f"ctest --test-dir {build_dir_name} -j{effective_jobs} --output-on-failure",
    ]

    if full:
        test_commands.append(
            "if command -v python3 >/dev/null 2>&1 && python3 -c 'import setuptools' >/dev/null 2>&1 && [ -f bindings/python/setup.py ]; then "
            "  echo '==> Running Python bindings test in container...' && "
            "  (cd bindings/python && rm -rf build histo/*.so && python3 setup.py build_ext --inplace && PYTHONPATH=. python3 -m unittest discover -s tests -v) && "
            "  (rm -rf bindings/python/build bindings/python/histo/*.so 2>/dev/null || true); "
            "fi"
        )
        test_commands.append(
            "if command -v perl >/dev/null 2>&1 && perl -MAlien::Build::MM -e 1 >/dev/null 2>&1 && perl -MAlien::cmake3 -e 1 >/dev/null 2>&1 && [ -f bindings/perl/Alien-libhisto/Makefile.PL ]; then "
            "  echo '==> Running Perl bindings test in container...' && "
            "  (cd bindings/perl/Alien-libhisto && perl Makefile.PL && make && make test && (make realclean 2>/dev/null || true)) && "
            "  (cd bindings/perl/Math-Histo && perl Makefile.PL && make && make test && (make realclean 2>/dev/null || true)); "
            "fi"
        )

    # Post-clean and restore ownership to host user so zero root-owned artifacts remain
    post_chown_cmd = f"chown -R {os.getuid()}:{os.getgid()} /workspace 2>/dev/null || true"
    test_commands.append(pre_clean_cmd)
    test_commands.append(post_chown_cmd)

    container_script = " && ".join(test_commands)

    docker_cmd = [
        engine,
        "run",
        "--rm",
        "--ulimit", "core=-1",
        "-e", "DEBIAN_FRONTEND=noninteractive",
    ]
    if config.get("platform"):
        docker_cmd.extend(["--platform", config["platform"]])
    docker_cmd.extend([
        "-v", f"{repo_root}:/workspace",
        "-w", "/workspace",
        image,
        "sh", "-c", container_script,
    ])

    log(f"Starting target '{target_name}' [{config['description']}] using {engine} ({image})...")
    t0 = time.time()
    try:
        exec_container_cmd(docker_cmd, check=True)
    except subprocess.CalledProcessError as err:
        elapsed = time.time() - t0
        log_error(f"Target '{target_name}' FAILED with exit code {err.returncode} after {elapsed:.2f}s.")

        if err.returncode in [139, 134, 132, 136, 2, 1]:
            sig_name = {139: "SIGSEGV (Segmentation Fault)", 134: "SIGABRT (Abort)", 132: "SIGILL (Illegal Instruction)", 136: "SIGFPE (Floating Point Exception)"}.get(err.returncode, f"Error {err.returncode}")
            print("\n" + "=" * 75)
            log_error(f"AUTOMATED CRASH INSPECTION & POST-MORTEM DIAGNOSTICS: {sig_name}")
            print("=" * 75)
            print(f"Target Architecture : {config.get('arch')} ({config.get('bits', 64)}-bit {config.get('endian', 'little')}-endian)")
            print(f"Container Image     : {image} ({config.get('platform', 'native')})")
            print(f"Build Directory     : {build_dir_name}")
            print("=" * 75)

            debug_script = (
                "echo '--- Active System & Core Pattern ---' && "
                "uname -a && "
                "cat /proc/sys/kernel/core_pattern 2>/dev/null || true && "
                "echo '--- Core Dump Search & GDB Backtrace ---' && "
                "CORE_FILE=$(find /tmp /var/crash \"" + build_dir_name + "\" -name 'core*' -o -name '*.core' 2>/dev/null | head -n 1) && "
                "if [ -n \"$CORE_FILE\" ]; then "
                "  echo \"Found Core Dump: $CORE_FILE\" && "
                "  BIN_FILE=$(find " + build_dir_name + " -type f -executable -not -name '*.sh' 2>/dev/null | head -n 1) && "
                "  if command -v gdb >/dev/null 2>&1 && [ -n \"$BIN_FILE\" ]; then "
                "    echo \"Inspecting with GDB against binary: $BIN_FILE...\" && "
                "    gdb --batch -ex 'set pagination off' -ex 'bt full' -ex 'thread apply all bt full' \"$BIN_FILE\" \"$CORE_FILE\" 2>/dev/null || true; "
                "  fi; "
                "else "
                "  echo 'Note: No local core file saved in container volume (host kernel may handle core dumps via systemd-coredump or kernel pipe).'; "
                "fi && "
                "if [ \"" + str(err.returncode) + "\" = \"139\" ] && [ \"" + str(is_foreign_arch(config.get("arch", ""))) + "\" = \"True\" ]; then "
                "  echo '--- QEMU Emulation Note ---' && "
                "  echo 'A SIGSEGV during multi-threaded build under QEMU user-mode emulation is typically caused by QEMU binfmt thread limit exhaustion.' && "
                "  echo 'Remedy: Retry with lower concurrency (e.g. -j 2 or -j 1) or upgrade host qemu-user-static.'; "
                "fi"
            )
            inspect_cmd = [engine, "run", "--rm", "-e", "DEBIAN_FRONTEND=noninteractive"]
            if config.get("platform"):
                inspect_cmd.extend(["--platform", config["platform"]])
            inspect_cmd.extend([
                "-v", f"{repo_root}:/workspace",
                "-w", "/workspace",
                image,
                "sh", "-c", debug_script
            ])
            try:
                exec_container_cmd(inspect_cmd, timeout=30)
            except Exception:
                pass
            print("=" * 75 + "\n")
        raise err
    finally:
        try:
            exec_container_cmd([engine, "run", "--rm", "-v", f"{repo_root}:/workspace", "alpine:latest", "sh", "-c", post_chown_cmd], timeout=15)
        except Exception:
            pass

    elapsed = time.time() - t0
    log_success(f"Target '{target_name}' PASSED in {elapsed:.2f}s")
    return True


def main():
    parser = argparse.ArgumentParser(
        description="libhisto Multi-Architecture & Portability Test Runner"
    )
    parser.add_argument(
        "-t", "--target",
        default="musl",
        help="Target profile name, alias, 'all', or 'matrix' (default: musl)"
    )
    parser.add_argument(
        "--engine",
        choices=["auto", "docker", "podman"],
        default="auto",
        help="Container runtime engine (default: auto-detect)"
    )
    parser.add_argument(
        "--full",
        action="store_true",
        help="Run full test suite (Core C + Python & Perl bindings) inside the target"
    )
    parser.add_argument(
        "-j", "--jobs",
        type=int,
        default=os.cpu_count() or 4,
        help="Number of parallel compilation jobs"
    )
    parser.add_argument(
        "--build-type",
        default="Release",
        choices=["Release", "Debug"],
        help="CMake build type (default: Release)"
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List available target architectures and profiles"
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="Clean up container build directories"
    )

    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent.parent

    if args.list:
        print("Available Portability & Multi-Architecture Targets:")
        print("=" * 70)
        for name, cfg in TARGETS.items():
            print(f"  * {name:<14} : {cfg['description']}")
        print("\nAliases:")
        for alias, target in ALIASES.items():
            print(f"  * {alias:<14} -> {target}")
        print("\nAggregates:")
        print(f"  * {'all / matrix':<14} : {', '.join(ALL_LOCAL_TARGETS)}")
        return 0

    if args.clean:
        log("Cleaning container build directories...")
        for p in repo_root.glob("build-container-*"):
            if p.is_dir():
                shutil.rmtree(p, ignore_errors=True)
                if p.is_dir():
                    engine = detect_container_engine()
                    if engine:
                        try:
                            exec_container_cmd([engine, "run", "--rm", "-v", f"{repo_root}:/workspace", "alpine:latest", "rm", "-rf", f"/workspace/{p.name}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                        except Exception:
                            pass
        if (repo_root / "build-x86_32").is_dir():
            shutil.rmtree(repo_root / "build-x86_32", ignore_errors=True)
        log_success("Clean complete.")
        return 0

    # Resolve target
    target_key = args.target.lower()
    target_key = ALIASES.get(target_key, target_key)

    if target_key in ["all", "matrix", "test-matrix-local"]:
        targets_to_run = ALL_LOCAL_TARGETS
    elif target_key in TARGETS:
        targets_to_run = [target_key]
    else:
        log_error(f"Unknown target '{args.target}'. Run with --list to see available targets.")
        return 1

    needs_container = any(TARGETS[t]["image"] is not None for t in targets_to_run)
    engine = None
    if needs_container:
        engine = detect_container_engine(args.engine)
        if not engine:
            return 1
        ensure_binfmt_registered(engine, targets_to_run)

    start_time = time.time()
    results = {}

    for t in targets_to_run:
        cfg = TARGETS[t]
        try:
            if cfg["image"] is None:
                ok = run_native_32bit(repo_root, args.jobs, args.build_type, args.full)
            else:
                ok = run_container_target(repo_root, t, cfg, engine, args.jobs, args.build_type, args.full)
            results[t] = "PASSED"
        except subprocess.CalledProcessError as e:
            log_error(f"Target '{t}' FAILED with exit code {e.returncode}")
            results[t] = f"FAILED (exit code {e.returncode})"
        except Exception as e:
            log_error(f"Target '{t}' FAILED: {e}")
            results[t] = f"FAILED ({e})"

    total_elapsed = time.time() - start_time

    print("\n" + "=" * 70)
    print(" PORTABILITY & MULTI-ARCHITECTURE TEST SUMMARY")
    print("=" * 70)
    all_passed = True
    for t, status in results.items():
        if "PASSED" in status:
            mark = "\033[1;32m[PASS]\033[0m" if sys.stdout.isatty() else "[PASS]"
        else:
            mark = "\033[1;31m[FAIL]\033[0m" if sys.stdout.isatty() else "[FAIL]"
            all_passed = False
        print(f"  {mark}  {t:<16} : {status}")
    print("=" * 70)
    print(f"Total time elapsed: {total_elapsed:.2f}s\n")

    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
