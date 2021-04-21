# NAME

Alien::OpenMP - Encapsulate system info for OpenMP

# SYNOPSIS

    use Alien::OpenMP;
    say Alien::OpenMP->cflags;    # e.g. -fopenmp if gcc 
    say Alien::OpenMP->lddlflags; # e.g. -fopenmp if gcc 

# DESCRIPTION

This module encapsulates the knowledge required to compile OpenMP programs
`$Config{ccname}`. `C`, `Fortran`, and `C++` programs annotated
with declarative OpenMP pragmas will still compile if the compiler (and
linker if this is a separate process) is not passed the appropriate flag
to enable OpenMP support. This is because all pragmas are hidden behind
full line comments (with the addition of OpenMP specific `sentinels`,
as they are called).

All compilers require OpenMP to be explicitly activated during compilation;
for example, GCC's implementation, `GOMP`, is invoked by the `-fopenmp`
flag.

Most major compilers support OpenMP, including: GCC, Intel, IBM,
Portland Group, NAG, and those compilers created using LLVM. GCC's OpenMP
implementation, `GOMP`, is available in all modern versions. Unfortunately,
while OpenMP is a well supported standard; compilers are not required to
use the same commandline switch to activate support. All compilers that
support OpenMP use slightly different ways of invoking it.

## Compilers Supported by this module

At this time, the following compilers are supported:

- `gcc`

    `-fopenmp` enables OpenMP support in via compiler and linker:

        gcc -fopenmp ./my-openmp.c -o my-openmp.x

## Note On Compiler Support

If used for an unsupported compiler, `ExtUtils::MakeMaker::os_unsupported` is
invoked, which results an exception propagating from this method being raised
with the value of `qq{OS unsupported\n}` (note the new line).

This module assumes that the compiler in question is the same one used to
build `perl`. Since the vast majority of `perl`s are building using `gcc`,
initial support is targeting it. However, like `perl`, many other compilers
may be used.

Adding support for a new compiler should be straightforward; please section on
contributing, below.

## Contributing

The biggest need is to support additional compilers. OpenMP is a well established
standard across compilers, but there is guarantee that all compilers will use the
same flags, library names, or header files. It should also be easy to contribute
a patch to add this information, which is effectively its purpose. At the very least,
please create an issue at the official issue tracker to request this support, and
be sure to include the relevant information. Chances are the maintainers of this
module do not have access to an unsupported compiler.

# METHODS

- `cflags`

    Returns flag used by a supported compiler to enable OpenMP. If not support,
    an empty string is provided since by definition all OpenMP programs must compile
    because OpenMP pramgas are annotations hidden behind source code comments.

    Example, GCC uses, `-fopenmp`.

- `lddlflags`

    Returns the flag used by the linker to enable OpenMP. This is usually the same
    as what is returned by `cflags`.

    Example, GCC uses, `-fopenmp`, for this as well.

- `_check_libs`

    Internal method.

    Returns an array reference of libraries, e.g., `gomp` for `gcc`. It is meant
    specifically as an internal method to support [Devel::CheckLib](https://metacpan.org/pod/Devel%3A%3ACheckLib) in this module's
    `Makefile.PL`.

- `_check_headers`

    Internal method.

    Returns an array reference of header files, e.g., `omp.h` for `gcc`. It is meant
    specifically as an internal method to support [Devel::CheckLib](https://metacpan.org/pod/Devel%3A%3ACheckLib) in this module's
    `Makefile.PL`.

# AUTHOR

OODLER 577 <oodler@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2021 by oodler577

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

# SEE ALSO

[PDL](https://metacpan.org/pod/PDL), [OpenMP::Environment](https://metacpan.org/pod/OpenMP%3A%3AEnvironment),
[https://gcc.gnu.org/onlinedocs/libgomp/index.html](https://gcc.gnu.org/onlinedocs/libgomp/index.html).
