# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [QUICK START](#quick-start)
  * [Scaffolding a new project from the default stub](#scaffolding-a-new-project-from-the-default-stub)
  * [Bootstrapping an existing project](#bootstrapping-an-existing-project)
* [NEXT STEPS](#next-steps)
* [WHY YOU SHOULD CONSIDER USING CPAN::Maker::Bootstrapper](#why-you-should-consider-using-cpanmakerbootstrapper)
  * [The Stack](#the-stack)
  * [Best Practices Out of the Box](#best-practices-out-of-the-box)
  * [Perl Quality Tools](#perl-quality-tools)
  * [A GNU Make Tutorial in Disguise](#a-gnu-make-tutorial-in-disguise)
* [IMPORTING FILES](#importing-files)
  * [Determining the Primary Module](#determining-the-primary-module)
  * [What Gets Imported](#what-gets-imported)
  * [Excluding Import Paths](#excluding-import-paths)
  * [Previewing an Import](#previewing-an-import)
  * [Creating a Project Tarball](#creating-a-project-tarball)
  * [Import Destination Safety](#import-destination-safety)
  * [Import Build Policy](#import-build-policy)
  * [Next Steps After a Successful Import](#next-steps-after-a-successful-import)
  * [Limitations](#limitations)
  * [Importing a CLI::Simple Scaffold Tarball](#importing-a-clisimple-scaffold-tarball)
* [CONFIGURATION](#configuration)
  * [Environment](#environment)
* [INSTALLED PROJECT FILES](#installed-project-files)
* [THE PROJECT MAKEFILE](#the-project-makefile)
  * [README.md](#readmemd)
* [COMMANDS](#commands)
  * [LLM Commands](#llm-commands)
* [OPTIONS](#options)
* [THE REVIEW WORKFLOW](#the-review-workflow)
  * [Overview](#overview)
  * [Dry Run Mode](#dry-run-mode)
  * [Dispositions](#dispositions)
  * [Diminishing Returns and When to Stop](#diminishing-returns-and-when-to-stop)
  * [The Release Artifact](#the-release-artifact)
  * [Cost Management](#cost-management)
  * [See Also](#see-also)
* [PROMPT PROFILES](#prompt-profiles)
  * [Using Profiles](#using-profiles)
    * [Built-in Profiles](#built-in-profiles)
    * [Creating Custom Profiles](#creating-custom-profiles)
    * [Additional Profile Ideas](#additional-profile-ideas)
* [EXTENDING THE BUILD SYSTEM](#extending-the-build-system)
  * [Immutability Is a Feature](#immutability-is-a-feature)
  * [How the Makefile Works](#how-the-makefile-works)
  * [What Belongs in `project.mk`](#what-belongs-in-projectmk)
  * [What Does NOT Belong in `project.mk`](#what-does-not-belong-in-projectmk)
  * [Custom Template Tokens](#custom-template-tokens)
  * [Keeping the build system up to date](#keeping-the-build-system-up-to-date)
  * [Automatic Drift and Update Checks](#automatic-drift-and-update-checks)
  * [What You Should Never Modify](#what-you-should-never-modify)
  * [Dependencies Management](#dependencies-management)
    * [The local dependency library](#the-local-dependency-library)
    * [`build-mirrors`](#build-mirrors)
* [MODULINOS](#modulinos)
  * [Continuous Integration](#continuous-integration)
    * [Running builder manually](#running-builder-manually)
    * [Environment variables](#environment-variables)
    * [`builder.env`](#builderenv)
    * [Builder lifecycle hooks](#builder-lifecycle-hooks)
    * [`make build-ci`](#make-build-ci)
    * [Builder input files](#builder-input-files)
    * [`perlcritic` and `perltidy` Gates](#perlcritic-and-perltidy-gates)
    * [See Also](#see-also)
* [PREREQUISITES](#prerequisites)
* [CAVEATS](#caveats)
* [FAQ](#faq)
  * [My build is failing with a module not found error during syntax](#my-build-is-failing-with-a-module-not-found-error-during-syntax)
  * [How do I do a fast build during development?](#how-do-i-do-a-fast-build-during-development)
  * [How do I add a new module or script to the project?](#how-do-i-add-a-new-module-or-script-to-the-project)
  * [How do I include additional files in the distribution?](#how-do-i-include-additional-files-in-the-distribution)
  * [I want to pin a version or add a module the scanner missed](#i-want-to-pin-a-version-or-add-a-module-the-scanner-missed)
  * [I want to exclude a module the scanner found](#i-want-to-exclude-a-module-the-scanner-found)
  * [I edited a .pm file and my changes disappeared](#i-edited-a-pm-file-and-my-changes-disappeared)
  * [Why does my build say it has drifted from the installed bootstrapper?](#why-does-my-build-say-it-has-drifted-from-the-installed-bootstrapper)
  * [make update overwrote something I changed in a managed file](#make-update-overwrote-something-i-changed-in-a-managed-file)
  * [`make` says nothing to do but my source changed](#make-says-nothing-to-do-but-my-source-changed)
  * [How do I disable dependency scanning temporarily?](#how-do-i-disable-dependency-scanning-temporarily)
  * [How do I disable syntax checking temporarily?](#how-do-i-disable-syntax-checking-temporarily)
  * [How do I upgrade the build system?](#how-do-i-upgrade-the-build-system)
  * [I want to add a bash script to my distribution](#i-want-to-add-a-bash-script-to-my-distribution)
  * [What is `make release-notes` used for?](#what-is-make-release-notes-used-for)
  * [Can I distribute the POD in my modules separately?](#can-i-distribute-the-pod-in-my-modules-separately)
  * [Something still doesn't work - how do I report an issue?](#something-still-doesnt-work---how-do-i-report-an-issue)
* [SEE ALSO](#see-also)
* [DEPENDENCIES](#dependencies)
* [VERSION](#version)
* [AUTHOR](#author)
* [LICENSE](#license)
# NAME

CPAN::Maker::Bootstrapper - A complete build, dependency, and release framework for CPAN distributions

# SYNOPSIS

    # Bootstrap an existing project
    cd /path/to/Foo-Bar
    cmb --import .

    # Create a configuration file (recommended first-time setup)
    cmb create-config > ~/.cpan-makerrc
    export CPAN_MAKER_CONFIG=$HOME/.cpan-makerrc

    # Create a new plain Perl module project
    cmb --module My::New::Module

    # Create a CLI module project (inherits from CLI::Simple)
    cmb --module My::New::CLI --stub cli

    # Use a custom stub
    cmb --module My::Module --stub /path/to/mystub.pm

    # Import files from another project
    mkdir My-Module
    cd My-Module
    cmb -I /path/to/my-module/lib -I /path/to/my-module/bin \
     --installdir .

    # Install into a specific directory
    cmb --module My::Module --installdir ~/git/My-Module

    # Override git identity
    cmb --module My::Module --username "Rob Lauer" --email rob@example.org

    # Run a code review on a module (set API key in environment)
    cmb code-review lib/My/Module.pm    

# DESCRIPTION

`CPAN::Maker::Bootstrapper` provides a complete development framework
for building, testing, maintaining, and releasing CPAN distributions.

It can scaffold a new Perl project or import an existing one, installing
a managed build framework that carries the project from source through
testing, dependency management, distribution, and release.

Core features include:

- Continuous dependency discovery and maintenance for runtime,
test, recommended, and suggested dependencies
- Syntax checking, perltidy, perlcritic, POD checking, and other
build-time quality gates
- Hermetic project-local dependency installation coupled with
syntax checking of modules and scripts to expose undeclared
dependencies
- Extensible project-specific build logic through `project.mk`
without modifying managed build files
- Semantic versioning, release-note generation, CPAN publishing,
and CI workflow support
- DarkPAN dependency manifests for distributions that depend on
modules published outside CPAN
- Build-system update checks and managed-file drift detection,
with support for upgrading and refreshing the framework
- AI-assisted code review, POD review and generation, structured
finding annotation, and release-note generation

See ["LLM Commands"](#llm-commands) and ["THE REVIEW WORKFLOW"](#the-review-workflow) for details on the
AI-assisted development tools.

_NOTE: Check out the
[release-notes](https://github.com/rlauer6/CPAN-Maker-Bootstrapper/tree/main/release-notes)
directory in the GitHub project for examples of release notes generated by
the LLM._

# QUICK START

Install the bootstrapper and its dependencies:

    cpanm CPAN::Maker::Bootstrapper

_Note: Before scaffolding your first project, consider running `create-config`
to set up a personal configuration file - it pre-populates your git
identity, GitHub username, and preferred project directory so you never
have to pass them on the command line. See ["CONFIGURATION"](#configuration) for details._

## Scaffolding a new project from the default stub

    cmb --module My::Module

or

    # create a directory for the new CPAN distribution
    mkdir My-Module

    # cd into the directory
    cd My-Module

    # scaffold the project
    cmb --installdir .

The bootstrapper derives the primary module name from the directory
name (`My::Module` in this example). It then installs the build
system, generates the stub source and test files, and runs `make`
automatically to create the first distribution tarball.

By default the final build step applies full linting: syntax
checking (`perl -wc`), perltidy conformance, and perlcritic at its
default severity (5 - the most severe violations only).

## Bootstrapping an existing project

If you already have a Perl project, run `cmb` from the project root
and import the current directory:

    cd Foo-Bar
    cmb --import .

When exactly one import directory is supplied and neither `--module`
nor `--installdir` determines the module name, the bootstrapper derives
the primary module name from the import directory. In this example,
`Foo-Bar` implies `Foo::Bar`.

Use `--dry-run` first if you want to inspect the import plan without
creating files or running the generated build:

    cmb --import . --dry-run

You may also import from multiple directories and specify the primary
module explicitly:

    cmb --module Foo::Bar 
        --import lib 
        --import bin 
        --installdir /tmp/Foo-Bar

# NEXT STEPS

- Review the project source

    For a newly scaffolded project, edit the generated source file:

        lib/My/Module.pm.in

    For an imported project, review the `.pm.in` and `.pl.in` files
    created from the imported modules and scripts.

    Files ending in `.in` are the editable project sources. The generated
    `.pm` and `.pl` files are build artifacts and will be overwritten by
    subsequent `make` invocations.

- Review the framework's populated artifacts
    - `buildspec.yml` - controls how the distribution is built

        See [CPAN::Maker](https://metacpan.org/pod/CPAN%3A%3AMaker) for details regarding `buildspec.yml`.

    - `requires` - found dependencies
    - `test-requires` - test dependencies
    - `recommends` - recommended dependencies
    - `suggests` - optional dependencies
- Manage the project version

    The bootstrapper creates a `VERSION` file containing the semantic
    version number for the project. New projects begin at `1.0.0`.

    Use the version targets to increment it:

        make release    # 1.0.0 -> 1.0.1
        make minor      # 1.0.1 -> 1.1.0
        make major      # 1.1.0 -> 2.0.0

    If you imported the primary module rather than generating it from a
    stub, make sure its version declaration uses the project version token:

        our $VERSION = C<E<64>PACKAGE_VERSIONE<64>>;

    When `make` generates the `.pm` file from its `.pm.in` source,
    `@PACKAGE_VERSION@` is replaced with the value from
    `VERSION`.

- Add More Modules, Scripts, and Tests

    As your project grows, add new modules beneath `lib/` as `.pm.in`
    files and scripts beneath `bin/` as `.pl.in` files. The build system
    discovers them automatically - no Makefile changes are required.

    Distribution tests belong beneath `t/`.

    Additional test suites may use the conventional extended-test
    directories:

        xt/author/
        xt/release/
        xt/smoke/

    These suites can be run explicitly with `make test-author`,
    `make test-release`, and `make test-smoke`, or together with
    `make test-all`.

- Add additional files to the distribution

    Edit `buildspec.yml` to declare additional files that should be
    included in the distribution.

    Files may be added at the distribution root or installed beneath the
    distribution's share directory.

    For example:

        extra-files:
          - ChangeLog
          - share:
            - config/example.ini
            - defaults.json

    Use root-level entries for files that should be packaged but not
    installed into the share directory.

    Use the `share` section for files that should be installed as
    distribution data.

    See ["How do I include additional files in the distribution?"](#how-do-i-include-additional-files-in-the-distribution) for
    more details.

- Rebuild Your Distribution

    When you are ready to rebuild the project:

        make

    The default build applies the project's dependency and quality gates,
    regenerates derived source files and documentation as needed, and
    produces the CPAN distribution tarball.

    When dependency scanning is enabled, changed source files are scanned
    and the dependency artifacts are updated only when their contents have
    changed:

        requires
        test-requires
        recommends
        suggests

    The build also regenerates `README.md` when required and rebuilds only
    those derived artifacts whose prerequisites have changed.

    For a faster development build that skips dependency scanning and both
    lint tools while retaining syntax checking, use:

        make quick

- Verify the Distribution Installs Cleanly

    After building the distribution, install the generated tarball with
    `cpanm` to verify that it can be consumed independently of the source
    tree:

        cpanm --local-lib=$HOME My-Module-*.tar.gz

    This exercises the packaged distribution and its declared
    dependencies through the normal CPAN installation path rather than
    through the project's development build environment.

- Put Your Project Under Source Control

    Initialize the repository and stage the project files recommended by
    the build system:

        make git

    By default, `make git` creates the initial commit after staging the
    managed build files, project configuration, editable source files, and
    other tracked project artifacts.

    If you want to initialize and stage the project without creating the
    commit yet, use:

        make git NO_COMMIT=1

- Learn More About `CPAN::Maker::Bootstrapper`

    See ["EXTENDING THE BUILD SYSTEM"](#extending-the-build-system) for adding project-specific build
    logic and customizing the managed build framework.

    See ["Dependencies Management"](#dependencies-management) for details on dependency discovery,
    classification, filtering, and generated dependency artifacts.

    See ["FAQ"](#faq) for common questions and practical recipes.

# WHY YOU SHOULD CONSIDER USING CPAN::Maker::Bootstrapper

Many build systems place the build procedure inside the CI platform:
workflow files describe the steps, the CI runner executes them, and a
separate local workflow is needed to reproduce the same build.

`CPAN::Maker::Bootstrapper` takes the opposite approach.

The build belongs to the project.

The same dependency graph, quality gates, generated artifacts, tests,
and distribution rules run whether `make` is invoked on your laptop,
on a remote host, inside `make build-ci`, or from GitHub Actions.

CI is therefore a caller of the build system rather than the place
where the build system lives.

A fresh checkout remains directly buildable with:

    git clone <repository>
    cd <project>
    make

The CI layer can add isolation and automation, but it does not define a
second build procedure that must be kept synchronized with local
development.

## The Stack

The build system is built on three tools with deliberately different
responsibilities:

- **GNU make** - models causality.

    Targets, prerequisites, timestamps, pattern rules, and order-only
    dependencies describe what must be rebuilt and why. Make decides what
    work is necessary.

- **bash** - performs process orchestration.

    Shell recipes connect command-line tools, manage files and temporary
    state, and express the small imperative steps needed to carry out a
    build action.

- **Perl** - handles transformations that deserve a real
programming language.

    Dependency analysis, metadata generation, configuration processing,
    distribution assembly, and other non-trivial transformations remain
    readable and testable Perl rather than growing into increasingly
    complex shell fragments.

`CPAN::Maker::Bootstrapper` provides the conventions that connect
those layers.

GNU make owns the dependency graph, bash performs the orchestration,
and Perl implements the complex transformations. The result is a
build system that remains visible and auditable: `make -n` shows what
would run, `bash -x` exposes shell execution, `make help` documents
the available targets, and `project.mk` provides an upgrade-safe place
for project-specific behavior.

## Best Practices Out of the Box

The installed build system makes several professional development
practices part of the project structure without forcing them on the
developer on every build:

- **Editable source and generated artifacts are distinct** -
`.pm.in` and `.pl.in` files are the project sources; the corresponding
`.pm` and `.pl` files are generated artifacts. Changes belong in the
`.in` files and are propagated by `make`.
- **Dependencies are derived from the source** -
`scandeps-static.pl` maintains `requires`, `test-requires`,
`recommends`, and `suggests` as the source changes. Pinning, sticky
entries, and skip lists allow the generated dependency model to be
adjusted when necessary.
- **Quality checks are part of the dependency graph** -
syntax checking, `perltidy`, `perlcritic`, and POD validation are
build gates rather than separate release-time procedures. The gates
remain independently controllable when a project needs different
development or runtime behavior.
- **Managed build policy remains upgradeable** -
`make update` refreshes the build framework installed beneath
`.includes/`, while `make upgrade` checks for and installs newer
versions of `CPAN::Maker::Bootstrapper`.
- **Project-specific behavior stays outside managed files** -
`project.mk` is the upgrade-safe extension point for custom targets,
additional dependencies, lifecycle hooks, and project-specific
variables. Projects extend the framework without modifying the files
maintained by the bootstrapper.

## Perl Quality Tools

The build system supports syntax checking, perltidy, and perlcritic as
build-time quality gates.

Syntax checking is controlled independently with `SYNTAX_CHECKING`:

    make SYNTAX_CHECKING=OFF

Perltidy and perlcritic are controlled by `LINT`, which acts as the
master switch for both tools:

    make LINT=OFF

The tools may also be disabled individually:

    make PERLTIDY=""
    make PERLCRITIC=""

This allows one linting tool to remain enabled while the other is
disabled.

`PERLTIDYRC` and `PERLCRITICRC` configure the corresponding tools;
they do not enable or disable them.

For example:

    make PERLTIDYRC=.perltidyrc
    make PERLCRITICRC=.perlcriticrc

If no profile is specified, the corresponding tool uses its default
configuration.

If a profile variable names a file that does not exist, the operation
fails.

Modules or scripts that cannot be syntax-checked outside their runtime
environment may be added to `PERLWC_SKIP` in `project.mk`:

    PERLWC_SKIP = bin/startup.pl

Inter-module build dependencies may also be declared explicitly in
`project.mk` when they cannot be inferred automatically:

    lib/Foo/Bar.pm: lib/Foo.pm

`make quick` provides a fast development build that disables
distribution dependency scanning and both lint tools while leaving
syntax checking enabled:

    make quick

This is equivalent to:

    make SCAN=OFF LINT=OFF

## A GNU Make Tutorial in Disguise

Because the build system is implemented with ordinary GNU make, the
managed files beneath `.includes/` are also working examples of the
techniques used to model a non-trivial build.

They include:

- Pattern rules and sentinel files for incremental quality gates
- `define`/`endef` blocks for reusable shell and Perl fragments
- `$(shell ...)`, `$(eval ...)`, `$(call ...)`,
`$(filter-out ...)`, `$(addprefix ...)`, and `$(patsubst ...)` for
deriving and transforming build state
- `?=`, `:=`, `+=`, and `=` with their distinct evaluation
semantics
- Order-only prerequisites, `.DEFAULT_GOAL`, `-include`, and
`.SHELLFLAGS := -ec`
- `mktemp`, shell traps, and bash conditionals inside recipes
- Perl programs embedded in make variables when a transformation
is better expressed in Perl than in shell

The build system is deliberately transparent to not only reveal _how
the sausage is made_ but to expose these techniques to the developer
so you can incorporate them in your recipes. However, the build sysetm
framework itself is read-only to discourage you from tampering with a
complex set of recipes that have been carefully crafted and can easily
be broken. Your extension point remains the `project.mk` file and the
double-colon targets.

# IMPORTING FILES

The `--import|-I` option allows you to bring existing Perl source
files into a new Bootstrapper project. This is the primary mechanism
for migrating an existing project or consuming a scaffold tarball
generated by `cli-simple -scaffold`.

The `--import` option may be specified multiple times to import from
several directories in a single operation:

    cmb --module My::Script \
      --import /path/to/roles \
      --import /path/to/bin \
      --installdir .

## Determining the Primary Module

The bootstrapper determines the primary module name in the following
order:

- 1. `--module`

    If `--module` is supplied, that value is used.

- 2. Custom stub

    If no module name was supplied and `--stub` names a file, the first
    package found in that file is used.

- 3. Installation directory

    If the module name is still unknown and `--installdir` was supplied,
    the bootstrapper derives the module name from the installation directory
    name.

- 4. Single import directory

    If the module name is still unknown and exactly one `--import` path was
    supplied, the bootstrapper derives the module name from the basename of
    that directory.

    For example:

        cd Foo-Bar
        cmb --import .

    infers `Foo::Bar`.

When deriving a module name from a directory name, hyphens are converted
to `::`, so `Foo-Bar` implies `Foo::Bar`.

The resulting name must be a valid Perl module name.

When importing an existing project, the corresponding module file must
also exist beneath one of the import paths. For example, `Foo::Bar`
must be found as `Foo/Bar.pm` somewhere beneath one of the directories
supplied with `--import`.

## What Gets Imported

When importing an existing project, the bootstrapper scans each
`--import` directory and builds an explicit import plan.

The following files are recognized:

- Perl modules

    Files ending in `.pm` are imported as distribution modules and placed
    beneath `lib/`.

    For example:

        lib/Foo/Bar.pm

    becomes:

        lib/Foo/Bar.pm.in

    The package declared by the module determines its destination beneath
    `lib/`.

- Perl scripts

    Files ending in `.pl` are imported beneath `bin/` and converted to
    generated source files ending in `.in`.

- Executable files

    Executable files not otherwise classified are imported beneath `bin/`
    and converted to generated source files ending in `.in`.

- Test files and test helpers

    Files beneath the following recognized test directories are preserved in
    place:

        t/
        xt/author/
        xt/release/
        xt/smoke/

    Within those directories, files with the following extensions are
    treated as test material:

        .pm
        .pl
        .t
        .sh
        .dat

    The directory takes precedence over the file extension. For example:

        t/lib/TestHelper.pm

    remains:

        t/lib/TestHelper.pm

    and is not imported as:

        lib/TestHelper.pm.in

    Likewise:

        xt/author/check.pl

    remains beneath `xt/author/`.

- Change logs

    The following root-level change log files are preserved when present:

        ChangeLog
        CHANGELOG
        Changes
        CHANGES

    Their original names are retained.

Files not matching one of the recognized categories are not imported.

## Excluding Import Paths

Use `--exclude` to omit directories beneath an import root.

The option may be supplied more than once:

    cmb --import . 
        --exclude local 
        --exclude Foo-Bar-1.2.3

Each exclusion is interpreted relative to the import root and excludes
that directory and everything beneath it.

For example:

    --exclude local

excludes:

    local/
    local/lib/
    local/bin/

but does not exclude an unrelated directory with the same name outside
the import root.

The following source-control directories are always excluded and do not
need to be specified explicitly:

    .git
    .hg
    .svn

These directories are pruned wherever they occur beneath an import
root.

## Previewing an Import

Use `--dry-run` to inspect the import plan without modifying the
filesystem or running the generated build.

For example:

    cmb --import . 
        --exclude local 
        --dry-run

The bootstrapper scans the import directories, applies exclusions,
classifies the recognized files, determines their destinations, and
prints the resulting import plan.

No installation directory is created, no files are copied, and `make`
is not run.

This is useful when importing an existing project because it allows the
proposed mapping to be reviewed before any project files are generated.

## Creating a Project Tarball

Use `--project-tarball` to create an archive containing the complete
generated CPAN::Maker::Bootstrapper project instead of installing that
project into a directory.

For example:

    cmb --import . 
        --exclude local 
        --project-tarball

The bootstrapper performs the normal import and build process in a
temporary working directory and then writes a project archive to the
directory from which `cmb` was invoked.

For a module named `Foo::Bar`, the resulting archive is named:

    Foo-Bar-cmb.tar.gz

The archive contains a top-level project directory:

    Foo-Bar/

and includes the generated CPAN::Maker::Bootstrapper project, including
the Makefile, build configuration, imported source files, test files,
build support files, logs, and the generated CPAN distribution tarball.

This is different from the CPAN distribution tarball produced by the
build. The CPAN distribution contains the files intended for release to
CPAN; the project tarball contains the complete CPAN::Maker::Bootstrapper
development project used to build that distribution.

The temporary dependency installation directory used during the import
build is not included in the project archive.

## Import Destination Safety

When importing an existing project into a directory, the bootstrapper
refuses to create the generated project inside one of the directories
being imported.

For example, this is not allowed:

    cmb --import . --installdir ./converted

when `converted/` would be created beneath the import root.

The bootstrapper also refuses to use the import root itself as the
installation directory.

These checks prevent the generated project from becoming part of the
source tree while that source tree is being scanned and imported.

`--force` does not override this safety check.

The check applies only when installing the generated project into a
directory. `--project-tarball` does not create an installation
directory and therefore does not require this restriction.

## Import Build Policy

After constructing the imported project, the bootstrapper runs the
generated build to verify that the project can be built successfully.

The import build uses the following defaults:

    SCAN=on
    SYNTAX_CHECKING=on
    LINT=off

Dependency scanning and syntax validation therefore remain enabled
during import.

Linting is disabled by default because importing an existing project
should not require that project to satisfy the bootstrapper's
perltidy or perlcritic policy before it can be converted.

These defaults may be overridden through the corresponding environment
variables.

For example:

    LINT=on cmb --import .

enables linting during the import build.

This setting applies only to the bootstrap import build. The generated
project retains its normal build configuration and may enable linting
for subsequent `make` invocations.

## Next Steps After a Successful Import

After a successful build you have a complete, buildable CPAN
distribution, although it may not reflect everything you need for your
project. Typical next steps:

- 1. Review and edit the generated `buildspec.yml` - verify the
module name, author, and resource links are correct
- 2. Manually import files missed by the importer

    Your project may want to package additional files that are installed
    into the distribution's share directory. Move them into an appropriate
    directory or the root of the project and add them to the
    `buildspec.yml` file.

        extra_files:
          - ChangeLog <= included in distribution tarball, but not installed
          share:
            - config/some-file.ini  <= installs config/some-file.in into the distribution's share directory
            - my-app.json <= installs my-app.json from the root of your project into the distribution's share directory

- 3. Initialize a git repository with `make git`
- 4. Run `make tidy` if you want to format the imported source

        make tidy

    Perltidy uses `PERLTIDYRC` when configured and otherwise uses its
    default configuration.

- 5. Run `make` to produce the final distribution tarball

    By default the generated build performs syntax checking, dependency
    scanning, perltidy, and perlcritic.

    Dependency scanning may be disabled with:

        make SCAN=OFF

    Perltidy may be disabled independently with:

        make PERLTIDY=""

    Perlcritic may be disabled independently with:

        make PERLCRITIC=""

    Both lint tools may be disabled together with:

        make LINT=OFF

    To disable dependency scanning and both lint tools while retaining
    syntax checking, use:

        make quick

- 6. Test installation

        cpanm -n -v ./My-Script-1.0.0.tar.gz

## Limitations

- `--import` cannot be used with `--stub` - they are mutually
exclusive ways to create the initial source
- The importer uses the package declarations inside `.pm` files
to determine where to place them under `lib/`. If the importer cannot
match the filename with a package declaration inside the file, it will
warn and skip that file
- Imported files are not tidied automatically.

    Run `make tidy` after import if you want to format the imported source.

    If `PERLTIDYRC` is configured, that profile is used. Otherwise
    perltidy runs with its default configuration.

- Inter-module dependencies are normally detected automatically.
The build generates `deps.mk` from dependencies between modules in the
distribution so prerequisite modules are built before syntax checking
modules that depend on them.

    If a dependency cannot be inferred automatically, declare it explicitly
    in `project.mk`:

        lib/My/Script.pm: \
          lib/My/Script/Role/Frobnicate.pm \
          lib/My/Script/Role/List.pm

    See ["Inter-module dependencies"](#inter-module-dependencies) for details.

## Importing a CLI::Simple Scaffold Tarball

Suppose you have a project that used `CLI::Simple` as base class and
now want to use the `CPAN::Maker::Bootstrapper` framework.

The `import-scaffold` command is a convenience wrapper around
`--import` specifically designed to consume tarballs generated by
`cli-simple -scaffold`:

    cmb import-scaffold my-script-roles.tar.gz --module My::Script --installdir .

The tarball is extracted to a temporary directory and fed to the
importer automatically. See [CLI::Simple](https://metacpan.org/pod/CLI%3A%3ASimple) for details on generating
scaffold tarballs.

# CONFIGURATION

`cmb` can read configuration from your global `.gitconfig` or from
a separate `.ini` file. Configuration values are used when
scaffolding distributions and by the AI-assisted commands.

    git config --global user.github <your-username>

If you typically create projects in one directory, add the `basedir`
option:

    git config --global cpan-maker.basedir $HOME/git

When `--installdir` is not supplied, the bootstrapper uses `basedir`
from the configuration when one is defined. Otherwise, it uses the
current working directory as the base directory for the new project.

An explicit `--installdir` always takes precedence.

A separate configuration file may contain entries such as:

    [user]
           email = your-email@somedomain
           name = First Last
           # use to construct GitHub resource URLs
           github = github-user

    [cpan-maker]
           basedir   = /home/myhome/git
           # indicates the resources section of Makefile.PL should contain github references
           resources = github
           llm-api-key-helper = cat ~/.ssh/anthropic-api-key

- `llm-api-key-helper`

    For LLM commands (code-review, pod-review), you can specify a
    shell command that outputs your API key without exposing it in shell
    history:

        llm-api-key-helper = cat ~/.ssh/anthropic-api-key

    When set, this command is executed to retrieve the API key, avoiding
    the need to pass it on the command line or set it in the environment
    manually. This is the recommended secure approach.

    See [CPAN::Maker::ConfigReader](https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3AConfigReader) for a complete description of the
    configuration file.

    Use the `--config` option to use your custom config.

    You can generate a starter configuration with:

        cmb create-config > ~/.cpan-makerrc

    Then point `cmb` at it by setting the
    `CPAN_MAKER_CONFIG` environment variable in your shell profile:

        export CPAN_MAKER_CONFIG=$HOME/.cpan-makerrc

## Environment

- LLM\_API\_KEY

    Your Anthropic Claude API key. Set this before running any LLM command
    (code-review, pod-review, release-notes).

    The key is removed from environment so it is not inherited by child
    processes such as 'make'. This does not protect against memory
    inspection of the current process - see [LLM::API](https://metacpan.org/pod/LLM%3A%3AAPI) for how the key is
    actually stored using a closure to prevent accidental serialization
    via Dumper.

    Avoid passing the key on the command line where it might be saved in
    history and can be seen in process lists.

- CPAN\_MAKER\_CONFIG

    Path to a configuration file (in .ini format) containing user settings
    such as name, email, GitHub username, and project base directory. If
    not set, the bootstrapper will attempt to read settings from
    ~/.gitconfig.

- SCAN

    Controls dependency scanning during `make`. Set to `OFF` to disable
    distribution dependency scanning. The default is `ON`.

# INSTALLED PROJECT FILES

The following files are installed into the project directory:

- `Makefile` - the complete build system. Derives project paths
and names from `MODULE_NAME`, the package name in a custom stub, or
the project directory name. See ["THE PROJECT MAKEFILE"](#the-project-makefile).
- `buildspec.yml` - generated from the template, pre-populated
with your module name, git identity, GitHub username, and project URLs.
- `lib/<Module/Path>.pm.in` - stub module, populated from
either `class-module.pm.tmpl` or `cli-module.pm.tmpl` when
`--stub cli` is used.

    _Note: Files under `lib/` and `bin/` use `.pm.in` and `.pl.in`
    as editable sources. The generated `.pm` and `.pl` files are derived
    from them by the Makefile and will be overwritten by subsequent
    builds._

- `t/00-<project-name>.t` - minimal smoke test that calls
`use_ok` on your module.
- `.includes/` - the managed build system directory. Contains
all `.mk` files installed and maintained by the bootstrapper. These
files are write-protected and should never be edited directly. Updated
with `make update`.

        .includes/bootstrap.mk       - used internally by the bootstrapper
        .includes/bash-completion.mk - make bash-completion target
        .includes/build-init.mk      - used to initialize build-time variables
        .includes/modulino.mk        - make modulino target
        .includes/git.mk             - make git target
        .includes/help.mk            - make help target
        .includes/local.mk           - vendors dependencies for syntax checking
        .includes/perl.mk            - pattern rules, syntax checking, tidy, critic
        .includes/publish.mk         - publish to CPAN
        .includes/release-notes.mk   - make release-notes target
        .includes/test.mk            - recipes for the test targets; test, test-all, etc
        .includes/update.mk          - make update target
        .includes/upgrade.mk         - make upgrade/check-upgrade targets
        .includes/version.mk         - make release/minor/major targets

- `project.mk` - your extension point for custom make rules,
inter-module dependencies, and project-specific variables. Never
touched by `make update`. See ["EXTENDING THE BUILD SYSTEM"](#extending-the-build-system).
- `modulino.tmpl` - template used by `make modulino` to
generate bash wrapper scripts for modulino-style modules.
- `VERSION` - contains the current version string in
`major.minor.patch` format. Managed by `make release`, `make minor`,
and `make major`.
- `ChangeLog` - empty placeholder, required by the distribution.
- `.prompts/`

    The directory is created automatically the first time `pod-review`
    or `code-review` needs the default prompt files.

- `config.mk` - developer-maintained Make configuration for
persistent project build settings. This file is not managed by
`make update`.
- `build-config.mk` - generated Make configuration containing
resolved project values and discovered build helper commands. It is
created automatically as needed and should not be edited or committed.

# THE PROJECT MAKEFILE

The installed Makefile is self-configuring. It can derive the primary
module from `MODULE_NAME`, the package name inside a custom stub, or
the project directory name.

For example, a primary module of `My::New::Module` produces:

    MODULE_PATH  - lib/My/New/Module.pm (from MODULE_NAME)
    PROJECT_NAME - My-New-Module (from MODULE_NAME)
    TARBALL      - My-New-Module-1.0.0.tar.gz (from PROJECT_NAME + VERSION)

If `MODULE_NAME` is not supplied on the command line, it is inferred
from the project directory name.

At build initialization, `cmb create-build-config` resolves project
paths, defaults, and configured helper commands into `build-config.mk`,
which is then included by Make. Developer overrides belong in
`config.mk`; `build-config.mk` is generated state.

Key Makefile targets:

- `make` / `make all`

    Builds the distribution tarball. When dependency scanning is enabled,
    updates `requires`, `test-requires`, `recommends`, and `suggests`,
    and generates `README.md` as prerequisites.

- `make bash-completion`

    Generates and installs a bash completion function for your project's
    modulino, then prints the `source` line to enable it. The function is
    produced by `<modulino> -generate-completion` (available to any
    `CLI::Simple`-based modulino) and written to
    `~/.local/share/bash-completion/completions/<alias>`.

        make bash-completion
        # then, as it instructs:
        source ~/.local/share/bash-completion/completions/<alias>

    The target depends on the modulino, so it will build `bin/<alias>`
    first if needed. Completion is only available for modulinos that
    subclass `CLI::Simple`.

- `make help`

    Lists the available build targets and commonly used build variables.
    Project-specific targets in `project.mk` are included when their
    target definition contains a `##` description.

- `make requires` / `make test-requires`

    Scans source files with `scandeps-static.pl` and writes the dependency
    files specified in the `buildspec.yml` file used by `make-cpan-dist.pl`.

    Any change to your `.pm.in` files will trigger a rescan of your
    modules for new dependencies. This can add a significant delay when
    you have many modules and a large number of dependencies. You can
    avoid the scan if you know that no new dependencies have been added by
    setting the environment variable `SCAN` to `OFF` (case insensitive).

        make SCAN=OFF

    You can make scanning deliberate by adding `SCAN=OFF` to your
    `config.mk` file. Then, to rescan:

        make SCAN=ON

- `make recommends` / `make suggests`

    Companion targets to `make requires`. The dependency scanner classifies
    each discovered module into one of three tiers: hard `requires`,
    `recommends` (soft, non-eval conditional dependencies), and `suggests`
    (eval-wrapped, optional dependencies).

    These files are consumed by [CPAN::Maker](https://metacpan.org/pod/CPAN%3A%3AMaker) when it generates the
    distribution metadata, including the corresponding dependency sections
    in `Makefile.PL`. See ["Dependencies Management"](#dependencies-management).

- `DARKPAN_REQUIRES`

    Set `DARKPAN_REQUIRES` to a true value (`1`, `yes`, `on`, or
    `si`) to generate dependency manifests for modules available from a
    configured DarkPAN.

    This is useful when a distribution published to CPAN has one or more runtime
    dependencies that are intentionally hosted on a separate CPAN-compatible
    repository. CPAN metadata can still declare those dependencies normally, but
    standard installers need additional information to locate distributions that
    should be obtained from the DarkPAN.

    The generated DarkPAN manifests provide that information without duplicating
    the dependency declarations maintained in `requires`. They are included in
    the distribution as installation aids for the person or process installing
    the module. They are not automatically consulted by Perl installers during a
    normal installation; the installer must explicitly use the appropriate
    manifest or configure the DarkPAN repository.

    When enabled, `DARKPAN_URL` must specify the base URL of the
    CPAN-compatible repository:

        DARKPAN_REQUIRES = yes
        DARKPAN_URL = https://cpan.example.com/repository

    `make` examines `requires` and generates:

        cpanfile.darkpan
        cpanm.darkpan

    When `DARKPAN_REQUIRES` is enabled, `cpanfile.darkpan` and `cpanm.darkpan`
    are added to `buildspec.yml` as extra files and are therefore included
    in the distribution. They are expected to be tracked by git unless the
    developer explicitly adds them to `extra-files.skip`.

    For each module listed in `requires`, the build checks whether the module
    is available from the configured DarkPAN. Modules found there are added to
    the generated DarkPAN manifests.

    For modules available from the DarkPAN, the build also checks MetaCPAN. If
    a module is available from both CPAN and the DarkPAN, the DarkPAN version is
    preferred and the module remains in the generated manifests. This allows the
    DarkPAN to provide a version of a module that is also published on CPAN.

    Modules that should not be obtained from the DarkPAN may be listed in
    `darkpan.skip`, one module name per line. Those modules are omitted from
    both generated DarkPAN manifests.

    `cpanfile.darkpan` contains dependencies selected for resolution from
    the DarkPAN in cpanfile syntax. `cpanm.darkpan` contains the same
    dependencies in a form suitable for passing to
    [cpanm](https://metacpan.org/pod/App%3A%3Acpanminus).

    The configured DarkPAN must publish:

        modules/02packages.details.txt.gz

    under `DARKPAN_URL`.

- `make package`

    Runs the quality and dependency gates together (`lint` plus a
    dependency scan) - a convenience for pre-release verification.

- `TARBALL_ORDER_ONLY_PREREQS`

    Additional order-only prerequisites for the distribution tarball.

    Set this in `project.mk` when project-specific generated artifacts or
    other preparation steps must complete before the tarball is built but
    should not themselves determine whether the tarball is out of date.

        TARBALL_ORDER_ONLY_PREREQS += prepare-assets

- `make release` / `make minor` / `make major`

    Bumps the patch, minor, or major version number in `VERSION`.

- `make release-notes`

    Generates the diff, file list, Git status, and draft release tarball
    used as evidence for LLM-generated release notes.

- `make clean`

    Removes build artifacts registered for cleaning. Does not affect
    `buildspec.yml`, `VERSION`, or any `*.in` source files.

    If your project needs a project-specific clean recipe, use the
    `clean-local` target with a double-colon.

        clean-local::
               rm -rf workdir

- `make test`

    Runs the project's distribution unit tests under `t/`:

        prove -I lib -I local/lib/perl5 -v t/

    `make test` also runs any project-specific `test-local::` recipes
    defined in `project.mk`.

    Projects may have tests that exercise development infrastructure,
    external services, generated artifacts, or other behavior that should
    not be included in the CPAN distribution. These can be added through
    the `test-local::` extension point:

        test-local::
            ./bin/test-integration

    The double-colon form allows `project.mk` to extend the managed
    `test-local` target without replacing it.

    `make test` also recognizes the conventional extended-test
    directories `xt/author/`, `xt/release/`, and `xt/smoke/`. These
    test suites are not run by default, but may be enabled through the
    corresponding environment or make variables:

        AUTHOR_TESTING=1 make test
        RELEASE_TESTING=1 make test
        AUTOMATED_TESTING=1 make test

    When enabled, `make test` invokes the corresponding test target after
    the normal `t/` test suite and `test-local::` recipes have completed.

- `make test-author`

    Runs tests under `xt/author/`:

        prove -I lib -I local/lib/perl5 -r xt/author

    The `xt/author/` directory is created automatically if it does not
    already exist.

    This target uses a double-colon rule and may therefore be extended in
    `project.mk` without replacing the managed target:

        test-author::
            ./bin/check-generated-docs

- `make test-release`

    Runs tests under `xt/release/`:

        prove -I lib -I local/lib/perl5 -r xt/release

    The `xt/release/` directory is created automatically if it does not
    already exist.

    The target may be extended in `project.mk` using `test-release::`.

- `make test-smoke`

    Runs tests under `xt/smoke/`:

        prove -I lib -I local/lib/perl5 -r xt/smoke

    The `xt/smoke/` directory is created automatically if it does not
    already exist.

    The target may be extended in `project.mk` using `test-smoke::`.

- `make test-all`

    Runs the complete test suite: distribution tests under `t/`, any
    project-specific `test-local::` recipes, and the author, release, and
    smoke test suites.

    It is equivalent to running:

        make test AUTHOR_TESTING=1 RELEASE_TESTING=1 AUTOMATED_TESTING=1

    The extended test directories follow established Perl distribution
    conventions. `CPAN::Maker::Bootstrapper` preserves those conventions
    rather than requiring imported or existing projects to reorganize
    their tests.

- `make tidy`

    Runs `perltidy` on all `.pm.in` and `.pl.in` source files.

    If `PERLTIDYRC` is set, the named profile is used:

        make tidy PERLTIDYRC=.perltidyrc

    If `PERLTIDYRC` is not set, perltidy runs using its default
    configuration.

    If `PERLTIDYRC` names a file that does not exist, the target fails.

    The target also performs syntax checking before modifying the source
    files.

- `make critic`

    Runs `perlcritic` on the project's Perl source files.

    If `PERLCRITICRC` is set, the named profile is used:

        make critic PERLCRITICRC=.perlcriticrc

    If `PERLCRITICRC` is not set, perlcritic runs using its default
    configuration.

    If `PERLCRITICRC` names a file that does not exist, the target fails.

    The target also honors:

        PERLCRITIC_THEME
        PERLCRITIC_SEVERITY

    and performs syntax checking before running perlcritic.

- `make lint`

    Runs both linting targets:

        make tidy
        make critic

    The perltidy and perlcritic configuration variables described above
    apply to their respective targets.

- `make git`

    Initializes a git repository, stages all recommended project files
    including `.includes/*`, and makes an initial `BigBang` commit.

- `make quick`

    Builds the distribution tarball with distribution dependency scanning
    and perltidy/perlcritic disabled. Syntax checking remains enabled.

    Useful during active development when you want fast iterative builds
    without updating `requires`, `test-requires`, `recommends`, or
    `suggests`.

        make quick

    Equivalent to:

        make SCAN=OFF LINT=OFF

- `make workflow`

    Installs a CI build script (`builder`), its default environment file
    (`builder.env`), and a GitHub Actions workflow
    (`.github/workflows/build.yml`) into your project, templated with your
    module and project name. Also merges any build-only dependencies
    `builder` needs into `build-requires`.

        make workflow
        git add build-requires builder builder.env .github/workflows/build.yml

    Commit these files - GitHub Actions will then run `./builder` on
    every push to `main` or `dev`. See ["Continuous Integration"](#continuous-integration) for
    what `builder` does, how to customize its environment and build
    lifecycle, and how to run it outside of GitHub Actions.

- `make build-ci`

    Runs `builder` locally inside Docker, against your current working tree,
    to reproduce a CI build without pushing. Requires `docker` and a
    `builder` script (run `make workflow` first if you don't have one).

        make build-ci

    See ["Continuous Integration"](#continuous-integration) for the variables that control this
    target.

## README.md

The `Makefile` will automatically create a `README.md` from your
Perl module's pod. The stock `buildspec.yml` will include that
`README.md` in the distribution's share directory. If you want the
`README.md` to be included in the distribution but not installed,
edit the `buildspec.yml` file.

**Before**

    extra-files:
      - ChangeLog
      - share:
        - README.md

**After**
  extra-files:
    - ChangeLog
    - README.md

If you want to generate `README.md` from a custom source, create a
`README.md.in` file. That file will be filtered through
`md-utils.pl` (from [Markdown::Render](https://metacpan.org/pod/Markdown%3A%3ARender)) to produce a `.md` file.

# COMMANDS

- install (default)

    Scaffolds a new project. This is the default command, so:

        cmb -m My::Module

    ...is the same as:

        cmb -m My::Module install

- create-config

    Outputs a stub configuration file to STDOUT. Create and edit a new
    config to customize the behavior of `cmb`.

        cmb create-config > ~/.cpan-makerrc

    Then set `CPAN_MAKER_CONFIG` to point to it:

        export CPAN_MAKER_CONFIG=$HOME/.cpan-makerrc

- deps-filter

        cmb deps-filter requires

    Filters a dependency list so that modules already provided by another
    listed distribution are removed.

    The command consults the public CPAN package index and any repositories
    listed in `build-mirrors`. Repository indexes are cached under the
    user's cache directory and conditionally refreshed on subsequent runs.

    This command is normally invoked automatically by the generated
    Makefile for `requires`, `recommends`, `suggests`, and
    `test-requires`.

- dist-file

        cmb dist-file distribution-name filename

    Copies a distribution file to STDOUT. Searches the root and `share/`
    directories of the distribution for file. Throws and exception if
    either the file is not found or the distribution is invalid.

    Example:

        cmb dist-file CPAN-Maker-Bootstrapper builder.env

- extra-files

        cmb extra-files path file1 file2 ...

    Adds files to the distribution. Use `.` for files that should appear
    at the root of the distribution tarball but not be installed into the
    share directory. Use `share` for files that should be installed into
    the distribution share directory.

    _NOTE: file should be the relative path within the project that points to the file._

    Example:

        cmb extra-files . README.md
        cmb extra-files share share/config.json 

    Entries may be removed by editing `buildspec.yml` directly, which is
    usually the clearest approach.

    The `cmb extra-files` command also supports removing an entry by
    prefixing the filename with `-`:

        cmb extra-files . -README.md

    This is primarily useful from scripts or other automated workflows.

- create-deps

        cmb create-deps [module.pm.in ...]

    Emits GNU make dependency rules (to STDOUT) capturing the
    **inter-module** dependencies within your distribution -- i.e. which of
    your own `.pm` files `use` which others. Uses
    [Module::ScanDeps::Static](https://metacpan.org/pod/Module%3A%3AScanDeps%3A%3AStatic) to scan each source module, then prints
    `target: prerequisite` lines (in `deps.mk` form) for the internal
    packages only, so `make` rebuilds a dependent module when a module it
    depends on changes. With no arguments every project module is scanned;
    name one or more modules to restrict the output.

- create-darkpan-requires

        cmb create-darkpan-requires [--filter file] [requires-file]

    Examines `requires` (or `requires-file`) and identifies dependencies
    available from the configured DarkPAN. Each dependency is checked
    against the DarkPAN `02packages.details.txt.gz` index. Dependencies
    found on the DarkPAN are included in the generated manifests.

    For each dependency found on the DarkPAN, MetaCPAN is also checked. If the
    module is available from both CPAN and the DarkPAN, a warning is emitted and
    the DarkPAN is preferred.

    The optional `--filter` argument names a file containing module names to
    exclude from the generated manifests, one module per line:

        cmb create-darkpan-requires --filter darkpan.skip requires

    This is useful when a module is available from both CPAN and the DarkPAN but
    the distribution author wants that dependency to be resolved from CPAN.

    When invoked through the generated Makefile, `darkpan.skip` is used
    automatically when it exists.

    The presence of `darkpan.skip` affects only which dependencies are
    written to the manifests; it does not change the distribution or
    source-control treatment of the generated files.

    The generated files are intended as installation aids and are included with
    the distribution. They do not alter normal Perl dependency resolution by
    themselves and are not automatically consulted during installation. Instead,
    they are intended to be consumed explicitly by your installation tool, such
    as `cpm` or `cpanm`.

    For distributions that include these files, the `cpan-distfile` utility
    provided with [DarkPAN::Resolver::SQLite](https://metacpan.org/pod/DarkPAN%3A%3AResolver%3A%3ASQLite) can be used to retrieve them
    directly from a CPAN distribution without manually downloading and unpacking
    the tarball.

        cpan-distfile Some::Module cpanm.darkpan > cpanm.darkpan

    See [DarkPAN::Resolver::SQLite](https://metacpan.org/pod/DarkPAN%3A%3AResolver%3A%3ASQLite) for examples of using these manifests with
    `cpm` and `cpanm`.

    The command generates two representations of those dependencies:

        cpanfile.darkpan
        cpanm.darkpan

    `cpanfile.darkpan` uses cpanfile syntax:

        requires 'Amazon::API::CloudWatchLogs', '1.43.90';

    `cpanm.darkpan` contains one cpanm module requirement per line:

        Amazon::API::CloudWatchLogs~1.43.90

    The version constraints are taken from `requires`; the DarkPAN index
    is used only to determine whether a module is available from a DarkPAN
    repository.

    This command is normally invoked automatically by `make` when
    `DARKPAN_REQUIRES` is enabled.

- critique

        cmb critique file ...
        cmb critique --file-list manifest

    Runs [Perl::Critic](https://metacpan.org/pod/Perl%3A%3ACritic) over the given files (or a newline-delimited
    `--file-list`). Defaults to the `pbp` theme at severity 5; override
    with the `PERLCRITIC_THEME`, `PERLCRITIC_SEVERITY`, and
    `PERLCRITICRC` environment variables. Requires [Perl::Critic](https://metacpan.org/pod/Perl%3A%3ACritic) to be
    installed.

- publish-to-cpan

        cmb publish-to-cpan distribution.tar.gz [username [password]]

    Uploads a distribution tarball to PAUSE.

    The username and password may be supplied as arguments or through
    `PAUSE_USER` and `PAUSE_PASSWORD`. Normally this command is invoked
    by `make publish`, which rebuilds and tests the distribution before
    uploading it.

- resolve-vars

        cmb resolve-vars [--vars-file FILE] [--no-strict] source-file

    Filters `source-file` to STDOUT, substituting `@TOKEN@` placeholders
    with values drawn from the environment (or from a `--vars-file`). This
    is the mechanism the generated `Makefile` uses to turn `.pm.in` and
    `.pl.in` sources into their built `.pm`/`.pl` counterparts -- for
    example filling `2.4.1` from the `VERSION` file or
    `@BUILD_DATE@` at build time.

    A placeholder is required to have a value only when it appears in live
    code. Placeholders that occur solely inside POD or `#` comments are
    treated as references, not substitutions: they never trigger a "no
    value present" error and are left untouched when no value is
    available. This lets you document a token in your POD (e.g. mention
    `@BUILD_DATE@` in a description) without breaking the build.

    For placeholders that _do_ appear in code, behavior depends on
    `--strict` (the default):

    - **strict** (default) - a placeholder in code with no value is a
    fatal error; the build stops.
    - **--no-strict** - a placeholder in code with no value produces a
    warning and is left in place literally (as `@TOKEN@`) rather than being
    substituted to an empty string.

    See ["`--vars-file`"](#vars-file) and ["`--strict, --no-strict`"](#strict-no-strict).

## LLM Commands

The following commands require [LLM::API](https://metacpan.org/pod/LLM%3A%3AAPI) to be installed and a valid
Anthropic API key. Set it in the environment before running any LLM command:

    export LLM_API_KEY=$(cat ~/.ssh/anthropic-api-key)

The key is deleted from the environment immediately after being read and
is never passed to child processes. See [CPAN::Maker::ConfigReader](https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3AConfigReader) for
the `llm-api-key-helper` option which avoids exposing the key in shell
history entirely.

_SECURITY NOTE: Never pass your API key on the command line where it
would be visible in shell history and process listings._

- code-review

    Submits a Perl module or script to the LLM for a code review. POD is
    automatically stripped before submission so token costs reflect code
    only. The review is written as a JSON file to the current directory.

        cmb code-review [options] lib/My/Module.pm

    The review file is named:

        <module>-review-<timestamp>.code

    A token usage summary is printed to stderr after the review completes.

    If a review has been completed at least once the annotated review file
    is automatically sent with your code to re-focus the review. You must
    annotate the review file before resubmitting by running the
    `annotate` command and marking each finding with a valid
    disposition. See ["THE REVIEW WORKFLOW"](#the-review-workflow) for details.

    Options specific to code-review:

        --prompt|-p PATH          path to a custom review prompt file
        --prompt-profile|-P NAME  additive prompt profile (repeatable)
        --context|-C PATH         context file to submit alongside the review (repeatable)

    _Note: The prompt profile list and the context file list are written
    to the review output file. On subsequent runs these will be read from
    the review. You do not need to provide them unless you want to update
    their values._

- annotate

    Applies disposition tags to findings in the latest review file and
    displays the current annotation state. Must be run from a project
    directory (one containing `.includes/`).

        cmb annotate [options] lib/My/Module.pm

    Without options, displays the current annotation state of the latest
    review file. With `-a` options, applies the specified dispositions
    before displaying.

        cmb annotate lib/My/Module.pm
        cmb annotate -a 1:wrong -a 2:reject lib/My/Module.pm

    Options:

        --annotate|-a N:DISPOSITION    apply disposition to finding N (repeatable)
        --auto-annotate|-A             annotate and immediately submit the next review
        --finalize-annotations|-F      create versioned release artifact

    Valid dispositions are `accept`, `reject`, `wrong`,
    `wrong-reconsider`, `defer`, and `confirmed` (case
    insensitive). See ["THE REVIEW WORKFLOW"](#the-review-workflow) for a description of each.

- pod-finding

        cmb pod-finding lib/CPAN/Maker/Bootstrapper.pm

    Run this after a `pod-review` command to display a table of findings.

- pod-review

    Submits a Perl module or script to the LLM for a documentation review.
    The full file including code is submitted so the LLM can check
    consistency between implementation and documentation.  If no POD
    exists, the LLM generates complete POD documentation suitable for
    placement after `__END__`.

        cmb pod-review lib/My/Module.pm

    The review file is named:

        <module>-review-<timestamp>.pod

- release-notes

    Generates release notes for a given version using the LLM. Requires
    the release artifacts produced by `make release-notes`:

        release-<version>.diffs
        release-<version>.lst
        release-<version>.status
        release-<version>.tar.gz

        cmb release-notes <version>

    The generated release notes are written to
    `release-notes-<version>.md`.  Binary files are automatically
    excluded. Use `--max-diff-files` to cap token consumption on large
    distributions (default: 50, 0 = unlimited).

- code-finding

    Generates a table with the complete details of a finding.

        cmb code-finding lib/My/Module.pm 1

- show-defaults

    Prints the resolved default option values to STDOUT after applying
    configuration-file values and runtime defaults.

- update-annotations

        cmb update-annotations file

    Applies human-curated annotations to the most recent code review for
    `file`. On first run it generates an `.annotate` file alongside the
    review for you to edit; re-run it to apply your edited annotations back
    into the review. Pairs with `code-review`/`annotate` in the review
    workflow.

# OPTIONS

- `--annotate|-a` N:DISPOSITION

    See ["THE REVIEW WORKFLOW"](#the-review-workflow)

- `--auto-annotate|-A`

    See ["THE REVIEW WORKFLOW"](#the-review-workflow)

- `--basedir|-b` DIR

    Base directory in which to create the project. Defaults to the
    current working directory when `--installdir` and `--basedir` are not
    provided. The directory must exist or the script will throw an
    exception.

    _Note: If `--installdir` is provided it takes precedence and
    `--basedir` is ignored._

    default: pwd

- `--color|--no-color`

    default: color

    To turn color off use --no-color.

- `--dry-run|-D`

    Dry run mode will abort after displaying a pre-submission token and
    cost estimation for the `pod-review` and `code-review` commands.

- `--config|-c` configuration file

    The path to a `.ini` file that contains configuration information
    used to scaffold your project.

    default: ~/.gitconfig

- `--context|-C` PATH

    One or more files to submit with your code review file that provide
    additional context for the LLM during the review.

- `--email|-e` EMAIL

    Override the author email. Defaults to `user.email` from your global
    git config.

- `--finalize-annotations|-F`

    See ["THE REVIEW WORKFLOW"](#the-review-workflow)

- `--force|-f`

    Overwrite an existing project. Without this flag, the command dies if a
    `Makefile` already exists in the target directory.

- `--github-user|-g` USER

    Override the GitHub username used to construct repository URLs in
    `buildspec.yml`. Defaults to `user.github` from your global git config.

- `--import|-I` path

    A path that contains `.pm` or `.pl` files for importing into the
    project. You can specify multiple paths. You cannot use `--stub` and
    `--import` together.

    Example:

        cmb --module Foo::Bar -I ~/foo-bar/lib -I ~/foo-bar/bin

    - The primary module must be determinable from either directory
    name or supplied using the `--module` option. The corresponding
    module file must exist beneath one of the import paths.  For example,
    `Foo::Bar` must be found as `Foo/Bar.pm`.
    - The `Makefile` will automatically attempt to substitute the
    token `@PACKAGE_VERSION@` inside your `.pl.in` or `.pm.in`
    files with the current semantic version in the `VERSION` file. If you
    want to use that for versioning your scripts and modules add the token
    as shown below:

            C<our $VERSION = 'E<64>PACKAGE_VERSIONE<64>';>

- `--installdir|-i` DIR

    Directory in which to create the project. When supplied, this overrides
    the configured or command-line `basedir`. The directory is created if
    it does not exist.

    Example:

        cmb --installdir ~/git/My-Module

    The install directory should include the project name.

    _Note: `--installdir` overrides `--basedir`_.

- `--max-diff-files` LIMIT

    The maximum number of changed files included in the release artifact
    that may be uploaded to the LLM when generating release notes. Set to
    `0` for no limit.

    default: 50

- `--max-tokens|-t` TOKENS

    Maximum number of tokens the LLM may return in a single response.
    Higher values reduce the risk of truncated reviews on large files.

    default: 4096 (set by [LLM::API](https://metacpan.org/pod/LLM%3A%3AAPI))

- `--model|-M` MODEL

    Specifies the model id to use for the `pod-review` and `code-review`
    commands.

    For `pod-review` the default model is `claude-haiku-4-5-20251001`.

    For `code-review` the default model is `claude-sonnet-4-6`.

    The Haiku model tends to be better at summarizing documentation and
    avoiding unnecessary analysis around edge cases that contribute to
    noise.

    _Caution: Both models try hard to find issues to the point that you
    will almost never get a clean run when asking for a POD review. When
    your POD is complete, accurate and usable it's good enough. Avoid
    shaving the yak!_

- `--module|-m` MODULE

    The Perl module name for the new project, e.g. `My::New::Module`.
    Used to derive the project directory name, source file path, and
    tarball name.

    You may omit this option when the module name can be determined from
    a custom stub file or from the project directory name.

- `--prompt|-p` PATH

    Path to a text file that will be used to prompt the LLM for a code or pod review.

    defaults:

        pod  => .prompts/pod-review.prompt
        code => .prompts/code-review.prompt

- `--prompt-profile|-P` NAME

    The name of a prompt profile located in the `.prompts` directory. One
    or more profile names may be specified. You need only provide the name
    (e.g. cli-tool).

    See ["PROMPT PROFILES"](#prompt-profiles)

- `--resources|-r` github

    Currently takes only a single value: 'github' that indicates that the
    resources section of `Makefile.PL` should be populated with GitHub
    URL references. Future versions may support additional providers.

- `--strict`, `--no-strict`

    Controls how `resolve-vars` treats an `@TOKEN@` placeholder that
    appears in code but has no value in the environment or `--vars-file`.
    `--strict` (the default) makes this a fatal error. `--no-strict`
    downgrades it to a warning and leaves the placeholder literal in the
    output.

    This affects code placeholders only. Placeholders that appear solely in
    POD or `#` comments are always ignored by the missing-value check
    regardless of this flag, so `--no-strict` is not needed merely to
    document a token.

- `--stub|-s` TYPE|PATH

    Controls the module stub used to generate the initial `.pm.in` source
    file. Three forms are accepted:

    - Omitted - uses the default plain class stub (`class-module.pm.tmpl`).
    - `cli` - uses the CLI stub (`cli-module.pm.tmpl`), which
    inherits from [CLI::Simple](https://metacpan.org/pod/CLI%3A%3ASimple) and includes a skeleton `main`, `init`,
    and a placeholder command.
    - A file path - uses the specified file as the stub. The file
    must exist or the command will die with an error. This allows you to
    supply your own template or bootstrap a project around a module you
    have already started writing. You can omit the `--module` option if
    you supply your own stub file. See the explanation for the
    `--module` option for details.

    When specifying a stub you cannot use the `--import` option.

- `--username|-u` NAME

    Override the author name used in the module stub and `buildspec.yml`.
    Defaults to `user.name` from your global git config.

- `--vars-file`

    The path to a file containing template variable values used by
    `resolve-vars`.

# THE REVIEW WORKFLOW

`CPAN::Maker::Bootstrapper` allows you to implement a structured
iterative code review workflow built around JSON review files and
developer-applied disposition annotations. The workflow converges over
several rounds, with each round potentially costing less as noise is
suppressed and findings are resolved.

## Overview

Each review round consists of three steps:

- 1. Run a review

        cmb code-review --prompt-profile cli-tool lib/My/Module.pm

    The review is written to a timestamped `.code` file containing a JSON
    object with `findings`, `confirmations`, and `deferred` arrays.

- 2. Annotate the findings

    An annotation is how you mark a finding with a disposition. The
    dispositions are used by the LLM during the next review. See ["Dispositions"](#dispositions).

        cmb annotate lib/My/Module.pm

    This displays the current annotation state. Apply dispositions with
    `-a` options:

        cmb annotate -a 1:accept -a 2:wrong -a 3:reject -a 4:defer lib/My/Module.pm

    You can annotate incrementally across multiple invocations. Each call
    shows the updated state so you always know what remains.

    Alternatively, use `update-annotations` to maintain dispositions in an
    annotation file rather than on the command line:

        cmb update-annotations lib/My/Module.pm

    The first invocation creates an `.annotate` file for editing. Run the
    command again after editing the file to apply those dispositions to the
    review.

- 3. Submit the next review

    Once all findings are annotated and code updated if necessary, run the
    next review. The bootstrapper automatically finds and submits the
    latest annotated review file with your updated code:

        cmb code-review lib/My/Module.pm

    Alternatively, use `--auto-annotate|-A` with the `annotate` command
    to annotate and immediately resubmit in one step:

        cmb annotate -a 1:wrong -a 2:reject --auto-annotate \
          lib/My/Module.pm

    The LLM will honor all dispositions from the prior round, confirm
    fixes marked `ACCEPT`, carry forward `DEFER` items, and suppress
    `REJECT` and `WRONG` findings. New findings appear without noise
    from settled questions.

## Dry Run Mode

Before the prompt and code are submitted for review, the script
displays estimated token usage and cost. The input token count is
obtained from the model's token-counting API using the message that
will actually be submitted, so the input count is accurate. The
output token count, and therefore the final cost, is an estimate.

To stop before submitting the review, use `--dry-run`. The command
will abort immediately before the message is sent to the LLM.

## Dispositions

Each finding in the annotations file must be given one of the
dispositions described below before the next review can be
submitted. The prompt sent to the LLM is designed around these
dispositions. This helps successive reviews converge by carrying forward the
developer's decisions from earlier rounds.

- ACCEPT

    The finding is valid and has been fixed. On the next review the LLM
    will confirm the fix is present. If the fix is not found the finding
    will be re-raised.

- REJECT

    The finding has been reviewed and dismissed as inapplicable to this
    codebase or context. It will not be raised again in subsequent reviews.

- WRONG

    The finding was based on faulty reasoning. The code is correct. The
    finding will not be re-raised. Use this when the LLM has misread the
    control flow, misunderstood the design intent, or applied an
    inappropriate threat model.

- WRONG-RECONSIDER

    Applied automatically at finalization to all findings marked WRONG.
    On the first review of the next version the LLM will re-examine the
    specific function and code excerpt carefully. If the prior analysis
    was still incorrect the finding reverts to WRONG. If the code has
    changed and the finding is now valid it is raised as a new finding.
    If the model understands specifically why its prior reasoning was
    wrong it may mark the finding CONFIRMED.

- DEFER

    The finding is known and acknowledged but not yet addressed. It is
    carried forward in the `deferred` array of each subsequent review
    without being treated as a new finding.

- CONFIRMED

    Used for logic confirmations rather than defects. Marks that both the
    LLM and the developer agree the code is correct.

## Diminishing Returns and When to Stop

Run the `annotate` command after each review submission to view the
findings. Each round tends to surface smaller and more obscure issues
as obvious findings are resolved. Despite some fairly aggressive
attempts to create prompts that prevent trivial or obscure findings
you should stop when you see these signals:

- All new findings are LOW severity.
- The LLM is re-raising findings already marked WRONG or REJECT,
possibly rephrased (LLMs can and do make mistakes!).
- New findings describe edge cases that cannot occur in normal usage.

When all findings have dispositions and no new substantive issues
appear, the review should be considered complete.

## The Release Artifact

When you are satisfied with the review state, finalize it with
`--finalize-annotations`:

    cmb annotate --finalize-annotations -a 1:wrong -a 2:reject lib/My/Module.pm

This applies any remaining dispositions, validates that all findings
are annotated, reads the version from the `VERSION` file, and writes
the versioned release artifact:

    CPAN-Maker-Bootstrapper-1.1.0-REVIEW.json

This file serves as a code review certification for the release - a
machine-readable record of every finding examined, every logic
confirmation made, and every disposition applied before the version
was published. Commit it to the repository alongside your ChangeLog.

All findings marked WRONG are automatically converted to
WRONG-RECONSIDER in the release artifact, prompting careful
re-examination on the first review of the next version rather
than permanent suppression.

## Cost Management

Review cost depends on the selected model, source size, prompt
profiles, and number of findings. Costs generally decrease over
successive rounds as the model spends fewer output tokens
re-explaining suppressed findings.

Use your own prompt profiles (`--prompt-profile`) to suppress entire
classes of noise before they reach the annotation file. A well-tuned
profile for your application type is the highest-leverage cost
reduction available.

## See Also

["LLM Commands"](#llm-commands), ["PROMPT PROFILES"](#prompt-profiles), [CPAN::Maker::ConfigReader](https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3AConfigReader)

# PROMPT PROFILES

Prompt profiles are additive prompt fragments that customize the review
behavior for specific application types. They are appended to the base
review prompt before submission and are intended to focus the review on
relevant concerns while suppressing noise that does not apply to the
target context.

_NOTE: Prompts count toward your input token count. Be succinct and
accurate._

## Using Profiles

Pass one or more profiles using the `--prompt-profile` option:

    cmb code-review --prompt-profile cli-tool MyModule.pm

Multiple profiles may be combined:

    cmb code-review --prompt-profile cli-tool --prompt-profile security MyModule.pm

Profiles are resolved from the `.prompts/` directory in the current
project. A profile named `cli-tool` resolves to
`.prompts/cli-tool.prompt`. Add project-specific prompt profiles to
`.prompts/` and commit them with your project.

### Built-in Profiles

The following profile is installed with the distribution:

- cli-tool

    Appropriate for single-user developer CLI tools. Suppresses security
    findings that assume a multi-user or hostile environment, TOCTOU race
    condition findings that assume concurrent invocation, and concerns about
    `qx{}` or `system()` calls where input originates from the user's own
    configuration. Also assumes `perlcritic` and `perltidy` are enforced
    in the development environment.

### Creating Custom Profiles

A profile is a plain text file in `.prompts/` containing additional
prompt instructions, one per line. Lines beginning with `#` are
treated as comments and stripped before submission. Profile
instructions are appended verbatim to the base review prompt.  The
built-in profiles use one instruction per line, typically prefixed
with `-`.

Example `.prompts/security.prompt`:

    # security profile - add to any review where input handling matters
    - Treat all caller-supplied input as untrusted regardless of source.
    - Flag any use of eval, system, or exec that incorporates external data.
    - Flag missing taint checks on data used in file or system operations.

### Additional Profile Ideas

- library

    Focuses on API contract correctness and caller assumptions. Appropriate
    for CPAN distributions intended for use by unknown callers.

- web-application

    Treats external input as untrusted. Flags injection risks, authentication
    gaps, and session handling concerns.

- mod-perl-handler

    Addresses Apache lifecycle concerns including global state, startup versus
    request time initialization, and child process behavior.

- lambda-function

    Focuses on cold start performance, statelessness, and environment variable
    handling appropriate for AWS Lambda deployments.

Community contributions of additional profiles are welcome. See
[https://github.com/rlauer6/CPAN-Maker-Bootstrapper/issues](https://github.com/rlauer6/CPAN-Maker-Bootstrapper/issues).

# EXTENDING THE BUILD SYSTEM

The installed `Makefile` and files under `.includes/` are managed by
`CPAN::Maker::Bootstrapper`. They are intentionally write-protected and
may be replaced by `make update` when the bootstrapper is upgraded.

Project-specific build logic belongs in `project.mk`, which is always
writable and is never touched by `make update`. This provides an
upgrade-safe extension point for project-specific targets, variables,
and build ordering.

The managed include files live in the `.includes/` directory,
where they are write-protected and clearly separated from project
files. The `Makefile` includes them automatically:

    include .includes/publish.mk
    include .includes/bootstrap.mk
    include .includes/perl.mk
    include .includes/local.mk
    include .includes/help.mk
    include .includes/version.mk
    include .includes/release-notes.mk
    include .includes/git.mk
    include .includes/update.mk
    include .includes/upgrade.mk
    include .includes/bash-completion.mk
    include .includes/modulino.mk

These files are included if they exist:

    include config.mk
    include project.mk
    include extra-files.mk

## Immutability Is a Feature

The managed build system is deliberately **immutable**: the
`Makefile`, everything under `.includes/`, and the generated
`.pm`/`.pl` files are write-protected on purpose. This is a feature,
not a restriction. It lets `make update` replace those files with
newer, better versions without clobbering anything of yours, and it
guarantees that two projects on the same bootstrapper version use the
same managed build rules -- there is no per-project drift hiding in a
locally edited managed rule.

You _can_ override any of it -- these are your files, and nothing stops you
from `chmod +w` and editing a generated module or a managed include. But
you should not need to, and if you do, `make update` will overwrite your
change. Every legitimate customization has a sanctioned hook that survives
`make update`:

- **Project-specific targets, rules, and build ordering** --
`project.mk` (always writable; never touched by `make update`).

    Reach for `project.mk` when your project needs to do something the
    generic build system can't know about, for example:

    - **Build a companion artifact** the managed build doesn't produce --
    generate a `.pm.in` from a JSON/YAML schema, render documentation, compile
    assets, or (as `Amazon::API` does) build a Storable data file consumed at
    runtime.
    - **Declare inter-module build order** the scanner can't infer --
    `lib/Foo/Bar.pm: lib/Foo.pm` when one module must be built before another.
    - **Deploy or publish** -- an `scp`/upload/notify target that runs
    after `all`.
    - **Extend cleanup** -- a `clean-local::` double-colon rule to remove
    your own generated files, and `CLEANFILES +=` for anything else.

    See ["What Belongs in `project.mk`"](#what-belongs-in-project-mk) for worked examples of each, and
    ["What Does NOT Belong in `project.mk`"](#what-does-not-belong-in-project-mk) for the line between your extensions
    and the managed core.

- **Build-behavior toggles** (dependency scanning, linting, syntax
checking, version-drift strictness) -- make variables set on the command
line or in `config.mk` (see ["CONFIGURATION"](#configuration) and the variable list below).
- **Template tokens in your source** -- declare them in
`TEMPLATE_VARS` and let `cmb resolve-vars` fill them, rather than
hand-editing a generated `.pm` (see ["Custom Template Tokens"](#custom-template-tokens)).
- **Extra distribution files** -- list them in `buildspec.yml`;
`extra-files.mk` wires them into the tarball automatically.
- **Dependencies the scanner cannot see** -- the sticky `+` prefix in
`requires` (see ["Dependencies Management"](#dependencies-management)).

If you find yourself wanting to edit a managed file, check this list first:
the hook you need almost certainly exists, and using it keeps you on the
upgrade path instead of forking the build system.

_Why the generated `.pm`/`.pl` files are read-only:_ they are
regenerated from their `.pm.in`/`.pl.in` sources when its
prerequisites require regeneration, so any edit you make directly to a
generated `.pm` would be silently lost on the next `make`.  The
`chmod -w` is there to stop you from making that mistake. Edit the
`.pm.in` source, not the generated `.pm`.

## How the Makefile Works

The installed `Makefile` is structured around a few key concepts:

- **Source files** live in `lib/` as `.pm.in` and in `bin/` as
`.pl.in`. The build generates the final `.pm` and `.pl` files from
these sources by substituting `@PACKAGE_VERSION@` and other
tokens, running syntax checks, and optionally running perltidy and
perlcritic.
- **Sentinel files** - the build uses sentinel files to track
incremental quality-gate state. `.checked` records successful syntax
and validation checks, `.tdy` records successful perltidy processing,
and `.crit` records successful perlcritic processing. Each sentinel is
regenerated only when the source or the prerequisites for that gate
change.
- **Dependency scanning** - `scandeps-static.pl` scans your
source files and maintains the dependency files used by [CPAN::Maker](https://metacpan.org/pod/CPAN%3A%3AMaker)
when generating distribution metadata, including `requires`,
`test-requires`, `recommends`, and `suggests`. Controlled by
`SCAN=ON|OFF`.
- **The distribution tarball** is the final output of `make`.
It is built by `make-cpan-dist.pl` using `buildspec.yml`.
- **Inter-module dependency discovery** - the build scans modules
within the distribution and generates `deps.mk` so `make` can build
modules in dependency order before syntax checking them. Dependencies
that cannot be inferred automatically may be added in `project.mk`.

Key build variables you can override on the make command line or in
`config.mk`:

- `SCAN=OFF` - skip distribution dependency scanning
- `LINT=OFF` - skip perltidy and perlcritic
- `SYNTAX_CHECKING=OFF` - skip `perl -wc` syntax checks
- `MIN_PERL_VERSION=5.016` - minimum Perl version for Makefile.PL
- `PERLTIDYRC=/path/to/rc` - path to perltidy configuration
- `PERLCRITICRC=/path/to/rc` - path to perlcritic configuration
- `SKIP_TESTS=1` - interpreted by [CPAN::Maker](https://metacpan.org/pod/CPAN%3A%3AMaker); skips running
the test suite when building the distribution tarball
- `PERLWC_SKIP="file1 file2"`  - space-separated list of files
to exclude from syntax and POD checks
- `POD=extract|remove` - extract POD to a companion `.pod` file
or strip it entirely from the built `.pm`
- `PERLINCLUDE="-I path"` - additional include paths used during
the `perl -wc` syntax check. Defaults to `-I lib -I local/lib/perl5`
for hermetic checking; see ["The local dependency library"](#the-local-dependency-library).
- `CPAN_INSTALLER=cpm|carton` - selects the installer used to
populate `local/` for hermetic syntax checking. Auto-detected (`cpm`
preferred) if unset.

Two further toggles, `CMB_UPDATE_CHECK` and `CMB_VERSION_DRIFT`, are set
in `config.mk` rather than on the command line; see ["Automatic Drift and
Update Checks"](#automatic-drift-and-update-checks). `config.mk` is read on every invocation of `make` and is
the right place for durable, machine- or project-wide build settings such as
`SYNTAX_CHECKING=OFF` on a box without an installer.

## What Belongs in `project.mk`

- Custom targets

    Any target specific to your project - generating assets, running
    linters, deploying, sending notifications:

        .PHONY: deploy
        deploy: all ## deploy the distribution
            scp $(TARBALL) user@myserver:/opt/cpan

    Add `##` followed by a description to a target definition to include
    the target in the output from `make help`. Because `project.mk` is
    included in `MAKEFILE_LIST`, project-specific targets are discovered
    automatically:

        make help

    There is no separate help table to maintain.

- Inter-module dependencies

    If your modules have build-time dependencies on each other, declare
    them here rather than modifying the Makefile:

        lib/Foo/Bar.pm: lib/Foo.pm

- Additional file generation

    If your project generates code or configuration from templates beyond
    what the standard Makefile handles:

        lib/Foo/Generated.pm.in: schema/foo.json
            perl bin/generate-module.pl $< > $@

- Project-specific variables

        DEPLOY_HOST = myserver.example.com
        DEPLOY_PATH = /opt/cpan/incoming

- Extending CLEANFILES

    Add project-specific generated files to the cleanup target by
    appending to `CLEANFILES`:

        CLEANFILES += mygenerated.pm config/generated.yml

- Extending the clean target

        clean-local::
               rm -rf workdir

- Extending the test recipe

    Projects may have development or integration tests that should not be
    included in the CPAN distribution. Add them to `make test` by
    extending `test-local` with a double-colon rule:

        test-local::
            prove -I lib -v xt/

## What Does NOT Belong in `project.mk`

- Modifications to existing targets like `all`, `clean`, `requires`
- Replacing managed variables such as `DEPS` or `CLEANFILES`.

    Use documented extension points such as `CLEANFILES +=` where
    provided rather than redefining the managed value.

- Anything that duplicates logic already in the managed Makefile

## Custom Template Tokens

The build generates each `.pm`/`.pl` from its `.pm.in`/`.pl.in` source
by substituting `@TOKEN@` placeholders through `cmb resolve-vars`.
The standard tokens (`@PACKAGE_VERSION@`, `@MODULE_NAME@`,
`@GIT_SHA@`, and the other git-metadata variables) are always
available, but the mechanism is extensible: a project can define its own
tokens without editing any managed file.

To add a token, declare its name in `TEMPLATE_VARS` (in
`project.mk`) and provide a value -- as a make variable, an exported
environment variable, or through the variables file passed to
`resolve-vars`. For example, to stamp a build timestamp:

    # in project.mk
    BUILD_DATE      := $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
    TEMPLATE_VARS   += BUILD_DATE

    # in a .pm.in source
    our $BUILD_DATE = 'E<64>BUILD_DATEE<64>';

`cmb resolve-vars` then fills `@BUILD_DATE@` from the value
when its prerequisites require regeneration. The token grammar is
uppercase-only (`@[A-Z0-9_]+@`), so placeholders never
collide with real Perl such as `@_` or `@ISA`.

By default, substitution is **fail-loud** for placeholders that appear
in live code: if a token has no value, the build stops and names the
offending token rather than silently substituting an empty string.

Placeholders that occur only in POD or comments do not require values.
`--no-strict` may be used to downgrade a missing live-code value to a
warning and leave the placeholder unchanged.

## Keeping the build system up to date

The following targets manage the lifecycle of the build system itself:

- `make check-upgrade` / `make upgrade-check`

    Checks MetaCPAN to see if a newer version of
    `CPAN::Maker::Bootstrapper` is available.

- `make publish`

    Builds the distribution tarball, unpacks it into a temporary directory,
    runs its normal `Makefile.PL`, build, and test sequence, and uploads
    the tarball to PAUSE if all checks succeed.

    Set the PAUSE credentials with:

        make publish PAUSE_USER=username PAUSE_PASSWORD=password

- `make upgrade`

    Checks MetaCPAN, installs the latest version via `cpanm`, then
    automatically runs `make update` to refresh the managed project
    files.

- `make update`

    Copies the managed files from the currently installed bootstrapper
    distribution into your project directory. After running, use
    `git diff` to review what changed.

    The following files are managed and may be updated:

        Makefile
        .includes/bootstrap.mk
        .includes/perl.mk
        .includes/local.mk
        .includes/git.mk
        .includes/help.mk
        .includes/update.mk
        .includes/upgrade.mk
        .includes/version.mk
        .includes/release-notes.mk
        .includes/bash-completion.mk
        .includes/modulino.mk
        .includes/publish.mk

    Your `project.mk`, `buildspec.yml`, `requires`, `VERSION`, source
    files and tests are **never** touched by `make update`.

- `make cpanm`

    Installs `cpanminus` if it is not already available on your
    `PATH`. Required for `make upgrade` to work:

        make cpanm && make upgrade

## Automatic Drift and Update Checks

Every build runs two checks before proceeding, so you don't have to
remember to run `make check-upgrade` yourself:

- Is a newer `CPAN::Maker::Bootstrapper` published on CPAN than the
one installed on this machine?
- Do this project's managed files still match what the _currently
installed_ `CPAN::Maker::Bootstrapper` would produce?

These are independent questions - your installed bootstrapper can be
fully current while a given project has still drifted from it (most
commonly because the project hasn't been through `make update`
since you last upgraded), or your bootstrapper itself can be behind
CPAN while every project stays perfectly in sync with it.

_Drift_ can happen for either of two reasons: your installed
`CPAN::Maker::Bootstrapper` was upgraded since this project last ran
`make update`, or a managed file was hand-edited despite the
warnings not to (see ["What You Should Never Modify"](#what-you-should-never-modify)). `make`
doesn't try to tell these apart - the fix is the same either way:

    make update

Two variables, set in `config.mk`, control how strict these checks
are:

- `CMB_UPDATE_CHECK` (`ON`|`OFF`, default `ON`)

    Set to `OFF` to skip the MetaCPAN lookup - useful in CI or offline
    environments where the network call would just fail or slow things
    down.

- `CMB_VERSION_DRIFT` (`FAIL`|`WARN`|`IGNORE`, default `FAIL`)

    Controls what happens when a project's managed files no longer match
    the installed bootstrapper. `FAIL` stops the build until you run
    `make update`; `WARN` prints a message and continues; `IGNORE`
    skips the check entirely.

## What You Should Never Modify

The files in `.includes/` - `perl.mk`, `git.mk`, `help.mk` etc.  -
are managed files that will be overwritten by `make update`.  Do not
modify managed files directly. Use `config.mk` for documented build
variables and `project.mk` for project-specific targets, rules, and
build ordering.

The `Makefile` itself is also managed and will be overwritten by
`make update`. Use the documented project-level configuration and
extension files instead.

## Dependencies Management

The build system scans `.pm.in` and `.pl.in` source files and
maintains the dependency files used by [CPAN::Maker](https://metacpan.org/pod/CPAN%3A%3AMaker) when generating
distribution metadata:

    F<requires>
    F<test-requires>
    F<recommends>
    F<suggests>

Distribution dependency scanning is controlled by `SCAN`. Set
`SCAN=OFF` to skip updates to `requires`, `test-requires`,
`recommends`, and `suggests` for a build; the default is `ON`.

To prevent an entry from being removed by a rescan, prefix the module
name with `+`. These entries are sticky and survive all subsequent
scans even if the scanner no longer detects them.  To pin a specific
version, simply edit the version number in the `requires` file. If
the scanner subsequently detects a different version, the Makefile
will preserve your pinned version. Note that pinned versions are
**never** updated automatically - if you want to adopt a newer version
you must edit the file manually.

In your requires file:

    +Foo::Bar 1.0    # sticky - survives all rescans
    Baz::Qux  2.5   # version pinned - scanner won't override this version

_Note: These two mechanisms are independent - `+` controls whether an entry
survives rescans, while the version number controls what version is
required._

### The local dependency library

Syntax checking is performed in a _hermetic_ environment: each
generated `.pm` is compiled with `perl -wc` against `lib` and a
project-local library at `local/lib/perl5` only, with `PERL5LIB`
explicitly cleared for the check. This ensures a module's dependencies
are actually declared and installed, rather than being satisfied by
chance from whatever happens to be in your `PERL5LIB` or system
`@INC`. A dependency that compiles on your machine but is missing
from the declared dependency set will fail the build here instead of
surprising you on a clean install or CI box.

To populate that library, the build installs your declared dependencies into
`local/` using `cpm` (preferred) or `carton`:

    make local # installs requires/recommends/suggests/test-requires into local/lib/perl5

This runs automatically as a prerequisite of the module build, so a
normal `make` installs dependencies first, then syntax-checks against
them.

`cpm` is preferred because it supports multiple resolvers directly
from `build-mirrors`. `carton` is also supported; see
["build-mirrors"](#build-mirrors) for its mirror behavior.

The use of a `build-mirrors` file versus specifying the mirrors in
the dependency files determines the scope of their
use. `build-mirrors` (and `cpanfile` mirror declarations) set the
resolvers used for **every** dependency in the build. To route a
**single** module to a specific mirror, URL, or distribution -- without
affecting how anything else resolves -- annotate that module's entry
in `requires` with `mirror=`, `url=`, or `dist=` (see
["build-mirrors"](#build-mirrors)).

The `+` prefix has a second use beyond protecting mirror annotations.
Because the check is hermetic, **a module reached only at runtime will not
be found unless it is declared**. Static scanning (`scandeps-static.pl`)
cannot see a dependency loaded dynamically -- for example a module pulled
in through a method call rather than a `use` statement -- so it will never
add it to `requires`. Declare such modules explicitly with `+`, which
makes the entry sticky and survives every rescan:

    +Log::Log4perl    # loaded at runtime via a framework call; scanner can't see it

### `build-mirrors`

When using the preferred CPAN installer (`cpm`), the build system
reads mirror URLs, one per line, from a `build-mirrors` file in the
project root and passes each as a resolver. This allows the build to
resolve dependencies against one or more configured CPAN-compatible
repositories, including private DarkPAN repositories.

When `carton` is used, because it does not support multiple mirrors
when setting the mirror using an environment variable, the build
system will use the first mirror in your `build-mirrors` file if
present. `carton` supports multiple mirrors only by specifying them
in the `cpanfile`.

Entries in `requires`, `suggests`, and `recommends` may carry optional
qualifiers after the version to control where a module resolves from:

    +Foo::Bar 1.0 mirror=https://cpan.openbedrock.net/orepan2
    +Baz::Qux 2.5 url=https://example.com/authors/id/D/DU/DUMMY/Baz-Qux-2.5.tar.gz
    +Xyz::Abc 0.9 dist=Xyz-Distribution

Only `dist=`, `url=`, and `mirror=` are permitted after the version;
anything else is an error. Prefix such entries with the sticky `+` so the
scanner does not strip the annotation on a later rescan. See [CPAN::Maker](https://metacpan.org/pod/CPAN%3A%3AMaker)
for the full format.

# MODULINOS

A modulino is a Perl module that doubles as a runnable script by
checking whether it was invoked directly or loaded as a library:

    package Foo::Bar;

    caller or __PACKAGE__->main;

    sub main {
      ...
      exit 0;
    }

Modulinos are useful for CLI scripts because they encourage
encapsulation, simplify unit testing, and keep logic organized
in named methods rather than inline code.

The `Makefile` provides a `modulino` target that generates a wrapper
script for invoking your module. By default it uses `MODULE_NAME`,
producing a script named after the module:

    make modulino

For a project named `Foo::Bar` this creates `bin/foo-bar.in`.
`make` then builds `bin/foo-bar` from that source file via a
pattern rule, and the executable ends up in the distribution.

To create a modulino wrapper for a module other than the primary
project module, override `MODULE_NAME`:

    make modulino MODULE_NAME=Foo::Bar::Buz

This creates `bin/foo-bar-buz.in` invoking `Foo::Bar::Buz`.

To give the wrapper a short or memorable name independent of the
module name, set `ALIAS`:

    make modulino MODULE_NAME=Foo::Bar::Buz ALIAS=fbb

This creates `bin/fbb.in` which still invokes `Foo::Bar::Buz`.
`ALIAS` accepts either a plain name (`fbb`) or a module-style
name (`Foo::Bar::Buz`) - colons are converted to hyphens and
the result is lowercased.

The generated wrapper scripts (without the `.in` suffix) are
automatically added to `.gitignore` since they are build artifacts.
The `.in` source files are tracked by git.

## Continuous Integration

CPAN::Maker::Bootstrapper provides a clean-room build path that can be
used locally or from a CI system.

The CI design separates source acquisition from project build
responsibilities:

    source acquisition       caller or CI system
    build environment        builder
    project build            make

A CI system such as GitHub Actions is responsible for checking out the
project. `builder` then operates on that existing project directory,
installs the required build environment and dependencies, and runs the
project build.

`make build-ci` provides the corresponding local clean-room build. It
uses the current working tree as its source, copies that tree into a
disposable container build directory, and invokes `builder` there.

This separation keeps `builder` independent of repository hosting,
branch selection, and source-control workflow while allowing the same
build mechanism to be used both locally and in CI.

The build lifecycle is:

    builder.env
        |
        v
    builder-pre
        |
        v
      make
        |
        v
    builder-post

`builder` can run unmodified in GitHub Actions, in another CI runner,
or by hand from the command line.

### Running builder manually

`builder` operates on an existing project directory. Source acquisition
is deliberately outside its responsibility; the caller must clone,
check out, or otherwise provide the project before invoking `builder`.

Run it from the root of a project:

    ./builder

or pass the project directory explicitly:

    /builder /path/to/project

The project directory defaults to the current working directory.

`builder` changes to that directory, loads the project CI environment,
resolves and installs the required build dependencies, and runs the
configured build lifecycle.

For the standard containerized clean-room build, use:

    make build-ci

`make build-ci` copies the current working tree into a disposable build
environment and invokes `builder` there. Because it operates on the
current working tree rather than cloning the repository, the build may
include uncommitted and untracked files present on disk.

### Environment variables

`builder` accepts environment variables that control dependency
installation and build behavior. These values may also be set in
`builder.env`.

- `INSTALLER`

    The command used to install Perl dependencies.

    The default is:

        cpm install -g --show-build-log-on-failure --verbose

- `SCAN`

    Controls dependency scanning during the project build.

    The builder default is:

        SCAN=on

- `SYNTAX_CHECKING`

    Controls Perl syntax checking during the project build.

    The builder does not enable syntax checking by default. To use syntax
    checking as a CI quality gate, add the following to `builder.env`:

        SYNTAX_CHECKING=on

- `LINT`

    Controls the perltidy and perlcritic quality gates.

    The builder does not enable linting by default. To enable configured
    lint tools during CI, add:

        LINT=on

    to `builder.env`.

- `PERLTIDYRC`

    Specifies the perltidy profile used when linting is enabled.

    If `PERLTIDYRC` is not defined, `builder` looks for `.perltidyrc`
    or `perltidyrc` in the project. An explicitly supplied value is not
    overwritten by profile discovery.

    When a profile is configured and `LINT=on`, `builder` installs
    [Perl::Tidy](https://metacpan.org/pod/Perl%3A%3ATidy) before running the project build.

    If `PERLTIDYRC` names a file that does not exist, the build fails.

- `PERLCRITICRC`

    Specifies the perlcritic profile used when linting is enabled.

    If `PERLCRITICRC` is not defined, `builder` looks for
    `.perlcriticrc` or `perlcriticrc` in the project. An explicitly
    supplied value is not overwritten by profile discovery.

    When a profile is configured and `LINT=on`, `builder` installs
    [Perl::Critic](https://metacpan.org/pod/Perl%3A%3ACritic) and the supporting policy modules required by the
    managed build.

    If `PERLCRITICRC` names a file that does not exist, the build fails.

    Setting `LINT=on` without either a perltidy or perlcritic profile is
    treated as a configuration error.

- `NO_ECHO`

    Passed through to the generated Makefile when set.

- `CMB_VERSION_DRIFT`

    Controls how `builder` handles differences between the installed
    CPAN::Maker::Bootstrapper version and the version expected by the
    project.

    The generated `builder.env` defaults this to:

        CMB_VERSION_DRIFT=ignore

### `builder.env`

Before installing project build dependencies or running the project
build, `builder` loads `builder.env` from the project root when that
file exists.

Variables defined there are exported to the build environment and are
used when resolving the effective CI build policy.

A generated project includes:

    CMB_VERSION_DRIFT=ignore
    NO_ECHO=

The default builder performs a clean distribution build but does not
enable syntax checking or linting as CI phase gates. Projects that want
those checks may opt in through `builder.env`.

For example:

    SYNTAX_CHECKING=on
    LINT=on

When linting is enabled, provide a `perltidyrc`, `.perltidyrc`,
`perlcriticrc`, or `.perlcriticrc` for each lint tool the CI build
should run. The corresponding tool dependencies are installed by
`builder` before `make` is invoked.

`builder.env` therefore provides a project-local place to define CI
policy without modifying `builder` itself.

### Builder lifecycle hooks

`builder` exposes two Makefile hooks around the main project build:

    builder-pre
    builder-post

The build lifecycle is:

    builder.env
        |
    builder-pre
        |
    make
        |
    builder-post

`builder-pre` runs after `builder.env` has been loaded and before the
main `make` invocation.

`builder-post` runs only after the main build completes successfully.

Generated projects define both targets as empty double-colon targets:

    builder-pre::

    builder-post::

Projects may extend them in `project.mk` without modifying the managed
Makefile.

For example:

    builder-pre::
            ./prepare-ci-environment

    builder-post::
            ./collect-build-artifacts

These hooks are intended for project-specific CI setup and post-build
work that should remain outside the managed build files.

### `make build-ci`

`make build-ci` runs the current project in a disposable containerized
build environment.

Unlike a CI workflow that clones the repository, `build-ci` uses the
current working tree as its source. The project is mounted read-only,
copied into the container build area, and then passed to `builder`.

This means the build reflects the files currently present on disk,
including uncommitted changes and untracked files.

The source tree itself is not modified by the container build.

`make build-ci` accepts the following variables:

    DOCKER_BUILD_IMAGE  - container image used for the build
    DOCKER_CPAN_INSTALLER
                        - dependency installer command used in the container
    BUILD_LOG           - path used for captured build output
    MODULE_NAME         - primary module name passed into the clean-room build

For example:

    make build-ci

or:

    make build-ci DOCKER_BUILD_IMAGE=debian:trixie

The command exits with the status of the container build even though
the output is also written to `BUILD_LOG`.

### Builder input files

`builder` recognizes project files that supply additional build
requirements without modifying `builder` itself.

- `build-apt-deps`

    A whitespace-separated list of additional Debian packages required by
    the project build.

    `builder` installs these packages in addition to its standard build
    environment before installing Perl dependencies.

    For example:

        libxml2-dev
        libpq-dev

- `build-mirrors`

    A list of CPAN mirror URLs, one per line.

    Use this file when the build requires a DarkPAN or another additional
    CPAN-compatible repository.

    For example:

        https://cpan.openbedrock.net
        https://cpan.metacpan.org

    The configured mirrors are used when resolving project dependencies.

These files describe build inputs. For environment variables use
`builder.env`; for project-specific Makefile behavior use
`project.mk`.

### `perlcritic` and `perltidy` Gates

During a CI build, the build script enables `PERLTIDY` and
`PERLCRITIC` when it can find the corresponding configuration files
in the project.

For reproducible CI builds, keep the project's `perltidyrc` and
`perlcriticrc` aligned with the configuration used in your development
environment.

Many editors and IDEs run Perltidy or Perl::Critic automatically while
you work. If those tools use a personal configuration that differs from
the project's checked-in configuration, code that appears clean locally
may fail during `build-ci`.

When a project-local `perltidyrc` or `perlcriticrc` is present,
`build-ci` uses it to enforce the project's formatting and critic
policies in the clean build environment. If no project-local
configuration can be discovered, the corresponding check is disabled
rather than falling back to the tool's default configuration.

### See Also

["make workflow"](#make-workflow), ["make build-ci"](#make-build-ci)

# PREREQUISITES

The following tool(s) must be on your `PATH`:

- `git` - used to read global identity config
- `make` - GNU make is required to build the project
- `curl` - used by `make upgrade` to query MetaCPAN
- `cpm` or `carton` - installs declared dependencies into a
project-local library (`local/lib/perl5`) for hermetic syntax checking

You can set make variables like `SYNTAX_CHECKING` in `config.mk`, which
is included on every invocation of `make`, to alter build behavior -- for
example `SYNTAX_CHECKING=OFF` to skip the check when neither installer is
present (undeclared dependencies then go undetected).

_Note: neither `cpm` nor `carton` is a hard prerequisite of
`CPAN::Maker::Bootstrapper` itself; they are needed only to populate the
local library for hermetic checking. `cpm` is preferred for its
multi-mirror support (see ["build-mirrors"](#build-mirrors))._

# CAVEATS

- `.pm` and `.pl` Generation

    Generated `.pm` and `.pl` files are derived from their
    `.pm.in`/`.pl.in` sources through `cmb resolve-vars` and are
    read-only. Always edit the `.in` source.

    Use `@PACKAGE_VERSION@` like this:

    `our $VERSION ='``@PACKAGE_VERSION@``';`

- The import feature cannot be used with `--stub`
- git

    `git` is used throughout the framework. `make git` initializes the
    repository and creates the initial commit, and the bootstrapper reads
    user identity and related defaults from `.gitconfig` when no separate
    configuration file is supplied.

# FAQ

## My build is failing with a module not found error during syntax
checking

There are several common causes.

One possible cause is an inter-module build-order dependency. The build
system normally detects dependencies between modules in the distribution
and writes them to `deps.mk`, allowing `make` to build prerequisite
modules before syntax-checking modules that depend on them.

For example, if `lib/Foo/Bar.pm` uses `lib/Foo.pm`, the generated
dependency rules ensure that `Foo.pm` is built first.

If the dependency cannot be inferred automatically, declare it explicitly
in `project.mk`:

    lib/Foo/Bar.pm: lib/Foo.pm

See ["Inter-module dependencies"](#inter-module-dependencies) for details.

Another cause is a real dependency that is not installed in
`local/`. Because syntax checking runs against `local/lib/perl5`
with `PERL5LIB` cleared, a dependency that is present elsewhere on
your system but not declared will fail here. 

Confirm it is in `requires` (add it with a sticky `+` if the scanner
can't see it -- see ["Dependencies Management"](#dependencies-management)), then `make local`
to install it. This is the check working as intended: it catches a
missing declaration on your machine instead of on someone else's.

If the module genuinely cannot be loaded outside its runtime
environment (an Apache handler, a mod\_perl module, etc.), add it to
`PERLWC_SKIP` in `project.mk`:

    PERLWC_SKIP = lib/My/Apache/Handler.pm

Files listed in `PERLWC_SKIP` are excluded from the `perl -wc`
syntax-checking and POD-checking stages. They are still built and
included in the distribution; only those validation steps are skipped.

## How do I do a fast build during development?

    make quick

This disables distribution dependency scanning and all linting
(perltidy, perlcritic) for the current build. `requires`,
`test-requires`, `recommends`, and `suggests` are not updated.
Syntax checking remains enabled.

Use `make` without flags when you are
ready to do a full build before committing or releasing.

You can also disable individual features:

    make SCAN=OFF             # skip distribution dependency scanning only
    make LINT=OFF             # skip all linting only
    make SYNTAX_CHECKING=OFF  # skip syntax checking only

## How do I add a new module or script to the project?

Create the source file with the `.pm.in` or `.pl.in` extension in
the appropriate directory:

    lib/My/New/Module.pm.in
    bin/my-script.pl.in

The build system discovers them automatically via `find-files` - no
changes to the Makefile are required. The next `make` will include
them in the dependency scan and the distribution.

## How do I include additional files in the distribution?

Edit `buildspec.yml` and add entries to the `extra-files` section:

    extra-files:
      - ChangeLog
      - README.md
      - share:
        - my-config-template.yml
        - my-data-file.json

Files listed under `share:` are installed into the distribution's
share directory and can be accessed at runtime via
[File::ShareDir](https://metacpan.org/pod/File%3A%3AShareDir).

The build verifies that files listed in `extra-files` are tracked by
git. This helps catch files that have been added to the distribution
but accidentally omitted from the project repository.

Some extra files are generated build artifacts and therefore **should
not be committed** to the repository. Add those files to
`extra-files.skip`, one file per line:

    generated/service-data.dat
    share/generated-index.json

Blank lines and lines beginning with `#` are ignored.

`extra-files.skip` only disables the git tracking check for those
files. The files remain part of the distribution and continue to be
included as dependencies when determining whether the distribution
tarball must be rebuilt.

When `DARKPAN_REQUIRES` is enabled, `cpanfile.darkpan` and
`cpanm.darkpan` are automatically added to `buildspec.yml` as extra
files. They are therefore subject to the normal git tracking check. If
the developer wants to include these generated manifests in the
distribution without tracking them in the repository, they may be
added explicitly to `extra-files.skip`. See ["DARKPAN\_REQUIRES"](#darkpan_requires).

## I want to pin a version or add a module the scanner missed

Edit `requires` directly. Prefix the module name with `+` to make
the entry sticky - it will survive all subsequent rescans even if the
scanner no longer detects it:

    +My::Required::Module 1.5

To pin a version without making the entry sticky, just set the version
number. The scanner will preserve your version if it detects a
different one on subsequent builds:

    Some::Module 2.0

These two mechanisms are independent - `+` controls survivability,
the version number controls what version is required. See ["Dependencies Management"](#dependencies-management)
for full details.

## I want to exclude a module the scanner found

Create a `requires.skip` file in the project root with one module
name per line:

    My::Own::Module
    Some::Transitive::Dep

The scanner will never add these to `requires`. Use
`test-requires.skip` for the same effect on test dependencies.

Note that on a clean first build neither skip file has any effect
since there is no prior `requires` file to compare against. The skip
list takes effect from the second build onward.

## I edited a .pm file and my changes disappeared

The `.pm` files in `lib/` are generated from the `.pm.in` sources
and are write-protected. Always edit the `.pm.in` file - the `.pm`
is regenerated when its prerequisites require regeneration and your
changes will be lost.

If you are unsure which file to edit:

    ls -l lib/My/Module.pm lib/My/Module.pm.in

The `.pm.in` file is the one you own.

## Why does my build say it has drifted from the installed bootstrapper?

This means your project's managed files (`Makefile`,
`.includes/*.mk`) no longer match what your _currently installed_
`CPAN::Maker::Bootstrapper` would generate. There are two ways this
happens - upgrading your bootstrapper (e.g. via `cpanm
\--upgrade-all`) instantly "drifts" every project you haven't yet
updated, or a managed file was edited by hand. Both are fixed the
same way:

    make update

If you don't want a drifted project to fail the build outright, set
`CMB_VERSION_DRIFT=WARN` (or `=IGNORE`) in that project's
`config.mk`. See ["Automatic Drift and Update Checks"](#automatic-drift-and-update-checks).

## make update overwrote something I changed in a managed file

The managed files in `.includes/` should never be edited directly.
Use `config.mk`, `project.mk`, or the other documented project-level
extension points instead.

This is why `make git` and committing your `.includes/` directory is
strongly recommended - git is your safety net for the entire build
system.

## `make` says nothing to do but my source changed

The most common cause is that the generated `.pm` file is newer than
the `.pm.in` source. This can happen if you accidentally edited the
`.pm` directly or if file timestamps got out of sync. Force a rebuild:

    touch lib/My/Module.pm.in

Or do a clean rebuild:

    make clean && make

## How do I disable dependency scanning temporarily?

    make SCAN=OFF

This skips distribution dependency scanning for that run, so
`requires`, `test-requires`, `recommends`, and `suggests` are not
updated.

Inter-module dependency discovery for `deps.mk` is independent of
`SCAN` and may still run when syntax checking is enabled. The default
is `SCAN=ON`.

## How do I disable syntax checking temporarily?

    make SYNTAX_CHECKING=OFF

Similarly you can disable individual quality gates:

    make PERLTIDY="" PERLCRITIC=""

## How do I upgrade the build system?

    make upgrade

This checks MetaCPAN for a newer version of
`CPAN::Maker::Bootstrapper`, installs it via `cpanm`, and
automatically refreshes the managed files in `.includes/` with
`make update`. Review the changes with `git diff`.

If `cpanm` is not installed:

    make cpanm && make upgrade

## I want to add a bash script to my distribution

Create the script in `bin/` with a `.sh.in` extension:

    bin/my-script.sh.in

The build system will process it through the standard token
substitution (replacing `@PACKAGE_VERSION@` and
`@MODULE_NAME@`), make it executable, and include it in the
distribution automatically.

If your script is more than a few lines of bash, consider writing it
as a _modulino_ instead - a Perl module that doubles as a runnable
script. Modulinos are easier to test, encourage encapsulation, and
give you the full power of Perl and CPAN. The build system has
first-class support for them:

    make modulino

This generates a bash wrapper in `bin/` that invokes your module as
a script if it uses the modulino pattern:

    caller or __PACKAGE__->main;

See ["MODULINOS"](#modulinos) for full details.

## What is `make release-notes` used for?

`make release-notes` generates four artifacts comparing the current
working state of your repository against the previous git tag:

- `release-<version>.diffs` - a unified diff of all
changed files
- `release-<version>.lst` - a list of added, modified,
and removed files
- `release-<version>.status` - Git name-status output
classifying added, modified, deleted, and renamed files
- `release-<version>.tar.gz` - a tarball containing
only the changed files

These are primarily useful for generating release notes and
changelogs, and for submitting targeted patches. Run it after bumping
the version with `make release`, `make minor`, or `make major` and
before creating your final distribution.

    make minor
    make release-notes
    # review release-1.1.0.diffs
    make

The artifacts are all the clues needed for LLMs to produce accurate
and well written release notes for your project.

To generate the release artifacts without submitting them to the LLM,
use:

    make release-notes DRYRUN=1

This is useful for inspecting or debugging the release evidence before
requesting generated release notes. The `.diffs`, `.lst`, `.status`,
and `.tar.gz` artifacts are produced normally, but no LLM request is
made.

The release artifacts are cleaned up by `make clean`.

## Can I distribute the POD in my modules separately?

When you package your CPAN distribution you can strip the pod from
your modules or you can extract the pod and provide them as separate
`.pod` files. The `POD` make variable controls that behavior:

- `make POD=extract`

    `extract` will strip POD from your module and create a `.pod` file
    containing the stripped POD that will be added to your distribution.

- `make POD=remove`

    `remove` will strip POD from your module. No POD will be included in
    the distribution.

## Something still doesn't work - how do I report an issue?

First check the ["FAQ"](#faq) sections above - your
issue may already be covered.

If you believe you have found a bug or want to request a feature,
please open an issue on GitHub:

    https://github.com/rlauer6/CPAN-Maker-Bootstrapper/issues

When reporting a bug please include:

- The version of `CPAN::Maker::Bootstrapper` (`cmb --version`
or `perl -MCPAN::Maker::Bootstrapper -e 'print $CPAN::Maker::Bootstrapper::VERSION'`)
- The output of `make -n` or `make --debug=v` if the issue is
build-related
- Your `buildspec.yml` and `project.mk` if relevant (redact
any sensitive information)
- The Perl and GNU make versions (`perl --version`, `make --version`)
- **MAKE SURE YOUR SUBMISSION DOES NOT CONTAIN SECRETS!**

Pull requests are welcome. The project follows the standard GitHub
fork-and-PR workflow.

# SEE ALSO

[CPAN::Maker](https://metacpan.org/pod/CPAN%3A%3AMaker) - the distribution builder driven by `buildspec.yml`
(includes `make-cpan-dist.pl`)

[CLI::Simple](https://metacpan.org/pod/CLI%3A%3ASimple) - the CLI framework used by the bootstrapper itself and
optionally by generated CLI module stubs

[CPAN::Maker::ConfigReader](https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3AConfigReader) - the git config reader bundled with this
distribution, available for use in your own
tools.

[LLM::API](https://metacpan.org/pod/LLM%3A%3AAPI) - client interface to Anthropic's Claude API

[Module::ScanDeps::Static](https://metacpan.org/pod/Module%3A%3AScanDeps%3A%3AStatic) - the static scanner used for CPAN
dependency discovery and for inter-module build-order discovery
through `deps.mk`.

# DEPENDENCIES

The current runtime, build, test, recommended, and suggested
dependencies are declared in the distribution metadata generated by
[CPAN::Maker](https://metacpan.org/pod/CPAN%3A%3AMaker).

See `Makefile.PL`, `META.json`, or `META.yml` in the distribution
for the authoritative dependency set.

Some optional features require additional dependencies only when those
features are used.

# VERSION

This documentation refers to version 2.4.1

# AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

# LICENSE

Copyright 2026, Robert C. Lauer All right reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
