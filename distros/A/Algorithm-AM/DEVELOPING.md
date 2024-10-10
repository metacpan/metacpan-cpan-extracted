# Developing Algorithm::AM

To manage module installation, I recommend you install [cpanm](https://cpanmin.us/).

To install dependencies:

    cpanm --notest --installdeps .

(`notest` is not strictly necessary, but there are lots of dependencies so at least one tends to fail).

To build:

    perl Makefile.PL
    make

To run tests:

    make test

If you are on Windows, I recommend using Strawberry Perl, in which case `make` above should be replaced with `gmake`.

# Releasing

The release process and a ton of authoring tests are managed using dzil. To install author dependencies:

    dzil authordeps --missing | cpanm --notest
    dzil listdeps --author --missing | cpanm --notest

Then, to run the author tests:

    dzil test --author --release

To release the module:

* update and commit `Changes`
* run `dzil release` (you'll need the PAUSE username and password)
* if the release succeeded:
    * `git tag <tag>`
    * `git push --tags`
    * create release with the given tag on GitHub
