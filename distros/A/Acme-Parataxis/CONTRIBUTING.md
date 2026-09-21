# Contributing to Acme::Parataxis

Thanks for your interest in contributing! This guide covers how to set up a
development environment, run the test suite, and submit changes.

## Getting started

### Prerequisites

- Perl **5.40+** (the code uses native `class`/`method` syntax)
- A C compiler
- Recommended: `cpanm` (or `cpan`) to install development dependencies

### Install

From a clone of the repository:

    cpanm --installdeps .
    perl Build.PL
    ./Build

This builds `Acme::Parataxis` and installs a local xmake into `blib/`.

### Running the tests

    ./Build test

## Development workflow

This project uses **native Perl `class` syntax** (`use v5.40`). Please keep that style and avoid adding comments unless they clarify non-obvious behavior.

We use [Test2::V0](https://metacpan.org/pod/Test2::V0) for tests. Follow the existing test structure when adding coverage.

Before submitting, please:

1. **Run the full suite** and confirm it passes.
2. Format your code so it matches the surrounding style (the repo has a
   `[Code::TidyAll](https://metacpan.org/pod/Code::TidyAll)` configuration in `.tidyallrc`).
3. Add a changelog entry under `## [Unreleased]` in `Changes.md`.

If you change the public API of a class, update the corresponding `.pod` and any examples under `eg/`.

## Submitting changes

1. Fork the repository on GitHub.
2. Create a feature branch: `git checkout -b my-change`
3. Commit your changes with a clear, concise message (see the existing `git log` for style).
4. Push your branch and open a Pull Request against `main` (previously `master`).

Please make sure your PR:

- Describes the problem being solved
- References any related issue
- Includes tests for any new behavior
- Does not push version-number bumps or changelog edits unless they are part of the change (maintainers handle release versions).

## Reporting bugs

Open a [GitHub issue](https://github.com/sanko/Acme-Parataxis.pm/issues) with:

- Perl version (`perl -V`, `$^O`)
- A minimal, reproducible example
- The output you saw (and what you expected)

Security issues should be reported privately. See [SECURITY.md](SECURITY.md).

## Contact

- Maintainer: Sanko Robinson - <https://github.com/sanko>
- Repository: https://github.com/sanko/Acme-Parataxis.pm
