use inc::Module::Install;
name 'CGI-Application-PSGI';
all_from 'lib/CGI/Application/PSGI.pm';

requires 'CGI::Application';
requires 'CGI::PSGI';
test_requires 'Test::TCP';
test_requires 'Test::Requires';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
