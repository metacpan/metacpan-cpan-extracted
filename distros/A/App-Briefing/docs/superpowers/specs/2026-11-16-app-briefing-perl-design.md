# App::Briefing in the project root

## Approved scope

The user requested the Perl port as the shared basis for library, CLI and binaries,
using the normal Getty distribution layout in this repository's root.
Distribution: `App-Briefing`; library: `App::Briefing`; command: `briefing`.
No parallel project under `perl/`, CPAN upload or release.
Repository prose, comments, documentation and diagnostics are English; non-English
strings are retained only as intentional test fixtures.

The first production foundation is an installable Perl library and CLI with
behavioral parity to the current Python hook. Existing plugin starters stay
functional during migration: switching them to shipped binaries is a separate,
verified step. Python is temporarily the compatibility reference, not a second
engine to maintain indefinitely. CPAN-installed `briefing` needs no Python at runtime.

## Structure and public interfaces

- Root: `dist.ini` with `[@Author::GETTY]`, `cpanfile`, existing `Changes`, `LICENSE`, `README.md`.
- `lib/App/Briefing.pm`: Moo class with `cwd`, `home` and `codex_home`; defaults follow the harness.
- `lib/App/Briefing/Filesystem.pm`: encapsulated file access and path operations.
- `lib/App/Briefing/CLI.pm`: arguments, stdin/stdout/stderr and exit codes.
- `bin/briefing`: thin CLI invocation; all new Perl files initially carry version `0.001`.
  Check that initial value at first-build acceptance. Retained tests compare module
  and CLI versions rather than freezing later automatic release bumps to `0.001`.
- `t/`: native Perl tests; existing Python tests remain additional external contract tests.

`App::Briefing->new(cwd => ..., home => ..., codex_home => ...)` lets tests and
library users supply explicit context. Public methods:

- `brief_agent($name, harness => 'claude'|'codex')`: `undef` without a declaring
  agent file; otherwise a hashref with `agent`, `path`, `harness`, `skills`,
  `missing`, `text`, `size`, `legacy`. `size` counts UTF-8 bytes; when any skill
  is missing, `text` contains no partial briefing.
- `check_agents(harness => 'claude'|'codex'|'both')`: arrayref of those results.
- `process_hook($payload)`: hashref `{ output => HASHREF|undef, stderr => STRING, exit_code => 0 }`.
  This library method prints nothing and changes no files. Payload `cwd` applies
  to that call without permanently changing the object's context.
- `process_notice($payload)`: the same result format, but with the explicitly
  separate, one-time marketplace-notice state write preserved from the existing implementation.

`App::Briefing::CLI->run(\@args)` performs CLI I/O and returns its exit code:
`briefing hook`, `briefing doctor [--cwd DIR] [--harness claude|codex|both]`,
`briefing notice`, `briefing --version`, `briefing --help`.
Existing JSON contracts and doctor output are the reference, not a new universal
harness protocol. The CLI uses the public library, not the other way around.
Never execute Python as an implementation shortcut.

## Behavior and platforms

- Shared `SubagentStart.additionalContext`; Claude PreToolUse is only a guard,
  never `updatedInput`. Codex receives an abort instead of a claimed spawn veto.
- Preserve search precedence, installed/enabled plugins, declaration formats,
  preflight, budget warnings, absolute skill directories and doctor exit codes.
- Invalid hook input exits cleanly with 0; only genuinely missing declared skills
  cause refusal/abort. Never produce a partial briefing.
- Use `Path::Tiny` for portable file operations. Replace the Windows access shown
  to fail in the prototype with explicit Unicode-capable Windows APIs behind the
  filesystem module. This is a justified project exception, not a global override.
- `Win32::LongPath` is the initial Windows adapter to verify: documented `testL`,
  `openL`, directory and absolute-path operations, without global monkeypatches.
- Use `JSON::MaybeXS`, Moo and Getty POD conventions. Read TOML with a suitable
  Perl parser; comments outside multiline strings remain a distinct declaration task.
- Minimum Perl follows the distribution template: 5.20. No runtime downloads.

## Installation and transition

Only `bin/briefing` is installed as the new CPAN command. Existing plugin doctor
starters and their `.exe` must not accidentally become additional CPAN commands;
keep them for the existing plugin route until binary cutover. Do not prematurely
point plugin manifests or shared winlaunch at a nonexistent Perl/binary launcher.

The normal distribution build follows Getty conventions, including license
generation and tracked files. Shared Perl skills/rules come through skilletor;
commit/release knowledge stays with the release manager. Releasing or pushing
this new feature branch requires its own authorization.

## Evidence

1. Native Perl tests cover library, CLI, failure policy and Unicode filesystem behavior.
2. Run the existing 105 contract tests against Python and, where applicable, the
   same cases against the Perl CLI; identify language-specific checks explicitly.
3. Run `prove -lr t`, `dzil build` and `dzil test`; verify the installable package
   contains library and CLI without accidentally installing old launchers.
4. Run the new Perl core natively on Windows/macOS/Linux after CI-branch approval;
   never infer a platform pass from Linux alone.
5. Keep standalone binary delivery distinct from source parity. PAR cache/startup
   costs and runtime isolation are not automatically solved by this port.
