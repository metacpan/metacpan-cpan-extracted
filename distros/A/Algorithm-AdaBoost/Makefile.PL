use inc::Module::Install;
name 'Algorithm-AdaBoost';
all_from 'lib/Algorithm/AdaBoost.pm';

requires 'Smart::Args' => '0.10';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
