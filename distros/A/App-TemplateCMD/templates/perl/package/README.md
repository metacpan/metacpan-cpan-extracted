[% module = module || 'module' -%]
[% file     = module -%]
[% IF file.match('::') -%]
[%     file = file.replace('::', '/') -%]
[% END -%]
[% file = file _ '.pm' -%]
[% package  = module -%]
[% IF package.match('::') -%]
[%     package = package.replace('::', '-') -%]
[% END -%]
[% IF travis %]
[![Build Status](https://travis-ci.org/ivanwills/[% package %].svg?branch=master)](https://travis-ci.org/ivanwills/[% package %]?branch=master)
[![Coverage Status](https://coveralls.io/repos/ivanwills/[% package %]/badge.svg?branch=master)](https://coveralls.io/r/ivanwills/[% package %]?branch=master)
[% END %]
[% package %]
=============

The README is used to introduce the module and provide instructions on
how to install the module, any machine dependencies it may have (for
example C compilers and installed libraries) and any other information
that should be provided before the module is installed.

A README file is required for CPAN modules since CPAN extracts the README
file from a module distribution so that people browsing the archive
can use it to get an idea of the module's uses. It is usually a good idea
to provide version information here so that people can decide whether
fixes for the module are worth downloading.

INSTALLATION
============

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

SUPPORT AND DOCUMENTATION
=========================

After installing, you can find documentation for this module with the
perldoc command.

    perldoc [% module %]

You can also look for information at:

    RT, CPAN's request tracker
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=[% package %]

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/[% package %]

    CPAN Ratings
        http://cpanratings.perl.org/d/[% package %]

    Search CPAN
        http://search.cpan.org/dist/[% package %]/

    Source Code
        git://github.com/ivanwills/[% package %].git

COPYRIGHT AND LICENCE
=====================

Copyright (C) [% year %] [% contact.fullname %]

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

