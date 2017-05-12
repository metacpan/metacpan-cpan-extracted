use inc::Module::Install;
name 'Algorithm-FuzzyCmeans';
all_from 'lib/Algorithm/FuzzyCmeans.pm';

requires 'Class::Accessor::Fast';
requires 'List::MoreUtils';
requires 'List::Util';
requires 'UNIVERSAL::require';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
