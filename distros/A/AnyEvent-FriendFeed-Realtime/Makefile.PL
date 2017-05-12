use inc::Module::Install;
name 'AnyEvent-FriendFeed-Realtime';
all_from 'lib/AnyEvent/FriendFeed/Realtime.pm';

requires 'AnyEvent';
requires 'AnyEvent::HTTP';
requires 'JSON', '2.0';
requires 'URI';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
