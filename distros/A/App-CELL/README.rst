=========
App::CELL
=========

.. image:: https://travis-ci.org/smithfarm/cell.svg?branch=master :target: https://travis-ci.org/smithfarm/cell

.. image:: https://badge.fury.io/pl/App-CELL.svg
    :target: https://badge.fury.io/pl/App-CELL

--------------------------------------------------------------------
Configuration, Error-handling, Localization, and Logging "framework"
--------------------------------------------------------------------


General Documentation
=====================

* http://metacpan.org/pod/App::CELL::Guide

* http://metacpan.org/pod/App::CELL
* http://metacpan.org/pod/App::CELL::Config
* http://metacpan.org/pod/App::CELL::Load
* http://metacpan.org/pod/App::CELL::Log
* http://metacpan.org/pod/App::CELL::Message
* http://metacpan.org/pod/App::CELL::Status
* http://metacpan.org/pod/App::CELL::Test
* http://metacpan.org/pod/App::CELL::Test::LogToFile


Contributor Documentation
=========================

All would-be contributors should first read ``CONTRIBUTING.rst``.


Maintainer Documentation
========================

Read on only if you are a maintainer of ``App::CELL``


How to build and run tests
--------------------------

First, install build and runtime dependencies. This can be done either by
installing packages from your favorite Linux distribution or direct from CPAN
using a tool such as ``cpanm``.

Second, build and install the distro:

    $ perl Build.PL ; ./Build ; sudo ./Build install

Third, run the tests:

    $ prove -l t/

To ease the pain, a script called ``bootstrap.sh`` is provided. This script
automates all three of the steps just described.

To include the "Perl Critic" and "Check Manifest" tests, do::

    $ sudo cpanm Test::Perl::Critic
    $ sudo cpanm Test::Check::Manifest
    $ export TEST_AUTHOR=1
    $ prove -l t/


How to cut a release
--------------------

First, clone the ``smithfarm/dochazka.git`` repo::

    $ git clone https://github.com/smithfarm/dochazka.git
    $ cd dochazka

From there, follow the instructions at
https://github.com/smithfarm/dochazka#release-management

