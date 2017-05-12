use inc::Module::Install;
name 'DBIx-DBHResolver';
all_from 'lib/DBIx/DBHResolver.pm';

requires 'parent';
requires 'Carp';
requires 'Class::Accessor::Fast';
requires 'Config::Any';
requires 'Data::Util';
requires 'DBI';
requires 'Hash::Merge::Simple';
requires 'Try::Tiny';
requires 'UNIVERSAL::require';
requires 'YAML';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::LoadAllModules';
test_requires 'Test::Requires';

tests_recursive 't';
author_tests 'xt';

use_test_base;
auto_set_repository;
auto_include;

WriteAll;
