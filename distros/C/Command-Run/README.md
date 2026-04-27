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
    my $cmd = Command::Run->new(command => ['date']);
    $cmd->update;
    system("cat", $cmd->path);  # /dev/fd/N

    # Code reference execution
    my $result = Command::Run->new(
        command => [\&some_function, @args],
        stdin   => $input_data,
    )->run;

    # Using with() method
    my ($out, $err);
    Command::Run->new->command("command", @args)
        ->with(stdin => $input, stdout => \$out, stderr => \$err)
        ->run;

# VERSION

Version 1.00

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

    Create a new Command::Run object.  Parameters are passed as
    key-value pairs (see ["PARAMETERS"](#parameters)):

        my $runner = Command::Run->new(
            command => \@command,
            stdin   => $input_data,
            stderr  => 'redirect',
        );

        # Or use method chaining
        my $runner = Command::Run->new->command('ls', '-l');

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

- **nofork** => _bool_

    When true and the command is a code reference, execute the code in
    the current process without forking.  Ignored for external commands.
    See ["NOFORK AND RAW MODE"](#nofork-and-raw-mode) for details.

- **raw** => _bool_

    When true (with `nofork`), use `:utf8` instead of
    `:encoding(utf8)` on I/O temporary files, avoiding encode/decode
    overhead and PerlIO layer leak.  See ["NOFORK AND RAW MODE"](#nofork-and-raw-mode) for
    details.

        my $result = Command::Run->new(
            command => [\&process, @args],
            nofork  => 1,
            raw     => 1,
        )->run;

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

# NOFORK AND RAW MODE

## Overview

When executing Perl code references, the default fork-based execution
has two significant costs:

- 1. Fork overhead

    `fork()` duplicates the entire process, including all loaded modules
    and data structures.

- 2. Encoding overhead

    I/O between parent and child processes goes through pipes, requiring
    `:encoding(utf8)` layers that encode and decode UTF-8 on every read
    and write.

The `nofork` option eliminates the fork cost by executing the code
reference in the current process.  The `raw` option eliminates the
encoding cost by using the `:utf8` PerlIO pseudo-layer instead of
`:encoding(utf8)`.

Combined, these options can achieve **over 30x speedup** compared to
fork-based execution for lightweight functions with small I/O.

## How Nofork Works

In nofork mode, `_execute_nofork` temporarily redirects the real
STDOUT, STDERR, and STDIN file descriptors to temporary files using
`dup`, executes the code reference, then restores them:

    # Simplified flow:
    open $save, '>&', \*STDOUT;           # save original
    open STDOUT, '>&', $tmpfile;          # redirect to tmpfile
    $code->(@args);                       # execute code ref
    open STDOUT, '>&', $save;             # restore original
    $tmpfile->seek(0, 0);
    $output = do { local $/; <$tmpfile> }; # read captured output

The code reference sees real STDOUT/STDIN file descriptors (not tied
handles), so it behaves identically to the fork path from the
callee's perspective.  `@ARGV`, `$0`, and `$_` are protected with
`local` to prevent side effects.

## How Raw Mode Works

The `raw` option controls which PerlIO layer is applied to the
temporary files used for I/O redirection:

    # Normal mode (raw => 0):
    binmode $tmpfile, ':encoding(utf8)';  # full encode/decode

    # Raw mode (raw => 1):
    binmode $tmpfile, ':utf8';            # flag only, no conversion

In the normal fork path, `:encoding(utf8)` is necessary because data
crosses process boundaries through pipes as byte streams.  But in
nofork mode, caller and callee share the same Perl interpreter, so
Perl's internal string format (which is already UTF-8 internally) can
be passed directly.  The `:utf8` layer simply sets Perl's UTF-8 flag
on strings read from the file without performing actual byte-level
conversion.

### PerlIO Encoding Leak

There is an additional reason to prefer `:utf8` over
`:encoding(utf8)` in long-running processes.  Repeatedly pushing and
popping the `:encoding(utf8)` layer (which happens on each nofork
execution when opening and closing temporary files) causes a
cumulative performance degradation in Perl's PerlIO subsystem.  This
affects **all** PerlIO operations in the process, not just the ones
using the encoding layer.

In benchmarks, nofork with `:encoding(utf8)` is actually **slower**
than fork after many iterations, due to this leak.  Raw mode avoids
the issue entirely.

    # Benchmark: code ref with stdin (100-byte input, 1000 iterations)
    fork:                  399/s (baseline)
    nofork + :encoding:    316/s (0.8x — slower than fork!)
    nofork + :utf8 (raw): 13,433/s (34x faster)

## Zero-Modification Callee Integration

A key advantage of this mechanism is that **callee modules typically
require no modification** to work with nofork+raw mode.

Many Perl modules use `use open` pragma or equivalent to set up
encoding layers on standard I/O:

    package App::ansicolumn;
    use open IO => ':utf8', ':std';    # sets :encoding(utf8) on STDIO

This works transparently because of execution order.  When using
nofork mode with method chaining:

    require App::ansicolumn;           # (1) module loaded here
    Command::Run->new
        ->command(\&ansicolumn, @args)
        ->with(stdin => $text, nofork => 1, raw => 1)
        ->update                       # (2) STDOUT redirected here
        ->data;

At step (1), `require` loads the module and `use open ':std'`
applies `:encoding(utf8)` to the **original** STDOUT.  At step (2),
`_execute_nofork` redirects STDOUT to a fresh temporary file with
`:utf8` layer.  The callee's encoding setup has already fired on the
original STDOUT and does not affect the redirected one.

This means existing modules like [App::ansicolumn](https://metacpan.org/pod/App%3A%3Aansicolumn) and
[App::ansifold](https://metacpan.org/pod/App%3A%3Aansifold) work unchanged with nofork+raw mode, achieving
significant speedups with zero code changes on the callee side.

## Caller Protection

Nofork mode executes the code reference in the same process, so care
is needed to prevent the callee from corrupting the caller's state.
The following protections are applied:

- `local $_;`

    Prevents the callee from modifying the caller's `$_`.  This is
    critical when the caller aliases `$_` to important data (e.g.,
    greple's `local *_ = shift` to alias `$_` to the content buffer).
    Without this protection, a callee's `while (<>)` loop
    would set `$_` to `undef` at EOF, destroying the caller's data.

- `local @ARGV`

    Prevents the callee from modifying the caller's `@ARGV`.

- `$0` save/restore

    Prevents the callee from permanently changing the program name.

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
