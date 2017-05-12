Bio::CIPRES
=========

[![Build Status](https://travis-ci.org/jvolkening/p5-Bio-CIPRES.svg?branch=master)](https://travis-ci.org/jvolkening/p5-Bio-CIPRES)
[![Coverage Status](https://coveralls.io/repos/github/jvolkening/p5-Bio-CIPRES/badge.svg?branch=master)](https://coveralls.io/github/jvolkening/p5-Bio-CIPRES?branch=master)
[![CPAN version](https://badge.fury.io/pl/Bio-CIPRES.svg)](https://badge.fury.io/pl/Bio-CIPRES)

`Bio::CIPRES` is an interface to the CIPRES REST API for running phylogenetic
analyses via the CIPRES service. Currently it provides general classes and
methods for job submission and handling - determination of the correct
parameters to submit is up to the user. Details of the available tools and
parameters can be found on the CIPRES website:

[CIPRES tool documentation](https://www.phylo.org/restusers/documentation.action)

Examples of module usage can be found in the `demo` directory of this
distribution.


INSTALLATION
------------

To install this module, run the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

SUPPORT AND DOCUMENTATION
-------------------------

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Bio::CIPRES

LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2014-2017 Jeremy Volkening <jdv@base2bio.com>

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 3 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

See the LICENSE file in the top-level directory of this distribution for the
full license terms.
