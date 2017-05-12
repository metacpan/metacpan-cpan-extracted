Apache/FakeTable version 0.06
=============================

This class emulates the behavior of the
[Apache::Table](http://search.cpan.org/perldoc?Apache::Table) class.

Apache::FakeTable is designed to behave exactly like Apache::Table, and
differs in only one respect. When a given key has multiple values in an
Apache::Table object, one can fetch each of the values for that key using
Perl's each operator:

    while (my ($k, $v) = each %$table) {
        push @cookies, $v if lc $k eq 'set-cookie';
    }

If anyone knows how Apache::Table does this, let us know! In the meantime, use
get() or do() to get at all of the values for a given key (they're much more
efficient, anyway).

Installation
------------

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
Earlier versions of Perl will need Test::More, part of the Test::Simple
distribution, in order to successfullly run ./Build test.

Copyright and Licence
---------------------

Copyright (c) 2003-2011, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
