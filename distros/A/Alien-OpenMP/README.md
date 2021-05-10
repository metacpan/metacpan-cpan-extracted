# NAME

Alien::OpenMP - Encapsulate system info for OpenMP

# SYNOPSIS

    use Alien::OpenMP;
    say Alien::OpenMP->cflags; # e.g. -fopenmp if GCC
    say Alien::OpenMP->lddlflags; # e.g. -fopenmp if GCC

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
