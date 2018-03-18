# CONTRIBUTING

Thank you for considering contributing to this distribution. This file
contains instructions that will help you work with the source code.

Please note that if you have any questions or difficulties, you can reach
the maintainer through the [issue
tracker](https://github.com/PerlDancer/Dancer-Session-Cookie/issues)
(preferred), or by emailing the releaser directly. You are not strictly
required to follow any of the steps in this document to submit a patch or
bug report; these are recommendations, intended to help you (and help us
help you faster).

Please also note that this plugin is for use with Dancer 1 which has been
superseded by Dancer 2, so it's possible that not all contributions can be
accepted.

## Getting the code

## Branching

Releases are prepared on the `release` branch, which is also the default Git
branch.  However, development takes place on the `master` branch, hence
patches should be based upon it.  Thus, after cloning the repository, one
should check out the `master` branch:

    $ git checkout master

Note that when you submit your pull request, you will need to ensure that
GitHub isn't comparing your branch to the `release` branch (which will do so
by default), however is comparing with the `master` branch, upon which you
will have based your patch.

## Installing the base dependencies

To install the dependencies, use
[cpanm](https://metacpan.org/pod/App::cpanminus):

    $ cpanm --installdeps .

Note that an upstream *development* dependency requires at least Perl 5.22,
hence you need to be using at least this version.  If you haven't done so
already, consider using [perlbrew](https://perlbrew.pl/).

## Running the basic test suite

Assuming that installing the dependencies went well, running the test suite
should then be as simple as

    $ prove -lr t

## Installing all development dependencies

The distribution is managed with
[Dist::Zilla](https://metacpan.org/release/Dist-Zilla), hence you will need
to install it before you can install the development dependencies:

    $ cpanm Dist::Zilla

Afterwards, you can install the author-specific dependencies like so:

    $ dzil authordeps --missing | cpanm

There are also additional dependencies necessary for testing and other
development.  Install these with

    $ dzil listdeps --author --missing | cpanm

## Running the full test suite

Now that all required dependencies have been installed, running the full
test suite should be as simple as:

    $ dzil test --author --release

## Travis

All pull requests for this distribution will be automatically tested by
[Travis](https://travis-ci.org/) and the build status will be reported on
the pull request page. If your build fails, please take a look at the
output.

## Contributor Names

If you send a patch or pull request, your name and email address will be
included in the documentation as a contributor (using the attribution on the
commit or patch), unless you specifically request for it not to be. If you
wish to be listed under a different name or address, you should submit a
pull request to the .mailmap file to contain the correct mapping.  [Check
here](https://github.com/git/git/blob/master/Documentation/mailmap.txt) for
more information on git's .mailmap files.

This document is based upon [maxmind's distribution CONTRIBUTING
documentation](https://github.com/maxmind/Dist-Zilla-PluginBundle-MAXMIND/blob/master/CONTRIBUTING.md).
