===================
App::Dochazka::REST
===================

.. image:: https://travis-ci.org/smithfarm/dochazka-rest.svg?branch=master
    :target: https://travis-ci.org/smithfarm/dochazka-rest

.. image:: https://badge.fury.io/pl/App-Dochazka-REST.svg
    :target: https://badge.fury.io/pl/App-Dochazka-REST

-----------------------------------------------------------------------
REST server component of the Dochazka Attendance & Time Tracking system
-----------------------------------------------------------------------

Documentation 
=============

http://metacpan.org/pod/App::Dochazka::REST

Test drive
==========

The :code:`test-drive.sh` script makes it possible to take
App::Dochazka::REST for a test drive without installing it. The only
prerequisite is that Docker must be installed and running. ::

    $ ./test-drive.sh

When the script finishes, you should be able to access the REST server
on port 5000.

Dockerized testing environment
==============================

The git repo includes a :code:`Dockerfile` that can be used to create
a Dockerized testing environment: ::

    $ docker build -t dochazka-rest docker/testing/

The resulting image, tagged :code:`dochazka-rest`, is designed to work with
the `official PostgreSQL Docker images`_. 

.. _`official PostgreSQL Docker images`: https://hub.docker.com/_/postgres/

A script, :code:`docker-test.sh`, is provided in the top-level directory
to make it easier to run both images and link them together properly: :: 

    $ ./docker-test.sh
    f4d9677dd59e23527122a4f38c662b4b8ea6bb49a3921a018e7b70dfc7c25c1e
    51e839db7d66fe5c90edc73e850fe85c35dca5401bd502277d6575fcbbea9f4d
    $

The :code:`docker-test.sh` script spawns two Docker containers, tagged
:code:`dr-postgres` and :code:`dr`, and writes their hashes to stdout.
The Dockerized testing environment is in the container :code:`dr`. To gain
access to it, run this command: ::

    $ docker exec -it dr bash
    smithfarm@dr:~/dochazka-rest>

At this point, you should be able run the test suite: ::

    smithfarm@dr:~/dochazka-rest> prove -lr t

Release management
==================

First, make sure you have :code:`perl-reversion` and :code:`cpan-uploader`
installed. In openSUSE, this means installing the :code:`perl-Perl-Version`
and :code:`perl-CPAN-Uploader` packages.

Second, run the :code:`prerelease.sh` script to bump the version number,
commit all outstanding modifications, add a git tag, and append draft
Changes file entry: ::

    $ sh prerelease.sh

Third, push the changes to GitHub: ::

    $ git push --follow-tags

Fourth, optionally run the release script to push the release to OBS 
and CPAN: ::

    $ sh release.sh

