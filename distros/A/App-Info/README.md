App/Info version 0.57
=====================

App::Info provides a generalized interface for providing metadata about
software packages installed on a system. The idea is that App::Info subclasses
can be used in Perl application installers in order to determine whether
software dependencies have been fulfilled, and to get necessary metadata about
those software packages.

App::Info provides an event model for handling events triggered by App::Info
subclasses. The events are classified as "info", "error", "unknown", and
"confirm" events, and multiple handlers may be specified to handle any or all
of these event types. This allows App::Info clients to flexibly handle events
in any way they deem necessary. Implementing new event handlers is
straight-forward, and use the triggering of events by App::Info subclasses is
likewise kept easy-to-use.

A few sample App::Info and App::Info::Handler (event handling) subclasses are
provided with the distribution, but others are invited to write their own
subclasses and contribute them to the CPAN. Contributors are welcome to extend
their subclasses to provide more information relevant to the application for
which data is to be provided (see App::Info::HTTPD::Apache for an example),
but are encouraged to, at a minimum, implement the methods defined by the
App::Info abstract base class relevant to the category of software they're
managing, e.g. App::Info::HTTPD or App::Info::RDBMS. New categories will be
added as needed.

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

This module requires these other modules and libraries:

* File::Spec
* Test::More -- For testing only -- part of the Test::Simple distribution.

COPYRIGHT AND LICENCE

Copyright (c) 2002-2011, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
