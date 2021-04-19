# NAME

Alien::OpenMP - Encapsulate system info for OpenMP

# SYNOPSIS

    use Alien::OpenMP;
    say Alien::OpenMP->cflags; # e.g. -fopenmp if GCC
    say Alien::OpenMP->lddlflags; # e.g. -fopenmp if GCC

# DESCRIPTION

Encapsulates knowledge of per-compiler or per-environment information
so consuming modules don't need to know. Won't install if no OpenMP
environment available.

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
