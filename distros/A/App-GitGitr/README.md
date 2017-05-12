# NAME

gitgitr - Automatically fetch and build the most recent git.

# VERSION

version 0.904

# SYNOPSIS

    gitgitr
      -- fetches and builds the most recent version of git

    gitgitr -t
      -- fetches and builds the most recent version of git, and runs the
         test suite prior to installation

    gitgitr -v 1.8.0
      -- fetches and builds version 1.8.0 of git

# DESCRIPTION

`gitgitr` is a tiny utility to simplify building the most recent (or,
really, any arbitrary) version of `git`. This is something you
probably only really need if you're obsessive about running the most
recent version of `git`, or if you maintain something like
[Git::Wrapper](https://metacpan.org/pod/Git::Wrapper), where the ability to quickly install a particular
`git` version comes up way more often than you would like.

# OPTIONS

- --help / -h

    Displays basically the same information you're currently soaking in.

- --no\_symlink / -N

    Don't symlink `/opt/git` to the new build directory

- --prefix / -p

    Installation prefix for the current build. Defaults to
    `/opt/git-$GIT_VERSION_NUMBER`

- --reinstall / -r

    By default, `gitgitr` will not build a version that's already
    installed. This flag will force it to build a version even if it is
    already preset.

- --run\_tests / -t

    Makes `gitgitr` run the `git` test suite after building and before
    installing. If the test suite fails, the build will not be
    installed. Disabled by default because the test suite takes a really
    long time to run.

- --verbose / -V

    Makes `gitgitr` be a lot more chatty about what it's doing

- --version / -v

    Specifies what version of `git` to build. Defaults to the most recent
    version as found on the front page of [http://git-scm.com](http://git-scm.com)

# SEE ALSO

- [http://git-scm.com](http://git-scm.com)

# AUTHOR

John SJ Anderson <genehack@genehack.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
