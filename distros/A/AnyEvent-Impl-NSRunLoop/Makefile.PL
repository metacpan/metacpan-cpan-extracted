use inc::Module::Install;

assertos 'MacOSX';

name 'AnyEvent-Impl-NSRunLoop';
all_from 'lib/AnyEvent/Impl/NSRunLoop.pm';

requires 'AnyEvent' => '5.29';
requires 'Cocoa::EventLoop';

test_requires 'Test::More' => '0.88';
tests 't/*.t t/*/*.t';
author_tests 'xt';

auto_set_repository;

WriteAll;
