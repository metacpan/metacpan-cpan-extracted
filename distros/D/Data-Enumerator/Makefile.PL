use inc::Module::Install;
name 'Data-Enumerator';
all_from 'lib/Data/Enumerator.pm';
readme_from 'lib/Data/Enumerator.pm';

githubmeta;

requires 'Data::Visitor::Lite';
requires 'List::MoreUtils';
requires 'Scalar::Util';
requires 'IO::File';
requires 'Exporter';

test_requires 'Test::More';
tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
