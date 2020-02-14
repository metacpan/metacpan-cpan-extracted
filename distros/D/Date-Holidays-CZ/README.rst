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

To install this module, first install all the dependencies listed in
``Build.PL``, and then type the following::

   perl Build.PL
   ./Build
   ./Build test
   sudo ./Build install


Submitting patches
------------------

Before you submit a patch, read carefully the file ``CONTRIBUTING.rst`` in the
same directory as this ``README.rst``.

