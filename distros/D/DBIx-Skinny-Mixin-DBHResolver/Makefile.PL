use inc::Module::Install;
name 'DBIx-Skinny-Mixin-DBHResolver';
all_from 'lib/DBIx/Skinny/Mixin/DBHResolver.pm';

requires 'DBIx::Skinny';
requires 'DBIx::DBHResolver';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
