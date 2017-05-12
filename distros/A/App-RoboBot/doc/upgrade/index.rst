.. include:: ../common.defs

.. _ch-upgrade:

Upgrading
*********

|RB| has been designed to handle most upgrade tasks, particularly keeping its
database schemas current, automatically and transparently. Beginning with
version 4, running the main ``robobot`` program with the ``-m`` argument will
have it verify, and if necessary update, the state of its database schema.

This section details any additional steps you may need to take. Please take the
time to read through all the sections that apply to you before attempting an
upgrade, so as to avoid any unnecessary headaches.

If you encounter a problem during an upgrade, please open an issue on the |GH|
project with as much detail about the problems you experienced and include the
full text of any errors that were shown.

Upgrading from versions prior to 4.0
====================================

|RB| underwent drastic changes for its 4.0 release, which was technically the
first official, public release. While it had been available in source on GitHub
since the very beginning, v4 was the first version remotely suitable for
publishing to CPAN.

The most significant user-facing change was the move to automated database
migrations using |Sqitch|. Because of this change, it is critical that anyone
running a version prior to 4.0, who wishes to retain any of their existing
data, follow the steps outlined here before running any newer version.

#. Stop your current |RB| instance and ensure nothing else is accessing or
   modifying its database.

#. Perform a *data only* database backup of the entire |RB| database. Assuming
   the PostgreSQL database is running on the default port of localhost and is
   named ``robobot``, the command will look like this::

       pg_dump -a -Fp -h localhost -d robobot -U robobot > robobot-dataonly.pgdump

#. Drop or rename the current database from your older |RB| instance, and
   create a new, blank |RB| database with appropriate access permissions.

#. Install version 4.002 of |RB|. Do not install any later versions yet. It is
   critical that you install this exact version first so that you can restore
   your existing data into the initial Sqitch-managed schema. If you are using
   the recommended |CPANM| installation process, you would issue the command::

       cpanm JSIME/App-RoboBot-4.002.tar.gz

#. Update the ``<database>`` section of your configuration file to match the
   post-4.0 format. The settings are described in the :ref:`config-database`
   section of the configuration chapter.

#. Run |RB| once with migrations enabled. This will ensure that |RB| applies
   all of the necessary migrations to create a new, clean database schema::

       robobot -c <path to config> -m

#. Stop the |RB| instance once migrations have been applied.

#. Use ``psql`` to connect to your |RB| database, as whatever user you have
   configured for access, and issue the following SQL statement to remove the
   redundant skill level names (your data-only backup from earlier is going to
   try to recreate these, which will be a problem if they already exist)::

       DELETE FROM skills_levels;

#. Restore the data-only backup you created earlier (again, assuming your |RB|
   database is on the default port of localhost; adjust the connection settings
   as necessary to match your actual environment)::

       psql -h localhost -U robobot -d robobot < robobot-dataonly.pgdump

#. Start the |RB| instance again with the ``robobot`` command and ensure that
   everything is okay.

Assuming you have not run into any errors, and all your data remains intact
(there is very little reason it should not be -- the worst you should encounter
in this process will be headaches with the overlapping skill levels data) you
will now be ready to upgrade to more recent versions of |RB| using the normal
procedures.
