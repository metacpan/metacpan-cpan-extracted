use inc::Module::Install;
name 'AnyEvent-ReverseHTTP';
all_from 'lib/AnyEvent/ReverseHTTP.pm';

requires 'HTTP::Request';
requires 'AnyEvent';
requires 'AnyEvent::HTTP';
requires 'URI::Escape';
requires 'Any::Moose';

requires 'Digest::SHA';
requires 'Time::HiRes';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
