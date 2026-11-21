# Agent Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Set up directly in this session; production code and commits are outside the initial setup scope.

**Goal:** Set up a checked Getty project team with skilletor and concise project instructions.
**Architecture:** skilletor manages shared rules and skills; project agents and `briefing-core` remain owned sources. CLAUDE.md points to relevant knowledge.
**Tech Stack:** Markdown/YAML, JSON, skilletor, briefing, Python unittest.
**Spec:** `docs/superpowers/specs/2026-11-16-agent-setup-design.md`

## Global Constraints

- Python 3.8+ for shared and Claude Code paths; standard library only.
- No hook, product-skill, binary or manifest changes. No commit or push in the initial scope.
- Five roles: scout, worker, test-writer, reviewer, release-manager.
- Keep the karr board unchanged; k5 remains the separate binary task.

## Review Focus

- Fresh checkout: sources and plugin requirements are tracked, installed copies ignored.
- Missing skill: a complete briefing or an explicit refusal, never partial context.
- Relocated documentation: existing guardrails and live-test traps stay reachable.
- Ownership: Git/release skills only in the release manager; read-only roles cannot edit files.
- False success: distinguish checkout, installed plugin and actual harness starts.

## Task 1: Setup and documentation migration

**Files:** `.claude/skilletor.json`, `.claude/settings.json`, `.claude/.gitignore`,
`.worktreeinclude`, `.claude/skills/briefing-core/SKILL.md` and `references/`,
`.claude/agents/briefing-*.md`, `.claude/rules/briefing-rules.md`, `CLAUDE.md`, `.gitignore`.
**Interfaces:** Agents declare `briefing-core`, role skills and the karr ticket skill;
settings enable briefing, skilletor and superpowers.

- [x] Check baseline: ack-team reports missing agents, rules and settings; 95 unittest tests pass.
- [x] Read existing ticket: k5 concerns binaries, not setup.
- [x] Install sources and house rules with skilletor, using the existing local sources.
- [x] Move project knowledge to `briefing-core` and references; write five agents and short rules.
- [x] Reduce CLAUDE.md to an entry point and specific pointers; ignore local files and root karr materialization.
- [x] Run `skilletor check --scope project`, `ack-team check` and both doctors with no missing skills.
- [x] Check positive hook output per role and a negative probe agent.
- [x] Check Markdown pointers, Git visibility and `git diff --check`.
- [x] Run `python3 -m unittest discover tests`; expected: 95 passing tests.
- [x] Review results and name unexecuted live/platform checks; no publication in the initial scope.

## Execution notes

- Ruling: work directly in the existing checkout as approved for team setup; no production-code changes or commit in the initial scope.
- Ruling: verify the configuration migration with existing tools rather than new product tests; the failing team check is the red baseline.
- Ruling: `targets: [claude]` reflects the existing development setup; do not create a second Codex team without a request.
- Ruling: `skilletor check` may report `changed` for local sources. The installed `LocalSource.check()` intentionally always returns true. An unchanged sync and eight installed entries without orphans, warnings or trust requests are the relevant evidence; do not alter user configuration to force a green exit.
- Corrected verification assumptions: `bin/briefing-doctor` is a shell wrapper (`sh -n`), not Python. The initial compile attempt failed accordingly. At setup time the installed hook injected at `SubagentStart`, while the checkout used `PreToolUse.updatedInput`; one positive test using the old event was inappropriate. Both contracts subsequently passed separate checks.

## Verified at setup time

- `ack-team check`: all five agents, roles, read-only restrictions, settings, board and hook passed.
- Checkout and installed doctors: all five roles resolve; largest briefing 28 KiB.
- Five positive payload tests per hook version; missing skills denied without partial context. Installed SubagentStart returned abort context only on failure.
- Relative Markdown pointers resolve; owned sources are trackable, installed/local files ignored; karr ignore patterns are root-anchored.
- Python syntax checks for both hooks and `sh -n bin/briefing-doctor` passed.
- `python3 -m unittest discover tests`: 95 tests passed, none skipped.
- `git diff --check` passed; no product-file changes or board writes during setup.

## Follow-up and remaining verification

- The first reviewer spawn was rejected with "Agent type not found". After the user authorized the local commit, `briefing-reviewer` became available: independent review found no issues; 95/95 tests, both doctors, both hook channels for all five roles and ack-team passed. The reviewer changed no files or board state. The behavioral control-agent test remained outstanding.
- Real Claude Code/Codex spawns with secret/control phrases and native Windows/macOS runs were not executed for this setup task. Passing payload tests are not a substitute.
