use inc::Module::Install;
name 'DBIx-TransactionManager';
all_from 'lib/DBIx/TransactionManager.pm';

requires 'DBI';
requires 'Try::Tiny';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More' => '0.96';

auto_set_repository;
WriteAll;
