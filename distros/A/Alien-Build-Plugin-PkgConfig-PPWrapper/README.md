# Alien::Build::Plugin::PkgConfig::PPWrapper [![Build Status](https://secure.travis-ci.org/shawnlaffan/Alien-Build-Plugin-PkgConfig-PPWrapper.png)](http://travis-ci.org/shawnlaffan/Alien-Build-Plugin-PkgConfig-PPWrapper)

Alien::Build plugin to ensure the pure perl PkgConfig is not run by the MSYS perl

# SYNOPSIS

       use alienfile
       share {
           #  other commands to download, unpack and build etc.,
           #  and then:
           plugin 'PkgConfig::PPWrapper';
       };

    1;

# DESCRIPTION

The pure perl PkgConfig script works well, but when called by
Alien::Build::Plugin::Build::Autoconf on Windows it is
called using the MSYS perl due to its shebang line.
This leads to issues with path separators in ```$ENV{PKG_CONFIG_PATH}```.

# NAME

Alien::Build::Plugin::PkgConfig::PPWrapper - Alien::Build plugin to ensure the pure perl PkgConfig is not run by the MSYS perl

# VERSION

version 0.01

# SEE ALSO

- [Alien::Build](https://metacpan.org/pod/Alien::Build)

# AUTHOR

Shawn Laffan <shawnlaffan@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Shawn Laffan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
