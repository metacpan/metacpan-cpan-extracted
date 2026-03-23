# Ref-First Board Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the persistent `karr/` working tree with a Git-ref-first board model and add destructive backup/restore for `refs/karr/*`.

**Architecture:** Treat `refs/karr/*` as the sole source of truth. Read and write commands operate on ref-backed state, using temporary materialization only as an internal implementation detail. Config overrides live in `refs/karr/config`, the next numeric id lives in `refs/karr/meta/next-id`, and backup/restore snapshots serialize the whole Karr ref namespace to YAML.

**Tech Stack:** Perl, Dist::Zilla, Git refs, YAML::XS, existing `App::karr::*` command modules, `Test::More`.

---

## Chunk 1: Ref-backed board storage

### Task 1: Add a board store abstraction

**Files:**
- Create: `lib/App/karr/BoardStore.pm`
- Modify: `lib/App/karr/Git.pm`
- Test: `t/23-board-store.t`

- [ ] **Step 1: Write the failing tests for loading config overrides, `next-id`, and task data from refs**
- [ ] **Step 2: Run `prove -l t/23-board-store.t`**
Expected: FAIL because `App::karr::BoardStore` does not exist yet.
- [ ] **Step 3: Implement `App::karr::BoardStore` with methods for `load_config`, `save_config`, `next_id`, `load_tasks`, `find_task`, `save_task`, `delete_task`, and `list_karr_refs`**
- [ ] **Step 4: Extend `App::karr::Git` with helpers for `refs/karr/meta/next-id` and namespace enumeration/deletion**
- [ ] **Step 5: Run `prove -l t/23-board-store.t`**
Expected: PASS.

### Task 2: Keep config defaults separate from overrides

**Files:**
- Modify: `lib/App/karr/Config.pm`
- Modify: `t/02-config.t`

- [ ] **Step 1: Write a failing test that merges code defaults with sparse ref overrides**
- [ ] **Step 2: Run `prove -l t/02-config.t`**
Expected: FAIL on the new override-merging behavior.
- [ ] **Step 3: Refactor `App::karr::Config` so it can build effective config from defaults plus override data rather than requiring a full file**
- [ ] **Step 4: Remove `next_id` persistence from config and move that concern out of `App::karr::Config`**
- [ ] **Step 5: Run `prove -l t/02-config.t t/23-board-store.t`**
Expected: PASS.

## Chunk 2: Remove persistent `karr/` board assumptions

### Task 3: Replace `BoardAccess` local-directory logic

**Files:**
- Modify: `lib/App/karr/Role/BoardAccess.pm`
- Modify: `lib/App/karr.pm`
- Test: `t/15-sync.t`
- Test: `t/24-ref-first-board-access.t`

- [ ] **Step 1: Write failing tests showing that board discovery requires Git and no longer requires `karr/config.yml`**
- [ ] **Step 2: Run `prove -l t/15-sync.t t/24-ref-first-board-access.t`**
Expected: FAIL because discovery still looks for `karr/config.yml`.
- [ ] **Step 3: Refactor `BoardAccess` to anchor on the Git worktree root and use `App::karr::BoardStore` instead of `tasks_dir` and `config.yml`**
- [ ] **Step 4: Keep any materialization strictly temporary and internal to the role/store**
- [ ] **Step 5: Run `prove -l t/15-sync.t t/24-ref-first-board-access.t`**
Expected: PASS.

### Task 4: Make `init` Git-only and ref-only

**Files:**
- Modify: `lib/App/karr/Cmd/Init.pm`
- Modify: `t/25-init-ref-first.t`

- [ ] **Step 1: Write failing tests for `karr init` outside Git, inside Git, and re-init on existing refs**
- [ ] **Step 2: Run `prove -l t/25-init-ref-first.t`**
Expected: FAIL because `init` still creates `karr/`.
- [ ] **Step 3: Update `karr init` to verify Git, write `refs/karr/config`, write `refs/karr/meta/next-id`, and skip any persistent board directory**
- [ ] **Step 4: Preserve optional skill installation as a separate concern**
- [ ] **Step 5: Run `prove -l t/25-init-ref-first.t`**
Expected: PASS.

## Chunk 3: Move commands onto the ref-backed store

### Task 5: Convert read commands

**Files:**
- Modify: `lib/App/karr/Cmd/List.pm`
- Modify: `lib/App/karr/Cmd/Show.pm`
- Modify: `lib/App/karr/Cmd/Board.pm`
- Modify: `lib/App/karr/Cmd/Context.pm`
- Modify: `lib/App/karr/Cmd/Config.pm`
- Test: `t/18-list-filter.t`
- Test: `t/07-context.t`
- Test: `t/06-config-cmd.t`

