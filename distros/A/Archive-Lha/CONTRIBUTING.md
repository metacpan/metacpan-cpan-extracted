# Contributing to Archive::Lha

## Reporting Bugs

Please use the [GitHub issue tracker](https://github.com/nicomen/archive-lha/issues).
Include the Archive::Lha version, Perl version, and OS.

## Pull Requests

1. Fork the repository and create a feature branch from `main`
2. Add tests for any new functionality
3. Ensure the test suite passes: `perl Makefile.PL && make test`
4. Update `Changes` with a summary of your change
5. Open a pull request against `main`

## Running Tests

    perl Makefile.PL
    make
    prove -lvr t/

## Code Style

This is a Perl XS module. Follow the existing style in the source files.

## License

By contributing you agree that your work will be licensed under the same
terms as Perl itself (Artistic License 1.0 or GPL).
