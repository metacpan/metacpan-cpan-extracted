use inc::Module::Install;
name 'Data-OpenStruct-Deep';
all_from 'lib/Data/OpenStruct/Deep.pm';

requires 'Storable';
requires 'Want';

tests 't/*.t';
test_requires 'Test::More';
test_requires 'ok';
test_requires 'Test::Deep';
author_tests 'xt';
use_test_base;

auto_include_deps;
WriteAll;
