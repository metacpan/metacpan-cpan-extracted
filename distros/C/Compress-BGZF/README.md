Compress::BGZF
====

[![Tests](https://github.com/jvolkening/p5-Compress-BGZF/actions/workflows/tests.yml/badge.svg)](https://github.com/jvolkening/p5-Compress-BGZF/actions/workflows/tests.yml)
[![Coverage Status](https://coveralls.io/repos/github/jvolkening/p5-Compress-BGZF/badge.svg?branch=master)](https://coveralls.io/github/jvolkening/p5-Compress-BGZF?branch=master)
[![CPAN version](https://badge.fury.io/pl/Compress-BGZF.svg)](https://badge.fury.io/pl/Compress-BGZF)


A pure-Perl implementation of blocked gzip (BGZF)

INSTALLATION
------------

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install


DEPENDENCIES
------------

Compress::BGZF uses the following modules:

  * List::Util

  * Compress::Zlib

  * IO::Uncompress::RawInflate

  * IO::Compress::RawDeflate

These are already included in recent core perl distributions



COPYRIGHT AND LICENSE
---------------------

Copyright (C) 2015-2016 Jeremy Volkening <jdv@base2bio.com>

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 3 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

See the LICENSE file in the top-level directory of this distribution for the
full license terms.
