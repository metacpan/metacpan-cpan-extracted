# Throwaway Perl packaging prototype

Question: Is the existing native Perl/pp path suitable for a small JSON hook
without a separately installed runtime?

**Not product code, not a distribution, and no fixed module name. Its own
protocol is NOT compatible with real harness protocols.** There is no
agent/skill resolution, frontmatter processing, or hook integration;
it reads only explicitly supplied fixture files. The artifact contains a Perl
runtime, but starts neither the test host's Python nor separately installed Perl.

## Commands

From the repository root. Build host: Perl with PAR::Packer 1.064 and Path::Tiny
(local 0.150); Python 3.8+ only for the build/test helpers. JSON::PP is explicitly
part of the experiment; Path::Tiny follows the Perl file-I/O house rule. The
skilletor build model supplies the pp path with PAR_VERBATIM=1. No module pruning
or size optimization.

- Native build per OS: `python prototypes/perl-packaging/build.py`
- Linux/macOS: `python prototypes/perl-packaging/smoke.py prototypes/perl-packaging/build/probe --expect-arch x86_64 --report prototypes/perl-packaging/build/smoke.json`
- Windows: `python prototypes/perl-packaging/smoke.py prototypes/perl-packaging/build/probe.exe --expect-arch x86_64 --report prototypes/perl-packaging/build/smoke.json`
- Artifact metadata: `prototypes/perl-packaging/build/probe --version` (append `.exe` on Windows).

Locally, the Python command on Linux is `python3`. `build.py --perl /absolute/perl`
selects the build interpreter. The helper records its portable pp command:
`perl -Mpp -e 'pp->go()' -- -o OUTPUT probe.pl`, with PAR_VERBATIM=1 in the
environment. The helper installs no global dependencies.

Request: `{"skills":[{"name":"example","path":"/absolute/Fixture SKILL.md"}]}`

Success: `{"ok":true,"skills":[{"name":"example","body":"complete UTF-8 file"}]}`.
Error: `{"ok":false,"error":{"code":"missing_skill","name":"example"}}`.
**No error includes skill content**, even if earlier files were already read.
Broken JSON yields `invalid_json`, an invalid request `invalid_request`, and an
unreadable file `unreadable_skill`.
Handled requests exit 0 and produce exactly one UTF-8 JSON object. These are
prototype semantics, not a statement about the behavior of real hooks.

## Checks and measurement limits

The Python test host creates Unicode content and paths with spaces, umlauts, and
characters outside Windows-1252 (`Pfad ä 技能`). It copies the artifact into a
path with spaces and an umlaut, and starts it through an absolute path with a
fresh minimal environment and empty PATH. The checks cover strict JSON on
stdout, empty stderr, complete content, present plus missing skills, and invalid
input. The application code starts no external Perl or Python.

Each run receives a new working directory under `.work/`.
**PAR_GLOBAL_TEMP** determines the actual **PAR_TEMP** cache: pp resets a passed
PAR_TEMP, so PAR_TEMP alone does not isolate a cache.
The runner checks that the selected directories are actually populated.
It measures a cold start, five repeats with the same cache, and one additional
start with a second empty cache. An empty PAR cache is not an empty OS page
cache. These are local wall-clock times, not a reliable benchmark.

The JSON separates `functional_status` and `separate_interpreter_absence.status`.
The latter remains **NOT_PROVEN** for the ordinary host runner: an empty PATH
hides neither absolute interpreter paths nor system Perl libraries or macOS
system Perl. A green smoke test therefore does not prove an environment without
an external runtime. The separately documented Linux isolation below came from
the main session; this runner does not create or start containers.

The report includes host OS/architecture/libc, embedded Perl architecture/version,
artifact and cache size, and system libraries (Linux ldd, macOS otool, Windows
objdump, when available). These tools run on the test host with its normal PATH
outside the timing measurements. Static library analysis is not a complete
runtime trace. pp can package optional modules present on the build host; size
is not a reproducibility guarantee.

## Target matrix with separate status fields

| Target | Native CI runner | Actually tested | Build / functional smoke | Without separate Perl |
|---|---|---|---|---|
| Linux | ubuntu-24.04, x86_64 | CI: glibc 2.39; local: glibc 2.41 | PASS / PASS | Separate local isolation PASS, details below |
| macOS | macos-15-intel, x86_64 | native Intel runner, Darwin 24.6 | PASS / PASS | NOT PROVEN: host test with empty PATH |
| Windows | windows-2022, x86_64 / Strawberry Perl | native Windows Server 2022 runner | Build PASS; smoke FAIL on Unicode file path | NOT PROVEN |

