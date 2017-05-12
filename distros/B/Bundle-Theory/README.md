Bundle/Theory version 1.08
==========================

This bundle installs all of the CPAN modules that Theory considers essential
whenever he's building a new system.

INSTALLATION

To install this module, type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you don't have Module::Build installed, type the following:

    perl Makefile.PL
    make
    make test
    make install

Dependencies
------------

This module requires no modules or libraries not already included with Perl.

Copyright and Licence
---------------------

Copyright (c) 2008-2011 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
