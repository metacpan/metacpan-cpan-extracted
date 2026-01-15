[![Actions Status](https://github.com/tecolicom/Command-Run/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/tecolicom/Command-Run/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/Command-Run.svg)](https://metacpan.org/release/Command-Run)
# NAME

Command::Run - Execute external command or code reference

# SYNOPSIS

    use Command::Run;

    # Simple usage
    my $result = Command::Run->new(
        command => ['ls', '-l'],
        stderr  => 'redirect',  # merge stderr to stdout
    )->run;
    print $result->{data};

    # Method chaining style
    my $runner = Command::Run->new;
    $runner->command('cat', '-n')->with(stdin => $data)->run;
    print $runner->data;

    # Separate stdout/stderr capture
    my $result = Command::Run->new(
        command => ['some_command'],
        stderr  => 'capture',
    )->run;
    print "data: ", $result->{data};
    print "error: ", $result->{error};

    # Access output via file descriptor path
    my $cmd = Command::Run->new('date');
    $cmd->update;
    system("cat", $cmd->path);  # /dev/fd/N

    # Code reference execution
    my $result = Command::Run->new(
        command => [\&some_function, @args],
        stdin   => $input_data,
    )->run;

    # Using with() method
    my ($out, $err);
    Command::Run->new("command", @args)
        ->with(stdin => $input, stdout => \$out, stderr => \$err)
        ->run;

# VERSION

Version 0.9901

# DESCRIPTION

This module provides a simple interface to execute external commands
or code references and capture their output.

When a code reference is passed as the first element of the command
array, it is called in a forked child process instead of executing an
external command.  This avoids the overhead of loading Perl and
modules for each invocation.

This module inherits from [Command::Run::Tmpfile](https://metacpan.org/pod/Command%3A%3ARun%3A%3ATmpfile), which provides
temporary file functionality.  The captured output is stored in this
temporary file, accessible via the `path` method as `/dev/fd/N`,
which can be used as a file argument to external commands.

# CONSTRUCTOR

- **new**(%parameters)
- **new**(@command)

    Create a new Command::Run object.  Parameters can be passed as
    key-value pairs (see ["PARAMETERS"](#parameters)), or a command can be passed
    directly:

        # Parameters style
        my $runner = Command::Run->new(
            command => \@command,
            stdin   => $input_data,
            stderr  => 'redirect',
        );

        # Direct command style
        my $runner = Command::Run->new('ls', '-l');

# PARAMETERS

The following parameters can be used with `new`, `with`, and `run`.
With `new` and `with`, parameters are stored in the object.
With `run`, parameters are temporary and do not modify the object.

- **command** => _\\@command_

    The command to execute.  Can be an array reference of command and
    arguments, or a code reference with arguments.

- **stdin** => _data_

    Input data to be fed to the command's STDIN.

- **stdout** => _\\$scalar_

    Scalar reference to capture STDOUT.

- **stderr** => _\\$scalar_ | `'redirect'` | `'capture'`

    Controls STDERR handling:

    - _\\$scalar_ - Capture STDERR into the referenced variable
    - `'redirect'` - Merge STDERR into STDOUT
    - `'capture'` - Capture STDERR separately (accessible via `error` method)
    - `undef` (default) - STDERR passes through to terminal

# METHODS

- **command**(_@command_)

    Set the command to execute.  The argument can be:

    - External command and arguments: `'ls', '-l'`
    - Code reference and arguments: `\&func, @args`

    Returns the object for method chaining.

- **with**(_%parameters_)

    Set parameters (see ["PARAMETERS"](#parameters)).  Settings are stored in the
    object and persist across multiple `run` calls.  Returns the object
    for method chaining.

        my ($out, $err);
        Command::Run->new("command")
            ->with(stdin => $data, stdout => \$out, stderr => \$err)
            ->run;

- **run**(_%parameters_)

    Execute the command and return the result hash reference.
    Accepts the same parameters as `with`, but parameters are
    temporary and do not modify the object state.

        # All-in-one style
        my $result = Command::Run->new->run(
            command => ['cat', '-n'],
            stdin   => $data,
            stderr  => 'redirect',
        );

        # Reuse runner with different input
        my $runner = Command::Run->new('cat');
        $runner->run(stdin => $input1);
        $runner->run(stdin => $input2);  # object state unchanged

- **update**()

    Execute the command and store the output.
    Returns the object for method chaining.

- **result**()

    Return the result hash reference from the last execution.

- **data**()

    Return the captured output (stdout) from the last execution.

- **error**()

    Return the captured error output (stderr) from the last execution.

- **path**()

    Return the file descriptor path (e.g., `/dev/fd/3`) for the
    captured output.  This can be passed to external commands.

- **rewind**()

    Seek to the beginning of the output temp file.

- **date**()

    Return the timestamp of the last execution.

# RETURN VALUE

The `run` method returns a hash reference containing:

- **result**

    The exit status of the command (`$?`).

- **data**

    The captured output (stdout).

- **error**

    The captured error output (stderr, empty string unless `stderr` is `'capture'`).

- **pid**

    The process ID of the executed command.

# COMPARISON WITH SIMILAR MODULES

There are many modules on CPAN for executing external commands.
This module is designed to be simple and lightweight, with minimal
dependencies.

This module was originally developed as [App::cdif::Command](https://metacpan.org/pod/App%3A%3Acdif%3A%3ACommand) and
has been used in production as part of the [App::cdif](https://metacpan.org/pod/App%3A%3Acdif) distribution
since 2014.  It has also been adopted by several unrelated modules,
which motivated its release as an independent distribution.

- [IPC::Run](https://metacpan.org/pod/IPC%3A%3ARun)

    Full-featured module for running processes with support for
    pipelines, pseudo-ttys, and timeouts.  Very powerful but large
    (135KB+) with non-core dependencies ([IO::Pty](https://metacpan.org/pod/IO%3A%3APty)).  Overkill for
    simple command execution.

- [Capture::Tiny](https://metacpan.org/pod/Capture%3A%3ATiny)

    Excellent for capturing STDOUT/STDERR from Perl code or external
    commands.  Does not provide stdin input functionality.

- [IPC::Run3](https://metacpan.org/pod/IPC%3A%3ARun3)

    Simpler than [IPC::Run](https://metacpan.org/pod/IPC%3A%3ARun), handles stdin/stdout/stderr.  Good
    alternative but does not support code reference execution.

- [Command::Runner](https://metacpan.org/pod/Command%3A%3ARunner)

    Modern interface with timeout support and code reference execution.
    Has non-core dependencies.

- [Proc::Simple](https://metacpan.org/pod/Proc%3A%3ASimple)

    Simple process management with background execution support.
    Focused on process control rather than I/O capture.

**Command::Run** differs from these modules in several ways:

- **Core modules only** - No non-core dependencies
- **Code reference support** - Execute Perl code with $0 and @ARGV setup
- **File descriptor path** - Output accessible via `/dev/fd/N`
- **Minimal footprint** - About 200 lines of code
- **Method chaining** - Fluent interface for readability

# SEE ALSO

[Command::Run::Tmpfile](https://metacpan.org/pod/Command%3A%3ARun%3A%3ATmpfile), [IPC::Run](https://metacpan.org/pod/IPC%3A%3ARun), [Capture::Tiny](https://metacpan.org/pod/Capture%3A%3ATiny), [IPC::Run3](https://metacpan.org/pod/IPC%3A%3ARun3), [Command::Runner](https://metacpan.org/pod/Command%3A%3ARunner)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
