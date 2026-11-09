# ADR 0058 — Family skill/agent/rule distribution moves to skilletor; the dist still ships its skill dirs as build provenance

- Status: accepted
- Date: 2026-09-28 (accepted 2026-10-04)
- Tags: skills, skilletor, build, sharedir, distribution, family-policy

## Context

Skills are shared across the DBIO family today by **manage-skills**: one authored
copy per skill, hardlinked into each repo so every checkout on the machine shares
one inode. The family topology — core is the priority source, `dbio-postgresql`
and `dbio-mysql` are secondary sources for their variant sub-families, every other
repo links — lives **only in `~/.manage-skills/sources` on the maintainer's
machine**. It is uncommitted, single-machine, and not reproducible on a fresh
checkout, a second machine, or under Codex. manage-skills also shares **skills
only**: the `dbio-*` agents and the house rules (`.claude/rules/dbio-rules.md`)
are not covered by it.

The rest of the maintainer's world has already moved to **skilletor** — the user
skilletor config declares `getty`, `karr`, `kubernetes-rest`, `io-k8s-p5` and
`author-getty` as sources. skilletor installs from remote/local sources into each
repo, renders items as build artifacts (edit in the source, re-`sync`), covers
**skills, agents and rules**, targets both Claude Code and Codex, and — decisively
— makes the topology a **committed, declarative `skilletor.json`** per repo. DBIO
is the last holdout on hardlinks.

A hard constraint sits under any migration: core ships a chosen subset of its own
skills to CPAN. `gather_files` in
`lib/Dist/Zilla/Plugin/DBIO/GatherSkills.pm` (dbio-dzil) copies each named skill
dir from `.claude/skills/` into `share/skills/<name>/`, `[ShareDir]` installs it,
and `DBIO::Skills` / `DBIO->skill()` reads it at runtime. **This shipped copy is
also the build's provenance record** — inspecting a released tarball shows exactly
which skills and conventions built it. That property is to be kept.

Two facts about `gather_files` decide the shape of the migration:

- It reads from **disk** (`Path::Tiny` iterator + `slurp_utf8`), not from git, and
  the **explicit `share_skill` allowlist** in `dist.ini` (`_owned`) is the
  deterministic set — the plugin's own POD states it is "independent of any
  hardlink/symlink state in the checkout". So a skilletor-managed skill that is
  git-ignored but present on disk after `skilletor sync` still ships.
- It gathers **every** file under a named dir (`next unless $file->is_file`, no
  dotfile filter) and a **missing** declared dir is only logged and skipped
  (`$self->log(... skipping)`), never fatal.

Under skilletor's default `gitignore: true`, each installed skill dir carries a
`.gitignore` (`*`). Left as is, `gather_files` would ship that management artifact
into the tarball, and a build run without a prior `skilletor sync` would silently
ship a skill-less dist.

## Decision

**The DBIO family adopts skilletor for skill/agent/rule distribution, and the
dist keeps shipping its own skill dirs as build provenance.** Concretely:

- **skilletor is the distribution tool**, replacing manage-skills across the
  family. It manages skills, the `dbio-*` agents and `dbio-rules`. The topology is
  a committed `skilletor.json` per repo, mirroring today's source order: **core**
  is the skilletor source for DBIO-owned skills and a consumer of the general
  `getty` source; **`dbio-postgresql`** and **`dbio-mysql`** are sources for their
  variant sub-families; every driver is a pure consumer.

- **Uniform `gitignore: true`.** skilletor-managed items stay git-ignored
  artifacts in every repo, core included. There is no committed second copy and no
  `git rm --cached` migration of tracked skill files. (This supersedes the earlier
  suggestion in this discussion to give core `gitignore: false`; the shipping
  contract below removes the need for it.)

- **The shipping contract is `GatherSkills`, and it does not change what ships,
  only what it filters.** The explicit `share_skill` allowlist remains the
  deterministic source of truth for the shipped set. Reading from disk after a
  `skilletor sync` is what puts the content there. Two changes, tracked in
  dbio-dzil k11:
  - `gather_files` **skips `.gitignore`** — skilletor's per-skill management file
    never enters the tarball. Only that file is dropped; `SKILL.md`, `references/`,
    `scripts/` and everything else ship. (skilletor's other artifacts — the lock,
    `skilletor.local.json`, the agent/rule ignore blocks — live at `.claude/`
    level, outside `from = .claude/skills`, and are never gathered.)
  - A skill dir named **explicitly** by `share_skill` that is **missing** becomes
    **fatal** (`log_fatal`), not a silent skip, so an unsynced build cannot ship a
    dist missing a declared skill. The name-derived fallback (`_owned` with no
    `skill` attr) stays a silent skip by design — it is "ship whatever matching
    dirs exist".

- **The build gains a `skilletor sync` prerequisite.** A release build runs
  `skilletor sync` before `dzil build`, so the declared skill dirs are on disk.
  The fatal-on-missing check is what makes that prerequisite safe rather than
  silent.

## Rationale

