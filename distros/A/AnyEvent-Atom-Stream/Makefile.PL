use inc::Module::Install;
name 'AnyEvent-Atom-Stream';
all_from 'lib/AnyEvent/Atom/Stream.pm';

requires 'XML::Atom::Stream';
requires 'AnyEvent';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
