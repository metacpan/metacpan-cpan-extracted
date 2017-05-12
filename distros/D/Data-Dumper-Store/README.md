README
======

Data::Dumper::Store - persistent key-value storage engine based on Data::Dumper serialization mechanism and flat files.


SYNOPSIS
========

    my $store = Data::Dumper::Store->new(file => 'filename.txt');
    my $data = {
        foo => 'bar'
    };

    $store->init($data);
    # or
    $store->set('foo', 'bar');

    say $store->get('foo'); # prints "bar"
    # or
    say $store->set('foo', 'bar')->get('foo'); # prints "bar" too

    say $store->dump(); # == Dumper $store->{data};

    # save data to the file:
    $store->commit();

    # or
    $store->DESTROY;


INSTALL
=======

    $ sudo cpan Data::Dumper::Store

    ... or from tarball:

    $ perl Makefile.PL
    $ make test
    $ sudo make install

LICENSE AND COPYRIGHT
=====================

Copyright 2014 shootnix.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.