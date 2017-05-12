use inc::Module::Install;
name 'Attribute-Generator';
all_from 'lib/Attribute/Generator.pm';

requires 'Coro' => '4.91';
requires 'Attribute::Handlers';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
