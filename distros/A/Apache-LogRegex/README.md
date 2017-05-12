Apache::LogRegex
================

*Parse a line from an Apache logfile into a hash*

Designed as a simple class to parse Apache log files. It will construct a regex that will parse the given log file format and can then parse lines from the log file line by line returning a hash of each line.

The field names of the hash are derived from the log file format. Thus if the format is '%a %t \"%r\" %s %b %T \"%{Referer}i\" ...' then the keys of the hash will be %a, %t, %r, %s, %b, %T and %{Referer}i.

Should these key names be unusable, as I guess they probably are, then subclass and provide an override rename_this_name() method that can rename the keys before they are added in the array of field names.

INSTALLATION
------------

    % perl Makefile.PL
    % make
    % make test
    % sudo make install

TEST FAILURES
-------------

The tests are there to make sure that nothing breaks when the code changes but may teach you little about how to use the code. 

TO DO
-----

More efficient and flexible API while maintaining the old one

BUGS
----

There was a test failure in Perl versions > 5.13 but that should be fixed now.

REQUIREMENTS
------------

* Developed under 5.6.1 but should work on anything 5+.
* Written completely in Perl. XS is not required.

THANKS
------
 
Peter Hickman wrote the original module and maintained it for several years. He kindly passed maintainership on to me. Most of the features of this module are the fruits of his work. If you find any bugs they are my doing.

AUTHOR
------

Original code by Peter Hickman <peterhi@ntlworld.com>

Additional code by Andrew Kirkpatrick <ubermonk@gmail.com>

LICENSE AND COPYRIGHT
---------------------

Original code copyright (c) 2004-2006 Peter Hickman. All rights reserved.

Additional code copyright (c) 2013 Andrew Kirkpatrick. All rights reserved.

This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.
