use inc::Module::Install;
name 'Algorithm-Kmeanspp';
all_from 'lib/Algorithm/Kmeanspp.pm';

requires 'Carp';
requires 'Class::Accessor::Fast';
requires 'List::Util';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
