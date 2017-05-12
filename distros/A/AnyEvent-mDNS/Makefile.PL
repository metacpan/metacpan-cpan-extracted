use inc::Module::Install;
name 'AnyEvent-mDNS';
all_from 'lib/AnyEvent/mDNS.pm';

requires 'AnyEvent', 7;
requires 'AnyEvent::Handle::UDP', 0.038;

build_requires 'Test::More';
author_tests('xt');
auto_set_repository;
WriteAll;
