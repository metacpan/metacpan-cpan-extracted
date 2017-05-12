.. include:: ../common.defs

.. _ch-install:

Installation
************

There are two main approaches to installing |RB|:
:ref:`CPAN <install-cpan>` and :ref:`Git <install-git>`. The former
is strongly preferred for users who simply wish to run |RB| on their own
chat services.

Regardless of which you choose, you will need to ensure you have installed all
the necessary :ref:`requirements <install-reqs>` first.

.. _install-reqs:

Requirements
============

The following system libraries and packages will need to be present on your
system to make full use of |RB|, regardless of whether you are installing
via CPAN or the Git repository.  The majority of these are used by the various
Perl module dependencies of |RB|.

Some of these dependencies are optional, and they are marked with a ``*``, but
their absence from your system will render some features of |RB| inert.

Build Toolchain
---------------

The following basic build tools will need to be present on your system:

- bison
- flex
- gcc
- g++
- libc-dev
- make

System Libraries
----------------

The following programs and libraries (and in several cases their accompanying
headers, often found in separate *-dev* packages for some distributions) will
need to be present on your system:

- aspell (and at least aspell-en, though you may add others) \*
- figlet \*
- filters \*
- fortune \*
- libaspell-dev \*
- libevent (2.0+)
- libevent-openssl (matching version to libevent)
- libpq-dev
- libxml2-dev

Perl Requirements
-----------------

The initial Perl requirements are simple, as most of the Perl dependencies will
be installed automatically from CPAN when you install |RB| itself. But you
will need to get two things out of the way before that:

- Perl (5.20+)
- App::cpanminus

You may also wish to handle the Perl side of things with |Perlbrew|, to avoid
contaminating your system Perl installation. This is especially useful if your
OS distribution ships an older Perl. In this case, you will still install OS
packages for your build toolchain and the system libraries above, but would
set up Perl and |CPANM| through the standard |Perlbrew| process.

The choice is up to you, though if you intend to be doing development on
|RB| itself or writing your own plugins for it, using |Perlbrew| provides
several benefits. Not the least of which is the ability to easily switch
between Perl versions for testing, without affecting your system Perl.

PostgreSQL
----------

|RB| requires access to a |PG| database, with 9.4 being the earliest version
currently supported. Older releases may work, but they will not be tested and
support requests for them will not receive the same priority as more current
versions. Other RDBMS packages are not supported at this time (no MySQL,
SQLite, etc.).

|RB| will set up the contents of its database for you when you first run it
(and will continuously upgrade its own schema as necessary whenever you install
new versions of |RB|), but you will still need to install and configure the
base |PG| service and create an empty database with appropriate access
permissions.

Installing Dependencies on Ubuntu
---------------------------------

Installing all of these on a relatively recent version of Ubuntu may be
accomplished with the following::

    sudo apt-get install build-essential bison flex

    sudo apt-get install aspell-en figlet filters fortune-mod \
        fortunes fortunes-bofh-excuses fortunes-min fortunes-off \
        libevent-openssl-2.0 libpq-dev libxml2-dev

    sudo apt-get install perl cpanminus

Installing Dependencies on RedHat/CentOS
----------------------------------------

*Forthcoming*

.. _install-cpan:

Installing via CPAN
===================

Installing |RB| via CPAN is very simple (assuming you have fulfilled the
requirements listed above)::

    cpanm App::RoboBot

On a fresh system, this will take quite a while, as there's a pretty deep list
of dependencies to work through. Once complete, you will have a ``robobot``
command available and may move on to :ref:`ch-config`.

.. _install-git:

Installing via Git
==================

Installing from the `Git repository <https://github.com/jsime/robobot.git>`_
will only add a few extra steps as compared to CPAN installs. This method is
recommended only if you are either working on |RB| development, or
desparately wish to run the absolute bleeding edge version from the Git master
branch. Most people should stick to the CPAN installation method.

Begin by cloning the repository (we'll assume you clone to ``~/robobot``)::

    git clone https://github.com/jsime/robobot.git ~/robobot
    cd ~/robobot

In addition to all of the requirements already listed, you will need to install
|DZIL|::

    cpanm Dist::Zilla

Followed by installing all the necessary |DZIL| plugins used by the |RB| build
configuration::

    dzil authordeps | cpanm

And all of the |RB| dependencies::

    dzil listdeps | cpanm

At this point, you'll be ready to move on to :ref:`ch-config`. For running
RoboBot from the Git clone without having to fully install it, you must use the
``dzil run`` command. This is necessary because |RB| needs to locate its
*share directory* to run database migrations, and that cannot be done by
invoking the ``bin/robobot`` script directly from the Git clone. To use ``dzil``
to run the script instead, you will invoke it as such::

    dzil run bin/robobot -c <path to config> -m

You'll want to keep an eye on the ``.build/`` directory, as |DZIL| will keep
around build artifacts for failed runs (or any time you prematurely kill the
robobot process). They're only a few megabytes each, but that can add up if you
do a lot of runs.

If you do wish to perform a full install of |RB|, |DZIL| will again be used::

    dzil install

This will build, test, and install the package locally on your system, with the
end result looking the same as if |RB| had been installed from CPAN.

Testing the Waters With Vagrant
===============================

|A-RB| ships with a sample Vagrantfile in its ``share/`` directory for spinning
up an environment suitable for trying out |RB| with |Vagrant|. This Vagrantfile
will create an Ubuntu virtual machine (64-bit 16.04 LTS, aka Xenial), though
you are welcome to modify the contents of the file before running it.

Included in the Vagrantfile are the necessary Apt commands, issued through the
inline shell provisioner, to install all the necessary dependencies for |RB|,
including |PG|. No |RB| configuration is provided, and no database setup or
access permissions are configured for |PG|. Those are still left as an exercise
for the user, but once the |Vagrant| provisioning has completed, all necessary
software will be installed and ready to configure and use.

.. literalinclude:: ../../share/Vagrantfile
   :language: ruby
