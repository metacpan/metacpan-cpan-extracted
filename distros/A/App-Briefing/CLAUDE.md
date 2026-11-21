# briefing

> Programmatic briefing beats prompt stuffing.

A plugin for Claude Code and Codex: declared skills reach subagents in full at
spawn time. Usage and installation: [README.md](README.md).

## Repository language

Write repository content in **English**, including skills, agents, documentation,
comments and CI text. Keep non-English strings only as intentional test fixtures.

## Before working

- **Hooks, resolution, doctor, tests or Windows launchers:** read
  [briefing-core](.claude/skills/briefing-core/SKILL.md). Its references separate
  the hook contract, resolution rules and live harness verification.
- **Ownership and verification:**
  [.claude/rules/briefing-rules.md](.claude/rules/briefing-rules.md).
- **Writing agents for plugin users:**
  [product skill](skills/briefing/SKILL.md); distinct from the development skill.
- **Planning the Perl port or distribution:** read
  [the App::Briefing direction](docs/perl-direction.md) and its packaging probe.

## The agent team

- `briefing-scout`: reads and reports; changes nothing.
- `briefing-worker`: implements code and maintains skills; never commits.
- `briefing-test-writer`: writes tests; leaves implementation to the worker.
- `briefing-reviewer`: reviews changes and runs tests; changes no files.
- `briefing-release-manager`: owns authorized commits, `Changes` and release checks.

Work belongs on the existing karr board (`karr list --compact`), not a second file
board. Newly created agents may require a fresh Claude Code session.

## Shared rules and skills

`.claude/skilletor.json` declares sources and the `getty-cpan-dist` bundle.
`skilletor sync --scope project` installs shared files;
`skilletor check --scope project` checks their state. Edit managed copies at their
source. This development team targets `claude`; the product supports both harnesses.

Project agents, `briefing-core`, settings and skilletor configuration are tracked.
Installed rules/skills, the lock and local settings are not. House rules come from
skilletor rather than being duplicated here.
