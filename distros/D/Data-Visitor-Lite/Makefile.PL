use inc::Module::Install;
name 'Data-Visitor-Lite';
all_from 'lib/Data/Visitor/Lite.pm';
readme_from 'lib/Data/Visitor/Lite.pm';
githubmeta;

requires 'Data::Util';
requires 'List::MoreUtils';
requires 'Scalar::Util';
requires 'Carp';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
