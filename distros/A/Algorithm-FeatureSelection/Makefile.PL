use inc::Module::Install;
name 'Algorithm-FeatureSelection';
all_from 'lib/Algorithm/FeatureSelection.pm';

requires 'List::Util';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
