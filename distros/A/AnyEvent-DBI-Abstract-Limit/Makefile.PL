use inc::Module::Install;
name 'AnyEvent-DBI-Abstract-Limit';
all_from 'lib/AnyEvent/DBI/Abstract/Limit.pm';

# requires '';
requires 'parent';
requires 'AnyEvent::DBI';
requires 'AnyEvent::DBI::Abstract';
requires 'SQL::Abstract::Limit';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
