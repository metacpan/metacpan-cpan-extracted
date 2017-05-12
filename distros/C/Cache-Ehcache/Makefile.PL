use inc::Module::Install;
name 'Cache-Ehcache';
all_from 'lib/Cache/Ehcache.pm';

requires 'LWP';
requires 'Moose';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
