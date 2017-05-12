Class/Meta version 0.66
=======================

Class::Meta provides an interface for automating the creation of Perl classes
with attribute data type validation. It differs from other such modules in
that it includes an introspection API that can be used as a unified interface
for all Class::Meta-generated classes. In this sense, it is an implementation
of the "Facade" design pattern.

Justification
-------------

One might argue that there are already too many class automation and parameter
validation modules on CPAN. And one would be right. They range from simple
accessor generators, such as Class::Accessor, to simple parameter validators,
such as Params::Validate, to more comprehensive systems, such as
Class::Contract and Class::Tangram. But, naturally, none of them could do
exactly what I needed.

What I needed was an implementation of the "Facade" design pattern. Okay, this
isn't a facade like the GOF meant it, but it is in the respect that it
creates classes with a common API so that objects of these classes can all be
used identically, calling the same methods on each. This is done via the
implementation of an introspection API. So the process of creating classes
with Class::Meta not only creates attributes and accessors, but also creates
objects that describe those classes. Using these descriptive objects, client
applications can determine what to do with objects of Class::Meta-generated
classes. This is particularly useful for user interface code.

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

* Data::Types 0.05 or later
* Class::ISA 0.35 or later

The test suite requires:

( Test::Simple 0.17 or later

Copyright and Licence
---------------------

Copyright (c) 2002-2011, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
