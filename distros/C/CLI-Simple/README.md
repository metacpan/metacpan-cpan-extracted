# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [VERSION](#version)
* [FEATURES](#features)
* [MODULINOS](#modulinos)
  * [Why Modulinos?](#why-modulinos)
  * [The Bash Wrapper](#the-bash-wrapper)
  * [create-modulino](#create-modulino)
  * [MODULINO\_WRAPPER](#modulino\wrapper)
* [QUICK START](#quick-start)
  * [Single-Module Application](#single-module-application)
  * [Role-Based Application](#role-based-application)
* [ROLE-BASED ARCHITECTURE](#role-based-architecture)
  * [The YAML Manifest](#the-yaml-manifest)
  * [Command Values](#command-values)
  * [Roles With No Commands](#roles-with-no-commands)
  * [Activating Role-Based Architecture](#activating-role-based-architecture)
  * [The Inherited main()](#the-inherited-main)
  * [Distributing the Manifest](#distributing-the-manifest)
  * [Not a Framework](#not-a-framework)
  * [Validation, Defaults, and Configuration](#validation-defaults-and-configuration)
  * [When to Use](#when-to-use)
  * [The init-run Lifecycle](#the-init-run-lifecycle)
  * ["opt-in" Default Command](#"opt-in"-default-command)
  * [`$AUTO_HELP` and `$AUTO_DEFAULT`](#$autohelp-and-$autodefault)
* [CONSTANTS](#constants)
* [ADDITIONAL NOTES](#additional-notes)
* [INTERNAL COMMANDS](#internal-commands)
  * [-generate-completion](#-generate-completion)
  * [-dump-spec](#-dump-spec)
  * [-scaffold](#-scaffold)
  * [-migrate](#-migrate)
* [METHODS AND SUBROUTINES](#methods-and-subroutines)
  * [new](#new)
  * [command](#command)
  * [commands (required)](#commands-required)
  * [main](#main)
  * [run](#run)
  * [get\_args](#get\args)
    * [With names](#with-names)
    * [With no names](#with-no-names)
  * [init](#init)
* [USING PACKAGE VARIABLES](#using-package-variables)
* [COMMAND LINE OPTIONS](#command-line-options)
  * [set\_args](#set\args)
* [COMMAND ARGUMENTS](#command-arguments)
* [CUSTOM ERROR HANDLER](#custom-error-handler)
* [SETTING DEFAULT VALUES FOR OPTIONS](#setting-default-values-for-options)
* [ADDING USAGE TO YOUR SCRIPTS](#adding-usage-to-your-scripts)
  * [Custom help() Method](#custom-help-method)
* [ADDING ADDITIONAL SETTERS](#adding-additional-setters)
* [LOGGING](#logging)
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

    use CLI::Simple::Constants qw(:booleans :chars);
    use CLI::Simple qw($AUTO_HELP $AUTO_DEFAULT);

    use parent qw(CLI::Simple);

    caller or __PACKAGE__->main();

    sub execute {
      my ($self) = @_;

      # retrieve a CLI option   
      my $file = $self->get_file;
      ...
    }

    sub list { 
      my ($self) = @_

      # retrieve a command argument
      my ($file) = $self->get_args();
      ...
    }

    sub main {

      # Disable auto-default for single commands, enable auto-help
      $AUTO_DEFAULT = 0;
      $AUTO_HELP = 1;

      my $cli = MyScript->new(
       option_specs    => [ qw( help format=s file=s) ],
       default_options => { format => 'json' }, # set some defaults
       extra_options   => [ qw( content ) ], # non-option, setter/getter
       commands        => { execute => \&execute, list => \&list,  }
       alias           => { options => { fmt => 'format' }, commands => { ls => 'list' } },
      );

      return $cli->run();
    }

    1;

\# role-based CLI Application (2.0.0)

\# create a YAML manifest `my-script.yml` in your project root:

    ---
    commands:
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

# VERSION

This documentation refers to version 2.0.6.

# FEATURES

- accept command line arguments ala [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)
- supports commands and command arguments
- automatically add a logger
- global or custom log levels per command
- easily add usage notes
- automatically create setter/getters for your script
- low dependency profile
- optional role-based architecture via YAML manifest
- built-in scaffolding tools for migrating legacy scripts to roles
- bash completion script generation for modulino wrappers

# MODULINOS

A _modulino_ is a Perl module that can also be run directly as a
script. The term was coined by Brian D. Foy and the pattern is simple:

    caller or __PACKAGE__->main();

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

# QUICK START

## Single-Module Application

The simplest way to use `CLI::Simple` is to subclass it and define
your commands as methods in the same module:

    package My::Script;

    use strict;
    use warnings;

    use CLI::Simple::Constants qw(:booleans);

    use parent qw(CLI::Simple);

    caller or __PACKAGE__->main;

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
    commands:
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

To scaffold role stubs from an existing modulino, run the built-in
`-scaffold` command:

    my-script -scaffold

To scaffold from an existing manifest - including a new one written by hand
or generated by `-dump-spec` - pass the spec file path:

    cli-simple -scaffold my-script.yml

Or let `CLI::Simple` generate the manifest and scaffold from an
existing modulino in one step:

    my-script -migrate

See ["ROLE-BASED ARCHITECTURE"](#role-based-architecture) for the complete workflow including
the baby-step migration path.

# ROLE-BASED ARCHITECTURE

`CLI::Simple` 2.0.0 introduces an optional role-based architecture
for applications that have grown beyond a single module. Commands are
implemented in dedicated [Role::Tiny](https://metacpan.org/pod/Role%3A%3ATiny) roles and declared in a YAML
manifest. `CLI::Simple` composes the roles, builds the dispatch
table, and provides an inherited `main()` - potentially reducing your
main module to a single declaration.

## The YAML Manifest

The manifest is a YAML file that declares your commands, options, and
defaults. By convention the filename is derived from your module name:

    My::Script        ->  my-script.yml
    CPAN::Maker::Bootstrapper  ->  cpan-maker-bootstrapper.yml

`CLI::Simple` locates the manifest via [File::ShareDir](https://metacpan.org/pod/File%3A%3AShareDir) using the
distribution name derived from the module name. The manifest must be
installed as part of the distribution - it cannot be loaded from an
arbitrary location.

_Security note: The manifest is loaded exclusively from the
distribution share directory via [File::ShareDir](https://metacpan.org/pod/File%3A%3AShareDir). A manifest that
was not installed as part of the distribution cannot be loaded. This
provides the same security model as Perl module loading itself._

A minimal manifest:

    ---
    commands:
      frobnicate: My::Script::Role::Frobnicate
      list:       My::Script::Role::List
    options:
      - help|h
      - verbose|v
      - output|o=s

A complete manifest with all supported keys:

    ---
    commands:
      frobnicate: My::Script::Role::Frobnicate
      list:       My::Script::Role::List
      default:    cmd_frobnicate
    options:
      - help|h
      - verbose|v
      - output|o=s
    default_options:
      verbose: 0
    extra_options:
      - dbh
      - config_data

## Command Values

Each command in the manifest maps to either a role class name or a
sub name:

- **Role class name** (contains `::`) - the role is composed
into your main module and the method `cmd__command_` is resolved
from the role. `code-review` resolves to `cmd_code_review`.
- **Sub name** - resolved directly via `can()` on your class.
Use this for alias commands that point to an existing method:

        default: cmd_frobnicate

## Roles With No Commands

Some roles provide framework behavior rather than commands - for
example an `init()` method for startup validation. Since these roles
have no command entry in the manifest they must be composed manually
in your main module:

    package My::Script;

    use CLI::Simple qw(:roles);
    use Role::Tiny::With;
    use parent qw(CLI::Simple);

    with 'My::Script::Role::Init';

    caller or exit __PACKAGE__->main;

    1;

_Note: A future version of `CLI::Simple` will support an
`extra_roles` key in the manifest to handle this automatically._

## Activating Role-Based Architecture

Add `:roles` to your `use CLI::Simple` statement:

    use CLI::Simple qw(:roles);

This triggers manifest loading at compile time. The manifest is
located using the fallback chain described above. Roles are composed
into your class and the dispatch table is built before `new()` is
called.

## The Inherited main()

When using `:roles`, your class inherits `main()` from
`CLI::Simple`. It reads the manifest, constructs the object with the
manifest's options and dispatch table, and calls `run()`:

    caller or exit __PACKAGE__->main;

Override `main()` in your subclass only if you need to add behaviour
that cannot be expressed in the manifest or `init()`.

## Distributing the Manifest

Add the manifest to your distribution's share
directory. `CPAN::Maker` users can add it `extra-files` in
`buildspec.yml` so it is installed into the share directory:

    extra-files:
      - share:
        - my-script.yml

During development the manifest is found via `%INC`. After
installation it is found via [File::ShareDir](https://metacpan.org/pod/File%3A%3AShareDir). No code changes
required between the two environments.
&#x3d;head1 PHILOSOPHY AND DESIGN PRINCIPLES

`CLI::Simple` is intentionally minimalist. It provides just enough
structure to build command-line tools with subcommands, option
parsing, and help handling -- but without enforcing any particular
framework or lifecycle.

## Not a Framework

This module is not [App::Cmd](https://metacpan.org/pod/App%3A%3ACmd), [MooseX::Getopt](https://metacpan.org/pod/MooseX%3A%3AGetopt), or a full
application toolkit.  Instead, it offers:

- An object-oriented base class with a clean `run()` dispatcher
- Command-line parsing via `Getopt::Long`
- Built-in logging via `Log::Log4perl`
- Subclass hooks like `init()` for setup and validation
- Optional role-based architecture via YAML manifest for larger applications

The philosophy is: provide just enough infrastructure, then get out of your way.

## Validation, Defaults, and Configuration

`CLI::Simple` does not impose a validation model. You may:

- Use `Getopt::Long` features (e.g., type constraints, default values)
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

- **Phase 0: Internal Commands**

    Before anything else, `CLI::Simple` checks `@ARGV` for internal
    commands prefixed with `-`. If one is found it executes immediately
    and exits. See ["INTERNAL COMMANDS"](#internal-commands).

- **Phase 1: Manifest Loading**

    For role-based applications using `use CLI::Simple qw(:roles)`, the
    YAML manifest is loaded at compile time during `import`. Roles are
    composed into the calling class and the dispatch table is built before
    `new()` is ever called. Single-module applications skip this phase
    entirely.

- **Phase 2: Initialization (`new` =** `init`)>

    The constructor parses command-line arguments via `Getopt::Long`,
    creates accessors for all options, and calls your `init()` method.
    Inside `init()`, your application has full access to the parsed options 
    and arguments. This phase is the ideal hook for all final setup tasks, 
    such as:

    - Validating command-line arguments.
    - Loading configuration files based on a `--config` option.
    - Dynamically overriding the command (e..g, `$self->command('new_default')`).
    - Performing any setup required **before** a command is run.

- **Phase 3: Execution (`run`)**

    Dispatches to the command method determined during initialization.

## "opt-in" Default Command

By design, `CLI::Simple` **does not impose a default command**.
This provides total flexibility for the application author:

- **You Can Set a Default:** If your application needs a default
command (e.g., to run `help` when no command is given), you can set
`$AUTO_HELP`, explicitly set the `default` command in the `command`
hash you pass to the constructor or use `command()` to set one
inside the `init()` method.
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

In role-based applications using a YAML manifest, a `default` command
that aliases another command should map to the sub name directly rather
than a role class:

    commands:
      default: cmd_install
      install: My::Module::Role::Installer

## `$AUTO_HELP` and `$AUTO_DEFAULT`

Two package variables can be used to further control the lifecycle. By
default, the framework provides no default command as explained in the
sections above. Some scripters may want default behaviors that assume
a command or provide usage if no command is provided.

- `$AUTO_HELP`

    Set the package variable `$AUTO_HELP` to a true value if you want
    `CLI::Simple` to provide help when no command is provided.

    default: false

- `$AUTO_DEFAULT`

    Set the package variable `$AUTO_DEFAULT` to a true value if you want
    `CLI::Simple` to automatically select a command if you have only 1
    command defined and no command is provided on the command line. When
    true, it will prepend the single command name to the argument list,
    allowing any subsequent arguments to be correctly parsed as args for
    that command.

    default: false

# CONSTANTS

`CLI::Simple` does not define its own constants directly, but it is often used
in conjunction with [CLI::Simple::Constants](https://metacpan.org/pod/CLI%3A%3ASimple%3A%3AConstants), which provides a collection of
exportable values commonly needed in command-line scripts.

These include:

- Boolean flags like `$TRUE`, `$FALSE`, `$SUCCESS`, and `$FAILURE`
- Common character tokens such as `$COLON`, `$DASH`, `$EQUALS_SIGN`, etc.
- Log level names compatible with [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl)

To use them in your script:

    use CLI::Simple::Constants qw(:all);

# ADDITIONAL NOTES

- All options are case insensitive
- See [CLI::Simple::Utils](https://metacpan.org/pod/CLI%3A%3ASimple%3A%3AUtils) to learn about additional utilities
useful when writing scripts, including `choose`, `slurp`, and `dmp`.
- `%INTERNAL_COMMANDS` is a package variable - subclasses can
add their own internal commands by pushing entries into the hash before
calling `new()`.

# INTERNAL COMMANDS

`CLI::Simple` reserves command names beginning with `-` for its own
use. These commands are intercepted before option parsing begins and
execute immediately, bypassing the normal lifecycle entirely. See
["The init-run Lifecycle"](#the-init-run-lifecycle).

Internal commands are dispatched via the `%INTERNAL_COMMANDS` package
variable:

    our %INTERNAL_COMMANDS = (
      '-generate-completion' => \&_cmd_generate_completion,
      '-dump-spec'           => \&_cmd_dump_spec,
      '-scaffold'            => \&_cmd_scaffold,
      '-migrate'             => \&_cmd_migrate,
    );

Subclasses can add their own internal commands by extending the hash
before `new()` is called:

    our %INTERNAL_COMMANDS = (
      %CLI::Simple::INTERNAL_COMMANDS,
      '-my-command' => \&_cmd_my_command,
    );

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
type `--` and press Tab.

To make completions permanent, most systems automatically source files
placed in `~/.local/share/bash-completion/completions/` when
`bash-completion` 2.x is installed. If your system does not pick
them up automatically, add the following to your `~/.bashrc`:

    source ~/.local/share/bash-completion/completions/my-script

Alternatively, place the generated file in the system-wide completion
directory (requires root):

    my-script -generate-completion > \
      /etc/bash_completion.d/my-script

The script name is taken from the first argument if provided, then
`MODULINO_WRAPPER` if set, then inferred from the module name. If the
inferred name cannot be found in `PATH`, a warning is issued but the
completion script is still generated.

_Note: If you created the modulino with the supplied
`create-modulino` tool `MODULINO_WRAPPER` is already set inside the
bash script that invokes the modulino._

- Case 1: Your modulino wrapper and module name are aligned 

    The modulino script `my-modulino` refers to My::Modulino

        my-modulino -generate-completion

- Case 2: Your modulino wrapper was created using `create-modulino`

    The modulino script `my-alias` refers to My::Modulino. They are not
    aligned however `MODULINO_WRAPPER` is set by the bash wrapper.

        my-alias -generate-completion

- Case 3: Your modulino is an alias not created by `create-modulino`

    The script name `my-alias` is not aligned with your module name
    `My::Module` and your modulino wrapper does not set
    `MODULINO_WRAPPER`. The `-generate-completion` script called by 
    your custom wrapper most likely only resolves the program name as the path to
    your Perl module:

        path-to-modules/My/Module.pm

    ...in this case you need to supply the alias name or set
    `MODULINO_WRAPPER` in the environment.

        my-alias -generate-completion my-alias

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
from an explicit spec file. The tarball contains role stubs, a slimmed
main module with extracted POD, a `project.mk` with inter-module
dependencies, and the YAML manifest.

    my-script -scaffold                        # introspect live module
    cli-simple -scaffold my-script.yml         # scaffold from spec file

The tarball is named `my-script-roles.tar.gz` by convention (the
lower case snake cased version of the class name). The name is used to
infer the class name. If your filename is different than the
classes you want to scaffold, you will need to edit the files. 

Feed the tarball to [CPAN::Maker::Bootstrapper](https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper) via the
`import-scaffold` command to produce a complete buildable CPAN
distribution.

## -migrate

Combines `-dump-spec roles` and `-scaffold` in a single step.

    my-script -migrate

Writes the YAML manifest then generates the role-based tarball. Use
this when you are ready for a full migration and do not need to inspect
or edit the manifest first. If you want to review or adjust the
manifest before scaffolding, run `-dump-spec` and `-scaffold`
separately.

# METHODS AND SUBROUTINES

## new

    new( args )

Instantiates a new `CLI::Simple` instance, parses options, optionally
initializes logging, and makes options available via dynamically
generated accessors.

_Note: The `new()` constructor uses [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)'s `GetOptions`,
which directly modifies `@ARGV` by removing any recognized
options. The remaining elements of `@ARGV` are treated as the command
name and its arguments._

`args` is a hash or hash reference containing the following keys:

- abbreviations

    A boolean that determines whether abbreviated command names are allowed.

    When true, the `run()` method will treat the provided command as a prefix
    and compare it to the keys in the command hash. If exactly one match is
    found, it will be used. If more than one match is found, or if no match is
    found, `run()` will throw an exception.

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
    apply if the corresponding option is not given on the command line.

- extra\_options (optional)

    An array reference of names for additional accessors you want to create,
    even if they are not part of `option_specs`.

    Example:

        extra_options => [ qw(foo bar baz) ]

- option\_specs (optional)

    An array reference of option specifications, as accepted by
    [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong). These define the command-line options your program
    recognizes.

## command

    command
    command(command)

Get or sets the command to execute. Usually this is the first argument
on the command line after all options have been parsed. There are
times when you might want to override the argument. You can pass a new
command that will be executed when you call the `run()` method.

## commands (required)

    commands
    commands(command, handler)

Returns the hash you passed in the constructor as `commands` or can
be used to insert a new command into the `commands` hash. `handler`
should be a code reference.

    commands(foo => sub { return 'foo' });

## main

    __PACKAGE__->main;

For role-based applications, `main` is inherited from `CLI::Simple`
and reads the YAML manifest loaded during `import`. It constructs the
object with the manifest's options, default options, extra options, and
dispatch table, then calls `run()`.

In a role-based modulino the entire `main` sub reduces to:

    caller or exit __PACKAGE__->main;

For single-module applications, override `main` in your subclass as
usual.

## run

Execute the script with the given options, commands and arguments. The
`run` method interprets the command line and passes control to your
command subroutines. Your subroutines should return a 0 for success
and a non-zero value for failure.  This error code is passed to the
shell as the script return code.

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

    my %args = $self->get_args('message', undef, 'cc');  # args 1 and 3

If there are fewer positional arguments than names, the remaining names
are set to `undef`. Extra positional arguments (beyond the provided
names) are ignored.

### With no names

- In scalar context returns an array reference containing the
command's positional arguments.
- In list context returns a list containing the command's
positional arguments.

## init

If you define your own `init()` method, it will be called by the
constructor. Use this method to perform any actions you require before
you execute the `run()` method.

# USING PACKAGE VARIABLES

You can pass the necessary parameter required to implement your
command line scripts in the constructor or some people prefer to see
them clearly defined in the code. Accordingly, you can use package
variables with the same name as the constructor arguments (in upper
case).

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

Subclasses can also extend the built-in internal commands by adding
entries to `%INTERNAL_COMMANDS`:

    our %INTERNAL_COMMANDS = (
      %CLI::Simple::INTERNAL_COMMANDS,
      '-my-command' => \&_cmd_my_command,
    );

# COMMAND LINE OPTIONS

Command-line options are defined using [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)-style
specifications. You pass these into the constructor via the
`option_specs` parameter:

    my $cli = CLI::Simple->new(
      option_specs => [ qw( help|h foo-bar=s log-level=s ) ]
    );

In your command subroutines, you can access these values using
automatically generated getter methods:

    $cli->get_foo();
    $cli->get_log_level();

Option names that contain dashes (`-`) are automatically converted to
snake\_case for the accessor methods. For example:

    option_specs => [ 'foo-bar=s' ]

...results in:

    $cli->get_foo_bar();

## set\_args

Resets the positional arguments.

    $self->set_args(qw(foo 1));

This method overrides the positional arguments originally passed to
the script. You can achieve the same behavior by calling the
`get_args` in scalar context and modifying the reference.

    my $args = $self->get_args;
    $args->[1] = '2';

Use this technique when you want don't want to alter the entire set of
arguments.

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

# CUSTOM ERROR HANDLER

By default, `CLI::Simple` will exit if `GetOptions` returns a false
value, indicating an error while parsing options. You can override this
behavior in one of two ways:

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

# ADDING USAGE TO YOUR SCRIPTS

To provide built-in usage/help output, include a `=head1 USAGE`
section in your script's POD:

    =head1 USAGE

      usage: myscript [options] command args

      Options
      -------
      --help, -h      Display help
      ...

If the user supplies the command `help`, or the `--help` option,
`CLI::Simple` will display this section automatically:

    perl myscript.pm --help
    perl myscript.pm help

## Custom help() Method

If you need full control over the help output, you can define a custom
`help` method and assign it as a command:

    commands => {
      help => \&help,
      ...
    }

This is useful if your module follows the modulino pattern and you
want to present usage information that differs from the embedded
POD. Without a custom handler, `CLI::Simple` defaults to displaying the
`USAGE` POD section.

# ADDING ADDITIONAL SETTERS

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

# LOGGING

`CLI::Simple` integrates with [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) to provide structured
logging for your scripts.

To enable logging, call the class method `use_log4perl()` in your
module or script:

    __PACKAGE__->use_log4perl(
      level  => 'info',
      config => $log4perl_config_string
    );

If you do not explicitly include a `log-level` option in your
`option_specs`, CLI::Simple will automatically add one for you.

Once enabled, you can access the logger instance via:

    my $logger = $self->get_logger;

This logger supports the standard Log4perl methods like `info`,
`debug`, `warn`, etc.

## Per Command Log Levels

Some commands may require more verbose logging than others. For
example, certain commands might perform complex actions that benefit
from detailed logs, while others are designed solely to produce clean,
structured output.

To assign a custom log level to a command, use an array reference as
the value for that command in the commands hash passed to the
constructor.

The array reference should contain at least two elements:

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

    No. If your script doesn't support multiple commands, you can specify
    a `default` key instead:

        commands => { default => \&main }

- Must I subclass `CLI::Simple`?

    No. You can use it procedurally or functionally.

- How do I turn my class into a script?

    Use the modulino pattern: create a class that checks whether it is
    being invoked directly:

        package MyScript;

        caller or __PACKAGE__->main();

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

    Your script must be invoked via a bash modulino wrapper with
    `MODULINO_WRAPPER` set. Then run:

        my-script -generate-completion > \
          ~/.local/share/bash-completion/completions/my-script

    Wrappers generated by [CPAN::Maker::Bootstrapper](https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper) set
    `MODULINO_WRAPPER` automatically.

- How do I add my own internal commands?

    Add entries to `%INTERNAL_COMMANDS` before calling `new()`:

        our %INTERNAL_COMMANDS = (
          %CLI::Simple::INTERNAL_COMMANDS,
          '-my-command' => \&_cmd_my_command,
        );

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

    _Note: If your option includes a one-letter short-cut and the alias
    does not start with the same letter it will not be automatically
    enabled as a short-cut._

- Accessors are created for both names

    Accessors are generated from all option names (canonical and aliases),
    with '-' normalized to '\_'. In the example, both `get_config()` and
    `get_cfg()` are available.

- Values are mirrored after parsing

    After option parsing and normalization, values are mirrored so either
    name can be used consistently. If both the canonical name and its alias
    are provided on the command line, the alias wins and becomes the final
    value for both names.

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
from `--cfg` (the alias) is used.

_Note: In role-based applications using a YAML manifest, command
aliases are expressed by mapping the alias command directly to the
target sub name rather than a role class. See ["ROLE-BASED ARCHITECTURE"](#role-based-architecture)._

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

When you execute the `run()` method it passes control to the method
that implements the command specified on the command line. Your method
is expected to return 0 for success or an error code that you can pass
to the shell on exit.

    exit CLI::Simple->new(commands => { foo => \&cmd_foo })->run();

## Exit Codes

`CLI::Simple` uses conventional exit codes so that calling scripts
can distinguish between normal completion and error conditions.

- '0'

    Successful completion of a command (`SUCCESS`).

- '1'

    General usage error, such as `--help` display via `pod2usage`, or an
    invalid command line (`FAILURE`).

- '2'

    Option parsing failure, such as an unrecognized option or invalid
    argument (also reported as `FAILURE`).

- Any other code

    If a user-supplied command callback explicitly calls `exit()` or
    returns a numeric value other than 0 - 2, that code is passed through
    unchanged to the shell. This allows application-specific exit codes.

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
