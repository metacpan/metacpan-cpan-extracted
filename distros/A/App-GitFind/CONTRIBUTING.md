# Contributing to git-find

Thank you for your interest and help!

## Finding issues

* Start with issues labeled `hacktoberfest`.
* If you are relatively new to Perl, start with the issues that are
  _also_ labeled `good first issue`.

## Development

This project uses the standard Perl workflow.

Fork on GitHub, and then:

    git clone https://github.com/<your name>/git-find.git
    cd git-find

To build and test:

    perl Makefile.PL
    make
    make test

To test iteratively while developing, run:

    prove -l

If you are testing the parser, run

    make yapp && prove -l

to make sure the latest parser is compiled.

## Licensing

git-find is licensed under the MIT license.  As part of your first PR, please
add a "Portions copyright `your name`" line to the [LICENSE](LICENSE) file.