[Second native run](https://github.com/Getty/briefing/actions/runs/43799294737):
Linux and macOS passed all smoke checks; Windows builds and starts the EXE,
but reports an existing file below `Pfad ä 技能` as `missing_skill`.
The additional [native control](https://github.com/Getty/briefing/actions/runs/43800137154)
compares ASCII, umlaut, and CJK paths with unchanged code:

| Windows file path | Unpacked script | PAR binary |
|---|---|---|
| ASCII | PASS | PASS |
| `Grüße` | FAIL: `missing_skill` | FAIL: `missing_skill` |
| `技能` | FAIL: `missing_skill` | FAIL: `missing_skill` |

All six processes start and return pure JSON with exit 0. On ASCII paths, the
same Unicode file content is read correctly. The files exist after creation by
the test host; the prototype fails its `-f` check before `Path::Tiny->slurp_utf8`.
The error is therefore already present in unpacked Windows file access, not only
after PAR packaging. A port needs an explicitly Unicode-capable solution here;
this experiment does not fix it. The diagnosis does not replace the strict smoke
test: Windows FAIL remains in the last CI run, while Linux and macOS again report PASS.

The first Windows attempt failed before the build: Git Bash placed its own
`/usr/bin/perl` before Strawberry Perl. The corrected workflow uses PowerShell
on Windows and Bash on Linux/macOS.

No statement applies to ARM, cross-compilation, or older system libraries.
The workflow checks RUNNER_ARCH; the runner checks platform.machine() and
reports the embedded Perl architecture instead of treating the runner label as proof.

CI measurements from the second run, each on different hosts:

| Target | Binary bytes | First empty PAR cache | Median of five warm starts |
|---|---:|---:|---:|
| Linux | 7.516.032 | 125,728 ms | 80,846 ms |
| macOS | 6.950.067 | 848,640 ms | 221,138 ms |
| Windows | 12.915.092 | not evaluated: functional failure | not evaluated |

These are not directly comparable OS benchmarks. JSON check reports remain as
short-lived artifacts in the CI run; no binaries were published.

Local state: Perl 5.40.1, pp 1.064, artifact 9.758.529 bytes (about 9.31 MiB),
208 cache files / 16.197.654 bytes. Last run with extended Unicode path:
cold start 632,066 ms, five repeats 272,364–385,379 ms
(median 286,473 ms), second empty cache 767,009 ms. Build 2,676 seconds.
ldd shows embedded libperl.so.5.40 and external libc, libm, libcrypt, libz,
and the ELF loader across the artifact and extracted libraries.
**Not a static binary.** Local raw data is ignored under
`build/build.json` and `build/smoke-linux.json`.

An additional small comparison with an identical one-skill minimal request, the
same minimal environment, and one unmeasured warm-up found median times from five
alternating starts of `/usr/bin/perl prototypes/perl-packaging/probe.pl` and the
warm artifact of 70,036 ms versus 293,180 ms (difference 223,144 ms). Raw data
including exact commands, input, and environment: `build/baseline-linux.json`.
This places possible packaging costs in context, but is not a general benchmark.

### Separate Linux isolation evidence from the main session

The main session checked the same artifact with SHA256
`9b926bc29ccd47cddfd3cb41532e32b695dd9bdbd849f4121db189e9aa6a46c4`
in a local debian:trixie-slim derivative (Linux x86_64, glibc 2.41).
According to the Dockerfile/report that was read, Perl programs, perl-base files,
and `/usr/share/perl5` were removed; Python and Node were absent as well. The
network was off, the root filesystem read-only, and PAR_GLOBAL_TEMP in tmpfs.
A Unicode file path outside Windows-1252, complete Unicode content, a missing
skill without a partial response, and invalid JSON passed. The binary hash was
compared here with the checked artifact; the worker did not rerun the container
itself. Main-session evidence:
`/tmp/briefing-no-runtime.CDFih0/linux-no-runtime.json` and the adjacent Dockerfile
(temporary local files, not part of this prototype).
Container wall-clock times include container startup and are **not** binary
startup times. This evidence applies to exactly this artifact and this Linux
environment, not to all distributions or other operating systems.

The workflow runs manually after explicit approval or on a push to
`spike/perl-packaging`, with `contents: read`, native builds, and job-local CPAN
dependencies. It retains only JSON check reports for seven days;
no binaries, releases, or changes to `main`. The native CI runs linked above
were actually executed. The build/test helpers themselves neither push nor
start CI.

Conclusion: The native build works on all three tested x86_64 platforms.
Linux and macOS pass the functional smoke; on Windows, umlaut file paths already
block suitability for this unchanged prototype, both unpacked and packaged.
Only the separate local Linux environment additionally proves the absence of
external interpreters. ARM, a native environment without external Perl on
macOS/Windows, and real harness integration remain untested.
For a tiny hook, archive/startup costs and cache extraction are relevant:
the application only reads, while the PAR launcher writes files on first start.
This is not yet approval for a fully portable, strictly read-only hook delivery.
The experiment ends with these findings; module name and production implementation
remain open.
