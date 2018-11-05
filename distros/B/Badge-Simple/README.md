Badge-Simple
============

This is the distribution of the Perl module
[`Badge::Simple`](https://metacpan.org/pod/Badge::Simple).

It is a Perl extension for generating simple SVG badges, based
heavily on the style of [Shields.io](http://shields.io).

Please see the module's documentation (POD) for details (try the
command `perldoc lib/Badge/Simple.pm`) and the file `Changes` for
version information.

[![Travis CI Build Status](https://travis-ci.org/haukex/Badge-Simple.svg)](https://travis-ci.org/haukex/Badge-Simple)
[![CPAN Testers](https://badges.zero-g.net/cpantesters/Badge-Simple.svg)](http://matrix.cpantesters.org/?dist=Badge-Simple)

Installation
------------

To install this distribution type the following:

	perl Makefile.PL
	make
	make test
	make install

If you are running Windows, you may need to use `dmake`, `nmake`,
or `gmake` instead of `make`.

Dependencies
------------

Requirements: Perl v5.6 or higher (a more current version is
*strongly* recommended) and several of its core modules; users of
older Perls may need to upgrade some core modules.

The CPAN distributions
[`Imager`](https://metacpan.org/release/Imager) and
[`XML-LibXML`](https://metacpan.org/release/XML-LibXML)
are also required.

The full list of required modules can be found in the file
`Makefile.PL`. This module should work on any platform supported
by these modules.

Author, Copyright and License
-----------------------------

Copyright (c) 2018 Hauke Daempfling <haukex@zero-g.net>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the Perl Artistic License,
which should have been distributed with your copy of Perl.
Try the command `perldoc perlartistic` or see
<http://perldoc.perl.org/perlartistic.html>

[Shields.io](http://shields.io) is licensed under Creative Commons
CC0 Public Domain Dedication.
See <https://github.com/badges/shields/blob/master/LICENSE>.

This distribution contains the file `DejaVuSans.ttf`, its license
terms can be found in the file `DejaVuSans_LICENSE.txt`. The
license terms can also be accessed at
<https://dejavu-fonts.github.io/License.html>.

