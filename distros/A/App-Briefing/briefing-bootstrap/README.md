# briefing-bootstrap

`briefing-bootstrap.exe` is the briefing-owned native Windows entry point used by
`bin/briefing.exe`. It is separate from the shared generic launcher in
`winlaunch/`; changes here belong to this repository and must not be copied back
to the shared launcher.

## Behavior

The bootstrap discovers its executable with wide Win32 APIs and requires an
absolute `CLAUDE_CONFIG_DIR` (or falls back to an absolute `%USERPROFILE%\.claude`).
It parses the plugin's strict five-entry pin manifest `briefing-binaries.sha256`
and takes the release version from it, as the POSIX starter does: all five
lines name one version that starts with `[A-Za-z0-9]` and has only
`[A-Za-z0-9._+-]`, otherwise the manifest is malformed. No version is compiled
into the executable, so a new release needs only a new pin file. The bootstrap
selects `briefing-<version>-windows-x86_64.exe`. The binary lives in the
versioned cache as `<config>\briefing\bin\<version>\<pin>\briefing.exe`, the
starter's layout, where `<pin>` is the first 16 hex digits of the pinned
SHA-256; the cache directories carry a protected access list for the current
user only and reparse points are rejected. Before every start the binary is
rehashed with BCrypt SHA-256 and compared with the full pin; the directory name
is never the trust anchor. Only `briefing hook session-start` provisions: it
downloads the asset from
`https://github.com/Getty/briefing/releases/download/<version>/` over HTTPS
with WinHTTP (at most 256 MiB), verifies it and moves it into the cache; any
other invocation uses a cached verified binary or a fallback.
`BRIEFING_BINARY_BASE_URL`, when set and not empty, replaces that base
(`<base>/<asset>`), as in the POSIX starter: a mirror override that production
honors over HTTPS, with every redirect HTTPS too. That is safe from any source
because nothing is kept or run unless its SHA-256 is the pinned one. A stable,
versioned `PAR_GLOBAL_TEMP`, the directory `par` beside the binary, keeps the
PAR runtime unpacked in the cache. PAR's loader accepts only plain ANSI paths
below MAX_PATH, including the tree it extracts: the bootstrap hands it the
long path when that leaves room for the tree, otherwise the 8.3 alias, and
falls back with a stated reason when neither qualifies. With the short layout
the long path qualifies for an ASCII configuration directory of up to about
90 characters. The binary runs through `CreateProcessW` with the original
arguments, working directory, standard handles and exit status, and with the
caller's environment except `PAR_GLOBAL_TEMP`, which the bootstrap sets to
that directory.

Without a verified binary the bootstrap falls back like the POSIX starter: hooks
and `doctor` run `hooks/briefing-preload` with Python, chosen by winlaunch's
rule: `python3.exe`, else `python.exe`, else `py.exe` with `-3`, each looked up
along `PATH` in order, skipping every directory whose path contains
`\WindowsApps` (the Microsoft Store stubs). That child gets `PYTHONUTF8=1`, so
the hook reads its JSON payload as UTF-8. Other commands run the plugin's Perl
source when `perl.exe` loads `App::Briefing`; with neither, a hook prints one
`systemMessage` warning and exits 0, and other commands report the reason and
fail. `hook marketplace-notice` is the exception: its only fallback is
`hooks/briefing-marketplace-notice` with that Python, and without one it exits 0
with no output.

Test-only overrides (a fixture child, plain HTTP to a loopback host as the base
URL, a size limit, synchronization points) are honored only when
`BRIEFING_BOOTSTRAP_TESTING` is exactly `1`; production ignores them. The
bootstrap accepts only `http` and `https` URLs, so `file://`, which the
starter's test gate allows, is refused even under the gate.

## Reproducible build

Install the pinned compiler package into the Python environment used for the
build:

```text
python3 -m pip install ziglang==0.13.0.post1
python3 briefing-bootstrap/build.py bin/briefing-bootstrap.exe
```

The build script requires compiler version `0.13.0`, defaults to target
`x86_64-windows-gnu`, compiles with `-Os -s`, links `winhttp`, `bcrypt`, and
`advapi32`, validates the PE output, clears its COFF timestamp, and removes any
sidecar `.pdb` or `.lib` file. An alternate C fixture can be built with
`--src SOURCE`; an alternate Zig target can be selected with `--target TARGET`.

Verify reproducibility by building twice and comparing the outputs byte for
byte:

```text
python3 briefing-bootstrap/build.py .build/briefing-bootstrap-a.exe
python3 briefing-bootstrap/build.py .build/briefing-bootstrap-b.exe
cmp .build/briefing-bootstrap-a.exe .build/briefing-bootstrap-b.exe
```

## Verification boundary

A cross-build on Linux proves the build and PE contracts, not Windows process
behavior. Native Windows x86_64 evidence requires:

```text
python -m unittest tests.test_windows_wiring -v
python tests/test_briefing_bootstrap.py C:\absolute\path\to\briefing-bootstrap.exe
```

The native suite (46 contracts in `tests/test_briefing_bootstrap.py`) covers
Unicode paths and arguments, Windows quoting, inherited UTF-8 standard streams, environment and current-directory preservation,
versioned `PAR_GLOBAL_TEMP`, relative-config rejection, and exact child exit
status.
