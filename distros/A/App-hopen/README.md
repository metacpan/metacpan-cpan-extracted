[![Build Status](https://img.shields.io/appveyor/ci/hopenbuild/App-hopen/master.svg?logo=appveyor)](https://ci.appveyor.com/project/hopenbuild/App-hopen/branch/master)
# NAME

App::hopen - Graph-driven cross-platform build system

# CURRENT STATUS

Most features are not yet implemented ;) .  However it will generate a
`Makefile` or `build.ninja` file for a C `Hello, World` program at this
point!  It can generate command lines for gcc(1) or for Microsoft's `cl.exe`.

# INTRODUCTION

hopen is a cross-platform software build generator.  It makes files you can
pass to Make, Ninja, Visual Studio, or other build tools, to compile and
link your software.  hopen gives you:

- A full, Turing-complete, robust programming language to write your
build scripts (specifically, Perl 5.14+)
- No hidden magic!  All your data is visible and accessible in a build graph
(whence "graph-driven").
- Context-sensitivity.  Your users can tweak their own builds for their own
platforms without affecting your project.

See [App::hopen::Conventions](https://metacpan.org/pod/App%3A%3Ahopen%3A%3AConventions) for details of the input format.

Why Perl?  Because (1) you probably already have it installed, and
(2) it is the original write-once, run-everywhere language!

## Example

Create a file `.hopen.pl` in your source tree.  Then:

    $ hopen
    From ``.'' into ``built''
    Running Check phase

Now `built/MY.hopen.pl` has been created, and loaded with information about
your configuration.  You can edit that file if you want to change what will
happen next.

    $ hopen
    From ``.'' into ``built''
    Running Gen phase

Now `built/Makefile` has been created.

    $ hopen --build
    Building in foo/built

And your software is ready to go!  `make` has been run in `built/`,
with output left in `built/`.

See [App::hopen::Conventions](https://metacpan.org/pod/App%3A%3Ahopen%3A%3AConventions) for information on writing `.hopen.pl` files.

# SYNOPSIS

    hopen [options] [--] [destination dir [project dir]]

If no project directory is specified, the current directory is used.

If no destination directory is specified, `<project dir>/built` is used.

See [App::hopen](https://metacpan.org/pod/App%3A%3Ahopen) and [App::hopen::Conventions](https://metacpan.org/pod/App%3A%3Ahopen%3A%3AConventions) for more details.

# OPTIONS

- -a `architecture`

    Specify the architecture.  This is an arbitrary string interpreted by the
    generator or toolset.

- --build

    Run the generator to process the blueprint files.  Cannot be used
    with `--fresh`.

- -e `Perl code`

    Add the `Perl code` as if it were a hopen file.  `-e` files are processed
    after all other hopen files, so can modify anything that has been set up
    by those files.  Can be specified more than once.

- --fresh

    Start a fresh build --- ignore any `MY.hopen.pl` file that may exist in
    the destination directory.  Cannot be used with `--build`.

- --from `project dir`

    Specify the project directory.  Overrides a project directory given as a
    positional argument.

- -g `generator` (or -G)

    Specify the generator.  The given `generator` should be either a full package
    name or the part after `App::hopen::Gen::`.  Also accepts `-G` to ease
    the transition from cmake.

- -t `toolset` (or -T)

    Specify the toolset.  The given `toolset` should be either a full package
    name or the part after `App::hopen::T::`.  Also accepts `-T` to ease
    the transition from cmake.

- --to `destination dir`

    Specify the destination directory.  Overrides a destination directory given
    as a positional argument.

- --phase `phase`

    Specify which phase of the process to run.  Note that this overrides whatever
    is specified in any MY.hopen.pl file, so may cause unexpected results!

    If `--phase` is given, no other hopen file can set the phase, and hopen will
    terminate if a file attempts to do so.

- -q

    Produce no output (quiet).  Overrides `-v`.

- -v, --verbose=n

    Verbose.  Specify more `v`'s for more verbosity.  At present, `-vv`
    (equivalently, `--verbose=2`) gives
    you detailed traces of the data, and `-vvv` gives you more detailed
    code tracebacks on error.

- --version

    Print the version of hopen and exit

# INTERNALS

After the `hopen` file is processed, cycles are detected and reported as
errors.  \*(TODO change this to support LaTeX multi-run files?)\*  Then the DAG
is traversed, and each operation writes the necessary information to the
file being generated.

# INTERNAL DATA

## `$RUNNING`

Set truthy when a hopen run is in progress.  This is so modules don't have
to `die()` if they are being run under `perl -c`, for example.

TODO replace this with a package parameter --- see
["\_language\_import" in App::hopen::HopenFileKit](https://metacpan.org/pod/App%3A%3Ahopen%3A%3AHopenFileKit#language_import).

## `$_hrData`

The hashref of the current data we have built up by processing hopen files.

## `$_did_set_phase`

Set to truthy if MY.hopen.pl sets the phase.

## `$_hf_pkg_idx`

Used to give each hopen file or `-e` a unique package name.

## %CMDLINE\_OPTS

A hash from internal name to array reference of
\[getopt-name, getopt-options, optional default-value\].

If default-value is a reference, it will be the destination for that value.

# INTERNAL FUNCTIONS

## \_parse\_command\_line

Takes {into=>hash ref, from=>array ref}.  Fills in the hash with the
values from the command line, keyed by the keys in ["%CMDLINE\_OPTS"](#cmdline_opts).

## \_execute\_hopen\_file

Execute a single hopen file, but **do not** run the DAG.  Usage:

    _execute_hopen_file($filename[, options...])

This function takes input from ["$\_hrData"](#_hrdata) unless a `DATA=>{...}` option
is given.  This function updates ["$\_hrData"](#_hrdata) based on the results.

Options are:

- phase

    If given, force the phase to be the one specified.

- quiet

    If truthy, suppress extra output.

- libs

    If given, it must be an arrayref of directories.  Each of those will be
    turned into a `use lib` statement (see [lib](https://metacpan.org/pod/lib)) in the generated source.

## \_run\_phase

Run a phase by executing the hopen files and running the DAG.
Reads from and writes to ["$\_hrData"](#_hrdata), which must be initialized by
the caller.  Usage:

    my $hrDagOutput = _run_phase(files=>[...][, options...])

Options `phase`, `quiet`, and `libs` are as ["\_execute\_hopen\_file"](#_execute_hopen_file).
Other options are:

- files

    (Required) An arrayref of filenames to run

- norun

    (Optional) if truthy, do not run the DAG.  Note that the DAG will also not
    be run if it is empty.

## \_inner

Do the work for one invocation of hopen(1).  Dies on failure.  Main() then
translates the die() into a print and error return.

Takes a hash of options.

The return value of \_inner is unspecified and ignored.

## Main

Command-line runner.  Call as `App::hopen::Main(\@ARGV)`.

# AUTHOR

Christopher White, `cxwembedded at gmail.com`

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::hopen                      For command-line options
    perldoc App::hopen::Conventions         For terminology and workflow
    perldoc Data::Hopen                     For the underlying engine

You can also look for information at:

- GitHub: The project's main repository and issue tracker

    [https://github.com/hopenbuild/App-hopen](https://github.com/hopenbuild/App-hopen)

- MetaCPAN

    [https://metacpan.org/pod/App::hopen](https://metacpan.org/pod/App::hopen)

- This distribution

    See the `eg/` directory distributed with this software for examples.

# LICENSE AND COPYRIGHT

Copyright (c) 2018--2019 Christopher White.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this program; if not, write to the Free
Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
