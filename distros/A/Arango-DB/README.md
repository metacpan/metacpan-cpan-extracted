# Arango::DB

![](https://gitlab.com/ambs/perl5-arango-db/badges/master/pipeline.svg)

This Perl module, Arango::DB, is an interface to ArangoDB REST API.

At the moment, it is a work in progress module. Released soon, so it can be
useful, and the community to know it exists and can collaborate, if there is
any interest on it.

For the tests to run properly, the environment variables ARANGO_DB_HOST,
ARANGO_DB_PORT, ARANGO_DB_USERNAME and ARANGO_DB_PASSWORD can be set as
desired. If not, the default values will be tested (localhost:8529, root and
empty password). The tests will create a tmp_ table, that should not exist
(in the future it might detect and adapt accordingly).

