Crypt::SecretBuffer
-------------------

### About

This module provides a buffer object which attempts to prevent the Perl core
from accidentally retaining copies of its data.  It is similar in purpose to
SecureString of the .NET framework.  It also provides some utilities for
loading and exporting the data without the value getting copied into a scalar.

### Installing

When distributed, all you should need to do is run

    perl Makefile.PL
    make install

or better,

    cpanm Crypt-SecretBuffer.tar.gz

or from CPAN:

    cpanm Crypt::SecretBuffer

### Developing

However, if you're trying to build from a fresh Git checkout, you'll need
the Dist::Zilla tool (and many plugins) to create the Makefile.PL.

    cpanm Dist::Zilla
    dzil authordeps --missing | cpanm
    dzil build

While Dist::Zilla takes the busywork and mistakes out of module authorship,
it fails to address the need of XS authors to easily compile XS projects
and run single test cases rather than the whole test suite.  For this, you
might find the following script handy:

    ./dzil-prove t/01-ctor.t  # or any other test case

which runs "dzil build" to get a clean dist, then enters the build directory
and runs "perl Makefile.PL" to compile the XS, then "prove -lvb t/01-ctor.t".

### Copyright

This software is copyright (c) 2025 by Michael Conrad

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
