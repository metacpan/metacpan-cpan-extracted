<!-- ack: shape=project manager=none board=karr committer=release-manager outside_input=on headless=off -->
# briefing: project rules

## Lanes

| Work | Agent |
|---|---|
| Read code and history, explain relationships | `briefing-scout` |
| `lib/`, `hooks/`, `bin/`, `winlaunch/` except tests; skills, examples, dist/plugin configuration | `briefing-worker` |
| `t/`, `tests/`, `winlaunch/test_winlaunch.py` | `briefing-test-writer` |
| Review completed work and run checks independently | `briefing-reviewer` |
| Authorized commits, `Changes`, release checks | `briefing-release-manager` |

These code/skill paths, hook configuration and plugin manifests are
behavior-relevant: changes belong to the worker, even when they are JSON.
The main session owns coordination, plain prose documentation and team configuration.

## Checks and commits

`prove -lr t` checks the Perl library; `python3 -m unittest discover tests -v`
checks the existing hook contracts. The Python driver can target the Perl CLI
for port parity; a passing reference run alone does not prove the port.
For resolution or agent changes, also check both doctor versions:
`python3 hooks/briefing-preload doctor --cwd . --harness both` and `briefing-doctor`.
The release manager alone makes authorized commits and closes their cards;
leave other sessions' working-tree changes untouched.

## Board

The existing board lives in `refs/karr/*`; `karr list --compact` shows open work.
Karr mutations synchronize with `origin`: obtain authorization for that exchange
before the first write. Setting up the team alone does not grant it.

## With superpowers

Work in the existing checkout; use isolation only when explicitly chosen.
Code tasks go to the worker/test-writer, then the reviewer checks the uncommitted
diff; the release manager makes an authorized commit afterwards.
Brainstorming and planning stay with the main session because they need the user.

## Hazards

- The checkout and installed briefing may have different hook contracts:
  read `briefing-core` and its relevant reference before hook work.
- The existing Windows `.exe` files are Python launchers, not standalone binaries;
  native checks are in `winlaunch/README.md`. Linux unittest is not a Windows proof.
- `hooks/briefing-preload` stays side-effect-free; the separate marketplace notice
  owns state. Keep those contracts distinct.
- `Changes` remains the single changelog for App::Briefing and plugin development;
  release conventions belong only to the release manager.
- Unicode Windows paths failed in the unpacked prototype. The encapsulated filesystem
  may therefore use wide Windows APIs instead of unchecked ordinary file tests;
  portable file operations still use Path::Tiny.
- CPAN should install only the new `briefing`, not the old plugin doctor launchers
  under `bin/`; inspect the generated installation list explicitly.
