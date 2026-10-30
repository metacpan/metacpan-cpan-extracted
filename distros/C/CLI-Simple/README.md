# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [VERSION](#version)
* [FEATURES](#features)
* [QUICK START](#quick-start)
  * [Single-Module Application](#single-module-application)
  * [Role-Based Application](#role-based-application)
* [MODULINOS](#modulinos)
  * [Why Modulinos?](#why-modulinos)
  * [The Bash Wrapper](#the-bash-wrapper)
  * [create-modulino](#create-modulino)
  * [MODULINO\_WRAPPER](#modulino\wrapper)
* [ROLE-BASED ARCHITECTURE](#role-based-architecture)
  * [The YAML Manifest](#the-yaml-manifest)
  * [Loading Multiple Manifests](#loading-multiple-manifests)
  * [Option Initialization](#option-initialization)
  * [Command Values](#command-values)
  * [`roles:` vs `commands:`](#roles-vs-commands)
  * [When to Use Each Approach](#when-to-use-each-approach)
  * [Sharing Methods Between Commands](#sharing-methods-between-commands)
  * [Roles With No Commands](#roles-with-no-commands)
  * [Activating Role-Based Architecture](#activating-role-based-architecture)
  * [The Inherited main()](#the-inherited-main)
  * [Distributing the Manifest](#distributing-the-manifest)
* [PHILOSOPHY AND DESIGN PRINCIPLES](#philosophy-and-design-principles)
  * [Validation, Defaults, and Configuration](#validation-defaults-and-configuration)
  * [When to Use](#when-to-use)
  * [The init-run Lifecycle](#the-init-run-lifecycle)
  * [Opt-in Default Command](#opt-in-default-command)
  * [`$AUTO_HELP` and `$AUTO_DEFAULT`](#$autohelp-and-$autodefault)
* [CONSTANTS](#constants)
* [ADDING USAGE TO YOUR SCRIPTS](#adding-usage-to-your-scripts)
  * [Customizing Help Output](#customizing-help-output)
    * [Custom help() Method](#custom-help-method)
    * [`help_sections`](#helpsections)
* [INTERNAL COMMANDS](#internal-commands)
  * [-generate-completion](#-generate-completion)
  * [-dump-spec](#-dump-spec)
  * [-scaffold](#-scaffold)
  * [-migrate](#-migrate)
* [METHODS AND SUBROUTINES](#methods-and-subroutines)
  * [use\_log4perl](#use\log4perl)
  * [use\_options](#use\options)
  * [new](#new)
  * [command](#command)
  * [command\_args](#command\args)
  * [commands](#commands)
  * [main](#main)
  * [options](#options)
  * [run](#run)
  * [get\_args](#get\args)
    * [With names](#with-names)
    * [With no names](#with-no-names)
  * [init](#init)
* [USING PACKAGE VARIABLES](#using-package-variables)
* [COMMAND LINE OPTIONS](#command-line-options)
  * [Getopt::Long Configuration](#getoptlong-configuration)
* [COMMAND ARGUMENTS](#command-arguments)
  * [set\_args](#set\args)
* [CUSTOM ERROR HANDLER](#custom-error-handler)
* [SETTING DEFAULT VALUES FOR OPTIONS](#setting-default-values-for-options)
* [OPTION PROVIDERS](#option-providers)
  * [Implementing an Option Provider](#implementing-an-option-provider)
  * [Option Resolution and Precedence](#option-resolution-and-precedence)
* [ADDING ADDITIONAL ACCESSORS](#adding-additional-accessors)
* [LOGGING](#logging)
  * [Colored Output](#colored-output)
  * [Per Command Log Levels](#per-command-log-levels)
* [FAQ](#faq)
* [ALIASING OPTIONS AND COMMANDS](#aliasing-options-and-commands)
  * [How option aliases work](#how-option-aliases-work)
  * [How command aliases work](#how-command-aliases-work)
  * [Usage examples](#usage-examples)
  * [Recommendations](#recommendations)
* [ERRORS/EXIT CODES](#errorsexit-codes)
  * [Exit Codes](#exit-codes)
* [LICENSE AND COPYRIGHT](#license-and-copyright)
* [SEE ALSO](#see-also)
* [AUTHOR](#author)
# NAME

CLI::Simple - a minimalist object oriented base class for CLI applications

# SYNOPSIS

    #!/usr/bin/env perl

    package MyScript;

    use strict;
    use warnings;

    use parent qw(CLI::Simple);

    caller or exit __PACKAGE__->main();

    sub main {

      my $cli = MyScript->new(
       option_specs    => [ qw( help format=s file=s) ],
       default_options => { format => 'json' }, # set some defaults
       extra_options   => [ qw( content ) ], # non-option, setter/getter
       commands        => { execute => \&cmd_execute, list => \&cmd_list,  },
       alias           => { options => { fmt => 'format' }, commands => { ls => 'list' } },
      );

      return $cli->run();
    }

    sub cmd_execute {
      my ($self) = @_;

      # retrieve a CLI option   
      my $file = $self->get_file;
      ...
      return 0;
    }

    sub cmd_list { 
      my ($self) = @_;

      # retrieve a command argument
      my ($file) = $self->get_args();
      ...
      return 0;
    }

    1;

\# role-based CLI Application (2.0.0)

\# create a YAML manifest `my-script.yml` in your project root:

    ---
    roles:
      frobnicate: My::Script::Role::Frobnicate
      list:       My::Script::Role::List
    options:
      - help|h
      - verbose|v
      - output|o=s

\# create a main module

    package My::Script;

    use CLI::Simple qw(:roles);
    use parent qw(CLI::Simple);

    our $VERSION = '1.0.0';

    caller or exit __PACKAGE__->main;

    1;

\# create implementation roles

    package My::Script::Role::Frobnicate;

    use Role::Tiny;
    use CLI::Simple::Constants qw(:booleans);

    sub cmd_frobnicate {
      my ($self) = @_;
      ...
      return $SUCCESS;
    }

    1;

# DESCRIPTION

[![CLI-Simple](https://github.com/rlauer6/CLI-Simple/actions/workflows/build.yml/badge.svg)](https://github.com/rlauer6/CLI-Simple/actions/workflows/build.yml)

Tired of writing the same 'ol boilerplate code for command line
scripts? Want a standard, simple way to create a Perl script that
takes options and commands?  `CLI::Simple` makes it easy to create
scripts that take _options_, _commands_ and _arguments_.

`CLI::Simple` is designed around the _modulino_ pattern - Perl
modules that can be executed directly as scripts. See ["MODULINOS"](#modulinos).

For common constant values (like `$TRUE`, `$DASH`, or `$SUCCESS`), see
[CLI::Simple::Constants](https://metacpan.org/pod/CLI%3A%3ASimple%3A%3AConstants), which pairs naturally with this module.

Version 2.0.0 introduces optional role-based architecture for applications
that have outgrown a single module. Declare your commands and options in a
YAML manifest, implement each command in a dedicated [Role::Tiny](https://metacpan.org/pod/Role%3A%3ATiny) role, and
`CLI::Simple` handles composition, dispatch, and lifecycle automatically.
Your main module shrinks to a single line:

    caller or exit __PACKAGE__->main;

Not ready for a full refactor? Start smaller. The built-in `-dump-spec`
command introspects your existing module and writes a YAML manifest that
makes your configuration data-driven without moving a single line of
implementation code. Adopt roles incrementally, one command at a time.

When you are ready to scaffold a full role-based project, `-scaffold`
generates role stubs, a slimmed main module, and inter-module dependencies
from your manifest. Feed the resulting tarball to
[CPAN::Maker::Bootstrapper](https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper) and you have a complete, buildable CPAN
distribution in one step.

Version 2.3.0 adds selective role composition. Commands declared with
the `roles` manifest key compose only the roles required by the selected
command. The original `commands` form remains supported for backward
compatibility and retains its original behavior of composing the complete
set of command roles.

Version 2.4.0 introduces pluggable option providers. CLI applications
frequently obtain option values from multiple sources, including the
command line, environment variables, configuration files, and credential
stores. Traditionally, each application must implement its own logic
for retrieving these values and determining their precedence, often
duplicating much of the same code in its `init()` method.

Option providers move that responsibility into reusable [Role::Tiny](https://metacpan.org/pod/Role%3A%3ATiny)
roles. Applications register the providers they need, in precedence
order, and `CLI::Simple` coordinates resolution of options not supplied
on the command line. This eliminates repetitive initialization logic
while leaving each provider responsible for how and where it obtains
its values.

# VERSION

This documentation refers to version 2.4.0.

# FEATURES

- accept command line arguments ala [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)
- supports commands and command arguments
- automatically add a logger
- global or custom log levels per command
- easily add usage notes
- automatically create setter/getters for your script
- low dependency profile
- selective role composition through YAML command manifests
- built-in scaffolding tools for migrating legacy scripts to roles
- bash completion script generation for modulino wrappers
- optional pager support for help output via [IO::Pager](https://metacpan.org/pod/IO%3A%3APager)
- customizable help sections via `help_sections`
- pluggable option providers with ordered resolution and precedence

# QUICK START

## Single-Module Application

The simplest way to use `CLI::Simple` is to subclass it and define
your commands as methods in the same module:

    package My::Script;

    use strict;
    use warnings;

    use CLI::Simple::Constants qw(:booleans);

    use parent qw(CLI::Simple);

    caller or exit __PACKAGE__->main;

    sub cmd_frobnicate {
      my ($self) = @_;
      my $output = $self->get_output;
      ...
      return $SUCCESS;
    }

    sub main {
      __PACKAGE__->new(
        option_specs => [ qw( help|h verbose|v output|o=s ) ],
        commands     => { frobnicate => \&cmd_frobnicate },
      )->run;
    }

    1;

## Role-Based Application

For larger applications, declare your commands and options in a YAML
manifest and implement each command in a dedicated [Role::Tiny](https://metacpan.org/pod/Role%3A%3ATiny) role.
Your main module becomes a single declaration:

    package My::Script;

    use strict;
    use warnings;

    use CLI::Simple qw(:roles);
    use parent qw(CLI::Simple);

    our $VERSION = '1.0.0';

    caller or exit __PACKAGE__->main;

    1;

**Naming convention:** The YAML manifest filename is derived from your
module name - `My::Script` looks for `my-script.yml` in the
distribution share directory. You must package the spec file with your
distribution.

The manifest maps commands to roles:

    ---
    roles:
      frobnicate: My::Script::Role::Frobnicate
      list:       My::Script::Role::List
    options:
      - help|h
      - verbose|v
      - output|o=s

Each role implements one or more commands:

    package My::Script::Role::Frobnicate;

    use Role::Tiny;
    use CLI::Simple::Constants qw(:booleans);

    sub cmd_frobnicate {
      my ($self) = @_;
      ...
      return $SUCCESS;
    }

    1;

To easily generate the directory structure, role stubs, and build
files for this architecture, `CLI::Simple` provides a built-in
`-scaffold` tool.

See ["-scaffold"](#scaffold) for detailed instructions on generating a role-based
project tarball from a monolithic script or a YAML manifest. For a
comprehensive guide on transitioning your application, see
["ROLE-BASED ARCHITECTURE"](#role-based-architecture).

# MODULINOS

A _modulino_ is a Perl module that can also be run directly as a
script. The term was coined by Brian D. Foy and the pattern is simple:

    caller or exit __PACKAGE__->main();

When the file is `require`d or `use`d by another module, `caller`
returns the calling package and the expression short-circuits -
`main()` is never called. When the file is executed directly by Perl,
`caller` returns false and `main()` runs. The same file serves as
both a reusable module and an executable script.

`CLI::Simple` is designed around this pattern. Every `CLI::Simple`
application is expected to be a modulino. The framework's lifecycle,
internal commands, bash completion, and scaffolding tools all assume
this dual-use design.

## Why Modulinos?

The modulino pattern offers several advantages over a traditional
script:

- **Testable** - your script logic lives in a proper Perl module
that can be `use`d in test files without executing `main()`
- **Reusable** - other scripts and modules can `use` your
modulino and call its methods directly
- **Introspectable** - tools like `-dump-spec` and
`-generate-completion` can load your modulino and inspect its live
state without running it as a script
- **Installable** - modulinos distribute cleanly as CPAN modules
with full man page support via [CPAN::Maker::Bootstrapper](https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper)

## The Bash Wrapper

Perl modulinos are invoked via a thin bash wrapper script that locates
the installed module file and passes all arguments through to Perl:

    #!/usr/bin/env bash
    #-*- mode: sh; -*-

    MODULINO_WRAPPER=my-script
    MODULE_NAME=My::Script
    MODULE_PATH=$(MODULE_PATH="${MODULE_NAME//:://}.pm" \
      perl -M$MODULE_NAME -e 'print $INC{$ENV{MODULE_PATH}};')

    MODULINO_WRAPPER=$MODULINO_WRAPPER perl $MODULE_PATH "$@"

The wrapper locates the installed `.pm` file via `%INC` and sets
`MODULINO_WRAPPER` in the environment so `CLI::Simple` knows the
name of the script the user actually typed. This is used by
`-generate-completion` to name the bash completion function correctly
and by [CPAN::Maker::Bootstrapper](https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper) to create man page symlinks.

## create-modulino

`CLI::Simple` ships with a `create-modulino` tool that generates the
bash wrapper for any `CLI::Simple` modulino:

    # create wrapper using module name convention (My::Script -> my-script)
    create-modulino -m My::Script

    # install to a specific directory
    create-modulino -m My::Script -i /usr/local/bin

    # use a custom wrapper name
    create-modulino -m My::Script -a my-alias -i /usr/local/bin

`create-modulino` is itself a modulino - an example of the pattern it
creates. The bash wrapper template lives in its `__DATA__` section,
keeping the tool entirely self-contained.

If you are building a CPAN distribution, [CPAN::Maker::Bootstrapper](https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper)
integrates `create-modulino` into the `make modulino` target,
generating and installing the wrapper as part of the build process.

## MODULINO\_WRAPPER

The `MODULINO_WRAPPER` environment variable tells `CLI::Simple` the
name of the wrapper script that invoked the modulino. It is set by the
wrapper and used by:

- `-generate-completion` - to name the bash completion function
and `complete` target correctly
- Man page symlinks via [CPAN::Maker::Bootstrapper](https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper) - so
`man my-script` resolves to the module's man page

If `MODULINO_WRAPPER` is not set, `CLI::Simple` infers the script
name from the module name by convention - `My::Script` becomes
`my-script`. Set it explicitly when the wrapper name does not follow
this convention.

# ROLE-BASED ARCHITECTURE

`CLI::Simple` 2.0.0 introduced an optional role-based architecture
for applications that have grown beyond a single module. Commands may
be implemented in dedicated [Role::Tiny](https://metacpan.org/pod/Role%3A%3ATiny) roles and declared in a YAML
manifest, allowing `CLI::Simple` to build the dispatch table and
provide an inherited `main()` - potentially reducing your main module
to a single declaration.

Version 2.3.0 adds selective role composition through the `roles:`
manifest key. When `roles:` is used, only the role or roles required
by the selected command are composed. The original `commands:`
manifest form remains supported for backward compatibility and retains
its original behavior of composing the complete set of command roles.

## The YAML Manifest

By default, `CLI::Simple` locates the application's manifest via
[File::ShareDir](https://metacpan.org/pod/File%3A%3AShareDir) using the distribution name derived from the module
name. The manifest must be installed as part of the distribution.

Additional YAML manifests may be supplied as arguments to
`use CLI::Simple`. These may be explicit filenames or glob patterns,
allowing applications to discover command registrations from
project-local configuration files.

_Note: Version 2.3.0 introduces `roles:` for selective role
composition. The original `commands:` form remains supported for
backward compatibility. See ["roles: vs commands:"](#roles-vs-commands)._

A minimal manifest:

    ---
    roles:
      frobnicate: My::Script::Role::Frobnicate
      list:       My::Script::Role::List
    options:
      - help|h
      - verbose|v
      - output|o=s

A manifest defining commands, options, defaults, and additional
accessors:

    ---
    roles:
      frobnicate: My::Script::Role::Frobnicate
      list:       My::Script::Role::List
    options:
      - help|h
      - verbose|v
      - output|o=s
    default_options:
      verbose: 0
    extra_options:
      - dbh
      - config_data

Manifest section names use underscores, not hyphens. For example,
`default_options` and `extra_options` are valid section names;
`default-options` and `extra-options` are not.

Unknown manifest keys and values that do not match the expected
section types cause an error when the manifest is loaded.

## Loading Multiple Manifests

`CLI::Simple` supports loading multiple YAML manifests during import.
This allows an application to extend its commands, roles, and options
without modifying its primary manifest. Each additional manifest may
contribute command definitions, option specifications, default values,
and additional accessors.

Additional manifests may be specified as filenames:

    use CLI::Simple qw(
      :roles
      extensions/publish.yml
      extensions/deploy.yml
    );

Glob patterns are also supported:

    use CLI::Simple qw(
      :roles
      .roles/*/role.yml
    );

When `:roles` is specified, `CLI::Simple` first attempts to load the
application's installed manifest through [File::ShareDir](https://metacpan.org/pod/File%3A%3AShareDir). Additional
manifests are then loaded in the order supplied.

All manifests contribute `options`, `default_options`, and
`extra_options` to the application's global option namespace. Duplicate
option names (including aliases) and duplicate default keys are errors.
Repeated `extra_options` declarations are harmless, and an accessor may
appear in both `options` and `extra_options`.

The first manifest alone supplies application-wide `alias` and
`abbreviations` metadata. Subsequent manifests also contribute
`roles:` and `commands:` entries.

Command names must be unique across all manifests. An attempt to
register a command more than once causes an error.

An unmatched glob pattern contributes no manifests and does not cause
an error. An explicitly named YAML file that cannot be loaded causes
an error.

Explicit YAML filenames may also be supplied without `:roles`:

    use CLI::Simple qw(
      config/application.yml
      .roles/*/role.yml
    );

In this case, the first explicitly supplied manifest provides the
application-wide configuration.

Loading a manifest does not compose its roles. For commands declared
under `roles:`, only the roles associated with the selected command
are composed during application startup.

See ["roles: vs commands:"](#roles-vs-commands) for the distinction between selective
and legacy role composition.

## Option Initialization

Option specifications and defaults from all manifests are registered
globally, but only the **roles** for the selected command are composed.

Because option specifications and defaults are merged from all
manifests, they are available regardless of which command is selected.
Manifest defaults are equivalent to values supplied through the
`default_options` argument to `new()`.

Applications should use `init()` when option values require
additional initialization or resolution after command-line parsing.

Manifest defaults are applied before `init()`, but after command-line
options have been parsed. Applications may inspect `options()` to
determine which options were explicitly supplied on the command line
and override default values during `init()`.

## Command Values

Entries beneath `roles:` map a command name to either a single role
or a list of roles required by that command.

For example:

    roles:
      frobnicate: My::Script::Role::Frobnicate
      publish:
        - My::Script::Role::Publish
        - My::Script::Role::Packages

When `frobnicate` is selected, only
`My::Script::Role::Frobnicate` is composed into the application.

When `publish` is selected, both `My::Script::Role::Publish` and
`My::Script::Role::Packages` are composed.

The selected role set must provide the command method corresponding to
the command name. Hyphens are converted to underscores when resolving
the method name, so:

    code-review

resolves to:

    cmd_code_review

The original `commands:` form remains supported for backward
compatibility. Its values may be role class names or method names and
retain the pre-2.3.0 behavior described in
["roles: vs commands:"](#roles-vs-commands).

## `roles:` vs `commands:`

Version 2.3.0 introduces `roles:` for selective role composition.
New applications should use `roles:`. The original `commands:`
manifest key remains supported for backward compatibility.

With `commands:`, selecting a command causes all roles referenced
by the loaded manifests' command definitions to be composed into the
application, regardless of which command is being executed.

This makes methods from every composed role available throughout
the application. However, it can also load modules that are not
needed by the selected command, increasing startup time.

For applications invoked repeatedly, such as utilities called from
`make` recipes, this additional startup overhead can become
significant.

With `roles:`, only the roles associated with the selected command
are composed. A command may require one role or several roles.

Selective composition reduces unnecessary dependencies and makes
the role requirements of each command explicit.

## When to Use Each Approach

`CLI::Simple` supports several approaches to organizing command-line
applications. The appropriate choice depends on the size of the
application and how its commands share functionality.

- Single-module application

    For small utilities with a limited number of commands, defining
    command handlers in a single module is often the simplest approach.
    Commands are registered directly through the `commands` constructor
    parameter.

    No YAML manifest or role composition is required.

- Legacy `commands:` manifest

    Existing applications using a YAML manifest with `commands:` retain
    the original behavior of composing all command roles together.

    This approach may be appropriate for applications whose commands
    depend on methods supplied by other command roles. However, every
    role class referenced by the manifest's command definitions is
    composed regardless of which command is selected.

- Selective `roles:` manifest

    For new or growing applications, `roles:` provides a more modular
    approach. Each command declares the roles it requires, and only
    those roles are composed when the command is selected.

    This is particularly useful when commands have different
    dependencies or when minimizing startup time is important.

Applications can migrate from `commands:` to `roles:` incrementally,
provided each migrated command declares the roles it requires.

## Sharing Methods Between Commands

With legacy `commands:` manifests, all command roles are composed
into the application. Methods provided by one command role are
therefore available to other commands.

With selective `roles:` composition, a command cannot assume that
roles associated with other commands have been composed.

Functionality shared by multiple commands can be placed in a
separate role and included in each command's role list:

    roles:
      publish:
        - My::Script::Role::Publish
        - My::Script::Role::Common
      deploy:
        - My::Script::Role::Deploy
        - My::Script::Role::Common

Alternatively, functionality required by every command can be
composed directly into the main application class using
[Role::Tiny::With](https://metacpan.org/pod/Role%3A%3ATiny%3A%3AWith).

Shared functionality can also be implemented in ordinary Perl
modules without using roles.

See ["Roles With No Commands"](#roles-with-no-commands) for an example of composing an
application-wide role.

## Roles With No Commands

Some roles provide application-wide behavior rather than implementing
a command. For example, a role may provide an `init()` method for
startup validation or other functionality required by every command.

Because these roles are not associated with a command beneath
`roles:`, they must be composed explicitly into the main module:

    package My::Script;

    use CLI::Simple qw(:roles);
    use Role::Tiny::With;
    use parent qw(CLI::Simple);

    with 'My::Script::Role::Init';

    caller or exit __PACKAGE__->main;

    1;

Roles composed this way are always available to the application,
regardless of which command is selected.

## Activating Role-Based Architecture

Role-based applications load their YAML manifests through
`use CLI::Simple`.

To load the application's installed manifest, specify `:roles`:

    use CLI::Simple qw(:roles);

`CLI::Simple` locates the manifest through [File::ShareDir](https://metacpan.org/pod/File%3A%3AShareDir)
and retains its command, role, option, alias, and abbreviation
metadata for the application.

Alternatively, specify an explicit YAML manifest:

    use CLI::Simple qw(config/application.yml);

Both forms may be combined with additional YAML manifests or
glob patterns. See ["Loading Multiple Manifests"](#loading-multiple-manifests).

Role composition does not occur while manifests are being loaded.

When the application starts, `CLI::Simple` resolves the selected
command, including aliases and abbreviations, before composing
the required roles.

For commands declared beneath `roles:`, only the associated
role set is composed.

For legacy commands declared beneath `commands:`, the original
all-role composition behavior is retained for backward
compatibility.

## The Inherited main()

When using a YAML manifest, your class can inherit `main()`
from `CLI::Simple`:

    caller or exit __PACKAGE__->main;

The inherited `main()` uses the manifest metadata to resolve the
requested command, composes the role or roles required for that
command, constructs the application object, and calls `run()`.

Aliases and command abbreviations are resolved before selective role
composition, so they select the same role set as the canonical
command.

Override `main()` in your subclass only if you need application
startup behavior that cannot be expressed through the manifest,
`init()`, or explicitly composed application roles.

## Distributing the Manifest

When using `:roles`, the application's primary YAML manifest must
be installed in the distribution's share directory.

`CPAN::Maker` users can add it to `extra-files` in
`buildspec.yml`:

    extra-files:
      - share:
        - my-script.yml

Additional manifests supplied as import arguments are loaded from
the filesystem. They do not need to be installed in the
distribution's share directory.

For example:

    use CLI::Simple qw(
      :roles
      .roles/*/role.yml
    );

This allows applications to maintain additional commands, roles,
and options independently of their primary manifest.

For example, an application may load optional extensions from
`.roles/`. Each extension can provide its own manifest and
implementation without modifying the application's primary
manifest. Extensions are available only when their manifests
are present and loaded.

See ["Loading Multiple Manifests"](#loading-multiple-manifests) for manifest precedence and
merging behavior.

# PHILOSOPHY AND DESIGN PRINCIPLES

Getting started with `CLI::Simple` is intentionally simple.
It provides a structured, convention-based approach to building
command-line applications, including option parsing, command
dispatch, defaults, logging, and help handling, without requiring
developers to adopt its optional role-based framework.

For a single-module application, you register commands directly
using the `commands` constructor parameter. Command handlers
can be implemented as methods or subroutines, allowing you to
organize application logic according to your own conventions.

For applications that need greater modularity, `CLI::Simple` also
provides an optional role-based framework. YAML manifests
declare commands, options, and the roles required to implement
them. The framework manages manifest loading and role composition,
including selective composition of the roles required by a
particular command.

You can use `CLI::Simple` without adopting the role-based framework.

The philosophy is: provide just enough infrastructure, then get out of
your way.

## Validation, Defaults, and Configuration

`CLI::Simple` does not impose a validation model. You may:

- Use `Getopt::Long` option specifications for argument types and
`default_options` to supply default values
- Write your own validation logic in `init()`
- Throw exceptions, emit usage, or exit early at any point

The lifecycle is explicit and under your control. You decide how much structure
you want to add on top of it.

## When to Use

`CLI::Simple` is ideal for:

- Internal tools and admin scripts
- Bootstrapped CLIs where you don't want a framework
- Users who want to subclass a clean, minimal interface
- Applications that have grown beyond a single module and benefit from
role-based command composition

For interactive CLI handling or complex command trees, consider
[App::Cmd](https://metacpan.org/pod/App%3A%3ACmd) or [CLI::Framework](https://metacpan.org/pod/CLI%3A%3AFramework).

## The init-run Lifecycle

- **Phase 0: Manifest Loading**

    For role-based applications, YAML manifests are loaded during
    `import`. The application's installed manifest may be loaded
    through `:roles`, and additional manifests may be supplied as
    filenames or glob patterns.

    The manifests are merged and normalized before their command,
    role, option, alias, and abbreviation metadata is retained
    for the application.

    Roles are not composed during manifest loading.

    The selected command is resolved later, during application startup.
    For commands declared beneath `roles:`, only the role or roles
    required by that command are composed. Legacy `commands:` manifests
    retain the original all-role composition behavior.

    Single-module applications skip this phase entirely.

- **Phase 1: Internal Commands**

    Before anything else, `CLI::Simple` checks `@ARGV` for internal
    commands prefixed with `-`. If one is found it executes immediately
    and exits. See ["INTERNAL COMMANDS"](#internal-commands).

- **Phase 2: Initialization (`new`)**

    The constructor parses command-line arguments using [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong),
    normalizes option names, and creates accessors for the declared options.
    After completing command and logger initialization, `CLI::Simple` resolves
    any remaining options through registered option providers, applies
    application defaults, and invokes the application's `init()` method,
    if defined.

    The order of initialization is significant. Command-line values take
    precedence over provider-supplied values, providers are consulted in
    registration order, and defaults are applied only to options that remain
    unresolved. By the time `init()` is called, all available option values
    have been assigned to their respective accessors.

    The `init()` method remains available for application-specific
    initialization, but applications no longer need to implement their own
    option-source resolution and precedence logic when using option
    providers. See ["OPTION PROVIDERS"](#option-providers) for details.

    - Validating command-line arguments.
    - Loading configuration files based on a `--config` option.
    - Dynamically overriding the command (e.g., `$self->command('new_default')`).
    - Overriding default options
    - Performing any setup required **before** a command is run.

- **Phase 3: Execution (`run`)**

    Dispatches to the command method determined during initialization.

## Opt-in Default Command

By design, `CLI::Simple` **does not impose a default command**.
This provides total flexibility for the application author:

- **You Can Set a Default:** If your application needs a default
command, define a `default` entry in the `commands` hash passed to
the constructor, or set the command during `init()` using `command()`.
Alternatively, enable `$AUTO_HELP` to display help when no command
is supplied.
- **You Can Have No Default:** If you do **not** set a default,
`run()` will simply do nothing and return cleanly if no command
is provided on the command line.

This "no default by default" behavior is what enables a powerful 
"setup-only" execution mode. A user can run your script _without_
specifying a command. This will:

- 1. Run the entire `new()` / `init()` phase, performing all setup.
- 2. Call `run()`, which will find no command and exit cleanly.

This provides an ideal hook for applications that need to perform
"on-demand initialization" (e.g., seeding a database, authenticating)
by checking for a specific flag inside `init()`, without also
triggering an unwanted command.

In applications using a YAML manifest, a default command can be
declared using `commands:`. For applications using selective
`roles:` composition, the default command can be associated with
a role directly:

    roles:
      default: My::Module::Role::Installer

## `$AUTO_HELP` and `$AUTO_DEFAULT`

The following package variables control automatic command selection,
help behavior, and output paging.

By default, the `CLI::Simple` provides no default command as explained in
the sections above. Some scripters may want default behaviors that
assume a command or provide usage if no command is provided.

- `$AUTO_HELP`

    Set the package variable `$AUTO_HELP` to a true value if you want
    `CLI::Simple` to provide help when no command is provided.

    default: false

- `$AUTO_DEFAULT`

    Set the package variable `$AUTO_DEFAULT` to a true value if you want
    `CLI::Simple` to automatically select a command when exactly one
    command is registered and no command is provided on the command line.

    default: false

- `$PAGER`

    Set the package variable `$PAGER` to a true value to route help
    output through [IO::Pager](https://metacpan.org/pod/IO%3A%3APager) when `--help` is invoked. When enabled,
    `IO::Pager` selects an appropriate pager (`less`, `more`, etc.)
    based on the `PAGER` environment variable, falling back to a sensible
    default. Set to false to suppress pager use and write help directly to
    STDOUT.

        use CLI::Simple qw($PAGER);
        $PAGER = 0;  # disable pager

    default: true

    Note: [IO::Pager](https://metacpan.org/pod/IO%3A%3APager) must be installed for pager support. If it is not
    available, help output is written directly to STDOUT regardless of the
    value of `$PAGER`.

# CONSTANTS

`CLI::Simple::Constants` provides a collection of exportable constants
commonly used in command-line applications.

These include:

- Boolean flags like `$TRUE`, `$FALSE`, `$SUCCESS`, and `$FAILURE`
- Common character tokens such as `$COLON`, `$DASH`, `$EQUALS_SIGN`, etc.
- Log level names compatible with [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl)

To use them in your script:

    use CLI::Simple::Constants qw(:all);

# ADDING USAGE TO YOUR SCRIPTS

To provide built-in usage/help output, include a `=head1 SYNOPSIS`
or `=head1 USAGE` section in your script's POD:

    =head1 SYNOPSIS

    ```
    usage: myscript [options] command args

    Options
    -------
    --help, -h      Display help
    ...
    ```

If the user supplies the command `help`, or the `--help` option,
`CLI::Simple` displays the configured help sections using
[Pod::Usage](https://metacpan.org/pod/Pod%3A%3AUsage).

For backward compatibility, `USAGE` is also supported. If a `USAGE`
section is present, it is used as the usage section.

If no `USAGE` section is present, `SYNOPSIS` is used instead.

When both `SYNOPSIS` and `USAGE` are present, `USAGE` is used by
default. Applications that explicitly configure `help_sections` may
select the desired section.

## Customizing Help Output

### Custom help() Method

If you need full control over the help output, you can define a custom
`help` method and assign it as a command:

    commands => {
      help => &help,
      ...
    };

This is useful if your module follows the modulino pattern and you want
to present help information that differs from the embedded POD.

### `help_sections`

By default, `CLI::Simple` renders the following POD sections when
present:

    USAGE (or SYNOPSIS if USAGE is absent)
    DESCRIPTION/Commands
    DESCRIPTION/Options
    OPTIONS

You can override the default selection by passing an array reference of
section names during construction:

    my $cli = CLI::Simple->new(
      help_sections => [qw(SYNOPSIS COMMANDS OPTIONS)],
      ...
    );

When `help_sections` differs from the default selection,
`CLI::Simple` honors the list exactly as provided.

    help_sections => [qw(SYNOPSIS USAGE)]

Section names follow [Pod::Usage](https://metacpan.org/pod/Pod%3A%3AUsage) conventions. Subsections are
specified with a `/` separator; for example,
`DESCRIPTION/Commands` renders only the `Commands` subsection under
`DESCRIPTION`.

# INTERNAL COMMANDS

`CLI::Simple` reserves command names beginning with `-` for its own
use. These commands are intercepted before option parsing begins and
execute immediately, bypassing the normal lifecycle entirely. See
["The init-run Lifecycle"](#the-init-run-lifecycle).

## -generate-completion

Generates a bash completion script for the script's commands and
options, derived from the live object state. Bash completions are a
feature that allows the shell to automatically finish commands, file
paths, and options when you press the Tab key.

    my-script -generate-completion > \
      ~/.local/share/bash-completion/completions/my-script

After generating the bash completion script, source it in your current
shell to test:

    source ~/.local/share/bash-completion/completions/my-script

Test by typing your script name followed by a space and pressing Tab.
You should see the available commands. To verify option completion,
type your script name followed by a space and `--` and press Tab.

To make completions permanent, most systems automatically source files
placed in `~/.local/share/bash-completion/completions/` when
`bash-completion` 2.x is installed. If your system does not pick
them up automatically, add the following to your `~/.bashrc`:

    source ~/.local/share/bash-completion/completions/my-script

Alternatively, place the generated file in the system-wide completion
directory (requires root):

    my-script -generate-completion > \
      /etc/bash_completion.d/my-script

The script name is taken from `MODULINO_WRAPPER` when set,
otherwise it is inferred from the module name.

_Note: If you created the modulino with the supplied
`create-modulino` tool `MODULINO_WRAPPER` is already set inside the
bash script that invokes the modulino._

- Case 1: Your modulino wrapper and module name are aligned 

    The modulino script `my-modulino` refers to My::Modulino

        my-modulino -generate-completion

- Case 2: Your modulino wrapper was created using `create-modulino`

    The modulino script `my-alias` refers to My::Modulino. Although the
    wrapper name differs from the module name, `MODULINO_WRAPPER` is set
    by the generated bash wrapper.

        my-alias -generate-completion

## -dump-spec

Introspects the running modulino and writes a YAML manifest to the
current directory. The filename is derived from the module name by
convention.

    my-script -dump-spec           # sub names - baby step toward roles
    my-script -dump-spec roles     # role class names - full commitment

Without the `roles` argument, commands map to their existing sub
names so the manifest can be used immediately without moving any
code. With `roles`, commands map to derived role class names suitable
for use with `-scaffold`.

Alias commands - those whose coderef resolves to a sub name that does
not match the command key - are always written as sub names regardless
of mode.

## -scaffold

Generates a role-based project tarball from the running modulino or
from an explicit spec file.

The `-scaffold` command can take a monolithic application or a YAML
file like the one above and create the project hierarchy for a role
based application. The command will create a tarball that contains
role stubs, a slimmed main module with extracted POD (if your monolith
contained any), a `project.mk` with inter-module dependencies, and
the YAML manifest.

If you've turned your monolith's package into a modulino:

    my-script -scaffold                        # introspect live module

...or use `cli-simple` if you have a .yml file.

    cli-simple -scaffold my-script.yml         # scaffold from spec file

The generated tarball is named from the distribution identifier
derived from the application class or supplied specification file,
with a `-roles.tar.gz` suffix. The name is used to infer the class
name. If your filename is different than the classes you want to
scaffold, you will need to edit the files.

Extract the content to a directory and start editing. If you feed the tarball
to [CPAN::Maker::Bootstrapper](https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper) via the `import-scaffold` command you can
produce a complete buildable CPAN distribution.

## -migrate

Combines `-dump-spec roles` and `-scaffold` in a single step.

    my-script -migrate

Writes the YAML manifest then generates the role-based tarball. Use
this when you are ready for a full migration and do not need to inspect
or edit the manifest first. If you want to review or adjust the
manifest before scaffolding, run `-dump-spec` and `-scaffold`
separately.

# METHODS AND SUBROUTINES

## use\_log4perl

    __PACKAGE__->use_log4perl(
      log_level => 'info',
      color     => 1,
    );

Enables [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) integration for the application class.
`CLI::Simple` initializes logging during object construction, before
invoking the application's `init()` method.

See ["LOGGING"](#logging) for configuration and usage details.

## use\_options

    __PACKAGE__->use_options(
      provider_name => {
        'Provider::Role' => [qw(option1 option2)],
      },
    );

Registers one or more option providers with the application class.
Each provider is identified by a name and implemented as a
[Role::Tiny](https://metacpan.org/pod/Role%3A%3ATiny) role, which `CLI::Simple` composes into the application
class.

Providers are registered in the order supplied. This order determines
their precedence when multiple providers can resolve the same option.

The array reference specifies which application options the provider
may resolve. An empty array reference allows the provider to resolve
any eligible application option declared through `option_specs` or
`extra_options`.

The provider must implement a resolver method named
`_provider_name_resolve()` and may optionally implement
`_provider_name_init()`.

Returns the application class.

See ["OPTION PROVIDERS"](#option-providers) for the complete provider contract,
examples, and resolution rules.

## new

    new( args )

Instantiates a new `CLI::Simple` instance, parses command-line options,
creates the corresponding accessors, and optionally initializes logging.
Registered option providers are then consulted, application defaults
are applied, and the application's `init()` method is invoked, if
defined.

See ["OPTION PROVIDERS"](#option-providers) for details on option resolution and
precedence.

_Note: The `new()` constructor uses [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)'s `GetOptions`,
which directly modifies `@ARGV` by removing any recognized
options. The remaining elements of `@ARGV` are treated as the command
name and its arguments._

`args` is a hash or hash reference containing the following keys:

- abbreviations

    A boolean that determines whether abbreviated command names are allowed.

    When true, `validate_command()` treats the provided command as a
    prefix and compares it to the keys in the command hash.

    This allows for convenient shorthand like:

        mytool disable-sched    # expands to 'disable-scheduled-task'

    default: false

- commands (required)

    A hash mapping command names to either a subroutine reference or an
    array reference.

    If an array reference is used, the first element must be a subroutine
    reference and the second should be a valid log level. (See
    ["Per Command Log Levels"](#per-command-log-levels).)

    Example:

        {
          send          => \&send_message,
          receive       => \&receive_message,
          list_messages => [ \&list_messages, 'error' ],
        }

    If your script does not use command names, you may set a `default` key
    to the subroutine or method to run:

        { default => \&main }

    If no default is provided, the behavior is controlled by the
    `$AUTO_DEFAULT` and `$AUTO_HELP` package variables.

    Setting `$AUTO_DEFAULT` to true when your `commands` hash
    contains only a single command, will cause that command to be run
    automatically when no command name is given on the command line. This
    allows you to treat the program like a single-command tool, where
    arguments can be passed directly without explicitly naming the
    command.

- default\_options (optional)

    A hash reference providing default values for options. These values
    are applied only when the corresponding option has not been resolved
    by the command line or a registered option provider.

- extra\_options (optional)

    An array reference of names for additional accessors you want to create,
    even if they are not part of `option_specs`.

    Example:

        extra_options => [ qw(foo bar baz) ]

- option\_specs (optional)

    An array reference of option specifications, as accepted by
    [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong). These define the command-line options your program
    recognizes.

- validate\_command

    By default, `CLI::Simple` validates the selected command against the
    registered commands. Set `validate_command` to a false value to
    disable this validation.

    Typically you might use this to allow a script to assume a default
    command and allow arguments. For example suppose you have a script
    `foo` with a command "get" with arguments:

        foo get something

    ...but want to allow users to also do:

        foo something

    To do this you should follow this recipe:

        sub init {
          my ($self) = @_;
        
          my $command = $self->command;
        
          if ( !exists $self->commands->{$command} ) {
            $self->command_args($command, $self->get_args);
            $self->command('get');
          }
        
          return;
        }

## command

    command
    command(command)

Gets or sets the command to execute. Usually this is the first argument
on the command line after all options have been parsed. There are
times when you might want to override the argument. You can pass a new
command that will be executed when you call the `run()` method.

## command\_args

    my $args = $self->command_args();

Gets or sets the argument list. Similar to `get_args` when no
arguments are passed except it returns an array reference.

To replace the argument list, pass an array reference or a list.

    my $args = $self->command_args;
    $self->command_args(@{$args}, 'foo');

## commands

    commands
    commands(command, handler)

Returns the command dispatch hash supplied to the constructor.
When called with a command name and handler, adds the command
to the dispatch hash. `handler` must be a code reference.

    commands(foo => sub { return 'foo' });

## main

    __PACKAGE__->main;

For role-based applications, `main` is inherited from `CLI::Simple`
and uses the manifest configuration assembled during `import`.
It constructs the application with its options, defaults, and
registered commands, then calls `run()`.

In a role-based modulino, the entire `main` sub reduces to:

    caller or exit __PACKAGE__->main;

For single-module applications, override `main` in your subclass as
usual.

## options

Returns a hash reference containing the command-line options parsed
by `Getopt::Long`. Option names are normalized to snake\_case.

The hash contains only options explicitly supplied on the command
line. It does not include values supplied by `default_options` or
subsequently initialized by `init()`.

Applications can use this hash to distinguish command-line options
from default values when resolving configuration.

## run

Executes the selected command using the parsed options and arguments.
The `run` method dispatches control to the corresponding command
subroutine.

Command subroutines should return `0` for success and a non-zero
value for failure. `run()` returns the command subroutine's return
value, which can be used as the script's exit status.

## get\_args

Return the arguments that follow the command.

    get_args(NAME, ... )     # with names
    get_args()               # raw positional args

### With names

- In scalar context, returns a hash reference mapping each NAME to
the corresponding positional argument.
- In list context, returns a flat list of `(name =` value)> pairs.

Example:

    sub send_message {
      my ($self) = @_;

      my %args = $self->get_args(qw(message email));

      _send_message($args{message}, $args{email});
    }

When you call `get_args` with a list of names, values are assigned in
order: the first name gets the first argument, the second name gets the
second argument, and so on. If you only want specific positions, you may
use `undef` as a placeholder:

    my %args = $self->get_args('message', undef, 'cc');  # skip argument 2

If there are fewer positional arguments than names, the remaining names
are set to `undef`. Extra positional arguments (beyond the provided
names) are ignored.

### With no names

- In scalar context returns an array reference containing the
command's positional arguments.
- In list context returns a list containing the command's
positional arguments.

## init

If defined, `init()` is invoked during application initialization,
after command-line options and arguments have been processed and
before command dispatch. Use this method to perform application-specific
initialization and validation.

The `init()` method is invoked after command-line options have been
parsed, registered option providers have resolved any remaining options,
and application defaults have been applied. Consequently, all resolved
option values are available through their corresponding accessors when
`init()` executes.

Applications may use `init()` to perform additional initialization,
including validation of resolved values, establishing connections, or
preparing resources needed by command handlers.

See ["OPTION PROVIDERS"](#option-providers) for details on option resolution and
precedence.

# USING PACKAGE VARIABLES

The `default_options`, `extra_options`, `option_specs`, and
`commands` constructor arguments may also be defined using package
variables. This provides a declarative alternative to passing these
configuration values directly to `new()`.

The corresponding package variables are `$DEFAULT_OPTIONS`,
`$EXTRA_OPTIONS`, `$OPTION_SPECS`, and `$COMMANDS`.

    our $OPTION_SPECS = [
      qw(
        help|h
        log-level=s|L
        debug|d
      )
    ];

    our $COMMANDS = {
      foo => \&foo,
      bar => \&bar,
    };

# COMMAND LINE OPTIONS

Command-line options are defined using [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)-style
specifications. You pass these into the constructor via the
`option_specs` parameter:

    my $cli = CLI::Simple->new(
      option_specs => [ qw( help|h foo-bar=s log-level=s ) ]
    );

Option values are accessible through automatically generated getter
methods:

    $cli->get_foo_bar();
    $cli->get_log_level();

Option names that contain dashes (`-`) are automatically converted to
snake\_case for the accessor methods. For example:

    option_specs => [ 'foo-bar=s' ]

...results in:

    $cli->get_foo_bar();

## Getopt::Long Configuration

`CLI::Simple` uses [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) to parse command-line options,
with the `no_ignore_case` configuration enabled.

Consequently:

- Option names are case-sensitive.
- Automatic option abbreviation is enabled. An option name
may be abbreviated to any unambiguous prefix.
- Multiple option names may be declared using Getopt::Long's
`|` syntax, such as `config|c=s`.
- When multiple spellings of the same option are supplied,
the last occurrence determines its value.

All other Getopt::Long configuration settings retain their defaults.

# COMMAND ARGUMENTS

If your commands accept positional arguments, you can retrieve them
using the `get_args` method.

You may optionally provide a list of argument names, in which case the
arguments will be returned as a hash (or hashref in scalar context)
with named values.

Example:

    sub send_message {
      my ($self) = @_;

      my %args = $self->get_args(qw(phone_number message));

      send_sms_message($args{phone_number}, $args{message});
    }

If you call `get_args()` without any argument names, it simply
returns all remaining arguments as a list:

    my ($phone_number, $message) = $self->get_args;

_Note: When called with names, `get_args` returns a hash in list
context and a hash reference in scalar context._

## set\_args

Replaces the positional argument list with the supplied array
reference.

    $self->set_args([qw(foo 1)]);

This method overrides the positional arguments originally passed to
the script. You can also modify individual arguments by retrieving
the existing array reference using `get_args()` in scalar context:

    my $args = $self->get_args;
    $args->[1] = '2';

This avoids replacing the entire argument list.

# CUSTOM ERROR HANDLER

By default, `CLI::Simple` exits if `Getopt::Long::GetOptions`
returns a false value, indicating an error while parsing options.

- Set `$CLI::Simple::GETOPT_EXIT_ON_ERROR` to a false value.

    This disables automatic exiting and lets your program decide what to do
    after an option-parsing failure.

- Provide an `error_handler` callback in the constructor.

        my $cli = CLI::Simple->new(
          commands        => \%commands,
          default_options => \%default_options,
          extra_options   => \@extra_options,
          option_specs    => \@option_specs,
          abbreviations   => $TRUE,
          error_handler   => sub {
            my ($msg) = @_;
            print {*STDERR} $msg;
            return $TRUE;   # continue processing
          },
        );

    The error handler is called with the error message from `GetOptions`.
    It must return a boolean: a true value allows processing to continue,
    while a false value causes `CLI::Simple` to exit immediately.

When an `error_handler` callback is supplied, its return value
determines whether processing continues, regardless of the value
of `$CLI::Simple::GETOPT_EXIT_ON_ERROR`. Without a callback, the
global variable controls whether an option-parsing failure causes
an immediate exit.

# SETTING DEFAULT VALUES FOR OPTIONS

To assign default values to your options, pass a hash reference as the
`default_options` argument to the constructor. These values will be
used unless explicitly overridden by the user on the command line.

Example:

    my $cli = CLI::Simple->new(
      default_options => { foo => 'bar' },
      option_specs    => [ qw(foo=s bar=s) ],
      commands        => {
        foo => \&foo,
        bar => \&bar,
      },
    );

Defaulted options are accessible through their corresponding getter
methods, just like options set via the command line.

Default values are applied after command-line arguments have been parsed
and registered option providers have been consulted. A default is used
only when the corresponding option remains unresolved. Consequently,
values supplied by option providers take precedence over application
defaults, just as command-line values take precedence over provider
values.

See ["OPTION PROVIDERS"](#option-providers) for details on option resolution and
precedence.

# OPTION PROVIDERS

`CLI::Simple` supports pluggable option providers that resolve application
options from sources other than the command line. Providers are implemented
as [Role::Tiny](https://metacpan.org/pod/Role%3A%3ATiny) roles and registered using the `use_options()` class
method.

Option providers separate the source of an option's value from its
use within the application. Regardless of whether an option was supplied
on the command line, retrieved from a configuration file, or resolved
by another provider, application code accesses it through the same
`get_` and `set_` accessors.

This makes the accessors the application's consistent interface to
option values, eliminating the need for application code to know
where those values originated or how precedence was established.

An application can register one or more providers:

    __PACKAGE__->use_options(
      environment => {
        'CLI::Simple::Role::Environment' => [],
      },
      config => {
        'MyApp::Role::Config' => [qw(host port database)],
      },
      secrets_manager => {
        'CLI::Simple::Role::SecretsManager' => [qw(database_password api_key)],
      },
    );

Each registration consists of a provider name, a role implementing the
provider, and an array reference identifying the application options
the provider may resolve.

Providers are consulted in registration order. When multiple providers
declare the same option, the first provider to successfully resolve it
takes precedence. Subsequent providers are asked to resolve only those
options that remain unresolved.

An empty option list indicates that the provider may resolve any
unresolved application option declared through `option_specs` or
`extra_options`.

The provider name determines the methods `CLI::Simple` invokes. For
example, a provider registered as `config` implements
`_config_resolve()` and may optionally implement `_config_init()`.

## Implementing an Option Provider

An option provider is a [Role::Tiny](https://metacpan.org/pod/Role%3A%3ATiny) role that implements a resolver
method named ` _foo_config_resolve() `, where _name_ is the name used
when registering the provider.

For example, the following provider resolves options from a Perl hash:

    package Foo::Config;

    use strict;
    use warnings;

    use Role::Tiny;

    our %FOO_CONFIG = (
      foo => 'bar',
    );

    sub _foo_config_resolve {
      my ( $self, @names ) = @_;

      my %values;

      foreach my $name (@names) {
        next if !exists $FOO_CONFIG{$name};

        $values{$name} = $FOO_CONFIG{$name};
      }

      return \%values;
    }

    1;

The application registers the provider using `use_options()`:

    package Foo;

    use parent qw(CLI::Simple);

    __PACKAGE__->use_options(
      foo_config => {
        'Foo::Config' => [qw(foo)],
      },
    );

    # In the application's main() method:
    my $cli = __PACKAGE__->new(
      option_specs => ['foo|f=s'],
    );

Once registered, `CLI::Simple` composes the role into the application class
and invokes `_foo_config_resolve()` when `foo` has not been supplied on
the command line. The resolved value is available through the normal
`get_foo()` accessor.

The resolver receives the names of the application options that remain
unresolved and returns a hash reference containing the values it can
supply. The returned keys must be the application option names, regardless
of how the values are represented in the underlying source.

For example, a provider might resolve the application option `foo`
from an environment variable or configuration entry named `FOO_TASTIC`.
Any such translation is the responsibility of the provider.

An option is considered resolved when its name exists as a key in the
returned hash reference. Values of `undef`, `0`, and the empty string
are valid resolved values. Options omitted from the returned hash
reference remain unresolved and may be supplied by subsequent providers
or application defaults.

A provider may also implement an optional initialization method named
` __name__init() `. `CLI::Simple` invokes this method before the
provider's resolver, but only when the provider has eligible unresolved
options to resolve. This allows providers to defer expensive operations,
such as establishing database connections or initializing AWS clients,
until they are actually needed.

## Option Resolution and Precedence

CLI::Simple resolves option values during object construction, before
invoking the application's `init()` method.

Options are resolved in the following order:

- 1. Command-line arguments

    Values supplied on the command line take precedence over all providers.
    Options already supplied on the command line are not passed to providers.

- 2. Registered option providers

    Providers are consulted in registration order. Each provider receives
    only the eligible option names that remain unresolved.

    A provider resolves an option by including its name in the hash reference
    returned by its resolver. Options omitted from that hash reference remain
    eligible for subsequent providers.

    When a provider has no eligible unresolved options, neither its optional
    initializer nor its resolver is invoked.

- 3. Application defaults

    Any remaining unresolved options may be initialized from the application's
    `default_options`.

After resolution and default initialization are complete, `CLI::Simple`
invokes the application's `init()` method, if defined.

Consequently, application initialization and command handlers can access
resolved option values through their normal accessors without needing
to know which source supplied them.

# ADDING ADDITIONAL ACCESSORS

All command-line options are automatically available through getter
methods named `get_*`.

If you need to create additional accessors (getters and setters) for
values that are not derived from the command line, use the
`extra_options` parameter.

This is useful for passing runtime configuration or computed values
throughout your application.

Example:

    my $cli = CLI::Simple->new(
      default_options => { foo => 'bar' },
      option_specs    => [ qw(foo=s bar=s) ],
      extra_options   => [ qw(biz buz baz) ],
      commands        => {
        foo => \&foo,
        bar => \&bar,
      },
    );

This will generate `get_biz`, `set_biz`, `get_buz`, etc., for
internal use.

Unlike `option_specs`, `extra_options` does not register
command-line options. It only creates accessors for values that
can be initialized or modified programmatically.

# LOGGING

`CLI::Simple` integrates with [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) to provide structured
logging for your scripts.

`CLI::Simple` provides convenient initialization of [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl)
through `use_log4perl()`.

    __PACKAGE__->use_log4perl(
      level  => 'info',
      config => $log4perl_config_string
    );

If you do not explicitly include a `log-level` option in your
`option_specs`, `CLI::Simple` will automatically add one for you.

Once enabled, you can access the logger instance via:

    my $logger = $self->get_logger;

This logger supports the standard Log4perl methods like `info`,
`debug`, `warn`, etc.

_Note: Because it is opt-in, `CLI::Simple` does not itself depend on
[Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl). **If your application calls `use_log4perl`, it owns that
dependency** and must declare it in its own `requires`/`cpanfile`. Static
dependency scanners cannot see it -- the module is loaded dynamically
inside the method call -- so you must add it by hand._

## Colored Output

Pass `color => 1` to `use_log4perl()` to default your script to
colorized log output using a built-in appender, instead of supplying
your own `config`:

    __PACKAGE__->use_log4perl(
      level => 'info',
      color => 1,
    );

Colorizing requires [Term::ANSIColor](https://metacpan.org/pod/Term%3A%3AANSIColor). If it isn't installed,
`CLI::Simple` quietly falls back to uncolored output rather than
failing - `color => 1` is a request, not a hard dependency.

If you'd like the person running your script to be able to override
that default from the command line, add `color!` to your
`option_specs`:

    my @option_specs = qw(
      color!
      ...
    );

This gives you `--color` and `--no-color` for free.  When `color!`
is declared, `--color` and `--no-color` override the default color
setting. These switches control `CLI::Simple`'s built-in colorized
configuration; they do not add coloring to a custom Log4perl
configuration. Declaring `color!` is therefore safe to add at any
time - it only changes behavior for scripts whose users actually pass
the flag.

_Note: `color` and `config` are mutually exclusive -
`use_log4perl()` dies if you pass both. `color` is specifically for
using `CLI::Simple`'s own built-in colorized appender; if you need a
custom config, write it to include coloring yourself rather than
passing `color => 1`._

## Per Command Log Levels

Some commands may require more verbose logging than others. For
example, certain commands might perform complex actions that benefit
from detailed logs, while others are designed solely to produce clean,
structured output.

To assign a custom log level to a command, use an array reference as
the value for that command in the commands hash passed to the
constructor.

The first two elements of the array reference are:

- A code reference to the command subroutine
- A log level string: one of 'trace', 'debug', 'info', 'warn',
'error', or 'fatal'

Example:

    CLI::Simple->new(
      option_specs    => [qw( help format=s )],
      default_options => { format => 'json' },  # set some defaults
      extra_options   => [qw( content )],       # non-option, setter/getter
      commands        => {
        execute => \&execute,
        list    => [ \&list, 'error' ],
      }
    )->run;

Log levels are resolved in the following order of precedence:

- 1. An explicit `--log-level` command-line option
- 2. The log level associated with the selected command
- 3. The application default supplied to `use_log4perl()`

The effective level is available through `get_log_level()`.

_TIP: add other elements to the array for your command to process._

_Note: Per-command log levels are not currently supported in the YAML
manifest. Define them programmatically by overriding `main()` if needed._

# FAQ

- How do I execute startup code before my command runs?

    Implement an `init()` method in your class. The `new()` constructor
    will invoke this method before returning and before `run()` is
    executed.

    Your `init()` method will have access to all options and
    arguments. Logging will also be initialized, so you can use
    `get_logger()` to emit messages.

- Do I need to implement commands?

    You do not need to define multiple named commands. For an application
    that performs a single operation, register a default command:

        commands => { default => \&main }

    If no command is selected and no default command is registered,
    `run()` returns successfully without invoking a command handler.

    The application's `init()` method still executes during construction.

- Must I subclass `CLI::Simple`?

    No. You can instantiate `CLI::Simple` directly and supply the
    `commands` and other configuration through the constructor.
    Subclassing is useful when you want to provide application-specific
    methods such as `init()`.

- How do I turn my class into a script?

    Use the modulino pattern: create a class that checks whether it is
    being invoked directly:

        package MyScript;

        caller or exit __PACKAGE__->main();

        sub main {
          ...
        }

    This lets the file be used as both a module and an executable script.

- How do I migrate an existing script to role-based architecture?

    Run the built-in `-dump-spec` command to generate a YAML manifest from
    your existing script, then `-scaffold` to generate role stubs:

        my-script -dump-spec        # generates my-script.yml
        my-script -scaffold         # generates my-script-roles.tar.gz

    See ["ROLE-BASED ARCHITECTURE"](#role-based-architecture) for the full migration workflow.

- How do I start a new role-based project from scratch?

    Write a YAML manifest and use the `cli-simple` wrapper to scaffold it:

        cli-simple -scaffold my-script.yml

    See ["ROLE-BASED ARCHITECTURE"](#role-based-architecture) for the manifest format.

- How do I enable bash completion for my script?

    Run the built-in `-generate-completion` command. The script name is
    taken from `MODULINO_WRAPPER` when set, or derived from the module
    name otherwise.

        my-script -generate-completion > \
          ~/.local/share/bash-completion/completions/my-script

    Wrappers generated by [CPAN::Maker::Bootstrapper](https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper) set
    `MODULINO_WRAPPER` automatically.

- My application dies with "use\_log4perl() requires Log::Log4perl..."

    Since not all scripts require logging, `Log::Log4perl` is an
    _optional dependency_ of `CLI::Simple`.  If your application calls
    `use_log4perl()`, `Log::Log4perl` must be installed.

# ALIASING OPTIONS AND COMMANDS

`CLI::Simple` lets you define short, human-friendly aliases for both
option names and command names. Use the `alias` parameter to `new():`

    my $app = CLI::Simple->new(
      option_specs    => [ qw(config=s verbose!) ],
      commands        => { list => \&list, execute => \&execute },
      alias => {
        options  => { cfg => 'config', v => 'verbose' },
        commands => { ls  => 'list'   }
      },
    );

## How option aliases work

- Spec tail is copied automatically

    You only name the canonical option in `option_specs`. For each alias,
    `CLI::Simple` finds the canonical option's spec tail (for example
    `=s`, `:i`, `!`, `+`) and appends it to the alias. In the example
    above, `cfg` behaves as if you had written `cfg=s`, and `v` behaves
    as if you had written `v!`.

- Accessors are created for both names

    Accessors are generated from all option names (canonical and aliases),
    with '-' normalized to '\_'. In the example, both `get_config()` and
    `get_cfg()` are available.

- Values are mirrored after parsing

    After option parsing and normalization, values are mirrored so either
    name can be used consistently.

    When both the canonical option and an alias are supplied the canonical
    name wins.

- No duplicate injection

    If the alias already exists in `option_specs`, it will not be injected
    again; value mirroring still occurs.

- Errors are explicit

    If an alias points at a canonical option that does not exist,
    `CLI::Simple` croaks with a clear error.

- Case sensitivity

    `Getopt::Long` is used with `:config no_ignore_case`, so option names
    (and therefore aliases) are case sensitive by default.

## How command aliases work

- Simple mapping

    Provide `alias =` { commands => { alias => canonical } }> to map an alias
    to an existing command. In the example, `ls` dispatches to the `list`
    command.

- Applied before abbreviations

    Aliases are installed before command abbreviation resolution. If you
    enable abbreviations, they apply to the full set of command names,
    including any aliases.

- Errors are explicit

    If an alias points at a command that does not exist, `CLI::Simple` croaks
    with a clear error.

## Usage examples

    # Using an option alias
    script.pl --cfg app.json execute

    # Using a command alias
    script.pl ls

After parsing, both `get_config()` and `get_cfg()` will return the
same value. If the user passes both `--config` and `--cfg`, the value
from `--config` (the canonical version) is used.

_Note: Applications using YAML manifests may define command aliases
through the `alias:` section, just as applications using the
`alias` constructor parameter do. Aliases resolve to their canonical
commands before role composition. See ["ROLE-BASED ARCHITECTURE"](#role-based-architecture)._

## Recommendations

- Keep the canonical spec single-named

    Define a single canonical name in `option_specs` and add other spellings
    via `alias`. Avoid multi-name specs like `config|cfg=s`; use `alias`
    instead.

- Document your precedence

    If you prefer the alias name to win when both are supplied, enforce
    that in your application or adjust the mirroring order. By default, the
    canonical name wins.

# ERRORS/EXIT CODES

The `run()` method dispatches the selected command and returns its
exit status. Command handlers should return `0` for success or a
non-zero value to indicate failure.

    exit CLI::Simple->new(commands => { foo => \&cmd_foo })->run();

## Exit Codes

`CLI::Simple` provides conventional success and failure exit codes
for its own operations. Applications may return additional exit
codes from their command handlers.

- '0'

    Successful completion of a command (`SUCCESS`).

- '1'

    General usage error, `--help` display via `pod2usage`, an
    invalid command line (`FAILURE`) or option parsing errors.

- Any other code

    A command handler may return an application-specific numeric exit
    code, which `run()` passes through to the caller. A handler that
    calls `exit()` terminates the process directly.

Some errors, including unknown commands, raise exceptions rather
than returning an exit code. Unless caught by the application,
these exceptions terminate the process with a non-zero status.

# LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See
[https://dev.perl.org/licenses/](https://dev.perl.org/licenses/) for more information.

# SEE ALSO

[Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong), [CLI::Simple::Constants](https://metacpan.org/pod/CLI%3A%3ASimple%3A%3AConstants), [CLI::Simple::Utils](https://metacpan.org/pod/CLI%3A%3ASimple%3A%3AUtils),
[Pod::Usage](https://metacpan.org/pod/Pod%3A%3AUsage), [App::Cmd](https://metacpan.org/pod/App%3A%3ACmd), [CLI::Framework](https://metacpan.org/pod/CLI%3A%3AFramework), [Role::Tiny](https://metacpan.org/pod/Role%3A%3ATiny),
[CPAN::Maker::Bootstrapper](https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper)

# AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>
