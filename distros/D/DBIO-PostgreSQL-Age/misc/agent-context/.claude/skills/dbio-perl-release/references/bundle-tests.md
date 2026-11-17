# Reference tests of the `[@DBIO]` bundle (dbio-dzil)

The tests in `dbio-dzil` are the executable reference for the bundle; read them when
unsure what `[@DBIO]` does.

- `t/10-bundle.t` — resolves `[@DBIO]` via `Dist::Zilla::Tester` and pins the
  `core = 1` vs driver branches (both: DBIO::CodebergMeta, DBIO::GatherSkills +
  ShareDir; core-only: VersionFromMainModule + MakeMaker::Awesome + ExecDir;
  driver-only: `@Git::VersionManager`), the `share_skill` → GatherSkills
  passthrough, and the versioning policy (RewriteVersion/Bump patch
  `:InstallModules` with `global = 1` — every module is versioned).
- `t/20-podweaver.t` — weaves a sample through `@DBIO` / `@DBIO::Heritage` and
  pins how `# ABSTRACT:` → NAME and `=attr`/`=method` → ATTRIBUTES/METHODS, plus
  the DBIx::Class copyright the Heritage variant adds.
- `t/30-codebergmeta.t` — pins how `DBIO::CodebergMeta` parses the git remote
  and assembles the repository/bugtracker/homepage resources.
- `t/40-bundle-coverage.t` — pins how the bundle wires `DBIO::CoverageGate` behind
  the build plugin, its `coverage_threshold` (default 80, `0` = off) and its verdict
  on a real `cover_db/`.
- `t/50-gatherskills.t` — pins `DBIO::GatherSkills`: a declared `share_skill`
  whose dir is missing is fatal, skilletor's per-skill `.gitignore` is not shipped.
- `t/60-agentcontext.t` — pins the `misc/agent-context/` snapshot
  (`GatherAgentContext`).
- `t/70-bundle-podchecker.t` — pins the POD gate: an unresolved internal link in
  a built module turns the generated test red, naming file and link; without
  `AUTHOR_TESTING` it skips.
- `t/80-bundle-versionlockstep.t` — pins the lockstep test (`core = 1` only): a
  module whose `$VERSION` is missing or differs turns the generated test red.
- `t/90-docs.t` — pins the plugin documentation (ABSTRACT lines, the SetMeta
  DESCRIPTION).
- `t/100-licensefile.t` — pins `DBIO::LicenseFile`: a missing or stale `LICENSE`
  stops the build.
- `t/compile.t` — the bundle and the Pod::Weaver bundle load.
