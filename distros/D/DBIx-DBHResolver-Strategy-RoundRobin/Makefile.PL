use inc::Module::Install;
name 'DBIx-DBHResolver-Strategy-RoundRobin';
all_from 'lib/DBIx/DBHResolver/Strategy/RoundRobin.pm';

requires 'DBIx::DBHResolver';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
