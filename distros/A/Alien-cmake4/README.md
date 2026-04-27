# NAME

Alien::cmake4 - Find or download or build cmake 4

# SYNOPSIS

From Perl:

    use Alien::cmake4;
    use Env qw(@PATH);
    
    unshift @PATH, Alien::cmake4->bin_dir;
    system Alien::cmake4->exe, ...;

# DESCRIPTION

This [Alien](https://metacpan.org/pod/Alien) distribution provides an external dependency on the build tool `cmake`
version 4.x.x.  `cmake` is a popular alternative to autoconf.

# METHODS

## bin\_dir

    my @dirs = Alien::cmake4->bin_dir;

List of directories that need to be added to the `PATH` in order for `cmake` to work.

## exe

    my $exe = Alien::cmake4->exe;

The name of the `cmake` executable.

# HELPERS

## cmake4

    %{cmake4}

The name of the `cmake` executable.

# SEE ALSO

- [Alien::Build::Plugin::Build::CMake](https://metacpan.org/pod/Alien%3A%3ABuild%3A%3APlugin%3A%3ABuild%3A%3ACMake)

    [Alien::Build](https://metacpan.org/pod/Alien%3A%3ABuild) plugin for `cmake`  This will automatically pull in Alien::cmake3 if you
    need it.

- [Alien::CMake](https://metacpan.org/pod/Alien%3A%3ACMake)

    This is an older distribution that provides an alienized `cmake`.  It is different in
    these ways:

    - [Alien::cmake3](https://metacpan.org/pod/Alien%3A%3Acmake3) is based on [alienfile](https://metacpan.org/pod/alienfile) and [Alien::Build](https://metacpan.org/pod/Alien%3A%3ABuild)

        It integrates better with [Alien](https://metacpan.org/pod/Alien)s that are based on that technology.

    - [Alien::cmake3](https://metacpan.org/pod/Alien%3A%3Acmake3) will provide version 3.x.x

        [Alien::CMake](https://metacpan.org/pod/Alien%3A%3ACMake) will provide 2.x.x on some platforms where more recent binaries are not available.

    - [Alien::cmake3](https://metacpan.org/pod/Alien%3A%3Acmake3) will install on platforms where there is no system `cmake` and no binary `cmake` provided by cmake.org

        It does this by building `cmake` from source.

    - [Alien::cmake3](https://metacpan.org/pod/Alien%3A%3Acmake3) is preferred

        In the opinion of the maintainer of both [Alien::cmake3](https://metacpan.org/pod/Alien%3A%3Acmake3) and [Alien::CMake](https://metacpan.org/pod/Alien%3A%3ACMake) for these reasons.

# ENVIRONMENT

- ALIEN\_INSTALL\_TYPE

    This is the normal [Alien::Build](https://metacpan.org/pod/Alien%3A%3ABuild) environment variable and you can set it to one of
    `share`, `system` or `default`.

- ALIEN\_CMAKE\_FROM\_SOURCE

    If set to true, and if a share install is attempted, [Alien::cmake4](https://metacpan.org/pod/Alien%3A%3Acmake4) will not try a
    binary share install (even if available), and instead a source share install.

# CAVEATS

If you do not have a system `cmake` version 4.x.x available, then a share install
will be attempted.

Binary share installs are attempted on platforms for which the latest version of `cmake`
are provided.  As of this writing, this includes: Windows (32/64 bit), macOS
(intel/arm universal) and Linux (intel/arm 64 bit).  No checks are made to ensure that
your platform is supported by this binary installs.  Typically the same versions
supported by the operating system vendor and supported by `cmake`, so that should not
be a problem.  If you are using an operating system not supported by its vendor
Please Stop That, this is almost certainly a security vulnerability.

That said if you really do need [Alien::cmake4](https://metacpan.org/pod/Alien%3A%3Acmake4) on an unsupported system,
you have some options:

- Install system version of `cmake`

    If you can find an older version of `cmake` 4.x.x that is supported by your operating
    system.

- Force a source code install

    Set the `ALIEN_CMAKE_FROM_SOURCE` environment variable to a true value to build a
    share install from source.

Source share installs are attempted on platforms for which the latest version of
`cmake` are not available, like the various flavours of \*BSD.  This may not be ideal,
and if you can install a system version of `cmake` it may work better.

# AUTHOR

Author of Alien::cmake4: Michal Josef Špaček <skim@cpan.org>

Author of Alien::cmake3: Graham Ollis <plicease@cpan.org>

Contributors of Alien::cmake3:

Adriano Ferreira (FERREIRA)

Dagfinn Ilmari Mannsåker (ilmari)

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2024 by Graham Ollis.
This software is copyright (c) 2026 by Michal Josef Špaček.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