- [ ] **Step 1: Write or extend failing tests so these commands read from refs without a local board directory**
- [ ] **Step 2: Run the focused tests**
Run: `prove -l t/18-list-filter.t t/07-context.t t/06-config-cmd.t`
Expected: FAIL on file-based assumptions.
- [ ] **Step 3: Refactor these commands to use `BoardStore` for effective config and task loading**
- [ ] **Step 4: Remove direct `config.yml` and `tasks/` path usage**
- [ ] **Step 5: Re-run the focused tests**
Expected: PASS.

### Task 6: Convert write commands

**Files:**
- Modify: `lib/App/karr/Cmd/Create.pm`
- Modify: `lib/App/karr/Cmd/Edit.pm`
- Modify: `lib/App/karr/Cmd/Move.pm`
- Modify: `lib/App/karr/Cmd/Delete.pm`
- Modify: `lib/App/karr/Cmd/Archive.pm`
- Modify: `lib/App/karr/Cmd/Handoff.pm`
- Modify: `lib/App/karr/Cmd/Pick.pm`
- Modify: `lib/App/karr/Cmd/Sync.pm`
- Test: `t/03-archive.t`
- Test: `t/04-handoff.t`
- Test: `t/16-pick-lock.t`
- Test: `t/20-next-id-collision.t`
- Test: `t/26-ref-first-writes.t`

- [ ] **Step 1: Add failing tests for write operations with no persistent `karr/` directory**
- [ ] **Step 2: Run `prove -l t/03-archive.t t/04-handoff.t t/16-pick-lock.t t/20-next-id-collision.t t/26-ref-first-writes.t`**
Expected: FAIL on direct file operations.
- [ ] **Step 3: Refactor each command to fetch refs, mutate ref-backed state, and push refs back**
- [ ] **Step 4: Move numeric id allocation to `refs/karr/meta/next-id`**
- [ ] **Step 5: Re-run the focused tests**
Expected: PASS.

## Chunk 4: Backup, restore, migration, and docs

### Task 7: Add backup and restore commands

**Files:**
- Create: `lib/App/karr/Cmd/Backup.pm`
- Create: `lib/App/karr/Cmd/Restore.pm`
- Modify: `lib/App/karr.pm`
- Modify: `bin/karr`
- Test: `t/27-backup-restore.t`

- [ ] **Step 1: Write failing tests for YAML backup, destructive restore, and `--yes` protection**
- [ ] **Step 2: Run `prove -l t/27-backup-restore.t`**
Expected: FAIL because the commands do not exist yet.
- [ ] **Step 3: Implement `backup` to emit all `refs/karr/*` as YAML to a file or stdout**
- [ ] **Step 4: Implement `restore` to require `--yes`, delete all current Karr refs, recreate the snapshot refs, and push them**
- [ ] **Step 5: Run `prove -l t/27-backup-restore.t`**
Expected: PASS.

### Task 8: Clean up docs, tests, and Docker skill behavior

**Files:**
- Modify: `README.md`
- Modify: `share/claude-skill.md`
- Modify: `lib/App/karr.pm`
- Modify: `lib/App/karr/Cmd/Init.pm`
- Modify: `lib/App/karr/Cmd/Skill.pm`
- Modify: `t/00-load.t`

- [ ] **Step 1: Update docs to describe Git-only behavior and the absence of persistent `karr/`**
- [ ] **Step 2: Verify skill installation still writes `SKILL.md` to mounted agent directories in Docker usage**
- [ ] **Step 3: Add load tests for new command modules**
- [ ] **Step 4: Run `prove -l t/00-load.t`**
Expected: PASS with the new commands present.
- [ ] **Step 5: Commit once docs and behavior match the ref-first model**

## Chunk 5: Full verification

### Task 9: Run final verification

**Files:**
- Modify: repository working tree as needed

- [ ] **Step 1: Run `prove -l t`**
- [ ] **Step 2: Run `podchecker lib/App/karr.pm lib/App/karr/Cmd/*.pm lib/App/karr/*.pm lib/App/karr/Role/*.pm`**
- [ ] **Step 3: Run `find lib -name '*.pm' -print0 | xargs -0 -n1 perl -c`**
- [ ] **Step 4: Run `dzil build` and verify Docker images still build**
- [ ] **Step 5: Commit the ref-first migration with Codex trailers**
