App-cpanminus-reporter
======================

[![Build status](https://travis-ci.org/garu/App-cpanminus-reporter.svg?branch=master)](https://travis-ci.org/garu/App-cpanminus-reporter)
[![Coverage Status](https://coveralls.io/repos/garu/App-cpanminus-reporter/badge.png)](https://coveralls.io/r/garu/App-cpanminus-reporter)
[![CPAN version](https://badge.fury.io/pl/App-cpanminus-reporter.png)](http://badge.fury.io/pl/App-cpanminus-reporter)


This distribution creates a tiny app called `cpanm-reporter` that lets
you send cpanm output to CPAN Testers.

Setup
-----

New to CPAN Testers' reporting? No problem! Just run:

    > cpanm-reporter --setup

And we will walk you through everything you need :)

(if you already use CPAN::Reporter, you can safely skip the setup)

Usage
-----

Call cpanm as you normally would:

    > cpanm Moose Catalyst::Runtime Data::Printer ...

then, just call cpanm-reporter:

    > cpanm-reporter


Optional Arguments
------------------

    --build_dir=PATH       Where your build directory is, containing
                           each dist's subdir. Default: $HOME/.cpanm/latest-build

    --build_logfile=PATH   Where the build.log is. Default: $BUILD_DIR/build.log

    --verbose (or -v)      Extra output

    --quiet (or -q)        As little output as possible (voids -v)

    --setup                Sets up the CPAN Testers configuration for you

    --only=A::B,C::D,...   Only send reports for these modules

    --exclude=A::B,...     Don't send reports for these modules

    --dry-run              Prepare, but do not actually send reports

    --skip-history         Skips reading/writing to CPAN Testers' history file


For more information, please refer to the full documentation at:

    https://metacpan.org/release/App-cpanminus-reporter

That same documentation will also be available to you after installation
at the command line. Just type:

   perldoc cpanm-reporter

after installing this module.

Installation
------------

To install this module via cpanm:

    > cpanm App::cpanminus::reporter

Or, at the cpan shell:

    cpan> install App::cpanminus::reporter

If you wish to install it manually, download and unpack the tarball and
run the following commands:

	perl Makefile.PL
	make
	make test
	make install


Thank you for using cpanm-reporter! Please let me know of potential
issues, bugs and wishlists :)


COPYRIGHT AND LICENCE

Copyright (C) 2012-2015, Breno G. de Oliveira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
