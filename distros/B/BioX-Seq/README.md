BioX::Seq
=========

[![Build Status](https://travis-ci.org/jvolkening/p5-BioX-Seq.svg?branch=master)](https://travis-ci.org/jvolkening/p5-BioX-Seq)
[![Coverage Status](https://coveralls.io/repos/github/jvolkening/p5-BioX-Seq/badge.svg?branch=master)](https://coveralls.io/github/jvolkening/p5-BioX-Seq?branch=master)

BioX::Seq is a simple sequence class that can be used to represent
biological sequences. It was designed as a compromise between using simple
strings and hashes to hold sequences and using the rather bloated objects of
Bioperl. Features (or, depending on your viewpoint, bugs) include
auto-stringification and context-dependent transformations. It is meant
be used primarily as the return object of the BioX::Seq::Stream and
BioX::Seq::Fetch parsers, but
there may be occasions where it is useful in its own right.

BioX::Seq::Stream and BioX::Seq::Fetch can be used to read in sequence objects
in a streaming or random-access fashion from FASTA and FASTQ files.

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

    perldoc BioX::Seq

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
