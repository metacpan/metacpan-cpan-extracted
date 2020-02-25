# NAME

App-gimpgitbuild - build GIMP from git

# VERSION

version 0.4.0

# SYNOPSIS

    gimpgitbuild build

# DESCRIPTION

gimpgitbuild is a command line utility to automatically build
[GIMP](https://www.gimp.org/) (= the "GNU Image Manipulation Program")
and some of its dependencies from its version control git repositories:
[https://developer.gimp.org/git.html](https://developer.gimp.org/git.html) .

Use it only if your paths and environment does not contain too many
nasty characters because we interpolate strings into the shell a lot.

So far, it is quite opinionated, but hopefully we'll allow for better
customization using [https://en.wikipedia.org/wiki/Environment\_variable](https://en.wikipedia.org/wiki/Environment_variable)
in the future.

## HISTORY

This utility evolved from an [old bash version](https://github.com/shlomif/shlomif-computer-settings/blob/db468a5d6190bce053af1621b30e7dfd673be43f/shlomif-settings/build-scripts/build/gimp-git-all-deps.bash)
and a [rewrite in perl 5](https://github.com/shlomif/shlomif-computer-settings/blob/master/shlomif-settings/build-scripts/build/gimp-git-all-deps.pl) .

# SEE ALSO

- [https://www.gimp.org/](https://www.gimp.org/)

# SUPPORT

## Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

- MetaCPAN

    A modern, open-source CPAN search engine, useful to view POD in HTML format.

    [https://metacpan.org/release/App-gimpgitbuild](https://metacpan.org/release/App-gimpgitbuild)

- RT: CPAN's Bug Tracker

    The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

    [https://rt.cpan.org/Public/Dist/Display.html?Name=App-gimpgitbuild](https://rt.cpan.org/Public/Dist/Display.html?Name=App-gimpgitbuild)

- CPANTS

    The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

    [http://cpants.cpanauthors.org/dist/App-gimpgitbuild](http://cpants.cpanauthors.org/dist/App-gimpgitbuild)

- CPAN Testers

    The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

    [http://www.cpantesters.org/distro/A/App-gimpgitbuild](http://www.cpantesters.org/distro/A/App-gimpgitbuild)

- CPAN Testers Matrix

    The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

    [http://matrix.cpantesters.org/?dist=App-gimpgitbuild](http://matrix.cpantesters.org/?dist=App-gimpgitbuild)

- CPAN Testers Dependencies

    The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

    [http://deps.cpantesters.org/?module=App::gimpgitbuild](http://deps.cpantesters.org/?module=App::gimpgitbuild)

## Bugs / Feature Requests

Please report any bugs or feature requests by email to `bug-app-gimpgitbuild at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/Public/Bug/Report.html?Queue=App-gimpgitbuild](https://rt.cpan.org/Public/Bug/Report.html?Queue=App-gimpgitbuild). You will be automatically notified of any
progress on the request by the system.

## Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

[https://github.com/shlomif/App-gimpgitbuild](https://github.com/shlomif/App-gimpgitbuild)

    git clone git://github.com/shlomif/App-gimpgitbuild.git

# AUTHOR

Shlomi Fish <shlomif@cpan.org>

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/shlomif/App-gimpgitbuild/issues](https://github.com/shlomif/App-gimpgitbuild/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Shlomi Fish.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004
