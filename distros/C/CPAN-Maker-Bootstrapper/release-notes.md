# CPAN::Maker::Bootstrapper 2.4.0

Version 2.4.0 significantly expands CPAN::Maker::Bootstrapper's ability
to bring existing Perl projects under CMB management and makes the same
project build cleanly across local development, Docker, and CI.

The import workflow is now a complete conversion path rather than
simply a file-copying mechanism, while the CI builder has been reduced
to a cleaner responsibility: build the project it is given.

## Importing Existing Projects

CMB can now bootstrap many existing Perl projects with little more than:

```
cd Foo-Bar
cmb --import .
```

When a single import root is supplied, CMB can infer the primary module
name from the directory name. In this example, _Foo-Bar_ implies
`Foo::Bar`.

The importer now builds an explicit import plan before creating the
project. This enables several new capabilities:

- `--dry-run` displays the complete import plan without creating files
  or running the build.
- `--exclude` omits selected source trees from the import.
- `.git/`, `.hg+`, and `.svn` are always excluded.
- Conventional `t/`, `xt/author/`, `xt/release/`, and `xt/smoke/`
  trees are preserved, including test helpers and data files.
- Files that cannot be classified safely, or whose canonical
  destinations collide, are preserved under `import-errors/` for
  manual review rather than being silently discarded or overwritten.
- Common root-level change log files are preserved.
- Import destinations are checked to prevent a generated project from
  being created inside its own import source.
- `--project-tarball` creates a portable archive of the complete
  generated CMB project instead of installing it into a directory.

Imported projects are built with dependency scanning and syntax
checking enabled, linting disabled, and the test suite skipped:

```
SCAN=on
SKIP_TESTS=1
SYNTAX_CHECKING=on
LINT=off
```

Tests remain a developer-controlled validation step after import and
can be run with `make test`.

This verifies that the converted project builds without requiring an
existing codebase to immediately conform to CMB's perltidy and
perlcritic policies.

## One Build Model for Local Development and CI

The _builder_ script no longer acquires source or knows anything about
Git branches or repository hosting.

It now builds an existing project directory:

```
./builder /path/to/project
```

or the current working directory when no path is supplied.

Source acquisition belongs to the caller. GitHub Actions may perform a
checkout, another CI system may provide a workspace, and `make
build-ci` uses the developer's current working tree.

`make build-ci` therefore tests the files actually present on disk,
including uncommitted and untracked files, by mounting the source
read-only, copying it into a disposable container workspace, and
running _builder_ against that copy.

The builder also gains a simple project-controlled lifecycle:

```
    builder.env
        |
    builder-pre
        |
    make
        |
    builder-post
```

_builder.env_ provides CI-specific environment configuration, while
`builder-pre::` and `builder-post::` can be extended safely from
_project.mk_. `builder-post` runs only after a successful project
build.

## Conventional Extended Test Suites

CMB now directly supports the conventional Perl extended-test trees:

```
    xt/author/
    xt/release/
    xt/smoke/
```

with:

```
    make test-author
    make test-release
    make test-smoke
    make test-all
```

They may also be enabled through the conventional testing variables:

```
    AUTHOR_TESTING=1 make test
    RELEASE_TESTING=1 make test
    AUTOMATED_TESTING=1 make test
```

The managed test rules have been moved into _.includes/test.mk_ and
remain extensible through double-colon targets in _project.mk_.

## Quality Gates and Make Dependency State

Syntax validation is now separated from generated-source creation.

Generated _.pm_ and _.pl_ files represent generation state, while
sentinel files represent successful quality-gate processing:

```
    .checked
    .tdy
    .crit
```

This allows GNU make to rerun validation only when the source or the
prerequisites for the corresponding gate change.

Perltidy and perlcritic controls have also been clarified.
`PERLTIDY` and `PERLCRITIC` determine whether the corresponding tool
runs; `PERLTIDYRC` and `PERLCRITICRC` only select configuration
files. Both tools can now run normally without an explicit profile.

## Inspecting Resolved Defaults

The new `show-defaults` command exposes the configuration CMB has
actually resolved before a project is created:

```
    cmb show-defaults
```

For example:

```
    basedir              /home/rlauer/git
    color                on
    config_source        /home/rlauer/.gitconfig
    email                rclauer@gmail.com
    github_user          rlauer6
    installdir           /home/rlauer/git/{module-name}
    llm_api_key_helper   <not set>
    max_diff_files       50
    max_tokens           8192
    resources            github
    username             Rob Lauer
```

`show-defaults` complements `--dry-run`: one exposes resolved
configuration; the other exposes the operation CMB intends to perform.

## Other Build Framework Changes

Additional changes in 2.4.0 include:

- New _.includes/builder.mk_ and _.includes/test.mk_ managed build
  components.
- A new `dist-file` command for retrieving individual files from a
  distribution.
- `provides` is derived directly from _.pm.in_ source files rather
  than requiring generated modules first.
- _deps.mk_ is generated only when syntax checking requires it.
- `CMB_UPDATE_CHECK` and `CMB_VERSION_DRIFT` values are normalized
  case-insensitively and invalid values are rejected.
- `pre-publish::` and `post-publish::` provide extension points
  around publishing.
- PAUSE credentials are no longer expanded into echoed Make recipes.
- Managed-file updates now fail when an expected framework file is
  missing instead of silently skipping it.
- The default LLM token limit is centralized and resolved with the
  other CMB configuration defaults.
- Stable Make configuration predicates are evaluated once rather than
  recursively spawning helper processes, substantially reducing
  overhead for no-op builds.
