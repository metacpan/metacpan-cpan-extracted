use inc::Module::Install;
name 'DBIx-AssertIndex';
all_from 'lib/DBIx/AssertIndex.pm';

requires 'DBI';
requires 'DBD::mysql';

test_requires 'Test::More', 0.98;
test_requires 'Test::Requires';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Requires';
auto_set_repository;
auto_include;
WriteAll;
