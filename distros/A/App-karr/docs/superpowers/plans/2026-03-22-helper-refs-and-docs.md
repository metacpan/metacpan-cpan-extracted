# Helper Refs And Docs Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add safe free-form helper ref commands, tighten POD/README-aligned messaging, and prepare the distribution for a local `dzil build`.

**Architecture:** Extend `App::karr::Git` with single-ref normalization, validation, fetch, and push helpers. Add `set-refs` and `get-refs` commands that rely on those helpers and document them through the main CLI POD. Keep tests integration-heavy around real Git repositories.

**Tech Stack:** Perl 5, Moo, MooX::Cmd, MooX::Options, Path::Tiny, YAML::XS, Test::More, Git CLI, Dist::Zilla

**Spec:** `docs/superpowers/specs/2026-03-22-helper-refs-design.md`

---

## File Structure

### Modify

- `dist.ini`
- `lib/App/karr.pm`
- `lib/App/karr/Git.pm`
- `t/00-load.t`
- existing POD-heavy command modules as needed for wording refresh

### Create

- `lib/App/karr/Cmd/SetRefs.pm`
- `lib/App/karr/Cmd/GetRefs.pm`
- `t/21-helper-refs.t`

## Chunk 1: Git helper refs foundation

### Task 1: Write the failing helper-ref tests

**Files:**
- Modify: `t/00-load.t`
- Create: `t/21-helper-refs.t`

- [ ] Add `App::karr::Cmd::SetRefs` and `App::karr::Cmd::GetRefs` to `t/00-load.t`.
- [ ] Write a failing integration test for:
  - bare ref normalization to `refs/...`,
  - blocked namespaces,
  - single-ref push/fetch between two repositories.
- [ ] Run `prove -l t/00-load.t t/21-helper-refs.t` and confirm red.

### Task 2: Implement Git helper methods

**Files:**
- Modify: `lib/App/karr/Git.pm`
- Test: `t/21-helper-refs.t`

- [ ] Add `normalize_ref_name`.
- [ ] Add `validate_helper_ref`.
- [ ] Add `push_ref` and `pull_ref`.
- [ ] Re-run `prove -l t/21-helper-refs.t` and get green.

## Chunk 2: CLI commands

### Task 3: Add `set-refs`

**Files:**
- Create: `lib/App/karr/Cmd/SetRefs.pm`
- Modify: `lib/App/karr.pm`
- Test: `t/21-helper-refs.t`

- [ ] Add the command to the CLI overview/help.
- [ ] Implement positional parsing, normalization, validation, write, and push.
- [ ] Keep informational output on `stderr`.
- [ ] Re-run the focused test and extend it until the command behaviour is covered.

### Task 4: Add `get-refs`

**Files:**
- Create: `lib/App/karr/Cmd/GetRefs.pm`
- Modify: `lib/App/karr.pm`
- Test: `t/21-helper-refs.t`

- [ ] Implement normalization, validation, single-ref fetch, and payload output.
- [ ] Keep payload on `stdout` and status output on `stderr`.
- [ ] Re-run the focused test and get green.

## Chunk 3: Distribution polish

### Task 5: Refresh docs and metadata

**Files:**
- Modify: `dist.ini`
- Modify: `lib/App/karr.pm`
- Modify: `lib/App/karr/Cmd/SetRefs.pm`
- Modify: `lib/App/karr/Cmd/GetRefs.pm`

- [ ] Add `irc = #ai` to `dist.ini`.
- [ ] Update main POD to mention helper refs, AI workflows, Perl-first usage, and Docker alias usage as an alternative.
- [ ] Add POD for the two new commands.
- [ ] Run `podchecker lib/App/karr.pm lib/App/karr/Cmd/*.pm lib/App/karr/*.pm lib/App/karr/Role/*.pm`.

## Chunk 4: Final verification and handoff

### Task 6: Full repo verification

**Files:**
- Modify: working tree as needed

- [ ] Run `prove -l t`.
- [ ] Run `git status --short`.
- [ ] Stage only intended files.
- [ ] Commit with a concise message and Codex trailers.
- [ ] Run `dzil build`.
