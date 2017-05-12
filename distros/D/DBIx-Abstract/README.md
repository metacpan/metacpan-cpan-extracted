Deprecated
----------

It is highly recommended that you use something like SQL::Abstract, which
was inspired by this module.  Or even DBIx::Class (which uses
SQL::Abstract for it's query syntax).  They're maintained and widely used.

DBIx::Abstract
--------------

This module provides methods for doing manipulating database tables This
module provides methods retreiving and storing data in SQL databases.
It provides methods for all of the more important SQL commands (like
SELECT, INSERT, REPLACE, UPDATE, DELETE).

It endeavors to produce an interface that will be intuitive to those already
familiar with SQL.

Notable features include:

  * data_source generation for some DBD drivers.
  * Can check to make sure the connection is not stale and reconnect
    if it is.
  * Controls statement handles for you.
  * Can delay writes.
  * Generates complex where clauses from hashes and arrays.
  * Shortcuts (convenience functions) for some common cases. (Like
    select_all_to_hashref.)

COPYRIGHT
---------

Portions copyright 2001-2002-2014 by Rebecca Turner

Portions copyright 2000-2001 by Adelphia Business Solutions

Portions copyright 1998-2000 by the Maine Internetworks (MINT)

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

PREREQUISITES
-------------

DBI (and a working DBD driver of course)

HOW TO BUILD
------------

perl Makefile.PL
make
make test

HOW TO INSTALL
--------------

make install

