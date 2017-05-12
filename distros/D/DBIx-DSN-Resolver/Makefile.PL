use inc::Module::Install;
name 'DBIx-DSN-Resolver';
all_from 'lib/DBIx/DSN/Resolver.pm';

requires 'DBI', '1.616';
requires 'Socket';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
#auto_include;
WriteAll;