The shipped skill dirs are provenance: `DBIO::Skills` at runtime, and a human
reading a tarball to see under which conventions it was built. That is why the
dirs ship and why only the `.gitignore` — pure tooling metadata, meaningless in a
sharedir — is stripped, never content.

`gitignore: true` everywhere is chosen over committing artifacts because the
`share_skill` allowlist already makes the shipped set deterministic without git
tracking, and `gather_files` already reads disk. Committing skilletor's output
would mean `sync` overwriting tracked files and a `git rm --cached` migration in
every repo, for no gain the allowlist does not already give. The cost is the
`skilletor sync`-before-build step, which the fatal-on-missing guard converts from
a silent failure into a loud one (house rule 10).

Making only an **explicitly declared** missing skill fatal keeps the name-derived
fallback's "take what exists" semantics intact: the fallback is a convenience for
drivers whose skills are named after the dist, where "none present" is a valid
answer, not an error.

## Consequences

- One central change in `GatherSkills` (dbio-dzil), then `dzil install` of the
  pluginbundle, fixes the whole family at once — every dist builds through
  `[@DBIO]`. This is the **prerequisite that lands before any repo switches to
  skilletor**; migrating first would start shipping `.gitignore` files to CPAN.
- Release/CI must `skilletor sync` before `dzil build`. A fresh clone built
  without it now **fails loud** on the first declared-but-missing skill instead of
  shipping a skill-less tarball.
- The migration is a per-repo cutover across the live family (~18 repos). Per
  house rule 8 it runs **serially**, not as parallel mutating agents.
  `dbio-informix` is skipped (abandoned); `dbio-deprecated`, `dbio-forked` and
  `dbio-dzil` are assessed for whether they consume skills at all.
- The hardlink-inode discipline is retired once the cutover completes: the
  `cat >`-only editing rule, the "no `git stash` with hardlinked skills" rule and
  manage-skills drift-triage no longer apply. skilletor's rule replaces them —
  never hand-edit a managed file; edit the source and re-`sync`. Updating
  `CLAUDE.md`, `dbio-rules.md` and the affected memories is follow-up to the
  cutover, not part of this ADR (done with the cutover — see the addendum of
  2026-10-04).
- **Repo-checkout visibility — settled with the cutover.** With `gitignore: true`,
  a consuming repo's git checkout does not show the skill dirs; they are visible in
  the skilletor **source** repo and in the **built tarball** (the provenance
  requirement is met at the tarball). The `gitignore: false` variant for the
  shipping dists (committed artifacts) was the alternative; the family was cut
  over with uniform `gitignore: true`, and that is what holds.

## Addendum 2026-10-04 — accepted: the family is cut over (karr k259)

dbio-dzil k11 landed (`gather_files` skips `.gitignore`; an explicitly declared
`share_skill` that is missing is fatal), and on 2026-10-04 the family — 20 repos,
`dbio-informix` left out — moved from manage-skills hardlinks to skilletor, one
commit per repo. What stands now:

- **Sources.** `getty`, `karr` and `dbio-core`, plus `dbio-postgresql` and
  `dbio-mysql` for their variant sub-families. The committed
  `.claude/skilletor.json` names them by https URL; a user-level
  `~/.claude/skilletor.json` may point them at local checkouts.
- **Skills, rules and agents all moved.** A driver installs the family skills,
  the house rules (`.claude/rules/.local.dbio-rules.md`) and the shared agents
  `dbio-adr-auditor`, `dbio-release-manager` and `karr-coordinator`
  (`.claude/agents/.local.<name>.md`) from core, and renders its worker from
  core's `dbio-driver-worker` template with the vars `driver`, `dist_label` and
  `worker_skills`. A driver whose worker needs text of its own keeps a tracked
  one. In core the same files are the tracked sources.
- **A fresh clone is not briefed until `skilletor sync` has run.** Everything
  installed is git-ignored. skilletor runs at user level; no repo's
  `.claude/settings.json` triggers it.
- **A managed file is never edited where it is installed.** Change the source,
  then `skilletor sync`. This replaces the hardlink discipline of ADR 0015.
- The house documents say so: core's `CLAUDE.md`, the house rules, the skills
  `dbio-coordination`, `dbio-perl-release` and `dbio-consolidate-release`, and
  `docs/driver-claude-md-template.md`.

## Future architecture work (tracked cross-repo, not here)

> All three items are done as of 2026-10-04 — see the addendum above. The list
> is kept as the record of what the decision left to follow.

- **dbio-dzil k11** — `GatherSkills`: skip `.gitignore` in `gather_files`; make an
  explicitly declared but missing `share_skill` fatal. The enabling prerequisite;
  lands first, then `dzil install` the bundle.
- **Per-repo skilletor cutover** — one card per repo, filed by the coordinator
  when k11 has landed: add `skilletor.json`, `skilletor install` the items that
  were hardlinked, drop the manage-skills links, verify the suite (core: confirm
  `GatherSkills` still ships the `share_skill` set and `dzil build` is clean).
  Serial, `dbio-informix` skipped.
- **House-doc follow-up** (core) — once the family is migrated: update `CLAUDE.md`,
  `dbio-rules.md` and the hardlink-related memories to the skilletor model.
