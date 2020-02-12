Date::Holidays::CZ
==================

.. image:: https://travis-ci.org/smithfarm/date-holidays-cz.svg?branch=master
    :target: https://travis-ci.org/smithfarm/date-holidays-cz

.. image:: https://badge.fury.io/pl/Date-Holidays-CZ.svg
    :target: https://badge.fury.io/pl/Date-Holidays-CZ


This module creates a list of Czech holidays in a given year.

Holidays that occur on weekends can be excluded from the generated list.

The generated list can be freely formatted using regular strftime() format
definitions.


Installation
------------

To install this module type the following::

   perl Build.PL
   ./Build
   ./Build test
   sudo ./Build install


Submitting patches
------------------

Patches are welcome. If you can, please fork the project on github::

    http://github.com/smithfarm/date-holidays-cz.git

and open a Pull Request.


Dependencies
------------

This module requires these other modules and libraries::

* Date::Calc 5.0
* POSIX, Time::Local (from the standard Perl distribution)

