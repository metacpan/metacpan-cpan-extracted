[![Build Status](https://img.shields.io/appveyor/ci/hopenbuild/Data-Hopen/master.svg?logo=appveyor)](https://ci.appveyor.com/project/hopenbuild/Data-Hopen/branch/master)
# NAME

Data::Hopen - A dataflow library with first-class edges

# SYNOPSIS

`Data::Hopen` is a dataflow library that runs actions you specify, moves data
between those actions, and permits transforming data as the data moves.  It is
the underlying engine of the [App::hopen](https://metacpan.org/pod/App%3A%3Ahopen) cross-platform software build
generator, but can be used for any dataflow task that can be represented as a
directed acyclic graph (DAG).

# INSTALLATION

Easiest: install `cpanminus` if you don't have it - see
[https://metacpan.org/pod/App::cpanminus#INSTALLATION](https://metacpan.org/pod/App::cpanminus#INSTALLATION).  Then run
`cpanm Data::Hopen`.

Manually: clone or untar into a working directory.  Then, in that directory,

    perl Makefile.PL
    make
    make test

(you may need to install dependencies as well -
see [https://www.cpan.org/modules/INSTALL.html](https://www.cpan.org/modules/INSTALL.html) for resources).
If all the tests pass,

    make install

If some of the tests fail, please check the issues and file a new one if
no one else has reported the problem yet.

# VARIABLES

Not exported by default, except as noted.

## $VERBOSE

Set to a positive integer to get debug output on stderr from hopen's internals.
The higher the value, the more output you are likely to get.  See also ["hlog"](#hlog).

## $QUIET

Set to truthy to suppress output.  Quiet overrides ["$VERBOSE"](#verbose).

# FUNCTIONS

All are exported by default unless indicated.

## hnew

Creates a new Data::Hopen instance.  For example:

    hnew DAG => 'foo';

is the same as

    Data::Hopen::G::DAG->new( name => 'foo' );

The first parameter (`$class`) is an abbreviated package name.  It is tried
as the following, in order.  The first one that succeeds is used.

1. `Data::Hopen::G::$class`.  This is tried only if `$class`
does not include a double-colon.
2. `Data::Hopen::$class`
3. `$class`

The second parameter
must be the name of the new instance.  All other parameters are passed
unchanged to the relevant constructor.

## hlog

Log information if ["$VERBOSE"](#verbose) is set.  Usage:

    hlog { <list of things to log> } [optional min verbosity level (default 1)];

The items in the list are joined by `' '` on output, and a `'\n'` is added.
Each line is prefixed with `'# '` for the benefit of test runs.

The list is in `{}` so that it won't be evaluated if logging is turned off.
It is a full block, so you can run arbitrary code to decide what to log.
If the block returns an empty list, hlog will not produce any output.
However, if the block returns at least one element, hlog will produce at
least a `'# '`.

The message will be output only if ["$VERBOSE"](#verbose) is at least the given minimum
verbosity level (1 by default).

If `$VERBOSE > 2`, the filename and line from which hlog was called
will also be printed.

## getparameters

An alias of the `parameters()` function from [Getargs::Mixed](https://metacpan.org/pod/Getargs%3A%3AMixed), but with
`-undef_ok` set.

## loadfrom

(Not exported by default) Load a package given a list of stems.  Usage:

    my $fullname = loadfrom($name[, @stems]);

Returns the full name of the loaded package, or falsy on failure.
If `@stems` is omitted, no stem is used, i.e., `$name` is tried as-is.

# CONSTANTS

## UNSPECIFIED

A [Data::Hopen::Util::NameSet](https://metacpan.org/pod/Data%3A%3AHopen%3A%3AUtil%3A%3ANameSet) that matches any non-empty string.
Always returns the same reference, so that it can be tested with `==`.

## NOTHING

A [Data::Hopen::Util::NameSet](https://metacpan.org/pod/Data%3A%3AHopen%3A%3AUtil%3A%3ANameSet) that never matches.  Always returns the
same reference, so that it can be tested with `==`.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Hopen
    perldoc hopen

You can also look for information at:

- GitHub (report bugs here)

    [https://github.com/cxw42/hopen](https://github.com/cxw42/hopen)

- MetaCPAN

    [https://metacpan.org/release/Data-Hopen](https://metacpan.org/release/Data-Hopen)

# INSPIRED BY

- [Luke](https://github.com/gvvaughan/luke)
- a bit of [Ant](https://ant.apache.org/)
- a tiny bit of [Buck](https://buckbuild.com/concept/what_makes_buck_so_fast.html)
- my own frustrations working with CMake.

# AUTHORS

Christopher White

Mohammed S Anwar

# LICENSE AND COPYRIGHT

Copyright (C) 2017--2024 Christopher White, `<cxwembedded at gmail.com>`

This software is licensed BSD-3-Clause.  See the accompanying `LICENSE`
file for details.
