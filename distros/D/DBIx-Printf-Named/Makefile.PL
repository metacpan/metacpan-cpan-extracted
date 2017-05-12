use inc::Module::Install;
name 'DBIx-Printf-Named';
all_from 'lib/DBIx/Printf/Named.pm';

requires 'DBI';
requires 'Carp::Clan';
requires 'Regexp::Common';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'DBD::Mock';
auto_set_repository;
auto_include;
WriteAll;
