# Docker Runtime Images Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the published container behavior into a dynamic root-based default image and a fixed non-root `user` image while keeping the `karr` CLI and docs consistent.

**Architecture:** Keep a single multi-stage `Dockerfile` with a shared Perl runtime base. Publish `runtime-root` as `raudssus/karr:latest` with an entrypoint that detects the mounted workspace owner and drops privileges before running `karr`, and publish `runtime-user` as `raudssus/karr:user` with a fixed `karr` user built from `KARR_UID`/`KARR_GID` defaults.

**Tech Stack:** Dist::Zilla hooks, Docker multi-stage builds, shell entrypoint bootstrap, Perl test suite, README and POD documentation.

---

### Task 1: Lock in the Docker tag contract with tests

**Files:**
- Modify: `t/12-dist-hooks.t`
- Create: `t/22-docker-images.t`
- Test: `t/12-dist-hooks.t`, `t/22-docker-images.t`

- [ ] **Step 1: Write the failing test assertions for the new tag layout**
- [ ] **Step 2: Run `prove -l t/12-dist-hooks.t t/22-docker-images.t` and confirm the old Dockerfile/hooks fail the new expectations**
- [ ] **Step 3: Keep the assertions focused on published tags and Dockerfile stage/entrypoint structure**
- [ ] **Step 4: Re-run the focused tests only after implementation changes**
- [ ] **Step 5: Commit once Docker behavior and docs are verified**

### Task 2: Implement the runtime split in the container build

**Files:**
- Modify: `Dockerfile`
- Create: `docker/karr-entrypoint.sh`

- [ ] **Step 1: Add a shared runtime base stage with the Perl install copied in**
- [ ] **Step 2: Add a `runtime-root` target that keeps `USER root` and uses an entrypoint script**
- [ ] **Step 3: Add a `runtime-user` target that creates `karr` with build args `KARR_UID` and `KARR_GID` and ends with `USER karr`**
- [ ] **Step 4: In the entrypoint, detect `KARR_UID`/`KARR_GID`, otherwise use `/work` ownership, then drop privileges before `exec karr "$@"`**
- [ ] **Step 5: Keep Git identity defaults and `/home/karr` available for mounted config/skill directories**

### Task 3: Publish and document the new image contract

**Files:**
- Modify: `dist.ini`
- Modify: `README.md`
- Modify: `lib/App/karr.pm`
- Modify: `share/claude-skill.md`

- [ ] **Step 1: Update build hooks so local builds create both `latest` and `user` tags from the correct targets**
- [ ] **Step 2: Update release hooks so published images include the new `user` tag without introducing a UID-tag matrix**
- [ ] **Step 3: Document the recommended Docker alias for `latest` and explain when to use `:user`**
- [ ] **Step 4: Mention the dynamic ownership behavior in the main POD and keep Docker guidance aligned with the README**
- [ ] **Step 5: Refresh the bundled skill text if Docker usage guidance is referenced there**

### Task 4: Verify, install the updated skill, and commit

**Files:**
- Modify: repository working tree as needed

- [ ] **Step 1: Run `prove -l t`**
- [ ] **Step 2: Run `podchecker lib/App/karr.pm lib/App/karr/Cmd/*.pm lib/App/karr/*.pm lib/App/karr/Role/*.pm`**
- [ ] **Step 3: Run `perl -c` across the modified Perl files**
- [ ] **Step 4: Build both Docker targets locally and smoke-test ownership behavior where practical**
- [ ] **Step 5: Reinstall the Codex skill from `share/claude-skill.md` and create a commit with Codex trailers**
