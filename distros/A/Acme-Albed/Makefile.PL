use inc::Module::Install;
name 'Acme-Albed';
all_from 'lib/Acme/Albed.pm';

requires 'Any::Moose';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
