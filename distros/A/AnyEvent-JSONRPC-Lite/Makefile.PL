use inc::Module::Install;
name 'AnyEvent-JSONRPC-Lite';
all_from 'lib/AnyEvent/JSONRPC/Lite.pm';

requires 'Any::Moose';
requires 'AnyEvent' => '5.12';
requires 'JSON';
recommends 'JSON::XS';

test_requires 'Test::More';
test_requires 'Test::TCP';
test_requires 'Test::Exception';

author_tests('xt');
use_test_base;

auto_include;
auto_set_repository;

WriteAll;
