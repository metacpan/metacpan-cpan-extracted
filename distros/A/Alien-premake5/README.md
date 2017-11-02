# NAME

Alien::premake5 - Build or find premake5

# SYNOPSIS

    use Alien::premake5;
    use Env qw( @PATH );

    unshift @ENV, Alien::premake5->bin_dir;
    my $premake = Alien::premake5->exe;
    system $premake, 'gmake';

# DESCRIPTION

Premake is a build tool that allows a software project to be described with a
single common build script, which can then be used to generate project files
for building under a wide variety of build environments.

**Alien::premake5** uses [Alien::Build](https://metacpan.org/pod/Alien::Build) to make it easier to use premake in a
Perl application or project.

This distribution will find an available version of `premake5`, or attempt to
build one from source.

# METHODS

- **exe**

        my $premake = Alien::premake5->exe;

    Returns the name of the premake executable. Currently, this should be
    `premake5`.

    When using the executable compiled by this distribution, you
    will need to make sure that the directories returned by `bin_dir` are added
    to your `PATH` environment variable. For more info, check the documentation
    of [Alien::Build](https://metacpan.org/pod/Alien::Build).

# HELPERS

- **premake5**

    The `%{premake5}` string will be interpolated by Alien::Build into the name
    of the premake5 executable (as returned by **exe**);

# SEE ALSO

- [https://premake.github.io/](https://premake.github.io/)

# CONTRIBUTIONS AND BUG REPORTS

Contributions of any kind are most welcome!

The main repository for this distribution is on
[Github](https://github.com/jjatria/Alien-premake5), which is where patches
and bug reports are mainly tracked. Bug reports can also be sent through the
CPAN RT system, or by mail directly to the developers at the addresses below,
although these will not be as closely tracked.

# AUTHOR

- José Joaquín Atria <jjatria@cpan.org>

# ACKNOWLEDGEMENTS

Special thanks to Graham Ollis for his help in the preparation of this
distribution.

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
