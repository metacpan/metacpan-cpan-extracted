# app-cpanmodulesite

Automatically create a GitHub Pages site for a CPAN module

[![Build Status](https://github.com/davorg-cpan/app-cpanmodulesite/actions/workflows/perltest.yml/badge.svg?branch=main)](https://github.com/davorg-cpan/app-cpanmodulesite/actions/workflows/perltest.yml) [![Coverage Status](https://coveralls.io/repos/github/davorg-cpan/app-cpanmodulesite/badge.svg?branch=main)](https://coveralls.io/github/davorg-cpan/app-cpanmodulesite?branch=main)

## Description

For more information about this module and the motivation behind it, please see
[this blog post](https://dev.to/davorg/easier-web-sites-for-cpan-modules-1nn4).

## Installation

This module can be installed using any of the standard methods for installing
CPAN modules. These include:

* cpanminus - `cpanm App::CPANModuleSite`
* cpan - `cpan App::CPANModuleSite`

Or the old method of downloading the tarball from the
[CPAN page](https://metacpan.org/release/App-CPANModuleSite) and running these steps:

* `perl Makefile.PL`
* `make`
* `make test`
* `sudo make install`

Once installed you can access the documentation for the module by running:

* `perldoc App::CPANModuleSite`

But for more people you'll be using the bundled `mksite` command-line tool and
you can get the documentation for that by running:

* `perldoc mksite`

## Module web site

As you might expect for a CPAN module that allows you to create web sites for
your CPAN modules, this module has a web site. It's at:

* [https://davorg.dev/app-cpanmodulesite](https://davorg.dev/app-cpanmodulesite)

## Author

This module was written by Dave Cross (dave@perlhacks.com) and he'd love to hear
your opinions on his work.
