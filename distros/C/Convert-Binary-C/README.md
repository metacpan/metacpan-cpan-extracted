# Convert-Binary-C

Binary Data Conversion using C Types


## Description

Convert::Binary::C is a preprocessor and parser for C type definitions.
It is highly configurable and should support arbitrarily complex data
structures. Its object-oriented interface has pack and unpack methods
that act as replacements for Perl's pack and unpack and allow to use the
C types instead of a string representation of the data structure for
conversion of binary data from and to Perl's complex data structures.

Actually, what Convert::Binary::C does is not very different from what
a C compiler does, just that it doesn't compile the source code into
an object file or executable, but only parses the code and allows Perl
to use the enumerations, structs, unions and typedefs that have been
defined within your C source for binary data conversion, similar to
Perl's pack and unpack.

Beyond that, the module offers a lot of convenience methods to retrieve
information about the C types that have been parsed.


## Installation

Installation of the Convert::Binary::C module follows the standard
Perl Way and should not be harder than:

    perl Makefile.PL
    make
    make test
    make install

Note that you may need to become superuser to `make install`.

If you're building the module under Windows, you may need to use a
different make program, such as `nmake`, instead of `make`.

When running 'make test' on on slower systems please be patient,
since some of the tests are quite time consuming. The time required
for running the whole test suite depends on your Perl version, the
features you're building the module with, and of course your machine.


## Upgrading

If you are upgrading from a previous release of Convert::Binary::C,
please check the Changes file. In its current state, the module is
still subject to changes that may affect compatibility with older
releases.


## Documentation

To see the documentation, use the perldoc command:

    perldoc Convert::Binary::C
    perldoc Convert::Binary::C::Cached

You can also visit CPAN Search and see the documentation online as
pretty nice HTML. This is also where you will find the most recent
version of this module:

    https://metacpan.org/release/Convert-Binary-C

Even though the documentation contains a large amount of tested
example code, you might want some working example scripts. You can
find them in the

    examples

subdirectory after you've built the module. These scripts normally
require Convert::Binary::C to be installed on your system. If you
want to test the examples prior to installing Convert::Binary::C,
you can start the examples like this after building the module:

    perl -Mblib examples/script.pl

Otherwise just run the example scripts like any other Perl script.


## Configuration

Configuring a Convert::Binary::C object correctly can be quite
painful if you don't know every little detail about your compiler.

However, if you're lucky, you can use the 'ccconfig' tool that
comes with this package. It was written to automatically retrieve
the complete compiler configuration. This may not work always,
or retrieve the complete configuration, but it should at least
give you some point to start from.

Just run

    ccconfig -c compiler

with `compiler` being the name of your compiler executable.

You can see the documentation for 'ccconfig' using the perldoc
command:

    perldoc ccconfig

As the tool is very experimental, any feedback on 'ccconfig'
is really appreciated!


## Compatibility

The module should build on most of the platforms that Perl runs on.
I have tested it on:

* Various Linux systems
* Various BSD systems
* HP-UX
* Compaq/HP Tru64 Unix
* Mac-OS X
* Cygwin
* Windows 98/NT/2000/XP

Also, most architectures should be supported. Tests were done on:

* Various Intel Pentium and Itanium systems
* Various Alpha systems
* HP PA-RISC
* Power-PC
* StrongARM (the module worked fine on an IPAQ system)

The module should build with any perl from 5.005 up to the latest
development version. It will also build with perl 5.004, but then
the test suite cannot be run completely.

Multithreaded perl binaries are explicitly supported, as the module
is intended to be thread-safe.


## Features

You can enable or disable certain features at compile time by adding
options to the `Makefile.PL` call. However, you can safely leave them
at their default.

Available features are `debug` to build the module with debugging
support and `ieeefp` to explicitly enable or disable IEEE floating
point support.

The `debug` feature depend on how your perl binary was built. If it
was built with the `DEBUGGING` flag, the `debug` feature is enabled,
otherwise it is disabled by default.

The `ieeefp` feature depends on how your machine stores floating point
values. If they are stored in IEEE format, this feature will be enabled
automatically. You should really only change the default if you know
what you're doing.

You can enable or disable features explicitly by adding the arguments

    enable-feature
    disable-feature

to the Makefile.PL call. To explicitly build the module with debugging
enabled, you would say:

    perl Makefile.PL enable-debug

This will still allow you to pass other standard arguments to
`Makefile.PL`, like

    perl Makefile.PL enable-debug OPTIMIZE=-O3


## Copyright

Copyright (c) Marcus Holland-Moritz. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The ucpp library is (c) 1998-2002 Thomas Pornin. For license
and redistribution details refer to 'ctlib/ucpp/README'.

Portions copyright (c) 1989, 1990 James A. Roskind.
