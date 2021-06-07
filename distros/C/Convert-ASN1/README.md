# Convert::ASN1

Convert::ASN1 is a perl library for encoding/decoding data using
ASN.1 definitions

The ASN.1 parser is not a complete implementation of the
[ASN.1](http://www.itu.int/ITU-T/studygroups/com17/languages/X.680-0207.pdf)
specification. It has been built over time and features have been
added on an as-needed basis.

## Latest Release

The latest release can be found on http://www.cpan.org/ at
http://search.cpan.org/dist/Convert-ASN1/

The documentation is at http://search.cpan.org/perldoc?Convert::ASN1

## Installing

Install with your favorite CPAN install manager, eg

    cpanm Convert::ASN1

If you do not have cpanm installed you can run

    curl -s -L http://cpanmin.us | perl - Convert::ASN1

## Contributing

### Git

The preferred method of contribution is by forking a repository on
github.

If you are not familiar with working with forked repositories please
read http://help.github.com/fork-a-repo/ for details on how to setup
your fork.

Try to avoid submitting to the master branch in your fork, it is
useful to keep that following the main repository and if I decide
to cherry-pick or fixup any commit you submit in a pull request you
will have tracking issues later

To start a branch for fixes do the following, assuming you have the
origin and upstream remotes setup as in the guide linked to above.

    git fetch upstream git checkout -b mybranch upstream/master

this will checkout a new branch called _mybranch_ from the latest
code in the master branch of the upstream repository.

Once you have finished push that branch to your origin repository
with

    git push -u origin HEAD

The -u will setup branch tracking so if you later add more commits
a simple

    git push

is enough to push those commits.

Once you have pushed the branch to github, send a pull as described
at http://help.github.com/send-pull-requests/

### Dist::Zilla

The release is developed using
[Dist::Zilla](http://search.cpan.org/perldoc?Dist::Zilla)

you will need to install

    cpanm Dist::Zilla

once you have the base install of Dist::Zilla run

    dzil authordeps --missing | cpanm dzil listdeps --missing | cpanm

### perl-byacc

If you need to make changes to the parser then you will need to
build perl-byacc1.8.2. You can fetch the source from
[perl-byacc1.8.2.tar.gz](http://www.cpan.org/src/misc/perl-byacc1.8.2.tar.gz)

With that built and available in your $PATH as byacc the parser can
be compiled with

    perl mkparse parser.y lib/Convert/ASN1/parser.pm

## License

This software is copyright (c) 2000-2012 by Graham Barr.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

