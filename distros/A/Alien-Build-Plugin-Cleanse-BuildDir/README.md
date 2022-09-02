# Alien::Build::Plugin::Cleanse::BuildDir [![Build Status](https://secure.travis-ci.org/shawnlaffan/Alien-Build-Plugin-Cleanse-BuildDir.png)](http://travis-ci.org/shawnlaffan/Alien-Build-Plugin-Cleanse-BuildDir)

Alien::Build plugin to cleanse the build dir

# SYNOPSIS

       use alienfile
       share {
           #  other commands to download, unpack and build etc.,
           #  and then:
           plugin 'Cleanse::BuildDir';
       };

    1;

# DESCRIPTION

This plugin deletes the build directory after the make phase.
This is useful if your alien has a large build size.  It was
developed because the [Alien::gdal](https://metacpan.org/pod/Alien::gdal) build footprint is enormous,
and was filling up disk space on cpan testers.

You should use it conditionally in your alienfile,
for example when you know the
build dir contents are not needed later.

Has no effect if you are running a non-share install,
or are using an out of source build
(although these are currently untested).

# NAME

Alien::Build::Plugin::Cleanse::BuildDir - Alien::Build plugin to cleanse the build dir

# VERSION

version 0.01

# SEE ALSO

- [Alien::Build](https://metacpan.org/pod/Alien::Build)

# AUTHOR

Shawn Laffan <shawnlaffan@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Shawn Laffan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
