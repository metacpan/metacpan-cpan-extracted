=========
App::CELL
=========

.. image:: https://travis-ci.org/smithfarm/cell.svg?branch=master
    :target: https://travis-ci.org/smithfarm/cell

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

Maintainer Documentation
========================

Read on only if you are a maintainer of ``App::CELL``


How to run tests
----------------

After cloning the git repo, you'll need to install all of the
dependencies shown in Build.PL -- either using distro packages
or ``cpanm``.

Since ``App::CELL`` needs its configuration files installed
in the system in order to run, install it::

    $ perl Build.PL ; ./Build ; sudo ./Build install

Then::

    $ prove -l t/

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

