# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [QUICK START](#quick-start)
* [WHY YOU SHOULD CONSIDER USING YET ANOTHER BUILD TOOL](#why-you-should-consider-using-yet-another-build-tool)
  * [The Stack](#the-stack)
  * [Best Practices Out of the Box](#best-practices-out-of-the-box)
  * [Perl Quality Tools](#perl-quality-tools)
  * [A GNU Make Tutorial in Disguise](#a-gnu-make-tutorial-in-disguise)
* [IMPORTING FILES](#importing-files)
  * [What Gets Imported](#what-gets-imported)
  * [Module Name Requirement](#module-name-requirement)
  * [The Build After Import](#the-build-after-import)
  * [Next Steps After a Successful Import](#next-steps-after-a-successful-import)
  * [Limitations](#limitations)
  * [Importing a CLI::Simple Scaffold Tarball](#importing-a-clisimple-scaffold-tarball)
* [CONFIGURATION](#configuration)
  * [Environment](#environment)
* [INSTALLED PROJECT FILES](#installed-project-files)
* [THE PROJECT MAKEFILE](#the-project-makefile)
  * [README.md](#readmemd)
* [USAGE](#usage)
  * [Commands](#commands)
  * [LLM Commands](#llm-commands)
  * [Options](#options)
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
    * [Planned Profiles](#planned-profiles)
* [EXTENDING THE BUILD SYSTEM](#extending-the-build-system)
  * [How the Makefile Works](#how-the-makefile-works)
  * [What belongs in project.mk](#what-belongs-in-projectmk)
  * [What does NOT belong in project.mk](#what-does-not-belong-in-projectmk)
  * [Keeping the build system up to date](#keeping-the-build-system-up-to-date)
  * [What You Should Never Modify](#what-you-should-never-modify)
  * [Dependencies Management](#dependencies-management)
* [MODULINOS](#modulinos)
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
  * [make update overwrote something I changed in a managed file](#make-update-overwrote-something-i-changed-in-a-managed-file)
  * [make says nothing to do but my source changed](#make-says-nothing-to-do-but-my-source-changed)
  * [How do I disable scanning temporarily?](#how-do-i-disable-scanning-temporarily)
  * [How do I disable syntax checking temporarily?](#how-do-i-disable-syntax-checking-temporarily)
  * [How do I upgrade the build system?](#how-do-i-upgrade-the-build-system)
  * [I want to add a bash script to my distribution](#i-want-to-add-a-bash-script-to-my-distribution)
  * [What is `make release-notes` used for?](#what-is-make-release-notes-used-for)
  * [Can I distribute the POD in my modules separately?](#can-i-distribute-the-pod-in-my-modules-separately)
  * [The dependency resolver keeps adding a file I don't want to](#the-dependency-resolver-keeps-adding-a-file-i-dont-want-to)
  * [Something still doesn't work - how do I report an issue?](#something-still-doesnt-work---how-do-i-report-an-issue)
* [SEE ALSO](#see-also)
* [DEPENDENCIES](#dependencies)
  * [Required for AI Commands](#required-for-ai-commands)
  * [Recommend Packages](#recommend-packages)
* [VERSION](#version)
* [AUTHOR](#author)
* [LICENSE](#license)
# NAME

CPAN::Maker::Bootstrapper - Scaffold a new CPAN distribution in one command

# SYNOPSIS

    # Create a configuration file (recommended first-time setup)
    cpan-maker-bootstrapper create-config > ~/.cpan-makerrc
    export CPAN_MAKER_CONFIG=$HOME/.cpan-makerrc

    # Create a new plain Perl module project
    cpan-maker-bootstrapper --module  My::New::Module

    # Create a CLI module project (inherits from CLI::Simple)
    cpan-maker-bootstrapper --module My::New::CLI --stub cli

    # Use a custom stub
    cpan-maker-bootstrapper --module My::Module --stub /path/to/mystub.pm

    # Import files from another project
    cpan-maker-bootstrapper --module My::Module \
     -I /path/to/my-module/lib -I /path/to/my-module/bin \
     --installdir /tmp/My-Module

    # Install into a specific directory
    cpan-maker-bootstrapper --module My::Module --installdir ~/git

    # Override git identity
    cpan-maker-bootstrapper --module My::Module --username "Rob Lauer" --email rob@example.org

    # Run a code review on a module (set API key in environment)
    export LLM_API_KEY=$(cat ~/.ssh/anthropic-api-key)
    cpan-maker-bootstrapper code-review lib/My/Module.pm    

# DESCRIPTION

[https://github.com/rlauer6/CPAN-Maker-Bootstrapper/actions/workflows/build.yml](https://github.com/rlauer6/CPAN-Maker-Bootstrapper/actions/workflows/build.yml)

[CPAN::Maker::Bootstrapper](https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper) scaffolds a new CPAN distribution directory
ready to build immediately. It installs a project Makefile, a
`buildspec.yml` pre-populated from your git config, stub source and test
files, and supporting makefiles - then runs `make` to generate the initial
artifacts.

The result is a project that can produce a distributable tarball with a
single additional `make` invocation, with no manual editing required for
a standard project layout.

[CPAN::Maker::Bootstrapper](https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper) also provides AI-assisted development
tools via the Anthropic Claude API. These include iterative code
review with structured finding annotations, POD documentation review
with **generation**, and AI-generated release notes. See ["LLM
Commands"](#llm-commands) and ["THE REVIEW WORKFLOW"](#the-review-workflow) for details regarding how to use
the AI tools for enhancing your code review process.

# QUICK START

Install the bootstrapper and its dependencies:

    cpanm CPAN::Maker CPAN::Maker::Bootstrapper

_Note: Before scaffolding your first project, consider running `create-config`
to set up a personal configuration file - it pre-populates your git
identity, GitHub username, and preferred project directory so you never
have to pass them on the command line. See ["CONFIGURATION"](#configuration) for details._

Scaffold a new project:

    cpan-maker-bootstrapper --module My::Module --installdir ~/git/My-Module

The bootstrapper creates the project directory, installs the build
system, generates stub source and test files, and runs `make`
automatically. By the time it finishes you already have a working
distribution tarball in `~/git/My-Module`.

    cd ~/git/My-Module

Review the generated files - particularly `buildspec.yml` which
controls how the distribution is built, and `requires` and
`test-requires` which list your module's dependencies. Your git
identity is pre-populated from `~/.gitconfig` but you may want to
adjust the description or resource URLs.

Edit the generated stub in `lib/My/Module.pm.in`. This is your
primary source file - never edit the generated `.pm` file directly
as it will be overwritten on the next `make`.

As your project grows, add new modules to `lib/` and scripts to
`bin/` as `.pm.in` and `.pl.in` files respectively. The build
system discovers them automatically - no changes to the Makefile
required. Add new test files to `t/` as `.t` files.

When you are ready to build:

    make

This scans your source files for dependencies, regenerates `requires`
and `test-requires`, generates `README.md` from your POD, and
produces a distributable tarball.

To verify your distribution installs cleanly:

    cpanm --local-lib=$HOME My-Module-*.tar.gz

To initialize version control and make your first commit:

    make git

See ["EXTENDING THE BUILD SYSTEM"](#extending-the-build-system) for customizing the build,
dependency management details. See ["FAQ"](#faq) for common
questions and recipes.

# WHY YOU SHOULD CONSIDER USING YET ANOTHER BUILD TOOL

If you have ever reached for Jenkins, GitHub Actions, CircleCI, or a
sprawling shell script to automate your Perl builds, consider what
those tools actually require: a server or cloud account, a proprietary
YAML DSL, plugin ecosystems with their own release cycles, containers,
agents, and configuration files that only run in one specific
environment.

The `CPAN::Maker` build system runs everywhere Perl runs - your
laptop, a remote EC2 instance, a colleague's workstation - with no
setup beyond `cpanm CPAN::Maker::Bootstrapper`. `git clone && make`
is always sufficient to build a fresh checkout.

## The Stack

The build system is built on three tools that have been solving these
problems correctly for decades:

- **GNU make** - dependency tracking, incremental builds, the
target/prerequisite model is still the clearest expression of _build
this from that_. A Makefile from 1990 still runs today.
- **bash** - process orchestration, file manipulation,
conditionals, the Unix toolkit. Available on every system you will
ever deploy to.
- **Perl** - text processing, CPAN ecosystem access, JSON, YAML,
HTTP - anything complex enough to warrant a real language, right there
in your build recipes without shelling out to another runtime.

Together they give you a complete, auditable, version-controlled build
system that is trivially debuggable with `make -n` and `bash -x`,
self-documents via `make help`, and needs no external services to run.

## Best Practices Out of the Box

The installed build system encourages professional Perl development
habits from the start:

- **Source files are clearly separated** - generated `.pm` and
`.pl` files live alongside their `.pm.in` and `.pl.in` sources.
The build system always regenerates the `.pm` from the `.pm.in` on
change, making it clear which file you own. Never edit the generated
file directly - your changes will be overwritten on the next `make`.
- **Dependencies are tracked automatically** - `scandeps-static.pl`
scans your source files on every build, keeping `requires` and
`test-requires` current. You stay in control via pinning, sticky
entries, and skip lists.
- **Quality gates are built in** - `perl -wc` syntax checking,
`perltidy`, and `perlcritic` run automatically on every build,
stopping bad code before it enters the distribution. Gates can be
selectively disabled via your configuration file or on the command
line (`make LINT=off`) when you need a faster build during
development.
- **The build system upgrades itself** - `make update` refreshes
managed build files from the installed bootstrapper; `make upgrade`
checks MetaCPAN and upgrades the bootstrapper itself.
- **Extension without modification** - `project.mk` is your
upgrade-safe extension point. Add custom targets, inter-module
dependencies, and project-specific variables there. The managed
`Makefile` is never modified directly.

## Perl Quality Tools

The build system supports optional Perl quality gates controlled via
your configuration file. Set the following keys in the `[cpan-maker]`
section:

    syntax-checking = on          # enables perl -wc on generated files
    perltidyrc = ~/.perltidyrc    # enables perltidy stage gate
    perlcriticrc = ~/.perlcriticrc # enables perlcritic stage gate

These can be overridden per-run from the command line:

    make SYNTAX_CHECKING=off      # disable syntax checking
    make PERLTIDYRC=""            # disable tidy gate
    make PERLCRITICRC=""          # disable critic gate

Add modules that cannot be syntax-checked outside their runtime
environment to `PERLWC_SKIP` in `project.mk`:

    PERLWC_SKIP = bin/startup.pl

Add inter-module build dependencies to `project.mk` when modules
depend on each other at build time:

    lib/Foo/Bar.pm: lib/Foo.pm

To disable all linting at once:

    make LINT=off

Or use `make quick` to disable both scanning and linting in one step.

## A GNU Make Tutorial in Disguise

The `.includes/` directory is also a practical demonstration of
advanced GNU make techniques that most developers never encounter -
working, production-tested examples you can learn from and adapt:

- Pattern rules and sentinel files for incremental quality gates
- `define`/`endef` snippets - reusable shell and Perl code
blocks exported as make variables, eliminating duplication across
recipes
- `$(shell ...)`, `$(eval ...)`, `$(call ...)`,
`$(filter-out ...)`, `$(addprefix ...)`, `$(patsubst ...)` - the
full make function toolkit in real use
- `?=`, `:=`, `+=`, and `=` - all four assignment operators
with their distinct evaluation semantics put to work
- Order-only prerequisites, `.DEFAULT_GOAL`, `-include`, and
`.SHELLFLAGS := -ec` - advanced directives that tame complex builds
- Trap-based temp file cleanup, `mktemp`, and bash `[[ ]]`>
conditionals inside make recipes
- Perl snippets exported into make via `$(value ...)` and
`export` - leveraging Perl's text processing power directly in the
build

If GNU make is the cast-iron pan of build tools - virtually
indestructible, infinitely useful, and unfairly overlooked in favor of
shinier alternatives - then `CPAN::Maker::Bootstrapper` is the recipe
book that shows you what it can really do.

# IMPORTING FILES

The `--import|-I` option allows you to bring existing Perl source
files into a new Bootstrapper project. This is the primary mechanism
for migrating an existing project or consuming a scaffold tarball
generated by `cli-simple -scaffold`.

The `--import` option may be specified multiple times to import from
several directories in a single operation:

    bootstrapper --module My::Script \
      --import /path/to/roles \
      --import /path/to/bin \
      --installdir .

## What Gets Imported

The importer recursively scans the path provided by `--import` and
brings in the following file types:

- `.pm` files - copied to `lib/` as `.pm.in` source files,
preserving the directory structure implied by the package name
- `.pl` files - copied to `bin/` as `.pl.in` source files
- `.t` files - copied to `t/`
- Executable files - copied to `bin/` as `.in` files.

    _Note: Executable files are imported with their execute permission
    removed. The build system sets permissions appropriately when
    generating the final files from the `.in` sources._

All imported files receive the `.in` extension because they become
source inputs to the build system. The build generates the final
`.pm`, `.pl`, and script files from these sources, substituting
version tokens and running syntax checks along the way.

## Module Name Requirement

When using `--import` you must also specify `--module` with the
primary module name of the distribution. The importer cannot infer
the module name from the imported files alone:

    bootstrapper --module My::Script --import /path/to/source --installdir .

## The Build After Import

After creating the project source tree the importer runs `make`
with linting disabled but syntax checking and dependency scanning
enabled:

    make LINT=off SYNTAX_CHECKING=on SCAN=on

This serves two purposes - it validates that the imported files are
syntactically correct Perl, and it runs `scandeps-static.pl` against
the source to seed the `requires` and `test-requires` dependency
files.

The build will attempt to produce a distribution tarball. If the
build fails, `make.log` and `make.err` are written to your current
working directory for diagnosis.

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
          - ChangleLog <= include is distribution tarball, but not installed
          share:
            - config/some-file.ini  <= installs some-file.ini from your config/ directory
            - my-app.json <= install my-app.json from the root of your project

- 3. Initialize a git repository with `make git`
- 4. Run `make tidy` if you have `perltidy` installed
- 5. Run `make` to produce the final distribution tarball

    By default the repipes in the `Makefile` will perform the following
    actions:

    - Perform a syntax check (`perl -wc -I lib $@`) on your source files
    - Scan your source for dependencies

        To turn this off:

            make SCAN=off

    - Run `perltidy` on your source files

        To turn this off:

            make PERLTIDYRC=""
            make LINT=off

    - Run `perlcritic` on your source files

            make PERLCRITICRC=""
            make LINT=off

    To turn off everything except syntax checking:

        make quick

- 6. Test installation: `cpanm -n -v ./My-Script-1.0.0.tar.gz`

## Limitations

- `--import` cannot be used with `--stub` - they are mutually
exclusive ways to create the initial source
- The importer uses the package declarations inside `.pm` files
to determine where to place them under `lib/`. If the importer cannot
match the filename with a package declaration inside the file, it will
warn and skip that file
- Imported files are not tidied automatically. If you have
`perltidy` installed, run `make tidy` after import to bring the
imported code into conformance with your `.perltidyrc` before
committing
- If your imported modules have dependencies on each other, the
syntax check phase of the build may fail because Make processes files
independently and cannot guarantee build order. Add a `project.mk`
to declare inter-module dependencies:

        lib/My/Script.pm: \
          lib/My/Script/Role/Frobnicate.pm \
          lib/My/Script/Role/List.pm

    Make will then build your dependencies before attempting to syntax-check
    the main module. See ["EXTENDING THE BUILD SYSTEM"](#extending-the-build-system) for details on
    `project.mk`.

## Importing a CLI::Simple Scaffold Tarball

The `import-scaffold` command is a convenience wrapper around
`--import` specifically designed to consume tarballs generated by
`cli-simple -scaffold`:

    bootstrapper import-scaffold my-script-roles.tar.gz \
      --module My::Script --installdir .

The tarball is extracted to a temporary directory and fed to the
importer automatically. See [CLI::Simple](https://metacpan.org/pod/CLI%3A%3ASimple) for details on generating
scaffold tarballs.

# CONFIGURATION

`cpan-maker-bootstrapper` can read your global `.gitconfig` file or
a properly formatted `.ini` file to populate some of the options used
when creating a distribution and using the AI commands. If you have a
GitHub user account add your username:

    git config --global user.github <your-username>

If you typically create projects in one directory, add the `basedir`
option:

    git config --global cpan-maker.basedir $HOME/git

If you want to create a different configuration file it should have at
least the following entries:

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

- Use the `--config` option to use your custom config.
- Use `create-config` to generate a starter configuration file:

        cpan-maker-bootstrapper create-config > ~/.cpan-makerrc

    Then point `cpan-maker-bootstrapper` at it by setting the
    `CPAN_MAKER_CONFIG` environment variable in your shell profile:

        export CPAN_MAKER_CONFIG=$HOME/.cpan-makerrc

## Environment

- LLM\_API\_KEY

    Your Anthropic Claude API key. Set this before running any LLM command
    (code-review, pod-review, release-notes).

    The key is removed from environment so it is not inherited by child
    processes such as 'make'. This does not protect against memory
    inspection of the current process - see [LLM::API](https://metacpan.org/pod/LLM%3A%3AAPI) for how the key is
    actuall stored using a closure to prevent accidental serialization
    via Dumper.

    Avoid passing the key on the command line where it might be saved in
    history and can be seen in process lists.

- CPAN\_MAKER\_CONFIG

    Path to a configuration file (in .ini format) containing user settings
    such as name, email, GitHub username, and project base directory. If
    not set, the bootstrapper will attempt to read settings from
    ~/.gitconfig.

- SCAN

    Controls whether dependency scanning is performed during `make`. Set
    to OFF or off to disable scanning. Default is ON.

# INSTALLED PROJECT FILES

The following files are installed into the project directory:

- `Makefile` - the complete build system. Derives all paths and
names from `MODULE_NAME` or your stub file's package name. See ["THE
PROJECT MAKEFILE"](#the-project-makefile).
- `buildspec.yml` - generated from the template, pre-populated
with your module name, git identity, GitHub username, and project URLs.
- `lib/<Module/Path>.pm.in` - stub module, populated from
either `class-module.pm.tmpl` (default) or `cli-module.pm.tmpl` (when
`--stub cli` option is used). Contains package declaration, `$VERSION`,
and a POD skeleton with your name and email from git config.

    _Note: All source files in `lib/` and `bin/` use the `.pm.in` / `.pl.in`
    convention. These are the files you edit. The `.pm` and `.pl` files are
    derived from them by the pattern rules in the Makefile, which substitute
    `@PACKAGE_VERSION@` with the current value of `VERSION`. Never edit the
    generated `.pm` or `.pl` files directly - your changes will be
    overwritten the next time `make` runs!_

- `t/00-<project-name>.t` - minimal smoke test that calls
`use_ok` on your module.
- `.includes/` - the managed build system directory. Contains
all `.mk` files installed and maintained by the bootstrapper. These
files are write-protected and should never be edited directly. Updated
by `make update`.

        .includes/perl.mk         - pattern rules, syntax checking, tidy, critic
        .includes/git.mk          - make git target
        .includes/help.mk         - make help target
        .includes/version.mk      - make release/minor/major targets
        .includes/release-notes.mk - make release-notes target
        .includes/update.mk       - make update target
        .includes/upgrade.mk      - make upgrade/check-upgrade targets

- `project.mk` - your extension point for custom make rules,
inter-module dependencies, and project-specific variables. Never
touched by `make update`. See ["EXTENDING THE BUILD SYSTEM"](#extending-the-build-system).
- `modulino.tmpl` - template used by `make modulino` to
generate bash wrapper scripts for modulino-style modules.
- `VERSION` - contains the current version string in
`major.minor.patch` format. Managed by `make release`, `make minor`,
and `make major`.
- `ChangeLog` - empty placeholder, required by the distribution.
- .prompts/

    The first time you attempt to run `pod-review` or `code-review` the
    script will populate this directory with the default prompts.

# THE PROJECT MAKEFILE

The installed Makefile is self-configuring. It can derive everything
from `MODULE_NAME` or the package name inside a custom stub file.

    MODULE_PATH  - lib/My/New/Module.pm (from MODULE_NAME)
    PROJECT_NAME - My-New-Module (from MODULE_NAME)
    TARBALL      - My-New-Module-1.0.0.tar.gz (from PROJECT_NAME + VERSION)

If `MODULE_NAME` is not supplied on the command line, it is inferred
from the project directory name.

Key Makefile targets:

- `make` / `make all`

    Builds the distribution tarball. Generates `requires`,
    `test-requires`, and `README.md` as prerequisites.

- `make requires` / `make test-requires`

    Scans source files with `scandeps-static.pl` and writes the dependency
    files specified in the `buildspec.yml` file used by `make-cpan-dist.pl`.

    _Note: By default, any change to your `.pm.in` files will trigger a
    rescan of your modules for new dependencies. This will add a
    significant delay when you have many modules and a large number of
    dependencies. You can avoid the scan by setting the environment
    variable `SCAN` to any value other than `ON` (case insensitive)._

        make SCAN=OFF

- `make release` / `make minor` / `make major`

    Bumps the patch, minor, or major version number in `VERSION`.

- `make release-notes`

    Generates a diff, file list, and tarball comparing the current version
    to the previous git tag.

- `make clean`

    Removes generated files. Does not affect `buildspec.yml`, `VERSION`,
    or any `*.in` source files.

- `make tidy`

    Runs `perltidy` on all `.pm.in` and `.pl.in` source files using
    the profile specified by `perltidyrc` in your config. Requires
    `perltidyrc` to be set.

- `make critic`

    Runs `perlcritic` on all source files using the profile specified by
    `perlcriticrc` in your config. Requires `perlcriticrc` to be set.

- `make lint`

    Runs both `make tidy` and `make critic`.

- `make git`

    Initializes a git repository, stages all recommended project files
    including `.includes/*`, and makes an initial `BigBang` commit.

- `make quick`

    Builds the distribution tarball with dependency scanning and all
    linting disabled. Useful during active development when you want fast
    iterative builds without waiting for `scandeps-static.pl` or quality
    gates.

        make quick

    Equivalent to:

        make SCAN=off LINT=off

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

If you want a different `README.md` generated create a
`README.md.in` file. That file will be filtered through
`md-utils.pl` (from [Markdown::Render](https://metacpan.org/pod/Markdown%3A%3ARender)) to produce a `.md` file.

# USAGE

    cpan-maker-bootstrapper options command

## Commands

- install (default)

    Scaffolds a new project. This is the default command so:

        cpan-maker-bootstrapper -m My::Module

    ...is the same as:

        cpan-maker-bootstrapper -m My::Module install

- create-config

    Outputs a stub configuration file to STDOUT. Create and edit a new
    config to customize the behavior of `cpan-maker-bootstrapper`.

        cpan-maker-bootstrapper create-config > ~/.cpan-makerrc

    Then set `CPAN_MAKER_CONFIG` to point to it:

        export CPAN_MAKER_CONFIG=$HOME/.cpan-makerrc

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

        cpan-maker-bootstrapper code-review [options] lib/My/Module.pm

    The review file is named:

        <module>-review-<timestamp>.code

    A token usage summary is printed to stderr after the review completes.

    If a review has been completed at least once the annotated review file
    is automatically sent with your code to re-focus the review. You must
    annotate the review file before resubmitting by running the
    `annotate` command and marking each finding with a valid
    dispostion. See ["THE REVIEW WORKFLOW"](#the-review-workflow) for details.

    Options specific to code-review:

        --prompt|-p PATH          path to a custom review prompt file
        --prompt-profile|-P NAME  additive prompt profile (repeatable)
        --context|-C PATH         context file to submit alongside the review (repeatable)

    _Note: The prompt profile list and the context file list is written
    to the review output file. On subsequent runs these will be read from
    the review. You do not need to provide them unless you want to update
    their values._

- annotate

    Applies disposition tags to findings in the latest review file and
    displays the current annotation state. Must be run from a project
    directory (one containing `.includes/`).

        cpan-maker-bootstrapper annotate [options] lib/My/Module.pm

    Without options, displays the current annotation state of the latest
    review file. With `-a` options, applies the specified dispositions
    before displaying.

        cpan-maker-bootstrapper annotate lib/My/Module.pm
        cpan-maker-bootstrapper annotate -a 1:wrong -a 2:reject lib/My/Module.pm

    Options:

        --annotate|-a N:DISPOSITION    apply disposition to finding N (repeatable)
        --auto-annotate|-A             annotate and immediately submit the next review
        --finalize-annotations|-F      create versioned release artifact

    Valid dispositions are `accept`, `reject`, `wrong`,
    `wrong-reconsider`, `defer`, and `confirmed` (case
    insensitive). See ["THE REVIEW WORKFLOW"](#the-review-workflow) for a description of each.

- pod-finding

        cpan-maker-bootstrapper pod-finding lib/CPAN/Maker/Bootstrapper.pm

    Run this after a `pod-review` command to display a table of findings.

- pod-review

    Submits a Perl module or script to the LLM for a documentation review.
    The full file including code is submitted so the LLM can check
    consistency between implementation and documentation. If no POD exists
    the LLM generates complete POD documentation ready to paste after
    `__END__`.

        cpan-maker-bootstrapper pod-review lib/My/Module.pm

    The review file is named:

        <module>-review-<timestamp>.pod

- release-notes

    Generates release notes for a given version using the LLM. Requires
    the release artifacts produced by `make release-notes`:

        release-<version>.diffs
        release-<version>.lst
        release-<version>.tar.gz

    Usage:

        cpan-maker-bootstrapper release-notes <version>

    The generated release notes are written to `release-notes-<version>.md`.
    Binary files are automatically excluded. Use `--max-diff-files` to
    cap token consumption on large distributions (default: 50, 0 = unlimited).

- code-finding

    Generates a table with the complete details of a finding.

        cpan-maker-bootstrapper code-finding lib/My/Module.pm 1

## Options

- `--annotate|-a` N:DISPOSITION

    See ["annotate"](#annotate)

- `--auto-annotate|-A`

    See ["annotate"](#annotate)

- `--basedir|-b` DIR

    Base directory in which to create the projects. Defaults to the
    current working directory when `--installdir` and `--basedir` are not
    provided. The directory must exist or the script will throw an
    exception.

    _Note: If `--installdir` is provided it takes precedence and
    `--basedir` is ignored._

    default: pwd

- `--dry-run|-D`

    Dry run mode will abort after displaying a pre-submission token and
    cost estimation for the `pod-review` and `code-review` commands.

- `--config|-c` configuration file

    The path to a `.ini` file that contains configuration information
    used to scaffold your project.

    default: ~/.gitconfig

- `--color, --no-color`

    Turns coloring of the annotation summary table on or off.

    default: on

- `--context|-C` PATH

    One or more files to submit with your code review file that provide
    additional context for the LLM during the review.

- `--email|-e` EMAIL

    Override the author email. Defaults to `user.email` from your global
    git config.

- `--finalize-annotations|-F`

    See ["annotate"](#annotate)

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

        cpan-maker-bootstrapper --module Foo::Bar -I ~/foo-bar/lib -I ~/foo-bar/bin

    When using the `--import` option, you must use the `--module` option
    to specify the primary module name of the distribution. The importer
    cannot infer the module name from the imported files alone.

    _Note: The `Makefile` will automatically attempt to substitute the
    token `@PACKAGE_VERSION@` inside your `.pl.in` or `.pm.in` files with
    the current semantic version in the `VERSION` file. If you want to
    use that for versioning your scripts and modules add the token as
    shown below:_

    `our $VERSION = '@PACKAGE_VERSION@;'`

- `--installdir|-i` DIR

    Directory in which to create the project. Defaults to the
    current working directory. The directory is created if it does not
    exist.

    Example:

        cpan-maker-bootstrapper --installdir ~/git/My-Module

    The install directory should include the project name.

    _Note: `--installdir` overrides `--basedir`_.

- `--max-diff-files` LIMIT

    The number of files inside the tarball that contains the changed files
    for release notes creation that can be uploaded to the LLM. Set to 0
    for no limit.

    default: 50

- `--max-tokens|-t` TOKENS

    Maximum number of tokens the LLM may return in a single response.
    Higher values reduce the risk of truncated reviews on large files.

    default: 4096 (set by [LLM::API](https://metacpan.org/pod/LLM%3A%3AAPI))

- `--model|-M` MODEL

    Specifies the model id to use for the `pod-review` and `code-review`
    commands.

    For `pod-review` the default model is `claude-haiku-4-5-20251001`.

    For `code-review` the default mode is `claude-sonnet-4-6`.

    The Haiku model tends to be better at summarizing documentation and
    avoiding unnecessary analysis around edge cases that contribute to
    noise.

    _Caution: Both models try hard to find issues to the point that you
    will almost never get a clean run when asking for a POD review. When
    your POD is complete, accurate and usable it's good enough. Avoid
    shaving the yak!_

- `--module|-m` MODULE (required)

    The Perl module name for the new project, e.g. `My::New::Module`.
    Used to derive the project directory name, source file path, and
    tarball name. You can omit this option if you provide a stub file
    (`--stub path`) that contains a package name that is consistent with
    the stub's path. For example, if my package is `My::App` and the
    module path contains `My/App` then the script will assume your
    module name is `My::App`.

        cpan-maker-bootstrapper --stub $HOME/workdir/My/App.pm

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

# THE REVIEW WORKFLOW

`CPAN::Maker::Bootstrapper` allow you implement a structured
iterative code review workflow built around JSON review files and
developer-applied disposition annotations. The workflow converges over
several rounds, with each round potentially costing less as noise is
suppressed and findings are resolved.

## Overview

Each review round consists of three steps:

- 1. Run a review

        cpan-maker-bootstrapper code-review \
          --prompt-profile cli-tool \
          lib/My/Module.pm

    The review is written to a timestamped `.code` file containing a JSON
    object with `findings`, `confirmations`, and `deferred` arrays.

- 2. Annotate the findings

        cpan-maker-bootstrapper annotate lib/My/Module.pm

    This displays the current annotation state. Apply dispositions with
    `-a` options:

        cpan-maker-bootstrapper annotate \
          -a 1:accept -a 2:wrong -a 3:reject -a 4:defer \
          lib/My/Module.pm

    You can annotate incrementally across multiple invocations. Each call
    shows the updated state so you always know what remains.

- 3. Submit the next review

    Once all findings are annotated and code updated if necessary, run the
    next review. The bootstrapper automatically finds and submits the
    latest annotated review file with your updated code:

        cpan-maker-bootstrapper code-review lib/My/Module.pm

    Alternatively, use `--auto-annotate|-A` with the `annotate` command
    to annotate and immediately resubmit in one step:

        cpan-maker-bootstrapper annotate -a 1:wrong -a 2:reject --auto-annotate \
          lib/My/Module.pm

    The LLM will honor all dispositions from the prior round, confirm
    fixes marked `ACCEPT`, carry forward `DEFER` items, and suppress
    `REJECT` and `WRONG` findings. New findings appear without noise
    from settled questions.

## Dry Run Mode

Before your prompt and code are submitted for review, the script will
output a table of showing you the estimated cosst based on token
counts. The input token count is derived by calling the "COUNT TOKEN"
endpoint API with the message to be submitted for review. The input
token count is therefore accurate, while the output token count is an
estimate.

To stop the script for actually submitting the message for review, use
the `--dry-run` option. This will abort the process immediately prior
to submission.

## Dispositions

Each finding in the annotations file must be given one of the following
dispositions before the next review can be submitted:

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
as obvious findings are resolved. Stop when you see these signals:

- All new findings are LOW severity.
- The LLM is re-raising findings already marked WRONG or REJECT,
possibly rephrased.
- New findings describe edge cases that cannot occur in normal usage.

When all findings have dispositions and no new substantive issues
appear, the code is ready to ship.

## The Release Artifact

When you are satisfied with the review state, finalize it with
`--finalize-annotations`:

    cpan-maker-bootstrapper annotate --finalize-annotations \
      -a 1:wrong -a 2:reject \
      lib/My/Module.pm

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

Typical review costs run $0.05-0.10 per run on a moderately sized
module with POD stripped depending on the model you choose. The
default model used for POD review is `claude-haiku-4-5-20251001` and
`claude-sonnet-4-6` for code review. Costs decrease over successive
rounds as the model spends fewer output tokens re-explaining
suppressed findings.

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

## Using Profiles

Pass one or more profiles using the `--prompt-profile` option:

    cpan-maker-bootstrapper code-review --prompt-profile cli-tool MyModule.pm

Multiple profiles may be combined:

    cpan-maker-bootstrapper code-review \
      --prompt-profile cli-tool \
      --prompt-profile security \
      MyModule.pm

Profiles are resolved from the `.prompts/` directory in the current
project. A profile named `cli-tool` resolves to
`.prompts/cli-tool.prompt`. Add your own prompt profiles and commit
them to your project.

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
prompt instructions, one per line. Lines beginning with `#` are treated
as comments and stripped before submission. Profile instructions use the
same format as the base review prompt.

Example `.prompts/security.prompt`:

    # security profile - add to any review where input handling matters
    - Treat all caller-supplied input as untrusted regardless of source.
    - Flag any use of eval, system, or exec that incorporates external data.
    - Flag missing taint checks on data used in file or system operations.

### Planned Profiles

The following profiles are planned for future releases:

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

The bootstrapper's `Makefile` is intended to be immutable and work
across all of the projects that use `CPAN::Maker::Bootstrapper`. Our
goal is to keep `Makefile` working for you even when we make updates
to the bootstrapper.

However, you own `Makefile` and are free to do with it as you
please. But we strongly advise that you read the sections below and
follow the _recipe_ as the saying goes, to use and update the build
system as it was intended.

The installed `Makefile` is a managed file - it can be updated by
using the `make` target `update` when a new version of
`CPAN::Maker::Bootstrapper` is released.

    make update

You are strongly advised not to modify the `Makefile` - your changes
will be overwritten if you run `make update`.

Instead, the recommended workflow, should you need to add new make
targets or control the order of the build based on dependencies is to
add those to `project.mk`. All managed build system files live in
the `.includes/` directory where they are write-protected and clearly
separated from your project files. The `Makefile` includes them
automatically and conditionally includes `project.mk` from the
project root:

    include .includes/perl.mk
    include .includes/help.mk
    include .includes/version.mk
    include .includes/release-notes.mk
    include .includes/git.mk
    include .includes/update.mk
    include .includes/upgrade.mk
    -include project.mk

`project.mk` remains in the project root - it is your file, always
writable, and never touched by `make update`. The leading `-` on
its include means make will not complain if it does not exist yet.
This gives you a sanctioned, upgrade-safe extension point for
anything project-specific.

## How the Makefile Works

The installed `Makefile` is structured around a few key concepts:

- **Source files** live in `lib/` as `.pm.in` and in `bin/` as
`.pl.in`. The build generates the final `.pm` and `.pl` files from
these sources by substituting `@PACKAGE_VERSIONE@` and other
tokens, running syntax checks, and optionally running perltidy and
perlcritic.
- **Sentinel files** - `.tdy` and `.crit` files track whether
a source file has passed tidiness and critic checks. These are
regenerated only when the source changes.
- **Dependency scanning** - `scandeps-static.pl` scans your
source files and generates `requires` and `test-requires` files
which feed into `Makefile.PL`. Controlled by `SCAN=on|off`.
- **The distribution tarball** is the final output of `make`.
It is built by `make-cpan-dist.pl` using `buildspec.yml`.

Key variables you can override on the make command line or in
`project.mk`:

- `SCAN=off` - skip dependency scanning
- `LINT=off` - skip perltidy and perlcritic
- `SYNTAX_CHECKING=off` - skip `perl -wc` syntax checks
- `MIN_PERL_VERSION=5.016` - minimum Perl version for Makefile.PL
- `PERLTIDYRC=/path/to/rc` - path to perltidy configuration
- `PERLCRITICRC=/path/to/rc` - path to perlcritic configuration
- `SKIP_TESTS=1` - skips running tests when building distribution

## What belongs in project.mk

- Custom targets

    Any target specific to your project - generating assets, running
    linters, deploying, sending notifications:

        .PHONY: deploy
        deploy: all
            scp $(TARBALL) user@myserver:/opt/cpan

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

## What does NOT belong in project.mk

- Modifications to existing targets like `all`, `clean`, `requires`
- Changes to `DEPS`, `CLEANFILES`, or other core variables - these
are owned by the managed Makefile
- Anything that duplicates logic already in the managed Makefile

## Keeping the build system up to date

The following targets manage the lifecycle of the build system itself:

- `make check-upgrade` / `make upgrade-check`

    Checks MetaCPAN to see if a newer version of
    `CPAN::Maker::Bootstrapper` is available.

- `make upgrade`

    Checks MetaCPAN, installs the latest version via `cpanm`, then
    automatically runs `make update` to refresh the managed project
    files.

- `make update`

    Copies the managed files from the currently installed bootstrapper
    distribution into your project directory. After running, use
    `git diff` to review what changed and `git checkout <file>`
    to revert any changes you don't want.

    The following files are managed and may be updated:

        Makefile
        .includes/git.mk
        .includes/help.mk
        .includes/update.mk
        .includes/upgrade.mk
        .includes/version.mk
        .includes/perl.mk
        .includes/release-notes.mk
        modulino.tmpl

    Your `project.mk`, `buildspec.yml`, `requires`, `VERSION`, source
    files and tests are **never** touched by `make update`.

- `make cpanm`

    Installs `cpanminus` if it is not already available on your
    `PATH`. Required for `make upgrade` to work:

        make cpanm && make upgrade

## What You Should Never Modify

The files in `.includes/` - `perl.mk`, `git.mk`, `help.mk` etc.
\- are managed files that will be overwritten by `make update`. Do
not modify them directly. If you need to override behavior they
provide, do so in `project.mk` using Make's double-colon rule
pattern or by setting variables before the include.

The `Makefile` itself is also managed and will be overwritten by
`make update`. Your extension point is exclusively `project.mk`.

## Dependencies Management

The `Makefile` will attempt to detect Perl module dependencies by
scanning .pm.in and .pl.in files and creating the `requires` and
`test-requires` files whenever you run `make`. These files are used
by the `make-cpan-dist.pl` utility to specify the dependencies in your
CPAN distribution file. You can prevent that by setting the environment
variable `SCAN=OFF`. The default is `SCAN=ON`.

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

The `Makefile` provides a `modulino` target that generates a bash
wrapper script that invokes your module. By default it uses
`MODULE_NAME`, producing a script named after the module:

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

# PREREQUISITES

The following tool(s) must be on your `PATH`:

- `git` - used to read global identity config
- `make` - GNU make is required to build the project
- `curl` - used by `make upgrade` to query MetaCPAN

# CAVEATS

- `.pm` and `.pl` Generation

    These files are generated from `.pm.in` and `.pl.in` files in the
    Makefile by filtering them through a `sed` command that replaces
    certain tokens like `@PACKAGE_VERSION@` with values. The
    generated files are read-only. Always edit the `.in` file version.

    Use `@PACKAGE_VERSION@` like this:

    `our $VERSION ='``@PACKAGE_VERSION@``';`

- The import feature cannot be used with `--stub`
- git

    There is an assumption that users of this script are also `git`
    users. `git` is required to run `make git` which instatiates a git
    project and makes an intial commit. It's also used to look into your
    `.gitconfig` file for your name and email address to populate the
    certain element in the resources file used when building your CPAN
    distribution.

# FAQ

## My build is failing with a module not found error during syntax
checking

This is almost always a build-time dependency ordering issue. If
`lib/Foo/Bar.pm` uses `lib/Foo.pm`, make may attempt to build and
syntax-check `Foo/Bar.pm` before `Foo.pm` exists. Declare the
dependency in `project.mk`:

    lib/Foo/Bar.pm: lib/Foo.pm

This tells make to build `Foo.pm` first. See ["Inter-module
dependencies"](#inter-module-dependencies) for details.

If the module genuinely cannot be loaded outside its runtime
environment (an Apache handler, a mod\_perl module, etc.), add it to
`PERLWC_SKIP` in `project.mk`:

    PERLWC_SKIP = lib/My/Apache/Handler.pm

## How do I do a fast build during development?

    make quick

This disables dependency scanning and all linting (syntax checking,
perltidy, perlcritic) for the current build. Your `requires` and
`test-requires` files are not updated and no quality gates run.

Use `make` without flags when you are ready to do a full build before
committing or releasing.

You can also disable individual features:

    make SCAN=off          # skip dependency scanning only
    make LINT=off          # skip all linting only
    make SYNTAX_CHECKING=off  # skip syntax checking only

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
the version number controls what version is required. See ["Dependencies"](#dependencies)
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
is regenerated on every `make` and your changes will be lost.

If you are unsure which file to edit:

    ls -l lib/My/Module.pm lib/My/Module.pm.in

The `.pm.in` file is the one you own.

## make update overwrote something I changed in a managed file

The managed files in `.includes/` should never be edited directly -
that is what `project.mk` is for. However if you did modify a managed
file and `make update` overwrote it, git has you covered:

    git diff .includes/perl.mk
    git checkout .includes/perl.mk

This is why `make git` and committing your `.includes/` directory is
strongly recommended - git is your safety net for the entire build
system.

## make says nothing to do but my source changed

The most common cause is that the generated `.pm` file is newer than
the `.pm.in` source. This can happen if you accidentally edited the
`.pm` directly or if file timestamps got out of sync. Force a rebuild:

    touch lib/My/Module.pm.in

Or do a clean rebuild:

    make clean && make

## How do I disable scanning temporarily?

    make SCAN=off

This skips the dependency scan entirely for that run - useful when
you have many modules and want a fast build during active development.
The default is `SCAN=ON`.

## How do I disable syntax checking temporarily?

    make SYNTAX_CHECKING=off

Similarly you can disable individual quality gates:

    make PERLTIDYRC="" PERLCRITICRC=""

## How do I upgrade the build system?

    make upgrade

This checks MetaCPAN for a newer version of
`CPAN::Maker::Bootstrapper`, installs it via `cpanm`, and
automatically refreshes the managed files in `.includes/` with
`make update`. Review the changes with `git diff` and revert
anything you don't want with `git checkout`.

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

`make release-notes` generates three artifacts comparing the current
working state of your repository against the previous git tag:

- `release-<version>.diffs` - a unified diff of all
changed files
- `release-<version>.lst` - a list of added, modified,
and removed files
- `release-<version>.tar.gz` - a tarball containing
only the changed files

These are primarily useful for generating release notes and changelogs,
and for submitting targeted patches. Run it after bumping the version
with `make release`, `make minor`, or `make major` and before
publishing to CPAN:

    make minor
    make release-notes
    # review release-1.1.0.diffs
    make

The artifacts are all the clues needed for LLMs to produce accurate
and well written release notes for your project.

The release artifacts are cleaned up by `make clean`.

## Can I distribute the POD in my modules separately?

When you package your CPAN distribution you can strip the pod from
your modules or you can extract the pod and provide them as separate
`.pod` files. There are two `make` environment variables you can set
to control that behavior.

- `make POD=extract`

    `extract` will strip POD from your module and create a `.pod` file
    containing the stripped POD that will be added to your distribution.

- `make POD=remove`

    `remove` will strip POD from your module. No POD will be included in
    the distribution.

## The dependency resolver keeps adding a file I don't want to
list. How can I tell it to skip those files?

Add a `requires.skip` file to exclude modules from the scanned
list. Sometimes the scanner may include modules that are optional or
modules you just don't want to include as requirements because they
are already included in a module you have already required.

Similarly, `test-requires.skip` excludes modules from the test
dependency scan.

On a clean first run neither `requires` nor `test-requires` exists
yet, so the raw scanner output becomes the dependency file - meaning
skip list and pins have no effect until the second run.

## Something still doesn't work - how do I report an issue?

First check the ["FAQ"](#faq) sections above - your
issue may already be covered.

If you believe you have found a bug or want to request a feature,
please open an issue on GitHub:

    https://github.com/rlauer6/CPAN-Maker-Bootstrapper/issues

When reporting a bug please include:

- The version of `CPAN::Maker::Bootstrapper` (`cpan-maker-bootstrapper --version`
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

[Module::ScanDeps::Static](https://metacpan.org/pod/Module%3A%3AScanDeps%3A%3AStatic) - the static dependency scanner used by
`make requires` and `make test-requires` to analyze your source files

# DEPENDENCIES

    CLI::Simple::Constants
    CLI::Simple::Utils
    CPAN::Maker::ConfigReader
    Cwd
    English
    Email::Valid
    File::Basename
    File::Copy
    File::Find
    File::Path
    File::ShareDir
    File::Temp
    JSON::PP
    List::Util
    Module::Metadata;

## Required for AI Commands

    Archive::Tar
    Pod::Extract (required for code-review command)
    Text::ASCIITable;

## Recommend Packages

    Term::ANSIColor

# VERSION

This documentation refers to version 1.1.1

# AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

# LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
