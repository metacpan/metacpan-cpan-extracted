Data::Sync is a simple, pure perl based metadirectory/data pump.
(Although you may need a compiler if you're using certain DBI
drivers and/or Net::LDAP).

At the moment this is ALPHA software - use it with caution! I'm keen
see the functionality develop further, and welcome feedback at
charlesc@g0n.net

INSTALLATION
============

install with cpan, or do:

perl Makefile.PL
make test
make install

TESTING
=======

Obviously not everyone has LDAP, Net::LDAP & DBD::SQLite installed. The
bulk of the testing is done on my dev server - the tests shipped with
the module test internal functionality only.
