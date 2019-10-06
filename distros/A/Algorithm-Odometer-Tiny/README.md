Algorithm-Odometer-Tiny
=======================

This is the distribution of the Perl modules
[`Algorithm::Odometer::Tiny`](https://metacpan.org/pod/Algorithm::Odometer::Tiny) and
[`Algorithm::Odometer::Gray`](https://metacpan.org/pod/Algorithm::Odometer::Gray) and.

It is a Perl extension for generating "base-N odometer" permutations.

Please see the modules' documentation (POD) for details (try the command
`perldoc lib/Algorithm/Odometer/Tiny.pm`) and the file `Changes` for version
information.

[![Travis CI Build Status](https://travis-ci.org/haukex/Algorithm-Odometer-Tiny.svg)](https://travis-ci.org/haukex/Algorithm-Odometer-Tiny)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/haukex/Algorithm-Odometer-Tiny?svg=true)](https://ci.appveyor.com/project/haukex/algorithm-odometer-tiny)
[![Coverage Status](https://coveralls.io/repos/github/haukex/Algorithm-Odometer-Tiny/badge.svg)](https://coveralls.io/github/haukex/Algorithm-Odometer-Tiny)
[![Kwalitee Score](https://cpants.cpanauthors.org/dist/Algorithm-Odometer-Tiny.svg)](https://cpants.cpanauthors.org/dist/Algorithm-Odometer-Tiny)
[![CPAN Testers](https://badges.zero-g.net/cpantesters/Algorithm-Odometer-Tiny.svg)](http://matrix.cpantesters.org/?dist=Algorithm-Odometer-Tiny)

Installation
------------

To install this module type the following:

	perl Makefile.PL
	make
	make test
	make install

If you are running Windows, you may need to use `dmake`, `nmake`, or `gmake`
instead of `make`.

Dependencies
------------

Requirements: Perl v5.6 or higher (a more current version is *strongly*
recommended) and several of its core modules; users of older Perls may need
to upgrade some core modules.

The full list of required modules can be found in the file `Makefile.PL`.
This module should work on any platform supported by these modules.

Author, Copyright and License
-----------------------------

Copyright (c) 2019 Hauke Daempfling <haukex@zero-g.net>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the Perl Artistic License,
which should have been distributed with your copy of Perl.
Try the command `perldoc perlartistic` or see
<http://perldoc.perl.org/perlartistic.html>

